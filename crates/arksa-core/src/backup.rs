//! SavedArks zip snapshots + rollback.
//!
//! ARK SA writes the world save plus a swarm of companion files
//! (`.ark` / timestamped `.ark` autosaves / engine `.arkrbf` rolling
//! backups / per-tribe `<TribeID>.arktribe` / per-player
//! `<SteamID>.arkprofile` / their `.arktribebak` & `.arkprofilebak`
//! timestamped variants) all under
//! `<install>\ShooterGame\Saved\SavedArks\<MapName>\`.
//!
//! These files **must roll back together** — the world save references
//! tribe IDs that reference player profiles, so a rollback that only
//! restored `.ark` while leaving the current `.arktribe` untouched would
//! create dangling references and silently destroy tribe membership and
//! tame ownership.
//!
//! This module captures the entire `<MapName>\` directory in one zip
//! and restores it the same way. Layout:
//!
//! ```text
//! <install>\ARKSA_Backups\<MapName>\
//!     auto\
//!         YYYYMMDD_HHMMSS.zip          // periodic, ring buffer (N kept)
//!     manual\
//!         YYYYMMDD_HHMMSS.zip          // user-initiated, no retention
//!     pre_rollback\
//!         from_<SRC>_to_<RB>.zip       // emergency, last 3 kept
//! ```
//!
//! `ARKSA_Backups\` lives at install root (sibling of `ShooterGame\` /
//! `Engine\` / `steamapps\`) so future engine updates that reorganise
//! `Saved\` cannot collide with our directory.
//!
//! The three sub-directories (`auto\` / `manual\` / `pre_rollback\`)
//! exist so retention policies can be applied independently: only
//! `auto\` is subject to the user's ring buffer, `manual\` is kept
//! until the user explicitly deletes, and `pre_rollback\` is capped at
//! a small fixed history.
//!
//! Pre-rollback filenames embed the timestamp of the source snapshot
//! the user was restoring **from**. This lets the GUI match each
//! snapshot row to its "before-rollback" emergency backup and offer a
//! one-click "undo this rollback" action.

use std::cmp::Ordering;
use std::fs::{self, File};
use std::io::{self, BufReader, BufWriter, Write};
use std::path::{Path, PathBuf};

use chrono::{DateTime, Local, NaiveDateTime, TimeZone};
use zip::write::SimpleFileOptions;
use zip::{CompressionMethod, ZipArchive, ZipWriter};

use crate::error::{Error, Result};

/// Hard cap on emergency `pre_rollback` snapshots. Not user-configurable
/// — the user only ever rolls back manually, so a small fixed history
/// is enough to undo a bad rollback choice.
pub const MAX_PRE_ROLLBACK: u32 = 3;

/// Default compression level when the caller doesn't specify one. 1 =
/// Deflate level 1 (fastest), the right default for SavedArks: the
/// engine's `.ark` blobs are already dense binary and only compress
/// 60–70% even at level 9, while level 1 finishes ~5–10× faster.
/// Users who want smaller files trade CPU back via the GUI's
/// compression dropdown.
pub const DEFAULT_COMPRESSION_LEVEL: u8 = 1;

/// Filename timestamp format. Sortable lexicographically, no separators
/// that would confuse Windows path tooling.
const TS_FORMAT: &str = "%Y%m%d_%H%M%S";

/// `ShooterGame\Saved\SavedArks\<MapName>\` for the given install root.
pub fn savedarks_dir(install_root: &Path, map_name: &str) -> PathBuf {
    install_root
        .join("ShooterGame")
        .join("Saved")
        .join("SavedArks")
        .join(map_name)
}

/// `<install>\ARKSA_Backups\<MapName>\`.
pub fn backup_root(install_root: &Path, map_name: &str) -> PathBuf {
    install_root.join("ARKSA_Backups").join(map_name)
}

/// `<install>\ARKSA_Backups\<MapName>\auto\` — periodic snapshots.
pub fn auto_dir(install_root: &Path, map_name: &str) -> PathBuf {
    backup_root(install_root, map_name).join("auto")
}

/// `<install>\ARKSA_Backups\<MapName>\manual\` — user-initiated snapshots.
pub fn manual_dir(install_root: &Path, map_name: &str) -> PathBuf {
    backup_root(install_root, map_name).join("manual")
}

/// `<install>\ARKSA_Backups\<MapName>\pre_rollback\` — emergency snapshots.
pub fn pre_rollback_dir(install_root: &Path, map_name: &str) -> PathBuf {
    backup_root(install_root, map_name).join("pre_rollback")
}

/// Whether the source SavedArks tree is present (server has run at least
/// once). Used by callers to gate "Take backup now" buttons.
pub fn savedarks_exists(install_root: &Path, map_name: &str) -> bool {
    savedarks_dir(install_root, map_name).is_dir()
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SnapshotKind {
    /// Periodic snapshot, written by the auto-backup scheduler. Subject
    /// to the user's retention policy (T-minute cadence, N count).
    Auto,
    /// User-initiated snapshot via the "Take backup now" button. Never
    /// pruned by retention — the user pressed the button, they can
    /// press the delete button to clean up.
    Manual,
    /// Emergency snapshot taken just before a rollback. Capped at
    /// [`MAX_PRE_ROLLBACK`]. The companion `source_timestamp` field on
    /// [`Snapshot`] links it to the snapshot the user was restoring
    /// from.
    PreRollback,
}

#[derive(Debug, Clone)]
pub struct Snapshot {
    pub path: PathBuf,
    pub created: DateTime<Local>,
    pub size_bytes: u64,
    pub kind: SnapshotKind,
    /// Set only for [`SnapshotKind::PreRollback`]: the timestamp of the
    /// snapshot the user was about to restore when this emergency
    /// backup was taken. Lets the GUI line up a snapshot row with its
    /// matching "before-rollback" zip.
    pub source_timestamp: Option<DateTime<Local>>,
}

// ---------------------------------------------------------------------------
// Public API: snapshot creation
// ---------------------------------------------------------------------------

/// Create a periodic (auto) snapshot of
/// `<install>\…\SavedArks\<MapName>\`, writing to
/// `<install>\ARKSA_Backups\<MapName>\auto\<TS>.zip`.
///
/// `compression_level` is `0` for STORE (no compression — file-copy
/// speed) or `1..=9` for Deflate (1 fastest, 9 smallest). Anything out
/// of range is clamped.
///
/// Returns the new snapshot. Does **not** apply retention — call
/// [`enforce_retention`] separately so callers can decide whether to
/// rotate (e.g. after a successful save vs. before).
pub fn create_auto_snapshot(
    install_root: &Path,
    map_name: &str,
    compression_level: u8,
) -> Result<Snapshot> {
    create_kind_snapshot(install_root, map_name, compression_level, SnapshotKind::Auto)
}

/// Create a manual snapshot of `<install>\…\SavedArks\<MapName>\`,
/// writing to `<install>\ARKSA_Backups\<MapName>\manual\<TS>.zip`.
///
/// Same compression-level convention as [`create_auto_snapshot`]. Not
/// affected by retention — manual snapshots stay until the user
/// deletes them through the GUI.
pub fn create_manual_snapshot(
    install_root: &Path,
    map_name: &str,
    compression_level: u8,
) -> Result<Snapshot> {
    create_kind_snapshot(install_root, map_name, compression_level, SnapshotKind::Manual)
}

/// Create an emergency `pre_rollback` snapshot. Same contents as
/// [`create_auto_snapshot`] but written to the `pre_rollback\`
/// sub-folder so it survives the periodic ring buffer.
///
/// `source_created` is the `created` timestamp of the snapshot the
/// caller is about to restore from. It is embedded in the new file's
/// name so the GUI can later match this emergency backup back to its
/// source.
pub fn create_pre_rollback(
    install_root: &Path,
    map_name: &str,
    compression_level: u8,
    source_created: DateTime<Local>,
) -> Result<Snapshot> {
    let src = savedarks_dir(install_root, map_name);
    if !src.is_dir() {
        return Err(Error::Other(format!(
            "SavedArks directory not found: {}",
            src.display(),
        )));
    }
    let dst_dir = pre_rollback_dir(install_root, map_name);
    fs::create_dir_all(&dst_dir)?;
    let now = Local::now();
    let zip_path = unique_path(
        &dst_dir,
        &format!(
            "from_{}_to_{}",
            source_created.format(TS_FORMAT),
            now.format(TS_FORMAT),
        ),
        "zip",
    )?;
    write_zip_atomic(&src, &zip_path, compression_level)?;
    let size_bytes = fs::metadata(&zip_path)?.len();
    Ok(Snapshot {
        path: zip_path,
        created: now,
        size_bytes,
        kind: SnapshotKind::PreRollback,
        source_timestamp: Some(source_created),
    })
}

// ---------------------------------------------------------------------------
// Public API: listing
// ---------------------------------------------------------------------------

/// List auto (periodic) snapshots, newest first. Missing directory →
/// empty list. Calls [`migrate_legacy_layout`] first so older installs
/// that wrote to the old flat layout still surface their snapshots.
pub fn list_auto(install_root: &Path, map_name: &str) -> Result<Vec<Snapshot>> {
    migrate_legacy_layout(install_root, map_name)?;
    list_simple_ts_dir(&auto_dir(install_root, map_name), SnapshotKind::Auto)
}

/// List manual snapshots, newest first.
pub fn list_manual(install_root: &Path, map_name: &str) -> Result<Vec<Snapshot>> {
    list_simple_ts_dir(&manual_dir(install_root, map_name), SnapshotKind::Manual)
}

/// List pre_rollback snapshots, newest first.
pub fn list_pre_rollbacks(install_root: &Path, map_name: &str) -> Result<Vec<Snapshot>> {
    let dir = pre_rollback_dir(install_root, map_name);
    let mut out = Vec::new();
    let entries = match fs::read_dir(&dir) {
        Ok(e) => e,
        Err(e) if e.kind() == io::ErrorKind::NotFound => return Ok(out),
        Err(e) => return Err(e.into()),
    };
    for entry in entries {
        let entry = entry?;
        let path = entry.path();
        if !path.is_file() {
            continue;
        }
        let Some(name) = path.file_name().and_then(|s| s.to_str()) else {
            continue;
        };
        let Some((created, source)) = parse_pre_rollback_filename(name) else {
            continue;
        };
        let size_bytes = fs::metadata(&path).map(|m| m.len()).unwrap_or(0);
        out.push(Snapshot {
            path,
            created,
            size_bytes,
            kind: SnapshotKind::PreRollback,
            source_timestamp: source,
        });
    }
    out.sort_by(|a, b| b.created.cmp(&a.created));
    Ok(out)
}

// ---------------------------------------------------------------------------
// Public API: retention / deletion / rollback
// ---------------------------------------------------------------------------

/// Delete the oldest auto snapshots until at most `retain_count` remain.
/// Manual and pre_rollback snapshots are never touched. Returns the
/// number deleted. `retain_count == 0` would wipe everything; we guard
/// with `max(1)` to avoid that footgun.
pub fn enforce_retention(
    install_root: &Path,
    map_name: &str,
    retain_count: u32,
) -> Result<u32> {
    let keep = retain_count.max(1) as usize;
    let snapshots = list_auto(install_root, map_name)?;
    let mut deleted = 0u32;
    for stale in snapshots.iter().skip(keep) {
        if fs::remove_file(&stale.path).is_ok() {
            deleted += 1;
        }
    }
    Ok(deleted)
}

/// Delete the oldest pre_rollback snapshots until [`MAX_PRE_ROLLBACK`]
/// remain. Returns the number deleted.
pub fn enforce_pre_rollback_retention(
    install_root: &Path,
    map_name: &str,
) -> Result<u32> {
    let snapshots = list_pre_rollbacks(install_root, map_name)?;
    let mut deleted = 0u32;
    for stale in snapshots.iter().skip(MAX_PRE_ROLLBACK as usize) {
        if fs::remove_file(&stale.path).is_ok() {
            deleted += 1;
        }
    }
    Ok(deleted)
}

/// Delete a single snapshot zip from disk. Refuses paths that aren't
/// inside the install root's `ARKSA_Backups\` tree so a stray click in
/// the GUI can't be tricked into wiping arbitrary user files.
pub fn delete_snapshot(install_root: &Path, snapshot_path: &Path) -> Result<()> {
    let allowed_root = install_root.join("ARKSA_Backups");
    let canonical_root = match fs::canonicalize(&allowed_root) {
        Ok(r) => r,
        Err(_) => allowed_root.clone(),
    };
    let canonical_target = match fs::canonicalize(snapshot_path) {
        Ok(r) => r,
        // If the file no longer exists, fall back to lexical containment
        // so a stale UI row can still be cleaned out of the listing.
        Err(_) => snapshot_path.to_path_buf(),
    };
    if !canonical_target.starts_with(&canonical_root)
        && !snapshot_path.starts_with(&allowed_root)
    {
        return Err(Error::Other(format!(
            "refusing to delete file outside the backup tree: {}",
            snapshot_path.display(),
        )));
    }
    fs::remove_file(snapshot_path)?;
    Ok(())
}

/// Restore `SavedArks\<MapName>\` from a snapshot zip.
///
/// Caller must ensure the server is stopped — extracting over a live
/// save would race the engine's writer and corrupt the world.
///
/// Strategy: extract into a sibling staging dir, then atomically swap
/// the existing tree out (renamed `<MapName>.replaced_<TS>` so a failed
/// rollback can be recovered) and the staging dir in. The replaced tree
/// is removed on success. If the staging extract fails, the existing
/// tree is left untouched.
pub fn rollback(
    install_root: &Path,
    map_name: &str,
    snapshot_path: &Path,
) -> Result<()> {
    let target = savedarks_dir(install_root, map_name);
    let parent = target
        .parent()
        .ok_or_else(|| Error::Other("SavedArks parent missing".into()))?;
    fs::create_dir_all(parent)?;

    let now = Local::now();
    let staging = parent.join(format!(
        "{}.staging_{}",
        map_name,
        now.format(TS_FORMAT)
    ));
    if staging.exists() {
        fs::remove_dir_all(&staging)?;
    }
    fs::create_dir_all(&staging)?;

    extract_zip_into(snapshot_path, &staging).map_err(|e| {
        // Clean up partial staging on failure so we don't leave litter.
        let _ = fs::remove_dir_all(&staging);
        e
    })?;

    let replaced = parent.join(format!(
        "{}.replaced_{}",
        map_name,
        now.format(TS_FORMAT)
    ));
    if target.exists() {
        fs::rename(&target, &replaced)?;
    }
    if let Err(e) = fs::rename(&staging, &target) {
        // Try to restore the original tree if the swap-in fails.
        if replaced.exists() {
            let _ = fs::rename(&replaced, &target);
        }
        return Err(e.into());
    }
    if replaced.exists() {
        let _ = fs::remove_dir_all(&replaced);
    }
    Ok(())
}

/// Best-effort: derive the "created" timestamp of an arbitrary snapshot
/// path from its filename. Recognises every on-disk shape this module
/// writes or has ever written: the new `<TS>.zip` (auto / manual), the
/// new `from_<SRC>_to_<RB>.zip` (pre_rollback), and the two legacy
/// forms (`snapshot_<map>_<TS>.zip`, `pre_rollback_<TS>.zip`). Falls
/// back to the file's mtime if no pattern matches.
///
/// The rollback path uses this to extract the source snapshot's
/// timestamp when creating a `from_..._to_...` pre_rollback zip — the
/// GUI passes the source path as a SharedString, not the original
/// Snapshot, so we recover the timestamp from the filename.
pub fn snapshot_path_created(path: &Path) -> Option<DateTime<Local>> {
    if let Some(name) = path.file_name().and_then(|s| s.to_str()) {
        if let Some(ts) = parse_ts_zip_filename(name) {
            return Some(ts);
        }
        if let Some((rb, _)) = parse_pre_rollback_filename(name) {
            return Some(rb);
        }
        if let Some(ts_str) = parse_legacy_auto_filename(name) {
            if let Some(dt) = parse_ts(&ts_str) {
                return Some(dt);
            }
        }
    }
    let meta = fs::metadata(path).ok()?;
    let modified = meta.modified().ok()?;
    Some(DateTime::<Local>::from(modified))
}

/// Move pre-existing legacy snapshots into the new layout. Tool versions
/// before the auto/manual split wrote `snapshot_<map>_<TS>.zip` directly
/// under `<root>\` and `pre_rollback_<TS>.zip` under `pre_rollback\`.
/// This walks the root, moves matching auto files into `auto\<TS>.zip`,
/// and leaves legacy pre_rollback names alone (their parser still
/// recognises them — just without a `source_timestamp`).
///
/// Idempotent: re-running after migration is a no-op. Failures on
/// individual files are swallowed so a transient lock on one zip can't
/// prevent the rest of the migration from completing.
pub fn migrate_legacy_layout(install_root: &Path, map_name: &str) -> Result<u32> {
    let root = backup_root(install_root, map_name);
    if !root.is_dir() {
        return Ok(0);
    }
    let auto = auto_dir(install_root, map_name);
    let mut moved = 0u32;
    let entries = match fs::read_dir(&root) {
        Ok(e) => e,
        Err(_) => return Ok(0),
    };
    let mut to_move: Vec<(PathBuf, String)> = Vec::new();
    for entry in entries.flatten() {
        let path = entry.path();
        if !path.is_file() {
            continue;
        }
        let Some(name) = path.file_name().and_then(|s| s.to_str()) else {
            continue;
        };
        if let Some(ts) = parse_legacy_auto_filename(name) {
            to_move.push((path, ts));
        }
    }
    if !to_move.is_empty() {
        fs::create_dir_all(&auto)?;
    }
    for (src_path, ts) in to_move {
        let Ok(dst) = unique_path(&auto, &ts, "zip") else {
            continue;
        };
        if fs::rename(&src_path, &dst).is_ok() {
            moved += 1;
        }
    }
    Ok(moved)
}

// ---------------------------------------------------------------------------
// internals
// ---------------------------------------------------------------------------

fn create_kind_snapshot(
    install_root: &Path,
    map_name: &str,
    compression_level: u8,
    kind: SnapshotKind,
) -> Result<Snapshot> {
    let src = savedarks_dir(install_root, map_name);
    if !src.is_dir() {
        return Err(Error::Other(format!(
            "SavedArks directory not found: {}",
            src.display(),
        )));
    }
    let dst_dir = match kind {
        SnapshotKind::Auto => auto_dir(install_root, map_name),
        SnapshotKind::Manual => manual_dir(install_root, map_name),
        SnapshotKind::PreRollback => {
            // create_pre_rollback has its own path so callers must use it
            // for the source-timestamp threading.
            return Err(Error::Other(
                "use create_pre_rollback for PreRollback kind".into(),
            ));
        }
    };
    fs::create_dir_all(&dst_dir)?;
    let now = Local::now();
    let zip_path = unique_path(&dst_dir, &now.format(TS_FORMAT).to_string(), "zip")?;
    write_zip_atomic(&src, &zip_path, compression_level)?;
    let size_bytes = fs::metadata(&zip_path)?.len();
    Ok(Snapshot {
        path: zip_path,
        created: now,
        size_bytes,
        kind,
        source_timestamp: None,
    })
}

/// Walk a directory expecting `<TS>.zip` filenames (auto/manual layout)
/// and return parsed Snapshot rows, newest first.
fn list_simple_ts_dir(dir: &Path, kind: SnapshotKind) -> Result<Vec<Snapshot>> {
    let mut out = Vec::new();
    let entries = match fs::read_dir(dir) {
        Ok(e) => e,
        Err(e) if e.kind() == io::ErrorKind::NotFound => return Ok(out),
        Err(e) => return Err(e.into()),
    };
    for entry in entries {
        let entry = entry?;
        let path = entry.path();
        if !path.is_file() {
            continue;
        }
        let Some(name) = path.file_name().and_then(|s| s.to_str()) else {
            continue;
        };
        let Some(created) = parse_ts_zip_filename(name) else {
            continue;
        };
        let size_bytes = fs::metadata(&path).map(|m| m.len()).unwrap_or(0);
        out.push(Snapshot {
            path,
            created,
            size_bytes,
            kind,
            source_timestamp: None,
        });
    }
    out.sort_by(|a, b| b.created.cmp(&a.created));
    Ok(out)
}

/// Parse `YYYYMMDD_HHMMSS.zip` (new auto/manual filename form).
fn parse_ts_zip_filename(name: &str) -> Option<DateTime<Local>> {
    let stem = name.strip_suffix(".zip")?;
    parse_ts(stem)
}

/// Parse `snapshot_<map>_<TS>.zip` (legacy flat auto filename). Returns
/// the embedded `<TS>` as a string so the migrator can use it as the
/// destination filename verbatim.
fn parse_legacy_auto_filename(name: &str) -> Option<String> {
    let stem = name.strip_suffix(".zip")?;
    if !stem.starts_with("snapshot_") {
        return None;
    }
    // Trailing 15-char `YYYYMMDD_HHMMSS` anchor — map names contain `_`
    // so we cannot rely on splitting from the head.
    if stem.len() < 16 {
        return None;
    }
    let (head, tail) = stem.split_at(stem.len() - 15);
    if !head.ends_with('_') {
        return None;
    }
    parse_ts(tail).map(|_| tail.to_string())
}

/// Parse pre_rollback filenames. Accepts both the new layout
/// `from_<SRC>_to_<RB>.zip` and the legacy `pre_rollback_<RB>.zip`.
/// Returns `(created, source_timestamp)` where `created` is the
/// rollback wall-clock time and `source_timestamp` is the source
/// snapshot's `created` if the filename carries it.
fn parse_pre_rollback_filename(
    name: &str,
) -> Option<(DateTime<Local>, Option<DateTime<Local>>)> {
    let stem = name.strip_suffix(".zip")?;
    if let Some(rest) = stem.strip_prefix("from_") {
        let (src, rb) = rest.split_once("_to_")?;
        let src_dt = parse_ts(src)?;
        let rb_dt = parse_ts(rb)?;
        return Some((rb_dt, Some(src_dt)));
    }
    if let Some(rest) = stem.strip_prefix("pre_rollback_") {
        let rb = parse_ts(rest)?;
        return Some((rb, None));
    }
    None
}

/// Parse `YYYYMMDD_HHMMSS` into a local-time DateTime.
fn parse_ts(s: &str) -> Option<DateTime<Local>> {
    if s.len() != 15 {
        return None;
    }
    let (date_part, time_part) = s.split_once('_')?;
    if date_part.len() != 8 || time_part.len() != 6 {
        return None;
    }
    if !date_part.bytes().all(|b| b.is_ascii_digit())
        || !time_part.bytes().all(|b| b.is_ascii_digit())
    {
        return None;
    }
    let naive = NaiveDateTime::parse_from_str(s, TS_FORMAT).ok()?;
    Local.from_local_datetime(&naive).single()
}

/// Choose `<dir>/<stem>.<ext>`, falling back to `<stem>_2.<ext>`,
/// `<stem>_3.<ext>`, … if the user happens to take two snapshots inside
/// the same wall-clock second.
fn unique_path(dir: &Path, stem: &str, ext: &str) -> Result<PathBuf> {
    let candidate = dir.join(format!("{stem}.{ext}"));
    if !candidate.exists() {
        return Ok(candidate);
    }
    for n in 2..1000 {
        let p = dir.join(format!("{stem}_{n}.{ext}"));
        if !p.exists() {
            return Ok(p);
        }
    }
    Err(Error::Other(format!(
        "could not find a free filename in {}",
        dir.display(),
    )))
}

/// Write `src_dir/**` into `dst_zip` at the given compression level.
/// `0` selects STORE (no compression — file-copy speed), `1..=9`
/// selects Deflate at that level. Writes to `<dst_zip>.tmp` first and
/// renames on success so a power-cut leaves only a half-finished
/// `.tmp` rather than a corrupt `.zip`.
fn write_zip_atomic(src_dir: &Path, dst_zip: &Path, compression_level: u8) -> Result<()> {
    let tmp = with_extra_extension(dst_zip, "tmp");
    {
        let file = File::create(&tmp)?;
        let mut writer = ZipWriter::new(BufWriter::new(file));
        let opts = build_file_options(compression_level);
        zip_dir_recursive(src_dir, src_dir, &mut writer, opts)?;
        writer.finish().map_err(zip_to_error)?;
    }
    if dst_zip.exists() {
        fs::remove_file(dst_zip)?;
    }
    fs::rename(&tmp, dst_zip)?;
    Ok(())
}

/// Map our 0..=9 compression-level convention to the zip crate's
/// per-file options. Out-of-range values are clamped silently (corrupt
/// INI shouldn't break the write path).
fn build_file_options(compression_level: u8) -> SimpleFileOptions {
    let level = compression_level.min(9);
    if level == 0 {
        SimpleFileOptions::default()
            .compression_method(CompressionMethod::Stored)
            .unix_permissions(0o644)
    } else {
        SimpleFileOptions::default()
            .compression_method(CompressionMethod::Deflated)
            .compression_level(Some(level as i64))
            .unix_permissions(0o644)
    }
}

fn zip_dir_recursive<W: Write + io::Seek>(
    root: &Path,
    cur: &Path,
    writer: &mut ZipWriter<W>,
    opts: SimpleFileOptions,
) -> Result<()> {
    for entry in fs::read_dir(cur)? {
        let entry = entry?;
        let path = entry.path();
        let rel = path
            .strip_prefix(root)
            .map_err(|_| Error::Other("path escape during zip walk".into()))?;
        let zip_name = rel
            .components()
            .map(|c| c.as_os_str().to_string_lossy())
            .collect::<Vec<_>>()
            .join("/");
        if path.is_dir() {
            // Empty directory entries help `unzip` recreate empty
            // sub-folders (e.g. `LocalProfiles\` if the server has not
            // populated it yet).
            let dir_name = format!("{zip_name}/");
            writer.add_directory(&dir_name, opts).map_err(zip_to_error)?;
            zip_dir_recursive(root, &path, writer, opts)?;
        } else if path.is_file() {
            writer
                .start_file(&zip_name, opts)
                .map_err(zip_to_error)?;
            let mut f = BufReader::new(File::open(&path)?);
            io::copy(&mut f, writer)?;
        }
    }
    Ok(())
}

fn extract_zip_into(zip_path: &Path, dst: &Path) -> Result<()> {
    let file = File::open(zip_path)?;
    let mut archive = ZipArchive::new(BufReader::new(file)).map_err(zip_to_error)?;
    for i in 0..archive.len() {
        let mut entry = archive.by_index(i).map_err(zip_to_error)?;
        // Reject zip entries whose stored path tries to escape `dst`
        // ("zip slip"). enclosed_name returns None when the path is
        // absolute or contains `..` segments.
        let Some(rel) = entry.enclosed_name() else {
            return Err(Error::Other(format!(
                "rejected unsafe zip entry: {}",
                entry.name(),
            )));
        };
        let out_path = dst.join(rel);
        if entry.is_dir() {
            fs::create_dir_all(&out_path)?;
            continue;
        }
        if let Some(p) = out_path.parent() {
            fs::create_dir_all(p)?;
        }
        let mut out = BufWriter::new(File::create(&out_path)?);
        io::copy(&mut entry, &mut out)?;
    }
    Ok(())
}

fn with_extra_extension(p: &Path, extra: &str) -> PathBuf {
    let mut s = p.as_os_str().to_owned();
    s.push(".");
    s.push(extra);
    PathBuf::from(s)
}

fn zip_to_error(e: zip::result::ZipError) -> Error {
    match e {
        zip::result::ZipError::Io(io) => Error::Io(io),
        other => Error::Other(format!("zip error: {other}")),
    }
}

/// Compare two snapshots by `created` for sorting newest-first.
#[allow(dead_code)]
fn cmp_newest_first(a: &Snapshot, b: &Snapshot) -> Ordering {
    b.created.cmp(&a.created)
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;
    use std::sync::atomic::{AtomicU32, Ordering as AtomicOrdering};

    static COUNTER: AtomicU32 = AtomicU32::new(0);

    fn unique_tmp() -> PathBuf {
        let id = COUNTER.fetch_add(1, AtomicOrdering::SeqCst);
        let pid = std::process::id();
        std::env::temp_dir().join(format!("arksa_backup_test_{pid}_{id}"))
    }

    fn write_save_tree(install: &Path, map: &str) {
        let saves = savedarks_dir(install, map);
        fs::create_dir_all(&saves).unwrap();
        fs::write(saves.join(format!("{map}.ark")), b"world-state").unwrap();
        fs::write(saves.join("1234.arktribe"), b"tribe-state").unwrap();
        fs::write(saves.join("76561198.arkprofile"), b"player").unwrap();
        let nested = saves.join("LocalProfiles");
        fs::create_dir_all(&nested).unwrap();
        fs::write(nested.join("PlayerLocal.arkprofile"), b"local").unwrap();
    }

    #[test]
    fn auto_snapshot_then_rollback_restores_files() {
        let install = unique_tmp();
        let map = "TestMap_WP";
        write_save_tree(&install, map);

        let snap = create_auto_snapshot(&install, map, DEFAULT_COMPRESSION_LEVEL).unwrap();
        assert!(snap.path.exists());
        assert_eq!(snap.kind, SnapshotKind::Auto);
        assert!(snap.path.starts_with(auto_dir(&install, map)));

        let live_ark = savedarks_dir(&install, map).join(format!("{map}.ark"));
        fs::write(&live_ark, b"CORRUPT").unwrap();
        rollback(&install, map, &snap.path).unwrap();
        assert_eq!(fs::read(&live_ark).unwrap(), b"world-state");
        assert_eq!(
            fs::read(savedarks_dir(&install, map).join("1234.arktribe")).unwrap(),
            b"tribe-state",
        );

        fs::remove_dir_all(&install).ok();
    }

    #[test]
    fn manual_snapshot_lives_under_manual_subdir() {
        let install = unique_tmp();
        let map = "ManualMap_WP";
        write_save_tree(&install, map);

        let snap = create_manual_snapshot(&install, map, DEFAULT_COMPRESSION_LEVEL).unwrap();
        assert_eq!(snap.kind, SnapshotKind::Manual);
        assert!(snap.path.starts_with(manual_dir(&install, map)));

        // Manual snapshots show up in list_manual, not list_auto.
        assert_eq!(list_auto(&install, map).unwrap().len(), 0);
        assert_eq!(list_manual(&install, map).unwrap().len(), 1);

        fs::remove_dir_all(&install).ok();
    }

    #[test]
    fn pre_rollback_records_source_timestamp() {
        let install = unique_tmp();
        let map = "PreRbMap_WP";
        write_save_tree(&install, map);

        let src = create_auto_snapshot(&install, map, DEFAULT_COMPRESSION_LEVEL).unwrap();
        let src_ts = src.created.format(TS_FORMAT).to_string();
        let pre = create_pre_rollback(&install, map, DEFAULT_COMPRESSION_LEVEL, src.created)
            .unwrap();
        assert_eq!(pre.kind, SnapshotKind::PreRollback);
        // The pre_rollback's `source_timestamp` should map back to the
        // same wall-clock second as the source snapshot. We compare
        // formatted strings because filename timestamps are
        // second-precision while `Local::now()` carries sub-second
        // precision in memory.
        let pre_src_ts = pre
            .source_timestamp
            .expect("source ts on Snapshot")
            .format(TS_FORMAT)
            .to_string();
        assert_eq!(pre_src_ts, src_ts);
        assert!(pre.path.starts_with(pre_rollback_dir(&install, map)));

        // Round-trip the filename through list_pre_rollbacks.
        let listed = list_pre_rollbacks(&install, map).unwrap();
        assert_eq!(listed.len(), 1);
        let parsed_src = listed[0].source_timestamp.expect("source ts parsed");
        assert_eq!(parsed_src.format(TS_FORMAT).to_string(), src_ts);

        fs::remove_dir_all(&install).ok();
    }

    #[test]
    fn enforce_retention_keeps_newest_n_auto_only() {
        let install = unique_tmp();
        let map = "RetMap_WP";
        write_save_tree(&install, map);

        let auto = auto_dir(&install, map);
        let manual = manual_dir(&install, map);
        fs::create_dir_all(&auto).unwrap();
        fs::create_dir_all(&manual).unwrap();
        let stamps = [
            "20260101_010000",
            "20260101_020000",
            "20260101_030000",
            "20260101_040000",
            "20260101_050000",
            "20260101_060000",
        ];
        for ts in stamps {
            fs::write(auto.join(format!("{ts}.zip")), b"x").unwrap();
        }
        // A manual snapshot must survive retention even with the same
        // timestamp.
        fs::write(manual.join("20260101_010000.zip"), b"m").unwrap();

        let removed = enforce_retention(&install, map, 3).unwrap();
        assert_eq!(removed, 3);
        let remaining = list_auto(&install, map).unwrap();
        assert_eq!(remaining.len(), 3);
        let names: Vec<String> = remaining
            .iter()
            .map(|s| s.path.file_name().unwrap().to_string_lossy().into_owned())
            .collect();
        assert!(names[0].contains("20260101_060000"));
        assert!(names[2].contains("20260101_040000"));
        // Manual untouched.
        assert_eq!(list_manual(&install, map).unwrap().len(), 1);

        fs::remove_dir_all(&install).ok();
    }

    #[test]
    fn migrate_legacy_layout_moves_flat_snapshots() {
        let install = unique_tmp();
        let map = "LegacyMap_WP";
        write_save_tree(&install, map);
        let root = backup_root(&install, map);
        fs::create_dir_all(&root).unwrap();
        // Two legacy auto snapshots at the old flat location.
        fs::write(
            root.join(format!("snapshot_{map}_20260101_010000.zip")),
            b"x",
        )
        .unwrap();
        fs::write(
            root.join(format!("snapshot_{map}_20260101_020000.zip")),
            b"y",
        )
        .unwrap();
        // Unrelated file at root must be left alone.
        fs::write(root.join("README.txt"), b"hi").unwrap();

        let moved = migrate_legacy_layout(&install, map).unwrap();
        assert_eq!(moved, 2);
        // Old flat files gone, new auto/ files exist with `<TS>.zip`.
        let auto = auto_dir(&install, map);
        assert!(auto.join("20260101_010000.zip").exists());
        assert!(auto.join("20260101_020000.zip").exists());
        assert!(root.join("README.txt").exists());
        assert!(!root
            .join(format!("snapshot_{map}_20260101_010000.zip"))
            .exists());

        // list_auto picks them up after migration.
        assert_eq!(list_auto(&install, map).unwrap().len(), 2);

        fs::remove_dir_all(&install).ok();
    }

    #[test]
    fn legacy_pre_rollback_filename_parses_without_source() {
        let install = unique_tmp();
        let map = "LegacyPreRb_WP";
        write_save_tree(&install, map);
        let dir = pre_rollback_dir(&install, map);
        fs::create_dir_all(&dir).unwrap();
        fs::write(dir.join("pre_rollback_20260101_010000.zip"), b"x").unwrap();

        let listed = list_pre_rollbacks(&install, map).unwrap();
        assert_eq!(listed.len(), 1);
        assert!(listed[0].source_timestamp.is_none());

        fs::remove_dir_all(&install).ok();
    }

    #[test]
    fn snapshot_with_no_compression_round_trips() {
        let install = unique_tmp();
        let map = "StoreMap_WP";
        write_save_tree(&install, map);

        let snap = create_auto_snapshot(&install, map, 0).unwrap();
        assert!(snap.path.exists());
        let live = savedarks_dir(&install, map).join(format!("{map}.ark"));
        std::fs::write(&live, b"changed").unwrap();
        rollback(&install, map, &snap.path).unwrap();
        assert_eq!(std::fs::read(&live).unwrap(), b"world-state");

        std::fs::remove_dir_all(&install).ok();
    }

    #[test]
    fn delete_snapshot_removes_file_inside_backup_tree() {
        let install = unique_tmp();
        let map = "DelMap_WP";
        write_save_tree(&install, map);
        let snap = create_auto_snapshot(&install, map, DEFAULT_COMPRESSION_LEVEL).unwrap();
        assert!(snap.path.exists());
        delete_snapshot(&install, &snap.path).unwrap();
        assert!(!snap.path.exists());
        assert!(list_auto(&install, map).unwrap().is_empty());
        std::fs::remove_dir_all(&install).ok();
    }

    #[test]
    fn delete_snapshot_refuses_paths_outside_backup_tree() {
        let install = unique_tmp();
        let map = "DelGuardMap_WP";
        write_save_tree(&install, map);
        let unrelated = install.join("important.txt");
        std::fs::write(&unrelated, b"do not delete").unwrap();
        let err = delete_snapshot(&install, &unrelated).unwrap_err();
        assert!(format!("{err}").contains("outside the backup tree"));
        assert!(unrelated.exists());
        std::fs::remove_dir_all(&install).ok();
    }

    #[test]
    fn parse_pre_rollback_filename_extracts_source() {
        let parsed = parse_pre_rollback_filename(
            "from_20260101_010000_to_20260101_020000.zip",
        )
        .unwrap();
        // Source ts present and parsed.
        assert!(parsed.1.is_some());
        let src = parsed.1.unwrap();
        assert_eq!(src.format("%Y%m%d_%H%M%S").to_string(), "20260101_010000");
        // Created (rollback time) parsed too.
        assert_eq!(
            parsed.0.format("%Y%m%d_%H%M%S").to_string(),
            "20260101_020000",
        );

        // Garbage filename rejected.
        assert!(parse_pre_rollback_filename("garbage.zip").is_none());
    }
}

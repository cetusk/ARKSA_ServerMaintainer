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
//!     snapshot_<MapName>_YYYYMMDD_HHMMSS.zip      // periodic, ring buffer
//!     pre_rollback\
//!         pre_rollback_YYYYMMDD_HHMMSS.zip        // emergency, last 3
//! ```
//!
//! `ARKSA_Backups\` lives at install root (sibling of `ShooterGame\` /
//! `Engine\` / `steamapps\`) so future engine updates that reorganise
//! `Saved\` cannot collide with our directory.

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

/// `<install>\ARKSA_Backups\<MapName>\pre_rollback\`.
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
    /// Periodic snapshot inside `ARKSA_Backups\<MapName>\`. Subject to
    /// the user's retention policy (T-hour cycle, N count).
    Periodic,
    /// Emergency snapshot taken just before a rollback. Lives in
    /// `pre_rollback\` and is capped at [`MAX_PRE_ROLLBACK`].
    PreRollback,
}

#[derive(Debug, Clone)]
pub struct Snapshot {
    pub path: PathBuf,
    pub created: DateTime<Local>,
    pub size_bytes: u64,
    pub kind: SnapshotKind,
}

/// Create a periodic snapshot of `<install>\…\SavedArks\<MapName>\`,
/// writing to `<install>\ARKSA_Backups\<MapName>\snapshot_<MapName>_<TS>.zip`.
///
/// `compression_level` is `0` for STORE (no compression — file-copy
/// speed) or `1..=9` for Deflate (1 fastest, 9 smallest). Anything out
/// of range is clamped.
///
/// Returns the new snapshot. Does **not** apply retention — call
/// [`enforce_retention`] separately so callers can decide whether to
/// rotate (e.g. after a successful save vs. before).
pub fn create_snapshot(
    install_root: &Path,
    map_name: &str,
    compression_level: u8,
) -> Result<Snapshot> {
    let src = savedarks_dir(install_root, map_name);
    if !src.is_dir() {
        return Err(Error::Other(format!(
            "SavedArks directory not found: {}",
            src.display(),
        )));
    }
    let dst_dir = backup_root(install_root, map_name);
    fs::create_dir_all(&dst_dir)?;
    let now = Local::now();
    let zip_path = unique_path(
        &dst_dir,
        &format!(
            "snapshot_{}_{}",
            map_name,
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
        kind: SnapshotKind::Periodic,
    })
}

/// Create an emergency `pre_rollback` snapshot. Same contents as
/// [`create_snapshot`] but written to the `pre_rollback\` subfolder so
/// it survives the periodic ring buffer.
///
/// Uses the same compression-level convention as [`create_snapshot`].
pub fn create_pre_rollback(
    install_root: &Path,
    map_name: &str,
    compression_level: u8,
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
        &format!("pre_rollback_{}", now.format(TS_FORMAT)),
        "zip",
    )?;
    write_zip_atomic(&src, &zip_path, compression_level)?;
    let size_bytes = fs::metadata(&zip_path)?.len();
    Ok(Snapshot {
        path: zip_path,
        created: now,
        size_bytes,
        kind: SnapshotKind::PreRollback,
    })
}

/// List periodic snapshots, newest first. Missing directory → empty list
/// (not an error: user just hasn't taken any backups yet).
pub fn list_snapshots(install_root: &Path, map_name: &str) -> Result<Vec<Snapshot>> {
    let dir = backup_root(install_root, map_name);
    list_dir_snapshots(&dir, "snapshot_", SnapshotKind::Periodic)
}

/// List pre_rollback snapshots, newest first.
pub fn list_pre_rollbacks(install_root: &Path, map_name: &str) -> Result<Vec<Snapshot>> {
    let dir = pre_rollback_dir(install_root, map_name);
    list_dir_snapshots(&dir, "pre_rollback_", SnapshotKind::PreRollback)
}

/// Delete the oldest periodic snapshots until at most `retain_count`
/// remain. Returns the number deleted. `retain_count == 0` would wipe
/// everything; we guard with `max(1)` to avoid that footgun.
pub fn enforce_retention(
    install_root: &Path,
    map_name: &str,
    retain_count: u32,
) -> Result<u32> {
    let keep = retain_count.max(1) as usize;
    let snapshots = list_snapshots(install_root, map_name)?;
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

// ---------------------------------------------------------------------------
// internals
// ---------------------------------------------------------------------------

fn list_dir_snapshots(
    dir: &Path,
    prefix: &str,
    kind: SnapshotKind,
) -> Result<Vec<Snapshot>> {
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
        if !name.starts_with(prefix) || !name.ends_with(".zip") {
            continue;
        }
        let Some(created) = parse_filename_timestamp(name) else {
            continue;
        };
        let size_bytes = fs::metadata(&path).map(|m| m.len()).unwrap_or(0);
        out.push(Snapshot {
            path,
            created,
            size_bytes,
            kind,
        });
    }
    out.sort_by(|a, b| b.created.cmp(&a.created));
    Ok(out)
}

/// Pull `YYYYMMDD_HHMMSS` out of `*_<YYYYMMDD>_<HHMMSS>.zip`. The map
/// name in periodic snapshots can contain underscores ("Aberration_WP"),
/// so we anchor on the trailing `<8>_<6>.zip` instead of splitting from
/// the front.
fn parse_filename_timestamp(name: &str) -> Option<DateTime<Local>> {
    let stem = name.strip_suffix(".zip")?;
    let bytes = stem.as_bytes();
    if bytes.len() < 16 {
        return None;
    }
    // Trailing pattern: `_YYYYMMDD_HHMMSS` (16 chars).
    let (head, tail) = stem.split_at(stem.len() - 15);
    if !head.ends_with('_') {
        return None;
    }
    let (date_part, time_part) = tail.split_once('_')?;
    if date_part.len() != 8 || time_part.len() != 6 {
        return None;
    }
    if !date_part.bytes().all(|b| b.is_ascii_digit())
        || !time_part.bytes().all(|b| b.is_ascii_digit())
    {
        return None;
    }
    let combined = format!("{date_part}_{time_part}");
    let naive = NaiveDateTime::parse_from_str(&combined, TS_FORMAT).ok()?;
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
    fn snapshot_then_rollback_restores_files() {
        let install = unique_tmp();
        let map = "TestMap_WP";
        write_save_tree(&install, map);

        let snap = create_snapshot(&install, map, DEFAULT_COMPRESSION_LEVEL).unwrap();
        assert!(snap.path.exists());
        assert_eq!(snap.kind, SnapshotKind::Periodic);

        // Mutate the live save then roll back.
        let live_ark = savedarks_dir(&install, map).join(format!("{map}.ark"));
        fs::write(&live_ark, b"CORRUPT").unwrap();
        rollback(&install, map, &snap.path).unwrap();
        assert_eq!(fs::read(&live_ark).unwrap(), b"world-state");
        // Companion files survive the round trip.
        assert_eq!(
            fs::read(savedarks_dir(&install, map).join("1234.arktribe")).unwrap(),
            b"tribe-state",
        );
        assert!(savedarks_dir(&install, map)
            .join("LocalProfiles")
            .join("PlayerLocal.arkprofile")
            .exists());

        fs::remove_dir_all(&install).ok();
    }

    #[test]
    fn pre_rollback_lives_under_pre_rollback_subdir() {
        let install = unique_tmp();
        let map = "TestMap2_WP";
        write_save_tree(&install, map);

        let snap = create_pre_rollback(&install, map, DEFAULT_COMPRESSION_LEVEL).unwrap();
        assert_eq!(snap.kind, SnapshotKind::PreRollback);
        assert!(snap.path.starts_with(pre_rollback_dir(&install, map)));

        let listed = list_pre_rollbacks(&install, map).unwrap();
        assert_eq!(listed.len(), 1);
        assert_eq!(listed[0].path, snap.path);

        fs::remove_dir_all(&install).ok();
    }

    #[test]
    fn enforce_retention_keeps_newest_n() {
        let install = unique_tmp();
        let map = "TestMap3_WP";
        write_save_tree(&install, map);

        let dst = backup_root(&install, map);
        fs::create_dir_all(&dst).unwrap();
        // Hand-craft six snapshot files with monotonically increasing
        // timestamps so the retention sort has something to chew on.
        let stamps = [
            "20260101_010000",
            "20260101_020000",
            "20260101_030000",
            "20260101_040000",
            "20260101_050000",
            "20260101_060000",
        ];
        for ts in stamps {
            let p = dst.join(format!("snapshot_{map}_{ts}.zip"));
            fs::write(&p, b"x").unwrap();
        }

        let removed = enforce_retention(&install, map, 3).unwrap();
        assert_eq!(removed, 3);
        let remaining = list_snapshots(&install, map).unwrap();
        assert_eq!(remaining.len(), 3);
        // Newest three kept (06, 05, 04).
        let names: Vec<String> = remaining
            .iter()
            .map(|s| s.path.file_name().unwrap().to_string_lossy().into_owned())
            .collect();
        assert!(names[0].contains("20260101_060000"));
        assert!(names[2].contains("20260101_040000"));

        fs::remove_dir_all(&install).ok();
    }

    #[test]
    fn snapshot_with_no_compression_round_trips() {
        // STORE (level 0) is the speed-priority option for users with
        // big saves; the round-trip must preserve bytes exactly.
        let install = unique_tmp();
        let map = "StoreMap_WP";
        write_save_tree(&install, map);

        let snap = create_snapshot(&install, map, 0).unwrap();
        assert!(snap.path.exists());
        // Mutate the live save and roll back from the STORE snapshot.
        let live = savedarks_dir(&install, map).join(format!("{map}.ark"));
        std::fs::write(&live, b"changed").unwrap();
        rollback(&install, map, &snap.path).unwrap();
        assert_eq!(std::fs::read(&live).unwrap(), b"world-state");

        std::fs::remove_dir_all(&install).ok();
    }

    #[test]
    fn parse_filename_timestamp_handles_underscored_map_name() {
        // Map names like Aberration_WP have an underscore so the
        // trailing-anchor parser is the right approach.
        let ts = parse_filename_timestamp("snapshot_Aberration_WP_20260509_140000.zip");
        assert!(ts.is_some());
        let bad = parse_filename_timestamp("snapshot_Aberration_WP_no-timestamp.zip");
        assert!(bad.is_none());
    }
}

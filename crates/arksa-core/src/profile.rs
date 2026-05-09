//! Per-server profile INI handling. Storage layout matches upstream so existing
//! `Profile/<name>.ini` files load without conversion:
//!
//!   [ASASM]      AppVersion / ChB_AutoRestart / ...
//!   [General]    Edit_Profile / Edit_Install_Location_Val / Sys_RelativePath /
//!                CB_MapName_Text / Edit_Mods / ...
//!   [Server]     Edit_SessionName / SE_Port / SE_QueryPort /
//!                Edit_ServerAdminPassword / CB_RCONEnabled / SE_RCONPort / ...
//!   [World] [VisualHUD] [Player] [TamedDino] [Wiladino] [Spawn] [Spawn2]
//!   [Structure] [Engrams] [XP] [iniFiles] [Experimental]
//!
//! Phase 1 only types the keys needed to start/stop a server and connect via
//! RCON. Everything else round-trips through `IniDoc` untouched, so writing a
//! profile back never silently drops settings we have not modelled yet.

use std::path::{Path, PathBuf};

use crate::ark_config;
use crate::error::{Error, Result};
use crate::ini_doc::IniDoc;
use crate::launch_args::{self, LaunchArgs};

pub const SECTION_ASASM: &str = "ASASM";
pub const SECTION_GENERAL: &str = "General";
pub const SECTION_SERVER: &str = "Server";

/// Mirror of `Profile::resolved_install_path` available at construction time.
/// We need this in `create_new` before we have a `Profile` object to call.
fn resolve_install_root(
    profiles_dir: &Path,
    install_location: &str,
    relative_path: bool,
) -> PathBuf {
    if relative_path {
        // `profiles_dir` is `<ARKSA_DIR>/Profile`, so its parent is `<ARKSA_DIR>`.
        let arksa_dir = profiles_dir.parent().unwrap_or(profiles_dir);
        arksa_dir.join(install_location)
    } else {
        PathBuf::from(install_location)
    }
}

#[derive(Debug, Clone)]
pub struct Profile {
    /// Path the profile was loaded from (or will be saved to).
    path: PathBuf,
    doc: IniDoc,
}

impl Profile {
    /// Load `Profile/<name>.ini`.
    pub fn load(path: impl AsRef<Path>) -> Result<Self> {
        let path = path.as_ref().to_path_buf();
        if !path.exists() {
            return Err(crate::Error::ProfileNotFound(path.display().to_string()));
        }
        let doc = IniDoc::load(&path)?;
        Ok(Self { path, doc })
    }

    pub fn empty_at(path: impl Into<PathBuf>) -> Self {
        Self {
            path: path.into(),
            doc: IniDoc::new(),
        }
    }

    /// Build a brand-new profile from `args`, persisting it under
    /// `<profiles_dir>/<file_stem>.ini`.
    ///
    /// `display_name` is what the user sees in the profile picker; the file
    /// stem comes from `file_stem` (sanitised by the caller — we reject paths
    /// that would escape `profiles_dir`).
    ///
    /// Errors when the destination file already exists, so the GUI can ask the
    /// user before overwriting.
    pub fn create_new(
        profiles_dir: &Path,
        file_stem: &str,
        display_name: &str,
        install_location: &str,
        relative_path: bool,
        args: &LaunchArgs,
    ) -> Result<Self> {
        if file_stem.is_empty()
            || file_stem.contains(['/', '\\', ':', '*', '?', '"', '<', '>', '|'])
        {
            return Err(Error::Other(format!(
                "invalid profile file name: {file_stem:?}"
            )));
        }
        let path = profiles_dir.join(format!("{file_stem}.ini"));
        if path.exists() {
            return Err(Error::Other(format!(
                "profile already exists: {}",
                path.display()
            )));
        }

        let mut profile = Self::empty_at(path);
        profile.set_display_name(display_name);
        profile.set_install_location(install_location);
        profile.set_relative_path(relative_path);
        profile.set_map_name(&args.map);
        profile.set_auto_restart(false);

        // [Server] keys consumed by stop_graceful() / status display.
        profile
            .doc_mut()
            .set_string(SECTION_SERVER, "Edit_SessionName", &args.session_name);
        profile
            .doc_mut()
            .set_i64(SECTION_SERVER, "SE_Port", args.game_port as i64);
        profile
            .doc_mut()
            .set_i64(SECTION_SERVER, "SE_QueryPort", args.query_port as i64);
        profile
            .doc_mut()
            .set_bool(SECTION_SERVER, "CB_RCONEnabled", args.rcon_enabled);
        profile
            .doc_mut()
            .set_i64(SECTION_SERVER, "SE_RCONPort", args.rcon_port as i64);
        profile.doc_mut().set_string(
            SECTION_SERVER,
            "Edit_ServerAdminPassword",
            &args.admin_password,
        );
        profile.doc_mut().set_string(
            SECTION_SERVER,
            "Edit_ServerPassword",
            &args.server_password,
        );

        // Pre-assembled launch line consumed by server::start().
        profile.set_server_command_line(&launch_args::build_command_line(args));

        profile.save()?;

        // Mirror RCON-relevant settings into GameUserSettings.ini at the
        // install root. The URL form of these keys cannot be relied on (see
        // launch_args::build_command_line for the rationale), so we write
        // them directly into the file ARK actually consults at startup. The
        // file may not yet exist (the user has not run "Install / Update
        // server") — load_or_empty handles that, and parent directories are
        // created on save().
        let install_root = resolve_install_root(profiles_dir, install_location, relative_path);
        let gus_path = ark_config::game_user_settings_path(&install_root);
        ark_config::write_rcon_settings(
            &gus_path,
            args.rcon_enabled,
            args.rcon_port,
            &args.admin_password,
        )?;

        Ok(profile)
    }

    pub fn save(&self) -> Result<()> {
        self.doc.save(&self.path)
    }

    pub fn save_as(&mut self, path: impl Into<PathBuf>) -> Result<()> {
        self.path = path.into();
        self.save()
    }

    pub fn path(&self) -> &Path {
        &self.path
    }

    pub fn doc(&self) -> &IniDoc {
        &self.doc
    }

    pub fn doc_mut(&mut self) -> &mut IniDoc {
        &mut self.doc
    }

    // ---- [General] -----------------------------------------------------------

    /// Display name shown on the profile tab. Independent of the file basename
    /// (the user can rename the profile in-app without renaming the .ini).
    pub fn display_name(&self) -> Option<String> {
        self.doc.get_string(SECTION_GENERAL, "Edit_Profile")
    }

    pub fn set_display_name(&mut self, name: &str) {
        self.doc.set_string(SECTION_GENERAL, "Edit_Profile", name);
    }

    /// Server install directory. May be relative to the ASASM executable when
    /// `Sys_RelativePath = 1`.
    pub fn install_location(&self) -> Option<String> {
        self.doc
            .get_string(SECTION_GENERAL, "Edit_Install_Location_Val")
    }

    pub fn set_install_location(&mut self, location: &str) {
        self.doc
            .set_string(SECTION_GENERAL, "Edit_Install_Location_Val", location);
    }

    /// Whether `install_location()` should be resolved relative to the
    /// executable directory.
    pub fn is_relative_path(&self) -> bool {
        self.doc
            .get_bool(SECTION_GENERAL, "Sys_RelativePath")
            .unwrap_or(false)
    }

    pub fn set_relative_path(&mut self, relative: bool) {
        self.doc
            .set_bool(SECTION_GENERAL, "Sys_RelativePath", relative);
    }

    /// Map name as the user typed/selected it (e.g. "TheIsland_WP").
    pub fn map_name(&self) -> Option<String> {
        self.doc.get_string(SECTION_GENERAL, "CB_MapName_Text")
    }

    pub fn set_map_name(&mut self, map: &str) {
        self.doc
            .set_string(SECTION_GENERAL, "CB_MapName_Text", map);
    }

    // ---- [General] backup ----------------------------------------------------

    /// Whether the GUI scheduler should take periodic SavedArks zip
    /// snapshots for this profile. Upstream ASASM stores the same flag
    /// under `[General] ChB_AutoBackup`, so loading an existing profile
    /// keeps its previous toggle state.
    pub fn auto_backup_enabled(&self) -> bool {
        self.doc
            .get_bool(SECTION_GENERAL, "ChB_AutoBackup")
            .unwrap_or(false)
    }

    pub fn set_auto_backup_enabled(&mut self, enabled: bool) {
        self.doc
            .set_bool(SECTION_GENERAL, "ChB_AutoBackup", enabled);
    }

    /// Period between automatic snapshots, in minutes. Default 30 (one
    /// per half hour) matches the planned default in `arksa-core::backup`.
    /// Clamped to `[1, 7 * 24 * 60]` on read so a corrupt INI can't push
    /// the scheduler into either a tight loop or "never fires".
    pub fn backup_interval_minutes(&self) -> u32 {
        let raw = self
            .doc
            .get_i64(SECTION_GENERAL, "SE_BackupIntervalMinutes")
            .unwrap_or(30);
        raw.clamp(1, 7 * 24 * 60) as u32
    }

    pub fn set_backup_interval_minutes(&mut self, minutes: u32) {
        let clamped = minutes.clamp(1, 7 * 24 * 60);
        self.doc
            .set_i64(SECTION_GENERAL, "SE_BackupIntervalMinutes", clamped as i64);
    }

    /// Number of periodic snapshots to retain. Default 12 (12 × 0.5h =
    /// 6h of history). Clamped to `[1, 1024]`.
    pub fn backup_retain_count(&self) -> u32 {
        let raw = self
            .doc
            .get_i64(SECTION_GENERAL, "SE_BackupRetainCount")
            .unwrap_or(12);
        raw.clamp(1, 1024) as u32
    }

    pub fn set_backup_retain_count(&mut self, count: u32) {
        let clamped = count.clamp(1, 1024);
        self.doc
            .set_i64(SECTION_GENERAL, "SE_BackupRetainCount", clamped as i64);
    }

    /// Resolved absolute path to the server install directory, given the
    /// directory containing the ARKSA tool executable.
    pub fn resolved_install_path(&self, exe_dir: &Path) -> Option<PathBuf> {
        let raw = self.install_location()?;
        if self.is_relative_path() {
            Some(exe_dir.join(raw))
        } else {
            Some(PathBuf::from(raw))
        }
    }

    /// Path to `ArkAscendedServer.exe` for this profile, given the directory
    /// containing the ARKSA tool executable.
    pub fn server_exe_path(&self, exe_dir: &Path) -> Option<PathBuf> {
        let install = self.resolved_install_path(exe_dir)?;
        Some(
            install
                .join("ShooterGame")
                .join("Binaries")
                .join("Win64")
                .join("ArkAscendedServer.exe"),
        )
    }

    // ---- [Server] ------------------------------------------------------------

    pub fn session_name(&self) -> Option<String> {
        self.doc.get_string(SECTION_SERVER, "Edit_SessionName")
    }

    pub fn game_port(&self) -> Option<u16> {
        self.doc
            .get_i64(SECTION_SERVER, "SE_Port")
            .and_then(|n| u16::try_from(n).ok())
    }

    pub fn query_port(&self) -> Option<u16> {
        self.doc
            .get_i64(SECTION_SERVER, "SE_QueryPort")
            .and_then(|n| u16::try_from(n).ok())
    }

    /// RCON listen port. Upstream uses `SE_RCONPort` here.
    pub fn rcon_port(&self) -> Option<u16> {
        self.doc
            .get_i64(SECTION_SERVER, "SE_RCONPort")
            .and_then(|n| u16::try_from(n).ok())
    }

    pub fn rcon_enabled(&self) -> bool {
        self.doc
            .get_bool(SECTION_SERVER, "CB_RCONEnabled")
            .unwrap_or(false)
    }

    /// Admin password, used as the RCON auth password.
    pub fn admin_password(&self) -> Option<String> {
        self.doc
            .get_string(SECTION_SERVER, "Edit_ServerAdminPassword")
    }

    pub fn server_password(&self) -> Option<String> {
        self.doc.get_string(SECTION_SERVER, "Edit_ServerPassword")
    }

    /// User-supplied address that public clients use to reach the
    /// server. Typical contents are a playit.gg tunnel hostname/port,
    /// a Tailscale machine name, or the operator's public IP. Empty
    /// when the profile hasn't recorded one — the GUI surfaces the
    /// field as just an editable line that the user can copy.
    ///
    /// Stored as `[Server] Edit_PublicAddress` so the upstream Pascal
    /// app's INI parser (which round-trips unknown keys) doesn't drop
    /// it on save.
    pub fn public_address(&self) -> Option<String> {
        self.doc
            .get_string(SECTION_SERVER, "Edit_PublicAddress")
            .map(|s| s.trim().to_string())
            .filter(|s| !s.is_empty())
    }

    pub fn set_public_address(&mut self, address: &str) {
        self.doc
            .set_string(SECTION_SERVER, "Edit_PublicAddress", address.trim());
    }

    // ---- [General] command line ---------------------------------------------

    /// Pre-assembled ARK SA server command line stored by upstream's UI as a
    /// single string in `[General] MM_Command_Val`. Begins with
    /// `ArkAscendedServer.exe ` followed by `?`-separated map options and any
    /// `-flag` arguments. Phase 2 honours this verbatim; a structured editor
    /// can replace it later.
    ///
    /// `MM_Command_Override` is preferred when present, mirroring how
    /// `frameui.pas` lets advanced users hand-tune the launch line.
    pub fn server_command_line(&self) -> Option<String> {
        let override_active = self
            .doc
            .get_bool(SECTION_GENERAL, "ChB_CMD_override")
            .unwrap_or(false);
        if override_active {
            if let Some(s) = self.doc.get_string(SECTION_GENERAL, "MM_Command_Override") {
                let trimmed = s.trim().to_string();
                if !trimmed.is_empty() {
                    return Some(trimmed);
                }
            }
        }
        self.doc
            .get_string(SECTION_GENERAL, "MM_Command_Val")
            .map(|s| s.trim().to_string())
            .filter(|s| !s.is_empty())
    }

    pub fn set_server_command_line(&mut self, cmd: &str) {
        self.doc
            .set_string(SECTION_GENERAL, "MM_Command_Val", cmd);
    }

    // ---- [ASASM] -------------------------------------------------------------

    pub fn auto_restart(&self) -> bool {
        self.doc
            .get_bool(SECTION_ASASM, "ChB_AutoRestart")
            .unwrap_or(false)
    }

    pub fn set_auto_restart(&mut self, enabled: bool) {
        self.doc
            .set_bool(SECTION_ASASM, "ChB_AutoRestart", enabled);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn sample_ini() -> &'static str {
        // Trimmed version of an actual upstream Profile/<name>.ini.
        r#"[ASASM]
Appversion=0.5.1.3038
ChB_AutoRestart=1

[General]
Edit_Profile=My Island
Sys_RelativePath=1
Edit_Install_Location_Val=ark001
CB_MapName_Text=TheIsland_WP
ChB_AutoBackup=0

[Server]
Edit_SessionName=cetusk's server
SE_Port=7777
SE_QueryPort=27015
SE_RCONPort=27020
CB_RCONEnabled=1
Edit_ServerAdminPassword=hunter2
"#
    }

    #[test]
    fn typed_accessors_read_known_keys() {
        let doc = IniDoc::load_bytes(sample_ini().as_bytes()).unwrap();
        let profile = Profile {
            path: PathBuf::from("test.ini"),
            doc,
        };
        assert_eq!(profile.display_name().as_deref(), Some("My Island"));
        assert_eq!(profile.install_location().as_deref(), Some("ark001"));
        assert!(profile.is_relative_path());
        assert_eq!(profile.map_name().as_deref(), Some("TheIsland_WP"));
        assert_eq!(profile.game_port(), Some(7777));
        assert_eq!(profile.rcon_port(), Some(27020));
        assert!(profile.rcon_enabled());
        assert_eq!(profile.admin_password().as_deref(), Some("hunter2"));
        assert!(profile.auto_restart());
        // Sample INI has the upstream `ChB_AutoBackup=0`, so the new
        // accessor should report disabled with default interval/retain.
        assert!(!profile.auto_backup_enabled());
        assert_eq!(profile.backup_interval_minutes(), 30);
        assert_eq!(profile.backup_retain_count(), 12);
    }

    #[test]
    fn backup_setters_round_trip_and_clamp() {
        let mut profile = Profile {
            path: PathBuf::from("test.ini"),
            doc: IniDoc::new(),
        };
        // Defaults when no key is present.
        assert!(!profile.auto_backup_enabled());
        assert_eq!(profile.backup_interval_minutes(), 30);
        assert_eq!(profile.backup_retain_count(), 12);

        profile.set_auto_backup_enabled(true);
        profile.set_backup_interval_minutes(120);
        profile.set_backup_retain_count(48);
        assert!(profile.auto_backup_enabled());
        assert_eq!(profile.backup_interval_minutes(), 120);
        assert_eq!(profile.backup_retain_count(), 48);

        // Clamped on write so corrupt or malicious values can't make
        // the scheduler spin or never fire.
        profile.set_backup_interval_minutes(0);
        assert_eq!(profile.backup_interval_minutes(), 1);
        profile.set_backup_retain_count(99_999);
        assert_eq!(profile.backup_retain_count(), 1024);
    }

    #[test]
    fn resolves_relative_install_path() {
        let doc = IniDoc::load_bytes(sample_ini().as_bytes()).unwrap();
        let profile = Profile {
            path: PathBuf::from("test.ini"),
            doc,
        };
        let exe_dir = Path::new("/opt/arksa");
        assert_eq!(
            profile.resolved_install_path(exe_dir),
            Some(PathBuf::from("/opt/arksa/ark001"))
        );
        assert_eq!(
            profile.server_exe_path(exe_dir),
            Some(PathBuf::from(
                "/opt/arksa/ark001/ShooterGame/Binaries/Win64/ArkAscendedServer.exe"
            ))
        );
    }

    #[test]
    fn create_new_writes_required_keys() {
        use crate::launch_args::LaunchArgs;
        let dir = std::env::temp_dir().join(format!(
            "arksa_profile_create_{}",
            std::process::id()
        ));
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let mut args = LaunchArgs::defaults();
        args.admin_password = "fixed-pw".into();
        args.session_name = "Test Session".into();
        let prof = Profile::create_new(
            &dir,
            "TestProfile",
            "Test Display",
            "ark001",
            true,
            &args,
        )
        .unwrap();

        // Reload from disk to ensure the file is fully self-describing.
        let reloaded = Profile::load(prof.path()).unwrap();
        assert_eq!(reloaded.display_name().as_deref(), Some("Test Display"));
        assert_eq!(reloaded.install_location().as_deref(), Some("ark001"));
        assert!(reloaded.is_relative_path());
        assert_eq!(reloaded.map_name().as_deref(), Some(args.map.as_str()));
        assert_eq!(reloaded.game_port(), Some(args.game_port));
        assert_eq!(reloaded.rcon_port(), Some(args.rcon_port));
        assert!(reloaded.rcon_enabled());
        assert_eq!(reloaded.admin_password().as_deref(), Some("fixed-pw"));
        let cmd = reloaded.server_command_line().unwrap();
        assert!(cmd.starts_with("ArkAscendedServer.exe TheIsland_WP?listen"));
        // ServerAdminPassword / RCONEnabled / RCONPort live in
        // GameUserSettings.ini now (URL parser corruption workaround), so
        // they must NOT appear in the launch line.
        assert!(!cmd.contains("ServerAdminPassword"));
        assert!(!cmd.contains("RCONEnabled"));
        assert!(!cmd.contains("RCONPort"));

        // The matching values must show up in GameUserSettings.ini under the
        // install root we declared (which here is `<tmp_dir>/../ark001`).
        let arksa_dir = dir.parent().unwrap();
        let install_root = arksa_dir.join("ark001");
        let gus_path = crate::ark_config::game_user_settings_path(&install_root);
        let gus = crate::ark_config::GameUserSettings::load_or_empty(&gus_path).unwrap();
        assert_eq!(gus.rcon_enabled(), Some(true));
        assert_eq!(gus.rcon_port(), Some(args.rcon_port));
        assert_eq!(gus.admin_password().as_deref(), Some("fixed-pw"));
        let _ = std::fs::remove_dir_all(install_root);

        // Repeating the create should fail with "already exists".
        let again = Profile::create_new(
            &dir,
            "TestProfile",
            "x",
            "ark001",
            true,
            &args,
        );
        assert!(again.is_err());

        // Reject filenames with path-separator characters.
        let bad = Profile::create_new(&dir, "bad/name", "x", "ark001", true, &args);
        assert!(bad.is_err());

        let _ = std::fs::remove_dir_all(dir);
    }

    #[test]
    fn round_trips_unknown_keys() {
        let original = "[General]\nEdit_Profile=foo\nUnknownKey=preserve me\n";
        let doc = IniDoc::load_bytes(original.as_bytes()).unwrap();
        let mut profile = Profile {
            path: PathBuf::from("/tmp/x.ini"),
            doc,
        };
        profile.set_display_name("bar");

        // Re-render and reload to assert the unknown key survives.
        let tmp = std::env::temp_dir().join("arksa_profile_roundtrip.ini");
        profile.path = tmp.clone();
        profile.save().unwrap();
        let reloaded = Profile::load(&tmp).unwrap();
        assert_eq!(reloaded.display_name().as_deref(), Some("bar"));
        assert_eq!(
            reloaded.doc().get_string("General", "UnknownKey").as_deref(),
            Some("preserve me")
        );
        let _ = std::fs::remove_file(tmp);
    }
}

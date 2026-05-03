//! ARK SA dedicated server config files (`GameUserSettings.ini`, `Game.ini`).
//!
//! Authoritative for settings that ARK SA's URL parser cannot accept reliably:
//! `ServerAdminPassword`, `RCONEnabled`, `RCONPort`. Putting these in the
//! launch URL leads to value corruption (the rest of the URL gets folded into
//! the password string) and silently disables RCON. Writing them straight
//! into `[ServerSettings]` of `GameUserSettings.ini` bypasses the bug, and
//! the URL parser ignores keys it does not see.

use std::path::{Path, PathBuf};

use crate::error::Result;
use crate::ini_doc::IniDoc;

/// `[ServerSettings]` section in `GameUserSettings.ini`.
pub const SECTION_SERVER_SETTINGS: &str = "ServerSettings";

/// Resolve the canonical `GameUserSettings.ini` path beneath an install root,
/// e.g. `D:\ARK\ARKSA_Server\ShooterGame\Saved\Config\WindowsServer\GameUserSettings.ini`.
pub fn game_user_settings_path(install_root: &Path) -> PathBuf {
    install_root
        .join("ShooterGame")
        .join("Saved")
        .join("Config")
        .join("WindowsServer")
        .join("GameUserSettings.ini")
}

/// Wrapper over `GameUserSettings.ini` exposing only the keys we own. All other
/// settings round-trip untouched (the underlying `IniDoc` preserves them).
#[derive(Debug)]
pub struct GameUserSettings {
    path: PathBuf,
    doc: IniDoc,
}

impl GameUserSettings {
    /// Load `path` or, if it does not exist yet, start an empty document with
    /// the eventual save target set.
    pub fn load_or_empty(path: impl Into<PathBuf>) -> Result<Self> {
        let path = path.into();
        let doc = if path.exists() {
            IniDoc::load(&path)?
        } else {
            IniDoc::new()
        };
        Ok(Self { path, doc })
    }

    pub fn path(&self) -> &Path {
        &self.path
    }

    pub fn doc(&self) -> &IniDoc {
        &self.doc
    }

    /// Persist the file. Parent directories are created as needed (the file
    /// usually lives several levels deep under a freshly-installed game).
    pub fn save(&self) -> Result<()> {
        self.doc.save(&self.path)
    }

    // ── settings we author ────────────────────────────────────────────

    pub fn set_rcon_enabled(&mut self, enabled: bool) {
        // ARK writes "True"/"False" (capital initial) in this file, so match
        // upstream rather than IniDoc::set_bool's 0/1 form.
        self.doc.set_string(
            SECTION_SERVER_SETTINGS,
            "RCONEnabled",
            if enabled { "True" } else { "False" },
        );
    }

    pub fn set_rcon_port(&mut self, port: u16) {
        self.doc
            .set_i64(SECTION_SERVER_SETTINGS, "RCONPort", port as i64);
    }

    pub fn set_admin_password(&mut self, password: &str) {
        self.doc
            .set_string(SECTION_SERVER_SETTINGS, "ServerAdminPassword", password);
    }

    pub fn rcon_enabled(&self) -> Option<bool> {
        self.doc
            .get_string(SECTION_SERVER_SETTINGS, "RCONEnabled")
            .map(|v| matches!(v.trim(), s if s.eq_ignore_ascii_case("true") || s == "1"))
    }

    pub fn rcon_port(&self) -> Option<u16> {
        self.doc
            .get_i64(SECTION_SERVER_SETTINGS, "RCONPort")
            .and_then(|n| u16::try_from(n).ok())
    }

    pub fn admin_password(&self) -> Option<String> {
        self.doc
            .get_string(SECTION_SERVER_SETTINGS, "ServerAdminPassword")
    }
}

/// Apply the RCON settings from a `LaunchArgs`-style triple to the file at
/// `path`, preserving every other key already present.
///
/// This is the one-call helper `Profile::create_new` uses so a freshly-created
/// profile is RCON-ready without the user having to edit anything by hand.
pub fn write_rcon_settings(
    path: &Path,
    rcon_enabled: bool,
    rcon_port: u16,
    admin_password: &str,
) -> Result<()> {
    let mut gus = GameUserSettings::load_or_empty(path)?;
    gus.set_rcon_enabled(rcon_enabled);
    gus.set_rcon_port(rcon_port);
    gus.set_admin_password(admin_password);
    gus.save()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn temp_path(suffix: &str) -> PathBuf {
        std::env::temp_dir().join(format!(
            "arksa_ark_config_{}_{}.ini",
            std::process::id(),
            suffix
        ))
    }

    #[test]
    fn standard_path_layout() {
        let root = PathBuf::from("D:\\ARK\\Server");
        let p = game_user_settings_path(&root);
        let s = p.to_string_lossy().replace('/', "\\");
        assert!(
            s.ends_with("ShooterGame\\Saved\\Config\\WindowsServer\\GameUserSettings.ini"),
            "got {s}"
        );
    }

    #[test]
    fn load_or_empty_creates_when_missing() {
        let p = temp_path("missing");
        let _ = std::fs::remove_file(&p);
        let mut gus = GameUserSettings::load_or_empty(&p).unwrap();
        gus.set_rcon_enabled(true);
        gus.set_rcon_port(27020);
        gus.set_admin_password("MyArkPass");
        gus.save().unwrap();

        let raw = std::fs::read_to_string(&p).unwrap();
        assert!(raw.contains("[ServerSettings]"));
        assert!(raw.contains("RCONEnabled=True"));
        assert!(raw.contains("RCONPort=27020"));
        assert!(raw.contains("ServerAdminPassword=MyArkPass"));
        // Backslashes in the path must not be doubled by the writer.
        assert!(!raw.contains("\\\\"));
        let _ = std::fs::remove_file(p);
    }

    #[test]
    fn write_rcon_settings_preserves_unrelated_keys() {
        let p = temp_path("preserve");
        let _ = std::fs::remove_file(&p);
        // Pre-seed the file with a [ServerSettings] section that contains an
        // unrelated key plus a stale ServerAdminPassword we want to overwrite.
        std::fs::write(
            &p,
            "[ServerSettings]\r\n\
             SomeOtherKey=keep me\r\n\
             ServerAdminPassword=stale\r\n\
             [Other]\r\n\
             TouchNotKey=preserved\r\n",
        )
        .unwrap();

        write_rcon_settings(&p, true, 27020, "freshpass").unwrap();

        let reloaded = GameUserSettings::load_or_empty(&p).unwrap();
        assert_eq!(reloaded.rcon_enabled(), Some(true));
        assert_eq!(reloaded.rcon_port(), Some(27020));
        assert_eq!(reloaded.admin_password().as_deref(), Some("freshpass"));
        assert_eq!(
            reloaded
                .doc()
                .get_string(SECTION_SERVER_SETTINGS, "SomeOtherKey")
                .as_deref(),
            Some("keep me")
        );
        assert_eq!(
            reloaded
                .doc()
                .get_string("Other", "TouchNotKey")
                .as_deref(),
            Some("preserved")
        );
        let _ = std::fs::remove_file(p);
    }

    #[test]
    fn rcon_enabled_round_trips_true_false_strings() {
        let p = temp_path("bool");
        let _ = std::fs::remove_file(&p);

        let mut gus = GameUserSettings::load_or_empty(&p).unwrap();
        gus.set_rcon_enabled(true);
        gus.save().unwrap();
        assert_eq!(
            GameUserSettings::load_or_empty(&p).unwrap().rcon_enabled(),
            Some(true)
        );

        let mut gus = GameUserSettings::load_or_empty(&p).unwrap();
        gus.set_rcon_enabled(false);
        gus.save().unwrap();
        assert_eq!(
            GameUserSettings::load_or_empty(&p).unwrap().rcon_enabled(),
            Some(false)
        );

        let _ = std::fs::remove_file(p);
    }
}

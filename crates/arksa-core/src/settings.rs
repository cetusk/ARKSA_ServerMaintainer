//! Application-wide settings INI (`AsaServerManegerWin.ini` upstream).
//!
//! Layout:
//!   [mainui]            DarkMode / language / Width / Height / DebugUpdate /
//!                       UseBuiltinRCON / DisableSteamcmdSharing / ...
//!   [Profiles]          Tab<n> = <profile name>     (tab order)
//!   [Discord]           Hook_Admin_URL / Hook_Admin_Kind / Hook_Admin_ASASMNAME
//!   [TrayNotification]  TrayNotificationKind / TrayNotificationName
//!   [ASASM_Updater]     BetaBranch / BetaBranchURL_INFO
//!
//! As with `Profile`, only a handful of keys are typed in Phase 1; everything
//! else round-trips through `IniDoc`.

use std::path::{Path, PathBuf};

use crate::error::Result;
use crate::ini_doc::IniDoc;

pub const SECTION_MAINUI: &str = "mainui";
pub const SECTION_PROFILES: &str = "Profiles";
pub const SECTION_DISCORD: &str = "Discord";
pub const SECTION_TRAY: &str = "TrayNotification";

/// Default basename. Kept to ease migration from upstream installs.
pub const DEFAULT_FILENAME: &str = "AsaServerManegerWin.ini";

#[derive(Debug, Clone)]
pub struct AppSettings {
    path: PathBuf,
    doc: IniDoc,
}

impl AppSettings {
    pub fn load(path: impl AsRef<Path>) -> Result<Self> {
        let path = path.as_ref().to_path_buf();
        let doc = if path.exists() {
            IniDoc::load(&path)?
        } else {
            IniDoc::new()
        };
        Ok(Self { path, doc })
    }

    pub fn empty_at(path: impl Into<PathBuf>) -> Self {
        Self {
            path: path.into(),
            doc: IniDoc::new(),
        }
    }

    pub fn save(&self) -> Result<()> {
        self.doc.save(&self.path)
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

    // ---- [mainui] ------------------------------------------------------------

    pub fn dark_mode(&self) -> bool {
        self.doc
            .get_bool(SECTION_MAINUI, "DarkMode")
            .unwrap_or(false)
    }

    pub fn set_dark_mode(&mut self, enabled: bool) {
        self.doc.set_bool(SECTION_MAINUI, "DarkMode", enabled);
    }

    /// 0 = follow OS, 1 = English, 2 = Japanese (matches upstream ordering).
    pub fn language(&self) -> i64 {
        self.doc.get_i64(SECTION_MAINUI, "language").unwrap_or(0)
    }

    pub fn set_language(&mut self, value: i64) {
        self.doc.set_i64(SECTION_MAINUI, "language", value);
    }

    pub fn use_builtin_rcon(&self) -> bool {
        self.doc
            .get_bool(SECTION_MAINUI, "UseBuiltinRCON")
            .unwrap_or(false)
    }

    pub fn set_use_builtin_rcon(&mut self, enabled: bool) {
        self.doc
            .set_bool(SECTION_MAINUI, "UseBuiltinRCON", enabled);
    }

    pub fn last_asasm_path(&self) -> Option<String> {
        self.doc.get_string(SECTION_MAINUI, "LastASASMPath")
    }

    pub fn set_last_asasm_path(&mut self, path: &str) {
        self.doc.set_string(SECTION_MAINUI, "LastASASMPath", path);
    }

    // ---- [Profiles] ----------------------------------------------------------

    /// Ordered list of profile names as shown in the tab strip.
    pub fn profile_tabs(&self) -> Vec<String> {
        let Some(section) = self.doc.raw().section(Some(SECTION_PROFILES)) else {
            return Vec::new();
        };
        // Upstream writes `Tab0`, `Tab1`, ... but iteration order is not
        // guaranteed; rebuild the order by parsing the trailing index.
        let mut indexed: Vec<(usize, String)> = section
            .iter()
            .filter_map(|(key, value)| {
                let suffix = key.strip_prefix("Tab")?;
                let idx: usize = suffix.parse().ok()?;
                Some((idx, value.to_string()))
            })
            .collect();
        indexed.sort_by_key(|(i, _)| *i);
        indexed.into_iter().map(|(_, v)| v).collect()
    }

    pub fn set_profile_tabs(&mut self, names: &[String]) {
        // Wipe and rewrite so removed entries do not leak.
        self.doc.raw_mut().delete(Some(SECTION_PROFILES));
        for (idx, name) in names.iter().enumerate() {
            self.doc
                .set_string(SECTION_PROFILES, &format!("Tab{idx}"), name);
        }
    }

    // ---- [Discord] -----------------------------------------------------------

    pub fn discord_admin_webhook_url(&self) -> Option<String> {
        self.doc.get_string(SECTION_DISCORD, "Hook_Admin_URL")
    }

    pub fn set_discord_admin_webhook_url(&mut self, url: &str) {
        self.doc
            .set_string(SECTION_DISCORD, "Hook_Admin_URL", url);
    }

    pub fn discord_display_name(&self) -> Option<String> {
        self.doc
            .get_string(SECTION_DISCORD, "Hook_Admin_ASASMNAME")
    }

    pub fn set_discord_display_name(&mut self, name: &str) {
        self.doc
            .set_string(SECTION_DISCORD, "Hook_Admin_ASASMNAME", name);
    }

    /// 6-character "kind" string upstream stores: each char is `0/1` for one of
    /// {Starting, Online, Stopped, Crash, ASASM update, ServerApp update}.
    pub fn discord_admin_event_mask(&self) -> Option<String> {
        self.doc.get_string(SECTION_DISCORD, "Hook_Admin_Kind")
    }

    pub fn set_discord_admin_event_mask(&mut self, mask: &str) {
        self.doc
            .set_string(SECTION_DISCORD, "Hook_Admin_Kind", mask);
    }

    // ---- [TrayNotification] --------------------------------------------------

    pub fn tray_event_mask(&self) -> Option<String> {
        self.doc
            .get_string(SECTION_TRAY, "TrayNotificationKind")
    }

    pub fn set_tray_event_mask(&mut self, mask: &str) {
        self.doc
            .set_string(SECTION_TRAY, "TrayNotificationKind", mask);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn reads_profile_tab_order() {
        let src = r#"[Profiles]
Tab0=Island
Tab2=Ragnarok
Tab1=Center
"#;
        let doc = IniDoc::load_bytes(src.as_bytes()).unwrap();
        let s = AppSettings {
            path: PathBuf::from("x.ini"),
            doc,
        };
        assert_eq!(
            s.profile_tabs(),
            vec!["Island".to_string(), "Center".to_string(), "Ragnarok".to_string()]
        );
    }

    #[test]
    fn writes_profile_tabs_in_order() {
        let mut s = AppSettings::empty_at("x.ini");
        s.set_profile_tabs(&["A".into(), "B".into(), "C".into()]);
        assert_eq!(s.profile_tabs(), vec!["A", "B", "C"]);
    }

    #[test]
    fn dark_mode_round_trip_uses_zero_one() {
        let mut s = AppSettings::empty_at("x.ini");
        s.set_dark_mode(true);
        assert_eq!(s.doc.get_string("mainui", "DarkMode").as_deref(), Some("1"));
        assert!(s.dark_mode());
    }
}

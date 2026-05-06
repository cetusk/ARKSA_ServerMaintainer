//! Generic INI document used as the foundation for `profile.rs`, `settings.rs`,
//! and any other key/value config.
//!
//! Why we wrap `rust-ini` instead of using it directly:
//!
//!   1. **Encoding fallback.** Upstream INIs are written by Lazarus, which uses
//!      the OS ANSI codepage. On JP Windows that is CP932 (Shift-JIS). We try
//!      UTF-8 first, then fall back to SJIS so existing user profiles load.
//!   2. **Round-trip preservation.** `frameui.pas` writes ~hundreds of keys
//!      across 15 sections; we only type a handful in Phase 1, but unknown
//!      keys must survive a load → save cycle untouched.
//!   3. **Lazarus quirks.** TIniFile writes booleans as `0`/`1` and floats with
//!      a `.` decimal separator regardless of locale. We match that on write
//!      and accept both `0/1` and `True/False` (case-insensitive) on read so
//!      profiles produced by either tool interoperate.

use std::fs;
use std::path::Path;

use encoding_rs::SHIFT_JIS;
use ini::{Ini, ParseOption};

use crate::error::{Error, Result};

/// In-memory INI document. A thin wrapper over `rust-ini::Ini`.
#[derive(Debug, Clone, Default)]
pub struct IniDoc {
    inner: Ini,
}

impl IniDoc {
    pub fn new() -> Self {
        Self::default()
    }

    /// Load from disk, transparently handling UTF-8 (with or without BOM) and
    /// SHIFT_JIS-encoded files written by upstream Lazarus.
    pub fn load(path: impl AsRef<Path>) -> Result<Self> {
        let bytes = fs::read(path.as_ref())?;
        Self::load_bytes(&bytes)
    }

    pub fn load_bytes(bytes: &[u8]) -> Result<Self> {
        let text = decode_text(bytes);
        // Lazarus's TIniFile does not quote values or interpret backslashes as
        // escapes, so disable both behaviours; otherwise paths like
        //   Edit_Install_Location_Val=C:\ark\server
        // round-trip incorrectly.
        let inner = Ini::load_from_str_opt(
            &text,
            ParseOption {
                enabled_quote: false,
                enabled_escape: false,
                ..Default::default()
            },
        )
        .map_err(|e| Error::IniParse(e.to_string()))?;
        Ok(Self { inner })
    }

    /// Always writes UTF-8 (no BOM) with `=` separators and `\r\n` line endings,
    /// matching what Notepad-class editors expect on Windows.
    ///
    /// `EscapePolicy::Nothing` is critical: Lazarus TIniFile (the upstream
    /// writer) does not escape backslashes, so a Windows path
    ///     Edit_Install_Location_Val=D:\ARK\ARKSA_Server
    /// is stored verbatim. With the rust-ini default policy we'd write
    ///     Edit_Install_Location_Val=D:\\ARK\\ARKSA_Server
    /// and our load path (with `enabled_escape: false`) would then read those
    /// literal `\\`s back, producing a broken path that doesn't match the
    /// real filesystem.
    pub fn save(&self, path: impl AsRef<Path>) -> Result<()> {
        if let Some(parent) = path.as_ref().parent() {
            if !parent.as_os_str().is_empty() {
                fs::create_dir_all(parent)?;
            }
        }
        self.inner.write_to_file_opt(
            path.as_ref(),
            ini::WriteOption {
                line_separator: ini::LineSeparator::CRLF,
                kv_separator: "=",
                escape_policy: ini::EscapePolicy::Nothing,
            },
        )?;
        Ok(())
    }

    pub fn raw(&self) -> &Ini {
        &self.inner
    }

    pub fn raw_mut(&mut self) -> &mut Ini {
        &mut self.inner
    }

    pub fn get_string(&self, section: &str, key: &str) -> Option<String> {
        self.inner.section(Some(section))
            .and_then(|s| s.get(key))
            .map(|v| v.to_string())
    }

    pub fn get_bool(&self, section: &str, key: &str) -> Option<bool> {
        self.get_string(section, key).and_then(|v| parse_bool(&v))
    }

    pub fn get_i64(&self, section: &str, key: &str) -> Option<i64> {
        self.get_string(section, key)
            .and_then(|v| v.trim().parse::<i64>().ok())
    }

    pub fn get_f64(&self, section: &str, key: &str) -> Option<f64> {
        self.get_string(section, key)
            .and_then(|v| v.trim().parse::<f64>().ok())
    }

    pub fn set_string(&mut self, section: &str, key: &str, value: impl Into<String>) {
        self.inner
            .with_section(Some(section))
            .set(key, value.into());
    }

    pub fn set_bool(&mut self, section: &str, key: &str, value: bool) {
        // Lazarus TIniFile writes booleans as 0/1 — match upstream so profiles
        // remain interoperable.
        self.set_string(section, key, if value { "1" } else { "0" });
    }

    pub fn set_i64(&mut self, section: &str, key: &str, value: i64) {
        self.set_string(section, key, value.to_string());
    }

    pub fn set_f64(&mut self, section: &str, key: &str, value: f64) {
        // Lazarus writes floats with a '.' decimal separator regardless of locale.
        self.set_string(section, key, format!("{value:?}"));
    }

    /// Delete a single key from a section. Quietly does nothing if the
    /// section or key is absent. Used during Save to clean up keys that
    /// have been re-routed between INI files (e.g. the Phase 8M routing
    /// of breeding multipliers GUS → Game.ini reverted in 8S, where
    /// stale values left in `[ServerSettings]` would otherwise compete
    /// with the canonical `Game.ini` value).
    pub fn remove_key(&mut self, section: &str, key: &str) {
        if let Some(props) = self.inner.section_mut(Some(section)) {
            props.remove(key);
        }
    }
}

fn decode_text(bytes: &[u8]) -> String {
    // UTF-8 BOM
    if bytes.starts_with(&[0xEF, 0xBB, 0xBF]) {
        return String::from_utf8_lossy(&bytes[3..]).into_owned();
    }
    // Strict UTF-8 first.
    if let Ok(s) = std::str::from_utf8(bytes) {
        return s.to_owned();
    }
    // SHIFT_JIS fallback for legacy upstream profiles.
    let (decoded, _, _) = SHIFT_JIS.decode(bytes);
    decoded.into_owned()
}

fn parse_bool(raw: &str) -> Option<bool> {
    let v = raw.trim();
    match v {
        "1" => Some(true),
        "0" => Some(false),
        s if s.eq_ignore_ascii_case("true") => Some(true),
        s if s.eq_ignore_ascii_case("false") => Some(false),
        _ => None,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn round_trips_unknown_keys() {
        let src = "[General]\nKnownKey=hello\nUnknown=42\n[Server]\nA=1\n";
        let doc = IniDoc::load_bytes(src.as_bytes()).unwrap();
        assert_eq!(doc.get_string("General", "Unknown").as_deref(), Some("42"));
        assert_eq!(doc.get_i64("Server", "A"), Some(1));
    }

    #[test]
    fn parses_lazarus_bool_forms() {
        let src = "[s]\na=1\nb=0\nc=True\nd=false\n";
        let doc = IniDoc::load_bytes(src.as_bytes()).unwrap();
        assert_eq!(doc.get_bool("s", "a"), Some(true));
        assert_eq!(doc.get_bool("s", "b"), Some(false));
        assert_eq!(doc.get_bool("s", "c"), Some(true));
        assert_eq!(doc.get_bool("s", "d"), Some(false));
    }

    #[test]
    fn writes_bool_as_lazarus_zero_one() {
        let mut doc = IniDoc::new();
        doc.set_bool("S", "k", true);
        assert_eq!(doc.get_string("S", "k").as_deref(), Some("1"));
    }

    #[test]
    fn handles_utf8_bom() {
        let src = b"\xEF\xBB\xBF[s]\nk=v\n";
        let doc = IniDoc::load_bytes(src).unwrap();
        assert_eq!(doc.get_string("s", "k").as_deref(), Some("v"));
    }

    #[test]
    fn windows_paths_round_trip_without_double_escaping() {
        // Regression: write+reload must not double-up backslashes in Windows
        // paths. We check both via the in-memory string round trip and via a
        // real file write/read.
        let tmp = std::env::temp_dir().join(format!(
            "arksa_ini_path_roundtrip_{}.ini",
            std::process::id()
        ));
        let _ = std::fs::remove_file(&tmp);

        let mut doc = IniDoc::new();
        doc.set_string("General", "Edit_Install_Location_Val", "D:\\ARK\\ARKSA_Server");
        doc.save(&tmp).unwrap();

        let raw = std::fs::read_to_string(&tmp).unwrap();
        // The on-disk file must contain the original single backslashes.
        assert!(
            raw.contains("Edit_Install_Location_Val=D:\\ARK\\ARKSA_Server"),
            "file content was: {raw:?}"
        );
        assert!(
            !raw.contains("\\\\"),
            "file content unexpectedly has \\\\: {raw:?}"
        );

        let reloaded = IniDoc::load(&tmp).unwrap();
        assert_eq!(
            reloaded
                .get_string("General", "Edit_Install_Location_Val")
                .as_deref(),
            Some("D:\\ARK\\ARKSA_Server")
        );
        let _ = std::fs::remove_file(tmp);
    }

    #[test]
    fn remove_key_strips_only_the_named_key() {
        let mut doc = IniDoc::new();
        doc.set_f64("ServerSettings", "BabyMatureSpeedMultiplier", 6.0);
        doc.set_f64("ServerSettings", "TamingSpeedMultiplier", 33.0);
        doc.set_string("Other", "Untouched", "x");

        doc.remove_key("ServerSettings", "BabyMatureSpeedMultiplier");

        assert_eq!(
            doc.get_f64("ServerSettings", "BabyMatureSpeedMultiplier"),
            None
        );
        assert_eq!(
            doc.get_f64("ServerSettings", "TamingSpeedMultiplier"),
            Some(33.0)
        );
        assert_eq!(doc.get_string("Other", "Untouched").as_deref(), Some("x"));
        // Removing a missing key is a no-op.
        doc.remove_key("ServerSettings", "DoesNotExist");
        doc.remove_key("NoSuchSection", "Anything");
    }

    #[test]
    fn falls_back_to_shift_jis() {
        // "[一般]\nキー=値\n" in SHIFT_JIS
        let src: &[u8] = &[
            0x5b, 0x88, 0xea, 0x94, 0xca, 0x5d, 0x0a, // [一般]\n
            0x83, 0x4c, 0x81, 0x5b, 0x3d, 0x92, 0x6c, 0x0a, // キー=値\n
        ];
        let doc = IniDoc::load_bytes(src).unwrap();
        assert_eq!(doc.get_string("一般", "キー").as_deref(), Some("値"));
    }
}

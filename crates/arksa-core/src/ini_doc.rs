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
                ..Default::default()
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

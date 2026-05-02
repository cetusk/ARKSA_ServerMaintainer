//! `ModList.txt` parser.
//!
//! Format: one mapping per line, `<u64 mod id>=<name>`. Blank lines and lines
//! starting with `#` or `;` are ignored. The upstream file is ~124 KB and is
//! checked into `assets/`.
//!
//! `assets/ModList.txt` may be UTF-8 or SHIFT_JIS; we use the same encoding
//! sniffer as `IniDoc` so that older copies of the file load cleanly.

use std::collections::BTreeMap;
use std::fs;
use std::path::Path;

use encoding_rs::SHIFT_JIS;

use crate::error::Result;

/// `mod_id → display name` lookup. `BTreeMap` so iteration is deterministic
/// (stable across builds, which makes Find-UI sorting predictable).
pub type ModList = BTreeMap<u64, String>;

pub fn load(path: impl AsRef<Path>) -> Result<ModList> {
    let bytes = fs::read(path.as_ref())?;
    Ok(parse(&bytes))
}

pub fn parse(bytes: &[u8]) -> ModList {
    let text = decode(bytes);
    parse_str(&text)
}

pub fn parse_str(text: &str) -> ModList {
    let mut map = ModList::new();
    for line in text.lines() {
        let line = line.trim();
        if line.is_empty() || line.starts_with('#') || line.starts_with(';') {
            continue;
        }
        let Some((id_part, name_part)) = line.split_once('=') else {
            continue;
        };
        let id_str = id_part.trim();
        let name = name_part.trim();
        if name.is_empty() {
            continue;
        }
        if let Ok(id) = id_str.parse::<u64>() {
            // Last-write-wins on duplicate IDs, matching how upstream's
            // sequential read of the file would overwrite earlier entries.
            map.insert(id, name.to_string());
        }
    }
    map
}

fn decode(bytes: &[u8]) -> String {
    if bytes.starts_with(&[0xEF, 0xBB, 0xBF]) {
        return String::from_utf8_lossy(&bytes[3..]).into_owned();
    }
    if let Ok(s) = std::str::from_utf8(bytes) {
        return s.to_owned();
    }
    let (decoded, _, _) = SHIFT_JIS.decode(bytes);
    decoded.into_owned()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_basic_lines() {
        let src = "1283493=LunarQoLPlus\n1280474=TreasureMapChest[Crossplay]\n";
        let m = parse_str(src);
        assert_eq!(m.get(&1283493).map(String::as_str), Some("LunarQoLPlus"));
        assert_eq!(
            m.get(&1280474).map(String::as_str),
            Some("TreasureMapChest[Crossplay]")
        );
        assert_eq!(m.len(), 2);
    }

    #[test]
    fn skips_blank_and_comment_lines() {
        let src = "\n# comment\n; also comment\n1=One\n  \n2=Two\n";
        let m = parse_str(src);
        assert_eq!(m.len(), 2);
        assert_eq!(m.get(&1).unwrap(), "One");
        assert_eq!(m.get(&2).unwrap(), "Two");
    }

    #[test]
    fn skips_unparseable_lines() {
        let src = "not_a_number=foo\n3=Bar\nmissing_value=\n";
        let m = parse_str(src);
        assert_eq!(m.len(), 1);
        assert_eq!(m.get(&3).unwrap(), "Bar");
    }

    #[test]
    fn loads_real_assets_modlist() {
        // CARGO_MANIFEST_DIR points at crates/arksa-core; the file lives at
        // workspace_root/assets/ModList.txt, so go up two directories.
        let mut path = std::path::PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        path.pop(); // crates/
        path.pop(); // workspace root
        path.push("assets");
        path.push("ModList.txt");

        // The file is committed; if missing, the test should fail loud.
        let m = load(&path).expect("ModList.txt must load");
        assert!(m.len() > 100, "expected many mod entries, got {}", m.len());
        // Spot check a known well-formed entry near the top of the file.
        assert!(m.contains_key(&1283493));
    }
}

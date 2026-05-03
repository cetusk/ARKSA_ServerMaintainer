//! Loaders for the game-content data files used by the Find UI:
//!
//!   * `assets/EngramData.txt` — `<name>=<engram_class>,<index>,<level>,<points>`
//!   * `assets/ItemData.txt`   — `<name>=<class_name>,<stack_size>`
//!   * `assets/DinoData.txt`   — `<name>=<i>,<i>,<i>,<class_name>`
//!
//! All three follow the same pattern: one entry per line, key/value separated
//! by `=`, value is a small CSV. Blank lines and `#`/`;` comments are skipped.
//! UTF-8 with a SHIFT_JIS fallback for legacy copies (matches the convention
//! used in `IniDoc` and `modlist`).

use std::fs;
use std::path::Path;

use encoding_rs::SHIFT_JIS;

use crate::error::Result;

#[derive(Debug, Clone)]
pub struct Engram {
    pub name: String,
    pub class_name: String,
    pub index: i32,
    pub level: u32,
    pub points: u32,
}

#[derive(Debug, Clone)]
pub struct Item {
    pub name: String,
    pub class_name: String,
    pub stack_size: u32,
}

#[derive(Debug, Clone)]
pub struct Dino {
    pub name: String,
    pub class_name: String,
}

pub fn load_engrams(path: impl AsRef<Path>) -> Result<Vec<Engram>> {
    let text = read_decoded(path.as_ref())?;
    Ok(parse_engrams(&text))
}

pub fn load_items(path: impl AsRef<Path>) -> Result<Vec<Item>> {
    let text = read_decoded(path.as_ref())?;
    Ok(parse_items(&text))
}

pub fn load_dinos(path: impl AsRef<Path>) -> Result<Vec<Dino>> {
    let text = read_decoded(path.as_ref())?;
    Ok(parse_dinos(&text))
}

/// Same as `parse_engrams` but takes raw bytes; handles UTF-8 (with or
/// without BOM) and SHIFT_JIS. Useful when feeding `include_bytes!` content.
pub fn parse_engrams_bytes(bytes: &[u8]) -> Vec<Engram> {
    parse_engrams(&decode_text(bytes))
}

pub fn parse_items_bytes(bytes: &[u8]) -> Vec<Item> {
    parse_items(&decode_text(bytes))
}

pub fn parse_dinos_bytes(bytes: &[u8]) -> Vec<Dino> {
    parse_dinos(&decode_text(bytes))
}

/// Decode a buffer that may be UTF-8, UTF-8 + BOM, or SHIFT_JIS — same
/// strategy as `IniDoc` and `modlist`.
pub fn decode_text(bytes: &[u8]) -> String {
    if bytes.starts_with(&[0xEF, 0xBB, 0xBF]) {
        return String::from_utf8_lossy(&bytes[3..]).into_owned();
    }
    if let Ok(s) = std::str::from_utf8(bytes) {
        return s.to_owned();
    }
    let (decoded, _, _) = SHIFT_JIS.decode(bytes);
    decoded.into_owned()
}

pub fn parse_engrams(text: &str) -> Vec<Engram> {
    parse_lines(text, |name, fields| {
        let mut it = fields.iter();
        let class_name = (*it.next()?).to_string();
        let index = it.next()?.parse::<i32>().ok()?;
        let level = it.next()?.parse::<u32>().ok()?;
        let points = it.next()?.parse::<u32>().ok()?;
        Some(Engram {
            name: name.to_string(),
            class_name,
            index,
            level,
            points,
        })
    })
}

pub fn parse_items(text: &str) -> Vec<Item> {
    parse_lines(text, |name, fields| {
        let mut it = fields.iter();
        let class_name = (*it.next()?).to_string();
        let stack_size = it.next()?.parse::<u32>().unwrap_or(1);
        Some(Item {
            name: name.to_string(),
            class_name,
            stack_size,
        })
    })
}

pub fn parse_dinos(text: &str) -> Vec<Dino> {
    parse_lines(text, |name, fields| {
        // The three numeric columns vary per upstream version and are not
        // useful to the Find UI; we only consume the trailing class name.
        let class_name = (*fields.last()?).to_string();
        Some(Dino {
            name: name.to_string(),
            class_name,
        })
    })
}

// ── helpers ─────────────────────────────────────────────────────────────

fn parse_lines<T, F>(text: &str, mut build: F) -> Vec<T>
where
    F: FnMut(&str, &[&str]) -> Option<T>,
{
    let mut out = Vec::new();
    for line in text.lines() {
        let line = line.trim();
        if line.is_empty() || line.starts_with('#') || line.starts_with(';') {
            continue;
        }
        let Some((name, rest)) = line.split_once('=') else {
            continue;
        };
        let name = name.trim();
        if name.is_empty() {
            continue;
        }
        let fields: Vec<&str> = rest.split(',').map(str::trim).collect();
        if let Some(entry) = build(name, &fields) {
            out.push(entry);
        }
    }
    out
}

fn read_decoded(path: &Path) -> Result<String> {
    let bytes = fs::read(path)?;
    Ok(decode_text(&bytes))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_engram_lines() {
        let src = "Campfire=EngramEntry_Campfire_C,0,3,2\nStoneHatchet=EngramEntry_StoneHatchet_C,1,3,2\n";
        let v = parse_engrams(src);
        assert_eq!(v.len(), 2);
        assert_eq!(v[0].name, "Campfire");
        assert_eq!(v[0].class_name, "EngramEntry_Campfire_C");
        assert_eq!(v[0].index, 0);
        assert_eq!(v[0].level, 3);
        assert_eq!(v[0].points, 2);
    }

    #[test]
    fn parses_item_lines() {
        let src = "AbsorbentSubstrate=PrimalItemResource_SubstrateAbsorbent_C,100\n";
        let v = parse_items(src);
        assert_eq!(v.len(), 1);
        assert_eq!(v[0].name, "AbsorbentSubstrate");
        assert_eq!(v[0].class_name, "PrimalItemResource_SubstrateAbsorbent_C");
        assert_eq!(v[0].stack_size, 100);
    }

    #[test]
    fn parses_dino_lines() {
        let src = "Achatina=0,0,0,Achatina_Character_BP_C\nAlpha Carnotaurus=0,0,0,MegaCarno_Character_BP_C\n";
        let v = parse_dinos(src);
        assert_eq!(v.len(), 2);
        assert_eq!(v[0].name, "Achatina");
        assert_eq!(v[0].class_name, "Achatina_Character_BP_C");
        assert_eq!(v[1].name, "Alpha Carnotaurus");
        assert_eq!(v[1].class_name, "MegaCarno_Character_BP_C");
    }

    #[test]
    fn skips_blank_and_comment_lines() {
        let src = "\n# comment\n; also\nA=Class_A_C,1\n\n";
        let v = parse_items(src);
        assert_eq!(v.len(), 1);
    }

    #[test]
    fn loads_real_assets() {
        // Sanity: assets shipped with the repo must parse without errors and
        // produce a non-trivial number of entries.
        let mut base = std::path::PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        base.pop();
        base.pop();
        base.push("assets");

        let engrams = load_engrams(base.join("EngramData.txt")).unwrap();
        let items = load_items(base.join("ItemData.txt")).unwrap();
        let dinos = load_dinos(base.join("DinoData.txt")).unwrap();
        assert!(engrams.len() > 50, "got {} engrams", engrams.len());
        assert!(items.len() > 50, "got {} items", items.len());
        assert!(dinos.len() > 20, "got {} dinos", dinos.len());
    }
}

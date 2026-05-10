//! Per-MOD INI configuration schemas + IO helpers.
//!
//! ARK SA mods routinely drop their own custom INI section into
//! `GameUserSettings.ini` (or, less often, `Game.ini`). Those keys
//! aren't consumed by the ARK engine itself — they're read by the
//! mod's own UE startup code. This module models the schemas of mods
//! the GUI knows about so the editor can present a typed UI
//! (CheckBox / hex-colour / etc.) instead of raw text, while
//! **keeping all mod-specific keys out of the world-settings dialog's
//! main categories**. That separation is the safety property: when
//! the user removes a mod from `MM_Command_Val`, the engine doesn't
//! know about the mod's keys, but they sit harmlessly in their own
//! `[ModName]` section so re-enabling the mod restores prior values.
//!
//! Adding support for a new mod:
//!   1. Add a `ModConfigSchema` constant with the section, fields,
//!      defaults, and bilingual descriptions.
//!   2. Append it to [`ALL_MODS`].
//!   3. Wire a `ModConfigsWindow` panel in the GUI side (see
//!      `arksa-gui/ui/main.slint` and `arksa-gui/src/main.rs`).
//!
//! When the user toggles a mod off in their profile, the GUI hides
//! the corresponding panel but never deletes the INI section — that
//! way re-enabling the mod brings back the previously-saved settings
//! instead of resetting to defaults.

use std::path::{Path, PathBuf};

use crate::ark_config;
use crate::error::Result;
use crate::game_config;
use crate::ini_doc::IniDoc;

/// Which on-disk INI a mod schema's section lives in. `arksa-core`'s
/// existing `ark_config` and `game_config` already know the file
/// paths, so we just pick which one to load against.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ModConfigIni {
    /// `<install>\ShooterGame\Saved\Config\WindowsServer\GameUserSettings.ini`
    GameUserSettings,
    /// `<install>\ShooterGame\Saved\Config\WindowsServer\Game.ini`
    Game,
}

impl ModConfigIni {
    pub fn path(self, install_root: &Path) -> PathBuf {
        match self {
            ModConfigIni::GameUserSettings => {
                ark_config::game_user_settings_path(install_root)
            }
            ModConfigIni::Game => game_config::game_ini_path(install_root),
        }
    }
}

/// Static type of a single configurable key. Used by the GUI to pick
/// which input widget to render and to validate `String` values
/// before writing them back.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ModConfigFieldType {
    Bool,
    /// Free-form text (e.g. arbitrary string options).
    Text,
    /// `#RRGGBB` (or `#RRGGBBAA`) hex colour. Stored verbatim — the
    /// engine and the mod's own renderer parse it back.
    HexColor,
    Int,
    Float,
}

#[derive(Debug, Clone, Copy)]
pub struct ModConfigField {
    pub key: &'static str,
    pub field_type: ModConfigFieldType,
    pub default: &'static str,
    pub description_en: &'static str,
    pub description_ja: &'static str,
}

#[derive(Debug, Clone, Copy)]
pub struct ModConfigSchema {
    /// CurseForge project ID — used to detect whether the mod is in
    /// the profile's `MM_Command_Val` `-mods=` list.
    pub project_id: u64,
    /// Display name shown in the GUI sidebar / GroupBox title.
    pub display_name: &'static str,
    /// Which INI file the section lives in.
    pub ini: ModConfigIni,
    /// INI section header (without the surrounding brackets).
    pub section: &'static str,
    /// Ordered list of fields. The order is the display order in the
    /// GUI panel.
    pub fields: &'static [ModConfigField],
}

/// Return The Beacons (RTB) — Project 933576.
///
/// As documented on the mod's CurseForge page, RTB stores its config
/// under `[RTB]` in `GameUserSettings.ini`. Defaults reproduced
/// verbatim from the description so the GUI's "first open" view
/// matches what RTB itself would generate.
pub const RTB_SCHEMA: ModConfigSchema = ModConfigSchema {
    project_id: 933576,
    display_name: "Return The Beacons (RTB)",
    ini: ModConfigIni::GameUserSettings,
    section: "RTB",
    fields: &[
        ModConfigField {
            key: "EnableBeaconUI",
            field_type: ModConfigFieldType::Bool,
            default: "True",
            description_en:
                "Enable the in-game per-player Settings UI as a whole.",
            description_ja: "ゲーム内のプレイヤー単位設定 UI 全体の有効/無効。",
        },
        ModConfigField {
            key: "PlayerBeamColor",
            field_type: ModConfigFieldType::HexColor,
            default: "#fe019a",
            description_en:
                "Default colour of the player death beam (#RRGGBB hex).",
            description_ja: "プレイヤー死亡ビームの既定色 (#RRGGBB hex)。",
        },
        ModConfigField {
            key: "DinoBeamColor",
            field_type: ModConfigFieldType::HexColor,
            default: "#0cf7dc",
            description_en: "Default colour of the dino death beam (#RRGGBB hex).",
            description_ja: "恐竜死亡ビームの既定色 (#RRGGBB hex)。",
        },
        ModConfigField {
            key: "EnableGUIKeybind",
            field_type: ModConfigFieldType::Bool,
            default: "True",
            description_en:
                "Enable the Shift+Drag (or Left Trigger + Up DPad) keybind to open the UI.",
            description_ja:
                "UI を開く Shift+Drag (パッドは LT+上) キーバインドの有効/無効。",
        },
        ModConfigField {
            key: "EnablePauseMenuButton",
            field_type: ModConfigFieldType::Bool,
            default: "True",
            description_en:
                "Show the RTB button in the in-game pause / escape menu.",
            description_ja: "ポーズ (Escape) メニューに RTB ボタンを表示。",
        },
    ],
};

/// All mods the GUI knows how to edit. Look-ups go through this slice
/// so adding a new mod is a single-line append.
pub const ALL_MODS: &[ModConfigSchema] = &[RTB_SCHEMA];

/// Look up a schema by CurseForge project ID. Returns `None` for
/// mods we have no editor for.
pub fn schema_for_project(project_id: u64) -> Option<&'static ModConfigSchema> {
    ALL_MODS
        .iter()
        .find(|s| s.project_id == project_id)
}

/// Read the current value of a single field. Returns the schema's
/// default verbatim when the section/key is absent so the GUI
/// renders "default" rather than empty boxes — and a Save without
/// edits is a no-op rather than a write-of-defaults.
pub fn read_field(doc: &IniDoc, schema: &ModConfigSchema, field: &ModConfigField) -> String {
    doc.get_string(schema.section, field.key)
        .unwrap_or_else(|| field.default.to_string())
}

/// Read every field of a schema in order. The returned Vec lines up
/// 1:1 with `schema.fields`.
pub fn read_all(install_root: &Path, schema: &ModConfigSchema) -> Result<Vec<String>> {
    let path = schema.ini.path(install_root);
    let doc = if path.exists() {
        IniDoc::load(&path)?
    } else {
        IniDoc::new()
    };
    Ok(schema
        .fields
        .iter()
        .map(|f| read_field(&doc, schema, f))
        .collect())
}

/// Write a single field. `Bool` values are normalised to `True`/`False`
/// (matching what RTB writes itself) regardless of the casing the
/// caller passes in.
pub fn write_field(
    doc: &mut IniDoc,
    schema: &ModConfigSchema,
    field: &ModConfigField,
    raw: &str,
) {
    let trimmed = raw.trim();
    let normalised = match field.field_type {
        ModConfigFieldType::Bool => match trimmed.to_ascii_lowercase().as_str() {
            "true" | "1" | "yes" | "on" => "True".to_string(),
            "false" | "0" | "no" | "off" => "False".to_string(),
            other => other.to_string(),
        },
        // Other types are stored verbatim. Hex colours are just
        // strings, so a trim is enough — the mod's own parser handles
        // missing `#` etc.
        _ => trimmed.to_string(),
    };
    doc.set_string(schema.section, field.key, &normalised);
}

/// Write every field of a schema. `values` must line up 1:1 with
/// `schema.fields` (caller's responsibility — a length mismatch
/// triggers a debug-time panic via `assert_eq!`).
pub fn write_all(
    install_root: &Path,
    schema: &ModConfigSchema,
    values: &[String],
) -> Result<()> {
    assert_eq!(
        values.len(),
        schema.fields.len(),
        "ModConfigSchema field count mismatch — caller must align values with schema.fields"
    );
    let path = schema.ini.path(install_root);
    let mut doc = if path.exists() {
        IniDoc::load(&path)?
    } else {
        IniDoc::new()
    };
    for (field, value) in schema.fields.iter().zip(values.iter()) {
        write_field(&mut doc, schema, field, value);
    }
    if let Some(parent) = path.parent() {
        std::fs::create_dir_all(parent)?;
    }
    doc.save(&path)?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    fn unique_install() -> PathBuf {
        let pid = std::process::id();
        let id = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .map(|d| d.as_nanos())
            .unwrap_or(0);
        let p = std::env::temp_dir().join(format!("arksa_modcfg_{pid}_{id}"));
        std::fs::create_dir_all(&p).unwrap();
        p
    }

    #[test]
    fn rtb_defaults_round_trip_when_section_absent() {
        let install = unique_install();
        let values = read_all(&install, &RTB_SCHEMA).unwrap();
        assert_eq!(values.len(), RTB_SCHEMA.fields.len());
        // Every field starts at the schema default when the INI
        // hasn't been written yet.
        for (val, field) in values.iter().zip(RTB_SCHEMA.fields.iter()) {
            assert_eq!(val, field.default);
        }
        std::fs::remove_dir_all(&install).ok();
    }

    #[test]
    fn rtb_round_trip_persists_edits() {
        let install = unique_install();
        let values = vec![
            "False".to_string(),       // EnableBeaconUI
            "#abcdef".to_string(),     // PlayerBeamColor
            "#012345".to_string(),     // DinoBeamColor
            "True".to_string(),
            "False".to_string(),
        ];
        write_all(&install, &RTB_SCHEMA, &values).unwrap();
        let reread = read_all(&install, &RTB_SCHEMA).unwrap();
        assert_eq!(reread, values);
        std::fs::remove_dir_all(&install).ok();
    }

    #[test]
    fn bool_normalisation_canonicalises_casing() {
        let install = unique_install();
        let values = vec![
            "yes".to_string(),         // EnableBeaconUI -> True
            "#fe019a".to_string(),
            "#0cf7dc".to_string(),
            "0".to_string(),           // EnableGUIKeybind -> False
            "true".to_string(),        // EnablePauseMenuButton -> True
        ];
        write_all(&install, &RTB_SCHEMA, &values).unwrap();
        let reread = read_all(&install, &RTB_SCHEMA).unwrap();
        assert_eq!(reread[0], "True");
        assert_eq!(reread[3], "False");
        assert_eq!(reread[4], "True");
        std::fs::remove_dir_all(&install).ok();
    }

    #[test]
    fn schema_for_project_finds_rtb() {
        assert_eq!(
            schema_for_project(933576).map(|s| s.section),
            Some("RTB"),
        );
        assert!(schema_for_project(0).is_none());
    }

    #[test]
    fn write_all_does_not_clobber_unrelated_sections() {
        // Mods config writes must coexist with `[ServerSettings]` etc.
        // — those keys are owned by `ark_config` but live in the same
        // GameUserSettings.ini file.
        let install = unique_install();
        let path = ModConfigIni::GameUserSettings.path(&install);
        std::fs::create_dir_all(path.parent().unwrap()).unwrap();
        std::fs::write(
            &path,
            b"[ServerSettings]\nServerPVE=False\n\n[OtherMod]\nFoo=bar\n",
        )
        .unwrap();

        let values: Vec<String> = RTB_SCHEMA
            .fields
            .iter()
            .map(|f| f.default.to_string())
            .collect();
        write_all(&install, &RTB_SCHEMA, &values).unwrap();

        let doc = IniDoc::load(&path).unwrap();
        // RTB section now present.
        assert_eq!(
            doc.get_string("RTB", "EnableBeaconUI").as_deref(),
            Some("True"),
        );
        // Pre-existing sections survived intact.
        assert_eq!(
            doc.get_string("ServerSettings", "ServerPVE").as_deref(),
            Some("False"),
        );
        assert_eq!(
            doc.get_string("OtherMod", "Foo").as_deref(),
            Some("bar"),
        );
        std::fs::remove_dir_all(&install).ok();
    }
}

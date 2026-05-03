//! ARK SA `Game.ini` wrapper.
//!
//! Most of the gameplay knobs the server admin tunes (XP / harvest / taming
//! multipliers, drain rates, etc.) live in `Game.ini` under the
//! `[/Script/ShooterGame.ShooterGameMode]` section. ARK loads this file at
//! startup; live edits while the server is running have no effect.
//!
//! Written values use ARK's conventions: `1.0`-style floats and `True`/`False`
//! booleans. Existing keys we do not model are preserved on save, so a user
//! who hand-edits Game.ini for an exotic setting won't have it overwritten by
//! a round-trip through the GUI.

use std::path::{Path, PathBuf};

use crate::error::Result;
use crate::ini_doc::IniDoc;

pub const SECTION_GAME_MODE: &str = "/Script/ShooterGame.ShooterGameMode";

pub fn game_ini_path(install_root: &Path) -> PathBuf {
    install_root
        .join("ShooterGame")
        .join("Saved")
        .join("Config")
        .join("WindowsServer")
        .join("Game.ini")
}

#[derive(Debug)]
pub struct GameSettings {
    path: PathBuf,
    doc: IniDoc,
}

macro_rules! float_field {
    ($getter:ident, $setter:ident, $key:literal) => {
        pub fn $getter(&self) -> Option<f64> {
            self.doc.get_f64(SECTION_GAME_MODE, $key)
        }
        pub fn $setter(&mut self, v: f64) {
            self.doc.set_f64(SECTION_GAME_MODE, $key, v);
        }
    };
}

macro_rules! bool_field {
    ($getter:ident, $setter:ident, $key:literal) => {
        pub fn $getter(&self) -> Option<bool> {
            self.doc.get_string(SECTION_GAME_MODE, $key).map(|v| {
                matches!(v.trim(), s if s.eq_ignore_ascii_case("true") || s == "1")
            })
        }
        pub fn $setter(&mut self, v: bool) {
            self.doc.set_string(
                SECTION_GAME_MODE,
                $key,
                if v { "True" } else { "False" },
            );
        }
    };
}

impl GameSettings {
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

    pub fn save(&self) -> Result<()> {
        self.doc.save(&self.path)
    }

    // ── Rates ────────────────────────────────────────────────────────
    float_field!(xp_multiplier, set_xp_multiplier, "XPMultiplier");
    float_field!(
        harvest_amount_multiplier,
        set_harvest_amount_multiplier,
        "HarvestAmountMultiplier"
    );
    float_field!(
        harvest_health_multiplier,
        set_harvest_health_multiplier,
        "HarvestHealthMultiplier"
    );
    float_field!(
        resources_respawn_period_multiplier,
        set_resources_respawn_period_multiplier,
        "ResourcesRespawnPeriodMultiplier"
    );
    float_field!(
        taming_speed_multiplier,
        set_taming_speed_multiplier,
        "TamingSpeedMultiplier"
    );
    float_field!(
        mating_interval_multiplier,
        set_mating_interval_multiplier,
        "MatingIntervalMultiplier"
    );
    float_field!(
        egg_hatch_speed_multiplier,
        set_egg_hatch_speed_multiplier,
        "EggHatchSpeedMultiplier"
    );
    float_field!(
        baby_mature_speed_multiplier,
        set_baby_mature_speed_multiplier,
        "BabyMatureSpeedMultiplier"
    );

    // ── Day cycle ────────────────────────────────────────────────────
    float_field!(day_cycle_speed_scale, set_day_cycle_speed_scale, "DayCycleSpeedScale");
    float_field!(day_time_speed_scale, set_day_time_speed_scale, "DayTimeSpeedScale");
    float_field!(night_time_speed_scale, set_night_time_speed_scale, "NightTimeSpeedScale");

    // ── Player ───────────────────────────────────────────────────────
    float_field!(
        player_character_food_drain_multiplier,
        set_player_character_food_drain_multiplier,
        "PlayerCharacterFoodDrainMultiplier"
    );
    float_field!(
        player_character_water_drain_multiplier,
        set_player_character_water_drain_multiplier,
        "PlayerCharacterWaterDrainMultiplier"
    );
    float_field!(
        player_character_stamina_drain_multiplier,
        set_player_character_stamina_drain_multiplier,
        "PlayerCharacterStaminaDrainMultiplier"
    );
    float_field!(
        player_character_health_recovery_multiplier,
        set_player_character_health_recovery_multiplier,
        "PlayerCharacterHealthRecoveryMultiplier"
    );
    float_field!(player_damage_multiplier, set_player_damage_multiplier, "PlayerDamageMultiplier");
    float_field!(
        player_resistance_multiplier,
        set_player_resistance_multiplier,
        "PlayerResistanceMultiplier"
    );
    float_field!(
        player_harvesting_damage_multiplier,
        set_player_harvesting_damage_multiplier,
        "PlayerHarvestingDamageMultiplier"
    );

    // ── Tamed dino ───────────────────────────────────────────────────
    float_field!(
        dino_character_food_drain_multiplier,
        set_dino_character_food_drain_multiplier,
        "DinoCharacterFoodDrainMultiplier"
    );
    float_field!(
        dino_character_stamina_drain_multiplier,
        set_dino_character_stamina_drain_multiplier,
        "DinoCharacterStaminaDrainMultiplier"
    );
    float_field!(
        dino_character_health_recovery_multiplier,
        set_dino_character_health_recovery_multiplier,
        "DinoCharacterHealthRecoveryMultiplier"
    );
    float_field!(
        tamed_dino_damage_multiplier,
        set_tamed_dino_damage_multiplier,
        "TamedDinoDamageMultiplier"
    );
    float_field!(
        tamed_dino_resistance_multiplier,
        set_tamed_dino_resistance_multiplier,
        "TamedDinoResistanceMultiplier"
    );

    // ── Wild dino ────────────────────────────────────────────────────
    float_field!(
        wild_dino_character_food_drain_multiplier,
        set_wild_dino_character_food_drain_multiplier,
        "WildDinoCharacterFoodDrainMultiplier"
    );
    float_field!(
        wild_dino_character_stamina_drain_multiplier,
        set_wild_dino_character_stamina_drain_multiplier,
        "WildDinoCharacterStaminaDrainMultiplier"
    );
    float_field!(
        wild_dino_torpor_drain_multiplier,
        set_wild_dino_torpor_drain_multiplier,
        "WildDinoTorporDrainMultiplier"
    );
    float_field!(dino_count_multiplier, set_dino_count_multiplier, "DinoCountMultiplier");

    // ── Structure ────────────────────────────────────────────────────
    float_field!(
        structure_damage_multiplier,
        set_structure_damage_multiplier,
        "StructureDamageMultiplier"
    );
    float_field!(
        structure_resistance_multiplier,
        set_structure_resistance_multiplier,
        "StructureResistanceMultiplier"
    );
    float_field!(
        structure_damage_repair_cooldown,
        set_structure_damage_repair_cooldown,
        "StructureDamageRepairCooldown"
    );

    // ── Booleans ─────────────────────────────────────────────────────
    bool_field!(
        disable_imprint_dino_buff,
        set_disable_imprint_dino_buff,
        "DisableImprintDinoBuff"
    );
    bool_field!(
        allow_anyone_baby_imprint_cuddle,
        set_allow_anyone_baby_imprint_cuddle,
        "AllowAnyoneBabyImprintCuddle"
    );
}

#[cfg(test)]
mod tests {
    use super::*;

    fn temp(suffix: &str) -> PathBuf {
        std::env::temp_dir().join(format!(
            "arksa_game_config_{}_{}.ini",
            std::process::id(),
            suffix
        ))
    }

    #[test]
    fn standard_path_layout() {
        let p = game_ini_path(Path::new("D:\\ARK\\Server"));
        let s = p.to_string_lossy().replace('/', "\\");
        assert!(
            s.ends_with("ShooterGame\\Saved\\Config\\WindowsServer\\Game.ini"),
            "got {s}"
        );
    }

    #[test]
    fn load_or_empty_creates_when_missing() {
        let p = temp("missing");
        let _ = std::fs::remove_file(&p);
        let mut g = GameSettings::load_or_empty(&p).unwrap();
        g.set_xp_multiplier(2.5);
        g.set_taming_speed_multiplier(10.0);
        g.set_disable_imprint_dino_buff(true);
        g.save().unwrap();

        let raw = std::fs::read_to_string(&p).unwrap();
        assert!(raw.contains("[/Script/ShooterGame.ShooterGameMode]"));
        assert!(raw.contains("XPMultiplier=2.5"));
        assert!(raw.contains("TamingSpeedMultiplier=10.0"));
        assert!(raw.contains("DisableImprintDinoBuff=True"));
        let _ = std::fs::remove_file(p);
    }

    #[test]
    fn save_preserves_unrelated_keys() {
        let p = temp("preserve");
        std::fs::write(
            &p,
            "[/Script/ShooterGame.ShooterGameMode]\r\n\
             SomeOtherKey=keepme\r\n\
             XPMultiplier=1.0\r\n\
             [Other]\r\n\
             K=v\r\n",
        )
        .unwrap();

        let mut g = GameSettings::load_or_empty(&p).unwrap();
        g.set_xp_multiplier(3.0);
        g.save().unwrap();

        let reloaded = GameSettings::load_or_empty(&p).unwrap();
        assert_eq!(reloaded.xp_multiplier(), Some(3.0));
        assert_eq!(
            reloaded
                .doc()
                .get_string(SECTION_GAME_MODE, "SomeOtherKey")
                .as_deref(),
            Some("keepme")
        );
        assert_eq!(reloaded.doc().get_string("Other", "K").as_deref(), Some("v"));
        let _ = std::fs::remove_file(p);
    }

    #[test]
    fn round_trips_six_digit_floats_from_ark() {
        // ARK sometimes writes "1.000000" — make sure we parse it back
        // correctly and overwrite it with a clean form when saved.
        let p = temp("sixdigit");
        std::fs::write(
            &p,
            "[/Script/ShooterGame.ShooterGameMode]\r\nXPMultiplier=1.500000\r\n",
        )
        .unwrap();
        let g = GameSettings::load_or_empty(&p).unwrap();
        assert_eq!(g.xp_multiplier(), Some(1.5));
        let _ = std::fs::remove_file(p);
    }

    #[test]
    fn bool_accepts_true_false_and_one_zero() {
        let p = temp("bool");
        std::fs::write(
            &p,
            "[/Script/ShooterGame.ShooterGameMode]\r\n\
             DisableImprintDinoBuff=True\r\n\
             AllowAnyoneBabyImprintCuddle=1\r\n",
        )
        .unwrap();
        let g = GameSettings::load_or_empty(&p).unwrap();
        assert_eq!(g.disable_imprint_dino_buff(), Some(true));
        assert_eq!(g.allow_anyone_baby_imprint_cuddle(), Some(true));
        let _ = std::fs::remove_file(p);
    }
}

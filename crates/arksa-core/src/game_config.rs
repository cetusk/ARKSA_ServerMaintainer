//! ARK SA `Game.ini` wrapper.
//!
//! `Game.ini` is the smaller of the two server config files, but it owns
//! everything the URL parser and `[ServerSettings]` cannot express:
//!
//! - **XP gain breakdown** (`Generic/Harvest/Kill/Craft/...XPMultiplier`)
//! - **Breeding & imprint** (`BabyMatureSpeedMultiplier`,
//!   `BabyImprintAmountMultiplier`, `BabyCuddle*`, …)
//! - **Wild dino food/torpor** (player & tame versions live in `[ServerSettings]`)
//! - **Per-stat arrays** (`PerLevelStatsMultiplier_*[0..11]`,
//!   `PlayerBaseStatMultipliers[0..11]`)
//! - **Loot / crops / spoilage** multipliers
//! - **Structure repair cooldown**, **`PlayerHarvestingDamageMultiplier`**
//! - **Imprint behaviour booleans** (`DisableImprintDinoBuff`,
//!   `AllowAnyoneBabyImprintCuddle`)
//!
//! Everything else the GUI exposes lives in `GameUserSettings.ini` (see
//! `ark_config.rs`). ARK loads both files at startup; live edits while the
//! server is running have no effect.
//!
//! Written values use ARK's conventions: `1.0`-style floats and `True`/`False`
//! booleans. Existing keys we do not model are preserved on save.

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

macro_rules! int_field {
    ($getter:ident, $setter:ident, $key:literal) => {
        pub fn $getter(&self) -> Option<i64> {
            self.doc.get_i64(SECTION_GAME_MODE, $key)
        }
        pub fn $setter(&mut self, v: i64) {
            self.doc.set_i64(SECTION_GAME_MODE, $key, v);
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

#[allow(unused_imports)]
pub(crate) use {bool_field, float_field, int_field};

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

    pub fn doc_mut(&mut self) -> &mut IniDoc {
        &mut self.doc
    }

    pub fn save(&self) -> Result<()> {
        self.doc.save(&self.path)
    }

    // ── Player harvest (genuinely Game.ini) ──────────────────────────
    float_field!(
        player_harvesting_damage_multiplier,
        set_player_harvesting_damage_multiplier,
        "PlayerHarvestingDamageMultiplier"
    );

    // ── Wild dino food/torpor (stamina counterpart lives in GUS) ─────
    float_field!(
        wild_dino_food_drain_multiplier,
        set_wild_dino_food_drain_multiplier,
        "WildDinoCharacterFoodDrainMultiplier"
    );
    float_field!(
        wild_dino_torpor_drain_multiplier,
        set_wild_dino_torpor_drain_multiplier,
        "WildDinoTorporDrainMultiplier"
    );

    // ── Breeding ─────────────────────────────────────────────────────
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
    float_field!(
        mating_speed_multiplier,
        set_mating_speed_multiplier,
        "MatingSpeedMultiplier"
    );
    float_field!(
        lay_egg_interval_multiplier,
        set_lay_egg_interval_multiplier,
        "LayEggIntervalMultiplier"
    );
    float_field!(
        passive_tame_interval_multiplier,
        set_passive_tame_interval_multiplier,
        "PassiveTameIntervalMultiplier"
    );
    float_field!(
        baby_food_consumption_speed_multiplier,
        set_baby_food_consumption_speed_multiplier,
        "BabyFoodConsumptionSpeedMultiplier"
    );
    float_field!(
        baby_imprint_amount_multiplier,
        set_baby_imprint_amount_multiplier,
        "BabyImprintAmountMultiplier"
    );
    float_field!(
        baby_imprinting_stat_scale_multiplier,
        set_baby_imprinting_stat_scale_multiplier,
        "BabyImprintingStatScaleMultiplier"
    );
    float_field!(
        baby_cuddle_interval_multiplier,
        set_baby_cuddle_interval_multiplier,
        "BabyCuddleIntervalMultiplier"
    );
    float_field!(
        baby_cuddle_grace_period_multiplier,
        set_baby_cuddle_grace_period_multiplier,
        "BabyCuddleGracePeriodMultiplier"
    );
    float_field!(
        baby_cuddle_lose_imprint_quality_speed_multiplier,
        set_baby_cuddle_lose_imprint_quality_speed_multiplier,
        "BabyCuddleLoseImprintQualitySpeedMultiplier"
    );
    bool_field!(
        disable_dino_breeding,
        set_disable_dino_breeding,
        "bDisableDinoBreeding"
    );
    bool_field!(
        disable_dino_taming,
        set_disable_dino_taming,
        "bDisableDinoTaming"
    );

    // ── Structure (repair cooldown is a Game.ini-only knob) ──────────
    float_field!(
        structure_damage_repair_cooldown,
        set_structure_damage_repair_cooldown,
        "StructureDamageRepairCooldown"
    );

    // ── Imprint behaviour ────────────────────────────────────────────
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

    // ── Loot / crops (Phase 8d) ──────────────────────────────────────
    float_field!(
        supply_crate_loot_quality_multiplier,
        set_supply_crate_loot_quality_multiplier,
        "SupplyCrateLootQualityMultiplier"
    );
    float_field!(
        fishing_loot_quality_multiplier,
        set_fishing_loot_quality_multiplier,
        "FishingLootQualityMultiplier"
    );
    float_field!(
        crop_decay_speed_multiplier,
        set_crop_decay_speed_multiplier,
        "CropDecaySpeedMultiplier"
    );
    float_field!(
        crop_growth_speed_multiplier,
        set_crop_growth_speed_multiplier,
        "CropGrowthSpeedMultiplier"
    );
    bool_field!(disable_loot_crates, set_disable_loot_crates, "bDisableLootCrates");
    int_field!(
        limit_non_player_dropped_items_count,
        set_limit_non_player_dropped_items_count,
        "LimitNonPlayerDroppedItemsCount"
    );
    int_field!(
        limit_non_player_dropped_items_range,
        set_limit_non_player_dropped_items_range,
        "LimitNonPlayerDroppedItemsRange"
    );

    // ── Spoilage / decomposition (Phase 8d) ──────────────────────────
    float_field!(
        global_item_decomposition_time_multiplier,
        set_global_item_decomposition_time_multiplier,
        "GlobalItemDecompositionTimeMultiplier"
    );
    float_field!(
        global_spoiling_time_multiplier,
        set_global_spoiling_time_multiplier,
        "GlobalSpoilingTimeMultiplier"
    );
    float_field!(
        global_corpse_decomposition_time_multiplier,
        set_global_corpse_decomposition_time_multiplier,
        "GlobalCorpseDecompositionTimeMultiplier"
    );
    float_field!(
        use_corpse_life_span_multiplier,
        set_use_corpse_life_span_multiplier,
        "UseCorpseLifeSpanMultiplier"
    );
    bool_field!(use_corpse_locator, set_use_corpse_locator, "bUseCorpseLocator");
    float_field!(
        poop_interval_multiplier,
        set_poop_interval_multiplier,
        "PoopIntervalMultiplier"
    );
    float_field!(
        fuel_consumption_interval_multiplier,
        set_fuel_consumption_interval_multiplier,
        "FuelConsumptionIntervalMultiplier"
    );
    float_field!(
        max_fall_speed_multiplier,
        set_max_fall_speed_multiplier,
        "MaxFallSpeedMultiplier"
    );

    // ── Stat arrays (Phase 8e) ───────────────────────────────────────
    //
    // Six 12-element float arrays. Indices map to:
    //   0=Health 1=Stamina 2=Torpidity 3=Oxygen 4=Food 5=Water
    //   6=Temperature 7=Weight 8=MeleeDamage 9=Speed 10=Fortitude
    //   11=CraftingSpeed
    //
    // ARK encodes each element as `Key[index]=value` in the same section.
    // We expose them via indexed accessors rather than 72 individual macro
    // expansions to keep the surface area sane.

    pub fn per_level_stats_multiplier_player(&self, idx: u8) -> Option<f64> {
        self.doc.get_f64(SECTION_GAME_MODE, &format!("PerLevelStatsMultiplier_Player[{idx}]"))
    }
    pub fn set_per_level_stats_multiplier_player(&mut self, idx: u8, v: f64) {
        self.doc.set_f64(SECTION_GAME_MODE, &format!("PerLevelStatsMultiplier_Player[{idx}]"), v);
    }

    pub fn per_level_stats_multiplier_dino_tamed(&self, idx: u8) -> Option<f64> {
        self.doc.get_f64(SECTION_GAME_MODE, &format!("PerLevelStatsMultiplier_DinoTamed[{idx}]"))
    }
    pub fn set_per_level_stats_multiplier_dino_tamed(&mut self, idx: u8, v: f64) {
        self.doc.set_f64(SECTION_GAME_MODE, &format!("PerLevelStatsMultiplier_DinoTamed[{idx}]"), v);
    }

    pub fn per_level_stats_multiplier_dino_tamed_add(&self, idx: u8) -> Option<f64> {
        self.doc.get_f64(SECTION_GAME_MODE, &format!("PerLevelStatsMultiplier_DinoTamed_Add[{idx}]"))
    }
    pub fn set_per_level_stats_multiplier_dino_tamed_add(&mut self, idx: u8, v: f64) {
        self.doc.set_f64(SECTION_GAME_MODE, &format!("PerLevelStatsMultiplier_DinoTamed_Add[{idx}]"), v);
    }

    pub fn per_level_stats_multiplier_dino_tamed_affinity(&self, idx: u8) -> Option<f64> {
        self.doc.get_f64(SECTION_GAME_MODE, &format!("PerLevelStatsMultiplier_DinoTamed_Affinity[{idx}]"))
    }
    pub fn set_per_level_stats_multiplier_dino_tamed_affinity(&mut self, idx: u8, v: f64) {
        self.doc.set_f64(SECTION_GAME_MODE, &format!("PerLevelStatsMultiplier_DinoTamed_Affinity[{idx}]"), v);
    }

    pub fn per_level_stats_multiplier_dino_wild(&self, idx: u8) -> Option<f64> {
        self.doc.get_f64(SECTION_GAME_MODE, &format!("PerLevelStatsMultiplier_DinoWild[{idx}]"))
    }
    pub fn set_per_level_stats_multiplier_dino_wild(&mut self, idx: u8, v: f64) {
        self.doc.set_f64(SECTION_GAME_MODE, &format!("PerLevelStatsMultiplier_DinoWild[{idx}]"), v);
    }

    pub fn player_base_stat_multipliers(&self, idx: u8) -> Option<f64> {
        self.doc.get_f64(SECTION_GAME_MODE, &format!("PlayerBaseStatMultipliers[{idx}]"))
    }
    pub fn set_player_base_stat_multipliers(&mut self, idx: u8, v: f64) {
        self.doc.set_f64(SECTION_GAME_MODE, &format!("PlayerBaseStatMultipliers[{idx}]"), v);
    }

    // ── Combat (Phase 8f) ────────────────────────────────────────────
    float_field!(
        dino_harvesting_damage_multiplier,
        set_dino_harvesting_damage_multiplier,
        "DinoHarvestingDamageMultiplier"
    );
    float_field!(
        dino_turret_damage_multiplier,
        set_dino_turret_damage_multiplier,
        "DinoTurretDamageMultiplier"
    );
    bool_field!(allow_speed_leveling, set_allow_speed_leveling, "bAllowSpeedLeveling");
    bool_field!(
        allow_flyer_speed_leveling,
        set_allow_flyer_speed_leveling,
        "bAllowFlyerSpeedLeveling"
    );
    bool_field!(disable_friendly_fire, set_disable_friendly_fire, "bDisableFriendlyFire");
    bool_field!(
        pve_disable_friendly_fire,
        set_pve_disable_friendly_fire,
        "bPvEDisableFriendlyFire"
    );
    bool_field!(
        allow_unlimited_respecs,
        set_allow_unlimited_respecs,
        "bAllowUnlimitedRespecs"
    );

    // ── Turret limits (Phase 8f) ─────────────────────────────────────
    bool_field!(
        hard_limit_turrets_in_range,
        set_hard_limit_turrets_in_range,
        "bHardLimitTurretsInRange"
    );
    bool_field!(
        limit_turrets_in_range,
        set_limit_turrets_in_range,
        "bLimitTurretsInRange"
    );
    int_field!(limit_turrets_num, set_limit_turrets_num, "LimitTurretsNum");
    float_field!(limit_turrets_range, set_limit_turrets_range, "LimitTurretsRange");

    // ── XP gain breakdown (Phase 8g) ─────────────────────────────────
    float_field!(generic_xp_multiplier, set_generic_xp_multiplier, "GenericXPMultiplier");
    float_field!(harvest_xp_multiplier, set_harvest_xp_multiplier, "HarvestXPMultiplier");
    float_field!(kill_xp_multiplier, set_kill_xp_multiplier, "KillXPMultiplier");
    float_field!(craft_xp_multiplier, set_craft_xp_multiplier, "CraftXPMultiplier");
    float_field!(special_xp_multiplier, set_special_xp_multiplier, "SpecialXPMultiplier");
    float_field!(
        explorer_note_xp_multiplier,
        set_explorer_note_xp_multiplier,
        "ExplorerNoteXPMultiplier"
    );
    float_field!(boss_kill_xp_multiplier, set_boss_kill_xp_multiplier, "BossKillXPMultiplier");
    float_field!(cave_kill_xp_multiplier, set_cave_kill_xp_multiplier, "CaveKillXPMultiplier");
    float_field!(wild_kill_xp_multiplier, set_wild_kill_xp_multiplier, "WildKillXPMultiplier");
    float_field!(tamed_kill_xp_multiplier, set_tamed_kill_xp_multiplier, "TamedKillXPMultiplier");
    float_field!(
        unclaimed_kill_xp_multiplier,
        set_unclaimed_kill_xp_multiplier,
        "UnclaimedKillXPMultiplier"
    );
    float_field!(alpha_kill_xp_multiplier, set_alpha_kill_xp_multiplier, "AlphaKillXPMultiplier");
    int_field!(
        override_max_experience_points_player,
        set_override_max_experience_points_player,
        "OverrideMaxExperiencePointsPlayer"
    );
    int_field!(
        override_max_experience_points_dino,
        set_override_max_experience_points_dino,
        "OverrideMaxExperiencePointsDino"
    );
}

/// Stat-index labels matching ARK's `PerLevelStatsMultiplier_*[i]` ordering.
pub const STAT_NAMES: [&str; 12] = [
    "Health",
    "Stamina",
    "Torpidity",
    "Oxygen",
    "Food",
    "Water",
    "Temperature",
    "Weight",
    "MeleeDamage",
    "Speed",
    "Fortitude",
    "CraftingSpeed",
];

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
        g.set_baby_mature_speed_multiplier(10.0);
        g.set_disable_imprint_dino_buff(true);
        g.save().unwrap();

        let raw = std::fs::read_to_string(&p).unwrap();
        assert!(raw.contains("[/Script/ShooterGame.ShooterGameMode]"));
        assert!(raw.contains("BabyMatureSpeedMultiplier=10.0"));
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
             BabyMatureSpeedMultiplier=1.0\r\n\
             [Other]\r\n\
             K=v\r\n",
        )
        .unwrap();

        let mut g = GameSettings::load_or_empty(&p).unwrap();
        g.set_baby_mature_speed_multiplier(3.0);
        g.save().unwrap();

        let r = GameSettings::load_or_empty(&p).unwrap();
        assert_eq!(r.baby_mature_speed_multiplier(), Some(3.0));
        assert_eq!(
            r.doc().get_string(SECTION_GAME_MODE, "SomeOtherKey").as_deref(),
            Some("keepme")
        );
        assert_eq!(r.doc().get_string("Other", "K").as_deref(), Some("v"));
        let _ = std::fs::remove_file(p);
    }

    #[test]
    fn round_trips_six_digit_floats_from_ark() {
        let p = temp("sixdigit");
        std::fs::write(
            &p,
            "[/Script/ShooterGame.ShooterGameMode]\r\nBabyMatureSpeedMultiplier=1.500000\r\n",
        )
        .unwrap();
        let g = GameSettings::load_or_empty(&p).unwrap();
        assert_eq!(g.baby_mature_speed_multiplier(), Some(1.5));
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

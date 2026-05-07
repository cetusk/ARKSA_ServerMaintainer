//! ARK SA dedicated server config files (`GameUserSettings.ini`, `Game.ini`).
//!
//! Authoritative for almost everything the server admin tunes. The vast
//! majority of multipliers (XP / harvest / taming / drain / day cycle /
//! structures / dino / player) live in `[ServerSettings]` of
//! `GameUserSettings.ini` and only a focused subset (breeding rates, XP
//! breakdown, stat arrays) live in `Game.ini` (see `game_config.rs`).
//!
//! `ServerAdminPassword`, `RCONEnabled`, `RCONPort` cannot be reliably passed
//! through the launch URL — ARK SA's URL parser folds the rest of the URL
//! into the password string and silently disables RCON. Writing them straight
//! into `[ServerSettings]` of `GameUserSettings.ini` bypasses the bug; the
//! URL parser ignores keys it does not see.

use std::path::{Path, PathBuf};

use crate::error::Result;
use crate::ini_doc::IniDoc;

/// `[ServerSettings]` section in `GameUserSettings.ini`.
pub const SECTION_SERVER_SETTINGS: &str = "ServerSettings";

/// `[MessageOfTheDay]` section in `GameUserSettings.ini` — holds the
/// MOTD text + display duration shown to joining players.
pub const SECTION_MESSAGE_OF_THE_DAY: &str = "MessageOfTheDay";

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

/// Wrapper over `GameUserSettings.ini` exposing the keys we model. All other
/// settings round-trip untouched (the underlying `IniDoc` preserves them).
#[derive(Debug)]
pub struct GameUserSettings {
    path: PathBuf,
    doc: IniDoc,
}

macro_rules! float_field {
    ($getter:ident, $setter:ident, $key:literal) => {
        pub fn $getter(&self) -> Option<f64> {
            self.doc.get_f64(SECTION_SERVER_SETTINGS, $key)
        }
        pub fn $setter(&mut self, v: f64) {
            self.doc.set_f64(SECTION_SERVER_SETTINGS, $key, v);
        }
    };
}

macro_rules! int_field {
    ($getter:ident, $setter:ident, $key:literal) => {
        pub fn $getter(&self) -> Option<i64> {
            self.doc.get_i64(SECTION_SERVER_SETTINGS, $key)
        }
        pub fn $setter(&mut self, v: i64) {
            self.doc.set_i64(SECTION_SERVER_SETTINGS, $key, v);
        }
    };
}

macro_rules! bool_field {
    ($getter:ident, $setter:ident, $key:literal) => {
        pub fn $getter(&self) -> Option<bool> {
            self.doc
                .get_string(SECTION_SERVER_SETTINGS, $key)
                .map(|v| matches!(v.trim(), s if s.eq_ignore_ascii_case("true") || s == "1"))
        }
        pub fn $setter(&mut self, v: bool) {
            // ARK writes "True"/"False" (capital initial) in this file, so
            // match upstream rather than IniDoc::set_bool's 0/1 form.
            self.doc.set_string(
                SECTION_SERVER_SETTINGS,
                $key,
                if v { "True" } else { "False" },
            );
        }
    };
}

macro_rules! string_field {
    ($getter:ident, $setter:ident, $key:literal) => {
        pub fn $getter(&self) -> Option<String> {
            self.doc.get_string(SECTION_SERVER_SETTINGS, $key)
        }
        pub fn $setter(&mut self, v: &str) {
            self.doc.set_string(SECTION_SERVER_SETTINGS, $key, v);
        }
    };
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

    // ── RCON / admin ─────────────────────────────────────────────────
    bool_field!(rcon_enabled, set_rcon_enabled, "RCONEnabled");
    string_field!(admin_password, set_admin_password, "ServerAdminPassword");

    pub fn rcon_port(&self) -> Option<u16> {
        self.doc
            .get_i64(SECTION_SERVER_SETTINGS, "RCONPort")
            .and_then(|n| u16::try_from(n).ok())
    }

    pub fn set_rcon_port(&mut self, port: u16) {
        self.doc
            .set_i64(SECTION_SERVER_SETTINGS, "RCONPort", port as i64);
    }

    // ── Difficulty ───────────────────────────────────────────────────
    float_field!(difficulty_offset, set_difficulty_offset, "DifficultyOffset");
    float_field!(
        override_official_difficulty,
        set_override_official_difficulty,
        "OverrideOfficialDifficulty"
    );

    // ── Rates (multipliers) ──────────────────────────────────────────
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

    // ── Day / night cycle ────────────────────────────────────────────
    float_field!(
        day_cycle_speed_scale,
        set_day_cycle_speed_scale,
        "DayCycleSpeedScale"
    );
    float_field!(
        day_time_speed_scale,
        set_day_time_speed_scale,
        "DayTimeSpeedScale"
    );
    float_field!(
        night_time_speed_scale,
        set_night_time_speed_scale,
        "NightTimeSpeedScale"
    );

    // ── Player tuning ────────────────────────────────────────────────
    float_field!(
        player_food_drain_multiplier,
        set_player_food_drain_multiplier,
        "PlayerCharacterFoodDrainMultiplier"
    );
    float_field!(
        player_water_drain_multiplier,
        set_player_water_drain_multiplier,
        "PlayerCharacterWaterDrainMultiplier"
    );
    float_field!(
        player_stamina_drain_multiplier,
        set_player_stamina_drain_multiplier,
        "PlayerCharacterStaminaDrainMultiplier"
    );
    float_field!(
        player_health_recovery_multiplier,
        set_player_health_recovery_multiplier,
        "PlayerCharacterHealthRecoveryMultiplier"
    );
    float_field!(
        player_damage_multiplier,
        set_player_damage_multiplier,
        "PlayerDamageMultiplier"
    );
    float_field!(
        player_resistance_multiplier,
        set_player_resistance_multiplier,
        "PlayerResistanceMultiplier"
    );

    // ── Tamed dino tuning ────────────────────────────────────────────
    float_field!(
        dino_food_drain_multiplier,
        set_dino_food_drain_multiplier,
        "DinoCharacterFoodDrainMultiplier"
    );
    float_field!(
        dino_stamina_drain_multiplier,
        set_dino_stamina_drain_multiplier,
        "DinoCharacterStaminaDrainMultiplier"
    );
    float_field!(
        dino_health_recovery_multiplier,
        set_dino_health_recovery_multiplier,
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

    // ── Wild dino (note: wild stamina lives here, not in Game.ini) ──
    float_field!(
        wild_dino_stamina_drain_multiplier,
        set_wild_dino_stamina_drain_multiplier,
        "WildDinoCharacterStaminaDrainMultiplier"
    );
    float_field!(
        dino_count_multiplier,
        set_dino_count_multiplier,
        "DinoCountMultiplier"
    );

    // ── Structures ───────────────────────────────────────────────────
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

    // ── PvE / PvP ────────────────────────────────────────────────────
    bool_field!(server_pve, set_server_pve, "serverPVE");
    bool_field!(allow_flyer_carry_pve, set_allow_flyer_carry_pve, "AllowFlyerCarryPvE");
    bool_field!(
        enable_cryo_sickness_pve,
        set_enable_cryo_sickness_pve,
        "EnableCryoSicknessPVE"
    );
    bool_field!(
        disable_structure_decay_pve,
        set_disable_structure_decay_pve,
        "DisableStructureDecayPvE"
    );

    // ── Operations basics ────────────────────────────────────────────
    float_field!(max_tamed_dinos, set_max_tamed_dinos, "MaxTamedDinos");
    float_field!(
        kick_idle_players_period,
        set_kick_idle_players_period,
        "KickIdlePlayersPeriod"
    );
    float_field!(
        auto_save_period_minutes,
        set_auto_save_period_minutes,
        "AutoSavePeriodMinutes"
    );
    int_field!(
        the_max_structures_in_range,
        set_the_max_structures_in_range,
        "TheMaxStructuresInRange"
    );

    // ── Structures (Phase 8f) ────────────────────────────────────────
    float_field!(
        structure_prevent_resource_radius_multiplier,
        set_structure_prevent_resource_radius_multiplier,
        "StructurePreventResourceRadiusMultiplier"
    );
    float_field!(
        per_platform_max_structures_multiplier,
        set_per_platform_max_structures_multiplier,
        "PerPlatformMaxStructuresMultiplier"
    );
    bool_field!(
        always_allow_structure_pickup,
        set_always_allow_structure_pickup,
        "AlwaysAllowStructurePickup"
    );
    float_field!(
        structure_pickup_time_after_placement,
        set_structure_pickup_time_after_placement,
        "StructurePickupTimeAfterPlacement"
    );
    float_field!(
        structure_pickup_hold_duration,
        set_structure_pickup_hold_duration,
        "StructurePickupHoldDuration"
    );
    int_field!(
        max_platform_saddle_structure_limit,
        set_max_platform_saddle_structure_limit,
        "MaxPlatformSaddleStructureLimit"
    );

    // ── Cryopod nerf block (Phase 8f) ────────────────────────────────
    bool_field!(enable_cryopod_nerf, set_enable_cryopod_nerf, "EnableCryopodNerf");
    float_field!(
        cryopod_nerf_damage_mult,
        set_cryopod_nerf_damage_mult,
        "CryopodNerfDamageMult"
    );
    float_field!(
        cryopod_nerf_duration,
        set_cryopod_nerf_duration,
        "CryopodNerfDuration"
    );
    bool_field!(
        allow_cryo_fridge_on_saddle,
        set_allow_cryo_fridge_on_saddle,
        "AllowCryoFridgeOnSaddle"
    );
    bool_field!(
        disable_cryopod_fridge_requirement,
        set_disable_cryopod_fridge_requirement,
        "DisableCryopodFridgeRequirement"
    );
    // ── Cryopod additions (Phase 8T) ─────────────────────────────────
    float_field!(
        cryopod_nerf_incoming_damage_mult_percent,
        set_cryopod_nerf_incoming_damage_mult_percent,
        "CryopodNerfIncomingDamageMultPercent"
    );
    bool_field!(
        disable_cryopod_enemy_check,
        set_disable_cryopod_enemy_check,
        "DisableCryopodEnemyCheck"
    );
    int_field!(
        cryopod_fridge_cooldowntime,
        set_cryopod_fridge_cooldowntime,
        "CryopodFridgeCooldowntime"
    );

    // ── Cosmetic / Chat (Phase 8h) ───────────────────────────────────
    bool_field!(global_voice_chat, set_global_voice_chat, "globalVoiceChat");
    bool_field!(proximity_chat, set_proximity_chat, "ProximityChat");
    bool_field!(
        dont_always_notify_player_joined,
        set_dont_always_notify_player_joined,
        "DontAlwaysNotifyPlayerJoined"
    );
    bool_field!(
        always_notify_player_left,
        set_always_notify_player_left,
        "AlwaysNotifyPlayerLeft"
    );
    bool_field!(admin_logging, set_admin_logging, "AdminLogging");
    bool_field!(
        allow_hide_damage_source_from_logs,
        set_allow_hide_damage_source_from_logs,
        "AllowHideDamageSourceFromLogs"
    );
    bool_field!(
        show_floating_damage_text,
        set_show_floating_damage_text,
        "ShowFloatingDamageText"
    );
    bool_field!(
        show_map_player_location,
        set_show_map_player_location,
        "ShowMapPlayerLocation"
    );
    bool_field!(server_crosshair, set_server_crosshair, "ServerCrosshair");
    bool_field!(server_force_no_hud, set_server_force_no_hud, "ServerForceNoHUD");
    bool_field!(
        allow_third_person_player,
        set_allow_third_person_player,
        "AllowThirdPersonPlayer"
    );
    bool_field!(allow_hit_markers, set_allow_hit_markers, "AllowHitMarkers");
    bool_field!(disable_pve_gamma, set_disable_pve_gamma, "DisablePvEGamma");
    bool_field!(enable_pvp_gamma, set_enable_pvp_gamma, "EnablePvPGamma");

    // ── Cluster / Lists (Phase 8i) ───────────────────────────────────
    string_field!(server_password, set_server_password, "ServerPassword");
    string_field!(ban_list_url, set_ban_list_url, "BanListURL");
    string_field!(admin_list_url, set_admin_list_url, "AdminListURL");
    string_field!(bad_word_list_url, set_bad_word_list_url, "BadWordListURL");
    string_field!(
        bad_word_white_list_url,
        set_bad_word_white_list_url,
        "BadWordWhiteListURL"
    );
    string_field!(
        custom_live_tuning_url,
        set_custom_live_tuning_url,
        "CustomLiveTuningUrl"
    );
    bool_field!(no_tribute_downloads, set_no_tribute_downloads, "noTributeDownloads");
    bool_field!(
        prevent_download_dinos,
        set_prevent_download_dinos,
        "PreventDownloadDinos"
    );
    bool_field!(
        prevent_download_items,
        set_prevent_download_items,
        "PreventDownloadItems"
    );
    bool_field!(
        prevent_download_survivors,
        set_prevent_download_survivors,
        "PreventDownloadSurvivors"
    );
    bool_field!(prevent_upload_dinos, set_prevent_upload_dinos, "PreventUploadDinos");
    bool_field!(prevent_upload_items, set_prevent_upload_items, "PreventUploadItems");
    bool_field!(
        prevent_upload_survivors,
        set_prevent_upload_survivors,
        "PreventUploadSurvivors"
    );
    bool_field!(
        cross_ark_allow_foreign_dino_downloads,
        set_cross_ark_allow_foreign_dino_downloads,
        "CrossARKAllowForeignDinoDownloads"
    );
    bool_field!(
        prevent_tribe_alliances,
        set_prevent_tribe_alliances,
        "PreventTribeAlliances"
    );
    int_field!(
        max_number_of_players_in_tribe,
        set_max_number_of_players_in_tribe,
        "MaxNumberOfPlayersInTribe"
    );

    // ── Stat clamps / Blueprint caps (Phase 8j) ──────────────────────
    int_field!(
        max_blueprint_dino_level,
        set_max_blueprint_dino_level,
        "MaxBlueprintDinoLevel"
    );
    int_field!(
        max_blueprint_dino_quality,
        set_max_blueprint_dino_quality,
        "MaxBlueprintDinoQuality"
    );
    int_field!(
        max_blueprint_item_quality,
        set_max_blueprint_item_quality,
        "MaxBlueprintItemQuality"
    );
    int_field!(
        max_blueprint_scout_quality,
        set_max_blueprint_scout_quality,
        "MaxBlueprintScoutQuality"
    );
    int_field!(
        max_hexagons_per_character,
        set_max_hexagons_per_character,
        "MaxHexagonsPerCharacter"
    );
    bool_field!(
        clamp_item_spoiling_times,
        set_clamp_item_spoiling_times,
        "ClampItemSpoilingTimes"
    );
    bool_field!(clamp_item_stats, set_clamp_item_stats, "ClampItemStats");
    bool_field!(
        clamp_resource_harvest_damage,
        set_clamp_resource_harvest_damage,
        "ClampResourceHarvestDamage"
    );
    int_field!(implant_suicide_cd, set_implant_suicide_cd, "ImplantSuicideCD");
    float_field!(
        server_auto_force_respawn_wild_dinos_interval,
        set_server_auto_force_respawn_wild_dinos_interval,
        "ServerAutoForceRespawnWildDinosInterval"
    );

    // ── PvP / decay (Phase 8L — covering an existing real-world config) ─
    bool_field!(
        fast_decay_unsnapped_core_structures,
        set_fast_decay_unsnapped_core_structures,
        "FastDecayUnsnappedCoreStructures"
    );
    bool_field!(
        override_structure_platform_prevention,
        set_override_structure_platform_prevention,
        "OverrideStructurePlatformPrevention"
    );
    bool_field!(prevent_offline_pvp, set_prevent_offline_pvp, "PreventOfflinePvP");
    float_field!(
        prevent_offline_pvp_interval,
        set_prevent_offline_pvp_interval,
        "PreventOfflinePvPInterval"
    );
    bool_field!(pvp_dino_decay, set_pvp_dino_decay, "PvPDinoDecay");
    bool_field!(pvp_structure_decay, set_pvp_structure_decay, "PvPStructureDecay");
    float_field!(
        pve_dino_decay_period_multiplier,
        set_pve_dino_decay_period_multiplier,
        "PvEDinoDecayPeriodMultiplier"
    );
    bool_field!(
        only_auto_destroy_core_structures,
        set_only_auto_destroy_core_structures,
        "OnlyAutoDestroyCoreStructures"
    );
    bool_field!(
        auto_destroy_decayed_dinos,
        set_auto_destroy_decayed_dinos,
        "AutoDestroyDecayedDinos"
    );
    bool_field!(
        tribe_log_destroyed_enemy_structures,
        set_tribe_log_destroyed_enemy_structures,
        "TribeLogDestroyedEnemyStructures"
    );
    bool_field!(
        pve_allow_structures_at_supply_drops,
        set_pve_allow_structures_at_supply_drops,
        "PvEAllowStructuresAtSupplyDrops"
    );

    // ── Multipliers / 物量系 ─────────────────────────────────────────
    float_field!(
        oxygen_swim_speed_stat_multiplier,
        set_oxygen_swim_speed_stat_multiplier,
        "OxygenSwimSpeedStatMultiplier"
    );
    float_field!(
        tribe_name_change_cooldown,
        set_tribe_name_change_cooldown,
        "TribeNameChangeCooldown"
    );
    float_field!(
        platform_saddle_build_area_bounds_multiplier,
        set_platform_saddle_build_area_bounds_multiplier,
        "PlatformSaddleBuildAreaBoundsMultiplier"
    );
    float_field!(
        raid_dino_character_food_drain_multiplier,
        set_raid_dino_character_food_drain_multiplier,
        "RaidDinoCharacterFoodDrainMultiplier"
    );
    float_field!(
        item_stack_size_multiplier,
        set_item_stack_size_multiplier,
        "ItemStackSizeMultiplier"
    );

    // ── Misc behaviour / safety / disease ────────────────────────────
    float_field!(start_time_hour, set_start_time_hour, "StartTimeHour");
    int_field!(
        rcon_server_game_log_buffer,
        set_rcon_server_game_log_buffer,
        "RCONServerGameLogBuffer"
    );
    bool_field!(
        allow_raid_dino_feeding,
        set_allow_raid_dino_feeding,
        "AllowRaidDinoFeeding"
    );
    bool_field!(
        enable_extra_structure_prevention_volumes,
        set_enable_extra_structure_prevention_volumes,
        "EnableExtraStructurePreventionVolumes"
    );
    bool_field!(
        prevent_spawn_animations,
        set_prevent_spawn_animations,
        "PreventSpawnAnimations"
    );
    bool_field!(prevent_diseases, set_prevent_diseases, "PreventDiseases");
    bool_field!(
        non_permanent_diseases,
        set_non_permanent_diseases,
        "NonPermanentDiseases"
    );
    bool_field!(
        use_optimized_harvesting_health,
        set_use_optimized_harvesting_health,
        "UseOptimizedHarvestingHealth"
    );
    bool_field!(
        allow_multiple_attached_c4,
        set_allow_multiple_attached_c4,
        "AllowMultipleAttachedC4"
    );
    bool_field!(
        allow_flying_stamina_recovery,
        set_allow_flying_stamina_recovery,
        "AllowFlyingStaminaRecovery"
    );
    bool_field!(
        allow_crate_spawns_on_top_of_structures,
        set_allow_crate_spawns_on_top_of_structures,
        "AllowCrateSpawnsOnTopOfStructures"
    );

    // ── Phase 8P: MOTD ([MessageOfTheDay] section, not [ServerSettings]) ─
    pub fn motd_message(&self) -> Option<String> {
        self.doc.get_string(SECTION_MESSAGE_OF_THE_DAY, "Message")
    }
    pub fn set_motd_message(&mut self, v: &str) {
        self.doc.set_string(SECTION_MESSAGE_OF_THE_DAY, "Message", v);
    }
    pub fn motd_duration(&self) -> Option<i64> {
        self.doc.get_i64(SECTION_MESSAGE_OF_THE_DAY, "Duration")
    }
    pub fn set_motd_duration(&mut self, v: i64) {
        self.doc.set_i64(SECTION_MESSAGE_OF_THE_DAY, "Duration", v);
    }
}

/// Keys that Phase 8M briefly modelled inside `[ServerSettings]` but which
/// the ARK Wiki / engine actually reads from `Game.ini
/// [/Script/ShooterGame.ShooterGameMode]`. Phase 8S (revert) routes them
/// back to `Game.ini`, and on Save we strip any leftover entries from
/// `[ServerSettings]` so a stale duplicate can't compete with the
/// canonical Game.ini value.
pub const LEGACY_GUS_BREEDING_LOOT_KEYS: &[&str] = &[
    "MatingIntervalMultiplier",
    "EggHatchSpeedMultiplier",
    "BabyMatureSpeedMultiplier",
    "BabyFoodConsumptionSpeedMultiplier",
    "BabyImprintAmountMultiplier",
    "BabyImprintingStatScaleMultiplier",
    "BabyCuddleIntervalMultiplier",
    "BabyCuddleGracePeriodMultiplier",
    "BabyCuddleLoseImprintQualitySpeedMultiplier",
    "SupplyCrateLootQualityMultiplier",
    "FishingLootQualityMultiplier",
    "CropDecaySpeedMultiplier",
];

impl GameUserSettings {
    /// Strip every Phase 8M-era misrouted breeding/loot key from
    /// `[ServerSettings]`. Idempotent.
    pub fn cleanup_legacy_breeding_loot_keys(&mut self) {
        for k in LEGACY_GUS_BREEDING_LOOT_KEYS {
            self.doc.remove_key(SECTION_SERVER_SETTINGS, k);
        }
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
        assert!(!raw.contains("\\\\"));
        let _ = std::fs::remove_file(p);
    }

    #[test]
    fn write_rcon_settings_preserves_unrelated_keys() {
        let p = temp_path("preserve");
        let _ = std::fs::remove_file(&p);
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

    #[test]
    fn multipliers_and_pvp_round_trip() {
        let p = temp_path("multi_pvp");
        let _ = std::fs::remove_file(&p);
        let mut gus = GameUserSettings::load_or_empty(&p).unwrap();
        gus.set_xp_multiplier(2.5);
        gus.set_taming_speed_multiplier(10.0);
        gus.set_server_pve(true);
        gus.set_max_tamed_dinos(5000.0);
        gus.set_the_max_structures_in_range(10500);
        gus.save().unwrap();

        let raw = std::fs::read_to_string(&p).unwrap();
        assert!(raw.contains("XPMultiplier=2.5"));
        assert!(raw.contains("TamingSpeedMultiplier=10.0"));
        assert!(raw.contains("serverPVE=True"));
        assert!(raw.contains("MaxTamedDinos=5000.0"));
        assert!(raw.contains("TheMaxStructuresInRange=10500"));

        let r = GameUserSettings::load_or_empty(&p).unwrap();
        assert_eq!(r.xp_multiplier(), Some(2.5));
        assert_eq!(r.server_pve(), Some(true));
        assert_eq!(r.the_max_structures_in_range(), Some(10500));
        let _ = std::fs::remove_file(p);
    }
}

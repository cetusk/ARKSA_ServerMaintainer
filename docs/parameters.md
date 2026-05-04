# ARK SA Server Parameters Reference

Comprehensive list of ARK Survival Ascended server-side configuration parameters,
extracted from upstream ASASM source (`_forked/frameui.pas` — the reference
implementation we are porting from) and cross-referenced with the official
[ARK Survival Ascended Server Configuration wiki](https://ark.wiki.gg/wiki/Server_configuration).

Use this document to:

- Find which file / section a given parameter belongs in.
- See whether the **World Settings dialog** in `arksa-gui` covers it (✅) or you
  need to edit the INI by hand (⚠️).
- Plan future Phase 8b–8c expansions of the GUI.

---

## 1. Where parameters live

ARK SA reads three primary config files at server startup and never re-reads
them — every change requires a restart.

| File | Section we care about | Typical contents |
|---|---|---|
| `<install>/ShooterGame/Saved/Config/WindowsServer/`**`GameUserSettings.ini`** | `[ServerSettings]` | Most server toggles + multipliers, RCON, admin password, PvE/PvP flag |
| (same dir) **`Game.ini`** | `[/Script/ShooterGame.ShooterGameMode]` | Detailed game-mode multipliers, per-stat / per-level scaling, breeding / imprint, spawn overrides, engram unlocks |
| (same dir) **`Engine.ini`** | `[/Script/OnlineSubsystemUtils.IpNetDriver]` `[OnlineSubsystemSteam]` `[HTTP]` | Network timeouts, P2P timeout, HTTP timeouts |
| **`MM_Command_Val`** in profile INI | — | One-shot URL `?key=value` and `-flag` arguments passed at server launch |

**Counts (extracted from upstream):**

| Source | Count |
|---|---|
| `[ServerSettings]` keys (GameUserSettings.ini) | **~178** |
| `[/Script/ShooterGame.ShooterGameMode]` keys (Game.ini) | **~170** |
| URL `?key=value` parameters | **4** (Port / Queryport / RCONPort / AltSaveDirectoryName) |
| URL `-flag` arguments | **~58** |
| Engine.ini network/HTTP keys | **7** |
| Mod-specific sections (`[Cryopods]`, `[SuperSpyglassPlus]`, etc.) | many more |

> Several upstream parameters are mod-specific (Cryopods, QoLPlus, etc.) and
> only relevant when those mods are loaded. They are excluded from the core
> tables below; see the bottom of this document for the mod section list.

---

## 2. Coverage by the World Settings dialog (Phase 8a)

The current GUI exposes 30 fields across 6 tabs. Mapping to the upstream
authoring layout:

### Currently in the dialog

| Dialog tab | Field | Canonical destination |
|---|---|---|
| **Rates** | `XPMultiplier` | GUS `[ServerSettings]` |
| Rates | `HarvestAmountMultiplier` | GUS `[ServerSettings]` |
| Rates | `HarvestHealthMultiplier` | GUS `[ServerSettings]` |
| Rates | `ResourcesRespawnPeriodMultiplier` | GUS `[ServerSettings]` |
| Rates | `TamingSpeedMultiplier` | GUS `[ServerSettings]` |
| Rates | `MatingIntervalMultiplier` | Game.ini `[/Script/ShooterGame.ShooterGameMode]` |
| Rates | `EggHatchSpeedMultiplier` | Game.ini |
| Rates | `BabyMatureSpeedMultiplier` | Game.ini |
| **Day cycle** | `DayCycleSpeedScale` `DayTimeSpeedScale` `NightTimeSpeedScale` | GUS `[ServerSettings]` |
| **Player** | `PlayerCharacterFood/Water/Stamina/HealthRecoveryMultiplier` | GUS `[ServerSettings]` |
| Player | `PlayerDamageMultiplier` `PlayerResistanceMultiplier` | GUS `[ServerSettings]` |
| Player | `PlayerHarvestingDamageMultiplier` | Game.ini |
| **Tamed dino** | `DinoCharacterFood/Stamina/HealthRecoveryMultiplier` | GUS `[ServerSettings]` |
| Tamed dino | `TamedDinoDamageMultiplier` `TamedDinoResistanceMultiplier` | GUS `[ServerSettings]` |
| **Wild dino** | `WildDinoCharacterFood/StaminaDrainMultiplier` `WildDinoTorporDrainMultiplier` | Game.ini |
| Wild dino | `DinoCountMultiplier` | GUS `[ServerSettings]` |
| **Difficulty / structure** | `DifficultyOffset` `OverrideOfficialDifficulty` | GUS `[ServerSettings]` |
| Difficulty / structure | `StructureDamageMultiplier` `StructureResistanceMultiplier` | GUS `[ServerSettings]` |
| Difficulty / structure | `StructureDamageRepairCooldown` | Game.ini |
| Difficulty / structure | `DisableImprintDinoBuff` `AllowAnyoneBabyImprintCuddle` | GUS `[ServerSettings]` |
| (auto by `ark_config`) | `RCONEnabled` `RCONPort` `ServerAdminPassword` | GUS `[ServerSettings]` |

### ⚠️ Known wire-up bug (Phase 8a)

`game_config::GameSettings` writes everything to Game.ini's
`[/Script/ShooterGame.ShooterGameMode]` section, but several of the keys above
(marked **GUS** in the table) actually belong in `GameUserSettings.ini`'s
`[ServerSettings]`. ARK reads both files so the keys still take effect, but
having them in the wrong file:

- doesn't match the upstream / community convention (confusing on cross-reference)
- can cause double-writes (same key in both files) if the user pastes a
  community-shared GameUserSettings.ini
- prevents `Profile::create_new`'s GameUserSettings.ini auto-writer from
  carrying these defaults

**Planned fix (Phase 8b)**: split `game_config` into the two correct
destinations, route each field through the right wrapper.

---

## 3. `[ServerSettings]` — full key list (GameUserSettings.ini)

Sourced from upstream `_forked/frameui.pas:createGUSIni`. Keys marked ✅ are
in our dialog today. **170+ keys total.**

### 3.1 Authentication / connectivity

| Key | Type | Default | Note |
|---|---|---|---|
| `ServerPassword` | string | "" | Join password (blank = open) |
| `ServerAdminPassword` ✅ | string | required | RCON admin (we auto-write) |
| `RCONEnabled` ✅ | bool | False | Enable RCON listener |
| `RCONPort` ✅ | int | 27020 | RCON TCP port |
| `RCONServerGameLogBuffer` | int | 600 | Max log lines RCON exposes |
| `BanListURL` | URL | "" | Remote ban list |
| `AdminListURL` | URL | "" | Remote admin list |
| `BadWordListURL` `BadWordWhiteListURL` | URL | "" | Chat filter URLs |
| `CustomLiveTuningUrl` | URL | "" | Live config feed |
| `WorldBossKingKaijuSpawnTime` | HH:MM:SS | "" | World boss schedule |

### 3.2 PvE / PvP mode

| Key | Type | Note |
|---|---|---|
| `serverPVE` | bool | **PvE on** (lowercase first char in upstream, but ARK accepts both `serverPVE` and `ServerPvE`) |
| `ServerHardcore` | bool | Permanent death |
| `AllowCaveBuildingPvE` | bool | Allow base building in caves under PvE |
| `AllowCaveBuildingPvP` | bool | Same for PvP (default True) |
| `AllowFlyerCarryPvE` | bool | Flyers can pickup tames in PvE |
| `bForceCanRideFliers` | bool | Allow flying mounts on maps that ban them |
| `EnableCryoSicknessPVE` | bool | |
| `DisableStructureDecayPvE` | bool | |
| `DisableDinoDecayPvE` | bool | |
| `DisablePvEGamma` `EnablePvPGamma` | bool | Limit gamma override |
| `PreventOfflinePvP` | bool | |
| `PreventOfflinePvPInterval` | float | seconds before offline protection kicks in |
| `IgnorePVPMountedWeaponryRestrictions` | bool | |
| `AllowTeslaCoilCaveBuildingPVP` | bool | |
| `PvPDinoDecay` `PvPStructureDecay` | bool | |
| `PvEDinoDecayPeriodMultiplier` `PvEStructureDecayPeriodMultiplier` | float | |
| `RandomSupplyCratePoints` | bool | |
| `PvEAllowStructuresAtSupplyDrops` | bool | |

### 3.3 Difficulty & spawn rates

| Key | Type | Default | Note |
|---|---|---|---|
| `DifficultyOffset` ✅ | float | 0.2 | 0.0–1.0; vanilla cap is 5 |
| `OverrideOfficialDifficulty` ✅ | float | 0 | Set to 5.0 for max wild lvl 150 |
| `MaxDifficulty` | bool | False | Forces above to ceiling |
| `DinoCountMultiplier` ✅ | float | 1.0 | Wild dino spawn density |
| `MaxPersonalTamedDinos` | int | 0 | 0 = unlimited |
| `MaxTamedDinos` | float | 5000 | Server-wide tamed dino limit |
| `DestroyTamesOverTheSoftTameLimit` | bool | False | |
| `MaxTamedDinos_SoftTameLimit` | int | 5000 | |
| `MaxTamedDinos_SoftTameLimit_CountdownForDeletionDuration` | int | 604800 | seconds (1 week) |

### 3.4 Multipliers

| Key | Type | Default | Note |
|---|---|---|---|
| `XPMultiplier` ✅ | float | 1.0 | |
| `TamingSpeedMultiplier` ✅ | float | 1.0 | |
| `HarvestAmountMultiplier` ✅ | float | 1.0 | |
| `HarvestHealthMultiplier` ✅ | float | 1.0 | |
| `ResourcesRespawnPeriodMultiplier` ✅ | float | 1.0 | smaller = faster respawn |
| `ItemStackSizeMultiplier` | float | 1.0 | |
| `OxygenSwimSpeedStatMultiplier` | float | 1.0 | |
| `RaidDinoCharacterFoodDrainMultiplier` | float | 1.0 | |
| `AutoDestroyOldStructuresMultiplier` | float | 0 | Days before unused structures decay |

### 3.5 Day / night cycle

| Key | Type | Default |
|---|---|---|
| `DayCycleSpeedScale` ✅ | float | 1.0 |
| `DayTimeSpeedScale` ✅ | float | 1.0 |
| `NightTimeSpeedScale` ✅ | float | 1.0 |
| `OverrideStartTime` | bool | False |
| `StartTimeHour` | float | 10.0 |

### 3.6 Player tuning

| Key | Type | Default | Tab |
|---|---|---|---|
| `PlayerCharacterFoodDrainMultiplier` ✅ | float | 1.0 | Player |
| `PlayerCharacterWaterDrainMultiplier` ✅ | float | 1.0 | Player |
| `PlayerCharacterStaminaDrainMultiplier` ✅ | float | 1.0 | Player |
| `PlayerCharacterHealthRecoveryMultiplier` ✅ | float | 1.0 | Player |
| `PlayerDamageMultiplier` ✅ | float | 1.0 | Player |
| `PlayerResistanceMultiplier` ✅ | float | 1.0 | Player |

### 3.7 Tamed / wild dino tuning

| Key | Type | Default |
|---|---|---|
| `DinoCharacterFoodDrainMultiplier` ✅ | float | 1.0 |
| `DinoCharacterStaminaDrainMultiplier` ✅ | float | 1.0 |
| `DinoCharacterHealthRecoveryMultiplier` ✅ | float | 1.0 |
| `DinoDamageMultiplier` | float | 1.0 |
| `DinoResistanceMultiplier` | float | 1.0 |
| `TamedDinoDamageMultiplier` ✅ | float | 1.0 |
| `TamedDinoResistanceMultiplier` ✅ | float | 1.0 |

### 3.8 Imprinting / breeding (the rest live in Game.ini — see §4.3)

| Key | Type | Default |
|---|---|---|
| `DisableImprintDinoBuff` ✅ | bool | False |
| `AllowAnyoneBabyImprintCuddle` ✅ | bool | False |

### 3.9 Structures / building

| Key | Type | Default |
|---|---|---|
| `StructureDamageMultiplier` ✅ | float | 1.0 |
| `StructureResistanceMultiplier` ✅ | float | 1.0 |
| `StructurePreventResourceRadiusMultiplier` | float | 1.0 |
| `PerPlatformMaxStructuresMultiplier` | float | 1.0 |
| `PlatformSaddleBuildAreaBoundsMultiplier` | float | 1.0 |
| `TheMaxStructuresInRange` | int | 10500 |
| `AlwaysAllowStructurePickup` | bool | False |
| `StructurePickupTimeAfterPlacement` | float | 30 |
| `StructurePickupHoldDuration` | float | 0.5 |
| `OverrideStructurePlatformPrevention` | bool | False |
| `EnableExtraStructurePreventionVolumes` | bool | False |
| `AllowCrateSpawnsOnTopOfStructures` | bool | False |
| `ForceAllStructureLocking` | bool | False |
| `MaxPlatformSaddleStructureLimit` | int | 75 |
| `MaxGateFrameOnSaddles` | int | -1 |
| `AutoDestroyDecayedDinos` | bool | False |
| `MaxTrainCars` | int | 8 |

### 3.10 Tribes / players

| Key | Type | Default |
|---|---|---|
| `PreventTribeAlliances` | bool | False |
| `TribeNameChangeCooldown` | float | 15 |
| `MaxTributeDinos` | int | 20 |
| `MaxTributeItems` | int | 50 |
| `MaxTributeCharacters` | int | 10 |
| `TributeItemExpirationSeconds` | int | 86400 |
| `TributeCharacterExpirationSeconds` | int | 0 |
| `TributeDinoExpirationSeconds` | int | 86400 |
| `KickIdlePlayersPeriod` | float | 3600 |
| `noTributeDownloads` | bool | False |
| `PreventDownloadDinos` `PreventDownloadItems` `PreventDownloadSurvivors` | bool | False |
| `PreventUploadDinos` `PreventUploadItems` `PreventUploadSurvivors` | bool | False |
| `ChB_CrossARKAllowForeignDinoDownloads` | bool | False *(typo in upstream; correct ARK key is `CrossARKAllowForeignDinoDownloads`)* |
| `MaxNumberOfPlayersInTribe` | int | 0 |
| `MaxHexagonsPerCharacter` | int | 2_000_000_000 |

### 3.11 Notifications / chat

| Key | Type | Default |
|---|---|---|
| `globalVoiceChat` | bool | False |
| `ProximityChat` | bool | False |
| `DontAlwaysNotifyPlayerJoined` | bool | False |
| `AlwaysNotifyPlayerLeft` | bool | False |
| `AdminLogging` | bool | False |
| `AllowHideDamageSourceFromLogs` | bool | False |
| `ShowFloatingDamageText` | bool | False |
| `ShowMapPlayerLocation` | bool | True |
| `ServerCrosshair` | bool | True |
| `ServerForceNoHUD` | bool | False |
| `AllowThirdPersonPlayer` | bool | True |
| `AllowHitMarkers` | bool | True |

### 3.12 Item / time clamps & combat

| Key | Type | Default |
|---|---|---|
| `ClampItemSpoilingTimes` | bool | False |
| `ClampItemStats` | bool | False |
| `ClampResourceHarvestDamage` | bool | False |
| `AllowMultipleAttachedC4` | bool | False |
| `AllowRaidDinoFeeding` | bool | False |
| `PreventMateBoost` | bool | False |
| `PreventSpawnAnimations` | bool | False |
| `ImplantSuicideCD` | int | 28800 |
| `MaxBlueprintDinoLevel` `MaxBlueprintDinoQuality` | int | 0 |
| `MaxBlueprintItemQuality` `MaxBlueprintScoutQuality` | int | 0 |
| `ServerAutoForceRespawnWildDinosInterval` | float | 0 |
| `ForceExploitedTameDeletion` | bool | False |
| `ForceGachaUnhappyInCaves` | bool | True |
| `bAllowFlyerDinoSubmerging` | bool | True |
| `AutoRestartIntervalSeconds` | float | 0 |

### 3.13 Diseases

| Key | Type | Default |
|---|---|---|
| `PreventDiseases` | bool | False |
| `NonPermanentDiseases` | bool | False |

### 3.14 Cryopod

| Key | Type | Default |
|---|---|---|
| `EnableCryopodNerf` | bool | False |
| `CryopodNerfDamageMult` | float | 0.01 |
| `CryopodNerfDuration` | float | 0 |
| `CryopodNerfIncomingDamageMultPercent` | float | 0 |
| `DisableCryopodEnemyCheck` | bool | False |
| `AllowCryoFridgeOnSaddle` | bool | False |
| `DisableCryopodFridgeRequirement` | bool | False |
| `CryopodFridgeCooldowntime` | int | 90 |

### 3.15 Tek / hexagon / outposts

| Key | Type | Default |
|---|---|---|
| `MaxActiveOutposts` | int | 0 |
| `MaxActiveResourceCaches` | int | 0 |
| `MaxActiveCityOutposts` | int | 0 |
| `OverrideBondedPassImprintMultiplier` | float | 0 |
| `MaxCosmoWeaponAmmo` | int | 0 |
| `CosmoWeaponAmmoReloadAmount` | int | 0 |
| `UseCharacterTracker` | bool | False |
| `UpdateAllowedCheatersInterval` | float | 600 |
| `TribeTowerBonusMultiplier` | float | 0 |
| `CosmeticWhitelistOverride` | string/URL | "" |

### 3.16 Bunkers (event content)

| Key | Type | Default |
|---|---|---|
| `LimitBunkersPerTribe` | bool | False |
| `LimitBunkersPerTribeNum` | int | 0 |
| `AllowBunkersInPreventionZones` | bool | False |
| `AllowRidingDinosInsideBunkers` | bool | False |
| `AllowBunkerModulesAboveGround` | bool | False |
| `AllowDinoAIInsideBunkers` | bool | False |
| `AllowBunkerModulesInPreventionZones` | bool | False |
| `MinDistanceBetweenBunkers` | float | 0 |
| `EnemyAccessBunkerHPThreshold` | float | 0 |
| `BunkerUnderHPThresholdDmgMultiplier` | float | 0 |

### 3.17 Cryo Hospital

| Key | Type | Default |
|---|---|---|
| `CryoHospitalHoursToRegenHP` | float | 0 |
| `CryoHospitalHoursToRegenFood` | float | 0 |
| `CryoHospitalHoursToDrainTorpor` | float | 0 |
| `CryoHospitalMatingCooldownReduction` | float | 0 |

### 3.18 Bloodforge

| Key | Type | Default |
|---|---|---|
| `BloodforgeReinforceExtraDurability` | float | 0 |
| `BloodforgeReinforceResourceCostMultiplier` | float | 0 |
| `BloodforgeReinforceSpeedMultiplier` | float | 0 |

### 3.19 Companions

| Key | Type | Default |
|---|---|---|
| `ArmadoggoDeathCooldown` | int | 3600 |
| `YoungIceFoxDeathCooldown` | int | 3600 |
| `CompanionsDeathCooldown` | int | 3600 |

---

## 4. `[/Script/ShooterGame.ShooterGameMode]` — full key list (Game.ini)

Sourced from upstream `_forked/frameui.pas:createGameIni`. **170 keys
total.** Many are 12-element float arrays (per stat).

### 4.1 XP gain breakdown

| Key | Type | Default |
|---|---|---|
| `GenericXPMultiplier` | float | 1.0 |
| `HarvestXPMultiplier` | float | 1.0 |
| `KillXPMultiplier` | float | 1.0 |
| `CraftXPMultiplier` | float | 1.0 |
| `SpecialXPMultiplier` | float | 1.0 |
| `ExplorerNoteXPMultiplier` | float | 1.0 |
| `BossKillXPMultiplier` | float | 1.0 |
| `CaveKillXPMultiplier` | float | 1.0 |
| `WildKillXPMultiplier` | float | 1.0 |
| `TamedKillXPMultiplier` | float | 1.0 |
| `UnclaimedKillXPMultiplier` | float | 1.0 |
| `AlphaKillXPMultiplier` | float | 1.0 |
| `OverrideMaxExperiencePointsPlayer` | int | 0 |
| `OverrideMaxExperiencePointsDino` | int | 0 |

### 4.2 Drain rates (food/torpor)

| Key | Type | Default |
|---|---|---|
| `WildDinoCharacterFoodDrainMultiplier` ✅ | float | 1.0 |
| `WildDinoTorporDrainMultiplier` ✅ | float | 1.0 |
| `TamedDinoCharacterFoodDrainMultiplier` | float | 1.0 |
| `TamedDinoTorporDrainMultiplier` | float | 1.0 |
| `WildDinoCharacterStaminaDrainMultiplier` ✅ *(actually GUS — wire-up bug)* | float | 1.0 |

### 4.3 Breeding & imprint

| Key | Type | Default |
|---|---|---|
| `BabyMatureSpeedMultiplier` ✅ | float | 1.0 |
| `EggHatchSpeedMultiplier` ✅ | float | 1.0 |
| `LayEggIntervalMultiplier` | float | 1.0 |
| `MatingSpeedMultiplier` | float | 1.0 |
| `MatingIntervalMultiplier` ✅ | float | 1.0 |
| `BabyImprintAmountMultiplier` | float | 1.0 |
| `BabyImprintingStatScaleMultiplier` | float | 1.0 |
| `BabyCuddleIntervalMultiplier` | float | 1.0 |
| `BabyCuddleGracePeriodMultiplier` | float | 1.0 |
| `BabyCuddleLoseImprintQualitySpeedMultiplier` | float | 1.0 |
| `BabyFoodConsumptionSpeedMultiplier` | float | 1.0 |
| `PassiveTameIntervalMultiplier` | float | 1.0 |
| `bDisableDinoBreeding` | bool | False |
| `bDisableDinoTaming` | bool | False |

### 4.4 Loot / crops

| Key | Type | Default |
|---|---|---|
| `SupplyCrateLootQualityMultiplier` | float | 1.0 |
| `FishingLootQualityMultiplier` | float | 1.0 |
| `CropDecaySpeedMultiplier` | float | 1.0 |
| `CropGrowthSpeedMultiplier` | float | 1.0 |
| `bDisableLootCrates` | bool | False |
| `LimitNonPlayerDroppedItemsCount` | int | 0 |
| `LimitNonPlayerDroppedItemsRange` | int | 0 |

### 4.5 Spoilage / decomposition

| Key | Type | Default |
|---|---|---|
| `GlobalItemDecompositionTimeMultiplier` | float | 1.0 |
| `GlobalSpoilingTimeMultiplier` | float | 1.0 |
| `GlobalCorpseDecompositionTimeMultiplier` | float | 1.0 |
| `UseCorpseLifeSpanMultiplier` | float | 1.0 |
| `bUseCorpseLocator` | bool | True |
| `PoopIntervalMultiplier` | float | 1.0 |
| `FuelConsumptionIntervalMultiplier` | float | 1.0 |

### 4.6 Player & stats arrays

| Key | Type |
|---|---|
| `PerLevelStatsMultiplier_Player[0]`–`[11]` | float (×12) |
| `PerLevelStatsMultiplier_DinoTamed[0]`–`[11]` | float (×12) |
| `PerLevelStatsMultiplier_DinoTamed_Add[0]`–`[11]` | float (×12) |
| `PerLevelStatsMultiplier_DinoTamed_Affinity[0]`–`[11]` | float (×12) |
| `PerLevelStatsMultiplier_DinoWild[0]`–`[11]` | float (×12) |
| `PlayerBaseStatMultipliers[0]`–`[11]` | float (×12) |

> Stat indices: 0=Health 1=Stamina 2=Torpidity 3=Oxygen 4=Food 5=Water
> 6=Temperature 7=Weight 8=MeleeDamage 9=Speed 10=Fortitude 11=CraftingSpeed

### 4.7 Damage & combat

| Key | Type | Default |
|---|---|---|
| `DinoHarvestingDamageMultiplier` | float | 3.2 |
| `DinoTurretDamageMultiplier` | float | 1.0 |
| `PlayerHarvestingDamageMultiplier` ✅ | float | 1.0 |
| `MaxFallSpeedMultiplier` | float | 1.0 |
| `BaseTemperatureMultiplier` | float | 1.0 |
| `MaxNumberOfPlayersInTribe` | int | 0 |
| `MaxDifficulty` | bool | False |
| `bAllowSpeedLeveling` | bool | True |
| `bAllowFlyerSpeedLeveling` | bool | False |
| `bDisableFriendlyFire` `bPvEDisableFriendlyFire` | bool | False |
| `bAllowUnlimitedRespecs` | bool | False |
| `bDisableDinoRiding` | bool | False |
| `bShowCreativeMode` | bool | False |
| `bUseSingleplayerSettings` | bool | False |
| `bUseDinoLevelUpAnimations` | bool | True |
| `bDisablePhotoMode` | bool | False |
| `PhotoModeRangeLimit` | int | 3000 |
| `bDisableStructurePlacementCollision` | bool | False |
| `bIgnoreStructuresPreventionVolumes` | bool | False |
| `bAllowPlatformSaddleMultiFloors` | bool | False |
| `bFlyerPlatformAllowUnalignedDinoBasing` | bool | False |
| `bPassiveDefensesDamageRiderlessDinos` | bool | False |
| `bAllowBuildingInNoBuildZone` | bool | False |
| `bAllowCustomRecipes` | bool | False |
| `bAutoUnlockAllEngrams` | bool | False |
| `bOnlyAllowSpecifiedEngrams` | bool | False |

### 4.8 Crafting

| Key | Type | Default |
|---|---|---|
| `CustomRecipeEffectivenessMultiplier` | float | 1.0 |
| `CustomRecipeSkillMultiplier` | float | 1.0 |
| `CraftingSkillBonusMultiplier` | float | 1.0 |

### 4.9 Hexagons

| Key | Type | Default |
|---|---|---|
| `HexagonCostMultiplier` | float | 1.0 |
| `BaseHexagonRewardMultiplier` | float | 1.0 |

### 4.10 Auto-PvE timer

| Key | Type | Default |
|---|---|---|
| `bAutoPvETimer` | bool | False |
| `bAutoPvEUseSystemTime` | bool | False |
| `AutoPvEStartTimeSeconds` | int | 0 |
| `AutoPvEStopTimeSeconds` | int | 0 |
| `bPvEAllowTribeWar` `bPvEAllowTribeWarCancel` | bool | False |

### 4.11 PvP respawn delay

| Key | Type | Default |
|---|---|---|
| `bIncreasePvPRespawnInterval` | bool | False |
| `IncreasePvPRespawnIntervalCheckPeriod` | float | 120 |
| `IncreasePvPRespawnIntervalMultiplier` | float | 2.0 |
| `IncreasePvPRespawnIntervalBaseAmount` | float | 60 |
| `PvPZoneStructureDamageMultiplier` | int | 6 |

### 4.12 Turret limits

| Key | Type | Default |
|---|---|---|
| `bHardLimitTurretsInRange` | bool | False |
| `bLimitTurretsInRange` | bool | True |
| `LimitTurretsNum` | int | 100 |
| `LimitTurretsRange` | float | 10000 |

### 4.13 Resource respawn radius

| Key | Type | Default |
|---|---|---|
| `ResourceNoReplenishRadiusPlayers` | float | 1.0 |
| `ResourceNoReplenishRadiusStructures` | float | 1.0 |

### 4.14 Tame deletion safety

| Key | Type | Default |
|---|---|---|
| `DestroyTamesOverLevelClamp` | int | 0 |
| `StructureDamageRepairCooldown` ✅ | float | 180 |

---

## 5. URL launch parameters

Embedded in `MM_Command_Val` after the map name. Two syntaxes:
`?Key=Value` (URL params) and `-flag` / `-flag=value` (Unreal cmdline args).

### 5.1 `?key=value` URL params

| Key | Type | Note |
|---|---|---|
| `Port` | int | Game port (UDP, default 7777) |
| `QueryPort` | int | Steam query port (UDP, default 27015) |
| `RCONPort` | int | RCON port (TCP). **Phase 5A removes this from the URL** because the URL parser is unreliable for it; we write it to `GameUserSettings.ini` instead |
| `AltSaveDirectoryName` | string | Custom save folder |
| `?listen` | flag | Mandatory for dedicated server |
| `?SessionName=` | string | What appears in the server browser |
| `?MaxPlayers=` | int | |
| `?ServerPassword=` | string | Join password (we do still pass via URL when set) |

> **Avoid in URL** (URL parser is buggy in ASA): `?ServerAdminPassword=`,
> `?RCONEnabled=`, `?RCONPort=`. Phase 5A's `ark_config` writes those to
> GameUserSettings.ini directly.

### 5.2 `-flag` cmdline args (~58 total)

Common ones:

| Flag | Note |
|---|---|
| `-log` | Print log to stdout (recommended) |
| `-NoBattlEye` | Disable BattlEye (matches `Play No BE` Steam launcher option on the client) |
| `-ServerPlatform=PC` (or `PC+PS5+XSX+WINGDK` etc.) | Restrict / open crossplay |
| `-mods=ID1,ID2,...` | Load mods |
| `-passivemods=ID1,ID2,...` | Load mods without spawning content |
| `-clusterid=NAME -ClusterDirOverride=PATH` | Cross-ARK cluster |
| `-MULTIHOME` | Bind to a specific NIC (with `-MultiHome=IP`) |
| `-culture=en` (or `ja`, etc.) | Localisation |
| `-NoAI` `-nodinos` `-NoDinosExceptForcedSpawn` etc. | Spawn restriction |
| `-WinLiveMaxPlayers=N` | True player cap (for >70) |
| `-NoTransferFromFiltering` | |
| `-AutoDestroyStructures` | |
| `-EnableIdlePlayerKick` | |
| `-exclusivejoin` | Allow-list mode |
| `-StasisKeepControllers` | Performance hint |
| `-UnstasisDinoObstructionCheck` | |
| `-ServerRCONOutputTribeLogs` | |
| `-ForceRespawnDinos` | Wipe wild dinos on next start |
| `-ForceClampItemQuality` | |
| `-ForceWipeTinkerExploit` `-ForceWipeTinkerExploitNoDinos` | |
| `-ForceCharRespec` | |
| `-DisableCustomCosmetics` | |
| `-DisableDupeLogDeletes` `-ForceDupeLog` `-UseItemDupeCheck` `-ignoredupeditems` | Dupe detection |
| `-CustomNotificationURL=URL` | |
| `-EasterColors` `-OlympicColors` `-PrideColors` `-HalloweenColors` `-ServerUseEventColors` | Event color toggles |
| `-RedownloadModsOnServerRestart` | |
| `-DestroyTamesOverLevel=N` | |
| `-NoTimeout` | |
| `-FixThrallStats` | |
| `-allowicefox` | |
| `-NoWildBabies` | |
| `-AlwaysTickDedicatedSkeletalMeshes` | |
| `-disabledinonetrangescaling` | |
| `-ForceAllowCaveFlyers` | |
| `-GBUsageToForceRestart=N` | Auto-restart memory threshold |
| `-Activeevent=NAME` | Force a seasonal event |

### 5.3 EOS / cross-platform flags (recent additions, not in upstream)

| Flag | Note |
|---|---|
| `-EpicApp=ArkAscended` | Register with EOS so EOS-based clients can see the server |
| `-PublicIPForEpic=IP` | Advertised IP for EOS matchmaking (LAN: your LAN IP; same-machine test: 127.0.0.1) |

---

## 6. Engine.ini — network / HTTP timeouts

Section: `[/Script/OnlineSubsystemUtils.IpNetDriver]`

| Key | Type | Default |
|---|---|---|
| `InitialConnectTimeout` | float | upstream-configurable |
| `ConnectionTimeout` | float | upstream-configurable |

Section: `[OnlineSubsystemSteam]`

| Key | Type | Default |
|---|---|---|
| `P2PConnectionTimeout` | int | upstream-configurable |

Section: `[HTTP]`

| Key | Type | Default |
|---|---|---|
| `HttpTimeout` | int | upstream-configurable |
| `HttpConnectionTimeout` | int | upstream-configurable |
| `HttpReceiveTimeout` | int | upstream-configurable |
| `HttpSendTimeout` | int | upstream-configurable |

> These are typically only touched when ARK is dropping connections under
> load. Defaults work for most personal servers.

---

## 7. Mod-specific sections (out of scope for core dialog)

When the matching mod is loaded, these sections are read by ARK from
`GameUserSettings.ini`. Listed here for completeness — Phase 8c+ candidate
for per-mod tabs in the GUI.

| Section | Mod | Approx key count |
|---|---|---|
| `[Cryopods]` | Awesome Cryopods + tweaks | ~25 |
| `[SuperSpyglassPlus]` | Super Spyglass Plus | ~17 |
| `[DerDinoFinder]` | Der Dino Finder | 2 |
| `[QoLPlus]` | QoL+ | ~80 |

---

## 8. References

- **Upstream extracted source**:
  - `_forked/frameui.pas:createGUSIni` → all GameUserSettings.ini keys
  - `_forked/frameui.pas:createGameIni` → all Game.ini keys
  - `_forked/frameui.pas` lines 4195–4297 → MM_Command_Val URL/flag builder
- **Official ARK SA wiki**: https://ark.wiki.gg/wiki/Server_configuration
- **SteamDB depot history** (for rollback): https://steamdb.info/app/2430930/depots/

Defaults shown reflect either upstream's `<> 1.0` guards or the official
wiki — when in doubt, omit the key (ARK will use its own default).

---

## 9. Roadmap for the World Settings dialog

Phase 8a (current) covers ~30 of the most commonly tweaked fields.
**Reasonable next-phase scope:**

| Phase | Adds | Approx size |
|---|---|---|
| **8b — wire-up fix + PvE/PvP** | Move misrouted keys to `GameUserSettings.ini`; add PvE / PvP toggles (`serverPVE`, `AllowFlyerCarryPvE`, `EnableCryoSicknessPVE`, `DisableStructureDecayPvE`); add `MaxTamedDinos`, `KickIdlePlayersPeriod`, `AutoSavePeriodMinutes`, `TheMaxStructuresInRange` | +10 fields |
| **8c — Imprint / breeding** | Full breeding tab: `BabyImprintAmount/Cuddle*` (5 fields), `MatingSpeed`, `LayEggInterval`, `PassiveTameInterval` | +8 fields |
| **8d — Loot & spoilage** | `SupplyCrateLootQuality`, `FishingLootQuality`, `Crop*`, `Global*Multiplier`, `Fuel*`, `MaxFallSpeed` | +10 fields |
| **8e — Stat arrays** | `PerLevelStatsMultiplier_*[0..10]` and `PlayerBaseStatMultipliers[0..10]` (60+ float fields, may need a more compact UI) | +60 fields |
| **8f — Combat / structures** | Bunker block, Cryopod nerf block, structure pickup, turret limits, etc. | +20 fields |
| **8g — XP gain breakdown** | `Generic/Harvest/Kill/Craft/Special/ExplorerNote/BossKill/CaveKill/WildKill/TamedKill/UnclaimedKill/AlphaKillXPMultiplier` | +12 fields |
| **8h — Cosmetic / chat** | Notification toggles, `ShowFloatingDamageText`, `AllowThirdPersonPlayer`, `ServerCrosshair`, `MOTD` | +10 fields |
| **8i — Cluster / mod URLs / lists** | `clusterid`, `BanListURL`, `AdminListURL`, `BadWordListURL`, etc. | +10 fields |
| **8j — Stat clamps / blueprint caps** | `MaxBlueprintDinoLevel/Quality`, `MaxBlueprintItem/ScoutQuality`, `MaxHexagonsPerCharacter` | +10 fields |
| **8k — URL/-flag editor** | Free-form check-list / tag editor for the ~58 `-flag` arguments | UI form |

Once 8b–8h are in, the GUI will cover ~95% of what most server admins ever
touch. The remaining specialised keys can stay as manual-paste-friendly
through `World Settings → Import…` (the dialog already preserves any keys
it does not model on save).

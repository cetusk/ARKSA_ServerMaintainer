unit frameui;

{$mode objfpc}{$H+}

interface

uses
  rcon, discord,
  MessageTrans,
  LazFileUtils,
  sort_ui,
  Graphics,
  asaUtils,
  other_proc_ctl,
  IniFiles,
  fileutil,
  LConvEncoding,
  Windows, dateutils, LCLType,
  Classes, SysUtils, process, Forms, Controls, StdCtrls, Dialogs, ComCtrls,
  AsyncProcess, Spin, ExtCtrls, Grids;

type

  TPageControl = class(ComCtrls.TPageControl)
  private
    SVActiveIDX : integer;
    procedure CNDrawItem(var Message: TWMDrawItem); message WM_DRAWITEM;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  public
    DarkMode       :boolean;
    ActiveTabColor :DWORD;
  end;

  TBeforeData = record
    Name:string;
    Str :string;
    Int :integer;
    Flt :Double;
    Bol :boolean;
  end;

  { TAsaFrame }

  TAsaFrame = class(TFrame)
    AsyncProcess: TAsyncProcess;
    AsyncProcess_ListPlayer: TAsyncProcess;
    AsyncProcess_NoWait: TAsyncProcess;
    Btn_InstVer: TButton;
    Button_SvrCMD_DelayedRestart: TButton;
    ButtonClearSvrCMDLogs: TButton;
    Button_DataBK2: TButton;
    Button_SvrCMD_Clear: TButton;
    Button_SvrCMD_Command: TButton;
    Button_SpawnList_Add: TButton;
    Button_ServerPassword_Random: TButton;
    Button_Import: TButton;
    Button_Import_File: TButton;
    Button_Export_Dir: TButton;
    Button_Export: TButton;
    Button_OpenPort: TButton;
    Button_Cosmetic_LocalFile: TButton;
    Button_Cosmetic_Add: TButton;
    Button_Cosmetic_Remove: TButton;
    Button_ClusterDirOverride: TButton;
    ButtonClearRCONLogs: TButton;
    Button_AllModInArgs: TButton;
    Button_AltSaveDirectoryName: TButton;
    Button_DestroyWildDinos: TButton;
    Button_Engrams_AddRow: TButton;
    Button_Engrams_DelRow: TButton;
    Button_GetChat: TButton;
    Button_GetGameLog: TButton;
    Button_Ini_Import: TButton;
    Button_Ini_Import_Dir: TButton;
    Button_Install: TButton;
    Button_Install_Location: TButton;
    Button_ItemMaxQuantity_AddRow: TButton;
    Button_ItemMaxQuantity_DelRow: TButton;
    Button_jump_ModStore: TButton;
    Button_ListPlayers: TButton;
    Button_Mod5_PropagatorFuelClass: TButton;
    Button_Mod5_PropagatorModCostItemClass: TButton;
    Button_RCON_Clear: TButton;
    Button_RCON_Command: TButton;
    Button_SaveProfile: TButton;
    Button_SaveWorld: TButton;
    Button_ServerAdminPassword_Generate: TButton;
    Button_ServerStart: TButton;
    Button_SetIni: TButton;
    Button_SpawnList_Del: TButton;
    Button_SvrCMD_AdminBroadcast: TButton;
    CB_ActiveEvent: TComboBox;
    CB_ActiveEvent_mod: TComboBox;
    CB_Culture: TComboBox;
    CB_Install_DelMovie: TCheckBox;
    CB_Install_Steamcmd: TCheckBox;
    CB_MapName: TComboBox;
    CB_Mod5_DisableResourcePulling: TCheckBox;
    CB_Mod5_RemoveFloorRequirementFromStructurePlacement: TCheckBox;
    CB_NonPermanentDiseases: TCheckBox;
    CB_OverrideStructurePlatformPrevention: TCheckBox;
    CB_RCONEnabled: TCheckBox;
    CB_SvrCMDEnabled: TCheckBox;
    CB_SvrCMD_Command: TComboBox;
    CB_SvrCMD_Command_List: TComboBox;
    CB_SrvStatus_Val: TComboBox;
    CG_ActiveEvent: TCheckGroup;
    CG_Mod5_MutatorModeBlacklist: TCheckGroup;
    ChB_AdminLogging: TCheckBox;
    ChB_AllowAnyoneBabyImprintCuddle: TCheckBox;
    ChB_AllowBunkerModulesAboveGround: TCheckBox;
    ChB_AllowBunkerModulesInPreventionZones: TCheckBox;
    ChB_FixThrallStats: TCheckBox;
    ChB_AllowRidingDinosInsideBunkers: TCheckBox;
    ChB_AllowCaveBuildingPvE: TCheckBox;
    ChB_AllowCaveBuildingPvP: TCheckBox;
    ChB_AllowCryoFridgeOnSaddle: TCheckBox;
    ChB_AllowFlyerCarryPvE: TCheckBox;
    ChB_AllowHideDamageSourceFromLogs: TCheckBox;
    ChB_AllowHitMarkers: TCheckBox;
    ChB_AllowMultipleAttachedC4: TCheckBox;
    ChB_AllowRaidDinoFeeding: TCheckBox;
    ChB_AllowDinoAIInsideBunkers: TCheckBox;
    ChB_AllowThirdPersonPlayer: TCheckBox;
    ChB_AltSaveDirectoryName: TCheckBox;
    ChB_AlwaysAllowStructurePickup: TCheckBox;
    ChB_AlwaysNotifyPlayerLeft: TCheckBox;
    ChB_AlwaysTickDedicatedSkeletalMeshes: TCheckBox;
    ChB_bAutoUnlockAllEngrams: TCheckBox;
    ChB_bIgnoreStructuresPreventionVolumes: TCheckBox;
    ChB_AllowBunkersInPreventionZones: TCheckBox;
    ChB_bUseCorpseLocator: TCheckBox;
    ChB_bAllowPlatformSaddleMultiFloors: TCheckBox;
    ChB_allowicefox: TCheckBox;
    ChB_ForceCharRespec: TCheckBox;
    ChB_LimitBunkersPerTribe: TCheckBox;
    ChB_EnableCryoSicknessPVE: TCheckBox;
    ChB_ER_Breeding: TCheckBox;
    ChB_ER_Experience: TCheckBox;
    ChB_ER_Harvesting: TCheckBox;
    ChB_ER_Hexagons: TCheckBox;
    ChB_ER_Tame: TCheckBox;
    ChB_ForceClampItemQuality: TCheckBox;
    ChB_bForceCanRideFliers: TCheckBox;
    ChB_AutoDestroyStructures: TCheckBox;
    ChB_AutoDestroyDecayedDinos: TCheckBox;
    ChB_bAllowCustomRecipes: TCheckBox;
    ChB_bAllowFlyerSpeedLeveling: TCheckBox;
    ChB_bAllowSpeedLeveling: TCheckBox;
    ChB_bAllowUnlimitedRespecs: TCheckBox;
    ChB_bAutoPvETimer: TCheckBox;
    ChB_bAutoPvEUseSystemTime: TCheckBox;
    ChB_bDisableDinoBreeding: TCheckBox;
    ChB_bDisableDinoRiding: TCheckBox;
    ChB_bDisableDinoTaming: TCheckBox;
    ChB_bDisableFriendlyFire: TCheckBox;
    ChB_bDisableLootCrates: TCheckBox;
    ChB_bDisablePhotoMode: TCheckBox;
    ChB_bDisableStructurePlacementCollision: TCheckBox;
    ChB_bAllowBuildingInNoBuildZone: TCheckBox;
    ChB_bFlyerPlatformAllowUnalignedDinoBasing: TCheckBox;
    ChB_bIncreasePvPRespawnInterval: TCheckBox;
    ChB_bPassiveDefensesDamageRiderlessDinos: TCheckBox;
    ChB_bPvEAllowTribeWar: TCheckBox;
    ChB_bPvEAllowTribeWarCancel: TCheckBox;
    ChB_bPvEDisableFriendlyFire: TCheckBox;
    ChB_bShowCreativeMode: TCheckBox;
    ChB_bUseDinoLevelUpAnimations: TCheckBox;
    ChB_bUseSingleplayerSettings: TCheckBox;
    ChB_ClampItemSpoilingTimes: TCheckBox;
    ChB_ClampResourceHarvestDamage: TCheckBox;
    ChB_ClampItemStats: TCheckBox;
    ChB_CMD_override: TCheckBox;
    ChB_DestroyTamesOverTheSoftTameLimit: TCheckBox;
    ChB_DisableCryopodEnemyCheck: TCheckBox;
    ChB_DisableCryopodFridgeRequirement: TCheckBox;
    ChB_DisableCustomCosmetics: TCheckBox;
    ChB_DisableDinoDecayPvE: TCheckBox;
    ChB_disabledinonetrangescaling: TCheckBox;
    ChB_DisableDupeLogDeletes: TCheckBox;
    ChB_DisableImprintDinoBuff: TCheckBox;
    ChB_DisablePvEGamma: TCheckBox;
    ChB_DisableStructureDecayPvE: TCheckBox;
    ChB_DisableWeatherFog: TCheckBox;
    ChB_DontAlwaysNotifyPlayerJoined: TCheckBox;
    ChB_EasterColors: TCheckBox;
    ChB_EnableExtraStructurePreventionVolumes: TCheckBox;
    ChB_EnablePvPGamma: TCheckBox;
    ChB_exclusivejoin: TCheckBox;
    ChB_ForceAllowCaveFlyers: TCheckBox;
    ChB_bAllowFlyerDinoSubmerging: TCheckBox;
    ChB_ForceWipeTinkerExploit: TCheckBox;
    ChB_ForceDupeLog: TCheckBox;
    ChB_ForceRespawnDinos: TCheckBox;
    ChB_forceuseperfthreads: TCheckBox;
    ChB_ForceWipeTinkerExploitNoDinos: TCheckBox;
    ChB_globalVoiceChat: TCheckBox;
    ChB_GS_Append: TCheckBox;
    ChB_GS_Override: TCheckBox;
    ChB_GUS_Append: TCheckBox;
    ChB_GUS_Override: TCheckBox;
    ChB_EnableCryopodNerf: TCheckBox;
    ChB_USE_AsaApiLoader: TCheckBox;
    ChB_NoTimeout: TCheckBox;
    ChB_ServerUseEventColors: TCheckBox;
    ChB_ignoredupeditems: TCheckBox;
    ChB_MaxDifficulty: TCheckBox;
    ChB_Mod1_AllowAdminCaptureAll: TCheckBox;
    ChB_Mod1_AllowCryoterminalOnPlatforms: TCheckBox;
    ChB_Mod1_AllowDeployInBossArenas: TCheckBox;
    ChB_Mod1_DisableAutoCycle: TCheckBox;
    ChB_Mod1_DisableCryopodChargeNeed: TCheckBox;
    ChB_Mod1_DisableCryopodsRequirement: TCheckBox;
    ChB_Mod1_DisableCryoSickness: TCheckBox;
    ChB_Mod1_Enabled: TCheckBox;
    ChB_Mod1_ForceUseINISettings: TCheckBox;
    ChB_Mod1_FullyGrownBabies: TCheckBox;
    ChB_Mod1_GiveTemporaryCryopodsInCryoterminal: TCheckBox;
    ChB_Mod1_PassImprintToDeployer: TCheckBox;
    ChB_Mod1_PreventDeployInCaves: TCheckBox;
    ChB_Mod2_DisableBuffInfo: TCheckBox;
    ChB_Mod2_DisableCrosshair: TCheckBox;
    ChB_Mod2_DisableEggInfo: TCheckBox;
    ChB_Mod2_DisableGPS: TCheckBox;
    ChB_Mod2_DisableItembagInfo: TCheckBox;
    ChB_Mod2_DisableNightVision: TCheckBox;
    ChB_Mod2_DisableOutlineMode: TCheckBox;
    ChB_Mod2_DisablePredatorVision: TCheckBox;
    ChB_Mod2_DisableStructureInfo: TCheckBox;
    ChB_Mod2_DisableSupplyDropInfo: TCheckBox;
    ChB_Mod2_DisableTameFoodInfo: TCheckBox;
    ChB_Mod2_DisableTheSpyglassOnEnemyTribes: TCheckBox;
    ChB_Mod2_DontShowAnyStatsOnWildDino: TCheckBox;
    ChB_Mod2_Enabled: TCheckBox;
    ChB_Mod2_OnlyHPonEnemyTribeDinos: TCheckBox;
    ChB_Mod2_OnlyShowStatsForTames: TCheckBox;
    ChB_Mod2_UseESPOutline: TCheckBox;
    ChB_Mod2_UseESPOutlineFill: TCheckBox;
    ChB_Mod3_Enabled: TCheckBox;
    ChB_Mod3_IsAdminOnly: TCheckBox;
    ChB_Mod4_AA_Acrocanthosaurus: TCheckBox;
    ChB_Mod4_AA_Anomalocaris: TCheckBox;
    ChB_Mod4_AA_Archelon: TCheckBox;
    ChB_Mod4_AA_Brachiosaurus: TCheckBox;
    ChB_Mod4_AA_Ceratosaurus: TCheckBox;
    ChB_Mod4_AA_Deinosuchus: TCheckBox;
    ChB_Mod4_AA_Deinotherium: TCheckBox;
    ChB_Mod4_AA_Helicoprion: TCheckBox;
    ChB_Mod4_AA_Xiphactinus: TCheckBox;
    ChB_Mod5_AllowGrindingMissionRewards: TCheckBox;
    ChB_Mod5_AllowMakingWeaponsAndArmorBPs: TCheckBox;
    ChB_Mod5_AllowMultiToolNeuterAll: TCheckBox;
    ChB_Mod5_AllowTekItemBlueprintCreation: TCheckBox;
    ChB_Mod5_DisableBlueprintInstall: TCheckBox;
    ChB_Mod5_DisableHitchingPostMatingBonus: TCheckBox;
    ChB_Mod5_DisableMultiToolDinoChibiMode: TCheckBox;
    ChB_Mod5_DisableMultiToolDinoKillMode: TCheckBox;
    ChB_Mod5_DisableNannyImprinting: TCheckBox;
    ChB_Mod5_Enabled: TCheckBox;
    ChB_Mod5_EnableExtendedDeathCache: TCheckBox;
    ChB_Mod5_EnableStructureSound: TCheckBox;
    ChB_Mod5_EnableUpdateDurability: TCheckBox;
    ChB_Mod5_GrinderReturnBlockedResources: TCheckBox;
    ChB_Mod5_MutatorAllowBreedingNeutered: TCheckBox;
    ChB_Mod5_PropagatorDisableDinoMods: TCheckBox;
    ChB_Mod5_PropagatorDisableEggDrop: TCheckBox;
    ChB_Mod5_PropagatorRespectMutationLimit: TCheckBox;
    ChB_Mod5_PullingIgnoresPinCodes: TCheckBox;
    ChB_MULTIHOME: TCheckBox;
    ChB_NoAI: TCheckBox;
    ChB_NoBattlEye: TCheckBox;
    ChB_NoDinosExceptForcedSpawn: TCheckBox;
    ChB_NoDinosExceptManualSpawn: TCheckBox;
    ChB_NoDinosExceptStreamingSpawn: TCheckBox;
    ChB_NoDinosExceptWaterSpawn: TCheckBox;
    ChB_noperfthreads: TCheckBox;
    ChB_nosound: TCheckBox;
    ChB_NoTransferFromFiltering: TCheckBox;
    ChB_noTributeDownloads: TCheckBox;
    ChB_NoWildBabies: TCheckBox;
    ChB_OlympicColors: TCheckBox;
    ChB_onethread: TCheckBox;
    ChB_OnlyAllowSpecifiedEngrams: TCheckBox;
    ChB_OverrideStartTime: TCheckBox;
    ChB_Port_Args: TCheckBox;
    ChB_PreventDiseases: TCheckBox;
    ChB_PreventDownloadDinos: TCheckBox;
    ChB_PreventDownloadItems: TCheckBox;
    ChB_PreventDownloadSurvivors: TCheckBox;
    ChB_PreventMateBoost: TCheckBox;
    ChB_PreventOfflinePvP: TCheckBox;
    ChB_PreventSpawnAnimations: TCheckBox;
    ChB_PreventTribeAlliances: TCheckBox;
    ChB_PreventUploadDinos: TCheckBox;
    ChB_PreventUploadItems: TCheckBox;
    ChB_PreventUploadSurvivors: TCheckBox;
    ChB_ProximityChat: TCheckBox;
    ChB_PvEAllowStructuresAtSupplyDrops: TCheckBox;
    ChB_PvPDinoDecay: TCheckBox;
    ChB_PvPStructureDecay: TCheckBox;
    ChB_Queryport_Args: TCheckBox;
    ChB_EnableIdlePlayerKick: TCheckBox;
    ChB_RandomSupplyCratePoints: TCheckBox;
    ChB_RCONPort_Args: TCheckBox;
    ChB_RedownloadModsOnServerRestart: TCheckBox;
    ChB_ServerCrosshair: TCheckBox;
    ChB_ServerForceNoHUD: TCheckBox;
    ChB_servergamelog: TCheckBox;
    ChB_servergamelogincludetribelogs: TCheckBox;
    ChB_ServerHardcore: TCheckBox;
    ChB_ServerPlatform_ALL: TCheckBox;
    ChB_ServerPlatform_MSStore: TCheckBox;
    ChB_ServerPlatform_PC: TCheckBox;
    ChB_ServerPlatform_PS5: TCheckBox;
    ChB_ServerPlatform_XSX: TCheckBox;
    ChB_serverPVE: TCheckBox;
    ChB_ServerRCONOutputTribeLogs: TCheckBox;
    ChB_ShowFloatingDamageText: TCheckBox;
    ChB_ShowMapPlayerLocation: TCheckBox;
    ChB_StasisKeepControllers: TCheckBox;
    ChB_UnstasisDinoObstructionCheck: TCheckBox;
    ChB_UseCharacterTracker: TCheckBox;
    ChB_UseDynamicConfig: TCheckBox;
    ChB_UseServerNetSpeedCheck: TCheckBox;
    CB_Install_TryClean: TCheckBox;
    ChB_nodinos: TCheckBox;
    ChB_UseItemDupeCheck: TCheckBox;
    ChB_PrideColors: TCheckBox;
    ChB_disableCharacterTracker: TCheckBox;
    ChB_AllowCrateSpawnsOnTopOfStructures: TCheckBox;
    ChB_ForceAllStructureLocking: TCheckBox;
    ChB_IgnorePVPMountedWeaponryRestrictions: TCheckBox;
    ChB_AllowTeslaCoilCaveBuildingPVP: TCheckBox;
    ChB_ForceExploitedTameDeletion: TCheckBox;
    ChB_CrossARKAllowForeignDinoDownloads: TCheckBox;
    ChB_bHardLimitTurretsInRange: TCheckBox;
    ChB_bLimitTurretsInRange: TCheckBox;
    ChB_EnableDynamicDownload: TCheckBox;
    ChB_Allow_non_dataonly_blueprints: TCheckBox;
    ChB_HalloweenColors: TCheckBox;
    ChB_ForceGachaUnhappyInCaves: TCheckBox;
    ChB_TryOpenPort: TCheckBox;
    ChB_SelectData_World: TCheckBox;
    ChB_SelectData_Profile: TCheckBox;
    ChB_SelectData_Logs: TCheckBox;
    ChB_UseEngineINI: TCheckBox;
    ChB_WorldBossKingKaijuSpawnTime_UTC: TCheckBox;
    ChB_CleanBackup: TCheckBox;
    CB_RCON_Command: TComboBox;
    CB_RCON_Command_List: TComboBox;
    CB_Install_ShareUpdate: TCheckBox;
    ChB_AutoRestart: TCheckBox;
    ChB_AutoBackup: TCheckBox;
    CB_ActiveEvent2: TComboBox;
    ChB_ASASM_AutoDestroyWildDinosSeconds: TCheckBox;
    CB_SvrCMD_BroadcastHist: TComboBox;
    ChB_RelativePath: TCheckBox;
    Edit_ActiveMapMod_Val: TEdit;
    Edit_Import: TEdit;
    Edit_Export: TEdit;
    Edit_WorldBossKingKaijuSpawnTime: TEdit;
    Edit_Cosmetic_URL: TEdit;
    Edit_Cosmetic_LocalFile: TEdit;
    Edit_Cosmetic_ModId: TEdit;
    Edit_ActiveMods_Val: TEdit;
    Edit_AdminListURL: TEdit;
    Edit_AllModInArgs: TEdit;
    Edit_AltSaveDirectoryName: TEdit;
    Edit_AutoAddedModInArgs: TEdit;
    Edit_BadWordListURL: TEdit;
    Edit_BadWordWhiteListURL: TEdit;
    Edit_BanListURL: TEdit;
    Edit_ClusterDirOverride: TEdit;
    Edit_clusterid: TEdit;
    Edit_CustomLiveTuningUrl: TEdit;
    Edit_CustomNotificationURL_Val: TEdit;
    Edit_Ini_Import: TEdit;
    Edit_Install_Location_Val: TEdit;
    Edit_ipv4_Val: TEdit;
    Edit_Message: TEdit;
    Edit_Mod5_AdvTransferItemBlacklist: TEdit;
    Edit_Mod5_MultiToolBlacklist: TEdit;
    Edit_Mod5_MutatorDinoBlacklist: TEdit;
    Edit_Mod5_MutatorPulseCooldowns: TEdit;
    Edit_Mod5_MutatorPulseCost: TEdit;
    Edit_Mod5_OmniToolBlacklist: TEdit;
    Edit_Mod5_PropagatorDinoBlacklist: TEdit;
    Edit_Mod5_PropagatorFuelClass: TEdit;
    Edit_Mod5_PropagatorModCostItemClass: TEdit;
    Edit_Mod5_PullResourceAdditions: TEdit;
    Edit_Mod5_PullResourceRemovals: TEdit;
    Edit_Mod5_QoLPlusEngramWhitelist: TEdit;
    Edit_Mods: TEdit;
    Edit_passivemods: TEdit;
    Edit_Profile: TEdit;
    Edit_ServerAdminPassword: TEdit;
    Edit_ServerAdminPassword2: TEdit;
    Edit_ServerIPv4_Val: TEdit;
    Edit_ServerPassword: TEdit;
    Edit_SessionName: TEdit;
    FSE_BabyCuddleIntervalMultiplier2: TFloatSpinEdit;
    FSE_BabyImprintAmountMultiplier2: TFloatSpinEdit;
    FSE_BabyMatureSpeedMultiplier2: TFloatSpinEdit;
    FSE_BloodforgeReinforceSpeedMultiplier: TFloatSpinEdit;
    FSE_BloodforgeReinforceResourceCostMultiplier: TFloatSpinEdit;
    FSE_BloodforgeReinforceExtraDurability: TFloatSpinEdit;
    FSE_CryopodNerfDuration: TFloatSpinEdit;
    FSE_CryopodNerfIncomingDamageMultPercent: TFloatSpinEdit;
    FSE_EggHatchSpeedMultiplier2: TFloatSpinEdit;
    FSE_CryoHospitalHoursToRegenHP: TFloatSpinEdit;
    FSE_CryoHospitalHoursToRegenFood: TFloatSpinEdit;
    FSE_CryoHospitalHoursToDrainTorpor: TFloatSpinEdit;
    FSE_CryoHospitalMatingCooldownReduction: TFloatSpinEdit;
    FSE_ER_Breeding: TFloatSpinEdit;
    FSE_ER_Breeding2: TFloatSpinEdit;
    FSE_ER_Breeding3: TFloatSpinEdit;
    FSE_ER_Experience: TFloatSpinEdit;
    FSE_ER_Harvesting: TFloatSpinEdit;
    FSE_ER_Hexagons: TFloatSpinEdit;
    FSE_ER_Tame: TFloatSpinEdit;
    FSE_HarvestAmountMultiplier2: TFloatSpinEdit;
    FSE_MinDistanceBetweenBunkers: TFloatSpinEdit;
    FSE_EnemyAccessBunkerHPThreshold: TFloatSpinEdit;
    FSE_BunkerUnderHPThresholdDmgMultiplier: TFloatSpinEdit;
    FSE_TribeTowerBonusMultiplier: TFloatSpinEdit;
    FSE_MatingIntervalMultiplier2: TFloatSpinEdit;
    FSE_OverrideBondedPassImprintMultiplier: TFloatSpinEdit;
    FSE_ConnectionTimeout: TFloatSpinEdit;
    FSE_InitialConnectTimeout: TFloatSpinEdit;
    FSE_BaseTemperatureMultiplier: TFloatSpinEdit;
    FSE_CropDecaySpeedMultiplier: TFloatSpinEdit;
    FSE_CropGrowthSpeedMultiplier: TFloatSpinEdit;
    FSE_FuelConsumptionIntervalMultiplier: TFloatSpinEdit;
    FSE_GlobalCorpseDecompositionTimeMultiplier: TFloatSpinEdit;
    FSE_GlobalItemDecompositionTimeMultiplier: TFloatSpinEdit;
    FSE_GlobalSpoilingTimeMultiplier: TFloatSpinEdit;
    FSE_HarvestAmountMultiplier: TFloatSpinEdit;
    FSE_HarvestHealthMultiplier: TFloatSpinEdit;
    FSE_ItemStackSizeMultiplier: TFloatSpinEdit;
    FSE_LimitTurretsRange: TFloatSpinEdit;
    FSE_ResourceNoReplenishRadiusPlayers: TFloatSpinEdit;
    FSE_ResourceNoReplenishRadiusStructures: TFloatSpinEdit;
    FSE_ResourcesRespawnPeriodMultiplier: TFloatSpinEdit;
    FSE_ServerAutoForceRespawnWildDinosInterval: TFloatSpinEdit;
    FSE_AutoDestroyOldStructuresMultiplier: TFloatSpinEdit;
    FSE_AutoRestartIntervalSeconds: TFloatSpinEdit;
    FSE_AutoSavePeriodMinutes: TFloatSpinEdit;
    FSE_BabyCuddleGracePeriodMultiplier: TFloatSpinEdit;
    FSE_BabyCuddleIntervalMultiplier: TFloatSpinEdit;
    FSE_BabyCuddleLoseImprintQualitySpeedMultiplier: TFloatSpinEdit;
    FSE_BabyFoodConsumptionSpeedMultiplier: TFloatSpinEdit;
    FSE_BabyImprintAmountMultiplier: TFloatSpinEdit;
    FSE_BabyImprintingStatScaleMultiplier: TFloatSpinEdit;
    FSE_BabyMatureSpeedMultiplier: TFloatSpinEdit;
    FSE_BaseHexagonRewardMultiplier: TFloatSpinEdit;
    FSE_BossKillXPMultiplier: TFloatSpinEdit;
    FSE_CaveKillXPMultiplier: TFloatSpinEdit;
    FSE_CraftingSkillBonusMultiplier: TFloatSpinEdit;
    FSE_CraftXPMultiplier: TFloatSpinEdit;
    FSE_CustomRecipeEffectivenessMultiplier: TFloatSpinEdit;
    FSE_CustomRecipeSkillMultiplier: TFloatSpinEdit;
    FSE_DayCycleSpeedScale: TFloatSpinEdit;
    FSE_DayTimeSpeedScale: TFloatSpinEdit;
    FSE_DifficultyOffset: TFloatSpinEdit;
    FSE_DinoCharacterFoodDrainMultiplier: TFloatSpinEdit;
    FSE_DinoCharacterHealthRecoveryMultiplier: TFloatSpinEdit;
    FSE_DinoCharacterStaminaDrainMultiplier: TFloatSpinEdit;
    FSE_DinoCountMultiplier: TFloatSpinEdit;
    FSE_DinoDamageMultiplier: TFloatSpinEdit;
    FSE_DinoHarvestingDamageMultiplier: TFloatSpinEdit;
    FSE_DinoResistanceMultiplier: TFloatSpinEdit;
    FSE_DinoTurretDamageMultiplier: TFloatSpinEdit;
    FSE_EggHatchSpeedMultiplier: TFloatSpinEdit;
    FSE_ExplorerNoteXPMultiplier: TFloatSpinEdit;
    FSE_FishingLootQualityMultiplier: TFloatSpinEdit;
    FSE_GenericXPMultiplier: TFloatSpinEdit;
    FSE_HarvestXPMultiplier: TFloatSpinEdit;
    FSE_HexagonCostMultiplier: TFloatSpinEdit;
    FSE_IncreasePvPRespawnIntervalBaseAmount: TFloatSpinEdit;
    FSE_IncreasePvPRespawnIntervalCheckPeriod: TFloatSpinEdit;
    FSE_IncreasePvPRespawnIntervalMultiplier: TFloatSpinEdit;
    FSE_KickIdlePlayersPeriod: TFloatSpinEdit;
    FSE_KillXPMultiplier: TFloatSpinEdit;
    FSE_LayEggIntervalMultiplier: TFloatSpinEdit;
    FSE_MatingIntervalMultiplier: TFloatSpinEdit;
    FSE_MatingSpeedMultiplier: TFloatSpinEdit;
    FSE_MaxFallSpeedMultiplier: TFloatSpinEdit;
    FSE_MaxTamedDinos: TFloatSpinEdit;
    FSE_Mod1_CryopodChargeSpeedMultiplier: TFloatSpinEdit;
    FSE_Mod1_CryoTerminalCaptureInterval: TFloatSpinEdit;
    FSE_Mod1_CryoTime: TFloatSpinEdit;
    FSE_Mod1_CryoTimeInCombat: TFloatSpinEdit;
    FSE_Mod5_GrinderScaleMultiplier: TFloatSpinEdit;
    FSE_Mod5_IndustrialForgeScaleMultiplier: TFloatSpinEdit;
    FSE_Mod5_PropagatorMatingIntervalMultiplier: TFloatSpinEdit;
    FSE_Mod5_PropagatorMatingSpeedMultiplier: TFloatSpinEdit;
    FSE_Mod5_RaidTimerLimitMultiplier: TFloatSpinEdit;
    FSE_Mod5_ReplicatorScaleMultiplier: TFloatSpinEdit;
    FSE_Mod5_ResourceTransferCooldown: TFloatSpinEdit;
    FSE_NightTimeSpeedScale: TFloatSpinEdit;
    FSE_OverrideOfficialDifficulty: TFloatSpinEdit;
    FSE_OxygenSwimSpeedStatMultiplier: TFloatSpinEdit;
    FSE_PassiveTameIntervalMultiplier: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoTamed0: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoTamed1: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoTamed10: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoTamed2: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoTamed3: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoTamed4: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoTamed5: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoTamed6: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoTamed7: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoTamed8: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoTamed9: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoTamed_Add0: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoTamed_Add1: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoTamed_Add10: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoTamed_Add2: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoTamed_Add3: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoTamed_Add4: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoTamed_Add5: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoTamed_Add6: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoTamed_Add7: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoTamed_Add8: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoTamed_Add9: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoTamed_Affinity0: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoTamed_Affinity1: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoTamed_Affinity10: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoTamed_Affinity2: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoTamed_Affinity3: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoTamed_Affinity4: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoTamed_Affinity5: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoTamed_Affinity6: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoTamed_Affinity7: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoTamed_Affinity8: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoTamed_Affinity9: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoWild0: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoWild1: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoWild10: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoWild2: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoWild3: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoWild4: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoWild5: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoWild6: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoWild7: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoWild8: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_DinoWild9: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_Player0: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_Player1: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_Player10: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_Player11: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_Player2: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_Player3: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_Player4: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_Player5: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_Player6: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_Player7: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_Player8: TFloatSpinEdit;
    FSE_PerLevelStatsMultiplier_Player9: TFloatSpinEdit;
    FSE_PerPlatformMaxStructuresMultiplier: TFloatSpinEdit;
    FSE_PlatformSaddleBuildAreaBoundsMultiplier: TFloatSpinEdit;
    FSE_PlayerBaseStatMultipliers0: TFloatSpinEdit;
    FSE_PlayerBaseStatMultipliers1: TFloatSpinEdit;
    FSE_PlayerBaseStatMultipliers10: TFloatSpinEdit;
    FSE_PlayerBaseStatMultipliers11: TFloatSpinEdit;
    FSE_PlayerBaseStatMultipliers2: TFloatSpinEdit;
    FSE_PlayerBaseStatMultipliers3: TFloatSpinEdit;
    FSE_PlayerBaseStatMultipliers4: TFloatSpinEdit;
    FSE_PlayerBaseStatMultipliers5: TFloatSpinEdit;
    FSE_PlayerBaseStatMultipliers6: TFloatSpinEdit;
    FSE_PlayerBaseStatMultipliers7: TFloatSpinEdit;
    FSE_PlayerBaseStatMultipliers8: TFloatSpinEdit;
    FSE_PlayerBaseStatMultipliers9: TFloatSpinEdit;
    FSE_PlayerCharacterFoodDrainMultiplier: TFloatSpinEdit;
    FSE_PlayerCharacterHealthRecoveryMultiplier: TFloatSpinEdit;
    FSE_PlayerCharacterStaminaDrainMultiplier: TFloatSpinEdit;
    FSE_PlayerCharacterWaterDrainMultiplier: TFloatSpinEdit;
    FSE_PlayerDamageMultiplier: TFloatSpinEdit;
    FSE_PlayerHarvestingDamageMultiplier: TFloatSpinEdit;
    FSE_PlayerResistanceMultiplier: TFloatSpinEdit;
    FSE_PoopIntervalMultiplier: TFloatSpinEdit;
    FSE_PreventOfflinePvPInterval: TFloatSpinEdit;
    FSE_PvEDinoDecayPeriodMultiplier: TFloatSpinEdit;
    FSE_PvEStructureDecayPeriodMultiplier: TFloatSpinEdit;
    FSE_RaidDinoCharacterFoodDrainMultiplier: TFloatSpinEdit;
    FSE_RCONServerGameLogBuffer: TFloatSpinEdit;
    FSE_SpecialXPMultiplier: TFloatSpinEdit;
    FSE_StartTimeHour: TFloatSpinEdit;
    FSE_StructureDamageMultiplier: TFloatSpinEdit;
    FSE_StructurePickupHoldDuration: TFloatSpinEdit;
    FSE_StructurePickupTimeAfterPlacement: TFloatSpinEdit;
    FSE_StructurePreventResourceRadiusMultiplier: TFloatSpinEdit;
    FSE_StructureResistanceMultiplier: TFloatSpinEdit;
    FSE_SupplyCrateLootQualityMultiplier: TFloatSpinEdit;
    FSE_TamedDinoCharacterFoodDrainMultiplier: TFloatSpinEdit;
    FSE_TamedDinoDamageMultiplier: TFloatSpinEdit;
    FSE_TamedDinoResistanceMultiplier: TFloatSpinEdit;
    FSE_TamedDinoTorporDrainMultiplier: TFloatSpinEdit;
    FSE_TamedKillXPMultiplier: TFloatSpinEdit;
    FSE_TamingSpeedMultiplier: TFloatSpinEdit;
    FSE_TamingSpeedMultiplier2: TFloatSpinEdit;
    FSE_TribeNameChangeCooldown: TFloatSpinEdit;
    FSE_CryopodNerfDamageMult: TFloatSpinEdit;
    FSE_UnclaimedKillXPMultiplier: TFloatSpinEdit;
    FSE_AlphaKillXPMultiplier: TFloatSpinEdit;
    FSE_UpdateAllowedCheatersInterval: TFloatSpinEdit;
    FSE_UseCorpseLifeSpanMultiplier: TFloatSpinEdit;
    FSE_WildDinoCharacterFoodDrainMultiplier: TFloatSpinEdit;
    FSE_WildDinoTorporDrainMultiplier: TFloatSpinEdit;
    FSE_WildKillXPMultiplier: TFloatSpinEdit;
    FSE_XPMultiplier: TFloatSpinEdit;
    FSE_XPMultiplier2: TFloatSpinEdit;
    GB_AdditionsAscended: TGroupBox;
    GB_BabyDino: TGroupBox;
    GB_ConfigOverrideItemMaxQuantity: TGroupBox;
    GB_CrossArkArgs: TGroupBox;
    GB_EventRate: TGroupBox;
    GB_Game: TGroupBox;
    GB_GameUserSettings: TGroupBox;
    GB_HarvestResourceItemAmountClassMultipliers: TGroupBox;
    GB_Hexagons: TGroupBox;
    GB_Ini_Import: TGroupBox;
    GB_Mod1_Cryopods: TGroupBox;
    GB_Mod2_Spyglass: TGroupBox;
    GB_Mod3_DerDinoFinder: TGroupBox;
    GB_Mod5_CommaSeparatedList: TGroupBox;
    GB_Mod5_CraftingSpeed: TGroupBox;
    GB_Mod5_Multiplier: TGroupBox;
    GB_Mod5_RangeInFoundations: TGroupBox;
    GB_Mod5_SlotCount: TGroupBox;
    GB_MODs: TGroupBox;
    GB_NitradServerOnly: TGroupBox;
    GB_OverrideNamedEngramEntries: TGroupBox;
    GB_PerLevelStatsMultiplier_DinoTamed: TGroupBox;
    GB_PerLevelStatsMultiplier_DinoTamed_Add: TGroupBox;
    GB_PerLevelStatsMultiplier_DinoTamed_Affinity: TGroupBox;
    GB_PerLevelStatsMultiplier_DinoWild: TGroupBox;
    GB_PerLevelStatsMultiplier_Player: TGroupBox;
    GB_PlayerBaseStatMultipliers: TGroupBox;
    GB_QoL1: TGroupBox;
    GB_RCON_COMMAND: TGroupBox;
    GB_SvrCMD_COMMAND: TGroupBox;
    GB_ServerPlatform: TGroupBox;
    GB_SoftTame: TGroupBox;
    GB_TamedDino: TGroupBox;
    GB_Tribe: TGroupBox;
    GB_Args_Sys: TGroupBox;
    GB_Args_Performance: TGroupBox;
    GB_Args_World: TGroupBox;
    GB_Args_Color: TGroupBox;
    GB_Args_Dino: TGroupBox;
    GB_Cryopod: TGroupBox;
    GB_Turret: TGroupBox;
    GB_CosmeticWhitelistOverride: TGroupBox;
    GB_LocalFile: TGroupBox;
    GB_Data_Export: TGroupBox;
    GB_Data_Import: TGroupBox;
    GB_QuickSet: TGroupBox;
    GB_TekBunker: TGroupBox;
    GB_CryoHospital: TGroupBox;
    GB_Bloodforge: TGroupBox;
    GroupBox1: TGroupBox;
    Lbl_ActiveEvent2: TLabel;
    Lbl_ActiveMapMod: TLabel;
    Lbl_BloodforgeReinforceSpeedMultiplier: TLabel;
    Lbl_BloodforgeReinforceResourceCostMultiplier: TLabel;
    Lbl_BloodforgeReinforceExtraDurability: TLabel;
    Lbl_CryopodNerfDamageMult: TLabel;
    Lbl_CryopodNerfDuration: TLabel;
    Lbl_CryopodNerfIncomingDamageMultPercent: TLabel;
    Lbl_LimitBunkersPerTribeNum: TLabel;
    Lbl_CryoHospitalHoursToRegenHP: TLabel;
    Lbl_CryoHospitalHoursToRegenFood: TLabel;
    Lbl_CryoHospitalHoursToDrainTorpor: TLabel;
    Lbl_CryoHospitalMatingCooldownReduction: TLabel;
    Lbl_MaxActiveOutposts: TLabel;
    Lbl_MaxActiveResourceCaches: TLabel;
    Lbl_MaxActiveCityOutposts: TLabel;
    Lbl_MinDistanceBetweenBunkers: TLabel;
    Lbl_EnemyAccessBunkerHPThreshold: TLabel;
    Lbl_BunkerUnderHPThresholdDmgMultiplier: TLabel;
    Lbl_TribeTowerBonusMultiplier: TLabel;
    Lbl_YoungIceFoxDeathCooldown: TLabel;
    Lbl_CompanionsDeathCooldown: TLabel;
    Lbl_ER_Breeding: TLabel;
    Lbl_ER_Breeding1: TLabel;
    Lbl_ER_Breeding2: TLabel;
    Lbl_ER_Breeding3: TLabel;
    Lbl_ER_Breeding4: TLabel;
    Lbl_ER_Experience: TLabel;
    Lbl_ER_Harvesting: TLabel;
    Lbl_ER_Hexagons: TLabel;
    Lbl_ER_Tame: TLabel;
    Lbl_MaxBlueprintDinoLevel: TLabel;
    Lbl_MaxBlueprintDinoLevel_desc: TLabel;
    Lbl_MaxBlueprintDinoQuality: TLabel;
    Lbl_MaxBlueprintDinoQuality_desc: TLabel;
    Lbl_MaxBlueprintItemQuality: TLabel;
    Lbl_MaxBlueprintItemQuality_desc: TLabel;
    Lbl_MaxBlueprintScoutQuality: TLabel;
    Lbl_ConnectionTimeout_Def: TLabel;
    Lbl_HttpConnectionTimeout: TLabel;
    Lbl_HttpReceiveTimeout: TLabel;
    Lbl_HttpSendTimeout: TLabel;
    Lbl_InitialConnectTimeout_Def: TLabel;
    Lbl_MaxBlueprintScoutQuality_desc: TLabel;
    Lbl_MaxPlatformSaddleStructureLimit: TLabel;
    Lbl_MaxGateFrameOnSaddles: TLabel;
    Lbl_MaxCosmoWeaponAmmo: TLabel;
    Lbl_CosmoWeaponAmmoReloadAmount: TLabel;
    Lbl_P2PConnectionTimeout: TLabel;
    Lbl_ConnectionTimeout: TLabel;
    Lbl_InitialConnectTimeout: TLabel;
    Lbl_BaseTemperatureMultiplier: TLabel;
    Lbl_CropDecaySpeedMultiplier: TLabel;
    Lbl_CropGrowthSpeedMultiplier: TLabel;
    Lbl_FuelConsumptionIntervalMultiplier: TLabel;
    Lbl_GlobalCorpseDecompositionTimeMultiplier: TLabel;
    Lbl_GlobalItemDecompositionTimeMultiplier: TLabel;
    Lbl_GlobalSpoilingTimeMultiplier: TLabel;
    Lbl_HarvestAmountMultiplier: TLabel;
    Lbl_HarvestHealthMultiplier: TLabel;
    Lbl_ItemStackSizeMultiplier: TLabel;
    Lbl_OverrideBondedPassImprintMultiplier: TLabel;
    Lbl_HttpTimeout: TLabel;
    Lbl_P2PConnectionTimeout_Def: TLabel;
    Lbl_HttpTimeout_Def: TLabel;
    Lbl_HttpConnectionTimeout_Def: TLabel;
    Lbl_HttpReceiveTimeout_Def: TLabel;
    Lbl_HttpSendTimeout_Def: TLabel;
    Lbl_Profile_Status: TLabel;
    Lbl_Import_Status: TLabel;
    Lbl_Export_Status: TLabel;
    Lbl_Import: TLabel;
    Lbl_Export: TLabel;
    Lbl_ArmadoggoDeathCooldown: TLabel;
    Lbl_Import_Warning: TLabel;
    Lbl_Ini_Import_Status: TLabel;
    Lbl_ResourceNoReplenishRadiusPlayers: TLabel;
    Lbl_ResourceNoReplenishRadiusStructures: TLabel;
    Lbl_ResourcesRespawnPeriodMultiplier: TLabel;
    Lbl_AlphaKillXPMultiplier: TLabel;
    Lbl_WorldBossKingKaijuSpawnTime: TLabel;
    Lbl_SrvStatus_Val: TLabel;
    Lbl_Cosmetic_LocalFile2: TLabel;
    Lbl_Cosmetic_URL: TLabel;
    Lbl_Cosmetic_Modid: TLabel;
    Lbl_Cosmetic_ModName: TLabel;
    Lbl_Ini_Import: TLabel;
    Lbl_Ini_Import_Warning: TLabel;
    Lbl_LimitTurretsRange: TLabel;
    Lbl_LimitTurretsNum: TLabel;
    Lbl_LimitNonPlayerDroppedItemsCount1: TLabel;
    Lbl_LimitNonPlayerDroppedItemsRange: TLabel;
    Lbl_LimitNonPlayerDroppedItemsCount: TLabel;
    Lbl_CryopodFridgeCooldowntime: TLabel;
    Lbl_LimitNonPlayerDroppedItemsRange1: TLabel;
    Lbl_ServerAutoForceRespawnWildDinosInterval: TLabel;
    Lbl_ActiveEvent: TLabel;
    Lbl_ActiveMods: TLabel;
    Lbl_AdminListURL: TLabel;
    Lbl_AllModInArgs: TLabel;
    Lbl_AutoAddedModInArgs: TLabel;
    Lbl_AutoDestroyOldStructuresMultiplier: TLabel;
    Lbl_AutoPvEStartTimeSeconds: TLabel;
    Lbl_AutoPvEStopTimeSeconds: TLabel;
    Lbl_AutoRestartIntervalSeconds: TLabel;
    Lbl_AutoSavePeriodMinutes: TLabel;
    Lbl_BabyCuddleGracePeriodMultiplier: TLabel;
    Lbl_BabyCuddleIntervalMultiplier: TLabel;
    Lbl_BabyCuddleLoseImprintQualitySpeedMultiplier: TLabel;
    Lbl_BabyFoodConsumptionSpeedMultiplier: TLabel;
    Lbl_BabyImprintAmountMultiplier: TLabel;
    Lbl_BabyImprintingStatScaleMultiplier: TLabel;
    Lbl_BabyMatureSpeedMultiplier: TLabel;
    Lbl_BadWordListURL: TLabel;
    Lbl_BadWordWhiteListURL: TLabel;
    Lbl_BanListURL: TLabel;
    Lbl_BaseHexagonRewardMultiplier: TLabel;
    Lbl_BossKillXPMultiplier: TLabel;
    Lbl_CaveKillXPMultiplier: TLabel;
    Lbl_ClusterDirOverride: TLabel;
    Lbl_clusterid: TLabel;
    Lbl_Command_Override: TLabel;
    Lbl_Coommand: TLabel;
    Lbl_CraftingSkillBonusMultiplier: TLabel;
    Lbl_CraftXPMultiplier: TLabel;
    Lbl_Culture: TLabel;
    Lbl_CustomLiveTuningUrl: TLabel;
    Lbl_CustomNotificationURL: TLabel;
    Lbl_CustomRecipeEffectivenessMultiplier: TLabel;
    Lbl_CustomRecipeSkillMultiplier: TLabel;
    Lbl_DayCycleSpeedScale: TLabel;
    Lbl_DayTimeSpeedScale: TLabel;
    Lbl_DestroyTamesOverLevel: TLabel;
    Lbl_DestroyTamesOverLevelClamp: TLabel;
    Lbl_DifficultyOffset: TLabel;
    Lbl_DinoCharacterFoodDrainMultiplier: TLabel;
    Lbl_DinoCharacterHealthRecoveryMultiplier: TLabel;
    Lbl_DinoCharacterStaminaDrainMultiplier: TLabel;
    Lbl_DinoCountMultiplier: TLabel;
    Lbl_DinoDamageMultiplier: TLabel;
    Lbl_DinoHarvestingDamageMultiplier: TLabel;
    Lbl_DinoResistanceMultiplier: TLabel;
    Lbl_DinoTurretDamageMultiplier: TLabel;
    Lbl_Duration: TLabel;
    Lbl_EggHatchSpeedMultiplier: TLabel;
    Lbl_Experimental_Worning: TLabel;
    Lbl_ExplorerNoteXPMultiplier: TLabel;
    Lbl_FishingLootQualityMultiplier: TLabel;
    Lbl_GBUsageToForceRestart: TLabel;
    Lbl_GenericXPMultiplier: TLabel;
    Lbl_GS_Append: TLabel;
    Lbl_GS_Contents: TLabel;
    Lbl_GUS_Append: TLabel;
    Lbl_GUS_Contents: TLabel;
    Lbl_HarvestXPMultiplier: TLabel;
    Lbl_HexagonCostMultiplier: TLabel;
    Lbl_ImplantSuicideCD: TLabel;
    Lbl_IncreasePvPRespawnIntervalBaseAmount: TLabel;
    Lbl_IncreasePvPRespawnIntervalCheckPeriod: TLabel;
    Lbl_IncreasePvPRespawnIntervalMultiplier: TLabel;
    Lbl_InstLocation: TLabel;
    Lbl_InstVer: TLabel;
    Lbl_InstVer_Val: TLabel;
    Lbl_KickIdlePlayersPeriod: TLabel;
    Lbl_KillXPMultiplier: TLabel;
    Lbl_LayEggIntervalMultiplier: TLabel;
    Lbl_MapName: TLabel;
    Lbl_MatingIntervalMultiplier: TLabel;
    Lbl_MatingSpeedMultiplier: TLabel;
    Lbl_MaxFallSpeedMultiplier: TLabel;
    Lbl_MaxHexagonsPerCharacter: TLabel;
    Lbl_MaxNumberOfPlayersInTribe: TLabel;
    Lbl_MaxPersonalTamedDinos: TLabel;
    Lbl_MaxTamedDinos: TLabel;
    Lbl_MaxTamedDinos_SoftTameLimit: TLabel;
    Lbl_MaxTamedDinos_SoftTameLimit_CountdownForDeletionDuration: TLabel;
    Lbl_MaxTrainCars: TLabel;
    Lbl_MaxTributeCharacters: TLabel;
    Lbl_MaxTributeDinos: TLabel;
    Lbl_MaxTributeItems: TLabel;
    Lbl_Message: TLabel;
    Lbl_Mod1ID: TLabel;
    Lbl_Mod1Name: TLabel;
    Lbl_Mod1_Creator: TLabel;
    Lbl_Mod1_CryofridgeInventorySlots: TLabel;
    Lbl_Mod1_CryogunCooldownSeconds: TLabel;
    Lbl_Mod1_CryogunRangeFoundations: TLabel;
    Lbl_Mod1_CryopodChargeSpeedMultiplier: TLabel;
    Lbl_Mod1_CryoSicknessTimer: TLabel;
    Lbl_Mod1_CryoTerminalCaptureInterval: TLabel;
    Lbl_Mod1_CryoterminalInventorySlots: TLabel;
    Lbl_Mod1_CryoTerminalMaxRadiusFoundations: TLabel;
    Lbl_Mod1_CryoTime: TLabel;
    Lbl_Mod1_CryoTimeInCombat: TLabel;
    Lbl_Mod1_ImprintAmountToGive: TLabel;
    Lbl_Mod1_LimitCryoterminalsRange: TLabel;
    Lbl_Mod1_MaxCryoterminalsInRange: TLabel;
    Lbl_Mod1_NeutergunCooldownSeconds: TLabel;
    Lbl_Mod1_NeutergunRangeFoundations: TLabel;
    Lbl_Mod2ID: TLabel;
    Lbl_Mod2Name: TLabel;
    Lbl_Mod2_Creator: TLabel;
    Lbl_Mod2_OutlineRange: TLabel;
    Lbl_Mod3ID: TLabel;
    Lbl_Mod3Name: TLabel;
    Lbl_Mod3_Creator: TLabel;
    Lbl_Mod3_MarkerLimit: TLabel;
    Lbl_Mod4_Creator1: TLabel;
    Lbl_Mod5ID: TLabel;
    Lbl_Mod5Name: TLabel;
    Lbl_Mod5_AdvTransferItemBlacklist: TLabel;
    Lbl_Mod5_AmmoBoxSlotCount: TLabel;
    Lbl_Mod5_BeeHiveHoneyIntervalInSeconds: TLabel;
    Lbl_Mod5_BeeHiveSlotCount: TLabel;
    Lbl_Mod5_BeeHiveWateringRangeInFoundations: TLabel;
    Lbl_Mod5_Creator: TLabel;
    Lbl_Mod5_FabricatorCraftingSpeed: TLabel;
    Lbl_Mod5_FabricatorSlotCount: TLabel;
    Lbl_Mod5_FarmerRangeInFoundations: TLabel;
    Lbl_Mod5_FarmerSlotCount: TLabel;
    Lbl_Mod5_FridgeCraftingSpeed: TLabel;
    Lbl_Mod5_FridgeSlotCount: TLabel;
    Lbl_Mod5_GardenerRangeInFoundations: TLabel;
    Lbl_Mod5_GardenerSlotCount: TLabel;
    Lbl_Mod5_GeneratorSlotCount: TLabel;
    Lbl_Mod5_GrinderCraftingSpeed: TLabel;
    Lbl_Mod5_GrinderResourceReturnMax: TLabel;
    Lbl_Mod5_GrinderResourceReturnPercent: TLabel;
    Lbl_Mod5_GrinderScaleMultiplier: TLabel;
    Lbl_Mod5_GrinderSlotCount: TLabel;
    Lbl_Mod5_HitchingPostDinoLimit: TLabel;
    Lbl_Mod5_HitchingPostRange: TLabel;
    Lbl_Mod5_HitchingPostTribeLimit: TLabel;
    Lbl_Mod5_IndustrialForgeCraftingSpeed: TLabel;
    Lbl_Mod5_IndustrialForgeScaleMultiplier: TLabel;
    Lbl_Mod5_IndustrialForgeSlotCount: TLabel;
    Lbl_Mod5_LargeStorageSlotCount: TLabel;
    Lbl_Mod5_MaxMutatorRangeInFoundations: TLabel;
    Lbl_Mod5_MaxPowerRangeInFoundations: TLabel;
    Lbl_Mod5_MetalStorageSlotCount: TLabel;
    Lbl_Mod5_MultiToolBlacklist: TLabel;
    Lbl_Mod5_MutatorBuffMaxStackCount: TLabel;
    Lbl_Mod5_MutatorDinoBlacklist: TLabel;
    Lbl_Mod5_MutatorPulseCooldowns: TLabel;
    Lbl_Mod5_MutatorPulseCost: TLabel;
    Lbl_Mod5_NannyFeedingStartThreshold: TLabel;
    Lbl_Mod5_NannyIntervalInSeconds: TLabel;
    Lbl_Mod5_NannyMaxImprint: TLabel;
    Lbl_Mod5_NannyRangeInFoundations: TLabel;
    Lbl_Mod5_NannySlotCount: TLabel;
    Lbl_Mod5_OmniToolBlacklist: TLabel;
    Lbl_Mod5_PreservingBinCraftingSpeed: TLabel;
    Lbl_Mod5_PreservingBinSlotCount: TLabel;
    Lbl_Mod5_PropagatorDinoBlacklist: TLabel;
    Lbl_Mod5_PropagatorFuelClass: TLabel;
    Lbl_Mod5_PropagatorFuelInterval: TLabel;
    Lbl_Mod5_PropagatorMatingIntervalMultiplier: TLabel;
    Lbl_Mod5_PropagatorMatingSpeedMultiplier: TLabel;
    Lbl_Mod5_PropagatorModCostItemClass: TLabel;
    Lbl_Mod5_PropagatorModCostMutate: TLabel;
    Lbl_Mod5_PropagatorSlotCount: TLabel;
    Lbl_Mod5_PullResourceAdditions: TLabel;
    Lbl_Mod5_PullResourceRemovals: TLabel;
    Lbl_Mod5_QoLPlusEngramWhitelist: TLabel;
    Lbl_Mod5_RaidTimerLimitMultiplier: TLabel;
    Lbl_Mod5_ReplicatorCraftingSpeed: TLabel;
    Lbl_Mod5_ReplicatorScaleMultiplier: TLabel;
    Lbl_Mod5_ReplicatorSlotCount: TLabel;
    Lbl_Mod5_ResourcePullRangeInFoundations: TLabel;
    Lbl_Mod5_ResourceTransferCooldown: TLabel;
    Lbl_Mod5_SmallStorageSlotCount: TLabel;
    Lbl_Mod5_TekGeneratorSlotCount: TLabel;
    Lbl_Mod5_TransmutatorSlotCount: TLabel;
    Lbl_Mod5_TribePropagatorLimit: TLabel;
    Lbl_Mods: TLabel;
    Lbl_NightTimeSpeedScale: TLabel;
    Lbl_OverrideMaxExperiencePointsDino: TLabel;
    Lbl_OverrideMaxExperiencePointsPlayer: TLabel;
    Lbl_OverrideOfficialDifficulty: TLabel;
    Lbl_OxygenSwimSpeedStatMultiplier: TLabel;
    Lbl_passivemods: TLabel;
    Lbl_PassiveTameIntervalMultiplier: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoTamed0: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoTamed1: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoTamed10: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoTamed2: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoTamed3: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoTamed4: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoTamed5: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoTamed6: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoTamed7: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoTamed8: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoTamed9: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoTamed_Add0: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoTamed_Add1: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoTamed_Add10: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoTamed_Add2: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoTamed_Add3: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoTamed_Add4: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoTamed_Add5: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoTamed_Add6: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoTamed_Add7: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoTamed_Add8: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoTamed_Add9: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoTamed_Affinity0: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoTamed_Affinity1: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoTamed_Affinity10: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoTamed_Affinity2: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoTamed_Affinity3: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoTamed_Affinity4: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoTamed_Affinity5: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoTamed_Affinity6: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoTamed_Affinity7: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoTamed_Affinity8: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoTamed_Affinity9: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoWild0: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoWild1: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoWild10: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoWild2: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoWild3: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoWild4: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoWild5: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoWild6: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoWild7: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoWild8: TLabel;
    Lbl_PerLevelStatsMultiplier_DinoWild9: TLabel;
    Lbl_PerLevelStatsMultiplier_Player0: TLabel;
    Lbl_PerLevelStatsMultiplier_Player1: TLabel;
    Lbl_PerLevelStatsMultiplier_Player10: TLabel;
    Lbl_PerLevelStatsMultiplier_Player11: TLabel;
    Lbl_PerLevelStatsMultiplier_Player2: TLabel;
    Lbl_PerLevelStatsMultiplier_Player3: TLabel;
    Lbl_PerLevelStatsMultiplier_Player4: TLabel;
    Lbl_PerLevelStatsMultiplier_Player5: TLabel;
    Lbl_PerLevelStatsMultiplier_Player6: TLabel;
    Lbl_PerLevelStatsMultiplier_Player7: TLabel;
    Lbl_PerLevelStatsMultiplier_Player8: TLabel;
    Lbl_PerLevelStatsMultiplier_Player9: TLabel;
    Lbl_PerPlatformMaxStructuresMultiplier: TLabel;
    Lbl_PhotoModeRangeLimit: TLabel;
    Lbl_PlatformSaddleBuildAreaBoundsMultiplier: TLabel;
    Lbl_PlayerBaseStatMultipliers0: TLabel;
    Lbl_PlayerBaseStatMultipliers1: TLabel;
    Lbl_PlayerBaseStatMultipliers10: TLabel;
    Lbl_PlayerBaseStatMultipliers11: TLabel;
    Lbl_PlayerBaseStatMultipliers2: TLabel;
    Lbl_PlayerBaseStatMultipliers3: TLabel;
    Lbl_PlayerBaseStatMultipliers4: TLabel;
    Lbl_PlayerBaseStatMultipliers5: TLabel;
    Lbl_PlayerBaseStatMultipliers6: TLabel;
    Lbl_PlayerBaseStatMultipliers7: TLabel;
    Lbl_PlayerBaseStatMultipliers8: TLabel;
    Lbl_PlayerBaseStatMultipliers9: TLabel;
    Lbl_PlayerCharacterFoodDrainMultiplier: TLabel;
    Lbl_PlayerCharacterHealthRecoveryMultiplier: TLabel;
    Lbl_PlayerCharacterStaminaDrainMultiplier: TLabel;
    Lbl_PlayerCharacterWaterDrainMultiplier: TLabel;
    Lbl_PlayerCnt: TLabel;
    Lbl_PlayerDamageMultiplier: TLabel;
    Lbl_PlayerHarvestingDamageMultiplier: TLabel;
    Lbl_PlayerResistanceMultiplier: TLabel;
    Lbl_PoopIntervalMultiplier: TLabel;
    Lbl_Port: TLabel;
    Lbl_PreventOfflinePvPInterval: TLabel;
    Lbl_Profile: TLabel;
    Lbl_PvEDinoDecayPeriodMultiplier: TLabel;
    Lbl_PvEStructureDecayPeriodMultiplier: TLabel;
    Lbl_PvPZoneStructureDamageMultiplier: TLabel;
    Lbl_QueryPort: TLabel;
    Lbl_RaidDinoCharacterFoodDrainMultiplier: TLabel;
    Lbl_RCONPort: TLabel;
    Lbl_RCONServerGameLogBuffer: TLabel;
    Lbl_ServerAdminPassword: TLabel;
    Lbl_ServerAdminPassword1: TLabel;
    Lbl_ServerIPv4: TLabel;
    Lbl_ServerPassword: TLabel;
    Lbl_SessionName: TLabel;
    Lbl_SpecialXPMultiplier: TLabel;
    Lbl_StartTimeHour: TLabel;
    Lbl_StructureDamageMultiplier: TLabel;
    Lbl_StructureDamageRepairCooldown: TLabel;
    Lbl_StructurePickupHoldDuration: TLabel;
    Lbl_StructurePickupTimeAfterPlacement: TLabel;
    Lbl_StructurePreventResourceRadiusMultiplier: TLabel;
    Lbl_StructureResistanceMultiplier: TLabel;
    Lbl_SupplyCrateLootQualityMultiplier: TLabel;
    Lbl_SvrStatus: TLabel;
    Lbl_TamedDinoCharacterFoodDrainMultiplier: TLabel;
    Lbl_TamedDinoDamageMultiplier: TLabel;
    Lbl_TamedDinoResistanceMultiplier: TLabel;
    Lbl_TamedDinoTorporDrainMultiplier: TLabel;
    Lbl_TamedKillXPMultiplier: TLabel;
    Lbl_TamingSpeedMultiplier: TLabel;
    Lbl_TheMaxStructuresInRange: TLabel;
    Lbl_TribeNameChangeCooldown: TLabel;
    Lbl_TributeCharacterExpirationSeconds: TLabel;
    Lbl_TributeDinoExpirationSeconds: TLabel;
    Lbl_TributeItemExpirationSeconds: TLabel;
    Lbl_UnclaimedKillXPMultiplier: TLabel;
    Lbl_UpdateAllowedCheatersInterval: TLabel;
    Lbl_UseCorpseLifeSpanMultiplier: TLabel;
    Lbl_WildDinoCharacterFoodDrainMultiplier: TLabel;
    Lbl_WildDinoTorporDrainMultiplier: TLabel;
    Lbl_WildKillXPMultiplier: TLabel;
    Lbl_WinLiveMaxPlayers: TLabel;
    Lbl_XPMultiplier: TLabel;
    Lvl_ipv4: TLabel;
    Memo_ServerLogs: TMemo;
    Memo_RCONLogs: TMemo;
    Memo_GameIni: TMemo;
    Memo_GameIni_Append: TMemo;
    Memo_GameIni_Override: TMemo;
    Memo_GameUserSettings: TMemo;
    Memo_GameUserSettings_Append: TMemo;
    Memo_GameUserSettings_Override: TMemo;
    Memo_SrvCMDLogs: TMemo;
    MM_Command_Override: TMemo;
    MM_Command_Val: TMemo;
    OpenDialog_ImportFile: TOpenDialog;
    PageControl1: TPageControl;
    PageControl2: TPageControl;
    PageControl3: TPageControl;
    PageControl4: TPageControl;
    PageControl5: TPageControl;
    PageControl6: TPageControl;
    PageControl7: TPageControl;
    PageControl8: TPageControl;
    Pnl_SetIni: TPanel;
    Pnl_SaveProfile: TPanel;
    Pnl_ServerUpdate_Focus: TPanel;
    Pnl_SvrCMD: TPanel;
    Pnl_RCON: TPanel;
    PBar_Export: TProgressBar;
    RG_Cosmetic_Kind: TRadioGroup;
    SelectDirectoryDialog_Location: TSelectDirectoryDialog;
    SE_LimitBunkersPerTribeNum: TSpinEdit;
    SE_MaxActiveOutposts: TSpinEdit;
    SE_MaxActiveResourceCaches: TSpinEdit;
    SE_MaxActiveCityOutposts: TSpinEdit;
    SE_YoungIceFoxDeathCooldown: TSpinEdit;
    SE_CompanionsDeathCooldown: TSpinEdit;
    SE_MaxBlueprintDinoLevel: TSpinEdit;
    SE_MaxBlueprintDinoQuality: TSpinEdit;
    SE_MaxBlueprintItemQuality: TSpinEdit;
    SE_MaxBlueprintScoutQuality: TSpinEdit;
    SE_AutoPvEStartTimeSeconds: TSpinEdit;
    SE_AutoPvEStopTimeSeconds: TSpinEdit;
    SE_DestroyTamesOverLevel: TSpinEdit;
    SE_DestroyTamesOverLevelClamp: TSpinEdit;
    SE_Duration: TSpinEdit;
    SE_GBUsageToForceRestart_Val: TSpinEdit;
    SE_HttpConnectionTimeout: TSpinEdit;
    SE_HttpReceiveTimeout: TSpinEdit;
    SE_HttpSendTimeout: TSpinEdit;
    SE_ImplantSuicideCD: TSpinEdit;
    SE_MaxHexagonsPerCharacter: TSpinEdit;
    SE_MaxHexagonsPerCharacter2: TSpinEdit;
    SE_MaxNumberOfPlayersInTribe: TSpinEdit;
    SE_MaxPersonalTamedDinos: TSpinEdit;
    SE_MaxTamedDinos_SoftTameLimit: TSpinEdit;
    SE_MaxTamedDinos_SoftTameLimit_CountdownForDeletionDuration: TSpinEdit;
    SE_MaxTrainCars: TSpinEdit;
    SE_MaxTributeCharacters: TSpinEdit;
    SE_MaxTributeDinos: TSpinEdit;
    SE_MaxTributeItems: TSpinEdit;
    SE_Mod1_CryofridgeInventorySlots: TSpinEdit;
    SE_Mod1_CryogunCooldownSeconds: TSpinEdit;
    SE_Mod1_CryogunRangeFoundations: TSpinEdit;
    SE_Mod1_CryoSicknessTimer: TSpinEdit;
    SE_Mod1_CryoterminalInventorySlots: TSpinEdit;
    SE_Mod1_CryoTerminalMaxRadiusFoundations: TSpinEdit;
    SE_Mod1_ImprintAmountToGive: TSpinEdit;
    SE_Mod1_LimitCryoterminalsRange: TSpinEdit;
    SE_Mod1_MaxCryoterminalsInRange: TSpinEdit;
    SE_Mod1_NeutergunCooldownSeconds: TSpinEdit;
    SE_Mod1_NeutergunRangeFoundations: TSpinEdit;
    SE_Mod2_OutlineRange: TSpinEdit;
    SE_Mod3_MarkerLimit: TSpinEdit;
    SE_Mod5_AmmoBoxSlotCount: TSpinEdit;
    SE_Mod5_BeeHiveHoneyIntervalInSeconds: TSpinEdit;
    SE_Mod5_BeeHiveSlotCount: TSpinEdit;
    SE_Mod5_BeeHiveWateringRangeInFoundations: TSpinEdit;
    SE_Mod5_FabricatorCraftingSpeed: TSpinEdit;
    SE_Mod5_FabricatorSlotCount: TSpinEdit;
    SE_Mod5_FarmerRangeInFoundations: TSpinEdit;
    SE_Mod5_FarmerSlotCount: TSpinEdit;
    SE_Mod5_FridgeCraftingSpeed: TSpinEdit;
    SE_Mod5_FridgeSlotCount: TSpinEdit;
    SE_Mod5_GardenerRangeInFoundations: TSpinEdit;
    SE_Mod5_GardenerSlotCount: TSpinEdit;
    SE_Mod5_GeneratorSlotCount: TSpinEdit;
    SE_Mod5_GrinderCraftingSpeed: TSpinEdit;
    SE_Mod5_GrinderResourceReturnMax: TSpinEdit;
    SE_Mod5_GrinderResourceReturnPercent: TSpinEdit;
    SE_Mod5_GrinderSlotCount: TSpinEdit;
    SE_Mod5_HitchingPostDinoLimit: TSpinEdit;
    SE_Mod5_HitchingPostRange: TSpinEdit;
    SE_Mod5_HitchingPostTribeLimit: TSpinEdit;
    SE_Mod5_IndustrialForgeCraftingSpeed: TSpinEdit;
    SE_Mod5_IndustrialForgeSlotCount: TSpinEdit;
    SE_Mod5_LargeStorageSlotCount: TSpinEdit;
    SE_Mod5_MaxMutatorRangeInFoundations: TSpinEdit;
    SE_Mod5_MaxPowerRangeInFoundations: TSpinEdit;
    SE_Mod5_MetalStorageSlotCount: TSpinEdit;
    SE_Mod5_MutatorBuffMaxStackCount: TSpinEdit;
    SE_Mod5_NannyFeedingStartThreshold: TSpinEdit;
    SE_Mod5_NannyIntervalInSeconds: TSpinEdit;
    SE_Mod5_NannyMaxImprint: TSpinEdit;
    SE_Mod5_NannyRangeInFoundations: TSpinEdit;
    SE_Mod5_NannySlotCount: TSpinEdit;
    SE_Mod5_PreservingBinCraftingSpeed: TSpinEdit;
    SE_Mod5_PreservingBinSlotCount: TSpinEdit;
    SE_Mod5_PropagatorFuelInterval: TSpinEdit;
    SE_Mod5_PropagatorModCostMutate: TSpinEdit;
    SE_Mod5_PropagatorSlotCount: TSpinEdit;
    SE_Mod5_ReplicatorCraftingSpeed: TSpinEdit;
    SE_Mod5_ReplicatorSlotCount: TSpinEdit;
    SE_Mod5_ResourcePullRangeInFoundations: TSpinEdit;
    SE_Mod5_SmallStorageSlotCount: TSpinEdit;
    SE_Mod5_TekGeneratorSlotCount: TSpinEdit;
    SE_Mod5_TransmutatorSlotCount: TSpinEdit;
    SE_Mod5_TribePropagatorLimit: TSpinEdit;
    SE_OverrideMaxExperiencePointsDino: TSpinEdit;
    SE_OverrideMaxExperiencePointsPlayer: TSpinEdit;
    SE_HttpTimeout: TSpinEdit;
    SE_PhotoModeRangeLimit: TSpinEdit;
    SE_Port: TSpinEdit;
    SE_PvPZoneStructureDamageMultiplier: TSpinEdit;
    SE_Queryport: TSpinEdit;
    SE_RCONPort: TSpinEdit;
    SE_StructureDamageRepairCooldown: TSpinEdit;
    SE_TheMaxStructuresInRange: TSpinEdit;
    SE_MaxPlatformSaddleStructureLimit: TSpinEdit;
    SE_MaxGateFrameOnSaddles: TSpinEdit;
    SE_TributeCharacterExpirationSeconds: TSpinEdit;
    SE_TributeDinoExpirationSeconds: TSpinEdit;
    SE_TributeItemExpirationSeconds: TSpinEdit;
    SE_WinLiveMaxPlayers_Val: TSpinEdit;
    SL_Button_ItemMaxQuantity_AddRow: TStringGrid;
    SL_OverrideNamedEngramEntries: TStringGrid;
    SL_SpawnList: TStringGrid;
    SE_CryopodFridgeCooldowntime: TSpinEdit;
    SE_LimitNonPlayerDroppedItemsCount: TSpinEdit;
    SE_LimitNonPlayerDroppedItemsRange: TSpinEdit;
    SE_LimitTurretsNum: TSpinEdit;
    SG_Cosmetic: TStringGrid;
    SE_ArmadoggoDeathCooldown: TSpinEdit;
    SE_P2PConnectionTimeout: TSpinEdit;
    SE_MaxCosmoWeaponAmmo: TSpinEdit;
    SE_CosmoWeaponAmmoReloadAmount: TSpinEdit;
    SL_SpawnList2: TStringGrid;
    SE_ASASM_AutoDestroyWildDinosSeconds: TSpinEdit;
    SE_DelayedRestartSec: TSpinEdit;
    StringGrid_PlayerList: TStringGrid;
    Tab_SvrLogs: TTabSheet;
    Tab_LostColony: TTabSheet;
    Tab_Ragnarok: TTabSheet;
    Tab_QuickSet: TTabSheet;
    Tab_ServerCMD: TTabSheet;
    Tab_EngineINI: TTabSheet;
    Tab_Multiplier: TTabSheet;
    Tab_Extinction: TTabSheet;
    Tab_Experimental_IniImport: TTabSheet;
    Tab_Experimental_EventRate: TTabSheet;
    Tab_URLs: TTabSheet;
    Tab_Message: TTabSheet;
    Tab_CrossARK: TTabSheet;
    Tab_Args: TTabSheet;
    Tab_Args2: TTabSheet;
    Tab_Engrams: TTabSheet;
    Tab_Experimental: TTabSheet;
    Tab_ExtraMod: TTabSheet;
    Tab_GameIni: TTabSheet;
    Tab_GameUserSettingsini: TTabSheet;
    Tab_general: TTabSheet;
    Tab_IniFiles: TTabSheet;
    Tab_Mod1: TTabSheet;
    Tab_Mod2: TTabSheet;
    Tab_Mod3: TTabSheet;
    Tab_Mod4: TTabSheet;
    Tab_Mod5_1: TTabSheet;
    Tab_Mod5_2: TTabSheet;
    Tab_Mod5_3: TTabSheet;
    Tab_OfficialMod: TTabSheet;
    Tab_PlayerSetting: TTabSheet;
    Tab_PvE: TTabSheet;
    Tab_PvP: TTabSheet;
    Tab_RCON: TTabSheet;
    Tab_ServerSettings: TTabSheet;
    Tab_Spawn: TTabSheet;
    Tab_StructureSettings: TTabSheet;
    Tab_TamedDino: TTabSheet;
    Tab_TamedDinoSettings: TTabSheet;
    Tab_VisualSettings: TTabSheet;
    Tab_WildDino: TTabSheet;
    Tab_WorldSetting: TTabSheet;
    Tab_XP: TTabSheet;
    Timer_SvrStatus: TTimer;
    Timer_GetVerInfo: TTimer;
    ToggleBox_ServerAdminPassword2: TToggleBox;
    ToggleBox_ServerAdminPassword: TToggleBox;
    ToggleBox_clusterid: TToggleBox;
    ToggleBox_SessionName: TToggleBox;
    ToggleBox_ServerPassword: TToggleBox;
    procedure Btn_InstVerClick(Sender: TObject);
    procedure Button_SvrCMD_CommandClick(Sender: TObject);
    procedure Button_SvrCMD_DelayedRestartClick(Sender: TObject);
    procedure Button_AllModInArgsClick(Sender: TObject);
    procedure Button_ClusterDirOverrideClick(Sender: TObject);
    procedure Button_Cosmetic_LocalFileClick(Sender: TObject);
    procedure Button_DataBK2Click(Sender: TObject);
    procedure Button_Engrams_AddRowClick(Sender: TObject);
    procedure Button_Engrams_DelRowClick(Sender: TObject);
    procedure Button_ExportClick(Sender: TObject);
    procedure Button_ImportClick(Sender: TObject);
    procedure Button_Import_FileClick(Sender: TObject);
    procedure Button_Ini_ImportClick(Sender: TObject);
    procedure Button_Ini_Import_DirClick(Sender: TObject);
    procedure Button_RCON_ClearClick(Sender: TObject);
    procedure Button_ServerPassword_RandomClick(Sender: TObject);
    procedure Button_SpawnList_AddClick(Sender: TObject);
    procedure Button_SpawnList_DelClick(Sender: TObject);
    procedure CB_Change(Sender: TObject);
    procedure CB_RCON_CommandKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure CB_RCON_Command_ListChange(Sender: TObject);
    procedure CB_SrvStatus_ValChange(Sender: TObject);
    procedure CGRG_Enter(Sender: TObject);
    procedure ChB_bAllowFlyerDinoSubmergingChange(Sender: TObject);
    procedure Edit_ActiveMapMod_ValEditingDone(Sender: TObject);
    procedure Edit_AllModInArgsChange(Sender: TObject);
    procedure Edit_ModsEditingDone(Sender: TObject);
    procedure Edit_ModsEnter(Sender: TObject);
    procedure Edit_ModsExit(Sender: TObject);
    procedure Edit_passivemodsEditingDone(Sender: TObject);
    procedure FrameDblClick(Sender: TObject);
    procedure GameIniChangeWithFocusOff(Sender: TObject);
    procedure argsChange(Sender: TObject);
    procedure argsChangeWithFocusOff(Sender: TObject);
    procedure argsGUSChange(Sender: TObject);
    procedure argsGUSChangeWithFocusOff(Sender: TObject);
    procedure AsyncProcess_ListPlayerTerminate(Sender: TObject);
    procedure ButtonClearRCONLogsClick(Sender: TObject);
    procedure Button_AltSaveDirectoryNameClick(Sender: TObject);
    procedure Button_InstallClick(Sender: TObject);
    procedure Button_Install_LocationClick(Sender: TObject);
    procedure Button_jump_ModStoreClick(Sender: TObject);
    procedure Button_SaveProfileClick(Sender: TObject);
    procedure Button_ServerStartClick(Sender: TObject);
    procedure Button_SetIniClick(Sender: TObject);
    procedure CG_ActiveEventItemClick(Sender: TObject; Index: integer);
    procedure ChB_GUS_OverrideChange(Sender: TObject);
    procedure FocusOffclForm(Sender: TObject);
    procedure Edit_ProfileChange(Sender: TObject);
    procedure Eg_Wood(Sender: TObject);
    procedure FocusOff(Sender: TObject);
    procedure FocusOn(Sender: TObject);
    procedure GameIniChange(Sender: TObject);
    procedure GUSChange(Sender: TObject);
    procedure GUSChangeWithFocusOff(Sender: TObject);
    procedure Mods_Change(Sender: TObject);
    procedure RCON_COMAND_Click(Sender: TObject);
    procedure RG_Cosmetic_Change(Sender: TObject);
    procedure ServerPlatformChange(Sender: TObject);
    procedure SL_OverrideNamedEngramEntriesEditingDone(Sender: TObject);
    procedure SL_SpawnList2EditingDone(Sender: TObject);
    procedure Timer_SvrStatusTimer(Sender: TObject);
    procedure Timer_GetVerInfoTimer(Sender: TObject);
    procedure ConditionCheck_Mods;
    procedure ToggleBoxChange(Sender: TObject);
  private
    BeforeData :TBeforeData;
    function  GetBusyFlg : Boolean;
    procedure SetBusyFlg(const AValue : Boolean);
    procedure StartServer;
    procedure HideTabs;
    procedure SetCmpInfo(Sender: TObject);
    procedure ChkCmpInfo(Sender: TObject);
  public
    ARKestra :boolean;
    sLastlogMessage :string;
    sLast_Profile_Status :string;
    iLast_Profile_Status_Time:LongInt;
    iLast_AutoDestroyWildDino_Time:LongInt;
    flg_backup:boolean;
    RClient : TRCON;
    ActiveTabColor :DWORD;
    FocusColor     :DWORD;
    beforeProfileName : string;
    beforeMods :string;
    iProsessId :Integer;
    RCONSender :TObject;
    isFirstExecute :boolean;
    canEditIni     :boolean;
    unuse_bat      :boolean;
    StrongClean    :boolean;
    DarkMode       :boolean;
    UseBuiltinRCON :boolean;
    DebugUpdate    :boolean;
    OldModList     :boolean;
    DisableSteamcmdSharing:boolean;
    EnableShareUpdate:boolean;
    bServerCMD :boolean;
    HiddenTabs :String;
    FlgHiddenTabs :boolean;
    DiscordAdmHookKind: string;
    NotificationKind: array [0..2,0..9] of boolean;
    DiscordAdmHookURL : string;
    DiscordAdmHookName: string;
    TrayNotificationKind: string;
    TrayNotificationName: string;
    iNewBuildID:integer;
    ArkVer     :String;
    AppVer     :string;
    AppVer_old :string;
    sl_ProfileLog :TStringList;
    bManuallyStarting:boolean;
    bManuallyStopping:boolean;
    iMemUseMB :integer;
    iCPULastTime :LongInt;
    iCPUCurrTime :LongInt;
    iCPULastUSE :LongInt;
    iCPUCurrUSE :LongInt;
    iExecime    :LongInt;
    iUptime    :LongInt;
    sUptime    :string;
    fCPU_Use   :double;
    TrayIcon_ASASM: TTrayIcon;
  public
    constructor Create(TheOwner: TComponent);override;
    destructor Destroy; override;
    procedure SetTrans;
    procedure createArgs;
    procedure createGUSIni;
    procedure createGameIni;
    procedure createDinoGrid;
    procedure saveProfile;
    procedure loadProfile(sname:string);
    procedure loadProfileFromIni(profieName:string;shooterGamePath:string);
    procedure loadArgsFromBat(batFile:string);
    procedure updateServerStatus;
    procedure new_updateServerStatus;
    procedure SetProfileLog(message:string);
    function  ArkFolder(FolderName:string):string;
    function  DeleteArkFolder(FolderName:string):boolean;
    function  DeleteArkFile(FolderName:string;FileName:string):boolean;
    procedure FlgsSetup;
    property  BusyFlg : Boolean Read GetBusyFlg Write SetBusyFlg;
  end;


implementation

uses
  mainui;

{$R *.lfm}

procedure TPageControl.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  if DarkMode then exit;
  with Params do
  begin
    if not (csDesigning in ComponentState) then
      Style := Style or TCS_OWNERDRAWFIXED;
  end;
end;

procedure TPageControl.CNDrawItem(var Message: TWMDrawItem);
var
  BrushHandle: HBRUSH;
  BrushColor: COLORREF;
begin
  if DarkMode then exit;
  with Message.DrawItemStruct^ do
  begin
    SVActiveIDX := TabCtrl_GetCurSel(self.Handle);
    if (itemID = SVActiveIDX) then BrushColor := ActiveTabColor
                              else BrushColor := ColorToRGB(clBtnFace);

    BrushHandle := CreateSolidBrush(BrushColor);
    FillRect(hDC, rcItem, BrushHandle);
    SetBkMode(hDC, TRANSPARENT);
    if (TabToPageIndex(itemID) > -1) then
    begin
      DrawTextEx(hDC, PChar(UTF8ToCP932(Page[TabToPageIndex(itemID)].Caption)), -1, rcItem, DT_CENTER or
        DT_VCENTER or DT_SINGLELINE, nil);
    end;
  end;
  Message.Result := 1;
end;


{ TAsaFrame }

constructor TAsaFrame.create(TheOwner: TComponent);
begin
  inherited;

  sLastlogMessage := '';
  iMemUseMB := 0;
  iCPULastTime := 0;
  iCPUCurrTime := 0;
  iCPULastUSE := 0;
  iCPUCurrUSE := 0;
  fCPU_Use := 0.0;
  iExecime:= 0;
  iUptime := 0;
  sl_ProfileLog := TStringList.Create;
  FlgHiddenTabs := true;

  if FileExists('RCON.txt') then CB_RCON_Command_List.Items.LoadFromFile('RCON.txt');

  iProsessId := 0;
  canEditIni := false;
  StrongClean := false;
  isFirstExecute := true;
  flg_backup := false;
  sLast_Profile_Status := '';
  bServerCMD := false;
  Tab_SvrLogs.TabVisible:=false;
end;

destructor TAsaFrame.Destroy;
begin
  sl_ProfileLog.Free;

  inherited;
end;

procedure TAsaFrame.SetTrans;
begin
  CB_RCON_Command_List.Items.Strings[0]:= Form_MessageTrans.Lbl_Hidden_CB_RCON_Command_List.Caption;
end;

procedure TAsaFrame.FlgsSetup;
var
  i  :integer;
  sl :TStringList;
begin
  FlgHiddenTabs := true;
  HideTabs;

  CB_Install_ShareUpdate.Checked:=EnableShareUpdate;

  Tab_ServerCMD.TabVisible:=bServerCMD;

  PageControl1.ActiveTabColor:=ActiveTabColor;
  PageControl2.ActiveTabColor:=ActiveTabColor;
  PageControl3.ActiveTabColor:=ActiveTabColor;
  PageControl4.ActiveTabColor:=ActiveTabColor;
  PageControl5.ActiveTabColor:=ActiveTabColor;
  PageControl6.ActiveTabColor:=ActiveTabColor;
  PageControl7.ActiveTabColor:=ActiveTabColor;
  PageControl8.ActiveTabColor:=ActiveTabColor;

  PageControl1.DarkMode:=DarkMode;
  PageControl2.DarkMode:=DarkMode;
  PageControl3.DarkMode:=DarkMode;
  PageControl4.DarkMode:=DarkMode;
  PageControl5.DarkMode:=DarkMode;
  PageControl6.DarkMode:=DarkMode;
  PageControl7.DarkMode:=DarkMode;
  PageControl8.DarkMode:=DarkMode;

  sl := TStringList.Create;
  try
    sl.CommaText:=DiscordAdmHookKind;
    for i := 0 to sl.Count-1 do
    begin
      if (sl.Strings[i] = '1') then NotificationKind[0,i] := true
                               else NotificationKind[0,i] := false;
    end;
    sl.CommaText:=TrayNotificationKind;
    for i := 0 to sl.Count-1 do
    begin
      if (sl.Strings[i] = '1') then NotificationKind[2,i] := true
                               else NotificationKind[2,i] := false;
    end;
  finally
    sl.Free;
  end;
end;

procedure TAsaFrame.HideTabs;
var
  i  :integer;
  sl :TStringList;
begin
  if FlgHiddenTabs then
  begin
    sl := TStringList.Create;
    try
      sl.CommaText:=HiddenTabs;
      for i := 0 to sl.Count-1 do
      begin
        if (sl.Strings[i] = '1') then
        begin
          if (i = 0) then Tab_ExtraMod         .TabVisible:=false;
          if (i = 1) then Tab_ServerSettings   .TabVisible:=false;
          if (i = 2) then Tab_WorldSetting     .TabVisible:=false;
          if (i = 3) then Tab_VisualSettings   .TabVisible:=false;
          if (i = 4) then Tab_PlayerSetting    .TabVisible:=false;
          if (i = 5) then Tab_TamedDinoSettings.TabVisible:=false;
          if (i = 6) then Tab_StructureSettings.TabVisible:=false;
          if (i = 7) then Tab_Engrams          .TabVisible:=false;
          if (i = 8) then Tab_XP               .TabVisible:=false;
          if (i = 9) then Tab_IniFiles         .TabVisible:=false;
          if (i =10) then Tab_Experimental     .TabVisible:=false;
        end;
      end;
    finally
      FlgHiddenTabs := true;
      sl.Free;
    end;
  end else begin
    Tab_ExtraMod         .TabVisible:=true;
    Tab_ServerSettings   .TabVisible:=true;
    Tab_WorldSetting     .TabVisible:=true;
    Tab_VisualSettings   .TabVisible:=true;
    Tab_PlayerSetting    .TabVisible:=true;
    Tab_TamedDinoSettings.TabVisible:=true;
    Tab_StructureSettings.TabVisible:=true;
    Tab_Engrams          .TabVisible:=true;
    Tab_XP               .TabVisible:=true;
    Tab_IniFiles         .TabVisible:=true;
    Tab_Experimental     .TabVisible:=true;
  end;
end;

function  TAsaFrame.ArkFolder(FolderName:string):string;
begin
  result := Edit_Install_Location_Val.Text+'\'+FolderName;
end;

function  TAsaFrame.DeleteArkFolder(FolderName:string):boolean;
var
  TargetDir :string;
begin
  TargetDir := Edit_Install_Location_Val.Text+'\'+FolderName;

  Result:=DeleteFolder(TargetDir);
end;

function  TAsaFrame.DeleteArkFile(FolderName:string;FileName:string):boolean;
var
  TargetDir :string;
  TergetFile :string;
begin
  TargetDir := Edit_Install_Location_Val.Text+'\'+FolderName;
  TergetFile:= TargetDir+'\'+FileName;

  Result:=DeleteFile(TergetFile);
end;

function  TAsaFrame.GetBusyFlg : Boolean;
var
  mainui : TAsa_ui;
begin
  mainui := TAsa_ui(TPageControl(TTabSheet(TAsaFrame(PageControl1.Parent).Parent).Parent).Parent);
  result := mainui.BusyFlg;
end;

procedure TAsaFrame.SetBusyFlg(const AValue : Boolean);
var
  mainui : TAsa_ui;
begin
  mainui := TAsa_ui(TPageControl(TTabSheet(TAsaFrame(PageControl1.Parent).Parent).Parent).Parent);
  mainui.BusyFlg:=AValue;
end;

procedure TAsaFrame.SetCmpInfo(Sender: TObject);
begin
  if (Sender.ClassName = 'TEdit') then
  begin
    BeforeData.Name:=TEdit(Sender).Name;
    BeforeData.Str :=TEdit(Sender).Text;
  end;
  if (Sender.ClassName = 'TSpinEdit') then
  begin
    BeforeData.Name:=TSpinEdit(Sender).Name;
    BeforeData.Int :=TSpinEdit(Sender).Value;
  end;
  if (Sender.ClassName = 'TFloatSpinEdit') then
  begin
    BeforeData.Name:=TFloatSpinEdit(Sender).Name;
    BeforeData.Flt :=TFloatSpinEdit(Sender).Value;
  end;
  if (Sender.ClassName = 'TCheckBox') then
  begin
    BeforeData.Name:=TCheckBox(Sender).Name;
    BeforeData.Bol :=TCheckBox(Sender).Checked;
  end;
  if (Sender.ClassName = 'TComboBox') then
  begin
    BeforeData.Name:=TComboBox(Sender).Name;
    BeforeData.Str :=TComboBox(Sender).Text;
  end;
  if (Sender.ClassName = 'TCheckGroup') then
  begin
    BeforeData.Name:=TComboBox(Sender).Name;
    BeforeData.Str :='';
  end;
  if (Sender.ClassName = 'TRadioGroup') then
  begin
    BeforeData.Name:=TComboBox(Sender).Name;
    BeforeData.Str :='';
  end;
  if (Sender.ClassName = 'TMemo') then
  begin
    BeforeData.Name:=TMemo(Sender).Name;
    BeforeData.Str :=TMemo(Sender).Text;
  end;
end;

procedure TAsaFrame.ChkCmpInfo(Sender: TObject);
begin
  if (Sender.ClassName = 'TEdit') then
  begin
    if (BeforeData.Name=TEdit(Sender).Name) and
       (BeforeData.Str<>TEdit(Sender).Text) then
    begin
      Pnl_SaveProfile.Color:=clRed;
      Pnl_SetIni.Color:=clRed;
    end;
  end;
  if (Sender.ClassName = 'TSpinEdit') then
  begin
    if (BeforeData.Name=TSpinEdit(Sender).Name) and
       (BeforeData.Int<>TSpinEdit(Sender).Value) then
    begin
      Pnl_SaveProfile.Color:=clRed;
      Pnl_SetIni.Color:=clRed;
    end;
  end;
  if (Sender.ClassName = 'TFloatSpinEdit') then
  begin
    if (BeforeData.Name=TFloatSpinEdit(Sender).Name) and
       (BeforeData.Flt<>TFloatSpinEdit(Sender).Value) then
    begin
      Pnl_SaveProfile.Color:=clRed;
      Pnl_SetIni.Color:=clRed;
    end;
  end;
  if (Sender.ClassName = 'TCheckBox') then
  begin
    if (BeforeData.Name=TCheckBox(Sender).Name) and
       (BeforeData.Bol<>TCheckBox(Sender).Checked) then
    begin
      Pnl_SaveProfile.Color:=clRed;
      Pnl_SetIni.Color:=clRed;
    end;
  end;
  if (Sender.ClassName = 'TComboBox') then
  begin
    if (BeforeData.Name=TComboBox(Sender).Name) and
       (BeforeData.Str<>TComboBox(Sender).Text) then
    begin
      Pnl_SaveProfile.Color:=clRed;
      Pnl_SetIni.Color:=clRed;
    end;
  end;
  if (Sender.ClassName = 'TCheckGroup') then
  begin
    Pnl_SaveProfile.Color:=clRed;
    Pnl_SetIni.Color:=clRed;
  end;
  if (Sender.ClassName = 'TRadioGroup') then
  begin
    Pnl_SaveProfile.Color:=clRed;
    Pnl_SetIni.Color:=clRed;
  end;
  if (Sender.ClassName = 'TMemo') then
  begin
    if (BeforeData.Name=TMemo(Sender).Name) and
       (BeforeData.Str<>TMemo(Sender).Text) then
    begin
      Pnl_SaveProfile.Color:=clRed;
      Pnl_SetIni.Color:=clRed;
    end;
  end;

end;

procedure TAsaFrame.ConditionCheck_Mods;
var
  ConditionColor :TColor;
  sl : TStringList;
  str,
  str2,
  str3 :string;
  i :integer;
  kind:integer;
begin
  for kind := 0 to 3 do
  begin
    ConditionColor := clNone;
    sl := TStringList.Create;

    try
      if (kind = 0) then str := Edit_Mods.Text;
      if (kind = 1) then str := Edit_ActiveMapMod_Val.Text;
      if (kind = 2) then str := Edit_passivemods.Text;
      if (kind = 3) then str := Edit_AutoAddedModInArgs.Text;
      str2:= '';
      if (str = '') then continue;

      // Condition Red
      if (pos(',,',str) <> 0) then
      begin
        str2:= 'Error:illegal double comma.';
        ConditionColor := clRed;
        continue;
      end;
      if (copy(str,str.Length,1) = ',') then
      begin
        str2:= 'Error:illegal last comma.';
        ConditionColor := clRed;
        continue;
      end;
      if (kind = 1)and(pos(',',str) <> 0) then
      begin
        str2:= 'Error:illegal many ModID.';
        ConditionColor := clRed;
        continue;
      end;

      sl.CommaText:=str;
      for i:=0 to sl.Count -1 do
      begin
        str3 := sl[i];
        if str3.Length <= 5 then
        begin
          str2:= format('Error:illegal ModID[%s].',[str3]);
          ConditionColor := clRed;
          break;
        end;
        if str3.Length >= 8 then
        begin
          str2:= format('Error:illegal ModID[%s].',[str3]);
          ConditionColor := clRed;
          break;
        end;
        if (StrToIntDef(str3,-99) = -99) then
        begin
          str2:= format('Error:illegal ModID[%s].',[str3]);
          ConditionColor := clRed;
          break;
        end;
        if (StrToIntDef(str3,-99) < 877745) then
        begin
          str2:= format('Error:illegal ModID[%s].',[str3]);
          ConditionColor := clRed;
          break;
        end;
        if (pos('(ClientOnly)',sl_ModList.Values[str3])=1) then
        begin
          str2:= format('Error:Client Only Mod ModID[%s].',[str3]);
          ConditionColor := clRed;
          break;
        end;

        // Condition Yellow
        if sl_ModList.Values[str3] = '' then
        begin
          str2:= format('Warning:Unknown ModID[%s].',[str3]);
          ConditionColor := clYellow;
          break;
        end;
      end;
      if (str2 <> '') then continue;
    finally
      sl.Free;
      if (kind = 0) then
      begin
        Lbl_Mods.Color := ConditionColor;
        Lbl_Mods.Hint  := str2;
        if (str2 <> '') then Lbl_Mods.ShowHint:= true
                        else Lbl_Mods.ShowHint:= false;
      end;
      if (kind = 1) then
      begin
        Lbl_ActiveMapMod.Color := ConditionColor;
        Lbl_ActiveMapMod.Hint  := str2;
        if (str2 <> '') then Lbl_ActiveMapMod.ShowHint:= true
                        else Lbl_ActiveMapMod.ShowHint:= false;
      end;
      if (kind = 2) then
      begin
        Lbl_passivemods.Color := ConditionColor;
        Lbl_passivemods.Hint  := str2;
        if (str2 <> '') then Lbl_passivemods.ShowHint:= true
                        else Lbl_passivemods.ShowHint:= false;
      end;
      if (kind = 3) then
      begin
        Lbl_AutoAddedModInArgs.Color := ConditionColor;
        Lbl_AutoAddedModInArgs.Hint  := str2;
        if (str2 <> '') then Lbl_AutoAddedModInArgs.ShowHint:= true
                        else Lbl_AutoAddedModInArgs.ShowHint:= false;
      end;
    end;
  end;
end;

procedure TAsaFrame.ToggleBoxChange(Sender: TObject);
begin
  if (Sender = ToggleBox_ServerAdminPassword2) then
  begin
    if (ToggleBox_ServerAdminPassword2.State = cbChecked) then Edit_ServerAdminPassword2.PasswordChar:= #0
                                                          else Edit_ServerAdminPassword2.PasswordChar:= '*';
  end;

  if (Sender = ToggleBox_SessionName) then
  begin
    if (ToggleBox_SessionName.State = cbChecked) then Edit_SessionName.PasswordChar:= #0
                                                 else Edit_SessionName.PasswordChar:= '*';
  end;

  if (Sender = ToggleBox_ServerPassword) then
  begin
    if (ToggleBox_ServerPassword.State = cbChecked) then Edit_ServerPassword.PasswordChar:= #0
                                                    else Edit_ServerPassword.PasswordChar:= '*';
  end;

  if (Sender = ToggleBox_ServerAdminPassword) then
  begin
    if (ToggleBox_ServerAdminPassword.State = cbChecked) then Edit_ServerAdminPassword.PasswordChar:= #0
                                                         else Edit_ServerAdminPassword.PasswordChar:= '*';
  end;

  if (Sender = ToggleBox_clusterid) then
  begin
    if (ToggleBox_clusterid.State = cbChecked) then Edit_clusterid.PasswordChar:= #0
                                               else Edit_clusterid.PasswordChar:= '*';
  end;
end;

procedure TAsaFrame.Button_Install_LocationClick(Sender: TObject);
begin
  SelectDirectoryDialog_Location.InitialDir := Edit_Install_Location_Val.Text + '\';
  SelectDirectoryDialog_Location.FileName   := Edit_Install_Location_Val.Text;
  if SelectDirectoryDialog_Location.Execute then
  begin
    Edit_Install_Location_Val.Text:=SelectDirectoryDialog_Location.FileName;
  end;
end;

procedure TAsaFrame.Button_jump_ModStoreClick(Sender: TObject);
begin
  ShellExecute(0, 'open', PChar(String('https://www.curseforge.com/ark-survival-ascended')), nil, nil, 0);
end;

procedure TAsaFrame.Button_SaveProfileClick(Sender: TObject);
begin
  Lbl_Profile_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Profile_Status_01.Caption;
  Lbl_Profile_Status.Repaint;
  sLast_Profile_Status :=Form_MessageTrans.Lbl_Hidden_Profile_Status_01.Caption;
  iLast_Profile_Status_Time := DateTimeToUnix(now);

  saveProfile;

  Lbl_Profile_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Profile_Status_02.Caption;
  Lbl_Profile_Status.Repaint;
  sLast_Profile_Status :=Form_MessageTrans.Lbl_Hidden_Profile_Status_02.Caption;
  iLast_Profile_Status_Time := DateTimeToUnix(now);
  Pnl_SaveProfile.Color:=clForm;
end;

procedure TAsaFrame.StartServer;
var
  OldFileTime :integer;
  NewFileTime :integer;
begin
  AsyncProcess_NoWait.CurrentDirectory:=ExtractFileDir(Edit_Install_Location_Val.Text+'\')+'\ShooterGame\Binaries\Win64';
  if (ChB_CMD_override.Checked) and (trim(StringReplace(MM_Command_Override.Text,'ArkAscendedServer.exe ','',[ rfReplaceAll ]))<>'') then
  begin
    AsyncProcess_NoWait.CommandLine:=ExtractFileDir(Edit_Install_Location_Val.Text+'\')+'\ShooterGame\Binaries\Win64\'+MM_Command_Override.Text;
  end else begin
    AsyncProcess_NoWait.CommandLine:=ExtractFileDir(Edit_Install_Location_Val.Text+'\')+'\ShooterGame\Binaries\Win64\'+MM_Command_Val.Text;
  end;

  if FileExists(ExtractFileDir(Edit_Install_Location_Val.Text+'\')+'\ShooterGame\Saved\Logs\ShooterGame.log') then
  begin
    OldFileTime := FileAge(ExtractFileDir(Edit_Install_Location_Val.Text+'\')+'\ShooterGame\Saved\Logs\ShooterGame.log');
  end else begin
    OldFileTime := 0;
  end;
  AsyncProcess_NoWait.Execute;
  iProsessId := AsyncProcess_NoWait.ProcessID;

  sleep(1000);
  if FileExists(ExtractFileDir(Edit_Install_Location_Val.Text+'\')+'\ShooterGame\Saved\Logs\ShooterGame.log') then
  begin
    NewFileTime := FileAge(ExtractFileDir(Edit_Install_Location_Val.Text+'\')+'\ShooterGame\Saved\Logs\ShooterGame.log');
  end else begin
    NewFileTime := -1;
  end;
  while (NewFileTime < OldFileTime) do
  begin
    sleep(500);
    if FileExists(ExtractFileDir(Edit_Install_Location_Val.Text+'\')+'\ShooterGame\Saved\Logs\ShooterGame.log') then
    begin
      NewFileTime := FileAge(ExtractFileDir(Edit_Install_Location_Val.Text+'\')+'\ShooterGame\Saved\Logs\ShooterGame.log');
    end else begin
      NewFileTime := -1;
    end;
  end;
end;

procedure TAsaFrame.Button_ServerStartClick(Sender: TObject);
var
  discord_hook : TDiscord_Webhook;
begin
  if BusyFlg then
  begin
    Lbl_Profile_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Import_Status_01.Caption;
    Lbl_Profile_Status.Repaint;
    sLast_Profile_Status :=Form_MessageTrans.Lbl_Hidden_Import_Status_01.Caption;
    iLast_Profile_Status_Time := DateTimeToUnix(now);

    exit;
  end;

  BusyFlg := true;
  try
    Screen.Cursor:=crHourGlass;
    Pnl_RCON.Enabled:=False;

    if (CB_SrvStatus_Val.ItemIndex < 3) then
    begin
      //Unavailable
      showmessage('Can'+ #39 + 't start this server. Please set up!');
      exit;
    end;
    if (CB_SrvStatus_Val.ItemIndex = 3) then
    begin
      //start server;
      Lbl_Profile_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Profile_Status_09.Caption;
      Lbl_Profile_Status.Repaint;
      sLast_Profile_Status :=Form_MessageTrans.Lbl_Hidden_Profile_Status_09.Caption;
      iLast_Profile_Status_Time := DateTimeToUnix(now);

      if (NotificationKind[0,0]) then
      begin
        discord_hook := TDiscord_Webhook.Create;
        try
          discord_hook.SetURL(DiscordAdmHookURL);
          discord_hook.SetSvrStartingMessage(DiscordAdmHookName,Edit_Profile.Text,CB_MapName.Text);
          discord_hook.send;
        finally
          discord_hook.Free;
        end;
      end;
      if (NotificationKind[2,0]) then
      begin
        TrayIcon_ASASM.Visible:=true;
        TrayIcon_ASASM.BalloonTitle:=format('[%s]Server Starting...',[TrayNotificationName]);
        TrayIcon_ASASM.BalloonHint :=format('Prof=%s : Map=%s',[Edit_Profile.Text,CB_MapName.Text]);
        TrayIcon_ASASM.ShowBalloonHint;
      end;

      SetProfileLog('Server Starting manually.');
      bManuallyStarting := true;

      StartServer;

      exit;
    end;
    if (CB_SrvStatus_Val.ItemIndex = 4) then
    begin
      //force stop server;
      Lbl_Profile_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Profile_Status_10.Caption;
      Lbl_Profile_Status.Repaint;
      sLast_Profile_Status :=Form_MessageTrans.Lbl_Hidden_Profile_Status_10.Caption;
      iLast_Profile_Status_Time := DateTimeToUnix(now);

      SetProfileLog('Server Stopping manually. Forced.');
      bManuallyStopping:=true;

      closeServer(ExtractFileDir(Edit_Install_Location_Val.Text+'\')+'\ShooterGame\Binaries\Win64\ArkAscendedServer.exe');

      Lbl_PlayerCnt.Caption := format('Player:%3d/%3d',[0,SE_WinLiveMaxPlayers_Val.Value]);
      exit;
    end;
    if (CB_SrvStatus_Val.ItemIndex = 5) then
    begin
      //stop server;
      Lbl_Profile_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Profile_Status_10.Caption;
      Lbl_Profile_Status.Repaint;
      sLast_Profile_Status :=Form_MessageTrans.Lbl_Hidden_Profile_Status_10.Caption;
      iLast_Profile_Status_Time := DateTimeToUnix(now);

      if ((Edit_ServerAdminPassword.Text<>'')and(SE_RCONPort.Text<>'')and(CB_RCONEnabled.Checked)) then
      begin
        SetProfileLog('Server Stopping manually.');
        bManuallyStopping:=true;

        if UseBuiltinRCON then
        begin
          RClient := TRCON.Create;
          try
            RClient.port    :=SE_RCONPort.Value;
            RClient.password:=Edit_ServerAdminPassword.Text;
            RClient.sendcmd('SaveWorld');
            RClient.sendcmd('DoExit');
          finally
            RClient.Free;
          end;
        end else begin
          AsyncProcess.CommandLine := format('mcrcon\mcrcon.exe -P %s -p %s DoExit',[SE_RCONPort.Text,Edit_ServerAdminPassword.Text]);
          AsyncProcess.Execute;
          WaitProcess(AsyncProcess);

          AsyncProcess.CommandLine:='';
        end;
      end else begin
        if (CB_SvrCMDEnabled.Checked)  and (not ChB_USE_AsaApiLoader.Checked) then
        begin
          SetProfileLog('Server Stopping manually. Forced. Saved.');
          bManuallyStopping:=true;

          SendCmdOtherWindow(iProsessId,'Exit');
        end else begin
          SetProfileLog('Server Stopping manually. Forced. NoSaved.');
          bManuallyStopping:=true;

          closeServer(ExtractFileDir(Edit_Install_Location_Val.Text+'\')+'\ShooterGame\Binaries\Win64\ArkAscendedServer.exe');
        end;
      end;
      Lbl_PlayerCnt.Caption := format('Player:%3d/%3d',[0,SE_WinLiveMaxPlayers_Val.Value]);
      exit;
    end;
  finally
    Screen.Cursor:=crDefault;
    BusyFlg := false;
  end;
end;

procedure TAsaFrame.Button_SetIniClick(Sender: TObject);
var
  ini  :TIniFile;
  sec,key,val :string;
  line    :string;
  i:integer;
  k:integer;
  sl : TStringList;
begin
  if (CB_SrvStatus_Val.ItemIndex in [2,3,5]) then
  begin
    Lbl_Profile_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Profile_Status_03.Caption;
    Lbl_Profile_Status.Repaint;
    sLast_Profile_Status :=Form_MessageTrans.Lbl_Hidden_Profile_Status_03.Caption;
    iLast_Profile_Status_Time := DateTimeToUnix(now);

    createGUSIni;
    createGameIni;

    Memo_GameUserSettings.Lines.SaveToFile(Edit_Install_Location_Val.Text+'\ShooterGame\Saved\Config\WindowsServer\GameUserSettings.ini');
    Memo_GameIni.Lines.SaveToFile(Edit_Install_Location_Val.Text+'\ShooterGame\Saved\Config\WindowsServer\Game.ini');

    // override GameUserSettings.ini
    if (ChB_GUS_Override.Checked) then
    begin
      ini := TIniFile.Create(Edit_Install_Location_Val.Text+'\ShooterGame\Saved\Config\WindowsServer\GameUserSettings.ini');
      try
        sec := '';
        key := '';
        val := '';
        for i:= 0 to Memo_GameUserSettings_Override.Lines.Count-1 do
        begin
          line := trim(Memo_GameUserSettings_Override.Lines[i]);
          if (line='') then continue;

          if (pos('[',line) = 1) and (pos(']',line) > 2) then
          begin
            sec := StringReplace(StringReplace(line,']','',[ rfReplaceAll ]),'[','',[ rfReplaceAll ]);
          end else begin
            if (sec<>'') then
            begin
              key := Memo_GameUserSettings_Override.Lines.Names[i];
              val := Memo_GameUserSettings_Override.Lines.Values[key];
              ini.WriteString(sec,key,val);
            end;
          end;
        end;
      finally
        ini.Free;
      end;
    end;

    // append GameUserSettings.ini
    if (ChB_GUS_Append.Checked) then
    begin
      ini := TIniFile.Create(Edit_Install_Location_Val.Text+'\ShooterGame\Saved\Config\WindowsServer\GameUserSettings.ini');
      try
        sec := '';
        key := '';
        val := '';
        k := 0;
        for i:= 0 to Memo_GameUserSettings_Append.Lines.Count-1 do
        begin
          line := trim(Memo_GameUserSettings_Append.Lines[i]);
          if (line='') then continue;

          if (pos('[',line) = 1) and (pos(']',line) > 2) then
          begin
            sec := StringReplace(StringReplace(line,']','',[ rfReplaceAll ]),'[','',[ rfReplaceAll ]);
          end else begin
            if (sec<>'') then
            begin
              key := Memo_GameUserSettings_Append.Lines.Names[i];
              val := Memo_GameUserSettings_Append.Lines.ValueFromIndex[i];
              key := '___' + IntToStr(k) + '---' + key;
              k := k +1;
              ini.WriteString(sec,key,val);
            end;
          end;
        end;
      finally
        ini.Free;
      end;

      sl := TStringList.Create;
      try
        sl.LoadFromFile(Edit_Install_Location_Val.Text+'\ShooterGame\Saved\Config\WindowsServer\GameUserSettings.ini');
        for i := 0 to sl.Count -1 do
        begin
          val := sl.Strings[i];
          if (pos('___',val)=1) and (pos('---',val)>4) then
          begin
            val := copy(val,pos('---',val)+3,4096);
            sl.Strings[i] := val;
          end;
        end;
      finally
        sl.SaveToFile(Edit_Install_Location_Val.Text+'\ShooterGame\Saved\Config\WindowsServer\GameUserSettings.ini');
        sl.Free;
      end;
    end;

    // override Game.ini
    if (ChB_GS_Override.Checked) then
    begin
      ini := TIniFile.Create(Edit_Install_Location_Val.Text+'\ShooterGame\Saved\Config\WindowsServer\Game.ini');
      try
        sec := '';
        key := '';
        val := '';
        for i:= 0 to Memo_GameIni_Override.Lines.Count-1 do
        begin
          line := trim(Memo_GameIni_Override.Lines[i]);
          if (line='') then continue;

          if (pos('[',line) = 1) and (pos(']',line) > 2) then
          begin
            sec := StringReplace(StringReplace(line,']','',[ rfReplaceAll ]),'[','',[ rfReplaceAll ]);
          end else begin
            if (sec<>'') then
            begin
              key := Memo_GameIni_Override.Lines.Names[i];
              val := Memo_GameIni_Override.Lines.Values[key];
              ini.WriteString(sec,key,val);
            end;
          end;
        end;
      finally
        ini.Free;
      end;
    end;

    // append Game.ini
    if (ChB_GS_Append.Checked) then
    begin
      ini := TIniFile.Create(Edit_Install_Location_Val.Text+'\ShooterGame\Saved\Config\WindowsServer\Game.ini');
      try
        sec := '';
        key := '';
        val := '';
        k := 0;
        for i:= 0 to Memo_GameIni_Append.Lines.Count-1 do
        begin
          line := trim(Memo_GameIni_Append.Lines[i]);
          if (line='') then continue;

          if (pos('[',line) = 1) and (pos(']',line) > 2) then
          begin
            sec := StringReplace(StringReplace(line,']','',[ rfReplaceAll ]),'[','',[ rfReplaceAll ]);
          end else begin
            if (sec<>'') then
            begin
              key := Memo_GameIni_Append.Lines.Names[i];
              val := Memo_GameIni_Append.Lines.ValueFromIndex[i];
              key := '___' + IntToStr(k) + '---' + key;
              k := k +1;
              ini.WriteString(sec,key,val);
            end;
          end;
        end;
      finally
        ini.Free;
      end;

      sl := TStringList.Create;
      try
        sl.LoadFromFile(Edit_Install_Location_Val.Text+'\ShooterGame\Saved\Config\WindowsServer\Game.ini');
        for i := 0 to sl.Count -1 do
        begin
          val := sl.Strings[i];
          if (pos('___',val)=1) and (pos('---',val)>4) then
          begin
            val := copy(val,pos('---',val)+3,4096);
            sl.Strings[i] := val;
          end;
        end;
      finally
        sl.SaveToFile(Edit_Install_Location_Val.Text+'\ShooterGame\Saved\Config\WindowsServer\Game.ini');
        sl.Free;
      end;
    end;

    // Engine.ini
    if (ChB_UseEngineINI.Checked) then
    begin
      ini := TIniFile.Create(Edit_Install_Location_Val.Text+'\ShooterGame\Saved\Config\WindowsServer\Engine.ini');
      try
        ini.WriteFloat('/Script/OnlineSubsystemUtils.IpNetDriver','InitialConnectTimeout',FSE_InitialConnectTimeout.Value);
        ini.WriteFloat('/Script/OnlineSubsystemUtils.IpNetDriver','ConnectionTimeout',FSE_ConnectionTimeout.Value);
        ini.WriteInteger('OnlineSubsystemSteam','P2PConnectionTimeout',SE_P2PConnectionTimeout.Value);

        ini.WriteInteger('HTTP','HttpTimeout'          ,SE_HttpTimeout.Value);
        ini.WriteInteger('HTTP','HttpConnectionTimeout',SE_HttpConnectionTimeout.Value);
        ini.WriteInteger('HTTP','HttpReceiveTimeout'   ,SE_HttpReceiveTimeout.Value);
        ini.WriteInteger('HTTP','HttpSendTimeout'      ,SE_HttpSendTimeout.Value);
      finally
        ini.Free;
      end;
    end else begin
      ini := TIniFile.Create(Edit_Install_Location_Val.Text+'\ShooterGame\Saved\Config\WindowsServer\Engine.ini');
      try
        ini.DeleteKey('/Script/OnlineSubsystemUtils.IpNetDriver','InitialConnectTimeout');
        ini.DeleteKey('/Script/OnlineSubsystemUtils.IpNetDriver','ConnectionTimeout');
        ini.DeleteKey('OnlineSubsystemSteam','P2PConnectionTimeout');

        ini.DeleteKey('HTTP','HttpTimeout');
        ini.DeleteKey('HTTP','HttpConnectionTimeout');
        ini.DeleteKey('HTTP','HttpReceiveTimeout');
        ini.DeleteKey('HTTP','HttpSendTimeout');
      finally
        ini.Free;
      end;
    end;

    //StartAsaServer.bat
    sl := TStringList.Create;
    try
      sl.Clear;
      sl.Add('@echo off');
      sl.Add('REM This .bat file is auto created by ASA Server manager.');
      sl.Add('REM Created : ' + DateTimeToStr (Now));
      if ChB_CMD_override.Checked then
      begin
        sl.Add('start /b '+MM_Command_Override.Text);
      end else begin
        sl.Add('start /b '+MM_Command_Val.Text);
      end;
    finally
      sl.SaveToFile(Edit_Install_Location_Val.Text+'\ShooterGame\Binaries\Win64\StartAsaServer.bat');
      sl.Free;
    end;
    Lbl_Profile_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Profile_Status_04.Caption;
    Lbl_Profile_Status.Repaint;
    sLast_Profile_Status :=Form_MessageTrans.Lbl_Hidden_Profile_Status_04.Caption;
    iLast_Profile_Status_Time := DateTimeToUnix(now);
    Pnl_SetIni.Color:=clForm;
  end else begin
    if (CB_SrvStatus_Val.ItemIndex < 2) then
    begin
      Lbl_Profile_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Profile_Status_05.Caption;
      Lbl_Profile_Status.Repaint;
      sLast_Profile_Status :=Form_MessageTrans.Lbl_Hidden_Profile_Status_05.Caption;
      iLast_Profile_Status_Time := DateTimeToUnix(now);
    end;
    if (CB_SrvStatus_Val.ItemIndex > 3) then
    begin
      Lbl_Profile_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Profile_Status_06.Caption;
      Lbl_Profile_Status.Repaint;
      sLast_Profile_Status :=Form_MessageTrans.Lbl_Hidden_Profile_Status_06.Caption;
      iLast_Profile_Status_Time := DateTimeToUnix(now);
    end;
    //Pnl_SetIni.Color:=clForm;
  end;
end;

procedure TAsaFrame.CG_ActiveEventItemClick(Sender: TObject; Index: integer);
begin
  if (Index < -1) then exit;
  if (Sender = CG_ActiveEvent) then Mods_Change(Sender);
  ConditionCheck_Mods;
  if (Sender = CG_Mod5_MutatorModeBlacklist) then GUSChange(Sender);
end;

procedure TAsaFrame.createDinoGrid;
var
  sl  :TStringList;
  i,cnt  :integer;
  ini :TIniFile;
begin
  SL_SpawnList.BeginUpdate;
  SL_SpawnList2.BeginUpdate;
  SL_OverrideNamedEngramEntries.BeginUpdate;
  CB_ActiveEvent.BeginUpdateBounds;
  CG_ActiveEvent.BeginUpdateBounds;
  CB_ActiveEvent_mod.BeginUpdateBounds;
  sl := TStringList.Create;
  try
    //DinoGrid
    SL_SpawnList.RowCount:=sl_DinoList.Count+1;
    with SL_SpawnList.Columns[4] do
    begin
      PickList.Clear;
      for i:=0 to sl_DinoList.Count -1 do
      begin
        sl.CommaText:=sl_DinoList.Values[sl_DinoList.Names[i]];
        PickList.Add(sl.Strings[3]);
        SL_SpawnList.Rows[i+1].Text:=format('%s,%s,%s,%s,%s',[sl_DinoList.Names[i],sl.Strings[0],sl.Strings[1],sl.Strings[2],sl.Strings[3]]);
      end;
    end;
    //DinoGrid2
    SL_SpawnList2.Columns[0].PickList.Clear;
    SL_SpawnList2.Columns[4].PickList.Clear;
    for i:=0 to sl_DinoList.Count -1 do
    begin
      sl.CommaText:=sl_DinoList.Values[sl_DinoList.Names[i]];
      SL_SpawnList2.Columns[0].PickList.Add(sl_DinoList.Names[i]);
      SL_SpawnList2.Columns[1].PickList.Add(sl.Strings[3]);
      SL_SpawnList2.Columns[5].PickList.Add(sl.Strings[3]);
    end;

    // EngramGrid
    if FileExists(ExtractFilePath(ParamStr0)+'EngramData.txt') then
    begin
      SL_OverrideNamedEngramEntries.Columns[0].PickList.LoadFromFile(ExtractFilePath(ParamStr0)+'EngramData.txt');
      SL_OverrideNamedEngramEntries.Columns[1].PickList.Add('(Manually Input)');

      for i:=0 to SL_OverrideNamedEngramEntries.Columns[0].PickList.Count -1 do
      begin
        SL_OverrideNamedEngramEntries.Columns[1].PickList.Add(SL_OverrideNamedEngramEntries.Columns[0].PickList.Names[i]);
        sl.CommaText:= SL_OverrideNamedEngramEntries.Columns[0].PickList.Values[SL_OverrideNamedEngramEntries.Columns[0].PickList.Names[i]];
        SL_OverrideNamedEngramEntries.Columns[2].PickList.Add(sl.Strings[0]);
      end;
    end else begin
      GB_OverrideNamedEngramEntries.Enabled:=false;
    end;

    //Events
    ini := TIniFile.Create(ExtractFilePath(ParamStr0)+'List.txt');
    try
      cnt := ini.ReadInteger('Events','count',0);
      for i:= 1 to cnt do
      begin
        CB_ActiveEvent.Items.Add(ini.ReadString('Events','ev'+InttoStr(i),''));
        CG_ActiveEvent.Items.Add(ini.ReadString('Events','ev'+InttoStr(i),''));
        CB_ActiveEvent_mod.Items.Add(ini.ReadString('Events','mod'+InttoStr(i),''));
      end;
    finally
      ini.Free
    end;
  finally
    sl.Free;
  end;
  CB_ActiveEvent_mod.EndUpdateBounds;
  CG_ActiveEvent.EndUpdateBounds;
  CB_ActiveEvent.EndUpdateBounds;
  SL_OverrideNamedEngramEntries.EndUpdate(true);
  SL_SpawnList2.EndUpdate(true);
  SL_SpawnList.EndUpdate(true);
end;

procedure TAsaFrame.ChB_GUS_OverrideChange(Sender: TObject);
begin
  Memo_GameUserSettings_Override.ReadOnly:= not ChB_GUS_Override.Checked;
  Memo_GameIni_Override.ReadOnly         := not ChB_GS_Override.Checked;
  Memo_GameUserSettings_Append.ReadOnly  := not ChB_GUS_Append.Checked;
  Memo_GameIni_Append.ReadOnly           := not ChB_GS_Append.Checked;
  MM_Command_Override.ReadOnly           := not ChB_CMD_override.Checked;
end;

procedure TAsaFrame.FocusOffclForm(Sender: TObject);
begin
  TWinControl(Sender).Color:=clForm;
end;

procedure TAsaFrame.Edit_ProfileChange(Sender: TObject);
var
  mainTab : TTabSheet;
  mainPage: TPageControl;
begin
  if (beforeProfileName <> Edit_Profile.Text) then
  begin
    mainTab := TTabSheet(TAsaFrame(TPageControl(TTabSheet(Tedit(Sender).Parent).Parent).Parent).Parent);
    mainPage:= TPageControl(mainTab.Parent);
    if (mainPage.FindComponent(Edit_Profile.Text) = nil) then
    begin
      if IsValidIdent(Edit_Profile.Text) then
      begin
        beforeProfileName := Edit_Profile.Text;
        mainTab.Name      := Edit_Profile.Text;
        mainTab.Caption   := Edit_Profile.Text;
      end else begin
        showmessage('ProfileName[' + Edit_Profile.Text + '] is not a valid name.');
        Edit_Profile.Text := beforeProfileName;
      end;
    end else begin
      showmessage('ProfileName[' + Edit_Profile.Text + '] is duplicate.');
      Edit_Profile.Text := beforeProfileName;
    end;
  end;
end;

procedure TAsaFrame.Eg_Wood(Sender: TObject);
begin
  if (Sender = Button_Mod5_PropagatorFuelClass)        then Edit_Mod5_PropagatorFuelClass.Text       :='/Game/PrimalEarth/CoreBlueprints/Resources/PrimalItemResource_Wood.PrimalItemResource_Wood';
  if (Sender = Button_Mod5_PropagatorModCostItemClass) then Edit_Mod5_PropagatorModCostItemClass.Text:='/Game/PrimalEarth/CoreBlueprints/Resources/PrimalItemResource_Wood.PrimalItemResource_Wood';

  GUSChange(Sender);
end;

procedure TAsaFrame.FocusOff(Sender: TObject);
begin
  if not DarkMode then TWinControl(Sender).Color:=clDefault;
  ChkCmpInfo(Sender);
end;

procedure TAsaFrame.FocusOn(Sender: TObject);
begin
  if not DarkMode then TWinControl(Sender).Color:=TColor(FocusColor);
  SetCmpInfo(Sender);
end;

procedure TAsaFrame.Button_InstallClick(Sender: TObject);
var
  IsCacheUpdate:boolean;
  sCachepath :string;
  sMain_ACFFile :string;
  sCacheACFFile :string;
  Main_BuildID:string;
  CacheBuildID:string;
  sl :TStringList;
  i :integer;

  sPath_SteamChk :string;
  sCMD_Steam2    :string;
  sCMD_ASADL     :string;
  sCMD_ASADLPRM1 :string;
  sCMD_ASADLPRM2 :string;
  sCMD_ASADLPRM3 :string;
  sCMD_ASADLPRM4 :string;

  sExePath:string;
  str:string;
begin
  Main_BuildID := '';
  CacheBuildID := '';
  if BusyFlg then
  begin
    Lbl_Profile_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Import_Status_01.Caption;
    Lbl_Profile_Status.Repaint;
    sLast_Profile_Status :=Form_MessageTrans.Lbl_Hidden_Import_Status_01.Caption;
    iLast_Profile_Status_Time := DateTimeToUnix(now);

    exit;
  end;

  BusyFlg := true;

  IsCacheUpdate := CB_Install_ShareUpdate.Checked;
  if not FileExists('AsaServerManegerWin_asa_filecopy.bat') then IsCacheUpdate := false;

  Screen.Cursor:=crHourGlass;
  try
    if (CB_SrvStatus_Val.ItemIndex > 3) then
    begin
      Lbl_Profile_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Profile_Status_06.Caption;
      Lbl_Profile_Status.Repaint;
      sLast_Profile_Status :=Form_MessageTrans.Lbl_Hidden_Profile_Status_06.Caption;
      iLast_Profile_Status_Time := DateTimeToUnix(now);
      exit;
    end;
    Lbl_Profile_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Profile_Status_07.Caption;
    Lbl_Profile_Status.Repaint;
    sLast_Profile_Status :=Form_MessageTrans.Lbl_Hidden_Profile_Status_07.Caption;
    iLast_Profile_Status_Time := DateTimeToUnix(now);

    if DisableSteamcmdSharing then
    begin
      sPath_SteamChk := Edit_Install_Location_Val.Text+'\steamcmd\steamerrorreporter.exe';
      sCMD_Steam2 := Edit_Install_Location_Val.Text +'\steamcmd\steamcmd.exe +quit';
      if (DebugUpdate) and FileExists('AsaServerManegerWin_asa_dl2_debug.bat') then
      begin
        sCMD_ASADL:='AsaServerManegerWin_asa_dl2_debug.bat';
      end else begin
        sCMD_ASADL:='AsaServerManegerWin_asa_dl2.bat';
      end;
    end else begin
      sPath_SteamChk := ExtractFilePath(ParamStr0)+'steamcmd\steamerrorreporter.exe';
      sCMD_Steam2 := ExtractFileDir(ParamStr0) +'\steamcmd\steamcmd.exe +quit';
      if (DebugUpdate) and FileExists('AsaServerManegerWin_asa_dl_debug.bat') then
      begin
        sCMD_ASADL:='AsaServerManegerWin_asa_dl_debug.bat';
      end else begin
        sCMD_ASADL:='AsaServerManegerWin_asa_dl.bat';
      end;
    end;
    if (IsCacheUpdate) then
    begin
      sCMD_ASADLPRM1:=ExtractFilePath(ParamStr0)  + 'Profile\UpdateChache';
      sCMD_ASADLPRM2:=ExtractFilePath(ParamStr0)  + 'Profile\UpdateChache\ShooterGame\Saved\Config\WindowsServer';
      sCMD_ASADLPRM3:=ExtractFilePath(ParamStr0)  + 'Profile\UpdateChache\ShooterGame\Content\Movies';
      sCMD_ASADLPRM4:=Edit_Install_Location_Val.Text+'\';
    end else begin
      sCMD_ASADLPRM1:=Edit_Install_Location_Val.Text;
      sCMD_ASADLPRM2:=Edit_Install_Location_Val.Text + '\ShooterGame\Saved\Config\WindowsServer';
      sCMD_ASADLPRM3:=Edit_Install_Location_Val.Text + '\ShooterGame\Content\Movies';
      sCMD_ASADLPRM4:=Edit_Install_Location_Val.Text +'\';
    end;

    if (CB_Install_TryClean.Checked) then
    begin
      if IsCacheUpdate then
      begin
        DeleteFile(ExtractFileDir(ParamStr0)+'\Profile\UpdateChache\steamapps\appmanifest_2430930.acf');
      end else begin
        DeleteArkFile('steamapps','appmanifest_2430930.acf')
      end;
      if (StrongClean) then
      begin
        if IsCacheUpdate then
        begin
          DeleteFolder(ExtractFileDir(ParamStr0)+'\Profile\UpdateChache\steamapps');
        end else begin
          DeleteArkFolder('steamapps');
        end;
        DeleteArkFolder('Engine');
        DeleteArkFolder('ShooterGame\Binaries');
        DeleteArkFolder('ShooterGame\Content');
        DeleteArkFolder('ShooterGame\Plugins');
      end;
    end;
    if (CB_Install_Steamcmd.Checked) then
    begin
      if DisableSteamcmdSharing then
      begin
        DeleteArkFolder('steamcmd');
        DeleteFile('steamcmd.zip');
      end else begin
        DeleteFolder(ExtractFileDir(ParamStr0)+'\steamcmd');
        DeleteFile('steamcmd.zip');
      end;
    end;

    if not FileExists(sPath_SteamChk) then
    begin
      if FileExists('steamcmd.zip') then
      begin
        try
          CheckZip('steamcmd.zip',ExtractFileDir(ParamStr0)+'\steamcmd');
        Except
          on E : Exception do DeleteFile('steamcmd.zip');
        end;
      end;
      if not FileExists('steamcmd.zip') then
      begin
        HttpGetFile('https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip','steamcmd.zip');
      end;
      if DisableSteamcmdSharing then
      begin
        UnZip('steamcmd.zip',ARKFolder('steamcmd'));
      end else begin
        UnZip('steamcmd.zip',ExtractFileDir(ParamStr0)+'\steamcmd');
      end;

      AsyncProcess.CommandLine:=sCMD_Steam2;
      AsyncProcess.Execute;
      WaitProcess(AsyncProcess);

      AsyncProcess.CommandLine:='';
    end;
    SetCurrentDir(ExtractFileDir(ParamStr0));
    updateServerStatus;

    if Edit_Install_Location_Val.Text<>'' then;
    begin
      CreateDir(Edit_Install_Location_Val.Text);
      begin
        AsyncProcess.Executable:= sCMD_ASADL;

        AsyncProcess.Parameters.Clear;
        AsyncProcess.Parameters.Add(sCMD_ASADLPRM1);
        AsyncProcess.Parameters.Add(sCMD_ASADLPRM2);
        AsyncProcess.Parameters.Add(sCMD_ASADLPRM3);
        AsyncProcess.Parameters.Add(sCMD_ASADLPRM4);
        AsyncProcess.Execute;
        WaitProcess(AsyncProcess);
      end;

      if (IsCacheUpdate) then
      begin
        sCachepath := ExtractFilePath(ParamStr0) + 'Profile\UpdateChache';
        sMain_ACFFile :=Edit_Install_Location_Val.Text + '\steamapps\appmanifest_2430930.acf';
        sCacheACFFile :=sCachepath                     + '\steamapps\appmanifest_2430930.acf';

        if FileExists(sMain_ACFFile) and FileExists(sCacheACFFile) then
        begin
          sl := TStringList.Create;
          try
            sl.LoadFromFile(sMain_ACFFile);
            for i := 0 to sl.Count -1 do
            begin
              if (Pos('"buildid"',sl.Strings[i])<>0) then
              begin
                Main_BuildID := sl.Strings[i];
                break;
              end;
            end;
          finally
            sl.Free;
          end;
          sl := TStringList.Create;
          try
            sl.LoadFromFile(sCacheACFFile);
            for i := 0 to sl.Count -1 do
            begin
              if (Pos('"buildid"',sl.Strings[i])<>0) then
              begin
                CacheBuildID := sl.Strings[i];
                break;
              end;
            end;
          finally
            sl.Free;
          end;
          if (Main_BuildID<>CacheBuildID) then
          begin
            AsyncProcess.Executable:='AsaServerManegerWin_asa_filecopy.bat';
            AsyncProcess.Parameters.Clear;
            AsyncProcess.Parameters.Add(Edit_Install_Location_Val.Text);      //dest
            AsyncProcess.Parameters.Add(sCachepath);                          //src
            AsyncProcess.Execute;
            WaitProcess(AsyncProcess);
          end;
        end else begin
          AsyncProcess.Executable:='AsaServerManegerWin_asa_filecopy.bat';
          AsyncProcess.Parameters.Clear;
          AsyncProcess.Parameters.Add(Edit_Install_Location_Val.Text);      //dest
          AsyncProcess.Parameters.Add(sCachepath);                          //src
          AsyncProcess.Execute;
          WaitProcess(AsyncProcess);
        end;
        DeleteArkFile('ShooterGame\Content\Paks','ShooterGame-WindowsServer.pak');
        DeleteArkFile('ShooterGame\Content\Paks','ShooterGame-WindowsServer.ucas');
        DeleteArkFile('ShooterGame\Content\Paks','ShooterGame-WindowsServer.utoc');
      end;

      CB_Install_TryClean.Checked := false;
      CB_Install_Steamcmd.Checked := false;
      CB_Install_ShareUpdate.Checked := EnableShareUpdate;
      begin
        sExePath := Edit_Install_Location_Val.Text + '\ShooterGame\Binaries\Win64\ArkAscendedServer.exe';
        str := MaybeGetInstVer(sExePath);

        if (str <> '') then
        begin
          Lbl_InstVer_Val.Caption:=format(Form_MessageTrans.Lbl_Hidden_SvrSTS_ADD2.Caption,[ArkVer,str]);
        end else begin
          Lbl_InstVer_Val.Caption:= ArkVer + Form_MessageTrans.Lbl_Hidden_SvrSTS_ADD.Caption;
        end;
      end;
    end;
    Lbl_Profile_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Profile_Status_08.Caption;
    Lbl_Profile_Status.Repaint;
    sLast_Profile_Status :=Form_MessageTrans.Lbl_Hidden_Profile_Status_08.Caption;
    iLast_Profile_Status_Time := DateTimeToUnix(now);
    updateServerStatus;
  finally
    Screen.Cursor:=crDefault;
    BusyFlg := false;
  end;
end;

procedure TAsaFrame.Button_AltSaveDirectoryNameClick(Sender: TObject);
begin
  SelectDirectoryDialog_Location.InitialDir := Edit_AltSaveDirectoryName.Text + '\';
  SelectDirectoryDialog_Location.FileName   := Edit_AltSaveDirectoryName.Text;
  if SelectDirectoryDialog_Location.Execute then
  begin
    Edit_AltSaveDirectoryName.Text:=SelectDirectoryDialog_Location.FileName;
    argsChange(Sender);
  end;
end;

procedure TAsaFrame.argsChange(Sender: TObject);
begin
  if canEditIni then createArgs;
  if canEditIni then ChkCmpInfo(Sender);
end;

procedure TAsaFrame.GameIniChangeWithFocusOff(Sender: TObject);
begin
  TWinControl(Sender).Color:=clDefault;
  if canEditIni then ChkCmpInfo(Sender);
  GameIniChange(Sender);
end;

procedure TAsaFrame.Button_Engrams_AddRowClick(Sender: TObject);
begin
  if (Sender = Button_Engrams_AddRow) then
  begin
    SL_OverrideNamedEngramEntries.RowCount := SL_OverrideNamedEngramEntries.RowCount +1;
    SL_OverrideNamedEngramEntries.Cells[3,SL_OverrideNamedEngramEntries.RowCount-1] := '0';
    SL_OverrideNamedEngramEntries.Cells[6,SL_OverrideNamedEngramEntries.RowCount-1] := '0';
  end;

  if (Sender = Button_ItemMaxQuantity_AddRow) then
  begin
    SL_Button_ItemMaxQuantity_AddRow.RowCount := SL_Button_ItemMaxQuantity_AddRow.RowCount +1;
    SL_Button_ItemMaxQuantity_AddRow.Cells[3,SL_Button_ItemMaxQuantity_AddRow.RowCount-1] := '0';
  end;
end;

procedure TAsaFrame.Button_ClusterDirOverrideClick(Sender: TObject);
begin
  SelectDirectoryDialog_Location.InitialDir := Edit_ClusterDirOverride.Text + '\';
  SelectDirectoryDialog_Location.FileName   := Edit_ClusterDirOverride.Text;
  if SelectDirectoryDialog_Location.Execute then
  begin
    Edit_ClusterDirOverride.Text:=SelectDirectoryDialog_Location.FileName;
    argsChange(Sender);
  end;
end;

procedure TAsaFrame.Button_Cosmetic_LocalFileClick(Sender: TObject);
begin
  SelectDirectoryDialog_Location.InitialDir := Edit_Cosmetic_LocalFile.Text + '\';
  SelectDirectoryDialog_Location.FileName   := Edit_Cosmetic_LocalFile.Text;
  if SelectDirectoryDialog_Location.Execute then
  begin
    Edit_Cosmetic_LocalFile.Text:=SelectDirectoryDialog_Location.FileName;
    GUSChange(Sender);
  end;
end;

procedure TAsaFrame.Button_DataBK2Click(Sender: TObject);
begin
  if BusyFlg then
  begin
    Lbl_Profile_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Import_Status_13.Caption;
    Lbl_Profile_Status.Repaint;
    sLast_Profile_Status :=Form_MessageTrans.Lbl_Hidden_Import_Status_13.Caption;
    iLast_Profile_Status_Time := DateTimeToUnix(now);

    exit;
  end;

  try
    if (Edit_Export.Text='') then Edit_Export.Text := ExtractFileDir(ParamStr0)+'\Profile\Backup';
    Screen.Cursor:=crHourGlass;
    Button_ExportClick(Sender);
  finally
    Lbl_Profile_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Profile_Status_14.Caption;
    Lbl_Profile_Status.Repaint;
    sLast_Profile_Status :=Form_MessageTrans.Lbl_Hidden_Profile_Status_14.Caption;
    iLast_Profile_Status_Time := DateTimeToUnix(now);
    Screen.Cursor:=crDefault;
  end;
end;

procedure TAsaFrame.Button_AllModInArgsClick(Sender: TObject);
var
  mainwin :TWinControl;
begin
  mainwin := Button_AllModInArgs.Parent.Parent.Parent.Parent.Parent.Parent;

  sortui.beforeMods:=Edit_AllModInArgs.Text;
  sortui.Top :=mainwin.Top;
  sortui.Left:=mainwin.Left;
  sortui.OldModList:=OldModList;
  sortui.ShowModal;

  if (Edit_AllModInArgs.Text<>sortui.afterMods) then Edit_AllModInArgs.Text:=sortui.afterMods;
end;

procedure TAsaFrame.Button_SvrCMD_DelayedRestartClick(Sender: TObject);
begin
  SendCmdOtherWindow(iProsessId,'DelayedRestart 300');
end;

procedure TAsaFrame.Button_SvrCMD_CommandClick(Sender: TObject);
var
  sCMD:string;
  i:integer;
begin
  if BusyFlg then
  begin
    Lbl_Profile_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Import_Status_01.Caption;
    Lbl_Profile_Status.Repaint;
    sLast_Profile_Status :=Form_MessageTrans.Lbl_Hidden_Import_Status_01.Caption;
    iLast_Profile_Status_Time := DateTimeToUnix(now);

    exit;
  end;

  BusyFlg := true;

  try
    if (CB_SrvStatus_Val.ItemIndex = 5) and (CB_SvrCMDEnabled.Checked) then
    begin
      sCMD := '';
      if (Sender = Button_SvrCMD_DelayedRestart) and (SE_DelayedRestartSec.Value > 0) then
      begin
        sCMD := format('DelayedRestart %d',[SE_DelayedRestartSec.Value]);
      end;
      if (Sender = Button_SvrCMD_AdminBroadcast) and (CB_SvrCMD_BroadcastHist.Text <> '') then
      begin
        sCMD := format('AdminBroadcast %s',[CB_SvrCMD_BroadcastHist.Text]);

        // command History
        begin
          CB_SvrCMD_BroadcastHist.Items.Insert(0,CB_SvrCMD_BroadcastHist.Text);
          for i := CB_SvrCMD_BroadcastHist.Items.Count-1 DownTo 1 do
          begin
            if (CB_SvrCMD_BroadcastHist.Items.Strings[i] = CB_SvrCMD_BroadcastHist.Text) then CB_SvrCMD_BroadcastHist.Items.Delete(i);
          end;

          for i := CB_SvrCMD_BroadcastHist.Items.Count-1 DownTo 10 do
          begin
            CB_SvrCMD_BroadcastHist.Items.Delete(i);
          end;
          CB_SvrCMD_BroadcastHist.Text := '';
        end;
      end;
      if (Sender = Button_SvrCMD_Command) then
      begin
        sCMD := CB_SvrCMD_Command.Text;

        // command History
        begin
          CB_SvrCMD_Command.Items.Insert(0,CB_SvrCMD_Command.Text);
          for i := CB_SvrCMD_Command.Items.Count-1 DownTo 1 do
          begin
            if (CB_SvrCMD_Command.Items.Strings[i] = CB_SvrCMD_Command.Text) then CB_SvrCMD_Command.Items.Delete(i);
          end;

          for i := CB_SvrCMD_Command.Items.Count-1 DownTo 10 do
          begin
            CB_SvrCMD_Command.Items.Delete(i);
          end;
          CB_SvrCMD_Command.Text := '';
        end;
      end;

      if (sCMD <> '') then
      begin
        Memo_SrvCMDLogs.Lines.Add(format('[ServerCommand]:%s',[sCMD]));

        SendCmdOtherWindow(iProsessId,sCMD);
      end;

    end;
  finally
    sleep(100);
    SetForeGroundWindow(Self.Handle);
    BusyFlg := false;
  end;
end;

procedure TAsaFrame.Btn_InstVerClick(Sender: TObject);
var
  sExePath:string;
  str:string;
begin
  sExePath := Edit_Install_Location_Val.Text + '\ShooterGame\Binaries\Win64\ArkAscendedServer.exe';

  str := MaybeGetInstVer(sExePath);
  if (str <> '') then
  begin
    Lbl_InstVer_Val.Caption:=format('maybe %s',[str]);
  end;
end;

procedure TAsaFrame.Button_Engrams_DelRowClick(Sender: TObject);
var
  iRow : integer;
begin
  if (Sender = Button_Engrams_DelRow) then
  begin
    iRow := SL_OverrideNamedEngramEntries.Row;
    if (iRow <>0) then SL_OverrideNamedEngramEntries.DeleteRow(iRow);
  end;

  if (Sender = Button_ItemMaxQuantity_DelRow) then
  begin
    iRow := SL_Button_ItemMaxQuantity_AddRow.Row;
    if (iRow <>0) then SL_Button_ItemMaxQuantity_AddRow.DeleteRow(iRow);
  end;

  GameIniChange(Sender);
end;

procedure TAsaFrame.Button_ExportClick(Sender: TObject);
var
  src:string;
  dst:string;
  szip:string;
  slDir :TStringList;
  slFile:TStringList;
  i,j :integer;
  sMap :string;
  sDir :string;
  sFile:string;
begin
  if BusyFlg then
  begin
    Lbl_Export_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Import_Status_01.Caption;
    Lbl_Export_Status.Repaint;
    exit;
  end;

  BusyFlg := true;
  try
    GB_Ini_Import.Enabled:=false;
    GB_Data_Export.Enabled:=false;
    GB_Data_Import.Enabled:=false;
    PBar_Export.Position:=0;
    PBar_Export.Visible:=true;

    if (CB_SrvStatus_Val.ItemIndex>3) then
    begin
      Lbl_Export_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Import_Status_02.Caption;
      Lbl_Export_Status.Repaint;
      exit;
    end;
    if (Edit_Export.Text = '') then
    begin
      Lbl_Export_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Export_Status_01.Caption;
      Lbl_Export_Status.Repaint;
      exit;
    end;

    Lbl_Export_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Import_Status_15.Caption;
    Lbl_Export_Status.Repaint;
    src := Edit_Install_Location_Val.Text+'\ShooterGame\Saved';
    dst := Edit_Export.Text + '\Saved';

    // (path)\(Profilenamme)_YYYYMMDD_hhmmss.ASASM.zip
    szip := format('%s\%s_%s.ASASM.zip',[Edit_Export.Text,Edit_Profile.Text,FormatDateTime('YYYYMMDD_hhnnss',Now)]);

    DeleteFolder(dst);
    fileutil.CopyDirTree(src,dst,[cffOverwriteFile,cffCreateDestDirectory,cffPreserveTime]);

    Lbl_Export_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Export_Status_02.Caption;
    Lbl_Export_Status.Repaint;
    flg_backup := true;
    saveProfile;
    flg_backup := false;

    if ChB_CleanBackup.Checked then
    begin
      slDir := FindAllDirectories(dst+'\SavedArks',false);
      try
        for i := 0 to slDir.Count -1 do
        begin
          sDir := slDir.Strings[i];
          sMap := ExtractFileName(sDir);
          if (Pos(' ',sMap)<>0) then continue;
          slFile := FindAllFiles(sDir,'*.ark',false);
          try
            for j := 0 to slFile.Count -1 do
            begin
              sFile := ExtractFileName(slFile.Strings[j]);

              if (sFile = (sMap + '.ark')) then continue;
              if (sFile = (sMap + '_WP.ark')) then continue;
              if (Pos('AntiCorruptionBackup',sFile)<>0) then continue;
              if (Pos('.20',sFile)=0) then continue;
              DeleteFile(slFile.Strings[j]);
            end;
          finally
            slFile.Free;
          end;
        end;
      finally
        slDir.Free;
      end;
    end;

    Lbl_Export_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Export_Status_03.Caption;
    Lbl_Export_Status.Repaint;
    //ZipDirectory(dst+'\',szip);
    ZipDirectory(dst+'\',szip,PBar_Export);

    DeleteFolder(dst);
    Lbl_Export_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Export_Status_04.Caption+szip;
    Lbl_Export_Status.Repaint;
  finally
    GB_Ini_Import.Enabled:=true;
    GB_Data_Export.Enabled:=true;
    GB_Data_Import.Enabled:=true;
    PBar_Export.Visible:=false;

    BusyFlg := false;
    Application.ProcessMessages;
  end;
end;

procedure TAsaFrame.Button_ImportClick(Sender: TObject);
var
  ans :TModalResult;
  szip:string;
  src:string;
  dst:string;
begin
  if BusyFlg then
  begin
    Lbl_Import_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Import_Status_01.Caption;
    Lbl_Import_Status.Repaint;
    exit;
  end;

  BusyFlg := true;
  try
    GB_Ini_Import.Enabled:=false;
    GB_Data_Export.Enabled:=false;
    GB_Data_Import.Enabled:=false;

    if (CB_SrvStatus_Val.ItemIndex>3) then
    begin
      Lbl_Import_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Import_Status_02.Caption;
      Lbl_Import_Status.Repaint;
      exit;
    end;
    if (Edit_Import.Text = '') then
    begin
      Lbl_Import_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Import_Status_03.Caption;
      Lbl_Import_Status.Repaint;
      exit;
    end;
    if (not ChB_SelectData_World.Checked) and (not ChB_SelectData_Profile.Checked) and (not ChB_SelectData_Logs.Checked) then
    begin
      Lbl_Import_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Import_Status_04.Caption;
      Lbl_Import_Status.Repaint;
      exit;
    end;

    ans := MessageDlg(Form_MessageTrans.Lbl_Hidden_Warning.Caption,Form_MessageTrans.Lbl_Hidden_Import_Status_05.Caption,mtConfirmation,[mbYes, mbNo],0);
    if ans<>mrYes then
    begin
      Lbl_Import_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Import_Status_06.Caption;
      Lbl_Import_Status.Repaint;
      exit;
    end;

    Lbl_Import_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Import_Status_07.Caption;
    Lbl_Import_Status.Repaint;
    szip := Edit_Import.Text;
    src  := ExtractFileDir(szip);
    if (not FileExists(szip)) then
    begin
      Lbl_Import_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Import_Status_08.Caption;
      Lbl_Import_Status.Repaint;
      exit;
    end;
    DeleteFolder(src+'\Saved');
    UnZip(szip,src);

    //check file
    Lbl_Import_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Import_Status_09.Caption;
    Lbl_Import_Status.Repaint;
    dst := Edit_Install_Location_Val.Text+'\ShooterGame\Saved';
    if (ChB_SelectData_World.Checked) then
    begin
      if not DirectoryExists(src+'\Saved\SavedArks') then
      begin
        Lbl_Import_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Import_Status_10.Caption;
        Lbl_Import_Status.Repaint;
        exit;
      end;
    end;
    if (ChB_SelectData_Logs.Checked) then
    begin
      //
    end;
    if (ChB_SelectData_Profile.Checked) then
    begin
      if not DirectoryExists(src+'\Saved\Config') then
      begin
        Lbl_Import_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Import_Status_11.Caption;
        Lbl_Import_Status.Repaint;
        exit;
      end;
      if not FileExists(src+'\Saved\Config\WindowsServer\Game.ini') then
      begin
        Lbl_Import_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Import_Status_12.Caption;
        Lbl_Import_Status.Repaint;
        exit;
      end;
      if not FileExists(src+'\Saved\Config\WindowsServer\GameUserSettings.ini') then
      begin
        Lbl_Import_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Import_Status_13.Caption;
        Lbl_Import_Status.Repaint;
        exit;
      end;
      if not FileExists(src+'\Saved\Profile.ini') then
      begin
        Lbl_Import_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Import_Status_14.Caption;
        Lbl_Import_Status.Repaint;
        exit;
      end;
    end;

    // restore
    dst := Edit_Install_Location_Val.Text+'\ShooterGame\Saved';
    if (ChB_SelectData_World.Checked) then
    begin
      Lbl_Import_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Import_Status_15.Caption;
      Lbl_Import_Status.Repaint;

      if DirectoryExists(src+'\Saved\SavedArks') then fileutil.CopyDirTree(src+'\Saved\SavedArks',dst+'\SavedArks',[cffOverwriteFile,cffCreateDestDirectory,cffPreserveTime]);
      if DirectoryExists(src+'\Saved\SaveGames') then fileutil.CopyDirTree(src+'\Saved\SaveGames',dst+'\SaveGames',[cffOverwriteFile,cffCreateDestDirectory,cffPreserveTime]);
    end;
    if (ChB_SelectData_Logs.Checked) then
    begin
      Lbl_Import_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Import_Status_16.Caption;
      Lbl_Import_Status.Repaint;

      if DirectoryExists(src+'\Saved\Crashes') then fileutil.CopyDirTree(src+'\Saved\Crashes',dst+'\Crashes',[cffOverwriteFile,cffCreateDestDirectory,cffPreserveTime]);
      if DirectoryExists(src+'\Saved\Logs')    then fileutil.CopyDirTree(src+'\Saved\Logs',   dst+'\Logs',   [cffOverwriteFile,cffCreateDestDirectory,cffPreserveTime]);
    end;
    if (ChB_SelectData_Profile.Checked) then
    begin
      Lbl_Import_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Import_Status_17.Caption;
      Lbl_Import_Status.Repaint;

      if DirectoryExists(src+'\Saved\Config') then fileutil.CopyDirTree(src+'\Saved\Config'     ,dst+'\Config'     ,[cffOverwriteFile,cffCreateDestDirectory,cffPreserveTime]);
      if FileExists(src+'\Saved\Profile.ini') then fileutil.CopyFile   (src+'\Saved\Profile.ini',dst+'\Profile.ini',[cffOverwriteFile,cffCreateDestDirectory,cffPreserveTime],false);

      flg_backup := true;
      canEditIni := false;
      loadProfile('Profile');
      flg_backup := false;
      canEditIni := true;
      createArgs;
      createGUSIni;
      createGameIni;
    end;

    Lbl_Import_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Import_Status_18.Caption+szip;
    Lbl_Import_Status.Repaint;
  finally
    GB_Ini_Import.Enabled:=true;
    GB_Data_Export.Enabled:=true;
    GB_Data_Import.Enabled:=true;

    BusyFlg := false;
  end;
end;

procedure TAsaFrame.Button_Import_FileClick(Sender: TObject);
begin
 if (Edit_Import.Text = '') then OpenDialog_ImportFile.InitialDir:=Edit_Export.Text
                            else OpenDialog_ImportFile.InitialDir:=ExtractFilePath(Edit_Import.Text);

 if OpenDialog_ImportFile.Execute then
 begin
   Edit_Import.Text:=OpenDialog_ImportFile.FileName;
 end;

end;

procedure TAsaFrame.Button_Ini_ImportClick(Sender: TObject);
var
  ans :TModalResult;
  GameIniPath,
  GUSIniPath :string;
begin
  if (Edit_Ini_Import.Text = '') then
  begin
    Lbl_Ini_Import_Status.Caption:=Form_MessageTrans.Lbl_Hidden_INI_Import_Status_01.Caption;
    Lbl_Ini_Import_Status.Repaint;
    exit;
  end;

  GameIniPath := Edit_Ini_Import.Text + '\Game.ini';
  GUSIniPath  := Edit_Ini_Import.Text + '\GameUserSettings.ini';
  if (not FileExists(GameIniPath))and(not FileExists(GUSIniPath)) then
  begin
    Lbl_Ini_Import_Status.Caption:=Form_MessageTrans.Lbl_Hidden_INI_Import_Status_02.Caption;
    Lbl_Ini_Import_Status.Repaint;
    exit;
  end;

  ans := MessageDlg(Form_MessageTrans.Lbl_Hidden_Warning.Caption,Form_MessageTrans.Lbl_Hidden_INI_Import_Status_03.Caption,mtConfirmation,[mbYes, mbNo],0);
  if ans=mrYes then
  begin
    loadProfileFromIni(Edit_Profile.Text,Edit_Ini_Import.Text);
    Lbl_Ini_Import_Status.Caption:=Form_MessageTrans.Lbl_Hidden_INI_Import_Status_04.Caption;
    Lbl_Ini_Import_Status.Repaint;
  end else begin
    Lbl_Ini_Import_Status.Caption:=Form_MessageTrans.Lbl_Hidden_INI_Import_Status_05.Caption;
    Lbl_Ini_Import_Status.Repaint;
  end;
end;

procedure TAsaFrame.Button_Ini_Import_DirClick(Sender: TObject);
begin
  if (sender = Button_Ini_Import_Dir) then SelectDirectoryDialog_Location.InitialDir:=Edit_Ini_Import.Text + '\';
  if (sender = Button_Ini_Import_Dir) then SelectDirectoryDialog_Location.FileName  :=Edit_Ini_Import.Text;
  if (sender = Button_Export_Dir    ) then SelectDirectoryDialog_Location.InitialDir:=Edit_Export.Text + '\';
  if (sender = Button_Export_Dir    ) then SelectDirectoryDialog_Location.FileName  :=Edit_Export.Text;

  if SelectDirectoryDialog_Location.Execute then
  begin
    if (sender = Button_Ini_Import_Dir) then Edit_Ini_Import.Text:=SelectDirectoryDialog_Location.FileName;
    if (sender = Button_Export_Dir    ) then Edit_Export.Text    :=SelectDirectoryDialog_Location.FileName;
  end;
end;

procedure TAsaFrame.Button_RCON_ClearClick(Sender: TObject);
begin
  if (Sender = CB_RCON_Command  ) then CB_RCON_Command.Text:='';
  if (Sender = CB_SvrCMD_Command) then CB_SvrCMD_Command.Text:='';

end;

procedure TAsaFrame.Button_ServerPassword_RandomClick(Sender: TObject);
var
  sPW:string;
  i  :Integer;
  cd :Byte;
begin
  sPW := '';

  Randomize;
  for i := 0 to 15 do
  begin
    cd := Random(62);
    if (cd <= 9)               then sPW := sPW + Char(cd + 48);
    if (cd >=10) and (cd <=35) then sPW := sPW + Char(cd + 55);
    if (cd >=36)               then sPW := sPW + Char(cd + 61);
  end;

  if (Sender = Button_ServerPassword_Random)        then Edit_ServerPassword     .Text:=sPW;
  if (Sender = Button_ServerAdminPassword_Generate) then Edit_ServerAdminPassword.Text:=sPW;

  if (Sender = Button_ServerPassword_Random)        then GusChange(Edit_ServerPassword);
  if (Sender = Button_ServerAdminPassword_Generate) then GusChange(Edit_ServerAdminPassword);
end;

procedure TAsaFrame.Button_SpawnList_AddClick(Sender: TObject);
begin
  SL_SpawnList2.RowCount:=SL_SpawnList2.RowCount+1;
  SL_SpawnList2.Cells[2,SL_SpawnList2.RowCount-1]:='0';
  SL_SpawnList2.Cells[3,SL_SpawnList2.RowCount-1]:='0';
  SL_SpawnList2.Cells[4,SL_SpawnList2.RowCount-1]:='0';
end;

procedure TAsaFrame.Button_SpawnList_DelClick(Sender: TObject);
begin
  if (SL_SpawnList2.Row > 0) then
  begin
    SL_SpawnList2.DeleteRow(SL_SpawnList2.Row);
  end;
end;

procedure TAsaFrame.CB_Change(Sender: TObject);
begin
  ArgsChange(Sender);
  if (canEditIni) and (Sender.ClassName = 'TComboBox') then
  begin
    BeforeData.Name:=TComboBox(Sender).Name;
    BeforeData.Str:='';
    ChkCmpInfo(Sender);
  end;
end;

procedure TAsaFrame.CB_RCON_CommandKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_RETURN) and (Shift = []) then
  begin
    if (Sender = CB_RCON_Command  ) then RCON_COMAND_Click(Button_RCON_Command);
    if (Sender = CB_SvrCMD_Command) then Button_SvrCMD_CommandClick(Button_SvrCMD_Command);
  end;

end;

procedure TAsaFrame.CB_RCON_Command_ListChange(Sender: TObject);
begin
  if (Sender = CB_RCON_Command_List) then
  begin
    if CB_RCON_Command_List.ItemIndex > 0 then
    begin
      CB_RCON_Command.Text:=CB_RCON_Command_List.Text;
      CB_RCON_Command_List.ItemIndex := 0;
      CB_RCON_Command.SetFocus;
    end;
  end;
  if (Sender = CB_SvrCMD_Command_List) then
  begin
    if CB_SvrCMD_Command_List.ItemIndex > 0 then
    begin
      CB_SvrCMD_Command.Text:=CB_SvrCMD_Command_List.Text;
      CB_SvrCMD_Command.ItemIndex := 0;
      CB_SvrCMD_Command.SetFocus;
    end;
  end;
end;

procedure TAsaFrame.CB_SrvStatus_ValChange(Sender: TObject);
begin
  if (CB_SrvStatus_Val.ItemIndex = 0) then Lbl_SrvStatus_Val.Caption := '× No SteamCMD';
  if (CB_SrvStatus_Val.ItemIndex = 1) then Lbl_SrvStatus_Val.Caption := '× No ServerPRG';
  if (CB_SrvStatus_Val.ItemIndex = 2) then Lbl_SrvStatus_Val.Caption := '× No Config';
  if (CB_SrvStatus_Val.ItemIndex = 3) then Lbl_SrvStatus_Val.Caption := '● OFFLINE';
  if (CB_SrvStatus_Val.ItemIndex = 4) then Lbl_SrvStatus_Val.Caption := '● Server Starting...';
  if (CB_SrvStatus_Val.ItemIndex = 5) then Lbl_SrvStatus_Val.Caption := '● ONLINE';

                                           Lbl_SrvStatus_Val.Font.Color:=clBlack;
  if (CB_SrvStatus_Val.ItemIndex = 3) then Lbl_SrvStatus_Val.Font.Color:=clRed;
  if (CB_SrvStatus_Val.ItemIndex = 4) then Lbl_SrvStatus_Val.Font.Color:=TColor($0099FF);
  if (CB_SrvStatus_Val.ItemIndex = 5) then Lbl_SrvStatus_Val.Font.Color:=clGreen;

end;

procedure TAsaFrame.CGRG_Enter(Sender: TObject);
begin
  SetCmpInfo(Sender);
end;

procedure TAsaFrame.ChB_bAllowFlyerDinoSubmergingChange(Sender: TObject);
begin
  GUSChange(Sender);
  GameIniChange(Sender);
end;

procedure TAsaFrame.Edit_ActiveMapMod_ValEditingDone(Sender: TObject);
begin
  ConditionCheck_Mods;
end;

procedure TAsaFrame.Edit_AllModInArgsChange(Sender: TObject);
var
  before,
  after  :string;
begin
  if canEditIni then
  begin
    before := Edit_AllModInArgs.Text;
    after  := '';
    if (Edit_AutoAddedModInArgs.Text<>'') then
    begin
      after := Edit_AutoAddedModInArgs.Text;
      if (Edit_Mods.Text <> '') then after := after + ',';
    end;

    if (Edit_Mods.Text <> '') then
    begin
      after := after + Edit_Mods.Text;
    end;

    if (before<>after) then
    begin
      Edit_AllModInArgs.Text := after;
      argsChange(Sender);
    end;
  end;
end;

procedure TAsaFrame.Edit_ModsEditingDone(Sender: TObject);
begin
  if (beforeMods = Edit_Mods.Text) then exit;
  ConditionCheck_Mods;
  Edit_AllModInArgsChange(Sender);
  beforeMods := Edit_Mods.Text;
end;

procedure TAsaFrame.Edit_ModsEnter(Sender: TObject);
begin
  TWinControl(Sender).Color:=TColor(FocusColor);
  beforeMods := Edit_Mods.Text;
end;

procedure TAsaFrame.Edit_ModsExit(Sender: TObject);
begin
  TWinControl(Sender).Color:=clDefault;
  Edit_ModsEditingDone(Sender);
end;

procedure TAsaFrame.Edit_passivemodsEditingDone(Sender: TObject);
begin
  ConditionCheck_Mods;
end;

procedure TAsaFrame.FrameDblClick(Sender: TObject);
begin
  Screen.Cursor:=crHourGlass;
  FlgHiddenTabs := not FlgHiddenTabs;
  HideTabs;
  Screen.Cursor:=crDefault;
end;

procedure TAsaFrame.argsChangeWithFocusOff(Sender: TObject);
begin
  TWinControl(Sender).Color:=clDefault;
  argsChange(Sender);
end;

procedure TAsaFrame.argsGUSChange(Sender: TObject);
begin
  argsChange(Sender);
  GUSChange(Sender);
end;

procedure TAsaFrame.argsGUSChangeWithFocusOff(Sender: TObject);
begin
  TWinControl(Sender).Color:=clDefault;
  argsGUSChange(Sender);
end;

procedure TAsaFrame.AsyncProcess_ListPlayerTerminate(Sender: TObject);
var
  sl  : TStringList;
  i :integer;
begin
  sl := TStringList.Create;
  try
    if (AsyncProcess_ListPlayer.Output.NumBytesAvailable=0) then exit;

    sl.LoadFromStream(AsyncProcess_ListPlayer.Output);
    AsyncProcess_ListPlayer.CloseOutput;

    // ListPlayers
    if (RCONSender = Button_ListPlayers) then
    begin
      StringGrid_PlayerList.BeginUpdate;
      sl.Text := StringReplace(sl.Text,#13#10+' '+#13#10,#13#10,[rfReplaceAll]);
      if (sl.Count>0) and (sl.Strings[0]='') then sl.delete(0);
      if sl.Count=0 then
      begin
        StringGrid_PlayerList.RowCount := 1;
        Lbl_PlayerCnt.Caption := format('Player:%3d/%3d',[0,SE_WinLiveMaxPlayers_Val.Value]);
      end else begin
        if (pos('Players Connected',sl.Text)<>0) then
        begin
          StringGrid_PlayerList.RowCount := 1;
          Lbl_PlayerCnt.Caption := format('Player:%3d/%3d',[0,SE_WinLiveMaxPlayers_Val.Value]);
        end else if (pos('Authentication Failed',sl.Text)<>0) then begin
          StringGrid_PlayerList.RowCount := 1;
          Lbl_PlayerCnt.Caption := format('Player:%3d/%3d',[0,SE_WinLiveMaxPlayers_Val.Value]);
        end else begin
          Lbl_PlayerCnt.Caption := format('Player:%3d/%3d',[sl.Count,SE_WinLiveMaxPlayers_Val.Value]);

          StringGrid_PlayerList.RowCount:=sl.Count+1;

          for i:= 1 to sl.Count do
          begin
            StringGrid_PlayerList.Cells[0,i] := trim(Copy(sl.Strings[i-1],0,pos('.',sl.Strings[i-1])-1));
            StringGrid_PlayerList.Cells[1,i] := trim(Copy(sl.Strings[i-1],pos('.',sl.Strings[i-1])+1,pos(',',sl.Strings[i-1])-pos('.',sl.Strings[i-1])-1));
            StringGrid_PlayerList.Cells[2,i] := trim(Copy(sl.Strings[i-1],pos(',',sl.Strings[i-1])+1,99));
          end;
        end;
        Memo_RCONLogs.Lines.Add(sl.Text);
      end;
      StringGrid_PlayerList.EndUpdate(true);
    end;

    // SaveWorld
    if (RCONSender = Button_SaveWorld) then
    begin
      sl.Delete(sl.Count-1);
      Memo_RCONLogs.Lines.Add(sl.Text);
    end;

    // GetGameLog
    if (RCONSender = Button_GetGameLog) then
    begin
      sl.Delete(sl.Count-1);
      sl.Delete(sl.Count-1);
      Memo_RCONLogs.Lines.Add(sl.Text);
    end;

    // GetChat
    if (RCONSender = Button_GetChat) then
    begin
      sl.Delete(sl.Count-1);
      Memo_RCONLogs.Lines.Add(sl.Text);
    end;

    // DestroyWildDinos
    if (RCONSender = Button_DestroyWildDinos) then
    begin
      sl.Delete(sl.Count-1);
      Memo_RCONLogs.Lines.Add(sl.Text);
    end;

    // Button_RCON_Command
    if (RCONSender = Button_RCON_Command) then
    begin
      sl.Delete(sl.Count-1);
      Memo_RCONLogs.Lines.Add(sl.Text);
    end;
  finally
    sl.Free;
  end;
end;

procedure TAsaFrame.ButtonClearRCONLogsClick(Sender: TObject);
begin
  if (Sender = ButtonClearRCONLogs  ) then Memo_RCONLogs.Clear;
  if (Sender = ButtonClearSvrCMDLogs) then Memo_SrvCMDLogs.Clear;
end;

procedure TAsaFrame.GUSChange(Sender: TObject);
begin
  if (Edit_ServerAdminPassword.Text<>Edit_ServerAdminPassword2.Text) then
  begin
    if Sender = Edit_ServerAdminPassword  then Edit_ServerAdminPassword2.Text := Edit_ServerAdminPassword.Text;
    if Sender = Edit_ServerAdminPassword2 then Edit_ServerAdminPassword.Text := Edit_ServerAdminPassword2.Text;
  end;
  if (FSE_TamingSpeedMultiplier.Value<>FSE_TamingSpeedMultiplier2.Value) then
  begin
    if Sender = FSE_TamingSpeedMultiplier  then FSE_TamingSpeedMultiplier2.Value := FSE_TamingSpeedMultiplier.Value;
    if Sender = FSE_TamingSpeedMultiplier2 then FSE_TamingSpeedMultiplier.Value  := FSE_TamingSpeedMultiplier2.Value;
  end;
  if (FSE_HarvestAmountMultiplier.Value<>FSE_HarvestAmountMultiplier2.Value) then
  begin
    if Sender = FSE_HarvestAmountMultiplier  then FSE_HarvestAmountMultiplier2.Value := FSE_HarvestAmountMultiplier.Value;
    if Sender = FSE_HarvestAmountMultiplier2 then FSE_HarvestAmountMultiplier.Value  := FSE_HarvestAmountMultiplier2.Value;
  end;
  if (FSE_XPMultiplier.Value<>FSE_XPMultiplier2.Value) then
  begin
    if Sender = FSE_XPMultiplier  then FSE_XPMultiplier2.Value := FSE_XPMultiplier.Value;
    if Sender = FSE_XPMultiplier2 then FSE_XPMultiplier.Value  := FSE_XPMultiplier2.Value;
  end;
  if (SE_MaxHexagonsPerCharacter.Value<>SE_MaxHexagonsPerCharacter2.Value) then
  begin
    if Sender = SE_MaxHexagonsPerCharacter  then SE_MaxHexagonsPerCharacter2.Value := SE_MaxHexagonsPerCharacter.Value;
    if Sender = SE_MaxHexagonsPerCharacter2 then SE_MaxHexagonsPerCharacter.Value  := SE_MaxHexagonsPerCharacter2.Value;
  end;

  if canEditIni then createGUSIni;
  if canEditIni then ChkCmpInfo(Sender);
end;

procedure TAsaFrame.GUSChangeWithFocusOff(Sender: TObject);
begin
  TWinControl(Sender).Color:=clDefault;
  GUSChange(Sender);
end;

procedure TAsaFrame.Mods_Change(Sender: TObject);
var
  sl :TStringList;
  i  :Integer;
  beforeAutoMods :string;
begin
  sl := TStringList.Create;
  try
    for i:=0 to CG_ActiveEvent.Items.Count-1 do
    begin
      if CG_ActiveEvent.Checked[i] then sl.Add(CB_ActiveEvent_mod.Items[i+1]);
    end;

    if (ChB_Mod1_Enabled.checked) then sl.add('928793');
    if (ChB_Mod2_Enabled.checked) then sl.add('929420');
    if (ChB_Mod3_Enabled.checked) then sl.add('935408');
    if (ChB_Mod5_Enabled.checked) then sl.add('939228');

    if (ChB_Mod4_AA_Ceratosaurus.checked)     then sl.add('900062');
    if (ChB_Mod4_AA_Archelon.checked)         then sl.add('926956');
    if (ChB_Mod4_AA_Deinotherium.checked)     then sl.add('914844');
    if (ChB_Mod4_AA_Brachiosaurus.checked)    then sl.add('927131');
    if (ChB_Mod4_AA_Deinosuchus.checked)      then sl.add('912902');
    if (ChB_Mod4_AA_Helicoprion.checked)      then sl.add('916922');
    if (ChB_Mod4_AA_Xiphactinus.checked)      then sl.add('908148');
    if (ChB_Mod4_AA_Anomalocaris.checked)     then sl.add('987274');
    if (ChB_Mod4_AA_Acrocanthosaurus.checked) then sl.add('926259');

    beforeAutoMods := Edit_AutoAddedModInArgs.Text;
    if (sl.Count<>0) then Edit_AutoAddedModInArgs.Text:=sl.CommaText;
    if (sl.Count =0) then Edit_AutoAddedModInArgs.Text:='';
    if (beforeAutoMods<>Edit_AutoAddedModInArgs.Text) then Edit_AllModInArgsChange(Sender);
  finally
    sl.Free;
  end;
  GUSChange(Sender);
end;

procedure TAsaFrame.RCON_COMAND_Click(Sender: TObject);
var
  i   :Integer;
  sCmd:string;
  str :string;
  sl  :TStringList;
  sl2 :TStringList;
begin
  if BusyFlg then
  begin
    Lbl_Profile_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Import_Status_01.Caption;
    Lbl_Profile_Status.Repaint;
    sLast_Profile_Status :=Form_MessageTrans.Lbl_Hidden_Import_Status_01.Caption;
    iLast_Profile_Status_Time := DateTimeToUnix(now);

    exit;
  end;

  BusyFlg := true;

  try
    if (AsyncProcess_ListPlayer.Running) then exit;
    if ((Edit_ServerAdminPassword.Text<>'')and(SE_RCONPort.Text<>'')and(CB_RCONEnabled.Checked)) then
    begin
      if UseBuiltinRCON then
      begin
        if (Sender=Button_ListPlayers)      then sCmd := 'ListPlayers';
        if (Sender=Button_SaveWorld)        then sCmd := 'SaveWorld';
        if (Sender=Button_GetGameLog)       then sCmd := 'GetGameLog';
        if (Sender=Button_GetChat)          then sCmd := 'GetChat';
        if (Sender=Button_DestroyWildDinos) then sCmd := 'DestroyWildDinos';
        if (Sender=Button_OpenPort)         then sCmd := 'Open 127.0.0.1:'+SE_Port.Text;
        if (Sender=Button_RCON_Command) then
        begin
          if (CB_RCON_Command.Text = '') then exit;
          sCmd := CB_RCON_Command.Text;
          sCmd := StringReplace(sCmd,'"','',[ rfReplaceAll ]);
          sCmd := format('%s',[sCmd]);

          // command History
          begin
            CB_RCON_Command.Items.Insert(0,CB_RCON_Command.Text);
            for i := CB_RCON_Command.Items.Count-1 DownTo 1 do
            begin
              if (CB_RCON_Command.Items.Strings[i] = CB_RCON_Command.Text) then CB_RCON_Command.Items.Delete(i);
            end;

            for i := CB_RCON_Command.Items.Count-1 DownTo 10 do
            begin
              CB_RCON_Command.Items.Delete(i);
            end;
            CB_RCON_Command.Text := '';
          end;
        end;
        RClient := TRCON.Create;
        try
          RClient.port    :=SE_RCONPort.Value;
          RClient.password:=Edit_ServerAdminPassword.Text;
          Memo_RCONLogs.Lines.Add(format('[Built-In]Port=%d PW=%s %s',[RClient.port,'******',sCmd]));
          RClient.sendcmd(sCmd);

          if (RClient.LastErrCD = CD_OK) then
          begin
            Memo_RCONLogs.Lines.Add(RClient.ReturnStr);
            if (sCmd = 'ListPlayers') then
            begin
              str := RClient.ReturnStr;
              if (pos('No Players Connected',str)<>0) then
              begin
                StringGrid_PlayerList.RowCount := 1;
                Lbl_PlayerCnt.Caption := format('Player:%3d/%3d',[0,SE_WinLiveMaxPlayers_Val.Value]);
              end else begin
                sl := TStringList.Create;
                sl2:= TStringList.Create;
                try
                  sl.Text:= str;
                  sl.Delete(0);
                  sl.Delete(sl.Count-1);

                  Lbl_PlayerCnt.Caption := format('Player:%3d/%3d',[sl.Count,SE_WinLiveMaxPlayers_Val.Value]);

                  StringGrid_PlayerList.BeginUpdate;
                  StringGrid_PlayerList.RowCount := sl.Count+1;
                  for i := 0 to sl.Count-1 do
                  begin
                    sl2.CommaText:=sl.Strings[i];
                    if (sl2.Count>=3) then
                    begin
                      StringGrid_PlayerList.Cells[0,i+1] := sl2.Strings[0];
                      StringGrid_PlayerList.Cells[1,i+1] := sl2.Strings[1];
                      StringGrid_PlayerList.Cells[2,i+1] := sl2.Strings[2];
                    end;
                  end;
                  StringGrid_PlayerList.EndUpdate(true);
                finally
                  sl.Free;
                  sl2.Free;
                end;
              end;
            end;
          end else begin
            Memo_RCONLogs.Lines.Add(format('[%d]%s',[RClient.LastErrCD,RClient.LastError]));
          end;
        finally
          RClient.Free;
        end;
        exit;
      end;

      RCONSender := Sender;

      // ListPlayers
      if (Sender=Button_ListPlayers) then
      begin
        AsyncProcess_ListPlayer.CommandLine := format('mcrcon\mcrcon.exe -P %s -p %s ListPlayers',[SE_RCONPort.Text,Edit_ServerAdminPassword.Text]);
        Memo_RCONLogs.Lines.Add(format('mcrcon\mcrcon.exe -P %s -p %s ListPlayers',[SE_RCONPort.Text,'******']));
      end;

      // SaveWorld
      if (Sender=Button_SaveWorld) then
      begin
        AsyncProcess_ListPlayer.CommandLine := format('mcrcon\mcrcon.exe -P %s -p %s SaveWorld',[SE_RCONPort.Text,Edit_ServerAdminPassword.Text]);
        Memo_RCONLogs.Lines.Add(format('mcrcon\mcrcon.exe -P %s -p %s SaveWorld',[SE_RCONPort.Text,'******']));
      end;

      // GetGameLog
      if (Sender=Button_GetGameLog) then
      begin
        if not ChB_servergamelog.Checked then exit;
        AsyncProcess_ListPlayer.CommandLine := format('mcrcon\mcrcon.exe -P %s -p %s GetGameLog',[SE_RCONPort.Text,Edit_ServerAdminPassword.Text]);
        Memo_RCONLogs.Lines.Add(format('mcrcon\mcrcon.exe -P %s -p %s GetGameLog',[SE_RCONPort.Text,'******']));
      end;

      // GetChat
      if (Sender=Button_GetChat) then
      begin
        AsyncProcess_ListPlayer.CommandLine := format('mcrcon\mcrcon.exe -P %s -p %s GetChat',[SE_RCONPort.Text,Edit_ServerAdminPassword.Text]);
        Memo_RCONLogs.Lines.Add(format('mcrcon\mcrcon.exe -P %s -p %s GetChat',[SE_RCONPort.Text,'******']));
      end;

      // DestroyWildDinos
      if (Sender=Button_DestroyWildDinos) then
      begin
        AsyncProcess_ListPlayer.CommandLine := format('mcrcon\mcrcon.exe -P %s -p %s DestroyWildDinos',[SE_RCONPort.Text,Edit_ServerAdminPassword.Text]);
        Memo_RCONLogs.Lines.Add(format('mcrcon\mcrcon.exe -P %s -p %s DestroyWildDinos',[SE_RCONPort.Text,'******']));
      end;

      // OpenPort
      if (Sender=Button_OpenPort) then
      begin
        AsyncProcess_ListPlayer.CommandLine := format('mcrcon\mcrcon.exe -P %s -p %s "Open 127.0.0.1:%s"',[SE_RCONPort.Text,Edit_ServerAdminPassword.Text,SE_Port.Text]);
        Memo_RCONLogs.Lines.Add(format('mcrcon\mcrcon.exe -P %s -p %s "Open 127.0.0.1:%s"',[SE_RCONPort.Text,'******']));
      end;

      // Button_RCON_Command
      if (Sender=Button_RCON_Command) then
      begin
        if (CB_RCON_Command.Text = '') then exit;
        sCmd := CB_RCON_Command.Text;
        sCmd := StringReplace(sCmd,'"','',[ rfReplaceAll ]);
        sCmd := format('"%s"',[sCmd]);
        AsyncProcess_ListPlayer.CommandLine := format('mcrcon\mcrcon.exe -P %s -p %s %s',[SE_RCONPort.Text,Edit_ServerAdminPassword.Text,sCmd]);
        Memo_RCONLogs.Lines.Add(format('mcrcon\mcrcon.exe -P %s -p %s %s',[SE_RCONPort.Text,'******']));

        // command History
        begin
          CB_RCON_Command.Items.Insert(0,CB_RCON_Command.Text);
          for i := CB_RCON_Command.Items.Count-1 DownTo 1 do
          begin
            if (CB_RCON_Command.Items.Strings[i] = CB_RCON_Command.Text) then CB_RCON_Command.Items.Delete(i);
          end;

          for i := CB_RCON_Command.Items.Count-1 DownTo 10 do
          begin
            CB_RCON_Command.Items.Delete(i);
          end;
        end;
        CB_RCON_Command.Text := '';
      end;
      AsyncProcess_ListPlayer.Execute;
    end;
  finally
    BusyFlg := false;
  end;
end;

procedure TAsaFrame.RG_Cosmetic_Change(Sender: TObject);
var
  modname : string;
  targetRow :integer;
begin
  if (Sender = RG_Cosmetic_Kind) then
  begin
    if (RG_Cosmetic_Kind.ItemIndex = 0) then
    begin
      Lbl_Cosmetic_URL         .Visible:=false;
      Edit_Cosmetic_URL        .Visible:=false;
      Edit_Cosmetic_LocalFile  .Visible:=false;
      Lbl_Cosmetic_LocalFile2  .Visible:=false;
      Button_Cosmetic_LocalFile.Visible:=false;
      GB_LocalFile             .Visible:=false;
    end;

    if (RG_Cosmetic_Kind.ItemIndex = 1) then
    begin
      Lbl_Cosmetic_URL         .Visible:=false;
      Edit_Cosmetic_URL        .Visible:=false;
      Edit_Cosmetic_LocalFile  .Visible:=false;
      Lbl_Cosmetic_LocalFile2  .Visible:=false;
      Button_Cosmetic_LocalFile.Visible:=false;
      GB_LocalFile             .Visible:=false;
    end;

    if (RG_Cosmetic_Kind.ItemIndex = 2) then
    begin
      Lbl_Cosmetic_URL         .Visible:=true;
      Edit_Cosmetic_URL        .Visible:=true;
      Edit_Cosmetic_LocalFile  .Visible:=false;
      Lbl_Cosmetic_LocalFile2  .Visible:=false;
      Button_Cosmetic_LocalFile.Visible:=false;
      GB_LocalFile             .Visible:=false;
    end;

    if (RG_Cosmetic_Kind.ItemIndex = 3) then
    begin
      Lbl_Cosmetic_URL         .Visible:=false;
      Edit_Cosmetic_URL        .Visible:=false;
      Edit_Cosmetic_LocalFile  .Visible:=true;
      Lbl_Cosmetic_LocalFile2  .Visible:=true;
      Button_Cosmetic_LocalFile.Visible:=true;
      GB_LocalFile             .Visible:=true;
      if (Edit_Cosmetic_LocalFile.Text = '') then
      begin
        // Default LocalFile
        Edit_Cosmetic_LocalFile.Text := Edit_Install_Location_Val.Text + '\ShooterGame\Binaries\Win64';
      end;
    end;

    if (RG_Cosmetic_Kind.ItemIndex = 4) then
    begin
      Lbl_Cosmetic_URL         .Visible:=false;
      Edit_Cosmetic_URL        .Visible:=false;
      Edit_Cosmetic_LocalFile  .Visible:=false;
      Lbl_Cosmetic_LocalFile2  .Visible:=false;
      Button_Cosmetic_LocalFile.Visible:=false;
      GB_LocalFile             .Visible:=true;
    end;
  end;

  if (Sender = Edit_Cosmetic_ModId) then
  begin
    if (Edit_Cosmetic_ModId.Text = '') then
    begin
      Lbl_Cosmetic_ModName.Caption := '';
    end else begin
      modname := sl_ModList.Values[Edit_Cosmetic_ModId.Text];
      if (modname = '')                     then modname := '(No Data)';
      if (pos('(ClientOnly)',modname) <> 1) then modname := '(No Data)';
      modname := stringReplace(modname,'(ClientOnly)','',[rfReplaceAll, rfIgnoreCase]);

      Lbl_Cosmetic_ModName.Caption := modname;
    end;
  end;

  if (Sender = Button_Cosmetic_Add) then
  begin
    if (Edit_Cosmetic_ModId.Text <> '') then
    begin
      SG_Cosmetic.RowCount := SG_Cosmetic.RowCount +1;
      targetRow            := SG_Cosmetic.RowCount -1;

      // set GridData
      begin
                                                            SG_Cosmetic.Cells[0,targetRow] := Edit_Cosmetic_ModId.Text;
                                                            SG_Cosmetic.Cells[1,targetRow] := Lbl_Cosmetic_ModName.Caption;
        if (ChB_EnableDynamicDownload.Checked)         then SG_Cosmetic.Cells[2,targetRow] := 'True';
        if (ChB_Allow_non_dataonly_blueprints.Checked) then SG_Cosmetic.Cells[3,targetRow] := 'True';

        Edit_Cosmetic_ModId.Text := '';
        Lbl_Cosmetic_ModName.Caption := '';
        ChB_EnableDynamicDownload.Checked := true;
        ChB_Allow_non_dataonly_blueprints.Checked := true;
        SG_Cosmetic.Row := targetRow;
      end;
    end;
  end;

  if (Sender = Button_Cosmetic_Remove) then
  begin
    Edit_Cosmetic_ModId.Text     := SG_Cosmetic.Cells[0,SG_Cosmetic.Row];
    Lbl_Cosmetic_ModName.Caption := SG_Cosmetic.Cells[1,SG_Cosmetic.Row];
    ChB_EnableDynamicDownload.Checked := true;
    ChB_Allow_non_dataonly_blueprints.Checked := true;

    if (SG_Cosmetic.Cells[2,SG_Cosmetic.Row] = '') then ChB_EnableDynamicDownload.Checked := false;
    if (SG_Cosmetic.Cells[3,SG_Cosmetic.Row] = '') then ChB_Allow_non_dataonly_blueprints.Checked := false;

    SG_Cosmetic.DeleteRow(SG_Cosmetic.Row);
  end;
  ChkCmpInfo(Sender);
  createGUSIni;
end;

procedure TAsaFrame.ServerPlatformChange(Sender: TObject);
begin
 if (Sender = ChB_ServerPlatform_ALL) then
 begin
   if ChB_ServerPlatform_ALL.Checked then
   begin
     ChB_ServerPlatform_PC.OnChange:=nil;
     ChB_ServerPlatform_PS5.OnChange:=nil;
     ChB_ServerPlatform_XSX.OnChange:=nil;
     ChB_ServerPlatform_MSStore.OnChange:=nil;

     ChB_ServerPlatform_PC.Checked:=false;
     ChB_ServerPlatform_PS5.Checked:=false;
     ChB_ServerPlatform_XSX.Checked:=false;
     ChB_ServerPlatform_MSStore.Checked:=false;

     ChB_ServerPlatform_PC.OnChange:=@ServerPlatformChange;
     ChB_ServerPlatform_PS5.OnChange:=@ServerPlatformChange;
     ChB_ServerPlatform_XSX.OnChange:=@ServerPlatformChange;
     ChB_ServerPlatform_MSStore.OnChange:=@ServerPlatformChange;
   end;
 end else begin
   if ChB_ServerPlatform_PC.Checked or
      ChB_ServerPlatform_PS5.Checked or
      ChB_ServerPlatform_XSX.Checked or
      ChB_ServerPlatform_MSStore.Checked then
   begin
     ChB_ServerPlatform_ALL.OnChange:=nil;
     ChB_ServerPlatform_ALL.Checked:=false;
     ChB_ServerPlatform_ALL.OnChange:=@ServerPlatformChange;
   end;
 end;
 argsChange(Sender);
end;

procedure TAsaFrame.SL_OverrideNamedEngramEntriesEditingDone(Sender: TObject);
var
  sItem,
  slastItem:string;
  sClass,
  sLastClass:string;
  sl : TStringList;
begin
  if (SL_OverrideNamedEngramEntries.Col = 1) then
  begin
    sItem     := SL_OverrideNamedEngramEntries.Cells[1,SL_OverrideNamedEngramEntries.Row];
    slastItem := SL_OverrideNamedEngramEntries.Cells[7,SL_OverrideNamedEngramEntries.Row];
    if (sItem<>slastItem) then
    begin
      SL_OverrideNamedEngramEntries.Cells[7,SL_OverrideNamedEngramEntries.Row] := SL_OverrideNamedEngramEntries.Cells[1,SL_OverrideNamedEngramEntries.Row];
      sl := TStringList.Create;
      try
        sl.CommaText:= SL_OverrideNamedEngramEntries.Columns[0].PickList.Values[sItem];
        if (sl.Count<>0) then
        begin
          SL_OverrideNamedEngramEntries.Cells[2,SL_OverrideNamedEngramEntries.Row] := sl.Strings[0];
          SL_OverrideNamedEngramEntries.Cells[3,SL_OverrideNamedEngramEntries.Row] := '0';
          SL_OverrideNamedEngramEntries.Cells[4,SL_OverrideNamedEngramEntries.Row] := sl.Strings[2];
          SL_OverrideNamedEngramEntries.Cells[5,SL_OverrideNamedEngramEntries.Row] := sl.Strings[3];
          SL_OverrideNamedEngramEntries.Cells[6,SL_OverrideNamedEngramEntries.Row] := '0';
          SL_OverrideNamedEngramEntries.Cells[8,SL_OverrideNamedEngramEntries.Row] := sl.Strings[0];
          SL_OverrideNamedEngramEntries.Cells[9,SL_OverrideNamedEngramEntries.Row] := sl.Strings[1];
        end;
      finally
        sl.Free;
      end;
    end;
  end;

  if (SL_OverrideNamedEngramEntries.Col = 2) then
  begin
    sClass     := SL_OverrideNamedEngramEntries.Cells[2,SL_OverrideNamedEngramEntries.Row];
    sLastClass := SL_OverrideNamedEngramEntries.Cells[8,SL_OverrideNamedEngramEntries.Row];
    if (sClass<>sLastClass) then
    begin
      SL_OverrideNamedEngramEntries.Cells[8,SL_OverrideNamedEngramEntries.Row] := SL_OverrideNamedEngramEntries.Cells[2,SL_OverrideNamedEngramEntries.Row];
      SL_OverrideNamedEngramEntries.Cells[7,SL_OverrideNamedEngramEntries.Row] := '(Manually Input)';
      SL_OverrideNamedEngramEntries.Cells[1,SL_OverrideNamedEngramEntries.Row] := '(Manually Input)';
    end;
  end;
end;

procedure TAsaFrame.SL_SpawnList2EditingDone(Sender: TObject);
var
  NewName :string;
  OldName :string;
  sl :TStringList;
begin
  if (SL_SpawnList2.Col = 0) then
  begin
    NewName := SL_SpawnList2.Cells[0,SL_SpawnList2.Row];
    OldName := SL_SpawnList2.Cells[5,SL_SpawnList2.Row];
    if (NewName <> OldName) then
    begin
      sl := TStringList.Create;
      try
        sl.CommaText:=sl_DinoList.Values[NewName];
        if (sl.Count>=4) then
        begin
          SL_SpawnList2.Cells[1,SL_SpawnList2.Row]:=sl[3];
          SL_SpawnList2.Cells[2,SL_SpawnList2.Row]:=sl[0];
          SL_SpawnList2.Cells[3,SL_SpawnList2.Row]:=sl[1];
          SL_SpawnList2.Cells[4,SL_SpawnList2.Row]:=sl[2];
          SL_SpawnList2.Cells[5,SL_SpawnList2.Row]:=sl[3];
        end;
      finally
        SL_SpawnList2.Cells[6,SL_SpawnList2.Row] := NewName;
        sl.Free;
      end;
    end;
  end;
end;

procedure TAsaFrame.Timer_SvrStatusTimer(Sender: TObject);
var
  iNow    :LongInt;
  iElapsed:LongInt;
begin
  if (sLast_Profile_Status <> '') then
  begin
    iNow := DateTimeToUnix(now);
    iElapsed := iNow - iLast_Profile_Status_Time;
    if iElapsed > 0 then
    begin
      if iElapsed > 59 then
      begin
        if iElapsed > 3599 then
        begin
          Lbl_Profile_Status.Caption := format(Form_MessageTrans.Lbl_Hidden_Before_h.Caption,[(iElapsed div 3600),sLast_Profile_Status]);
        end else begin
          Lbl_Profile_Status.Caption := format(Form_MessageTrans.Lbl_Hidden_Before_m.Caption,[(iElapsed mod 3600) div 60,sLast_Profile_Status]);
        end;
      end else begin
        Lbl_Profile_Status.Caption := format(Form_MessageTrans.Lbl_Hidden_Before_s.Caption,[iElapsed,sLast_Profile_Status]);
      end;
      Lbl_Profile_Status.Repaint;
    end;
  end;

  if BusyFlg then exit;
  updateServerStatus;
end;

procedure TAsaFrame.Timer_GetVerInfoTimer(Sender: TObject);
var
  sl  : TStringList;
  strm: TFileStream;
  i   : Integer;
  str : String;
begin
  if BusyFlg then exit;
  //バージョン情報の取得
  sl := TStringList.Create;
  strm := TFileStream.Create(Edit_Install_Location_Val.Text+'\ShooterGame\Saved\Logs\ShooterGame.log',fmOpenRead or fmShareDenyNone);
  try
    sl.Clear;
    sl.LoadFromStream(strm);
    if sl.Count=0 then exit;

    for i:=0 to sl.Count -1 do
    begin
      str := sl.Strings[i];
      if (pos('ARK Version:',str)<>0) then
      begin
        ArkVer := Copy(str,pos('ARK Version:',str)+13,8);
        Lbl_InstVer_Val.Caption:=ArkVer;
        Timer_GetVerInfo.Enabled:=false;
      end;
    end;
  finally
    sl.Free;
    strm.Free;
  end;
end;

procedure TAsaFrame.GameIniChange(Sender: TObject);
begin
  if (FSE_BabyMatureSpeedMultiplier.Value<>FSE_BabyMatureSpeedMultiplier2.Value) then
  begin
    if Sender = FSE_BabyMatureSpeedMultiplier  then FSE_BabyMatureSpeedMultiplier2.Value := FSE_BabyMatureSpeedMultiplier.Value;
    if Sender = FSE_BabyMatureSpeedMultiplier2 then FSE_BabyMatureSpeedMultiplier.Value  := FSE_BabyMatureSpeedMultiplier2.Value;
  end;
  if (FSE_EggHatchSpeedMultiplier.Value<>FSE_EggHatchSpeedMultiplier2.Value) then
  begin
    if Sender = FSE_EggHatchSpeedMultiplier  then FSE_EggHatchSpeedMultiplier2.Value := FSE_EggHatchSpeedMultiplier.Value;
    if Sender = FSE_EggHatchSpeedMultiplier2 then FSE_EggHatchSpeedMultiplier.Value  := FSE_EggHatchSpeedMultiplier2.Value;
  end;
  if (FSE_BabyImprintAmountMultiplier.Value<>FSE_BabyImprintAmountMultiplier2.Value) then
  begin
    if Sender = FSE_BabyImprintAmountMultiplier  then FSE_BabyImprintAmountMultiplier2.Value := FSE_BabyImprintAmountMultiplier.Value;
    if Sender = FSE_BabyImprintAmountMultiplier2 then FSE_BabyImprintAmountMultiplier.Value  := FSE_BabyImprintAmountMultiplier2.Value;
  end;
  if (FSE_MatingIntervalMultiplier.Value<>FSE_MatingIntervalMultiplier2.Value) then
  begin
    if Sender = FSE_MatingIntervalMultiplier  then FSE_MatingIntervalMultiplier2.Value := FSE_MatingIntervalMultiplier.Value;
    if Sender = FSE_MatingIntervalMultiplier2 then FSE_MatingIntervalMultiplier.Value  := FSE_MatingIntervalMultiplier2.Value;
  end;
  if (FSE_BabyCuddleIntervalMultiplier.Value<>FSE_BabyCuddleIntervalMultiplier2.Value) then
  begin
    if Sender = FSE_BabyCuddleIntervalMultiplier  then FSE_BabyCuddleIntervalMultiplier2.Value := FSE_BabyCuddleIntervalMultiplier.Value;
    if Sender = FSE_BabyCuddleIntervalMultiplier2 then FSE_BabyCuddleIntervalMultiplier.Value  := FSE_BabyCuddleIntervalMultiplier2.Value;
  end;

  if canEditIni then createGameIni;
  if canEditIni then Pnl_SaveProfile.Color:=clRed;
  if canEditIni then Pnl_SetIni     .Color:=clRed;
end;

procedure TAsaFrame.createArgs;
  function ipcheck(sender:TObject):string;
  begin
    result := '';
    if sender = Edit_ipv4_Val then
    begin
      if (Edit_ipv4_Val.Text <> '256.256.256.256') and
         (Edit_ipv4_Val.Text <> ''               ) then result := '-ip='+Edit_ipv4_Val.Text + ' ';
    end;
    if sender = Edit_ServerIPv4_Val then
    begin
      if (Edit_ServerIPv4_Val.Text <> '256.256.256.256') and
         (Edit_ServerIPv4_Val.Text <> ''               ) then result := '-ServerIP='+Edit_ServerIPv4_Val.Text + ' ';
    end;
  end;
var
  cmd :string;
  sl  :TStringList;
  i   :integer;
begin
  if ChB_USE_AsaApiLoader.Checked then
  begin
    cmd:= 'AsaApiLoader.exe ';
  end else begin
    cmd:= 'ArkAscendedServer.exe ';
  end;
  cmd := cmd + CB_MapName.Text;

  // [?] Args
  if (ChB_Port_Args.Checked)                                  then cmd := cmd + '?Port='     +SE_Port.Text;
  if (ChB_Queryport_Args.Checked)                             then cmd := cmd + '?Queryport='+SE_Queryport.Text;
  if (ChB_RCONPort_Args.Checked)                              then cmd := cmd + '?RCONPort=' +SE_RCONPort.Text;
  if ChB_AltSaveDirectoryName.Checked and (Edit_AltSaveDirectoryName.Text <> '')
                                                              then cmd := cmd + '?AltSaveDirectoryName="'+Edit_AltSaveDirectoryName.Text + '"';

  // [-] Args
                                                                   cmd := cmd + ' ';
  if ChB_NoBattlEye.Checked                                   then cmd := cmd + '-NoBattlEye ';
  if ChB_AlwaysTickDedicatedSkeletalMeshes.Checked            then cmd := cmd + '-AlwaysTickDedicatedSkeletalMeshes ';
  if CB_Culture.ItemIndex>0                                   then cmd := cmd + '-culture='+CB_Culture.Text + ' ';
  if ChB_disabledinonetrangescaling.Checked                   then cmd := cmd + '-disabledinonetrangescaling ';
  if ChB_ForceAllowCaveFlyers.Checked                         then cmd := cmd + '-ForceAllowCaveFlyers ';
  if SE_GBUsageToForceRestart_Val.Value<>35                   then cmd := cmd + '-GBUsageToForceRestart='+SE_GBUsageToForceRestart_Val.Text + ' ';
  if (Edit_clusterid.Text<>'')                                then cmd := cmd + '-clusterid='+Edit_clusterid.Text + ' ';
  if (Edit_ClusterDirOverride.Text<>'')                       then cmd := cmd + '-ClusterDirOverride="'+Edit_ClusterDirOverride.Text + '" ';
  if ChB_NoTransferFromFiltering.Checked                      then cmd := cmd + '-NoTransferFromFiltering ';

  if (Edit_AllModInArgs.Text<>'')                             then cmd := cmd + '-mods='+Edit_AllModInArgs.Text + ' ';
  if (Edit_passivemods.Text<>'')                              then cmd := cmd + '-passivemods='+Edit_passivemods.Text + ' ';

  if (CB_ActiveEvent2.ItemIndex>0)                            then cmd := cmd + '-Activeevent='+CB_ActiveEvent2.Text + ' ';

  if ChB_MULTIHOME.Checked                                    then cmd := cmd + '-MULTIHOME ';
  if ChB_MULTIHOME.Checked                                    then cmd := cmd + ipcheck(Edit_ipv4_Val);
  if ChB_MULTIHOME.Checked                                    then cmd := cmd + ipcheck(Edit_ServerIPv4_Val);
  if ChB_NoWildBabies.Checked                                 then cmd := cmd + '-NoWildBabies ';
  if ChB_servergamelog.Checked                                then cmd := cmd + '-servergamelog ';
  if ChB_servergamelogincludetribelogs.Checked                then cmd := cmd + '-servergamelogincludetribelogs ';
  if ChB_ServerRCONOutputTribeLogs.Checked                    then cmd := cmd + '-ServerRCONOutputTribeLogs ';
  if ChB_ForceRespawnDinos.Checked                            then cmd := cmd + '-ForceRespawnDinos ';
  if ChB_UseDynamicConfig.Checked                             then cmd := cmd + '-UseDynamicConfig ';
  if SE_WinLiveMaxPlayers_Val.Value<>70                       then cmd := cmd + '-WinLiveMaxPlayers='+SE_WinLiveMaxPlayers_Val.Text + ' ';
  if Edit_CustomNotificationURL_Val.Text<>''                  then cmd := cmd + '-CustomNotificationURL="'+Edit_CustomNotificationURL_Val.Text + '" ';
  if ChB_UseServerNetSpeedCheck.Checked                       then cmd := cmd + '-UseServerNetSpeedCheck ';

  if ChB_DisableCustomCosmetics.Checked                       then cmd := cmd + '-DisableCustomCosmetics ';
  if ChB_disableCharacterTracker.Checked                      then cmd := cmd + '-disableCharacterTracker ';
  if ChB_DisableDupeLogDeletes.Checked                        then cmd := cmd + '-DisableDupeLogDeletes ';
  if ChB_ForceDupeLog.Checked                                 then cmd := cmd + '-ForceDupeLog ';
  if ChB_forceuseperfthreads.Checked                          then cmd := cmd + '-forceuseperfthreads ';
  if ChB_ignoredupeditems.Checked                             then cmd := cmd + '-ignoredupeditems ';
  if ChB_UseItemDupeCheck.Checked                             then cmd := cmd + '-UseItemDupeCheck ';
  if ChB_NoAI.Checked                                         then cmd := cmd + '-NoAI ';
  if ChB_nodinos.Checked                                      then cmd := cmd + '-nodinos ';
  if ChB_NoDinosExceptForcedSpawn.Checked                     then cmd := cmd + '-NoDinosExceptForcedSpawn ';
  if ChB_NoDinosExceptStreamingSpawn.Checked                  then cmd := cmd + '-NoDinosExceptStreamingSpawn ';
  if ChB_NoDinosExceptManualSpawn.Checked                     then cmd := cmd + '-NoDinosExceptManualSpawn ';
  if ChB_NoDinosExceptWaterSpawn.Checked                      then cmd := cmd + '-NoDinosExceptWaterSpawn ';
  if ChB_noperfthreads.Checked                                then cmd := cmd + '-noperfthreads ';
  if ChB_nosound.Checked                                      then cmd := cmd + '-nosound ';
  if ChB_onethread.Checked                                    then cmd := cmd + '-onethread ';
  if ChB_StasisKeepControllers.Checked                        then cmd := cmd + '-StasisKeepControllers ';
  if ChB_UnstasisDinoObstructionCheck.Checked                 then cmd := cmd + '-UnstasisDinoObstructionCheck ';
  if ChB_AutoDestroyStructures.Checked                        then cmd := cmd + '-AutoDestroyStructures ';
  if ChB_exclusivejoin.Checked                                then cmd := cmd + '-exclusivejoin ';
  if ChB_EnableIdlePlayerKick.Checked                         then cmd := cmd + '-EnableIdlePlayerKick ';
  if ChB_ForceClampItemQuality.Checked                        then cmd := cmd + '-ForceClampItemQuality ';
  if ChB_ForceWipeTinkerExploit.Checked                       then cmd := cmd + '-ForceWipeTinkerExploit ';
  if ChB_ForceWipeTinkerExploitNoDinos.Checked                then cmd := cmd + '-ForceWipeTinkerExploitNoDinos ';
  if ChB_NoTimeout.Checked                                    then cmd := cmd + '-NoTimeout ';

  if ChB_FixThrallStats.Checked                               then cmd := cmd + '-FixThrallStats ';
  if ChB_ForceCharRespec.Checked                              then cmd := cmd + '-ForceCharRespec ';
  if ChB_allowicefox.Checked                                  then cmd := cmd + '-allowicefox ';

  if ChB_EasterColors.Checked                                 then cmd := cmd + '-EasterColors ';
  if ChB_OlympicColors.Checked                                then cmd := cmd + '-OlympicColors ';
  if ChB_PrideColors.Checked                                  then cmd := cmd + '-PrideColors ';
  if ChB_HalloweenColors.Checked                              then cmd := cmd + '-HalloweenColors ';
  if ChB_ServerUseEventColors.Checked                         then cmd := cmd + '-ServerUseEventColors ';
  if ChB_RedownloadModsOnServerRestart.Checked                then cmd := cmd + '-RedownloadModsOnServerRestart ';
  if (SE_DestroyTamesOverLevel.Text<>'') and (SE_DestroyTamesOverLevel.Value<> 0)
                                                              then cmd := cmd + '-DestroyTamesOverLevel='+SE_DestroyTamesOverLevel.Text + ' ';

  sl := TStringList.Create;
  try
    sl.Clear;
    if ChB_ServerPlatform_PC.Checked      then sl.Add('PC');
    if ChB_ServerPlatform_ALL.Checked     then sl.Add('ALL');
    if ChB_ServerPlatform_PS5.Checked     then sl.Add('PS5');
    if ChB_ServerPlatform_XSX.Checked     then sl.Add('XSX');
    if ChB_ServerPlatform_MSStore.Checked then sl.Add('WINGDK');

    if sl.Count>0 then cmd := cmd + '-ServerPlatform=';
    if sl.Count>0 then cmd := cmd + sl.Strings[0];
    for i:=1 to sl.Count-1 do
    begin
      cmd := cmd + '+' +sl.Strings[i];
    end;
    if sl.Count>0 then cmd := cmd + ' ';
  finally
    sl.Free;
  end;

  MM_Command_Val.Text:=trim(cmd);
end;

procedure TAsaFrame.createGUSIni;
var
  str : string;
  sl:TStringList;
  i:integer;
  vMemo         :TStringList;
  ihh,imm,iss   :integer;
begin
  Memo_GameUserSettings.BeginUpdateBounds;
  Memo_GameUserSettings.Clear;
  vMemo := TStringList.Create;
  try
    with vMemo do
    begin
                                                                              Add('[ServerSettings]');
      if Edit_ActiveMods_Val.Text<>''                                    then Add('ActiveMods='+Edit_ActiveMods_Val.Text);
      if Edit_ActiveMapMod_Val.Text<>''                                  then Add('ActiveMapMod='+Edit_ActiveMapMod_Val.Text);
      if ChB_AdminLogging.Checked                                        then Add('AdminLogging=True');
      if ChB_AllowAnyoneBabyImprintCuddle.Checked                        then Add('AllowAnyoneBabyImprintCuddle=True');
      if ChB_AllowCaveBuildingPvE.Checked                                then Add('AllowCaveBuildingPvE=True');
      if not ChB_AllowCaveBuildingPvP.Checked                            then Add('AllowCaveBuildingPvP=False');
      if ChB_AllowFlyerCarryPvE.Checked                                  then Add('AllowFlyerCarryPvE=True');
      if not ChB_AllowHideDamageSourceFromLogs.Checked                   then Add('AllowHideDamageSourceFromLogs=False');
      if not ChB_AllowHitMarkers.Checked                                 then Add('AllowHitMarkers=False');
      if ChB_AllowMultipleAttachedC4.Checked                             then Add('AllowMultipleAttachedC4=True');
      if ChB_AllowRaidDinoFeeding.Checked                                then Add('AllowRaidDinoFeeding=True');
      if not ChB_AllowThirdPersonPlayer.Checked                          then Add('AllowThirdPersonPlayer=False');
      if ChB_AlwaysAllowStructurePickup.Checked                          then Add('AlwaysAllowStructurePickup=True');
      if (FSE_AutoSavePeriodMinutes.Value <> 15.0)                       then Add('AutoSavePeriodMinutes='+FSE_AutoSavePeriodMinutes.Text);
      if ChB_ClampItemSpoilingTimes.Checked                              then Add('ClampItemSpoilingTimes=True');
      if ChB_ClampResourceHarvestDamage.Checked                          then Add('ClampResourceHarvestDamage=True');
      if ChB_ClampItemStats.Checked                                      then Add('ClampItemStats=True');
      if (FSE_DayCycleSpeedScale.Value <> 1.0)                           then Add('DayCycleSpeedScale='+FSE_DayCycleSpeedScale.Text);
      if (FSE_DayTimeSpeedScale.Value <> 1.0)                            then Add('DayTimeSpeedScale='+FSE_DayTimeSpeedScale.Text);
      if (FSE_NightTimeSpeedScale.Value <> 1.0)                          then Add('NightTimeSpeedScale='+FSE_NightTimeSpeedScale.Text);
      if (FSE_DifficultyOffset.Value <> 1.0)                             then Add('DifficultyOffset='+FSE_DifficultyOffset.Text);
      if ChB_MaxDifficulty.Checked                                       then Add('MaxDifficulty=True');
      if (FSE_DinoCharacterFoodDrainMultiplier.Value <> 1.0)             then Add('DinoCharacterFoodDrainMultiplier='+FSE_DinoCharacterFoodDrainMultiplier.Text);
      if (FSE_DinoCharacterHealthRecoveryMultiplier.Value <> 1.0)        then Add('DinoCharacterHealthRecoveryMultiplier='+FSE_DinoCharacterHealthRecoveryMultiplier.Text);
      if (FSE_DinoCharacterStaminaDrainMultiplier.Value <> 1.0)          then Add('DinoCharacterStaminaDrainMultiplier='+FSE_DinoCharacterStaminaDrainMultiplier.Text);
      if (FSE_DinoDamageMultiplier.Value <> 1.0)                         then Add('DinoDamageMultiplier='+FSE_DinoDamageMultiplier.Text);
      if (FSE_DinoResistanceMultiplier.Value <> 1.0)                     then Add('DinoResistanceMultiplier='+FSE_DinoResistanceMultiplier.Text);
      if ChB_DisableDinoDecayPvE.Checked                                 then Add('DisableDinoDecayPvE=True');
      if ChB_DisableImprintDinoBuff.Checked                              then Add('DisableImprintDinoBuff=True');
      if ChB_DisablePvEGamma.Checked                                     then Add('DisablePvEGamma=True');
      if ChB_DisableStructureDecayPvE.Checked                            then Add('DisableStructureDecayPvE=True');
      if ChB_DisableWeatherFog.Checked                                   then Add('DisableWeatherFog=True');
      if ChB_DontAlwaysNotifyPlayerJoined.Checked                        then Add('DontAlwaysNotifyPlayerJoined=True');
      if ChB_EnableExtraStructurePreventionVolumes.Checked               then Add('EnableExtraStructurePreventionVolumes=True');
      if ChB_AutoDestroyDecayedDinos.Checked                             then Add('AutoDestroyDecayedDinos=True');
      if ChB_bForceCanRideFliers.Checked                                 then Add('bForceCanRideFliers=True');
      if ChB_EnablePvPGamma.Checked                                      then Add('EnablePvPGamma=True');
      if ChB_globalVoiceChat.Checked                                     then Add('globalVoiceChat=True');
      if (FSE_HarvestHealthMultiplier.Value <> 1.0)                      then Add('HarvestHealthMultiplier='+FSE_HarvestHealthMultiplier.Text);
      if (FSE_ItemStackSizeMultiplier.Value <> 1.0)                      then Add('ItemStackSizeMultiplier='+FSE_ItemStackSizeMultiplier.Text);
      if ChB_EnableIdlePlayerKick.Checked                                then Add('KickIdlePlayersPeriod='+FSE_KickIdlePlayersPeriod.Text);
      if (SE_MaxPersonalTamedDinos.Value <> 0)                           then Add('MaxPersonalTamedDinos='+SE_MaxPersonalTamedDinos.Text);
      if (FSE_MaxTamedDinos.Value <> 5000.0)                             then Add('MaxTamedDinos='+FSE_MaxTamedDinos.Text);
      if ChB_DestroyTamesOverTheSoftTameLimit.Checked                    then Add('DestroyTamesOverTheSoftTameLimit=True');
      if (SE_MaxTamedDinos_SoftTameLimit.Value <> 5000)                  then Add('MaxTamedDinos_SoftTameLimit='+SE_MaxTamedDinos_SoftTameLimit.Text);
      if (SE_MaxTamedDinos_SoftTameLimit_CountdownForDeletionDuration.Value <> 604800)then
                                                                              Add('MaxTamedDinos_SoftTameLimit_CountdownForDeletionDuration='+SE_MaxTamedDinos_SoftTameLimit_CountdownForDeletionDuration.Text);
      if (SE_MaxTributeDinos.Value <> 20)                                then Add('MaxTributeDinos='+SE_MaxTributeDinos.Text);
      if (SE_MaxTributeItems.Value <> 50)                                then Add('MaxTributeItems='+SE_MaxTributeItems.Text);
      if (SE_MaxTributeCharacters.Value <> 10)                           then Add('MaxTributeCharacters='+SE_MaxTributeCharacters.Text);
      if (SE_TributeItemExpirationSeconds.Value <> 86400)                then Add('TributeItemExpirationSeconds='+SE_TributeItemExpirationSeconds.Text);
      if (SE_TributeCharacterExpirationSeconds.Value <> 0)               then Add('TributeCharacterExpirationSeconds='+SE_TributeCharacterExpirationSeconds.Text);
      if (SE_TributeDinoExpirationSeconds.Value <> 86400)                then Add('TributeDinoExpirationSeconds='+SE_TributeDinoExpirationSeconds.Text);

      if CB_NonPermanentDiseases.Checked                                 then Add('NonPermanentDiseases=True');
      if (FSE_OverrideOfficialDifficulty.Value <> 0.0)                   then Add('OverrideOfficialDifficulty='+FSE_OverrideOfficialDifficulty.Text);
      if CB_OverrideStructurePlatformPrevention.Checked                  then Add('OverrideStructurePlatformPrevention=True');
      if (FSE_OxygenSwimSpeedStatMultiplier.Value <> 1.0)                then Add('OxygenSwimSpeedStatMultiplier='+FSE_OxygenSwimSpeedStatMultiplier.Text);
      if (FSE_PerPlatformMaxStructuresMultiplier.Value <> 1.0)           then Add('PerPlatformMaxStructuresMultiplier='+FSE_PerPlatformMaxStructuresMultiplier.Text);
      if (FSE_PlatformSaddleBuildAreaBoundsMultiplier.Value <> 1.0)      then Add('PlatformSaddleBuildAreaBoundsMultiplier='+FSE_PerPlatformMaxStructuresMultiplier.Text);
      if (FSE_PlayerCharacterFoodDrainMultiplier.Value <> 1.0)           then Add('PlayerCharacterFoodDrainMultiplier='+FSE_PlayerCharacterFoodDrainMultiplier.Text);
      if (FSE_PlayerCharacterHealthRecoveryMultiplier.Value <> 1.0)      then Add('PlayerCharacterHealthRecoveryMultiplier='+FSE_PlayerCharacterHealthRecoveryMultiplier.Text);
      if (FSE_PlayerCharacterStaminaDrainMultiplier.Value <> 1.0)        then Add('PlayerCharacterStaminaDrainMultiplier='+FSE_PlayerCharacterStaminaDrainMultiplier.Text);
      if (FSE_PlayerCharacterWaterDrainMultiplier.Value <> 1.0)          then Add('PlayerCharacterWaterDrainMultiplier='+FSE_PlayerCharacterWaterDrainMultiplier.Text);
      if (FSE_PlayerDamageMultiplier.Value <> 1.0)                       then Add('PlayerDamageMultiplier='+FSE_PlayerDamageMultiplier.Text);
      if (FSE_PlayerResistanceMultiplier.Value <> 1.0)                   then Add('PlayerResistanceMultiplier='+FSE_PlayerResistanceMultiplier.Text);
      if ChB_PreventDiseases.Checked                                     then Add('PreventDiseases=True');
      if ChB_PreventMateBoost.Checked                                    then Add('PreventMateBoost=True');
      if ChB_PreventOfflinePvP.Checked                                   then Add('PreventOfflinePvP=True');
      if (FSE_PreventOfflinePvPInterval.Value <> 0.0)                    then Add('PreventOfflinePvPInterval='+FSE_PreventOfflinePvPInterval.Text);
      if ChB_IgnorePVPMountedWeaponryRestrictions.Checked                then Add('IgnorePVPMountedWeaponryRestrictions=True');
      if ChB_AllowTeslaCoilCaveBuildingPVP.Checked                       then Add('AllowTeslaCoilCaveBuildingPVP=True');
      if ChB_PreventSpawnAnimations.Checked                              then Add('PreventSpawnAnimations=True');
      if ChB_PreventTribeAlliances.Checked                               then Add('PreventTribeAlliances=True');
      if ChB_ProximityChat.Checked                                       then Add('ProximityChat=True');
      if ChB_PvEAllowStructuresAtSupplyDrops.Checked                     then Add('PvEAllowStructuresAtSupplyDrops=True');
      if (FSE_PvEDinoDecayPeriodMultiplier.Value <> 1.0)                 then Add('PvEDinoDecayPeriodMultiplier='+FSE_PvEDinoDecayPeriodMultiplier.Text);
      if ChB_PvPDinoDecay.Checked                                        then Add('PvPDinoDecay=True');
      if ChB_PvPStructureDecay.Checked                                   then Add('PvPStructureDecay=True');
      if (FSE_RaidDinoCharacterFoodDrainMultiplier.Value <> 1.0)         then Add('RaidDinoCharacterFoodDrainMultiplier='+FSE_RaidDinoCharacterFoodDrainMultiplier.Text);
      if ChB_RandomSupplyCratePoints.Checked                             then Add('RandomSupplyCratePoints=True');
      if CB_RCONEnabled.Checked                                          then Add('RCONEnabled=True');
      if not (ChB_RCONPort_Args.Checked)                                 then Add('RCONPort='+SE_RCONPort.Text);
     {if (FSE_RCONServerGameLogBuffer.Value <> 600.0)                    then}Add('RCONServerGameLogBuffer='+FSE_RCONServerGameLogBuffer.Text);
      if (FSE_ResourcesRespawnPeriodMultiplier.Value <> 1.0)             then Add('ResourcesRespawnPeriodMultiplier='+FSE_ResourcesRespawnPeriodMultiplier.Text);
      if Edit_ServerAdminPassword.Text<>''                               then Add('ServerAdminPassword='+Edit_ServerAdminPassword.Text);
      if not ChB_ServerCrosshair.Checked                                 then Add('ServerCrosshair=False');
      if ChB_ServerForceNoHUD.Checked                                    then Add('ServerForceNoHUD=True');
      if ChB_ServerHardcore.Checked                                      then Add('ServerHardcore=True');
      if Edit_ServerPassword.Text<>''                                    then Add('ServerPassword='+Edit_ServerPassword.Text);
      if ChB_serverPVE.Checked                                           then Add('serverPVE=True');
      if ChB_ShowFloatingDamageText.Checked                              then Add('ShowFloatingDamageText=True');
      if not ChB_ShowMapPlayerLocation.Checked                           then Add('ShowMapPlayerLocation=False');
      if (FSE_StructurePickupHoldDuration.Value <> 0.5)                  then Add('StructurePickupHoldDuration='+FSE_StructurePickupHoldDuration.Text);
      if (FSE_StructurePickupTimeAfterPlacement.Value <> 30.0)           then Add('StructurePickupTimeAfterPlacement='+FSE_StructurePickupTimeAfterPlacement.Text);
      if (FSE_StructurePreventResourceRadiusMultiplier.Value <> 1.0)     then Add('StructurePreventResourceRadiusMultiplier='+FSE_StructurePreventResourceRadiusMultiplier.Text);
      if (FSE_StructureResistanceMultiplier.Value <> 1.0)                then Add('StructureResistanceMultiplier='+FSE_StructureResistanceMultiplier.Text);
      if (SE_TheMaxStructuresInRange.Value <> 10500)                     then Add('TheMaxStructuresInRange='+SE_TheMaxStructuresInRange.Text);
      if (FSE_TribeNameChangeCooldown.Value <> 15.0)                     then Add('TribeNameChangeCooldown='+FSE_TribeNameChangeCooldown.Text);
      if ChB_noTributeDownloads.Checked                                  then Add('noTributeDownloads=True');
      if ChB_CrossARKAllowForeignDinoDownloads.Checked                   then Add('ChB_CrossARKAllowForeignDinoDownloads=True');
      if ChB_PreventDownloadDinos.Checked                                then Add('PreventDownloadDinos=True');
      if ChB_PreventDownloadItems.Checked                                then Add('PreventDownloadItems=True');
      if ChB_PreventDownloadSurvivors.Checked                            then Add('PreventDownloadSurvivors=True');
      if ChB_PreventUploadDinos.Checked                                  then Add('PreventUploadDinos=True');
      if ChB_PreventUploadItems.Checked                                  then Add('PreventUploadItems=True');
      if ChB_PreventUploadSurvivors.Checked                              then Add('PreventUploadSurvivors=True');
      if ChB_DisableCryopodEnemyCheck.Checked                            then Add('DisableCryopodEnemyCheck=True');
      if ChB_AllowCryoFridgeOnSaddle.Checked                             then Add('AllowCryoFridgeOnSaddle=True');
      if ChB_DisableCryopodFridgeRequirement.Checked                     then Add('DisableCryopodFridgeRequirement=True');
      if (SE_CryopodFridgeCooldowntime.Value <> 90)                      then Add('CryopodFridgeCooldowntime='+SE_CryopodFridgeCooldowntime.Text);

      if ChB_EnableCryopodNerf.Checked                                   then Add('EnableCryopodNerf=True');
      if ChB_EnableCryoSicknessPVE.Checked                               then Add('EnableCryoSicknessPVE=True');
      if (FSE_CryopodNerfDamageMult.Value <> 0.01)                       then Add('CryopodNerfDamageMult='+FSE_CryopodNerfDamageMult.Text);
      if (FSE_CryopodNerfDuration.Value <> 0.0)                          then Add('CryopodNerfDuration='+FSE_CryopodNerfDuration.Text);
      if (FSE_CryopodNerfIncomingDamageMultPercent.Value <> 0.0)         then Add('CryopodNerfIncomingDamageMultPercent='+FSE_CryopodNerfIncomingDamageMultPercent.Text);

      if (FSE_DinoCountMultiplier.Value <> 1.0)                          then Add('DinoCountMultiplier='+FSE_DinoCountMultiplier.Text);
      if (FSE_StructureDamageMultiplier.Value <> 1.0)                    then Add('StructureDamageMultiplier='+FSE_StructureDamageMultiplier.Text);
      if ChB_AlwaysNotifyPlayerLeft.Checked                              then Add('AlwaysNotifyPlayerLeft=True');
      if (FSE_PvEStructureDecayPeriodMultiplier.Value <> 1.0)            then Add('PvEStructureDecayPeriodMultiplier='+FSE_PvEStructureDecayPeriodMultiplier.Text);
      if ChB_OverrideStartTime.Checked                                   then Add('OverrideStartTime=True');
      if (FSE_StartTimeHour.Value <> 10.0)                               then Add('StartTimeHour='+FSE_StartTimeHour.Text);
      if (FSE_TamedDinoDamageMultiplier.Value <> 1.0)                    then Add('TamedDinoDamageMultiplier='+FSE_TamedDinoDamageMultiplier.Text);
      if (FSE_TamedDinoResistanceMultiplier.Value <> 1.0)                then Add('TamedDinoResistanceMultiplier='+FSE_TamedDinoResistanceMultiplier.Text);
      if (SE_MaxTrainCars.Value <> 8)                                    then Add('MaxTrainCars='+SE_MaxTrainCars.Text);
      if (SE_ImplantSuicideCD.Value <> 28800)                            then Add('ImplantSuicideCD='+SE_ImplantSuicideCD.Text);
      if (FSE_AutoDestroyOldStructuresMultiplier.Value <> 1.0)           then Add('AutoDestroyOldStructuresMultiplier='+FSE_AutoDestroyOldStructuresMultiplier.Text);

      if ChB_AllowCrateSpawnsOnTopOfStructures.Checked                   then Add('AllowCrateSpawnsOnTopOfStructures=True');
      if ChB_ForceAllStructureLocking.Checked                            then Add('ForceAllStructureLocking=True');

      if (SE_MaxCosmoWeaponAmmo.Value <> 0)                              then Add('MaxCosmoWeaponAmmo='+SE_MaxCosmoWeaponAmmo.Text);
      if (SE_CosmoWeaponAmmoReloadAmount.Value <> 0)                     then Add('CosmoWeaponAmmoReloadAmount='+SE_CosmoWeaponAmmoReloadAmount.Text);
      if (FSE_OverrideBondedPassImprintMultiplier.Value <> 0.0)          then Add('OverrideBondedPassImprintMultiplier='+FSE_OverrideBondedPassImprintMultiplier.Text);
      if (SE_MaxPlatformSaddleStructureLimit.Value <> 75)                then Add('MaxPlatformSaddleStructureLimit='+SE_MaxPlatformSaddleStructureLimit.Text);
      if (SE_MaxGateFrameOnSaddles.Value <> -1)                          then Add('MaxGateFrameOnSaddles='+SE_MaxGateFrameOnSaddles.Text);

      if (FSE_UpdateAllowedCheatersInterval.Value <> 600.0)              then Add('UpdateAllowedCheatersInterval='+FSE_UpdateAllowedCheatersInterval.Text);
      if (FSE_ServerAutoForceRespawnWildDinosInterval.Value <> 0.0)      then Add('ServerAutoForceRespawnWildDinosInterval='+FSE_ServerAutoForceRespawnWildDinosInterval.Text);
      if ChB_UseCharacterTracker.Checked                                 then Add('UseCharacterTracker=True');
      if ChB_ForceExploitedTameDeletion.Checked                          then Add('ForceExploitedTameDeletion=True');
      if (FSE_AutoRestartIntervalSeconds.Value <> 0.0)                   then Add('AutoRestartIntervalSeconds='+FSE_AutoRestartIntervalSeconds.Text);
      if (Edit_BadWordListURL.Text <> '')                                then Add('BadWordListURL='+Edit_BadWordListURL.Text);
      if (Edit_BadWordWhiteListURL.Text <> '')                           then Add('BadWordWhiteListURL='+Edit_BadWordWhiteListURL.Text);
      if (Edit_AdminListURL.Text <> '')                                  then Add('AdminListURL='+Edit_AdminListURL.Text);
      if (Edit_BanListURL.Text <> '')                                    then Add('BanListURL='+Edit_BanListURL.Text);
      if (Edit_CustomLiveTuningUrl.Text <> '')                           then Add('CustomLiveTuningUrl='+Edit_CustomLiveTuningUrl.Text);
      if (SE_MaxHexagonsPerCharacter.Value <> 2000000000)                then Add('MaxHexagonsPerCharacter='+SE_MaxHexagonsPerCharacter.Text);

      if ChB_WorldBossKingKaijuSpawnTime_UTC.Checked then
      begin
        Add('WorldBossKingKaijuSpawnTime='+Edit_WorldBossKingKaijuSpawnTime.Text);
      end else begin
        ihh := -1;
        imm := -1;
        iss := -1;
        try
          ihh := StrToIntDef(FormatdateTime('hh',(StrToDateTime(Edit_WorldBossKingKaijuSpawnTime.Text))),-1);
          imm := StrToIntDef(FormatdateTime('nn',(StrToDateTime(Edit_WorldBossKingKaijuSpawnTime.Text))),-1);
          iss := StrToIntDef(FormatdateTime('ss',(StrToDateTime(Edit_WorldBossKingKaijuSpawnTime.Text))),-1);
        except
        end;
        if (ihh <> -1) and (imm <> -1) and (iss <> -1) then
        begin
          ihh := (ihh +15) mod 24;
          Add('WorldBossKingKaijuSpawnTime='+format('%2.2d:%2.2d:%2.2d',[ihh,imm,iss]));
        end;
      end;
      if not ChB_ForceGachaUnhappyInCaves.Checked                        then Add('ForceGachaUnhappyInCaves=false');
      if not ChB_bAllowFlyerDinoSubmerging.Checked                       then Add('bAllowFlyerDinoSubmerging=false')
                                                                         else Add('bAllowFlyerDinoSubmerging=True');
      if (SE_ArmadoggoDeathCooldown.Value <> 3600)                       then Add('ArmadoggoDeathCooldown='+SE_ArmadoggoDeathCooldown.Text);
      if (SE_YoungIceFoxDeathCooldown.Value <> 3600)                     then Add('YoungIceFoxDeathCooldown='+SE_YoungIceFoxDeathCooldown.Text);
      if (SE_CompanionsDeathCooldown.Value <> 3600)                      then Add('CompanionsDeathCooldown='+SE_CompanionsDeathCooldown.Text);

      if (SE_MaxBlueprintDinoLevel.Value <> 0)                           then Add('MaxBlueprintDinoLevel='+SE_MaxBlueprintDinoLevel.Text);
      if (SE_MaxBlueprintDinoQuality.Value <> 0)                         then Add('MaxBlueprintDinoQuality='+SE_MaxBlueprintDinoQuality.Text);
      if (SE_MaxBlueprintItemQuality.Value <> 0)                         then Add('MaxBlueprintItemQuality='+SE_MaxBlueprintItemQuality.Text);
      if (SE_MaxBlueprintScoutQuality.Value <> 0)                        then Add('MaxBlueprintScoutQuality='+SE_MaxBlueprintScoutQuality.Text);

      if (ChB_ER_Tame.Checked) then                                           Add('TamingSpeedMultiplier='+FloatToStr(FSE_TamingSpeedMultiplier.Value * FSE_ER_Tame.Value))
          else if (FSE_TamingSpeedMultiplier.Value <> 1.0)               then Add('TamingSpeedMultiplier='           +FSE_TamingSpeedMultiplier.Text);
      if (ChB_ER_Harvesting.Checked) then                                     Add('HarvestAmountMultiplier='+FloatToStr(FSE_HarvestAmountMultiplier.Value * FSE_ER_Harvesting.Value))
          else if (FSE_HarvestAmountMultiplier.Value <> 1.0)             then Add('HarvestAmountMultiplier='           +FSE_HarvestAmountMultiplier.Text);
      if (ChB_ER_Experience.Checked) then                                     Add('XPMultiplier='+FloatToStr(FSE_XPMultiplier.Value * FSE_ER_Experience.Value))
          else if (FSE_XPMultiplier.Value <> 1.0)                        then Add('XPMultiplier='           +FSE_XPMultiplier.Text);

      if (RG_Cosmetic_Kind.ItemIndex = 1) then                                Add('CosmeticWhitelistOverride="URL"');
      if (RG_Cosmetic_Kind.ItemIndex = 2) then                                Add('CosmeticWhitelistOverride="' + Edit_Cosmetic_URL.Text + '"');
      if (RG_Cosmetic_Kind.ItemIndex = 3) then                                Add('CosmeticWhitelistOverride="' + Edit_Cosmetic_LocalFile.Text + '\CosmeticWhitelist.txt"');
      if (RG_Cosmetic_Kind.ItemIndex = 4) then
      begin
        str := 'CosmeticWhitelistOverride=' + SG_Cosmetic.Cols[0].CommaText;
        str := stringReplace(str,'CosmeticWhitelistOverride=,','CosmeticWhitelistOverride=',[rfReplaceAll, rfIgnoreCase]);
        Add(str);
      end;

      if (FSE_TribeTowerBonusMultiplier.Value <> 0.0)                    then Add('TribeTowerBonusMultiplier='+FSE_TribeTowerBonusMultiplier.Text);

      if ChB_LimitBunkersPerTribe.Checked                                then Add('LimitBunkersPerTribe=True')
                                                                         else Add('LimitBunkersPerTribe=False');
      if (SE_LimitBunkersPerTribeNum.Value <> 0)                         then Add('LimitBunkersPerTribeNum='+SE_LimitBunkersPerTribeNum.Text);
      if ChB_AllowBunkersInPreventionZones.Checked                       then Add('AllowBunkersInPreventionZones=True')
                                                                         else Add('AllowBunkersInPreventionZones=False');
      if ChB_AllowRidingDinosInsideBunkers.Checked                       then Add('AllowRidingDinosInsideBunkers=True')
                                                                         else Add('AllowRidingDinosInsideBunkers=False');
      if ChB_AllowBunkerModulesAboveGround.Checked                       then Add('AllowBunkerModulesAboveGround=True')
                                                                         else Add('AllowBunkerModulesAboveGround=False');
      if ChB_AllowDinoAIInsideBunkers.Checked                            then Add('AllowDinoAIInsideBunkers=True')
                                                                         else Add('AllowDinoAIInsideBunkers=False');
      if ChB_AllowBunkerModulesInPreventionZones.Checked                 then Add('AllowBunkerModulesInPreventionZones=True')
                                                                         else Add('AllowBunkerModulesInPreventionZones=False');
      if (FSE_MinDistanceBetweenBunkers.Value <> 0.0)                    then Add('MinDistanceBetweenBunkers='+FSE_MinDistanceBetweenBunkers.Text);
      if (FSE_EnemyAccessBunkerHPThreshold.Value <> 0.0)                 then Add('EnemyAccessBunkerHPThreshold='+FSE_EnemyAccessBunkerHPThreshold.Text);
      if (FSE_BunkerUnderHPThresholdDmgMultiplier.Value <> 0.0)          then Add('BunkerUnderHPThresholdDmgMultiplier='+FSE_BunkerUnderHPThresholdDmgMultiplier.Text);

      if (FSE_CryoHospitalHoursToRegenHP.Value <> 0.0)                   then Add('CryoHospitalHoursToRegenHP='+FSE_CryoHospitalHoursToRegenHP.Text);
      if (FSE_CryoHospitalHoursToRegenFood.Value <> 0.0)                 then Add('CryoHospitalHoursToRegenFood='+FSE_CryoHospitalHoursToRegenFood.Text);
      if (FSE_CryoHospitalHoursToDrainTorpor.Value <> 0.0)               then Add('CryoHospitalHoursToDrainTorpor='+FSE_CryoHospitalHoursToDrainTorpor.Text);
      if (FSE_CryoHospitalMatingCooldownReduction.Value <> 0.0)          then Add('CryoHospitalMatingCooldownReduction='+FSE_CryoHospitalMatingCooldownReduction.Text);

      if (FSE_BloodforgeReinforceExtraDurability.Value <> 0.0)           then Add('BloodforgeReinforceExtraDurability='+FSE_BloodforgeReinforceExtraDurability.Text);
      if (FSE_BloodforgeReinforceResourceCostMultiplier.Value <> 0.0)    then Add('BloodforgeReinforceResourceCostMultiplier='+FSE_BloodforgeReinforceResourceCostMultiplier.Text);
      if (FSE_BloodforgeReinforceSpeedMultiplier.Value <> 0.0)           then Add('BloodforgeReinforceSpeedMultiplier='+FSE_BloodforgeReinforceSpeedMultiplier.Text);

      if (SE_MaxActiveOutposts.Value <> 0.0)                             then Add('MaxActiveOutposts='+SE_MaxActiveOutposts.Text);
      if (SE_MaxActiveResourceCaches.Value <> 0.0)                       then Add('MaxActiveResourceCaches='+SE_MaxActiveResourceCaches.Text);
      if (SE_MaxActiveCityOutposts.Value <> 0.0)                         then Add('MaxActiveCityOutposts='+SE_MaxActiveCityOutposts.Text);

                                                                              Add('');
                                                                              Add('[SessionSettings]');
      if not (ChB_Port_Args.Checked)                                     then Add('Port='+SE_Port.Text);
      if not (ChB_Queryport_Args.Checked)                                then Add('QueryPort='+SE_QueryPort.Text);
      if Edit_SessionName.Text<>''                                       then Add('SessionName='+Edit_SessionName.Text);

                                                                              Add('');
                                                                              Add('[MessageOfTheDay]');
      if Edit_Message.Text<>''                                           then Add('Message='+Edit_Message.Text);
      if (SE_Duration.Value <> 20)                                       then Add('Duration='+SE_Duration.Text);

      if (ChB_Mod1_Enabled.Checked) then
      begin
                                                                              Add('');
                                                                              Add('[Cryopods]');
        if ChB_Mod1_ForceUseINISettings.Checked                          then Add('ForceUseINISettings=True')
                                                                         else Add('ForceUseINISettings=False');
        if ChB_Mod1_DisableCryoSickness.Checked                          then Add('DisableCryoSickness=True')
                                                                         else Add('DisableCryoSickness=False');
        if ChB_Mod1_PreventDeployInCaves.Checked                         then Add('PreventDeployInCaves=True')
                                                                         else Add('PreventDeployInCaves=False');
      {if (FSE_Mod1_CryoTime.Value <> 5.0)                              then} Add('CryoTime='+FSE_Mod1_CryoTime.Text);
      {if (FSE_Mod1_CryoTimeInCombat.Value <> 5.0)                      then} Add('CryoTimeInCombat='+FSE_Mod1_CryoTimeInCombat.Text);
      {if (SE_Mod1_CryoSicknessTimer.Value <> 300)                      then} Add('CryoSicknessTimer='+SE_Mod1_CryoSicknessTimer.Text);
        if ChB_Mod1_DisableAutoCycle.Checked                             then Add('DisableAutoCycle=True')
                                                                         else Add('DisableAutoCycle=False');
      {if (SE_Mod1_CryogunRangeFoundations.Value <> 10)                 then} Add('CryogunRangeFoundations='+SE_Mod1_CryogunRangeFoundations.Text);
      {if (SE_Mod1_CryogunCooldownSeconds.Value <> 0)                   then} Add('CryogunCooldownSeconds='+SE_Mod1_CryogunCooldownSeconds.Text);
      {if (SE_Mod1_NeutergunRangeFoundations.Value <> 10)               then} Add('NeutergunRangeFoundations='+SE_Mod1_NeutergunRangeFoundations.Text);
      {if (SE_Mod1_NeutergunCooldownSeconds.Value <> 0)                 then} Add('NeutergunCooldownSeconds='+SE_Mod1_NeutergunCooldownSeconds.Text);
        if ChB_Mod1_DisableCryopodsRequirement.Checked                   then Add('DisableCryopodsRequirement=True')
                                                                         else Add('DisableCryopodsRequirement=False');
      {if (FSE_Mod1_CryoTerminalCaptureInterval.Value <> 1.0)           then} Add('CryoTerminalCaptureInterval='+FSE_Mod1_CryoTerminalCaptureInterval.Text);
      {if (SE_Mod1_CryoTerminalMaxRadiusFoundations.Value <> 100)       then} Add('CryoTerminalMaxRadiusFoundations='+SE_Mod1_CryoTerminalMaxRadiusFoundations.Text);
        if ChB_Mod1_PassImprintToDeployer.Checked                        then Add('PassImprintToDeployer=True')
                                                                         else Add('PassImprintToDeployer=False');
      {if (SE_Mod1_ImprintAmountToGive.Value <> 0)                      then} Add('ImprintAmountToGive='+SE_Mod1_ImprintAmountToGive.Text);
        if ChB_Mod1_FullyGrownBabies.Checked                             then Add('FullyGrownBabies=True')
                                                                         else Add('FullyGrownBabies=False');
        if ChB_Mod1_AllowCryoterminalOnPlatforms.Checked                 then Add('AllowCryoterminalOnPlatforms=True')
                                                                         else Add('AllowCryoterminalOnPlatforms=False');
        if ChB_Mod1_AllowAdminCaptureAll.Checked                         then Add('AllowAdminCaptureAll=True')
                                                                         else Add('AllowAdminCaptureAll=False');
      {if (SE_Mod1_MaxCryoterminalsInRange.Value <> 1)                  then} Add('MaxCryoterminalsInRange='+SE_Mod1_MaxCryoterminalsInRange.Text);
      {if (SE_Mod1_LimitCryoterminalsRange.Value <> 100)                then} Add('LimitCryoterminalsRange='+SE_Mod1_LimitCryoterminalsRange.Text);
        if ChB_Mod1_AllowDeployInBossArenas.Checked                      then Add('AllowDeployInBossArenas=True')
                                                                         else Add('AllowDeployInBossArenas=False');
      {if (FSE_Mod1_CryopodChargeSpeedMultiplier.Value <> 1.0)          then} Add('CryopodChargeSpeedMultiplier='+FSE_Mod1_CryopodChargeSpeedMultiplier.Text);
        if ChB_Mod1_DisableCryopodChargeNeed.Checked                     then Add('DisableCryopodChargeNeed=True')
                                                                         else Add('DisableCryopodChargeNeed=False');
        if ChB_Mod1_GiveTemporaryCryopodsInCryoterminal.Checked          then Add('GiveTemporaryCryopodsInCryoterminal=True')
                                                                         else Add('GiveTemporaryCryopodsInCryoterminal=False');
      {if (SE_Mod1_CryofridgeInventorySlots.Value <> 72)                then} Add('CryofridgeInventorySlots='+SE_Mod1_CryofridgeInventorySlots.Text);
      {if (SE_Mod1_CryoterminalInventorySlots.Value <> 300)             then} Add('CryoterminalInventorySlots='+SE_Mod1_CryoterminalInventorySlots.Text);
      end;

      if (ChB_Mod2_Enabled.Checked) then
      begin
                                                                              Add('');
                                                                              Add('[SuperSpyglassPlus]');
        if ChB_Mod2_DisableNightVision.Checked                           then Add('DisableNightVision=True')
                                                                         else Add('DisableNightVision=False');
        if ChB_Mod2_DisablePredatorVision.Checked                        then Add('DisablePredatorVision=True')
                                                                         else Add('DisablePredatorVision=False');
        if ChB_Mod2_DisableOutlineMode.Checked                           then Add('DisableOutlineMode=True')
                                                                         else Add('DisableOutlineMode=False');
        if ChB_Mod2_DisableSupplyDropInfo.Checked                        then Add('DisableSupplyDropInfo=True')
                                                                         else Add('DisableSupplyDropInfo=False');
        if ChB_Mod2_DisableItembagInfo.Checked                           then Add('DisableItembagInfo=True')
                                                                         else Add('DisableItembagInfo=False');
        if ChB_Mod2_DisableStructureInfo.Checked                         then Add('DisableStructureInfo=True')
                                                                         else Add('DisableStructureInfo=False');
        if ChB_Mod2_DisableBuffInfo.Checked                              then Add('DisableBuffInfo=True')
                                                                         else Add('DisableBuffInfo=False');
        if ChB_Mod2_DisableTameFoodInfo.Checked                          then Add('DisableTameFoodInfo=True')
                                                                         else Add('DisableTameFoodInfo=False');
        if ChB_Mod2_DisableEggInfo.Checked                               then Add('DisableEggInfo=True')
                                                                         else Add('DisableEggInfo=False');
        if ChB_Mod2_DisableTheSpyglassOnEnemyTribes.Checked              then Add('DisableTheSpyglassOnEnemyTribes=True')
                                                                         else Add('DisableTheSpyglassOnEnemyTribes=False');
        if ChB_Mod2_OnlyShowStatsForTames.Checked                        then Add('OnlyShowStatsForTames=True')
                                                                         else Add('OnlyShowStatsForTames=False');
        if ChB_Mod2_DisableGPS.Checked                                   then Add('DisableGPS=True')
                                                                         else Add('DisableGPS=False');
        if ChB_Mod2_DisableCrosshair.Checked                             then Add('DisableCrosshair=True')
                                                                         else Add('DisableCrosshair=False');
        if ChB_Mod2_OnlyHPonEnemyTribeDinos.Checked                      then Add('OnlyHPonEnemyTribeDinos=True')
                                                                         else Add('OnlyHPonEnemyTribeDinos=False');
      {if (SE_Mod2_OutlineRange.Value <> 15000)                         then} Add('OutlineRange='+SE_Mod2_OutlineRange.Text);
        if ChB_Mod2_UseESPOutline.Checked                                then Add('UseESPOutline=True')
                                                                         else Add('UseESPOutline=False');
        if ChB_Mod2_UseESPOutlineFill.Checked                            then Add('UseESPOutlineFill=True')
                                                                         else Add('UseESPOutlineFill=False');
        if ChB_Mod2_DontShowAnyStatsOnWildDino.Checked                   then Add('DontShowAnyStatsOnWildDino=True')
                                                                         else Add('DontShowAnyStatsOnWildDino=False');
      end;

      if (ChB_Mod3_Enabled.Checked) then
      begin
                                                                              Add('');
                                                                              Add('[DerDinoFinder]');
        if ChB_Mod3_IsAdminOnly.Checked                                  then Add('IsAdminOnly=True')
                                                                         else Add('IsAdminOnly=False');
      {if (SE_Mod3_MarkerLimit.Value <> 15)                             then} Add('MarkerLimit='+SE_Mod3_MarkerLimit.Text);
      end;

      if (ChB_Mod5_Enabled.Checked) then
      begin
                                                                              Add('');
                                                                              Add('[QoLPlus]');
        if CB_Mod5_RemoveFloorRequirementFromStructurePlacement.Checked  then Add('RemoveFloorRequirementFromStructurePlacement=True')
                                                                         else Add('RemoveFloorRequirementFromStructurePlacement=False');
        if CB_Mod5_DisableResourcePulling.Checked                        then Add('DisableResourcePulling=True')
                                                                         else Add('DisableResourcePulling=False');
       {if (FSE_Mod5_ResourceTransferCooldown.Value <> 1.0)             then} Add('ResourceTransferCooldown='+FSE_Mod5_ResourceTransferCooldown.Text);
        if ChB_Mod5_PullingIgnoresPinCodes.Checked                       then Add('PullingIgnoresPinCodes=True')
                                                                         else Add('PullingIgnoresPinCodes=False');
        if ChB_Mod5_EnableExtendedDeathCache.Checked                     then Add('EnableExtendedDeathCache=True')
                                                                         else Add('EnableExtendedDeathCache=False');
        if ChB_Mod5_EnableUpdateDurability.Checked                       then Add('EnableUpdateDurability=True')
                                                                         else Add('EnableUpdateDurability=False');
        if ChB_Mod5_AllowTekItemBlueprintCreation.Checked                then Add('AllowTekItemBlueprintCreation=True')
                                                                         else Add('AllowTekItemBlueprintCreation=False');
        if ChB_Mod5_AllowMakingWeaponsAndArmorBPs.Checked                then Add('AllowMakingWeaponsAndArmorBPs=True')
                                                                         else Add('AllowMakingWeaponsAndArmorBPs=False');
        if ChB_Mod5_DisableMultiToolDinoKillMode.Checked                 then Add('DisableMultiToolDinoKillMode=True')
                                                                         else Add('DisableMultiToolDinoKillMode=False');
        if ChB_Mod5_DisableMultiToolDinoChibiMode.Checked                then Add('DisableMultiToolDinoChibiMode=True')
                                                                         else Add('DisableMultiToolDinoChibiMode=False');
        if ChB_Mod5_AllowMultiToolNeuterAll.Checked                      then Add('AllowMultiToolNeuterAll=True')
                                                                         else Add('AllowMultiToolNeuterAll=False');
        if ChB_Mod5_AllowGrindingMissionRewards.Checked                  then Add('AllowGrindingMissionRewards=True')
                                                                         else Add('AllowGrindingMissionRewards=False');
        if ChB_Mod5_EnableStructureSound.Checked                         then Add('EnableStructureSound=True')
                                                                         else Add('EnableStructureSound=False');
        if ChB_Mod5_DisableBlueprintInstall.Checked                      then Add('DisableBlueprintInstall=True')
                                                                         else Add('DisableBlueprintInstall=False');
       {if (SE_Mod5_PropagatorFuelInterval.Value <> 86400)              then} Add('PropagatorFuelInterval='+SE_Mod5_PropagatorFuelInterval.Text);
       {if (SE_Mod5_PropagatorModCostMutate.Value <> 1)                 then} Add('PropagatorModCostMutate='+SE_Mod5_PropagatorModCostMutate.Text);
        if ChB_Mod5_PropagatorDisableDinoMods.Checked                    then Add('PropagatorDisableDinoMods=True')
                                                                         else Add('PropagatorDisableDinoMods=False');
        if ChB_Mod5_PropagatorRespectMutationLimit.Checked               then Add('PropagatorRespectMutationLimit=True')
                                                                         else Add('PropagatorRespectMutationLimit=False');
        if ChB_Mod5_PropagatorDisableEggDrop.Checked                     then Add('PropagatorDisableEggDrop=True')
                                                                         else Add('PropagatorDisableEggDrop=False');
       {if (SE_Mod5_TribePropagatorLimit.Value <> 0)                    then} Add('TribePropagatorLimit='+SE_Mod5_TribePropagatorLimit.Text);
       {if (SE_Mod5_NannyMaxImprint.Value <> 100)                       then} Add('NannyMaxImprint='+SE_Mod5_NannyMaxImprint.Text);
        if ChB_Mod5_DisableNannyImprinting.Checked                       then Add('DisableNannyImprinting=True')
                                                                         else Add('DisableNannyImprinting=False');
       {if (SE_Mod5_NannyIntervalInSeconds.Value <> 35)                 then} Add('NannyIntervalInSeconds='+SE_Mod5_NannyIntervalInSeconds.Text);
       {if (SE_Mod5_NannyFeedingStartThreshold.Value <> 20)             then} Add('NannyFeedingStartThreshold='+SE_Mod5_NannyFeedingStartThreshold.Text);
       {if (SE_Mod5_BeeHiveHoneyIntervalInSeconds.Value <> 180)         then} Add('BeeHiveHoneyIntervalInSeconds='+SE_Mod5_BeeHiveHoneyIntervalInSeconds.Text);
       {if (SE_Mod5_MutatorBuffMaxStackCount.Value <> 2)                then} Add('MutatorBuffMaxStackCount='+SE_Mod5_MutatorBuffMaxStackCount.Text);
        if ChB_Mod5_MutatorAllowBreedingNeutered.Checked                 then Add('MutatorAllowBreedingNeutered=True')
                                                                         else Add('MutatorAllowBreedingNeutered=False');
        if ChB_Mod5_DisableHitchingPostMatingBonus.Checked               then Add('DisableHitchingPostMatingBonus=True')
                                                                         else Add('DisableHitchingPostMatingBonus=False');
       {if (SE_Mod5_HitchingPostRange.Value <> 4)                       then} Add('HitchingPostRange='+SE_Mod5_HitchingPostRange.Text);
       {if (SE_Mod5_HitchingPostDinoLimit.Value <> 0)                   then} Add('HitchingPostDinoLimit='+SE_Mod5_HitchingPostDinoLimit.Text);
       {if (SE_Mod5_HitchingPostTribeLimit.Value <> 0)                  then} Add('HitchingPostTribeLimit='+SE_Mod5_HitchingPostTribeLimit.Text);
       {if (SE_Mod5_GrinderResourceReturnPercent.Value <> 30)           then} Add('GrinderResourceReturnPercent='+SE_Mod5_GrinderResourceReturnPercent.Text);
       {if (SE_Mod5_GrinderResourceReturnMax.Value <> 10000)            then} Add('GrinderResourceReturnMax='+SE_Mod5_GrinderResourceReturnMax.Text);
        if ChB_Mod5_GrinderReturnBlockedResources.Checked                then Add('GrinderReturnBlockedResources=True')
                                                                         else Add('GrinderReturnBlockedResources=False');
       {if (SE_Mod5_SmallStorageSlotCount.Value <> 30)                  then} Add('SmallStorageSlotCount='+SE_Mod5_SmallStorageSlotCount.Text);
       {if (SE_Mod5_LargeStorageSlotCount.Value <> 90)                  then} Add('LargeStorageSlotCount='+SE_Mod5_LargeStorageSlotCount.Text);
       {if (SE_Mod5_MetalStorageSlotCount.Value <> 100)                 then} Add('MetalStorageSlotCount='+SE_Mod5_MetalStorageSlotCount.Text);
       {if (SE_Mod5_PropagatorSlotCount.Value <> 100)                   then} Add('PropagatorSlotCount='+SE_Mod5_PropagatorSlotCount.Text);
       {if (SE_Mod5_NannySlotCount.Value <> 100)                        then} Add('NannySlotCount='+SE_Mod5_NannySlotCount.Text);
       {if (SE_Mod5_TransmutatorSlotCount.Value <> 100)                 then} Add('TransmutatorSlotCount='+SE_Mod5_TransmutatorSlotCount.Text);
       {if (SE_Mod5_GardenerSlotCount.Value <> 300)                     then} Add('GardenerSlotCount='+SE_Mod5_GardenerSlotCount.Text);
       {if (SE_Mod5_FarmerSlotCount.Value <> 300)                       then} Add('FarmerSlotCount='+SE_Mod5_FarmerSlotCount.Text);
       {if (SE_Mod5_BeeHiveSlotCount.Value <> 24)                       then} Add('BeeHiveSlotCount='+SE_Mod5_BeeHiveSlotCount.Text);
       {if (SE_Mod5_AmmoBoxSlotCount.Value <> 300)                      then} Add('AmmoBoxSlotCount='+SE_Mod5_AmmoBoxSlotCount.Text);
       {if (SE_Mod5_GrinderSlotCount.Value <> 200)                      then} Add('GrinderSlotCount='+SE_Mod5_GrinderSlotCount.Text);
       {if (SE_Mod5_IndustrialForgeSlotCount.Value <> 100)              then} Add('IndustrialForgeSlotCount='+SE_Mod5_IndustrialForgeSlotCount.Text);
       {if (SE_Mod5_GeneratorSlotCount.Value <> 8)                      then} Add('GeneratorSlotCount='+SE_Mod5_GeneratorSlotCount.Text);
       {if (SE_Mod5_ReplicatorSlotCount.Value <> 600)                   then} Add('ReplicatorSlotCount='+SE_Mod5_ReplicatorSlotCount.Text);
       {if (SE_Mod5_FridgeSlotCount.Value <> 150)                       then} Add('FridgeSlotCount='+SE_Mod5_FridgeSlotCount.Text);
       {if (SE_Mod5_PreservingBinSlotCount.Value <> 50)                 then} Add('PreservingBinSlotCount='+SE_Mod5_PreservingBinSlotCount.Text);
       {if (SE_Mod5_FabricatorSlotCount.Value <> 300)                   then} Add('FabricatorSlotCount='+SE_Mod5_FabricatorSlotCount.Text);
       {if (SE_Mod5_TekGeneratorSlotCount.Value <> 100)                 then} Add('TekGeneratorSlotCount='+SE_Mod5_TekGeneratorSlotCount.Text);
       {if (FSE_Mod5_RaidTimerLimitMultiplier.Value <> 1.0)             then} Add('RaidTimerLimitMultiplier='+FSE_Mod5_RaidTimerLimitMultiplier.Text);
       {if (FSE_Mod5_PropagatorMatingSpeedMultiplier.Value <> 1.0)      then} Add('PropagatorMatingSpeedMultiplier='+FSE_Mod5_PropagatorMatingSpeedMultiplier.Text);
       {if (FSE_Mod5_PropagatorMatingIntervalMultiplier.Value <> 1.0)   then} Add('PropagatorMatingIntervalMultiplier='+FSE_Mod5_PropagatorMatingIntervalMultiplier.Text);
       {if (FSE_Mod5_GrinderScaleMultiplier.Value <> 1.0)               then} Add('GrinderScaleMultiplier='+FSE_Mod5_GrinderScaleMultiplier.Text);
       {if (FSE_Mod5_IndustrialForgeScaleMultiplier.Value <> 1.0)       then} Add('IndustrialForgeScaleMultiplier='+FSE_Mod5_IndustrialForgeScaleMultiplier.Text);
       {if (FSE_Mod5_ReplicatorScaleMultiplier.Value <> 1.3)            then} Add('ReplicatorScaleMultiplier='+FSE_Mod5_ReplicatorScaleMultiplier.Text);
       {if (SE_Mod5_GrinderCraftingSpeed.Value <> 1)                    then} Add('GrinderCraftingSpeed='+SE_Mod5_GrinderCraftingSpeed.Text);
       {if (SE_Mod5_IndustrialForgeCraftingSpeed.Value <> 1)            then} Add('IndustrialForgeCraftingSpeed='+SE_Mod5_IndustrialForgeCraftingSpeed.Text);
       {if (SE_Mod5_ReplicatorCraftingSpeed.Value <> 12)                then} Add('ReplicatorCraftingSpeed='+SE_Mod5_ReplicatorCraftingSpeed.Text);
       {if (SE_Mod5_FridgeCraftingSpeed.Value <> 1)                     then} Add('FridgeCraftingSpeed='+SE_Mod5_FridgeCraftingSpeed.Text);
       {if (SE_Mod5_PreservingBinCraftingSpeed.Value <> 1)              then} Add('PreservingBinCraftingSpeed='+SE_Mod5_PreservingBinCraftingSpeed.Text);
       {if (SE_Mod5_FabricatorCraftingSpeed.Value <> 1)                 then} Add('FabricatorCraftingSpeed='+SE_Mod5_FabricatorCraftingSpeed.Text);
       {if (SE_Mod5_ResourcePullRangeInFoundations.Value <> 25)         then} Add('ResourcePullRangeInFoundations='+SE_Mod5_ResourcePullRangeInFoundations.Text);
       {if (SE_Mod5_BeeHiveWateringRangeInFoundations.Value <> 30)      then} Add('BeeHiveWateringRangeInFoundations='+SE_Mod5_BeeHiveWateringRangeInFoundations.Text);
       {if (SE_Mod5_MaxMutatorRangeInFoundations.Value <> 50)           then} Add('MaxMutatorRangeInFoundations='+SE_Mod5_MaxMutatorRangeInFoundations.Text);
       {if (SE_Mod5_MaxPowerRangeInFoundations.Value <> 50)             then} Add('MaxPowerRangeInFoundations='+SE_Mod5_MaxPowerRangeInFoundations.Text);
       {if (SE_Mod5_GardenerRangeInFoundations.Value <> 25)             then} Add('GardenerRangeInFoundations='+SE_Mod5_GardenerRangeInFoundations.Text);
       {if (SE_Mod5_FarmerRangeInFoundations.Value <> 25)               then} Add('FarmerRangeInFoundations='+SE_Mod5_FarmerRangeInFoundations.Text);
       {if (SE_Mod5_NannyRangeInFoundations.Value <> 10)                then} Add('NannyRangeInFoundations='+SE_Mod5_NannyRangeInFoundations.Text);
        sl := TStringList.Create;
        try
          for i:= 0 to CG_Mod5_MutatorModeBlacklist.Items.Count -1 do
          begin
            if (CG_Mod5_MutatorModeBlacklist.Checked[i]) then sl.Add(CG_Mod5_MutatorModeBlacklist.Items[i]);
          end;
        finally
          Add('MutatorModeBlacklist='+sl.CommaText);
          sl.free;
        end;
       {if Edit_Mod5_MutatorPulseCost.Text<>''                          then} Add('MutatorPulseCost='+Edit_Mod5_MutatorPulseCost.Text);
       {if Edit_Mod5_MutatorPulseCooldowns.Text<>''                     then} Add('MutatorPulseCooldowns='+Edit_Mod5_MutatorPulseCooldowns.Text);
       {if Edit_Mod5_MutatorDinoBlacklist.Text<>''                      then} Add('MutatorDinoBlacklist='+Edit_Mod5_MutatorDinoBlacklist.Text);
       {if Edit_Mod5_PullResourceAdditions.Text<>''                     then} Add('PullResourceAdditions='+Edit_Mod5_PullResourceAdditions.Text);
       {if Edit_Mod5_PullResourceRemovals.Text<>''                      then} Add('PullResourceRemovals='+Edit_Mod5_PullResourceRemovals.Text);
       {if Edit_Mod5_AdvTransferItemBlacklist.Text<>''                  then} Add('AdvTransferItemBlacklist='+Edit_Mod5_AdvTransferItemBlacklist.Text);
       {if Edit_Mod5_QoLPlusEngramWhitelist.Text<>''                    then} Add('QoLPlusEngramWhitelist='+Edit_Mod5_QoLPlusEngramWhitelist.Text);
       {if Edit_Mod5_OmniToolBlacklist.Text<>''                         then} Add('OmniToolBlacklist='+Edit_Mod5_OmniToolBlacklist.Text);
       {if Edit_Mod5_MultiToolBlacklist.Text<>''                        then} Add('MultiToolBlacklist='+Edit_Mod5_MultiToolBlacklist.Text);
       {if Edit_Mod5_PropagatorDinoBlacklist.Text<>''                   then} Add('PropagatorDinoBlacklist='+Edit_Mod5_PropagatorDinoBlacklist.Text);
       {if Edit_Mod5_PropagatorFuelClass.Text<>''                       then} Add('PropagatorFuelClass='+Edit_Mod5_PropagatorFuelClass.Text);
       {if Edit_Mod5_PropagatorModCostItemClass.Text<>''                then} Add('PropagatorModCostItemClass='+Edit_Mod5_PropagatorModCostItemClass.Text);
      end;
    end;
  finally
    Memo_GameUserSettings.Text:=vMemo.Text;
    vMemo.Free;
  end;
  Memo_GameUserSettings.EndUpdateBounds;
end;

procedure TAsaFrame.createGameIni;
var
  //sl2,sl3   :TStringList;
  i             :Integer;
  str1,str2,str3:string;
  str4,str5,str6:string;
  str7          :string;
  vMemo         :TStringList;
begin
  Memo_GameIni.BeginUpdateBounds;
  Memo_GameIni.Clear;
  vMemo := TStringList.Create;
  try
    with vMemo do
    begin
                                                                              Add('[/Script/ShooterGame.ShooterGameMode]');
      if (FSE_BabyCuddleGracePeriodMultiplier.Value <> 1.0)              then Add('BabyCuddleGracePeriodMultiplier='+FSE_BabyCuddleGracePeriodMultiplier.Text);
      if (FSE_BabyCuddleLoseImprintQualitySpeedMultiplier.Value <> 1.0)  then Add('BabyCuddleLoseImprintQualitySpeedMultiplier='+FSE_BabyCuddleLoseImprintQualitySpeedMultiplier.Text);
      if (FSE_BabyFoodConsumptionSpeedMultiplier.Value <> 1.0)           then Add('BabyFoodConsumptionSpeedMultiplier='+FSE_BabyFoodConsumptionSpeedMultiplier.Text);
      if (FSE_BabyImprintingStatScaleMultiplier.Value <> 1.0)            then Add('BabyImprintingStatScaleMultiplier='+FSE_BabyImprintingStatScaleMultiplier.Text);
      if (FSE_LayEggIntervalMultiplier.Value <> 1.0)                     then Add('LayEggIntervalMultiplier='+FSE_LayEggIntervalMultiplier.Text);
      if ChB_bAllowUnlimitedRespecs.Checked                              then Add('bAllowUnlimitedRespecs=True');
      if ChB_bDisableFriendlyFire.Checked                                then Add('bDisableFriendlyFire=True');
      if ChB_bPvEDisableFriendlyFire.Checked                             then Add('bPvEDisableFriendlyFire=True');
      if ChB_bUseSingleplayerSettings.Checked                            then Add('bUseSingleplayerSettings=True');
      if (FSE_CraftingSkillBonusMultiplier.Value <> 1.0)                 then Add('CraftingSkillBonusMultiplier='+FSE_CraftingSkillBonusMultiplier.Text);
      if (FSE_CraftXPMultiplier.Value <> 1.0)                            then Add('CraftXPMultiplier='+FSE_CraftXPMultiplier.Text);
      if (FSE_CropDecaySpeedMultiplier.Value <> 1.0)                     then Add('CropDecaySpeedMultiplier='+FSE_CropDecaySpeedMultiplier.Text);
      if (FSE_CropGrowthSpeedMultiplier.Value <> 1.0)                    then Add('CropGrowthSpeedMultiplier='+FSE_CropGrowthSpeedMultiplier.Text);
      if (FSE_CustomRecipeEffectivenessMultiplier.Value <> 1.0)          then Add('CustomRecipeEffectivenessMultiplier='+FSE_CustomRecipeEffectivenessMultiplier.Text);
      if (FSE_CustomRecipeSkillMultiplier.Value <> 1.0)                  then Add('CustomRecipeSkillMultiplier='+FSE_CustomRecipeSkillMultiplier.Text);
      if (SE_DestroyTamesOverLevelClamp.Value <> 0)                      then Add('DestroyTamesOverLevelClamp='+SE_DestroyTamesOverLevelClamp.Text);
      if (FSE_GlobalItemDecompositionTimeMultiplier.Value <> 1.0)        then Add('GlobalItemDecompositionTimeMultiplier='+FSE_GlobalItemDecompositionTimeMultiplier.Text);
      if (FSE_GlobalSpoilingTimeMultiplier.Value <> 1.0)                 then Add('GlobalSpoilingTimeMultiplier='+FSE_GlobalSpoilingTimeMultiplier.Text);
      if (FSE_GenericXPMultiplier.Value <> 1.0)                          then Add('GenericXPMultiplier='+FSE_GenericXPMultiplier.Text);
      if (FSE_HarvestXPMultiplier.Value <> 1.0)                          then Add('HarvestXPMultiplier='+FSE_HarvestXPMultiplier.Text);
      if (FSE_KillXPMultiplier.Value <> 1.0)                             then Add('KillXPMultiplier='+FSE_KillXPMultiplier.Text);
      if (FSE_SpecialXPMultiplier.Value <> 1.0)                          then Add('SpecialXPMultiplier='+FSE_SpecialXPMultiplier.Text);
      if (FSE_ExplorerNoteXPMultiplier.Value <> 1.0)                     then Add('ExplorerNoteXPMultiplier='+FSE_ExplorerNoteXPMultiplier.Text);
      if (FSE_BossKillXPMultiplier.Value <> 1.0)                         then Add('BossKillXPMultiplier='+FSE_BossKillXPMultiplier.Text);
      if (FSE_CaveKillXPMultiplier.Value <> 1.0)                         then Add('CaveKillXPMultiplier='+FSE_CaveKillXPMultiplier.Text);
      if (FSE_WildKillXPMultiplier.Value <> 1.0)                         then Add('WildKillXPMultiplier='+FSE_WildKillXPMultiplier.Text);
      if (FSE_TamedKillXPMultiplier.Value <> 1.0)                        then Add('TamedKillXPMultiplier='+FSE_TamedKillXPMultiplier.Text);
      if (FSE_UnclaimedKillXPMultiplier.Value <> 1.0)                    then Add('UnclaimedKillXPMultiplier='+FSE_UnclaimedKillXPMultiplier.Text);
      if (FSE_AlphaKillXPMultiplier.Value <> 1.0)                        then Add('AlphaKillXPMultiplier='+FSE_AlphaKillXPMultiplier.Text);
      if (FSE_PoopIntervalMultiplier.Value <> 1.0)                       then Add('PoopIntervalMultiplier='+FSE_PoopIntervalMultiplier.Text);
      if (FSE_PlayerHarvestingDamageMultiplier.Value <> 1.0)             then Add('PlayerHarvestingDamageMultiplier='+FSE_PlayerHarvestingDamageMultiplier.Text);
      if (FSE_ResourceNoReplenishRadiusPlayers.Value <> 1.0)             then Add('ResourceNoReplenishRadiusPlayers='+FSE_ResourceNoReplenishRadiusPlayers.Text);
      if (FSE_ResourceNoReplenishRadiusStructures.Value <> 1.0)          then Add('ResourceNoReplenishRadiusStructures='+FSE_ResourceNoReplenishRadiusStructures.Text);
      if (FSE_DinoHarvestingDamageMultiplier.Value <> 3.2)               then Add('DinoHarvestingDamageMultiplier='+FSE_DinoHarvestingDamageMultiplier.Text);
      if (FSE_DinoTurretDamageMultiplier.Value <> 1.0)                   then Add('DinoTurretDamageMultiplier='+FSE_DinoTurretDamageMultiplier.Text);
      if (SE_StructureDamageRepairCooldown.Value <> 180.0)               then Add('StructureDamageRepairCooldown='+SE_StructureDamageRepairCooldown.Text);
      if ChB_bDisableStructurePlacementCollision.Checked                 then Add('bDisableStructurePlacementCollision=True');
      if ChB_bIgnoreStructuresPreventionVolumes.Checked                  then Add('bIgnoreStructuresPreventionVolumes=True');
      if ChB_bAllowSpeedLeveling.Checked                                 then Add('bAllowSpeedLeveling=True')
                                                                         else Add('bAllowSpeedLeveling=False');
      if ChB_bAllowFlyerSpeedLeveling.Checked                            then Add('bAllowFlyerSpeedLeveling=True');
      if (ChB_bUseCorpseLocator.Checked <> true)                         then Add('bUseCorpseLocator=False');
      if ChB_bAllowPlatformSaddleMultiFloors.Checked                     then Add('bAllowPlatformSaddleMultiFloors=True');
      if ChB_bAllowFlyerSpeedLeveling.Checked                            then Add('bAllowFlyerSpeedLeveling=True');
      if ChB_bDisableDinoRiding.Checked                                  then Add('bDisableDinoRiding=True');
      if ChB_bDisableDinoTaming.Checked                                  then Add('bDisableDinoTaming=True');
      if ChB_bDisableDinoBreeding.Checked                                then Add('bDisableDinoBreeding=True');
      if ChB_bAutoUnlockAllEngrams.Checked                               then Add('bAutoUnlockAllEngrams=True');
      if ChB_bShowCreativeMode.Checked                                   then Add('bShowCreativeMode=True');
      if ChB_bDisableLootCrates.Checked                                  then Add('bDisableLootCrates=True');
      if ChB_bAutoPvETimer.Checked                                       then Add('bAutoPvETimer=True');
      if (SE_AutoPvEStartTimeSeconds.Value <> 0)                         then Add('AutoPvEStartTimeSeconds='+SE_AutoPvEStartTimeSeconds.Text);
      if (SE_AutoPvEStopTimeSeconds.Value <> 0)                          then Add('AutoPvEStopTimeSeconds='+SE_AutoPvEStopTimeSeconds.Text);
      if ChB_bAutoPvEUseSystemTime.Checked                               then Add('bAutoPvEUseSystemTime=True');
      if ChB_bPvEAllowTribeWar.Checked                                   then Add('bPvEAllowTribeWar=True');
      if ChB_bPvEAllowTribeWarCancel.Checked                             then Add('bPvEAllowTribeWarCancel=True');
      if ChB_bIncreasePvPRespawnInterval.Checked                         then Add('bIncreasePvPRespawnInterval=True');
      if (FSE_IncreasePvPRespawnIntervalCheckPeriod.Value <> 120.0)      then Add('IncreasePvPRespawnIntervalCheckPeriod='+FSE_IncreasePvPRespawnIntervalCheckPeriod.Text);
      if (FSE_IncreasePvPRespawnIntervalMultiplier.Value <> 2.0)         then Add('IncreasePvPRespawnIntervalMultiplier='+FSE_IncreasePvPRespawnIntervalMultiplier.Text);
      if (FSE_IncreasePvPRespawnIntervalBaseAmount.Value <> 60.0)        then Add('IncreasePvPRespawnIntervalBaseAmount='+FSE_IncreasePvPRespawnIntervalBaseAmount.Text);
      if (SE_PvPZoneStructureDamageMultiplier.Value <> 6)                then Add('PvPZoneStructureDamageMultiplier='+SE_PvPZoneStructureDamageMultiplier.Text);
      if (FSE_GlobalCorpseDecompositionTimeMultiplier.Value <> 1.0)      then Add('GlobalCorpseDecompositionTimeMultiplier='+FSE_GlobalCorpseDecompositionTimeMultiplier.Text);
      if (SE_MaxNumberOfPlayersInTribe.Value <> 0)                       then Add('MaxNumberOfPlayersInTribe='+SE_MaxNumberOfPlayersInTribe.Text);
      if (SE_OverrideMaxExperiencePointsPlayer.Value <> 0)               then Add('OverrideMaxExperiencePointsPlayer='+SE_OverrideMaxExperiencePointsPlayer.Text);
      if (SE_OverrideMaxExperiencePointsDino.Value <> 0)                 then Add('OverrideMaxExperiencePointsDino='+SE_OverrideMaxExperiencePointsDino.Text);
      if ChB_MaxDifficulty.Checked                                       then Add('MaxDifficulty=True');
      if ChB_OnlyAllowSpecifiedEngrams.Checked                           then Add('bOnlyAllowSpecifiedEngrams=True');

      if not ChB_bAllowFlyerDinoSubmerging.Checked                       then Add('bAllowFlyerDinoSubmerging=false')
                                                                         else Add('bAllowFlyerDinoSubmerging=True');

      if (SE_PhotoModeRangeLimit.Value <> 3000)                          then Add('PhotoModeRangeLimit='+SE_PhotoModeRangeLimit.Text);
      if ChB_bAllowCustomRecipes.Checked                                 then Add('bAllowCustomRecipes=True');
      if ChB_bAllowBuildingInNoBuildZone.Checked                         then Add('bAllowBuildingInNoBuildZone=True');

      if (SE_LimitNonPlayerDroppedItemsCount.Value <> 0)                 then Add('LimitNonPlayerDroppedItemsCount='+SE_LimitNonPlayerDroppedItemsCount.Text);
      if (SE_LimitNonPlayerDroppedItemsRange.Value <> 0)                 then Add('LimitNonPlayerDroppedItemsRange='+SE_LimitNonPlayerDroppedItemsRange.Text);
      if ChB_bHardLimitTurretsInRange.Checked                            then Add('bHardLimitTurretsInRange=True');
      if not ChB_bLimitTurretsInRange.Checked                            then Add('bLimitTurretsInRange=Flase');
      if (SE_LimitTurretsNum.Value <> 100)                               then Add('LimitTurretsNum='+SE_LimitTurretsNum.Text);
      if (FSE_LimitTurretsRange.Value <> 10000.0)                        then Add('LimitTurretsRange='+FSE_LimitTurretsRange.Text);

      if ChB_bFlyerPlatformAllowUnalignedDinoBasing.Checked              then Add('bFlyerPlatformAllowUnalignedDinoBasing=True');
      if ChB_bPassiveDefensesDamageRiderlessDinos.Checked                then Add('bPassiveDefensesDamageRiderlessDinos=True');
      if (FSE_SupplyCrateLootQualityMultiplier.Value <> 1.0)             then Add('SupplyCrateLootQualityMultiplier='+FSE_SupplyCrateLootQualityMultiplier.Text);
      if (FSE_FishingLootQualityMultiplier.Value <> 1.0)                 then Add('FishingLootQualityMultiplier='+FSE_FishingLootQualityMultiplier.Text);
      if (FSE_BaseTemperatureMultiplier.Value <> 1.0)                    then Add('BaseTemperatureMultiplier='+FSE_BaseTemperatureMultiplier.Text);
      if (FSE_FuelConsumptionIntervalMultiplier.Value <> 1.0)            then Add('FuelConsumptionIntervalMultiplier='+FSE_FuelConsumptionIntervalMultiplier.Text);
      if (FSE_MaxFallSpeedMultiplier.Value <> 1.0)                       then Add('MaxFallSpeedMultiplier='+FSE_MaxFallSpeedMultiplier.Text);
      if (FSE_UseCorpseLifeSpanMultiplier.Value <> 1.0)                  then Add('UseCorpseLifeSpanMultiplier='+FSE_UseCorpseLifeSpanMultiplier.Text);
      if (FSE_TamedDinoCharacterFoodDrainMultiplier.Value <> 1.0)        then Add('TamedDinoCharacterFoodDrainMultiplier='+FSE_TamedDinoCharacterFoodDrainMultiplier.Text);
      if (FSE_TamedDinoTorporDrainMultiplier.Value <> 1.0)               then Add('TamedDinoTorporDrainMultiplier='+FSE_TamedDinoTorporDrainMultiplier.Text);
      if (FSE_MatingSpeedMultiplier.Value <> 1.0)                        then Add('MatingSpeedMultiplier='+FSE_MatingSpeedMultiplier.Text);
      if (FSE_PassiveTameIntervalMultiplier.Value <> 1.0)                then Add('PassiveTameIntervalMultiplier='+FSE_PassiveTameIntervalMultiplier.Text);
      if (FSE_WildDinoCharacterFoodDrainMultiplier.Value <> 1.0)         then Add('WildDinoCharacterFoodDrainMultiplier='+FSE_WildDinoCharacterFoodDrainMultiplier.Text);
      if (FSE_WildDinoTorporDrainMultiplier.Value <> 1.0)                then Add('WildDinoTorporDrainMultiplier='+FSE_WildDinoTorporDrainMultiplier.Text);
      if not ChB_bUseDinoLevelUpAnimations.Checked                       then Add('bUseDinoLevelUpAnimations=False');
      if ChB_bDisablePhotoMode.Checked                                   then Add('bDisablePhotoMode=True');
      if (FSE_HexagonCostMultiplier.Value <> 1.0)                        then Add('HexagonCostMultiplier='+FSE_HexagonCostMultiplier.Text);
      if (ChB_ER_Breeding.Checked) then
      begin
                                                                              Add('BabyMatureSpeedMultiplier='   +FloatToStr(FSE_BabyMatureSpeedMultiplier.Value    * FSE_ER_Breeding.Value));
                                                                              Add('EggHatchSpeedMultiplier='     +FloatToStr(FSE_EggHatchSpeedMultiplier.Value      * FSE_ER_Breeding.Value));
                                                                              Add('BabyImprintAmountMultiplier=' +FloatToStr(FSE_BabyImprintAmountMultiplier.Value  * FSE_ER_Breeding.Value));
                                                                              Add('MatingIntervalMultiplier='    +FloatToStr(FSE_MatingIntervalMultiplier.Value     * FSE_ER_Breeding2.Value));
                                                                              Add('BabyCuddleIntervalMultiplier='+FloatToStr(FSE_BabyCuddleIntervalMultiplier.Value * FSE_ER_Breeding3.Value));
      end else begin
        if (FSE_BabyMatureSpeedMultiplier.Value <> 1.0)                  then Add('BabyMatureSpeedMultiplier='              +FSE_BabyMatureSpeedMultiplier.Text);
        if (FSE_EggHatchSpeedMultiplier.Value <> 1.0)                    then Add('EggHatchSpeedMultiplier='                +FSE_EggHatchSpeedMultiplier.Text);
        if (FSE_BabyImprintAmountMultiplier.Value <> 1.0)                then Add('BabyImprintAmountMultiplier='            +FSE_BabyImprintAmountMultiplier.Text);
        if (FSE_MatingIntervalMultiplier.Value <> 1.0)                   then Add('MatingIntervalMultiplier='               +FSE_MatingIntervalMultiplier.Text);
        if (FSE_BabyCuddleIntervalMultiplier.Value <> 1.0)               then Add('BabyCuddleIntervalMultiplier='           +FSE_BabyCuddleIntervalMultiplier.Text);
      end;
      if (ChB_ER_Hexagons.Checked) then                                       Add('BaseHexagonRewardMultiplier='+FloatToStr(FSE_BaseHexagonRewardMultiplier.Value * FSE_ER_Hexagons.Value))
            else if (FSE_BaseHexagonRewardMultiplier.Value <> 1.0)       then Add('BaseHexagonRewardMultiplier='           +FSE_BaseHexagonRewardMultiplier.Text);

                                                                              Add('PerLevelStatsMultiplier_Player[0]='+FSE_PerLevelStatsMultiplier_Player0.Text);
                                                                              Add('PerLevelStatsMultiplier_Player[1]='+FSE_PerLevelStatsMultiplier_Player1.Text);
                                                                              Add('PerLevelStatsMultiplier_Player[2]='+FSE_PerLevelStatsMultiplier_Player2.Text);
                                                                              Add('PerLevelStatsMultiplier_Player[3]='+FSE_PerLevelStatsMultiplier_Player3.Text);
                                                                              Add('PerLevelStatsMultiplier_Player[4]='+FSE_PerLevelStatsMultiplier_Player4.Text);
                                                                              Add('PerLevelStatsMultiplier_Player[5]='+FSE_PerLevelStatsMultiplier_Player5.Text);
                                                                              Add('PerLevelStatsMultiplier_Player[6]='+FSE_PerLevelStatsMultiplier_Player6.Text);
                                                                              Add('PerLevelStatsMultiplier_Player[7]='+FSE_PerLevelStatsMultiplier_Player7.Text);
                                                                              Add('PerLevelStatsMultiplier_Player[8]='+FSE_PerLevelStatsMultiplier_Player8.Text);
                                                                              Add('PerLevelStatsMultiplier_Player[9]='+FSE_PerLevelStatsMultiplier_Player9.Text);
                                                                              Add('PerLevelStatsMultiplier_Player[10]='+FSE_PerLevelStatsMultiplier_Player10.Text);
                                                                              Add('PerLevelStatsMultiplier_Player[11]='+FSE_PerLevelStatsMultiplier_Player11.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoTamed[0]='+FSE_PerLevelStatsMultiplier_DinoTamed0.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoTamed[1]='+FSE_PerLevelStatsMultiplier_DinoTamed1.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoTamed[2]='+FSE_PerLevelStatsMultiplier_DinoTamed2.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoTamed[3]='+FSE_PerLevelStatsMultiplier_DinoTamed3.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoTamed[4]='+FSE_PerLevelStatsMultiplier_DinoTamed4.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoTamed[5]='+FSE_PerLevelStatsMultiplier_DinoTamed5.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoTamed[6]='+FSE_PerLevelStatsMultiplier_DinoTamed6.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoTamed[7]='+FSE_PerLevelStatsMultiplier_DinoTamed7.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoTamed[8]='+FSE_PerLevelStatsMultiplier_DinoTamed8.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoTamed[9]='+FSE_PerLevelStatsMultiplier_DinoTamed9.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoTamed[10]='+FSE_PerLevelStatsMultiplier_DinoTamed10.Text);
                                                                              //Add('PerLevelStatsMultiplier_DinoTamed[11]='+FSE_PerLevelStatsMultiplier_DinoTamed11.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoTamed_Add[0]='+FSE_PerLevelStatsMultiplier_DinoTamed_Add0.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoTamed_Add[1]='+FSE_PerLevelStatsMultiplier_DinoTamed_Add1.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoTamed_Add[2]='+FSE_PerLevelStatsMultiplier_DinoTamed_Add2.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoTamed_Add[3]='+FSE_PerLevelStatsMultiplier_DinoTamed_Add3.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoTamed_Add[4]='+FSE_PerLevelStatsMultiplier_DinoTamed_Add4.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoTamed_Add[5]='+FSE_PerLevelStatsMultiplier_DinoTamed_Add5.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoTamed_Add[6]='+FSE_PerLevelStatsMultiplier_DinoTamed_Add6.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoTamed_Add[7]='+FSE_PerLevelStatsMultiplier_DinoTamed_Add7.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoTamed_Add[8]='+FSE_PerLevelStatsMultiplier_DinoTamed_Add8.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoTamed_Add[9]='+FSE_PerLevelStatsMultiplier_DinoTamed_Add9.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoTamed_Add[10]='+FSE_PerLevelStatsMultiplier_DinoTamed_Add10.Text);
                                                                              //Add('PerLevelStatsMultiplier_DinoTamed_Add[11]='+FSE_PerLevelStatsMultiplier_DinoTamed_Affinity0.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoTamed_Affinity[0]='+FSE_PerLevelStatsMultiplier_DinoTamed_Affinity0.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoTamed_Affinity[1]='+FSE_PerLevelStatsMultiplier_DinoTamed_Affinity1.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoTamed_Affinity[2]='+FSE_PerLevelStatsMultiplier_DinoTamed_Affinity2.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoTamed_Affinity[3]='+FSE_PerLevelStatsMultiplier_DinoTamed_Affinity3.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoTamed_Affinity[4]='+FSE_PerLevelStatsMultiplier_DinoTamed_Affinity4.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoTamed_Affinity[5]='+FSE_PerLevelStatsMultiplier_DinoTamed_Affinity5.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoTamed_Affinity[6]='+FSE_PerLevelStatsMultiplier_DinoTamed_Affinity6.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoTamed_Affinity[7]='+FSE_PerLevelStatsMultiplier_DinoTamed_Affinity7.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoTamed_Affinity[8]='+FSE_PerLevelStatsMultiplier_DinoTamed_Affinity8.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoTamed_Affinity[9]='+FSE_PerLevelStatsMultiplier_DinoTamed_Affinity9.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoTamed_Affinity[10]='+FSE_PerLevelStatsMultiplier_DinoTamed_Affinity10.Text);
                                                                              //Add('PerLevelStatsMultiplier_DinoTamed_Affinity[11]='+FSE_PerLevelStatsMultiplier_DinoTamed_Affinity11.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoWild[0]='+FSE_PerLevelStatsMultiplier_DinoWild0.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoWild[1]='+FSE_PerLevelStatsMultiplier_DinoWild1.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoWild[2]='+FSE_PerLevelStatsMultiplier_DinoWild2.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoWild[3]='+FSE_PerLevelStatsMultiplier_DinoWild3.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoWild[4]='+FSE_PerLevelStatsMultiplier_DinoWild4.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoWild[5]='+FSE_PerLevelStatsMultiplier_DinoWild5.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoWild[6]='+FSE_PerLevelStatsMultiplier_DinoWild6.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoWild[7]='+FSE_PerLevelStatsMultiplier_DinoWild7.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoWild[8]='+FSE_PerLevelStatsMultiplier_DinoWild8.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoWild[9]='+FSE_PerLevelStatsMultiplier_DinoWild9.Text);
                                                                              Add('PerLevelStatsMultiplier_DinoWild[10]='+FSE_PerLevelStatsMultiplier_DinoWild10.Text);
                                                                              //Add('PerLevelStatsMultiplier_DinoWild[11]='+FSE_PerLevelStatsMultiplier_DinoWild11.Text);
                                                                              Add('PlayerBaseStatMultipliers[0]='+FSE_PlayerBaseStatMultipliers0.Text);
                                                                              Add('PlayerBaseStatMultipliers[1]='+FSE_PlayerBaseStatMultipliers1.Text);
                                                                              Add('PlayerBaseStatMultipliers[2]='+FSE_PlayerBaseStatMultipliers2.Text);
                                                                              Add('PlayerBaseStatMultipliers[3]='+FSE_PlayerBaseStatMultipliers3.Text);
                                                                              Add('PlayerBaseStatMultipliers[4]='+FSE_PlayerBaseStatMultipliers4.Text);
                                                                              Add('PlayerBaseStatMultipliers[5]='+FSE_PlayerBaseStatMultipliers5.Text);
                                                                              Add('PlayerBaseStatMultipliers[6]='+FSE_PlayerBaseStatMultipliers6.Text);
                                                                              Add('PlayerBaseStatMultipliers[7]='+FSE_PlayerBaseStatMultipliers7.Text);
                                                                              Add('PlayerBaseStatMultipliers[8]='+FSE_PlayerBaseStatMultipliers8.Text);
                                                                              Add('PlayerBaseStatMultipliers[9]='+FSE_PlayerBaseStatMultipliers9.Text);
                                                                              Add('PlayerBaseStatMultipliers[10]='+FSE_PlayerBaseStatMultipliers10.Text);
                                                                              Add('PlayerBaseStatMultipliers[11]='+FSE_PlayerBaseStatMultipliers11.Text);

      //NPCReplacements
      for i:=1 to SL_SpawnList2.RowCount -1 do
      begin
        str1 := SL_SpawnList2.Cells[1,i];
        str2 := SL_SpawnList2.Cells[5,i];
        if (str1<>str2) then
        begin
          Add(format('NPCReplacements=(FromClassName="%s",ToClassName="%s")',[str1,str2]));
        end;
      end;

      //OverrideNamedEngramEntries
      for i:=1 to SL_OverrideNamedEngramEntries.RowCount-1 do
      begin
        if (SL_OverrideNamedEngramEntries.Cells[4,i]='') then continue;
        if (SL_OverrideNamedEngramEntries.Cells[5,i]='') then continue;
        str1 := format('%s=%s,%s,%s,%s',[SL_OverrideNamedEngramEntries.Cells[1,i],
                                         SL_OverrideNamedEngramEntries.Cells[2,i],
                                         SL_OverrideNamedEngramEntries.Cells[9,i],
                                         SL_OverrideNamedEngramEntries.Cells[4,i],
                                         SL_OverrideNamedEngramEntries.Cells[5,i]]);
        str2 := format('%s=%s',[SL_OverrideNamedEngramEntries.Cells[1,i],SL_OverrideNamedEngramEntries.Columns[0].PickList.Values[SL_OverrideNamedEngramEntries.Cells[1,i]]]);
        if (str1<>str2) or
           (SL_OverrideNamedEngramEntries.Cells[3,i]<> '0') or
           (SL_OverrideNamedEngramEntries.Cells[6,i]<> '0') then
        begin
          str3 := format('EngramClassName="%s"',[SL_OverrideNamedEngramEntries.Cells[2,i]]);
          if (SL_OverrideNamedEngramEntries.Cells[3,i]<> '0') then str4 := ',EngramHidden=True';
          str5 := format(',EngramPointsCost="%s"',[SL_OverrideNamedEngramEntries.Cells[4,i]]);
          str6 := format(',EngramLevelRequirement="%s"',[SL_OverrideNamedEngramEntries.Cells[5,i]]);
          if (SL_OverrideNamedEngramEntries.Cells[6,i]<> '0') then str7 := ',RemoveEngramPreReq=True';
          Add(format('OverrideNamedEngramEntries=(%s%s%s%s%s)',[str3,str4,str5,str6,str7]));
        end;
      end;

      Add('');
      Add('[ShooterGameMode_TEMPOverrides]');
      Add('');
    end;
  finally
    Memo_GameIni.Text:=vMemo.Text;
    vMemo.Free;
  end;
  Memo_GameIni.EndUpdateBounds;
end;

procedure TAsaFrame.saveProfile;
var
  dataset  :TMemIniFile;
  i        :Integer;
  rowcnt   :Integer;
  str      :string;
  sec      :string;
  sl       :TStringList;
begin
  Edit_ModsExit(Edit_Mods);

  if flg_backup then dataset := TMemIniFile.Create('Profile\Backup\Saved\Profile.ini')
                else dataset := TMemIniFile.Create('Profile\'+Edit_Profile.Text+'.ini');
  try
    //dataset.EraseSection('ASASM');
    //dataset.EraseSection('General');
    //dataset.EraseSection('Server');
    //dataset.EraseSection('World');
    //dataset.EraseSection('VisualHUD');
    //dataset.EraseSection('Player');
    //dataset.EraseSection('TamedDino');
    //dataset.EraseSection('Wiladino');
    //dataset.EraseSection('Spawn');
    //dataset.EraseSection('Spawn2');
    //dataset.EraseSection('Structure');
    //dataset.EraseSection('Engrams');
    //dataset.EraseSection('XP');
    //dataset.EraseSection('iniFiles');
    //dataset.EraseSection('Experimental');
    with dataset do
    begin
      sec := 'ASASM';
      begin
        WriteString (sec,'Appversion'         ,AppVer);
        WriteBool   (sec,'ChB_AutoRestart'    ,ChB_AutoRestart.Checked);
        WriteInteger(sec,'Button_SetIni_Color',Pnl_SetIni.Color);
      end;

      sec := 'General';
      begin
        WriteString (sec,'Edit_Profile',                                        Edit_Profile.Text);
        begin
          WriteBool   (sec,'ChB_RelativePath',                                  ChB_RelativePath.Checked);
          if (ChB_RelativePath.Checked) and (Pos(ExtractFilePath(ParamStr(0)),Edit_Install_Location_Val.Text) = 1) then
          begin
            WriteString (sec,'Edit_Install_Location_Val',                       stringReplace(Edit_Install_Location_Val.Text,ExtractFilePath(ParamStr(0)),'',[rfIgnoreCase]));
            WriteBool   (sec,'Sys_RelativePath',                                true);
          end else begin
            WriteString (sec,'Edit_Install_Location_Val',                       Edit_Install_Location_Val.Text);
            WriteBool   (sec,'Sys_RelativePath',                                false);
          end;
        end;
        WriteString (sec,'Lbl_InstVer_Val',                                     Lbl_InstVer_Val.Caption);
        WriteString (sec,'ArkVer',                                              ArkVer);
        WriteBool   (sec,'CB_Install_DelMovie',                                 CB_Install_DelMovie.Checked);
        WriteBool   (sec,'ChB_AutoBackup',                                      ChB_AutoBackup.Checked);
        WriteInteger(sec,'CB_MapName',                                          CB_MapName.ItemIndex);
        WriteString (sec,'CB_MapName_Text',                                     CB_MapName.Text);
        WriteInteger(sec,'CB_ActiveEvent',                                      CB_ActiveEvent.ItemIndex);
        WriteInteger(sec,'CB_ActiveEvent2',                                     CB_ActiveEvent2.ItemIndex);
        WriteBool   (sec,'ChB_MULTIHOME',                                       ChB_MULTIHOME.Checked);
        WriteBool   (sec,'ChB_UseServerNetSpeedCheck',                          ChB_UseServerNetSpeedCheck.Checked);
        WriteInteger(sec,'SE_GBUsageToForceRestart_Val',                        SE_GBUsageToForceRestart_Val.Value);
        WriteInteger(sec,'CB_Culture',                                          CB_Culture.ItemIndex);
        WriteBool   (sec,'ChB_NoBattlEye',                                      ChB_NoBattlEye.Checked);
        WriteBool   (sec,'ChB_AlwaysTickDedicatedSkeletalMeshes',               ChB_AlwaysTickDedicatedSkeletalMeshes.Checked);
        WriteBool   (sec,'ChB_UseDynamicConfig',                                ChB_UseDynamicConfig.Checked);
        WriteBool   (sec,'ChB_disabledinonetrangescaling',                      ChB_disabledinonetrangescaling.Checked);
        WriteInteger(sec,'SE_WinLiveMaxPlayers_Val',                            SE_WinLiveMaxPlayers_Val.Value);
        WriteBool   (sec,'ChB_AltSaveDirectoryName',                            ChB_AltSaveDirectoryName.Checked);
        WriteString (sec,'Edit_AltSaveDirectoryName',                           Edit_AltSaveDirectoryName.Text);
        WriteString (sec,'Edit_Mods',                                           Edit_Mods.Text);
        WriteString (sec,'Edit_passivemods',                                    Edit_passivemods.Text);
        WriteString (sec,'Edit_CustomNotificationURL_Val',                      Edit_CustomNotificationURL_Val.Text);
        WriteBool   (sec,'ChB_NoWildBabies',                                    ChB_NoWildBabies.Checked);
        WriteBool   (sec,'ChB_ForceAllowCaveFlyers',                            ChB_ForceAllowCaveFlyers.Checked);
        WriteString (sec,'Edit_clusterid',                                      Edit_clusterid.Text);
        WriteString (sec,'Edit_ClusterDirOverride',                             Edit_ClusterDirOverride.Text);
        WriteBool   (sec,'ChB_NoTransferFromFiltering',                         ChB_NoTransferFromFiltering.Checked);
        WriteString (sec,'Edit_ipv4_Val',                                       Edit_ipv4_Val.Text);
        WriteString (sec,'Edit_ServerIPv4_Val',                                 Edit_ServerIPv4_Val.Text);
        WriteBool   (sec,'ChB_CMD_override',                                    ChB_CMD_override.Checked);
        WriteString (sec,'MM_Command_Val',                                      MM_Command_Val.text);
        WriteString (sec,'MM_Command_Override',                                 MM_Command_Override.text);
        WriteBool   (sec,'ChB_servergamelog',                                   ChB_servergamelog.Checked);
        WriteBool   (sec,'ChB_servergamelogincludetribelogs',                   ChB_servergamelogincludetribelogs.Checked);
        WriteBool   (sec,'ChB_ServerRCONOutputTribeLogs',                       ChB_ServerRCONOutputTribeLogs.Checked);
        WriteBool   (sec,'ChB_ForceRespawnDinos',                               ChB_ForceRespawnDinos.Checked);
        WriteBool   (sec,'ChB_ServerPlatform_ALL',                              ChB_ServerPlatform_ALL.Checked);
        WriteBool   (sec,'ChB_ServerPlatform_PC',                               ChB_ServerPlatform_PC.Checked);
        WriteBool   (sec,'ChB_ServerPlatform_PS5',                              ChB_ServerPlatform_PS5.Checked);
        WriteBool   (sec,'ChB_ServerPlatform_XSX',                              ChB_ServerPlatform_XSX.Checked);
        WriteBool   (sec,'ChB_ServerPlatform_MSStore',                          ChB_ServerPlatform_MSStore.Checked);

        WriteBool   (sec,'ChB_DisableCustomCosmetics',                          ChB_DisableCustomCosmetics.Checked);
        WriteBool   (sec,'ChB_disableCharacterTracker',                         ChB_disableCharacterTracker.Checked);
        WriteBool   (sec,'ChB_DisableDupeLogDeletes',                           ChB_DisableDupeLogDeletes.Checked);
        WriteBool   (sec,'ChB_EasterColors',                                    ChB_EasterColors.Checked);
        WriteBool   (sec,'ChB_ForceDupeLog',                                    ChB_ForceDupeLog.Checked);
        WriteBool   (sec,'ChB_forceuseperfthreads',                             ChB_forceuseperfthreads.Checked);
        WriteBool   (sec,'ChB_ignoredupeditems',                                ChB_ignoredupeditems.Checked);
        WriteBool   (sec,'ChB_UseItemDupeCheck',                                ChB_UseItemDupeCheck.Checked);
        WriteBool   (sec,'ChB_NoAI',                                            ChB_NoAI.Checked);
        WriteBool   (sec,'ChB_nodinos',                                         ChB_nodinos.Checked);
        WriteBool   (sec,'ChB_NoDinosExceptForcedSpawn',                        ChB_NoDinosExceptForcedSpawn.Checked);
        WriteBool   (sec,'ChB_NoDinosExceptStreamingSpawn',                     ChB_NoDinosExceptStreamingSpawn.Checked);
        WriteBool   (sec,'ChB_NoDinosExceptManualSpawn',                        ChB_NoDinosExceptManualSpawn.Checked);
        WriteBool   (sec,'ChB_NoDinosExceptWaterSpawn',                         ChB_NoDinosExceptWaterSpawn.Checked);
        WriteBool   (sec,'ChB_noperfthreads',                                   ChB_noperfthreads.Checked);
        WriteBool   (sec,'ChB_nosound',                                         ChB_nosound.Checked);
        WriteBool   (sec,'ChB_onethread',                                       ChB_onethread.Checked);
        WriteBool   (sec,'ChB_NoTimeout',                                       ChB_NoTimeout.Checked);
        WriteBool   (sec,'ChB_StasisKeepControllers',                           ChB_StasisKeepControllers.Checked);
        WriteBool   (sec,'ChB_UnstasisDinoObstructionCheck',                    ChB_UnstasisDinoObstructionCheck.Checked);
        WriteBool   (sec,'ChB_AutoDestroyStructures',                           ChB_AutoDestroyStructures.Checked);
        WriteBool   (sec,'ChB_exclusivejoin',                                   ChB_exclusivejoin.Checked);
        WriteBool   (sec,'ChB_ForceClampItemQuality',                           ChB_ForceClampItemQuality.Checked);
        WriteBool   (sec,'ChB_ForceWipeTinkerExploit',                          ChB_ForceWipeTinkerExploit.Checked);
        WriteBool   (sec,'ChB_ForceWipeTinkerExploitNoDinos',                   ChB_ForceWipeTinkerExploitNoDinos.Checked);

        WriteBool   (sec,'ChB_FixThrallStats',                                  ChB_FixThrallStats.Checked);
        WriteBool   (sec,'ChB_ForceCharRespec',                                 ChB_ForceCharRespec.Checked);
        WriteBool   (sec,'ChB_allowicefox',                                     ChB_allowicefox.Checked);

        WriteBool   (sec,'ChB_OlynpicColors',                                   ChB_OlympicColors.Checked);
        WriteBool   (sec,'ChB_PrideColors',                                     ChB_PrideColors.Checked);
        WriteBool   (sec,'ChB_HalloweenColors',                                 ChB_HalloweenColors.Checked);
        WriteBool   (sec,'ChB_ServerUseEventColors',                            ChB_ServerUseEventColors.Checked);
        WriteBool   (sec,'ChB_RedownloadModsOnServerRestart',                   ChB_RedownloadModsOnServerRestart.Checked);
        WriteBool   (sec,'SE_DestroyTamesOverLevel_CNV',                        True);
        WriteInteger(sec,'SE_DestroyTamesOverLevel',                            SE_DestroyTamesOverLevel.Value);

        // New ActiveEvent
        WriteInteger(sec,'CG_ActiveEventCount',                                 CG_ActiveEvent.Items.Count);
        for i:= 0 to CG_ActiveEvent.Items.Count -1 do
        begin
          WriteBool   (sec,'CG_ActiveEvent'+Inttostr(i),                        CG_ActiveEvent.Checked[i]);
        end;
        WriteString (sec,'Edit_AllModInArgs',                                   Edit_AllModInArgs.Text);
        WriteBool   (sec,'ChB_USE_AsaApiLoader',                                ChB_USE_AsaApiLoader.Checked);
      end;

      sec := 'Server';
      begin
        WriteString (sec,'Edit_SessionName',                                    Edit_SessionName.Text);
        WriteInteger(sec,'SE_Port',                                             SE_Port.Value);
        WriteInteger(sec,'SE_QueryPort',                                        SE_QueryPort.Value);
        WriteBool   (sec,'ChB_Port_Args',                                       ChB_Port_Args.Checked);
        WriteBool   (sec,'ChB_Queryport_Args',                                  ChB_Queryport_Args.Checked);
        WriteString (sec,'Edit_ServerPassword',                                 Edit_ServerPassword.Text);
        WriteString (sec,'Edit_ServerAdminPassword',                            Edit_ServerAdminPassword.Text);
        WriteFloat  (sec,'FSE_AutoSavePeriodMinutes',                           FSE_AutoSavePeriodMinutes.Value);
        WriteFloat  (sec,'FSE_KickIdlePlayersPeriod',                           FSE_KickIdlePlayersPeriod.Value);
        WriteBool   (sec,'ChB_EnableIdlePlayerKick',                            ChB_EnableIdlePlayerKick.Checked);
        WriteString (sec,'Edit_ActiveMods_Val',                                 Edit_ActiveMods_Val.Text);
        WriteString (sec,'Edit_ActiveMapMod_Val',                               Edit_ActiveMapMod_Val.Text);
        WriteString (sec,'Edit_Message',                                        Edit_Message.Text);
        WriteInteger(sec,'SE_Duration',                                         SE_Duration.Value);
        WriteBool   (sec,'ChB_AdminLogging',                                    ChB_AdminLogging.Checked);
        WriteBool   (sec,'ChB_AllowHideDamageSourceFromLogs',                   ChB_AllowHideDamageSourceFromLogs.Checked);
        WriteBool   (sec,'ChB_DontAlwaysNotifyPlayerJoined',                    ChB_DontAlwaysNotifyPlayerJoined.Checked);
        WriteBool   (sec,'ChB_globalVoiceChat',                                 ChB_globalVoiceChat.Checked);
        WriteBool   (sec,'ChB_ProximityChat',                                   ChB_ProximityChat.Checked);
        WriteBool   (sec,'ChB_noTributeDownloads',                              ChB_noTributeDownloads.Checked);
        WriteBool   (sec,'ChB_CrossARKAllowForeignDinoDownloads',               ChB_CrossARKAllowForeignDinoDownloads.Checked);
        WriteBool   (sec,'ChB_PreventDownloadItems',                            ChB_PreventDownloadItems.Checked);
        WriteBool   (sec,'ChB_PreventDownloadSurvivors',                        ChB_PreventDownloadSurvivors.Checked);
        WriteBool   (sec,'ChB_PreventDownloadDinos',                            ChB_PreventDownloadDinos.Checked);
        WriteBool   (sec,'ChB_PreventUploadDinos',                              ChB_PreventUploadDinos.Checked);
        WriteBool   (sec,'ChB_PreventUploadItems',                              ChB_PreventUploadItems.Checked);
        WriteBool   (sec,'ChB_PreventUploadSurvivors',                          ChB_PreventUploadSurvivors.Checked);
        WriteInteger(sec,'SE_MaxTributeDinos',                                  SE_MaxTributeDinos.Value);
        WriteInteger(sec,'SE_MaxTributeItems',                                  SE_MaxTributeItems.Value);
        WriteInteger(sec,'SE_MaxTributeCharacters',                             SE_MaxTributeCharacters.Value);
        WriteInteger(sec,'SE_TributeItemExpirationSeconds',                     SE_TributeItemExpirationSeconds.Value);
        WriteInteger(sec,'SE_TributeCharacterExpirationSeconds',                SE_TributeCharacterExpirationSeconds.Value);
        WriteInteger(sec,'SE_TributeDinoExpirationSeconds',                     SE_TributeDinoExpirationSeconds.Value);

        WriteBool   (sec,'CB_RCONEnabled',                                      CB_RCONEnabled.Checked);
        WriteInteger(sec,'SE_RCONPort',                                         SE_RCONPort.Value);
        WriteBool   (sec,'ChB_RCONPort_Args',                                   ChB_RCONPort_Args.Checked);
        WriteFloat  (sec,'FSE_RCONServerGameLogBuffer',                         FSE_RCONServerGameLogBuffer.Value);
        WriteBool   (sec,'ChB_AlwaysNotifyPlayerLeft',                          ChB_AlwaysNotifyPlayerLeft.Checked);
        WriteBool   (sec,'ChB_bShowCreativeMode',                               ChB_bShowCreativeMode.Checked);
        WriteBool   (sec,'ChB_OverrideStartTime',                               ChB_OverrideStartTime.Checked);
        WriteFloat  (sec,'FSE_StartTimeHour',                                   FSE_StartTimeHour.Value);
        WriteInteger(sec,'SE_OverrideMaxExperiencePointsPlayer',                SE_OverrideMaxExperiencePointsPlayer.Value);
        WriteInteger(sec,'SE_OverrideMaxExperiencePointsDino',                  SE_OverrideMaxExperiencePointsDino.Value);

        WriteFloat  (sec,'FSE_AutoRestartIntervalSeconds',                      FSE_AutoRestartIntervalSeconds.Value);
        WriteInteger(sec,'SE_PhotoModeRangeLimit',                              SE_PhotoModeRangeLimit.Value);
        WriteFloat  (sec,'FSE_UpdateAllowedCheatersInterval',                   FSE_UpdateAllowedCheatersInterval.Value);
        WriteFloat  (sec,'FSE_ServerAutoForceRespawnWildDinosInterval',         FSE_ServerAutoForceRespawnWildDinosInterval.Value);
        WriteBool   (sec,'ChB_UseCharacterTracker',                             ChB_UseCharacterTracker.Checked);
        WriteBool   (sec,'ChB_ForceExploitedTameDeletion',                      ChB_ForceExploitedTameDeletion.Checked);
        WriteString (sec,'Edit_BanListURL',                                     Edit_BanListURL.Text);
        WriteString (sec,'Edit_CustomLiveTuningUrl',                            Edit_CustomLiveTuningUrl.Text);
        WriteString (sec,'Edit_BadWordListURL',                                 Edit_BadWordListURL.Text);
        WriteString (sec,'Edit_BadWordWhiteListURL',                            Edit_BadWordWhiteListURL.Text);
        WriteString (sec,'Edit_AdminListURL',                                   Edit_AdminListURL.Text);

        WriteInteger(sec,'SE_LimitNonPlayerDroppedItemsCount',                  SE_LimitNonPlayerDroppedItemsCount.Value);
        WriteInteger(sec,'SE_LimitNonPlayerDroppedItemsRange',                  SE_LimitNonPlayerDroppedItemsRange.Value);

        WriteBool   (sec,'ChB_ASASM_AutoDestroyWildDinosSeconds',               ChB_ASASM_AutoDestroyWildDinosSeconds.Checked);
        WriteInteger(sec,'SE_ASASM_AutoDestroyWildDinosSeconds',                SE_ASASM_AutoDestroyWildDinosSeconds.Value);
        WriteBool   (sec,'CB_SvrCMDEnabled',                                    CB_SvrCMDEnabled.Checked);
        WriteInteger(sec,'SE_DelayedRestartSec',                                SE_DelayedRestartSec.Value);
      end;

      sec := 'World';
      begin
        WriteFloat  (sec,'FSE_DayCycleSpeedScale',                              FSE_DayCycleSpeedScale.Value);
        WriteFloat  (sec,'FSE_DayTimeSpeedScale',                               FSE_DayTimeSpeedScale.Value);
        WriteFloat  (sec,'FSE_NightTimeSpeedScale',                             FSE_NightTimeSpeedScale.Value);
        WriteFloat  (sec,'FSE_DifficultyOffset',                                FSE_DifficultyOffset.Value);
        WriteFloat  (sec,'FSE_OverrideOfficialDifficulty',                      FSE_OverrideOfficialDifficulty.Value);
        WriteBool   (sec,'ChB_ServerHardcore',                                  ChB_ServerHardcore.Checked);
        WriteBool   (sec,'ChB_AllowCaveBuildingPvE',                            ChB_AllowCaveBuildingPvE.Checked);
        WriteBool   (sec,'ChB_AllowFlyerCarryPvE',                              ChB_AllowFlyerCarryPvE.Checked);
        WriteFloat  (sec,'FSE_PvEDinoDecayPeriodMultiplier',                    FSE_PvEDinoDecayPeriodMultiplier.Value);
        WriteBool   (sec,'ChB_DisableDinoDecayPvE',                             ChB_DisableDinoDecayPvE.Checked);
        WriteBool   (sec,'ChB_DisablePvEGamma',                                 ChB_DisablePvEGamma.Checked);
        WriteBool   (sec,'ChB_serverPVE',                                       ChB_serverPVE.Checked);
        WriteBool   (sec,'ChB_bPvEDisableFriendlyFire',                         ChB_bPvEDisableFriendlyFire.Checked);
        WriteBool   (sec,'ChB_DisableStructureDecayPvE',                        ChB_DisableStructureDecayPvE.Checked);
        WriteBool   (sec,'ChB_PvEAllowStructuresAtSupplyDrops',                 ChB_PvEAllowStructuresAtSupplyDrops.Checked);
        WriteBool   (sec,'ChB_AllowCaveBuildingPvP',                            ChB_AllowCaveBuildingPvP.Checked);
        WriteBool   (sec,'ChB_PvPDinoDecay',                                    ChB_PvPDinoDecay.Checked);
        WriteBool   (sec,'ChB_PvPStructureDecay',                               ChB_PvPStructureDecay.Checked);
        WriteBool   (sec,'ChB_EnablePvPGamma',                                  ChB_EnablePvPGamma.Checked);
        WriteBool   (sec,'ChB_PreventOfflinePvP',                               ChB_PreventOfflinePvP.Checked);
        WriteFloat  (sec,'FSE_PreventOfflinePvPInterval',                       FSE_PreventOfflinePvPInterval.Value);
        WriteFloat  (sec,'FSE_HarvestAmountMultiplier',                         FSE_HarvestAmountMultiplier.Value);
        WriteFloat  (sec,'FSE_HarvestHealthMultiplier',                         FSE_HarvestHealthMultiplier.Value);
        WriteFloat  (sec,'FSE_ResourcesRespawnPeriodMultiplier',                FSE_ResourcesRespawnPeriodMultiplier.Value);
        WriteFloat  (sec,'FSE_ItemStackSizeMultiplier',                         FSE_ItemStackSizeMultiplier.Value);
        WriteInteger(sec,'SE_MaxPersonalTamedDinos',                            SE_MaxPersonalTamedDinos.Value);
        WriteFloat  (sec,'FSE_MaxTamedDinos',                                   FSE_MaxTamedDinos.Value);
        WriteBool   (sec,'ChB_DestroyTamesOverTheSoftTameLimit',                ChB_DestroyTamesOverTheSoftTameLimit.Checked);
        WriteInteger(sec,'SE_MaxTamedDinos_SoftTameLimit',                      SE_MaxTamedDinos_SoftTameLimit.Value);
        WriteInteger(sec,'SE_MaxTamedDinos_SoftTameLimit_CountdownForDeletionDuration',SE_MaxTamedDinos_SoftTameLimit_CountdownForDeletionDuration.Value);
        WriteFloat  (sec,'FSE_GlobalItemDecompositionTimeMultiplier',           FSE_GlobalItemDecompositionTimeMultiplier.Value);
        WriteFloat  (sec,'FSE_GlobalSpoilingTimeMultiplier',                    FSE_GlobalSpoilingTimeMultiplier.Value);
        WriteBool   (sec,'ChB_PreventDiseases',                                 ChB_PreventDiseases.Checked);
        WriteBool   (sec,'CB_NonPermanentDiseases',                             CB_NonPermanentDiseases.Checked);
        WriteBool   (sec,'ChB_bDisableFriendlyFire',                            ChB_bDisableFriendlyFire.Checked);
        WriteBool   (sec,'ChB_ClampItemSpoilingTimes',                          ChB_ClampItemSpoilingTimes.Checked);
        WriteBool   (sec,'ChB_ClampResourceHarvestDamage',                      ChB_ClampResourceHarvestDamage.Checked);
        WriteBool   (sec,'ChB_ClampItemStats',                                  ChB_ClampItemStats.Checked);
        WriteBool   (sec,'ChB_bUseSingleplayerSettings',                        ChB_bUseSingleplayerSettings.Checked);
        WriteBool   (sec,'ChB_RandomSupplyCratePoints',                         ChB_RandomSupplyCratePoints.Checked);
        WriteBool   (sec,'ChB_EnableExtraStructurePreventionVolumes',           ChB_EnableExtraStructurePreventionVolumes.Checked);
        WriteBool   (sec,'ChB_AutoDestroyDecayedDinos',                         ChB_AutoDestroyDecayedDinos.Checked);
        WriteBool   (sec,'ChB_bForceCanRideFliers',                             ChB_bForceCanRideFliers.Checked);
        WriteBool   (sec,'ChB_PreventTribeAlliances',                           ChB_PreventTribeAlliances.Checked);
        WriteFloat  (sec,'FSE_TribeNameChangeCooldown',                         FSE_TribeNameChangeCooldown.Value);
        WriteFloat  (sec,'FSE_ResourceNoReplenishRadiusPlayers',                FSE_ResourceNoReplenishRadiusPlayers.Value);
        WriteFloat  (sec,'FSE_ResourceNoReplenishRadiusStructures',             FSE_ResourceNoReplenishRadiusStructures.Value);
        WriteFloat  (sec,'FSE_CropDecaySpeedMultiplier',                        FSE_CropDecaySpeedMultiplier.Value);
        WriteFloat  (sec,'FSE_CropGrowthSpeedMultiplier',                       FSE_CropGrowthSpeedMultiplier.Value);
        WriteFloat  (sec,'FSE_DinoCountMultiplier',                             FSE_DinoCountMultiplier.Value);
        WriteBool   (sec,'ChB_bDisableDinoRiding',                              ChB_bDisableDinoRiding.Checked);
        WriteBool   (sec,'ChB_bDisableDinoTaming',                              ChB_bDisableDinoTaming.Checked);
        WriteBool   (sec,'ChB_bDisableDinoBreeding',                            ChB_bDisableDinoBreeding.Checked);
        WriteBool   (sec,'ChB_bAutoUnlockAllEngrams',                           ChB_bAutoUnlockAllEngrams.Checked);
        WriteBool   (sec,'ChB_bDisableStructurePlacementCollision',             ChB_bDisableStructurePlacementCollision.Checked);
        WriteBool   (sec,'ChB_bIgnoreStructuresPreventionVolumes',              ChB_bIgnoreStructuresPreventionVolumes.Checked);
        WriteBool   (sec,'ChB_bAllowSpeedLeveling',                             ChB_bAllowSpeedLeveling.Checked);
        WriteBool   (sec,'ChB_bAllowFlyerSpeedLeveling',                        ChB_bAllowFlyerSpeedLeveling.Checked);
        WriteBool   (sec,'ChB_MaxDifficulty',                                   ChB_MaxDifficulty.Checked);
        WriteBool   (sec,'ChB_bDisableLootCrates',                              ChB_bDisableLootCrates.Checked);
        WriteBool   (sec,'ChB_bAutoPvETimer',                                   ChB_bAutoPvETimer.Checked);
        WriteInteger(sec,'SE_AutoPvEStartTimeSeconds',                          SE_AutoPvEStartTimeSeconds.Value);
        WriteInteger(sec,'SE_AutoPvEStopTimeSeconds',                           SE_AutoPvEStopTimeSeconds.Value);
        WriteBool   (sec,'ChB_bAutoPvEUseSystemTime',                           ChB_bAutoPvEUseSystemTime.Checked);
        WriteBool   (sec,'ChB_bPvEAllowTribeWar',                               ChB_bPvEAllowTribeWar.Checked);
        WriteBool   (sec,'ChB_bPvEAllowTribeWarCancel',                         ChB_bPvEAllowTribeWarCancel.Checked);
        WriteFloat  (sec,'FSE_PvEStructureDecayPeriodMultiplier',               FSE_PvEStructureDecayPeriodMultiplier.Value);
        WriteBool   (sec,'ChB_bIncreasePvPRespawnInterval',                     ChB_bIncreasePvPRespawnInterval.Checked);
        WriteFloat  (sec,'FSE_IncreasePvPRespawnIntervalCheckPeriod',           FSE_IncreasePvPRespawnIntervalCheckPeriod.Value);
        WriteFloat  (sec,'FSE_IncreasePvPRespawnIntervalMultiplier',            FSE_IncreasePvPRespawnIntervalMultiplier.Value);
        WriteFloat  (sec,'FSE_IncreasePvPRespawnIntervalBaseAmount',            FSE_IncreasePvPRespawnIntervalBaseAmount.Value);
        WriteInteger(sec,'SE_PvPZoneStructureDamageMultiplier',                 SE_PvPZoneStructureDamageMultiplier.Value);
        WriteFloat  (sec,'FSE_GlobalCorpseDecompositionTimeMultiplier',         FSE_GlobalCorpseDecompositionTimeMultiplier.Value);
        WriteInteger(sec,'SE_MaxNumberOfPlayersInTribe',                        SE_MaxNumberOfPlayersInTribe.Value);
        WriteFloat  (sec,'FSE_BaseTemperatureMultiplier',                       FSE_BaseTemperatureMultiplier.Value);
        WriteFloat  (sec,'FSE_FuelConsumptionIntervalMultiplier',               FSE_FuelConsumptionIntervalMultiplier.Value);
        WriteInteger(sec,'SE_MaxTrainCars',                                     SE_MaxTrainCars.Value);
        WriteBool   (sec,'ChB_IgnorePVPMountedWeaponryRestrictions',            ChB_IgnorePVPMountedWeaponryRestrictions.Checked);
        WriteBool   (sec,'ChB_AllowTeslaCoilCaveBuildingPVP',                   ChB_AllowTeslaCoilCaveBuildingPVP.Checked);
        WriteString (sec,'Edit_WorldBossKingKaijuSpawnTime',                    Edit_WorldBossKingKaijuSpawnTime.Text);
        WriteBool   (sec,'ChB_WorldBossKingKaijuSpawnTime_UTC',                 ChB_WorldBossKingKaijuSpawnTime_UTC.Checked);
        WriteBool   (sec,'ChB_ForceGachaUnhappyInCaves',                        ChB_ForceGachaUnhappyInCaves.Checked);
        WriteInteger(sec,'SE_ArmadoggoDeathCooldown',                           SE_ArmadoggoDeathCooldown.Value);
        WriteInteger(sec,'SE_MaxBlueprintDinoLevel',                            SE_MaxBlueprintDinoLevel.Value);
        WriteInteger(sec,'SE_MaxBlueprintDinoQuality',                          SE_MaxBlueprintDinoQuality.Value);
        WriteInteger(sec,'SE_MaxBlueprintItemQuality',                          SE_MaxBlueprintItemQuality.Value);
        WriteInteger(sec,'SE_MaxBlueprintScoutQuality',                         SE_MaxBlueprintScoutQuality.Value);
        WriteBool   (sec,'ChB_bAllowBuildingInNoBuildZone',                     ChB_bAllowBuildingInNoBuildZone.Checked);
        WriteBool   (sec,'ChB_bUseCorpseLocator',                               ChB_bUseCorpseLocator.Checked);
        WriteBool   (sec,'ChB_bAllowFlyerDinoSubmerging',                       ChB_bAllowFlyerDinoSubmerging.Checked);

        WriteInteger(sec,'SE_YoungIceFoxDeathCooldown',                         SE_YoungIceFoxDeathCooldown.Value);
        WriteInteger(sec,'SE_CompanionsDeathCooldown',                          SE_CompanionsDeathCooldown.Value);

        WriteFloat  (sec,'FSE_TribeTowerBonusMultiplier',                       FSE_TribeTowerBonusMultiplier.Value);

        WriteBool   (sec,'ChB_LimitBunkersPerTribe',                            ChB_LimitBunkersPerTribe.Checked);
        WriteInteger(sec,'SE_LimitBunkersPerTribeNum',                          SE_LimitBunkersPerTribeNum.Value);
        WriteBool   (sec,'ChB_AllowBunkersInPreventionZones',                   ChB_AllowBunkersInPreventionZones.Checked);
        WriteBool   (sec,'ChB_AllowRidingDinosInsideBunkers',                   ChB_AllowRidingDinosInsideBunkers.Checked);
        WriteBool   (sec,'ChB_AllowBunkerModulesAboveGround',                   ChB_AllowBunkerModulesAboveGround.Checked);
        WriteBool   (sec,'ChB_AllowDinoAIInsideBunkers',                        ChB_AllowDinoAIInsideBunkers.Checked);
        WriteBool   (sec,'ChB_AllowBunkerModulesInPreventionZones',             ChB_AllowBunkerModulesInPreventionZones.Checked);
        WriteFloat  (sec,'FSE_MinDistanceBetweenBunkers',                       FSE_MinDistanceBetweenBunkers.Value);
        WriteFloat  (sec,'FSE_EnemyAccessBunkerHPThreshold',                    FSE_EnemyAccessBunkerHPThreshold.Value);
        WriteFloat  (sec,'FSE_BunkerUnderHPThresholdDmgMultiplier',             FSE_BunkerUnderHPThresholdDmgMultiplier.Value);

        WriteFloat  (sec,'FSE_CryoHospitalHoursToRegenHP',                      FSE_CryoHospitalHoursToRegenHP.Value);
        WriteFloat  (sec,'FSE_CryoHospitalHoursToRegenFood',                    FSE_CryoHospitalHoursToRegenFood.Value);
        WriteFloat  (sec,'FSE_CryoHospitalHoursToDrainTorpor',                  FSE_CryoHospitalHoursToDrainTorpor.Value);
        WriteFloat  (sec,'FSE_CryoHospitalMatingCooldownReduction',             FSE_CryoHospitalMatingCooldownReduction.Value);

        WriteFloat  (sec,'FSE_BloodforgeReinforceExtraDurability',              FSE_BloodforgeReinforceExtraDurability.Value);
        WriteFloat  (sec,'FSE_BloodforgeReinforceResourceCostMultiplier',       FSE_BloodforgeReinforceResourceCostMultiplier.Value);
        WriteFloat  (sec,'FSE_BloodforgeReinforceSpeedMultiplier',              FSE_BloodforgeReinforceSpeedMultiplier.Value);

        WriteInteger(sec,'SE_MaxActiveOutposts',                                SE_MaxActiveOutposts.Value);
        WriteInteger(sec,'SE_MaxActiveResourceCaches',                          SE_MaxActiveResourceCaches.Value);
        WriteInteger(sec,'SE_MaxActiveCityOutposts',                            SE_MaxActiveCityOutposts.Value);
      end;

      sec := 'VisualHUD';
      begin
        WriteBool   (sec,'ChB_AllowHitMarkers',                                 ChB_AllowHitMarkers.Checked);
        WriteBool   (sec,'ChB_AllowThirdPersonPlayer',                          ChB_AllowThirdPersonPlayer.Checked);
        WriteBool   (sec,'ChB_DisableWeatherFog',                               ChB_DisableWeatherFog.Checked);
        WriteBool   (sec,'ChB_ServerCrosshair',                                 ChB_ServerCrosshair.Checked);
        WriteBool   (sec,'ChB_ServerForceNoHUD',                                ChB_ServerForceNoHUD.Checked);
        WriteBool   (sec,'ChB_ShowFloatingDamageText',                          ChB_ShowFloatingDamageText.Checked);
        WriteBool   (sec,'ChB_ShowMapPlayerLocation',                           ChB_ShowMapPlayerLocation.Checked);
        WriteBool   (sec,'ChB_bDisablePhotoMode',                               ChB_bDisablePhotoMode.Checked);

        WriteInteger(sec,'RG_Cosmetic_Kind',                                    RG_Cosmetic_Kind.ItemIndex);
        WriteString (sec,'Edit_Cosmetic_URL',                                   Edit_Cosmetic_URL.Text);
        WriteString (sec,'Edit_Cosmetic_LocalFile',                             Edit_Cosmetic_LocalFile.Text);
        WriteInteger(sec,'SG_Cosmetic_RowCount',                                SG_Cosmetic.RowCount-1);
        for i := 1 to SG_Cosmetic.RowCount -1 do
        begin
          WriteString (sec,'SG_Cosmetic_Text' + IntToStr(i),                    SG_Cosmetic.Rows[i].CommaText);
        end;
        if DirectoryExists(Edit_Cosmetic_LocalFile.Text) then
        begin
          if (RG_Cosmetic_Kind.ItemIndex = 3) then
          begin
            sl := TStringList.Create;
            try
              for i := 1 to SG_Cosmetic.RowCount-1 do
              begin
                str := '';
                str := SG_Cosmetic.Cells[0,i];
                if (SG_Cosmetic.Cells[2,i] <> '') then str := str + '|1'
                                                  else str := str + '|0';
                if (SG_Cosmetic.Cells[3,i] <> '') then str := str + '|1'
                                                  else str := str + '|0';
                sl.Add(str);
              end;
              sl.Text:=sl.CommaText;
              sl.SaveToFile(Edit_Cosmetic_LocalFile.Text + '\CosmeticWhitelist.txt');
            finally
              sl.Free;
            end;
          end;
        end;
      end;

      sec := 'Player';
      begin
        WriteFloat  (sec,'FSE_PlayerBaseStatMultipliers0',                      FSE_PlayerBaseStatMultipliers0.Value);
        WriteFloat  (sec,'FSE_PlayerBaseStatMultipliers1',                      FSE_PlayerBaseStatMultipliers1.Value);
        WriteFloat  (sec,'FSE_PlayerBaseStatMultipliers2',                      FSE_PlayerBaseStatMultipliers2.Value);
        WriteFloat  (sec,'FSE_PlayerBaseStatMultipliers3',                      FSE_PlayerBaseStatMultipliers3.Value);
        WriteFloat  (sec,'FSE_PlayerBaseStatMultipliers4',                      FSE_PlayerBaseStatMultipliers4.Value);
        WriteFloat  (sec,'FSE_PlayerBaseStatMultipliers5',                      FSE_PlayerBaseStatMultipliers5.Value);
        WriteFloat  (sec,'FSE_PlayerBaseStatMultipliers6',                      FSE_PlayerBaseStatMultipliers6.Value);
        WriteFloat  (sec,'FSE_PlayerBaseStatMultipliers7',                      FSE_PlayerBaseStatMultipliers7.Value);
        WriteFloat  (sec,'FSE_PlayerBaseStatMultipliers8',                      FSE_PlayerBaseStatMultipliers8.Value);
        WriteFloat  (sec,'FSE_PlayerBaseStatMultipliers9',                      FSE_PlayerBaseStatMultipliers9.Value);
        WriteFloat  (sec,'FSE_PlayerBaseStatMultipliers10',                     FSE_PlayerBaseStatMultipliers10.Value);
        WriteFloat  (sec,'FSE_PlayerBaseStatMultipliers11',                     FSE_PlayerBaseStatMultipliers11.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_Player0',                 FSE_PerLevelStatsMultiplier_Player0.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_Player1',                 FSE_PerLevelStatsMultiplier_Player1.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_Player2',                 FSE_PerLevelStatsMultiplier_Player2.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_Player3',                 FSE_PerLevelStatsMultiplier_Player3.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_Player4',                 FSE_PerLevelStatsMultiplier_Player4.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_Player5',                 FSE_PerLevelStatsMultiplier_Player5.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_Player6',                 FSE_PerLevelStatsMultiplier_Player6.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_Player7',                 FSE_PerLevelStatsMultiplier_Player7.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_Player8',                 FSE_PerLevelStatsMultiplier_Player8.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_Player9',                 FSE_PerLevelStatsMultiplier_Player9.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_Player10',                FSE_PerLevelStatsMultiplier_Player10.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_Player11',                FSE_PerLevelStatsMultiplier_Player11.Value);
        WriteFloat  (sec,'FSE_OxygenSwimSpeedStatMultiplier',                   FSE_OxygenSwimSpeedStatMultiplier.Value);
        WriteFloat  (sec,'FSE_PlayerCharacterHealthRecoveryMultiplier',         FSE_PlayerCharacterHealthRecoveryMultiplier.Value);
        WriteFloat  (sec,'FSE_PlayerCharacterWaterDrainMultiplier',             FSE_PlayerCharacterWaterDrainMultiplier.Value);
        WriteFloat  (sec,'FSE_PlayerResistanceMultiplier',                      FSE_PlayerResistanceMultiplier.Value);
        WriteFloat  (sec,'FSE_PlayerCharacterFoodDrainMultiplier',              FSE_PlayerCharacterFoodDrainMultiplier.Value);
        WriteFloat  (sec,'FSE_PlayerCharacterStaminaDrainMultiplier',           FSE_PlayerCharacterStaminaDrainMultiplier.Value);
        WriteFloat  (sec,'FSE_PlayerDamageMultiplier',                          FSE_PlayerDamageMultiplier.Value);
        WriteFloat  (sec,'FSE_PoopIntervalMultiplier',                          FSE_PoopIntervalMultiplier.Value);
        WriteFloat  (sec,'FSE_PlayerHarvestingDamageMultiplier',                FSE_PlayerHarvestingDamageMultiplier.Value);
        WriteBool   (sec,'ChB_PreventSpawnAnimations',                          ChB_PreventSpawnAnimations.Checked);
        WriteBool   (sec,'ChB_bAllowUnlimitedRespecs',                          ChB_bAllowUnlimitedRespecs.Checked);
        WriteFloat  (sec,'FSE_MaxFallSpeedMultiplier',                          FSE_MaxFallSpeedMultiplier.Value);
        WriteFloat  (sec,'FSE_UseCorpseLifeSpanMultiplier',                     FSE_UseCorpseLifeSpanMultiplier.Value);
        WriteInteger(sec,'SE_ImplantSuicideCD',                                  SE_ImplantSuicideCD.Value);
        WriteInteger(sec,'SE_MaxHexagonsPerCharacter',                          SE_MaxHexagonsPerCharacter.Value);
        WriteFloat  (sec,'FSE_BaseHexagonRewardMultiplier',                     FSE_BaseHexagonRewardMultiplier.Value);
        WriteFloat  (sec,'FSE_HexagonCostMultiplier',                           FSE_HexagonCostMultiplier.Value);
      end;

      sec := 'TamedDino';
      begin
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed0',              FSE_PerLevelStatsMultiplier_DinoTamed0.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed1',              FSE_PerLevelStatsMultiplier_DinoTamed1.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed2',              FSE_PerLevelStatsMultiplier_DinoTamed2.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed3',              FSE_PerLevelStatsMultiplier_DinoTamed3.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed4',              FSE_PerLevelStatsMultiplier_DinoTamed4.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed5',              FSE_PerLevelStatsMultiplier_DinoTamed5.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed6',              FSE_PerLevelStatsMultiplier_DinoTamed6.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed7',              FSE_PerLevelStatsMultiplier_DinoTamed7.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed8',              FSE_PerLevelStatsMultiplier_DinoTamed8.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed9',              FSE_PerLevelStatsMultiplier_DinoTamed9.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed10',             FSE_PerLevelStatsMultiplier_DinoTamed10.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Affinity0',     FSE_PerLevelStatsMultiplier_DinoTamed_Affinity0.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Affinity1',     FSE_PerLevelStatsMultiplier_DinoTamed_Affinity1.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Affinity2',     FSE_PerLevelStatsMultiplier_DinoTamed_Affinity2.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Affinity3',     FSE_PerLevelStatsMultiplier_DinoTamed_Affinity3.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Affinity4',     FSE_PerLevelStatsMultiplier_DinoTamed_Affinity4.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Affinity5',     FSE_PerLevelStatsMultiplier_DinoTamed_Affinity5.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Affinity6',     FSE_PerLevelStatsMultiplier_DinoTamed_Affinity6.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Affinity7',     FSE_PerLevelStatsMultiplier_DinoTamed_Affinity7.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Affinity8',     FSE_PerLevelStatsMultiplier_DinoTamed_Affinity8.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Affinity9',     FSE_PerLevelStatsMultiplier_DinoTamed_Affinity9.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Affinity10',    FSE_PerLevelStatsMultiplier_DinoTamed_Affinity10.Value);
        WriteBool   (sec,'ChB_AllowAnyoneBabyImprintCuddle',                    ChB_AllowAnyoneBabyImprintCuddle.Checked);
        WriteFloat  (sec,'FSE_BabyCuddleGracePeriodMultiplier',                 FSE_BabyCuddleGracePeriodMultiplier.Value);
        WriteFloat  (sec,'FSE_BabyCuddleIntervalMultiplier',                    FSE_BabyCuddleIntervalMultiplier.Value);
        WriteFloat  (sec,'FSE_BabyCuddleLoseImprintQualitySpeedMultiplier',     FSE_BabyCuddleLoseImprintQualitySpeedMultiplier.Value);
        WriteFloat  (sec,'FSE_BabyFoodConsumptionSpeedMultiplier',              FSE_BabyFoodConsumptionSpeedMultiplier.Value);
        WriteFloat  (sec,'FSE_BabyImprintAmountMultiplier',                     FSE_BabyImprintAmountMultiplier.Value);
        WriteFloat  (sec,'FSE_BabyImprintingStatScaleMultiplier',               FSE_BabyImprintingStatScaleMultiplier.Value);
        WriteFloat  (sec,'FSE_BabyMatureSpeedMultiplier',                       FSE_BabyMatureSpeedMultiplier.Value);
        WriteFloat  (sec,'FSE_EggHatchSpeedMultiplier',                         FSE_EggHatchSpeedMultiplier.Value);
        WriteFloat  (sec,'FSE_LayEggIntervalMultiplier',                        FSE_LayEggIntervalMultiplier.Value);
        WriteBool   (sec,'ChB_AllowRaidDinoFeeding',                            ChB_AllowRaidDinoFeeding.Checked);
        WriteBool   (sec,'ChB_PreventMateBoost',                                ChB_PreventMateBoost.Checked);
        WriteBool   (sec,'ChB_DisableImprintDinoBuff',                          ChB_DisableImprintDinoBuff.Checked);
        WriteInteger(sec,'SE_DestroyTamesOverLevelClamp',                       SE_DestroyTamesOverLevelClamp.Value);
        WriteFloat  (sec,'FSE_RaidDinoCharacterFoodDrainMultiplier',            FSE_RaidDinoCharacterFoodDrainMultiplier.Value);
        WriteFloat  (sec,'FSE_DinoHarvestingDamageMultiplier',                  FSE_DinoHarvestingDamageMultiplier.Value);
        WriteFloat  (sec,'FSE_MatingIntervalMultiplier',                        FSE_MatingIntervalMultiplier.Value);
        WriteBool   (sec,'ChB_bFlyerPlatformAllowUnalignedDinoBasing',          ChB_bFlyerPlatformAllowUnalignedDinoBasing.Checked);
        WriteBool   (sec,'ChB_bPassiveDefensesDamageRiderlessDinos',            ChB_bPassiveDefensesDamageRiderlessDinos.Checked);
        WriteFloat  (sec,'FSE_TamedDinoDamageMultiplier',                       FSE_TamedDinoDamageMultiplier.Value);
        WriteFloat  (sec,'FSE_TamedDinoResistanceMultiplier',                   FSE_TamedDinoResistanceMultiplier.Value);
        WriteFloat  (sec,'FSE_TamedDinoCharacterFoodDrainMultiplier',           FSE_TamedDinoCharacterFoodDrainMultiplier.Value);
        WriteFloat  (sec,'FSE_TamedDinoTorporDrainMultiplier',                  FSE_TamedDinoTorporDrainMultiplier.Value);
        WriteFloat  (sec,'FSE_MatingSpeedMultiplier',                           FSE_MatingSpeedMultiplier.Value);
        WriteBool   (sec,'ChB_bUseDinoLevelUpAnimations',                       ChB_bUseDinoLevelUpAnimations.Checked);
        WriteInteger(sec,'SE_MaxCosmoWeaponAmmo',                               SE_MaxCosmoWeaponAmmo.Value);
        WriteInteger(sec,'SE_CosmoWeaponAmmoReloadAmount',                      SE_CosmoWeaponAmmoReloadAmount.Value);
      end;

      sec := 'Wiladino';
      begin
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoWild0',               FSE_PerLevelStatsMultiplier_DinoWild0.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoWild1',               FSE_PerLevelStatsMultiplier_DinoWild1.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoWild2',               FSE_PerLevelStatsMultiplier_DinoWild2.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoWild3',               FSE_PerLevelStatsMultiplier_DinoWild3.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoWild4',               FSE_PerLevelStatsMultiplier_DinoWild4.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoWild5',               FSE_PerLevelStatsMultiplier_DinoWild5.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoWild6',               FSE_PerLevelStatsMultiplier_DinoWild6.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoWild7',               FSE_PerLevelStatsMultiplier_DinoWild7.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoWild8',               FSE_PerLevelStatsMultiplier_DinoWild8.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoWild9',               FSE_PerLevelStatsMultiplier_DinoWild9.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoWild10',              FSE_PerLevelStatsMultiplier_DinoWild10.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Add0',          FSE_PerLevelStatsMultiplier_DinoTamed_Add0.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Add1',          FSE_PerLevelStatsMultiplier_DinoTamed_Add1.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Add2',          FSE_PerLevelStatsMultiplier_DinoTamed_Add2.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Add3',          FSE_PerLevelStatsMultiplier_DinoTamed_Add3.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Add4',          FSE_PerLevelStatsMultiplier_DinoTamed_Add4.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Add5',          FSE_PerLevelStatsMultiplier_DinoTamed_Add5.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Add6',          FSE_PerLevelStatsMultiplier_DinoTamed_Add6.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Add7',          FSE_PerLevelStatsMultiplier_DinoTamed_Add7.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Add8',          FSE_PerLevelStatsMultiplier_DinoTamed_Add8.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Add9',          FSE_PerLevelStatsMultiplier_DinoTamed_Add9.Value);
        WriteFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Add10',         FSE_PerLevelStatsMultiplier_DinoTamed_Add10.Value);
        WriteFloat  (sec,'FSE_DinoCharacterFoodDrainMultiplier',                FSE_DinoCharacterFoodDrainMultiplier.Value);
        WriteFloat  (sec,'FSE_DinoCharacterHealthRecoveryMultiplier',           FSE_DinoCharacterHealthRecoveryMultiplier.Value);
        WriteFloat  (sec,'FSE_DinoCharacterStaminaDrainMultiplier',             FSE_DinoCharacterStaminaDrainMultiplier.Value);
        WriteFloat  (sec,'FSE_DinoDamageMultiplier',                            FSE_DinoDamageMultiplier.Value);
        WriteFloat  (sec,'FSE_DinoResistanceMultiplier',                        FSE_DinoResistanceMultiplier.Value);
        WriteFloat  (sec,'FSE_TamingSpeedMultiplier',                           FSE_TamingSpeedMultiplier.Value);
        WriteFloat  (sec,'FSE_DinoTurretDamageMultiplier',                      FSE_DinoTurretDamageMultiplier.Value);
        WriteFloat  (sec,'FSE_PassiveTameIntervalMultiplier',                   FSE_PassiveTameIntervalMultiplier.Value);
        WriteFloat  (sec,'FSE_WildDinoCharacterFoodDrainMultiplier',            FSE_WildDinoCharacterFoodDrainMultiplier.Value);
        WriteFloat  (sec,'FSE_WildDinoTorporDrainMultiplier',                   FSE_WildDinoTorporDrainMultiplier.Value);
        WriteFloat  (sec,'FSE_OverrideBondedPassImprintMultiplier',             FSE_OverrideBondedPassImprintMultiplier.Value);
      end;

      sec := 'Spawn';
      begin
        rowcnt := SL_SpawnList.RowCount;
        WriteInteger(sec,'SL_SpawnList_RowCount',rowcnt);
        for i:=1 to rowcnt-1 do
        begin
          str :=            SL_SpawnList.Cells[1,i];
          str := str + ',' +SL_SpawnList.Cells[2,i];
          str := str + ',' +SL_SpawnList.Cells[3,i];
          str := str + ',' +SL_SpawnList.Cells[4,i];
          WriteString (sec,'SL_SpawnList'+inttostr(i),str);
        end;
        WriteBool(sec,'New_SpawnList',true);
      end;

      sec := 'Spawn2';
      begin
        for i := SL_SpawnList2.RowCount-1 downto 1 do
        begin
          if (SL_SpawnList2.Cells[0,i] = '') or
             (SL_SpawnList2.Cells[1,i] = '') then
          begin
            SL_SpawnList2.DeleteRow(i);
          end;
        end;
        rowcnt := SL_SpawnList2.RowCount;
        WriteInteger(sec,'SL_SpawnList_RowCount',rowcnt);
        for i:=1 to rowcnt-1 do
        begin
          str :=       '"' +SL_SpawnList2.Cells[0,i] + '"';
          str := str + ',' +SL_SpawnList2.Cells[1,i];
          str := str + ',' +SL_SpawnList2.Cells[2,i];
          str := str + ',' +SL_SpawnList2.Cells[3,i];
          str := str + ',' +SL_SpawnList2.Cells[4,i];
          str := str + ',' +SL_SpawnList2.Cells[5,i];
          WriteString (sec,'SL_SpawnList'+inttostr(i),str);
        end;
      end;

      sec := 'Structure';
      begin
        WriteBool   (sec,'CB_OverrideStructurePlatformPrevention',              CB_OverrideStructurePlatformPrevention.Checked);
        WriteFloat  (sec,'FSE_PlatformSaddleBuildAreaBoundsMultiplier',         FSE_PlatformSaddleBuildAreaBoundsMultiplier.Value);
        WriteFloat  (sec,'FSE_StructurePickupHoldDuration',                     FSE_StructurePickupHoldDuration.Value);
        WriteFloat  (sec,'FSE_StructurePreventResourceRadiusMultiplier',        FSE_StructurePreventResourceRadiusMultiplier.Value);
        WriteInteger(sec,'SE_TheMaxStructuresInRange',                          SE_TheMaxStructuresInRange.Value);
        WriteFloat  (sec,'FSE_PerPlatformMaxStructuresMultiplier',              FSE_PerPlatformMaxStructuresMultiplier.Value);
        WriteFloat  (sec,'FSE_StructurePickupTimeAfterPlacement',               FSE_StructurePickupTimeAfterPlacement.Value);
        WriteFloat  (sec,'FSE_StructureResistanceMultiplier',                   FSE_StructureResistanceMultiplier.Value);
        WriteBool   (sec,'ChB_AllowMultipleAttachedC4',                         ChB_AllowMultipleAttachedC4.Checked);
        WriteBool   (sec,'ChB_AlwaysAllowStructurePickup',                      ChB_AlwaysAllowStructurePickup.Checked);
        WriteFloat  (sec,'FSE_StructureDamageMultiplier',                       FSE_StructureDamageMultiplier.Value);
        WriteInteger(sec,'SE_StructureDamageRepairCooldown',                    SE_StructureDamageRepairCooldown.Value);
        WriteFloat  (sec,'FSE_AutoDestroyOldStructuresMultiplier',              FSE_AutoDestroyOldStructuresMultiplier.Value);
        WriteBool   (sec,'ChB_AllowCrateSpawnsOnTopOfStructures',               ChB_AllowCrateSpawnsOnTopOfStructures.Checked);
        WriteBool   (sec,'ChB_ForceAllStructureLocking',                         ChB_ForceAllStructureLocking.Checked);
        WriteBool   (sec,'ChB_bHardLimitTurretsInRange',                        ChB_bHardLimitTurretsInRange.Checked);
        WriteBool   (sec,'ChB_bLimitTurretsInRange',                            ChB_bLimitTurretsInRange.Checked);
        WriteInteger(sec,'SE_LimitTurretsNum',                                  SE_LimitTurretsNum.Value);
        WriteFloat  (sec,'FSE_LimitTurretsRange',                               FSE_LimitTurretsRange.Value);
        WriteInteger(sec,'SE_MaxPlatformSaddleStructureLimit',                  SE_MaxPlatformSaddleStructureLimit.Value);
        WriteInteger(sec,'SE_MaxGateFrameOnSaddles',                            SE_MaxGateFrameOnSaddles.Value);

        WriteBool   (sec,'ChB_bAllowPlatformSaddleMultiFloors',                 ChB_bAllowPlatformSaddleMultiFloors.Checked);
      end;

      sec := 'Engrams';
      begin
        WriteFloat  (sec,'FSE_CraftingSkillBonusMultiplier',                    FSE_CraftingSkillBonusMultiplier.Value);
        WriteFloat  (sec,'FSE_CustomRecipeEffectivenessMultiplier',             FSE_CustomRecipeEffectivenessMultiplier.Value);
        WriteFloat  (sec,'FSE_CustomRecipeSkillMultiplier',                     FSE_CustomRecipeSkillMultiplier.Value);
        WriteBool   (sec,'ChB_DisableCryopodEnemyCheck',                        ChB_DisableCryopodEnemyCheck.Checked);
        WriteBool   (sec,'ChB_AllowCryoFridgeOnSaddle',                         ChB_AllowCryoFridgeOnSaddle.Checked);
        WriteBool   (sec,'ChB_DisableCryopodFridgeRequirement',                 ChB_DisableCryopodFridgeRequirement.Checked);
        WriteBool   (sec,'ChB_OnlyAllowSpecifiedEngrams',                       ChB_OnlyAllowSpecifiedEngrams.Checked);
        WriteBool   (sec,'ChB_bAllowCustomRecipes',                             ChB_bAllowCustomRecipes.Checked);
        WriteFloat  (sec,'FSE_SupplyCrateLootQualityMultiplier',                FSE_SupplyCrateLootQualityMultiplier.Value);
        WriteFloat  (sec,'FSE_FishingLootQualityMultiplier',                    FSE_FishingLootQualityMultiplier.Value);
        WriteInteger(sec,'SE_CryopodFridgeCooldowntime',                        SE_CryopodFridgeCooldowntime.Value);

        WriteBool   (sec,'ChB_EnableCryopodNerf',                               ChB_EnableCryopodNerf.Checked);
        WriteBool   (sec,'ChB_EnableCryoSicknessPVE',                           ChB_EnableCryoSicknessPVE.Checked);
        WriteFloat  (sec,'FSE_CryopodNerfDamageMult',                           FSE_CryopodNerfDamageMult.Value);
        WriteFloat  (sec,'FSE_CryopodNerfDuration',                             FSE_CryopodNerfDuration.Value);
        WriteFloat  (sec,'FSE_CryopodNerfIncomingDamageMultPercent',            FSE_CryopodNerfIncomingDamageMultPercent.Value);

        rowcnt := 0;
        for i:=1 to SL_OverrideNamedEngramEntries.RowCount -1 do
        begin
          if (SL_OverrideNamedEngramEntries.Cells[1,i]<>'') or
             (SL_OverrideNamedEngramEntries.Cells[2,i]<>'') then
          begin
            rowcnt := rowcnt +1;
            str :=            SL_OverrideNamedEngramEntries.Cells[1,i];
            str := str + ',' +SL_OverrideNamedEngramEntries.Cells[2,i];
            str := str + ',' +SL_OverrideNamedEngramEntries.Cells[3,i];
            str := str + ',' +SL_OverrideNamedEngramEntries.Cells[4,i];
            str := str + ',' +SL_OverrideNamedEngramEntries.Cells[5,i];
            str := str + ',' +SL_OverrideNamedEngramEntries.Cells[6,i];
            str := str + ',' +SL_OverrideNamedEngramEntries.Cells[9,i];
            WriteString (sec,'SL_OverrideNamedEngramEntries'+inttostr(rowcnt),str);
          end;
        end;
        WriteInteger(sec,'SL_OverrideNamedEngramEntries_RowCount',rowcnt);
      end;

      sec := 'XP';
      begin
        WriteFloat  (sec,'FSE_XPMultiplier',                                    FSE_XPMultiplier.Value);
        WriteFloat  (sec,'FSE_GenericXPMultiplier',                             FSE_GenericXPMultiplier.Value);
        WriteFloat  (sec,'FSE_CraftXPMultiplier',                               FSE_CraftXPMultiplier.Value);
        WriteFloat  (sec,'FSE_HarvestXPMultiplier',                             FSE_HarvestXPMultiplier.Value);
        WriteFloat  (sec,'FSE_KillXPMultiplier',                                FSE_KillXPMultiplier.Value);
        WriteFloat  (sec,'FSE_SpecialXPMultiplier',                             FSE_SpecialXPMultiplier.Value);
        WriteFloat  (sec,'FSE_ExplorerNoteXPMultiplier',                        FSE_ExplorerNoteXPMultiplier.Value);
        WriteFloat  (sec,'FSE_BossKillXPMultiplier',                            FSE_BossKillXPMultiplier.Value);
        WriteFloat  (sec,'FSE_CaveKillXPMultiplier',                            FSE_CaveKillXPMultiplier.Value);
        WriteFloat  (sec,'FSE_WildKillXPMultiplier',                            FSE_WildKillXPMultiplier.Value);
        WriteFloat  (sec,'FSE_TamedKillXPMultiplier',                           FSE_TamedKillXPMultiplier.Value);
        WriteFloat  (sec,'FSE_UnclaimedKillXPMultiplier',                       FSE_UnclaimedKillXPMultiplier.Value);
        WriteFloat  (sec,'FSE_AlphaKillXPMultiplier',                           FSE_AlphaKillXPMultiplier.Value);
      end;

      sec := 'RCONHistory';
      begin
        WriteInteger(sec,'HistoryCount',CB_RCON_Command.Items.Count);
        for i := 1 to CB_RCON_Command.Items.Count do
        begin
          WriteString (sec,'Command'+inttostr(i),CB_RCON_Command.Items.Strings[i-1]);
        end;
      end;

      sec := 'SvrCMDHistory';
      begin
        WriteInteger(sec,'HistoryCount',CB_SvrCMD_Command.Items.Count);
        for i := 1 to CB_SvrCMD_Command.Items.Count do
        begin
          WriteString (sec,'Command'+inttostr(i),CB_SvrCMD_Command.Items.Strings[i-1]);
        end;
      end;

      sec := 'BroadcacstTxtHistory';
      begin
        WriteInteger(sec,'HistoryCount',CB_SvrCMD_BroadcastHist.Items.Count);
        for i := 1 to CB_SvrCMD_BroadcastHist.Items.Count do
        begin
          WriteString (sec,'Command'+inttostr(i),CB_SvrCMD_BroadcastHist.Items.Strings[i-1]);
        end;
      end;

      sec := 'Mod1';
      begin
        WriteBool   (sec,'ChB_Mod1_Enabled',                                    ChB_Mod1_Enabled.Checked);
        WriteBool   (sec,'ChB_Mod1_ForceUseINISettings',                        ChB_Mod1_ForceUseINISettings.Checked);
        WriteBool   (sec,'ChB_Mod1_DisableCryoSickness',                        ChB_Mod1_DisableCryoSickness.Checked);
        WriteBool   (sec,'ChB_Mod1_PreventDeployInCaves',                       ChB_Mod1_PreventDeployInCaves.Checked);
        WriteFloat  (sec,'FSE_Mod1_CryoTime',                                   FSE_Mod1_CryoTime.Value);
        WriteFloat  (sec,'FSE_Mod1_CryoTimeInCombat',                           FSE_Mod1_CryoTimeInCombat.Value);
        WriteInteger(sec,'SE_Mod1_CryoSicknessTimer',                           SE_Mod1_CryoSicknessTimer.Value);
        WriteBool   (sec,'ChB_Mod1_DisableAutoCycle',                           ChB_Mod1_DisableAutoCycle.Checked);
        WriteInteger(sec,'SE_Mod1_CryogunRangeFoundations',                     SE_Mod1_CryogunRangeFoundations.Value);
        WriteInteger(sec,'SE_Mod1_CryogunCooldownSeconds',                      SE_Mod1_CryogunCooldownSeconds.Value);
        WriteInteger(sec,'SE_Mod1_NeutergunRangeFoundations',                   SE_Mod1_NeutergunRangeFoundations.Value);
        WriteInteger(sec,'SE_Mod1_NeutergunCooldownSeconds',                    SE_Mod1_NeutergunCooldownSeconds.Value);
        WriteBool   (sec,'ChB_Mod1_DisableCryopodsRequirement',                 ChB_Mod1_DisableCryopodsRequirement.Checked);
        WriteFloat  (sec,'FSE_Mod1_CryoTerminalCaptureInterval',                FSE_Mod1_CryoTerminalCaptureInterval.Value);
        WriteInteger(sec,'SE_Mod1_CryoTerminalMaxRadiusFoundations',            SE_Mod1_CryoTerminalMaxRadiusFoundations.Value);
        WriteBool   (sec,'ChB_Mod1_PassImprintToDeployer',                      ChB_Mod1_PassImprintToDeployer.Checked);
        WriteInteger(sec,'SE_Mod1_ImprintAmountToGive',                         SE_Mod1_ImprintAmountToGive.Value);
        WriteBool   (sec,'ChB_Mod1_FullyGrownBabies',                           ChB_Mod1_FullyGrownBabies.Checked);
        WriteBool   (sec,'ChB_Mod1_AllowCryoterminalOnPlatforms',               ChB_Mod1_AllowCryoterminalOnPlatforms.Checked);
        WriteBool   (sec,'ChB_Mod1_AllowAdminCaptureAll',                       ChB_Mod1_AllowAdminCaptureAll.Checked);
        WriteInteger(sec,'SE_Mod1_MaxCryoterminalsInRange',                     SE_Mod1_MaxCryoterminalsInRange.Value);
        WriteInteger(sec,'SE_Mod1_LimitCryoterminalsRange',                     SE_Mod1_LimitCryoterminalsRange.Value);
        WriteBool   (sec,'ChB_Mod1_AllowDeployInBossArenas',                    ChB_Mod1_AllowDeployInBossArenas.Checked);
        WriteFloat  (sec,'FSE_Mod1_CryopodChargeSpeedMultiplier',               FSE_Mod1_CryopodChargeSpeedMultiplier.Value);
        WriteBool   (sec,'ChB_Mod1_DisableCryopodChargeNeed',                   ChB_Mod1_DisableCryopodChargeNeed.Checked);
        WriteBool   (sec,'ChB_Mod1_GiveTemporaryCryopodsInCryoterminal',        ChB_Mod1_GiveTemporaryCryopodsInCryoterminal.Checked);
        WriteInteger(sec,'SE_Mod1_CryofridgeInventorySlots',                    SE_Mod1_CryofridgeInventorySlots.Value);
        WriteInteger(sec,'SE_Mod1_CryoterminalInventorySlots',                  SE_Mod1_CryoterminalInventorySlots.Value);
      end;

      sec := 'Mod2';
      begin
        WriteBool   (sec,'ChB_Mod2_Enabled',                                    ChB_Mod2_Enabled.Checked);
        WriteBool   (sec,'ChB_Mod2_DisableNightVision',                         ChB_Mod2_DisableNightVision.Checked);
        WriteBool   (sec,'ChB_Mod2_DisablePredatorVision',                      ChB_Mod2_DisablePredatorVision.Checked);
        WriteBool   (sec,'ChB_Mod2_DisableOutlineMode',                         ChB_Mod2_DisableOutlineMode.Checked);
        WriteBool   (sec,'ChB_Mod2_DisableSupplyDropInfo',                      ChB_Mod2_DisableSupplyDropInfo.Checked);
        WriteBool   (sec,'ChB_Mod2_DisableItembagInfo',                         ChB_Mod2_DisableItembagInfo.Checked);
        WriteBool   (sec,'ChB_Mod2_DisableStructureInfo',                       ChB_Mod2_DisableStructureInfo.Checked);
        WriteBool   (sec,'ChB_Mod2_DisableBuffInfo',                            ChB_Mod2_DisableBuffInfo.Checked);
        WriteBool   (sec,'ChB_Mod2_DisableTameFoodInfo',                        ChB_Mod2_DisableTameFoodInfo.Checked);
        WriteBool   (sec,'ChB_Mod2_DisableEggInfo',                             ChB_Mod2_DisableEggInfo.Checked);
        WriteBool   (sec,'ChB_Mod2_DisableTheSpyglassOnEnemyTribes',            ChB_Mod2_DisableTheSpyglassOnEnemyTribes.Checked);
        WriteBool   (sec,'ChB_Mod2_OnlyShowStatsForTames',                      ChB_Mod2_OnlyShowStatsForTames.Checked);
        WriteBool   (sec,'ChB_Mod2_DisableGPS',                                 ChB_Mod2_DisableGPS.Checked);
        WriteBool   (sec,'ChB_Mod2_DisableCrosshair',                           ChB_Mod2_DisableCrosshair.Checked);
        WriteBool   (sec,'ChB_Mod2_OnlyHPonEnemyTribeDinos',                    ChB_Mod2_OnlyHPonEnemyTribeDinos.Checked);
        WriteInteger(sec,'SE_Mod2_OutlineRange',                                SE_Mod2_OutlineRange.Value);
        WriteBool   (sec,'ChB_Mod2_UseESPOutline',                              ChB_Mod2_UseESPOutline.Checked);
        WriteBool   (sec,'ChB_Mod2_UseESPOutlineFill',                          ChB_Mod2_UseESPOutlineFill.Checked);
        WriteBool   (sec,'ChB_Mod2_DontShowAnyStatsOnWildDino',                 ChB_Mod2_DontShowAnyStatsOnWildDino.Checked);
      end;

      sec := 'Mod3';
      begin
        WriteBool   (sec,'ChB_Mod3_Enabled',                                    ChB_Mod3_Enabled.Checked);
        WriteBool   (sec,'ChB_Mod3_IsAdminOnly',                                ChB_Mod3_IsAdminOnly.Checked);
        WriteInteger(sec,'SE_Mod3_MarkerLimit',                                 SE_Mod3_MarkerLimit.Value);
      end;

      sec := 'Mod4';
      begin
        WriteBool   (sec,'ChB_Mod4_AA_Ceratosaurus',                            ChB_Mod4_AA_Ceratosaurus.Checked);
        WriteBool   (sec,'ChB_Mod4_AA_Archelon',                                ChB_Mod4_AA_Archelon.Checked);
        WriteBool   (sec,'ChB_Mod4_AA_Deinotherium',                            ChB_Mod4_AA_Deinotherium.Checked);
        WriteBool   (sec,'ChB_Mod4_AA_Brachiosaurus',                           ChB_Mod4_AA_Brachiosaurus.Checked);
        WriteBool   (sec,'ChB_Mod4_AA_Deinosuchus',                             ChB_Mod4_AA_Deinosuchus.Checked);
        WriteBool   (sec,'ChB_Mod4_AA_Helicoprion',                             ChB_Mod4_AA_Helicoprion.Checked);
        WriteBool   (sec,'ChB_Mod4_AA_Xiphactinus',                             ChB_Mod4_AA_Xiphactinus.Checked);
        WriteBool   (sec,'ChB_Mod4_AA_Anomalocaris',                            ChB_Mod4_AA_Anomalocaris.Checked);
        WriteBool   (sec,'ChB_Mod4_AA_Acrocanthosaurus',                        ChB_Mod4_AA_Acrocanthosaurus.Checked);
      end;

      sec := 'Mod5';
      begin
        WriteBool   (sec,'ChB_Mod5_Enabled',                                    ChB_Mod5_Enabled.Checked);
        WriteBool   (sec,'CB_Mod5_RemoveFloorRequirementFromStructurePlacement',CB_Mod5_RemoveFloorRequirementFromStructurePlacement.Checked);
        WriteBool   (sec,'CB_Mod5_DisableResourcePulling',                      CB_Mod5_DisableResourcePulling.Checked);
        WriteFloat  (sec,'FSE_Mod5_ResourceTransferCooldown',                   FSE_Mod5_ResourceTransferCooldown.Value);
        WriteBool   (sec,'ChB_Mod5_PullingIgnoresPinCodes',                     ChB_Mod5_PullingIgnoresPinCodes.Checked);
        WriteBool   (sec,'ChB_Mod5_EnableExtendedDeathCache',                   ChB_Mod5_EnableExtendedDeathCache.Checked);
        WriteBool   (sec,'ChB_Mod5_EnableUpdateDurability',                     ChB_Mod5_EnableUpdateDurability.Checked);
        WriteBool   (sec,'ChB_Mod5_AllowTekItemBlueprintCreation',              ChB_Mod5_AllowTekItemBlueprintCreation.Checked);
        WriteBool   (sec,'ChB_Mod5_AllowMakingWeaponsAndArmorBPs',              ChB_Mod5_AllowMakingWeaponsAndArmorBPs.Checked);
        WriteBool   (sec,'ChB_Mod5_DisableMultiToolDinoKillMode',               ChB_Mod5_DisableMultiToolDinoKillMode.Checked);
        WriteBool   (sec,'ChB_Mod5_DisableMultiToolDinoChibiMode',              ChB_Mod5_DisableMultiToolDinoChibiMode.Checked);
        WriteBool   (sec,'ChB_Mod5_AllowMultiToolNeuterAll',                    ChB_Mod5_AllowMultiToolNeuterAll.Checked);
        WriteBool   (sec,'ChB_Mod5_AllowGrindingMissionRewards',                ChB_Mod5_AllowGrindingMissionRewards.Checked);
        WriteBool   (sec,'ChB_Mod5_EnableStructureSound',                       ChB_Mod5_EnableStructureSound.Checked);
        WriteBool   (sec,'ChB_Mod5_DisableBlueprintInstall',                    ChB_Mod5_DisableBlueprintInstall.Checked);
        WriteInteger(sec,'SE_Mod5_PropagatorFuelInterval',                      SE_Mod5_PropagatorFuelInterval.Value);
        WriteInteger(sec,'SE_Mod5_PropagatorModCostMutate',                     SE_Mod5_PropagatorModCostMutate.Value);
        WriteBool   (sec,'ChB_Mod5_PropagatorDisableDinoMods',                  ChB_Mod5_PropagatorDisableDinoMods.Checked);
        WriteBool   (sec,'ChB_Mod5_PropagatorRespectMutationLimit',             ChB_Mod5_PropagatorRespectMutationLimit.Checked);
        WriteBool   (sec,'ChB_Mod5_PropagatorDisableEggDrop',                   ChB_Mod5_PropagatorDisableEggDrop.Checked);
        WriteInteger(sec,'SE_Mod5_TribePropagatorLimit',                        SE_Mod5_TribePropagatorLimit.Value);
        WriteInteger(sec,'SE_Mod5_NannyMaxImprint',                             SE_Mod5_NannyMaxImprint.Value);
        WriteBool   (sec,'ChB_Mod5_DisableNannyImprinting',                     ChB_Mod5_DisableNannyImprinting.Checked);
        WriteInteger(sec,'SE_Mod5_NannyIntervalInSeconds',                      SE_Mod5_NannyIntervalInSeconds.Value);
        WriteInteger(sec,'SE_Mod5_NannyFeedingStartThreshold',                  SE_Mod5_NannyFeedingStartThreshold.Value);
        WriteInteger(sec,'SE_Mod5_BeeHiveHoneyIntervalInSeconds',               SE_Mod5_BeeHiveHoneyIntervalInSeconds.Value);
        WriteInteger(sec,'SE_Mod5_MutatorBuffMaxStackCount',                    SE_Mod5_MutatorBuffMaxStackCount.Value);
        WriteBool   (sec,'ChB_Mod5_MutatorAllowBreedingNeutered',               ChB_Mod5_MutatorAllowBreedingNeutered.Checked);
        WriteBool   (sec,'ChB_Mod5_DisableHitchingPostMatingBonus',             ChB_Mod5_DisableHitchingPostMatingBonus.Checked);
        WriteInteger(sec,'SE_Mod5_HitchingPostRange',                           SE_Mod5_HitchingPostRange.Value);
        WriteInteger(sec,'SE_Mod5_HitchingPostDinoLimit',                       SE_Mod5_HitchingPostDinoLimit.Value);
        WriteInteger(sec,'SE_Mod5_HitchingPostTribeLimit',                      SE_Mod5_HitchingPostTribeLimit.Value);
        WriteInteger(sec,'SE_Mod5_GrinderResourceReturnPercent',                SE_Mod5_GrinderResourceReturnPercent.Value);
        WriteInteger(sec,'SE_Mod5_GrinderResourceReturnMax',                    SE_Mod5_GrinderResourceReturnMax.Value);
        WriteBool   (sec,'ChB_Mod5_GrinderReturnBlockedResources',              ChB_Mod5_GrinderReturnBlockedResources.Checked);
        WriteInteger(sec,'SE_Mod5_SmallStorageSlotCount',                       SE_Mod5_SmallStorageSlotCount.Value);
        WriteInteger(sec,'SE_Mod5_LargeStorageSlotCount',                       SE_Mod5_LargeStorageSlotCount.Value);
        WriteInteger(sec,'SE_Mod5_MetalStorageSlotCount',                       SE_Mod5_MetalStorageSlotCount.Value);
        WriteInteger(sec,'SE_Mod5_PropagatorSlotCount',                         SE_Mod5_PropagatorSlotCount.Value);
        WriteInteger(sec,'SE_Mod5_NannySlotCount',                              SE_Mod5_NannySlotCount.Value);
        WriteInteger(sec,'SE_Mod5_TransmutatorSlotCount',                       SE_Mod5_TransmutatorSlotCount.Value);
        WriteInteger(sec,'SE_Mod5_GardenerSlotCount',                           SE_Mod5_GardenerSlotCount.Value);
        WriteInteger(sec,'SE_Mod5_FarmerSlotCount',                             SE_Mod5_FarmerSlotCount.Value);
        WriteInteger(sec,'SE_Mod5_BeeHiveSlotCount',                            SE_Mod5_BeeHiveSlotCount.Value);
        WriteInteger(sec,'SE_Mod5_AmmoBoxSlotCount',                            SE_Mod5_AmmoBoxSlotCount.Value);
        WriteInteger(sec,'SE_Mod5_GrinderSlotCount',                            SE_Mod5_GrinderSlotCount.Value);
        WriteInteger(sec,'SE_Mod5_IndustrialForgeSlotCount',                    SE_Mod5_IndustrialForgeSlotCount.Value);
        WriteInteger(sec,'SE_Mod5_GeneratorSlotCount',                          SE_Mod5_GeneratorSlotCount.Value);
        WriteInteger(sec,'SE_Mod5_ReplicatorSlotCount',                         SE_Mod5_ReplicatorSlotCount.Value);
        WriteInteger(sec,'SE_Mod5_FridgeSlotCount',                             SE_Mod5_FridgeSlotCount.Value);
        WriteInteger(sec,'SE_Mod5_PreservingBinSlotCount',                      SE_Mod5_PreservingBinSlotCount.Value);
        WriteInteger(sec,'SE_Mod5_FabricatorSlotCount',                         SE_Mod5_FabricatorSlotCount.Value);
        WriteInteger(sec,'SE_Mod5_TekGeneratorSlotCount',                       SE_Mod5_TekGeneratorSlotCount.Value);
        WriteFloat  (sec,'FSE_Mod5_RaidTimerLimitMultiplier',                   FSE_Mod5_RaidTimerLimitMultiplier.Value);
        WriteFloat  (sec,'FSE_Mod5_PropagatorMatingSpeedMultiplier',            FSE_Mod5_PropagatorMatingSpeedMultiplier.Value);
        WriteFloat  (sec,'FSE_Mod5_PropagatorMatingIntervalMultiplier',         FSE_Mod5_PropagatorMatingIntervalMultiplier.Value);
        WriteFloat  (sec,'FSE_Mod5_GrinderScaleMultiplier',                     FSE_Mod5_GrinderScaleMultiplier.Value);
        WriteFloat  (sec,'FSE_Mod5_IndustrialForgeScaleMultiplier',             FSE_Mod5_IndustrialForgeScaleMultiplier.Value);
        WriteFloat  (sec,'FSE_Mod5_ReplicatorScaleMultiplier',                  FSE_Mod5_ReplicatorScaleMultiplier.Value);
        WriteInteger(sec,'SE_Mod5_GrinderCraftingSpeed',                        SE_Mod5_GrinderCraftingSpeed.Value);
        WriteInteger(sec,'SE_Mod5_IndustrialForgeCraftingSpeed',                SE_Mod5_IndustrialForgeCraftingSpeed.Value);
        WriteInteger(sec,'SE_Mod5_ReplicatorCraftingSpeed',                     SE_Mod5_ReplicatorCraftingSpeed.Value);
        WriteInteger(sec,'SE_Mod5_FridgeCraftingSpeed',                         SE_Mod5_FridgeCraftingSpeed.Value);
        WriteInteger(sec,'SE_Mod5_PreservingBinCraftingSpeed',                  SE_Mod5_PreservingBinCraftingSpeed.Value);
        WriteInteger(sec,'SE_Mod5_FabricatorCraftingSpeed',                     SE_Mod5_FabricatorCraftingSpeed.Value);
        WriteInteger(sec,'SE_Mod5_ResourcePullRangeInFoundations',              SE_Mod5_ResourcePullRangeInFoundations.Value);
        WriteInteger(sec,'SE_Mod5_BeeHiveWateringRangeInFoundations',           SE_Mod5_BeeHiveWateringRangeInFoundations.Value);
        WriteInteger(sec,'SE_Mod5_MaxMutatorRangeInFoundations',                SE_Mod5_MaxMutatorRangeInFoundations.Value);
        WriteInteger(sec,'SE_Mod5_MaxPowerRangeInFoundations',                  SE_Mod5_MaxPowerRangeInFoundations.Value);
        WriteInteger(sec,'SE_Mod5_GardenerRangeInFoundations',                  SE_Mod5_GardenerRangeInFoundations.Value);
        WriteInteger(sec,'SE_Mod5_FarmerRangeInFoundations',                    SE_Mod5_FarmerRangeInFoundations.Value);
        WriteInteger(sec,'SE_Mod5_NannyRangeInFoundations',                     SE_Mod5_NannyRangeInFoundations.Value);
        WriteBool   (sec,'CG_Mod5_MutatorModeBlacklist0',                       CG_Mod5_MutatorModeBlacklist.Checked[0]);
        WriteBool   (sec,'CG_Mod5_MutatorModeBlacklist1',                       CG_Mod5_MutatorModeBlacklist.Checked[1]);
        WriteBool   (sec,'CG_Mod5_MutatorModeBlacklist2',                       CG_Mod5_MutatorModeBlacklist.Checked[2]);
        WriteBool   (sec,'CG_Mod5_MutatorModeBlacklist3',                       CG_Mod5_MutatorModeBlacklist.Checked[3]);
        WriteBool   (sec,'CG_Mod5_MutatorModeBlacklist4',                       CG_Mod5_MutatorModeBlacklist.Checked[4]);
        WriteBool   (sec,'CG_Mod5_MutatorModeBlacklist5',                       CG_Mod5_MutatorModeBlacklist.Checked[5]);
        WriteBool   (sec,'CG_Mod5_MutatorModeBlacklist6',                       CG_Mod5_MutatorModeBlacklist.Checked[6]);
        WriteString (sec,'Edit_Mod5_MutatorPulseCost',                          Edit_Mod5_MutatorPulseCost.Text);
        WriteString (sec,'Edit_Mod5_MutatorPulseCooldowns',                     Edit_Mod5_MutatorPulseCooldowns.Text);
        WriteString (sec,'Edit_Mod5_MutatorDinoBlacklist',                      Edit_Mod5_MutatorDinoBlacklist.Text);
        WriteString (sec,'Edit_Mod5_PullResourceAdditions',                     Edit_Mod5_PullResourceAdditions.Text);
        WriteString (sec,'Edit_Mod5_PullResourceRemovals',                      Edit_Mod5_PullResourceRemovals.Text);
        WriteString (sec,'Edit_Mod5_AdvTransferItemBlacklist',                  Edit_Mod5_AdvTransferItemBlacklist.Text);
        WriteString (sec,'Edit_Mod5_QoLPlusEngramWhitelist',                    Edit_Mod5_QoLPlusEngramWhitelist.Text);
        WriteString (sec,'Edit_Mod5_OmniToolBlacklist',                         Edit_Mod5_OmniToolBlacklist.Text);
        WriteString (sec,'Edit_Mod5_MultiToolBlacklist',                        Edit_Mod5_MultiToolBlacklist.Text);
        WriteString (sec,'Edit_Mod5_PropagatorDinoBlacklist',                   Edit_Mod5_PropagatorDinoBlacklist.Text);
        WriteString (sec,'Edit_Mod5_PropagatorFuelClass',                       Edit_Mod5_PropagatorFuelClass.Text);
        WriteString (sec,'Edit_Mod5_PropagatorModCostItemClass',                Edit_Mod5_PropagatorModCostItemClass.Text);
      end;

      sec := 'iniFiles';
      begin
        WriteBool   (sec,'ChB_GUS_Override',                                    ChB_GUS_Override.Checked);
        WriteInteger(sec,'Memo_GameUserSettings_Override_LineCount',            Memo_GameUserSettings_Override.Lines.Count);
        for i:=0 to Memo_GameUserSettings_Override.Lines.Count -1 do
        begin
          WriteString (sec,'Memo_GameUserSettings_Override'+InttoStr(i),        Memo_GameUserSettings_Override.Lines[i]);
        end;

        WriteBool   (sec,'ChB_GUS_Append',                                      ChB_GUS_Append.Checked);
        WriteInteger(sec,'Memo_GameUserSettings_Append_LineCount',              Memo_GameUserSettings_Append.Lines.Count);
        for i:=0 to Memo_GameUserSettings_Append.Lines.Count -1 do
        begin
          WriteString (sec,'Memo_GameUserSettings_Append'+InttoStr(i),          Memo_GameUserSettings_Append.Lines[i]);
        end;

        WriteBool   (sec,'ChB_GS_Override',                                     ChB_GS_Override.Checked);
        WriteInteger(sec,'Memo_GameIni_Override_LineCount',                     Memo_GameIni_Override.Lines.Count);
        for i:=0 to Memo_GameIni_Override.Lines.Count -1 do
        begin
          WriteString (sec,'Memo_GameIni_Override'+InttoStr(i),                 Memo_GameIni_Override.Lines[i]);
        end;

        WriteBool   (sec,'ChB_GS_Append',                                       ChB_GS_Append.Checked);
        WriteInteger(sec,'Memo_GameIni_Append_LineCount',                       Memo_GameIni_Append.Lines.Count);
        for i:=0 to Memo_GameIni_Append.Lines.Count -1 do
        begin
          WriteString (sec,'Memo_GameIni_Append'+InttoStr(i),                   Memo_GameIni_Append.Lines[i]);
        end;
      end;

      sec := 'Experimental';
      begin
        WriteBool   (sec,'ChB_ER_Tame',                                         ChB_ER_Tame.Checked);
        WriteBool   (sec,'ChB_ER_Harvesting',                                   ChB_ER_Harvesting.Checked);
        WriteBool   (sec,'ChB_ER_Experience',                                   ChB_ER_Experience.Checked);
        WriteBool   (sec,'ChB_ER_Breeding',                                     ChB_ER_Breeding.Checked);
        WriteBool   (sec,'ChB_ER_Hexagons',                                     ChB_ER_Hexagons.Checked);
        WriteFloat  (sec,'FSE_ER_Tame',                                         FSE_ER_Tame.Value);
        WriteFloat  (sec,'FSE_ER_Harvesting',                                   FSE_ER_Harvesting.Value);
        WriteFloat  (sec,'FSE_ER_Experience',                                   FSE_ER_Experience.Value);
        WriteFloat  (sec,'FSE_ER_Breeding',                                     FSE_ER_Breeding.Value);
        WriteFloat  (sec,'FSE_ER_Breeding2',                                    FSE_ER_Breeding2.Value);
        WriteFloat  (sec,'FSE_ER_Breeding3',                                    FSE_ER_Breeding3.Value);
        WriteFloat  (sec,'FSE_ER_Hexagons',                                     FSE_ER_Hexagons.Value);
        WriteString (sec,'Edit_Export',                                         Edit_Export.Text);
        WriteBool   (sec,'ChB_CleanBackup',                                     ChB_CleanBackup.Checked);

        WriteBool   (sec,'ChB_UseEngineINI',                                    ChB_UseEngineINI.Checked);
        WriteFloat  (sec,'FSE_InitialConnectTimeout',                           FSE_InitialConnectTimeout.Value);
        WriteFloat  (sec,'FSE_ConnectionTimeout',                               FSE_ConnectionTimeout.Value);
        WriteInteger(sec,'SE_P2PConnectionTimeout',                             SE_P2PConnectionTimeout.Value);

        WriteInteger(sec,'SE_HttpTimeout',                                      SE_HttpTimeout.Value);
        WriteInteger(sec,'SE_HttpConnectionTimeout',                            SE_HttpConnectionTimeout.Value);
        WriteInteger(sec,'SE_HttpReceiveTimeout',                               SE_HttpReceiveTimeout.Value);
        WriteInteger(sec,'SE_HttpSendTimeout',                                  SE_HttpSendTimeout.Value);
      end;
    end;
  finally
    dataset.Free;
    SetProfileLog('Profile Saveed.');
  end;
end;

procedure TAsaFrame.loadProfile(sname:string);
var
  dataset  :TMemIniFile;
  i      :Integer;
  rowcnt   :Integer;
  sec      :string;
  sl :TStringList;
  cnt      :Integer;
  DestroyTamesOverLevel :boolean;
  NewDinoGrid :boolean;
  Old_DinoBP :string;
  Lst_DinoBP :string;
begin
  sl := TStringList.Create;

  if (flg_backup) then dataset := TMemIniFile.Create(Edit_Install_Location_Val.Text+'\ShooterGame\Saved\Profile.ini')
                  else dataset := TMemIniFile.Create('Profile\'+sname+'.ini');
  try
    with dataset do
    begin
      sec := 'ASASM';
      begin
        AppVer_old              :=ReadString(sec,'AppVersion'          ,'0.0.0.0');
        ChB_AutoRestart.Checked :=ReadBool  (sec,'ChB_AutoRestart'     ,ChB_AutoRestart.Checked);
        Pnl_SetIni.Color        :=ReadInteger(sec,'Button_SetIni_Color',clForm);
      end;

      sec := 'General';
      begin
        if not flg_backup then
        begin
          beforeProfileName                                    :=ReadString (sec,'Edit_Profile',                                     'err');
          Edit_Profile.Text                                    :=ReadString (sec,'Edit_Profile',                                     'err');
          if (beforeProfileName = 'err') then beforeProfileName:=sname;
          if (Edit_Profile.Text = 'err') then beforeProfileName:=sname;
          ChB_RelativePath.Checked                             :=ReadBool   (sec,'ChB_RelativePath',                                 ChB_RelativePath.Checked);
          if ReadBool(sec,'Sys_RelativePath',false) then
          begin
            Edit_Install_Location_Val.Text                     :=ExtractFilePath(ParamStr(0))+ReadString (sec,'Edit_Install_Location_Val',Edit_Install_Location_Val.Text);
          end else begin
            Edit_Install_Location_Val.Text                     :=ReadString (sec,'Edit_Install_Location_Val',                        Edit_Install_Location_Val.Text);
          end;
          Lbl_InstVer_Val.Caption                              :=ReadString (sec,'Lbl_InstVer_Val',                                  Lbl_InstVer_Val.Caption);
          ArkVer                                               :=ReadString (sec,'ArkVer',                                           Lbl_InstVer_Val.Caption);
          CB_Install_DelMovie.Checked                          :=ReadBool   (sec,'CB_Install_DelMovie',                              CB_Install_DelMovie.Checked);
          ChB_AutoBackup.Checked                               :=ReadBool   (sec,'ChB_AutoBackup',                                   ChB_AutoBackup.Checked);
          ChB_AltSaveDirectoryName.Checked                     :=ReadBool   (sec,'ChB_AltSaveDirectoryName',                         ChB_AltSaveDirectoryName.Checked);
          Edit_AltSaveDirectoryName.Text                       :=ReadString (sec,'Edit_AltSaveDirectoryName',                        Edit_AltSaveDirectoryName.Text);
        end;
        Edit_clusterid.Text                                  :=ReadString (sec,'Edit_clusterid',                                   Edit_clusterid.Text);
        Edit_ClusterDirOverride.Text                         :=ReadString (sec,'Edit_ClusterDirOverride',                          Edit_ClusterDirOverride.Text);
        CB_MapName.ItemIndex                                 :=ReadInteger(sec,'CB_MapName',                                       CB_MapName.ItemIndex);
        CB_MapName.Text                                      :=ReadString(sec,'CB_MapName_Text',                                   'err');
        CB_ActiveEvent.ItemIndex                             :=ReadInteger(sec,'CB_ActiveEvent',                                   CB_ActiveEvent.ItemIndex);
        CB_ActiveEvent2.ItemIndex                            :=ReadInteger(sec,'CB_ActiveEvent2',                                  CB_ActiveEvent2.ItemIndex);
        CB_ActiveEvent_mod.ItemIndex                         :=ReadInteger(sec,'CB_ActiveEvent',                                   CB_ActiveEvent.ItemIndex);
        ChB_MULTIHOME.Checked                                :=ReadBool   (sec,'ChB_MULTIHOME',                                    ChB_MULTIHOME.Checked);
        ChB_UseServerNetSpeedCheck.Checked                   :=ReadBool   (sec,'ChB_UseServerNetSpeedCheck',                       ChB_UseServerNetSpeedCheck.Checked);
        SE_GBUsageToForceRestart_Val.Value                   :=ReadInteger(sec,'SE_GBUsageToForceRestart_Val',                     SE_GBUsageToForceRestart_Val.Value);
        CB_Culture.ItemIndex                                 :=ReadInteger(sec,'CB_Culture',                                       CB_Culture.ItemIndex);
        ChB_NoBattlEye.Checked                               :=ReadBool   (sec,'ChB_NoBattlEye',                                   ChB_NoBattlEye.Checked);
        ChB_AlwaysTickDedicatedSkeletalMeshes.Checked        :=ReadBool   (sec,'ChB_AlwaysTickDedicatedSkeletalMeshes',            ChB_AlwaysTickDedicatedSkeletalMeshes.Checked);
        ChB_UseDynamicConfig.Checked                         :=ReadBool   (sec,'ChB_UseDynamicConfig',                             ChB_UseDynamicConfig.Checked);
        ChB_disabledinonetrangescaling.Checked               :=ReadBool   (sec,'ChB_disabledinonetrangescaling',                   ChB_disabledinonetrangescaling.Checked);
        SE_WinLiveMaxPlayers_Val.Value                       :=ReadInteger(sec,'SE_WinLiveMaxPlayers_Val',                         SE_WinLiveMaxPlayers_Val.Value);
        Edit_Mods.Text                                       :=ReadString (sec,'Edit_Mods',                                        Edit_Mods.Text);
        beforeMods := Edit_Mods.Text;
        Edit_passivemods.Text                                :=ReadString (sec,'Edit_passivemods',                                 Edit_passivemods.Text);
        Edit_CustomNotificationURL_Val.Text                  :=ReadString (sec,'Edit_CustomNotificationURL_Val',                   Edit_CustomNotificationURL_Val.Text);
        ChB_NoWildBabies.Checked                             :=ReadBool   (sec,'ChB_NoWildBabies',                                 ChB_NoWildBabies.Checked);
        ChB_ForceAllowCaveFlyers.Checked                     :=ReadBool   (sec,'ChB_ForceAllowCaveFlyers',                         ChB_ForceAllowCaveFlyers.Checked);
        ChB_NoTransferFromFiltering.Checked                  :=ReadBool   (sec,'ChB_NoTransferFromFiltering',                      ChB_NoTransferFromFiltering.Checked);
        Edit_ipv4_Val.Text                                   :=ReadString (sec,'Edit_ipv4_Val',                                    Edit_ipv4_Val.Text);
        Edit_ServerIPv4_Val.Text                             :=ReadString (sec,'Edit_ServerIPv4_Val',                              Edit_ServerIPv4_Val.Text);
        ChB_CMD_override.Checked                             :=ReadBool   (sec,'ChB_CMD_override',                                 ChB_CMD_override.Checked);
        MM_Command_Override.Text                             :=ReadString (sec,'MM_Command_Override',                              '');
        ChB_servergamelog.Checked                            :=ReadBool   (sec,'ChB_servergamelog',                                ChB_servergamelog.Checked);
        ChB_servergamelogincludetribelogs.Checked            :=ReadBool   (sec,'ChB_servergamelogincludetribelogs',                ChB_servergamelogincludetribelogs.Checked);
        ChB_ServerRCONOutputTribeLogs.Checked                :=ReadBool   (sec,'ChB_ServerRCONOutputTribeLogs',                    ChB_ServerRCONOutputTribeLogs.Checked);
        ChB_ForceRespawnDinos.Checked                        :=ReadBool   (sec,'ChB_ForceRespawnDinos',                            ChB_ForceRespawnDinos.Checked);
        ChB_ServerPlatform_ALL.Checked                       :=ReadBool   (sec,'ChB_ServerPlatform_ALL',                           ChB_ServerPlatform_ALL.Checked);
        ChB_ServerPlatform_PC.Checked                        :=ReadBool   (sec,'ChB_ServerPlatform_PC',                            ChB_ServerPlatform_PC.Checked);
        ChB_ServerPlatform_PS5.Checked                       :=ReadBool   (sec,'ChB_ServerPlatform_PS5',                           ChB_ServerPlatform_PS5.Checked);
        ChB_ServerPlatform_XSX.Checked                       :=ReadBool   (sec,'ChB_ServerPlatform_XSX',                           ChB_ServerPlatform_XSX.Checked);
        ChB_ServerPlatform_MSStore.Checked                   :=ReadBool   (sec,'ChB_ServerPlatform_MSStore',                       ChB_ServerPlatform_MSStore.Checked);

        ChB_DisableCustomCosmetics.Checked                   :=ReadBool   (sec,'ChB_DisableCustomCosmetics',                       ChB_DisableCustomCosmetics.Checked);
        ChB_disableCharacterTracker.Checked                  :=ReadBool   (sec,'ChB_disableCharacterTracker',                      ChB_disableCharacterTracker.Checked);
        ChB_DisableDupeLogDeletes.Checked                    :=ReadBool   (sec,'ChB_DisableDupeLogDeletes',                        ChB_DisableDupeLogDeletes.Checked);
        ChB_EasterColors.Checked                             :=ReadBool   (sec,'ChB_EasterColors',                                 ChB_EasterColors.Checked);
        ChB_ForceDupeLog.Checked                             :=ReadBool   (sec,'ChB_ForceDupeLog',                                 ChB_ForceDupeLog.Checked);
        ChB_forceuseperfthreads.Checked                      :=ReadBool   (sec,'ChB_forceuseperfthreads',                          ChB_forceuseperfthreads.Checked);
        ChB_ignoredupeditems.Checked                         :=ReadBool   (sec,'ChB_ignoredupeditems',                             ChB_ignoredupeditems.Checked);
        ChB_UseItemDupeCheck.Checked                         :=ReadBool   (sec,'ChB_UseItemDupeCheck',                             ChB_UseItemDupeCheck.Checked);
        ChB_NoAI.Checked                                     :=ReadBool   (sec,'ChB_NoAI',                                         ChB_NoAI.Checked);
        ChB_nodinos.Checked                                  :=ReadBool   (sec,'ChB_nodinos',                                      ChB_nodinos.Checked);
        ChB_NoDinosExceptForcedSpawn.Checked                 :=ReadBool   (sec,'ChB_NoDinosExceptForcedSpawn',                     ChB_NoDinosExceptForcedSpawn.Checked);
        ChB_NoDinosExceptStreamingSpawn.Checked              :=ReadBool   (sec,'ChB_NoDinosExceptStreamingSpawn',                  ChB_NoDinosExceptStreamingSpawn.Checked);
        ChB_NoDinosExceptManualSpawn.Checked                 :=ReadBool   (sec,'ChB_NoDinosExceptManualSpawn',                     ChB_NoDinosExceptManualSpawn.Checked);
        ChB_NoDinosExceptWaterSpawn.Checked                  :=ReadBool   (sec,'ChB_NoDinosExceptWaterSpawn',                      ChB_NoDinosExceptWaterSpawn.Checked);
        ChB_noperfthreads.Checked                            :=ReadBool   (sec,'ChB_noperfthreads',                                ChB_noperfthreads.Checked);
        ChB_nosound.Checked                                  :=ReadBool   (sec,'ChB_nosound',                                      ChB_nosound.Checked);
        ChB_onethread.Checked                                :=ReadBool   (sec,'ChB_onethread',                                    ChB_onethread.Checked);
        ChB_NoTimeout.Checked                                :=ReadBool   (sec,'ChB_NoTimeout',                                    ChB_NoTimeout.Checked);
        ChB_StasisKeepControllers.Checked                    :=ReadBool   (sec,'ChB_StasisKeepControllers',                        ChB_StasisKeepControllers.Checked);
        ChB_UnstasisDinoObstructionCheck.Checked             :=ReadBool   (sec,'ChB_UnstasisDinoObstructionCheck',                 ChB_UnstasisDinoObstructionCheck.Checked);
        ChB_AutoDestroyStructures.Checked                    :=ReadBool   (sec,'ChB_AutoDestroyStructures',                        ChB_AutoDestroyStructures.Checked);
        ChB_exclusivejoin.Checked                            :=ReadBool   (sec,'ChB_exclusivejoin',                                ChB_exclusivejoin.Checked);
        ChB_ForceClampItemQuality.Checked                    :=ReadBool   (sec,'ChB_ForceClampItemQuality',                        ChB_ForceClampItemQuality.Checked);
        ChB_ForceWipeTinkerExploit.Checked                   :=ReadBool   (sec,'ChB_ForceWipeTinkerExploit',                       ChB_ForceWipeTinkerExploit.Checked);
        ChB_ForceWipeTinkerExploitNoDinos.Checked            :=ReadBool   (sec,'ChB_ForceWipeTinkerExploitNoDinos',                ChB_ForceWipeTinkerExploitNoDinos.Checked);

        ChB_FixThrallStats.Checked                           :=ReadBool   (sec,'ChB_FixThrallStats',                               ChB_FixThrallStats.Checked);
        ChB_ForceCharRespec.Checked                          :=ReadBool   (sec,'ChB_ForceCharRespec',                              ChB_ForceCharRespec.Checked);
        ChB_allowicefox.Checked                              :=ReadBool   (sec,'ChB_allowicefox',                                  ChB_allowicefox.Checked);

        ChB_OlympicColors.Checked                            :=ReadBool   (sec,'ChB_OlynpicColors',                                ChB_OlympicColors.Checked);
        ChB_PrideColors.Checked                              :=ReadBool   (sec,'ChB_PrideColors',                                  ChB_PrideColors.Checked);
        ChB_HalloweenColors.Checked                          :=ReadBool   (sec,'ChB_HalloweenColors',                              ChB_HalloweenColors.Checked);
        ChB_ServerUseEventColors.Checked                     :=ReadBool   (sec,'ChB_ServerUseEventColors',                         ChB_ServerUseEventColors.Checked);
        ChB_RedownloadModsOnServerRestart.Checked            :=ReadBool   (sec,'ChB_RedownloadModsOnServerRestart',                ChB_RedownloadModsOnServerRestart.Checked);
        ChB_USE_AsaApiLoader.Checked                         :=ReadBool   (sec,'ChB_USE_AsaApiLoader',                             ChB_USE_AsaApiLoader.Checked);

        DestroyTamesOverLevel                                :=ReadBool   (sec,'SE_DestroyTamesOverLevel_CNV',                     false);
        SE_DestroyTamesOverLevel.Value                       :=ReadInteger(sec,'SE_DestroyTamesOverLevel',                         SE_DestroyTamesOverLevel.Value);
        if not DestroyTamesOverLevel then SE_DestroyTamesOverLevel.Value := 0;

        // New ActiveEvent Convert
        begin
          cnt := ReadInteger(sec,'CG_ActiveEventCount',-99);
          if (cnt = -99)then
          begin
            if (ReadInteger(sec,'CB_ActiveEvent',CB_ActiveEvent.ItemIndex)>=1) then
            begin
              CG_ActiveEvent.Checked[CB_ActiveEvent.ItemIndex-1] := true;
            end;
          end else begin
            for i:= 0 to CG_ActiveEvent.Items.Count -1 do
            begin
              CG_ActiveEvent.Checked[i]                      :=ReadBool   (sec,'CG_ActiveEvent'+ InttoStr(i),                      CG_ActiveEvent.Checked[i]);
            end;
          end;
        end;
        Edit_AllModInArgs.Text                               :=ReadString (sec,'Edit_AllModInArgs',                                Edit_AllModInArgs.Text);
        if (Edit_AllModInArgs.Text = '') then
        begin
          Mods_Change(CG_ActiveEvent);
          if (Edit_AutoAddedModInArgs.Text<>'') then
          begin
            Edit_AllModInArgs.Text := Edit_AutoAddedModInArgs.Text;
            if (Edit_Mods.Text <> '') then Edit_AllModInArgs.Text := Edit_AllModInArgs.Text + ',';
          end;

          if (Edit_Mods.Text <> '') then
          begin
            Edit_AllModInArgs.Text := Edit_AllModInArgs.Text + Edit_Mods.Text;
          end;
        end;
      end;

      sec := 'Server';
      begin
        Edit_SessionName.Text                                :=ReadString (sec,'Edit_SessionName',                                 Edit_SessionName.Text);
        SE_Port.Value                                        :=ReadInteger(sec,'SE_Port',                                          SE_Port.Value);
        SE_QueryPort.Value                                   :=ReadInteger(sec,'SE_QueryPort',                                     SE_QueryPort.Value);
        ChB_Port_Args.Checked                                :=ReadBool   (sec,'ChB_Port_Args',                                    ChB_Port_Args.Checked);
        ChB_Queryport_Args.Checked                           :=ReadBool   (sec,'ChB_Queryport_Args',                               ChB_Queryport_Args.Checked);
        Edit_ServerPassword.Text                             :=ReadString (sec,'Edit_ServerPassword',                              Edit_ServerPassword.Text);
        Edit_ServerAdminPassword.Text                        :=ReadString (sec,'Edit_ServerAdminPassword',                         Edit_ServerAdminPassword.Text);
        Edit_ServerAdminPassword2.Text                       :=ReadString (sec,'Edit_ServerAdminPassword',                         Edit_ServerAdminPassword2.Text);
        FSE_AutoSavePeriodMinutes.Value                      :=ReadFloat  (sec,'FSE_AutoSavePeriodMinutes',                        FSE_AutoSavePeriodMinutes.Value);
        FSE_KickIdlePlayersPeriod.Value                      :=ReadFloat  (sec,'FSE_KickIdlePlayersPeriod',                        FSE_KickIdlePlayersPeriod.Value);
        ChB_EnableIdlePlayerKick.Checked                     :=ReadBool   (sec,'ChB_EnableIdlePlayerKick',                         ChB_EnableIdlePlayerKick.Checked);
        Edit_ActiveMods_Val.Text                             :=ReadString (sec,'Edit_ActiveMods_Val',                              Edit_ActiveMods_Val.Text);
        Edit_ActiveMapMod_Val.Text                           :=ReadString (sec,'Edit_ActiveMapMod_Val',                            Edit_ActiveMapMod_Val.Text);
        Edit_Message.Text                                    :=ReadString (sec,'Edit_Message',                                     Edit_Message.Text);
        SE_Duration.Value                                    :=ReadInteger(sec,'SE_Duration',                                      SE_Duration.Value);
        ChB_AdminLogging.Checked                             :=ReadBool   (sec,'ChB_AdminLogging',                                 ChB_AdminLogging.Checked);
        ChB_AllowHideDamageSourceFromLogs.Checked            :=ReadBool   (sec,'ChB_AllowHideDamageSourceFromLogs',                ChB_AllowHideDamageSourceFromLogs.Checked);
        ChB_DontAlwaysNotifyPlayerJoined.Checked             :=ReadBool   (sec,'ChB_DontAlwaysNotifyPlayerJoined',                 ChB_DontAlwaysNotifyPlayerJoined.Checked);
        ChB_globalVoiceChat.Checked                          :=ReadBool   (sec,'ChB_globalVoiceChat',                              ChB_globalVoiceChat.Checked);
        ChB_ProximityChat.Checked                            :=ReadBool   (sec,'ChB_ProximityChat',                                ChB_ProximityChat.Checked);
        ChB_noTributeDownloads.Checked                       :=ReadBool   (sec,'ChB_noTributeDownloads',                           ChB_noTributeDownloads.Checked);
        ChB_CrossARKAllowForeignDinoDownloads.Checked        :=ReadBool   (sec,'ChB_CrossARKAllowForeignDinoDownloads',            ChB_CrossARKAllowForeignDinoDownloads.Checked);
        ChB_PreventDownloadItems.Checked                     :=ReadBool   (sec,'ChB_PreventDownloadItems',                         ChB_PreventDownloadItems.Checked);
        ChB_PreventDownloadSurvivors.Checked                 :=ReadBool   (sec,'ChB_PreventDownloadSurvivors',                     ChB_PreventDownloadSurvivors.Checked);
        ChB_PreventDownloadDinos.Checked                     :=ReadBool   (sec,'ChB_PreventDownloadDinos',                         ChB_PreventDownloadDinos.Checked);
        ChB_PreventUploadItems.Checked                       :=ReadBool   (sec,'ChB_PreventUploadItems',                           ChB_PreventUploadItems.Checked);
        ChB_PreventUploadSurvivors.Checked                   :=ReadBool   (sec,'ChB_PreventUploadSurvivors',                       ChB_PreventUploadSurvivors.Checked);
        ChB_PreventUploadDinos.Checked                       :=ReadBool   (sec,'ChB_PreventUploadDinos',                           ChB_PreventUploadDinos.Checked);
        SE_MaxTributeDinos.Value                             :=ReadInteger(sec,'SE_MaxTributeDinos',                               SE_MaxTributeDinos.Value);
        SE_MaxTributeItems.Value                             :=ReadInteger(sec,'SE_MaxTributeItems',                               SE_MaxTributeItems.Value);
        SE_MaxTributeCharacters.Value                        :=ReadInteger(sec,'SE_MaxTributeCharacters',                          SE_MaxTributeCharacters.Value);
        SE_TributeItemExpirationSeconds.Value                :=ReadInteger(sec,'SE_TributeItemExpirationSeconds',                  SE_TributeItemExpirationSeconds.Value);
        SE_TributeCharacterExpirationSeconds.Value           :=ReadInteger(sec,'SE_TributeCharacterExpirationSeconds',             SE_TributeCharacterExpirationSeconds.Value);
        SE_TributeDinoExpirationSeconds.Value                :=ReadInteger(sec,'SE_TributeDinoExpirationSeconds',                  SE_TributeDinoExpirationSeconds.Value);

        CB_RCONEnabled.Checked                               :=ReadBool   (sec,'CB_RCONEnabled',                                   CB_RCONEnabled.Checked);
        SE_RCONPort.Value                                    :=ReadInteger(sec,'SE_RCONPort',                                      SE_RCONPort.Value);
        ChB_RCONPort_Args.Checked                            :=ReadBool   (sec,'ChB_RCONPort_Args',                                ChB_RCONPort_Args.Checked);
        FSE_RCONServerGameLogBuffer.Value                    :=ReadFloat  (sec,'FSE_RCONServerGameLogBuffer',                      FSE_RCONServerGameLogBuffer.Value);
        ChB_AlwaysNotifyPlayerLeft.Checked                   :=ReadBool   (sec,'ChB_AlwaysNotifyPlayerLeft',                       ChB_AlwaysNotifyPlayerLeft.Checked);
        ChB_bShowCreativeMode.Checked                        :=ReadBool   (sec,'ChB_bShowCreativeMode',                            ChB_bShowCreativeMode.Checked);
        ChB_OverrideStartTime.Checked                        :=ReadBool   (sec,'ChB_OverrideStartTime',                            ChB_OverrideStartTime.Checked);
        FSE_StartTimeHour.Value                              :=ReadFloat  (sec,'FSE_StartTimeHour',                                FSE_StartTimeHour.Value);
        SE_OverrideMaxExperiencePointsPlayer.Value           :=ReadInteger(sec,'SE_OverrideMaxExperiencePointsPlayer',             SE_OverrideMaxExperiencePointsPlayer.Value);
        SE_OverrideMaxExperiencePointsDino.Value             :=ReadInteger(sec,'SE_OverrideMaxExperiencePointsDino',               SE_OverrideMaxExperiencePointsDino.Value);

        FSE_AutoRestartIntervalSeconds.Value                 :=ReadFloat  (sec,'FSE_AutoRestartIntervalSeconds',                   FSE_AutoRestartIntervalSeconds.Value);
        SE_PhotoModeRangeLimit.Value                         :=ReadInteger(sec,'SE_PhotoModeRangeLimit',                           SE_PhotoModeRangeLimit.Value);
        FSE_UpdateAllowedCheatersInterval.Value              :=ReadFloat  (sec,'FSE_UpdateAllowedCheatersInterval',                FSE_UpdateAllowedCheatersInterval.Value);
        FSE_ServerAutoForceRespawnWildDinosInterval.Value    :=ReadFloat  (sec,'FSE_ServerAutoForceRespawnWildDinosInterval',      FSE_ServerAutoForceRespawnWildDinosInterval.Value);
        ChB_UseCharacterTracker.Checked                      :=ReadBool   (sec,'ChB_UseCharacterTracker',                          ChB_UseCharacterTracker.Checked);
        ChB_ForceExploitedTameDeletion.Checked               :=ReadBool   (sec,'ChB_ForceExploitedTameDeletion',                   ChB_ForceExploitedTameDeletion.Checked);
        Edit_BanListURL.Text                                 :=ReadString (sec,'Edit_BanListURL',                                  Edit_BanListURL.Text);
        Edit_CustomLiveTuningUrl.Text                        :=ReadString (sec,'Edit_CustomLiveTuningUrl',                         Edit_CustomLiveTuningUrl.Text);
        Edit_BadWordListURL.Text                             :=ReadString (sec,'Edit_BadWordListURL',                              Edit_BadWordListURL.Text);
        Edit_BadWordWhiteListURL.Text                        :=ReadString (sec,'Edit_BadWordWhiteListURL',                         Edit_BadWordWhiteListURL.Text);
        Edit_AdminListURL.Text                               :=ReadString (sec,'Edit_AdminListURL',                                Edit_AdminListURL.Text);
        SE_LimitNonPlayerDroppedItemsCount.Value             :=ReadInteger(sec,'SE_LimitNonPlayerDroppedItemsCount',               SE_LimitNonPlayerDroppedItemsCount.Value);
        SE_LimitNonPlayerDroppedItemsRange.Value             :=ReadInteger(sec,'SE_LimitNonPlayerDroppedItemsRange',               SE_LimitNonPlayerDroppedItemsRange.Value);

        ChB_ASASM_AutoDestroyWildDinosSeconds.Checked        :=ReadBool   (sec,'ChB_ASASM_AutoDestroyWildDinosSeconds',            ChB_ASASM_AutoDestroyWildDinosSeconds.Checked);
        SE_ASASM_AutoDestroyWildDinosSeconds.Value           :=ReadInteger(sec,'SE_ASASM_AutoDestroyWildDinosSeconds',             SE_ASASM_AutoDestroyWildDinosSeconds.Value);
        CB_SvrCMDEnabled.Checked                             :=ReadBool   (sec,'CB_SvrCMDEnabled',                                 CB_SvrCMDEnabled.Checked);
        SE_DelayedRestartSec.Value                           :=ReadInteger(sec,'SE_DelayedRestartSec',                             SE_DelayedRestartSec.Value);
      end;

      sec := 'World';
      begin
        FSE_DayCycleSpeedScale.Value                         :=ReadFloat  (sec,'FSE_DayCycleSpeedScale',                           FSE_DayCycleSpeedScale.Value);
        FSE_DayTimeSpeedScale.Value                          :=ReadFloat  (sec,'FSE_DayTimeSpeedScale',                            FSE_DayTimeSpeedScale.Value);
        FSE_NightTimeSpeedScale.Value                        :=ReadFloat  (sec,'FSE_NightTimeSpeedScale',                          FSE_NightTimeSpeedScale.Value);
        FSE_DifficultyOffset.Value                           :=ReadFloat  (sec,'FSE_DifficultyOffset',                             FSE_DifficultyOffset.Value);
        FSE_OverrideOfficialDifficulty.Value                 :=ReadFloat  (sec,'FSE_OverrideOfficialDifficulty',                   FSE_OverrideOfficialDifficulty.Value);
        ChB_ServerHardcore.Checked                           :=ReadBool   (sec,'ChB_ServerHardcore',                               ChB_ServerHardcore.Checked);
        ChB_AllowCaveBuildingPvE.Checked                     :=ReadBool   (sec,'ChB_AllowCaveBuildingPvE',                         ChB_AllowCaveBuildingPvE.Checked);
        ChB_AllowFlyerCarryPvE.Checked                       :=ReadBool   (sec,'ChB_AllowFlyerCarryPvE',                           ChB_AllowFlyerCarryPvE.Checked);
        FSE_PvEDinoDecayPeriodMultiplier.Value               :=ReadFloat  (sec,'FSE_PvEDinoDecayPeriodMultiplier',                 FSE_PvEDinoDecayPeriodMultiplier.Value);
        ChB_DisableDinoDecayPvE.Checked                      :=ReadBool   (sec,'ChB_DisableDinoDecayPvE',                          ChB_DisableDinoDecayPvE.Checked);
        ChB_DisablePvEGamma.Checked                          :=ReadBool   (sec,'ChB_DisablePvEGamma',                              ChB_DisablePvEGamma.Checked);
        ChB_serverPVE.Checked                                :=ReadBool   (sec,'ChB_serverPVE',                                    ChB_serverPVE.Checked);
        ChB_bPvEDisableFriendlyFire.Checked                  :=ReadBool   (sec,'ChB_bPvEDisableFriendlyFire',                      ChB_bPvEDisableFriendlyFire.Checked);
        ChB_DisableStructureDecayPvE.Checked                 :=ReadBool   (sec,'ChB_DisableStructureDecayPvE',                     ChB_DisableStructureDecayPvE.Checked);
        ChB_PvEAllowStructuresAtSupplyDrops.Checked          :=ReadBool   (sec,'ChB_PvEAllowStructuresAtSupplyDrops',              ChB_PvEAllowStructuresAtSupplyDrops.Checked);
        ChB_AllowCaveBuildingPvP.Checked                     :=ReadBool   (sec,'ChB_AllowCaveBuildingPvP',                         ChB_AllowCaveBuildingPvP.Checked);
        ChB_PvPDinoDecay.Checked                             :=ReadBool   (sec,'ChB_PvPDinoDecay',                                 ChB_PvPDinoDecay.Checked);
        ChB_PvPStructureDecay.Checked                        :=ReadBool   (sec,'ChB_PvPStructureDecay',                            ChB_PvPStructureDecay.Checked);
        ChB_EnablePvPGamma.Checked                           :=ReadBool   (sec,'ChB_EnablePvPGamma',                               ChB_EnablePvPGamma.Checked);
        ChB_PreventOfflinePvP.Checked                        :=ReadBool   (sec,'ChB_PreventOfflinePvP',                            ChB_PreventOfflinePvP.Checked);
        FSE_PreventOfflinePvPInterval.Value                  :=ReadFloat  (sec,'FSE_PreventOfflinePvPInterval',                    FSE_PreventOfflinePvPInterval.Value);
        FSE_HarvestAmountMultiplier.Value                    :=ReadFloat  (sec,'FSE_HarvestAmountMultiplier',                      FSE_HarvestAmountMultiplier.Value);
        FSE_HarvestHealthMultiplier.Value                    :=ReadFloat  (sec,'FSE_HarvestHealthMultiplier',                      FSE_HarvestHealthMultiplier.Value);
        FSE_ResourcesRespawnPeriodMultiplier.Value           :=ReadFloat  (sec,'FSE_ResourcesRespawnPeriodMultiplier',             FSE_ResourcesRespawnPeriodMultiplier.Value);
        FSE_ItemStackSizeMultiplier.Value                    :=ReadFloat  (sec,'FSE_ItemStackSizeMultiplier',                      FSE_ItemStackSizeMultiplier.Value);
        SE_MaxPersonalTamedDinos.Value                       :=ReadInteger(sec,'SE_MaxPersonalTamedDinos',                         SE_MaxPersonalTamedDinos.Value);
        FSE_MaxTamedDinos.Value                              :=ReadFloat  (sec,'FSE_MaxTamedDinos',                                FSE_MaxTamedDinos.Value);
        ChB_DestroyTamesOverTheSoftTameLimit.Checked         :=ReadBool   (sec,'ChB_DestroyTamesOverTheSoftTameLimit',             ChB_DestroyTamesOverTheSoftTameLimit.Checked);
        SE_MaxTamedDinos_SoftTameLimit.Value                 :=ReadInteger(sec,'SE_MaxTamedDinos_SoftTameLimit',                   SE_MaxTamedDinos_SoftTameLimit.Value);
        SE_MaxTamedDinos_SoftTameLimit_CountdownForDeletionDuration.Value:=
                                                               ReadInteger(sec,'SE_MaxTamedDinos_SoftTameLimit_CountdownForDeletionDuration',
                                                                                                                                   SE_MaxPersonalTamedDinos.Value);
        FSE_GlobalItemDecompositionTimeMultiplier.Value      :=ReadFloat  (sec,'FSE_GlobalItemDecompositionTimeMultiplier',        FSE_GlobalItemDecompositionTimeMultiplier.Value);
        FSE_GlobalSpoilingTimeMultiplier.Value               :=ReadFloat  (sec,'FSE_GlobalSpoilingTimeMultiplier',                 FSE_GlobalSpoilingTimeMultiplier.Value);
        ChB_PreventDiseases.Checked                          :=ReadBool   (sec,'ChB_PreventDiseases',                              ChB_PreventDiseases.Checked);
        CB_NonPermanentDiseases.Checked                      :=ReadBool   (sec,'CB_NonPermanentDiseases',                          CB_NonPermanentDiseases.Checked);
        ChB_bDisableFriendlyFire.Checked                     :=ReadBool   (sec,'ChB_bDisableFriendlyFire',                         ChB_bDisableFriendlyFire.Checked);
        ChB_ClampItemSpoilingTimes.Checked                   :=ReadBool   (sec,'ChB_ClampItemSpoilingTimes',                       ChB_ClampItemSpoilingTimes.Checked);
        ChB_ClampResourceHarvestDamage.Checked               :=ReadBool   (sec,'ChB_ClampResourceHarvestDamage',                   ChB_ClampResourceHarvestDamage.Checked);
        ChB_ClampItemStats.Checked                           :=ReadBool   (sec,'ChB_ClampItemStats',                               ChB_ClampItemStats.Checked);
        ChB_bUseSingleplayerSettings.Checked                 :=ReadBool   (sec,'ChB_bUseSingleplayerSettings',                     ChB_bUseSingleplayerSettings.Checked);
        ChB_RandomSupplyCratePoints.Checked                  :=ReadBool   (sec,'ChB_RandomSupplyCratePoints',                      ChB_RandomSupplyCratePoints.Checked);
        ChB_EnableExtraStructurePreventionVolumes.Checked    :=ReadBool   (sec,'ChB_EnableExtraStructurePreventionVolumes',        ChB_EnableExtraStructurePreventionVolumes.Checked);
        ChB_AutoDestroyDecayedDinos.Checked                  :=ReadBool   (sec,'ChB_AutoDestroyDecayedDinos',                      ChB_AutoDestroyDecayedDinos.Checked);
        ChB_bForceCanRideFliers.Checked                      :=ReadBool   (sec,'ChB_bForceCanRideFliers',                          ChB_bForceCanRideFliers.Checked);
        ChB_PreventTribeAlliances.Checked                    :=ReadBool   (sec,'ChB_PreventTribeAlliances',                        ChB_PreventTribeAlliances.Checked);
        FSE_TribeNameChangeCooldown.Value                    :=ReadFloat  (sec,'FSE_TribeNameChangeCooldown',                      FSE_TribeNameChangeCooldown.Value);
        FSE_ResourceNoReplenishRadiusPlayers.Value           :=ReadFloat  (sec,'FSE_ResourceNoReplenishRadiusPlayers',             FSE_ResourceNoReplenishRadiusPlayers.Value);
        FSE_ResourceNoReplenishRadiusStructures.Value        :=ReadFloat  (sec,'FSE_ResourceNoReplenishRadiusStructures',          FSE_ResourceNoReplenishRadiusStructures.Value);
        FSE_CropDecaySpeedMultiplier.Value                   :=ReadFloat  (sec,'FSE_CropDecaySpeedMultiplier',                     FSE_CropDecaySpeedMultiplier.Value);
        FSE_CropGrowthSpeedMultiplier.Value                  :=ReadFloat  (sec,'FSE_CropGrowthSpeedMultiplier',                    FSE_CropGrowthSpeedMultiplier.Value);
        FSE_DinoCountMultiplier.Value                        :=ReadFloat  (sec,'FSE_DinoCountMultiplier',                          FSE_DinoCountMultiplier.Value);
        ChB_bDisableDinoRiding.Checked                       :=ReadBool   (sec,'ChB_bDisableDinoRiding',                           ChB_bDisableDinoRiding.Checked);
        ChB_bDisableDinoTaming.Checked                       :=ReadBool   (sec,'ChB_bDisableDinoTaming',                           ChB_bDisableDinoTaming.Checked);
        ChB_bDisableDinoBreeding.Checked                     :=ReadBool   (sec,'ChB_bDisableDinoBreeding',                         ChB_bDisableDinoBreeding.Checked);
        ChB_bAutoUnlockAllEngrams.Checked                    :=ReadBool   (sec,'ChB_bAutoUnlockAllEngrams',                        ChB_bAutoUnlockAllEngrams.Checked);
        ChB_bDisableStructurePlacementCollision.Checked      :=ReadBool   (sec,'ChB_bDisableStructurePlacementCollision',          ChB_bDisableStructurePlacementCollision.Checked);
        ChB_bIgnoreStructuresPreventionVolumes.Checked       :=ReadBool   (sec,'ChB_bIgnoreStructuresPreventionVolumes',           ChB_bIgnoreStructuresPreventionVolumes.Checked);
        ChB_bAllowSpeedLeveling.Checked                      :=ReadBool   (sec,'ChB_bAllowSpeedLeveling',                          ChB_bAllowSpeedLeveling.Checked);
        ChB_bAllowFlyerSpeedLeveling.Checked                 :=ReadBool   (sec,'ChB_bAllowFlyerSpeedLeveling',                     ChB_bAllowFlyerSpeedLeveling.Checked);
        ChB_MaxDifficulty.Checked                            :=ReadBool   (sec,'ChB_MaxDifficulty',                                ChB_MaxDifficulty.Checked);
        ChB_bDisableLootCrates.Checked                       :=ReadBool   (sec,'ChB_bDisableLootCrates',                           ChB_bDisableLootCrates.Checked);
        ChB_bAutoPvETimer.Checked                            :=ReadBool   (sec,'ChB_bAutoPvETimer',                                ChB_bAutoPvETimer.Checked);
        SE_AutoPvEStartTimeSeconds.Value                     :=ReadInteger(sec,'SE_AutoPvEStartTimeSeconds',                       SE_AutoPvEStartTimeSeconds.Value);
        SE_AutoPvEStopTimeSeconds.Value                      :=ReadInteger(sec,'SE_AutoPvEStopTimeSeconds',                        SE_AutoPvEStopTimeSeconds.Value);
        ChB_bAutoPvEUseSystemTime.Checked                    :=ReadBool   (sec,'ChB_bAutoPvEUseSystemTime',                        ChB_bAutoPvEUseSystemTime.Checked);
        ChB_bPvEAllowTribeWar.Checked                        :=ReadBool   (sec,'ChB_bPvEAllowTribeWar',                            ChB_bPvEAllowTribeWar.Checked);
        ChB_bPvEAllowTribeWarCancel.Checked                  :=ReadBool   (sec,'ChB_bPvEAllowTribeWarCancel',                      ChB_bPvEAllowTribeWarCancel.Checked);
        FSE_PvEStructureDecayPeriodMultiplier.Value          :=ReadFloat  (sec,'FSE_PvEStructureDecayPeriodMultiplier',            FSE_PvEStructureDecayPeriodMultiplier.Value);
        ChB_bIncreasePvPRespawnInterval.Checked              :=ReadBool   (sec,'ChB_bIncreasePvPRespawnInterval',                  ChB_bIncreasePvPRespawnInterval.Checked);
        FSE_IncreasePvPRespawnIntervalCheckPeriod.Value      :=ReadFloat  (sec,'FSE_IncreasePvPRespawnIntervalCheckPeriod',        FSE_IncreasePvPRespawnIntervalCheckPeriod.Value);
        FSE_IncreasePvPRespawnIntervalMultiplier.Value       :=ReadFloat  (sec,'FSE_IncreasePvPRespawnIntervalMultiplier',         FSE_IncreasePvPRespawnIntervalMultiplier.Value);
        FSE_IncreasePvPRespawnIntervalBaseAmount.Value       :=ReadFloat  (sec,'FSE_IncreasePvPRespawnIntervalBaseAmount',         FSE_IncreasePvPRespawnIntervalBaseAmount.Value);
        SE_PvPZoneStructureDamageMultiplier.Value            :=ReadInteger(sec,'SE_PvPZoneStructureDamageMultiplier',              SE_PvPZoneStructureDamageMultiplier.Value);
        FSE_GlobalCorpseDecompositionTimeMultiplier.Value    :=ReadFloat  (sec,'FSE_GlobalCorpseDecompositionTimeMultiplier',      FSE_GlobalCorpseDecompositionTimeMultiplier.Value);
        SE_MaxNumberOfPlayersInTribe.Value                   :=ReadInteger(sec,'SE_MaxNumberOfPlayersInTribe',                     SE_MaxNumberOfPlayersInTribe.Value);
        FSE_BaseTemperatureMultiplier.Value                  :=ReadFloat  (sec,'FSE_BaseTemperatureMultiplier',                    FSE_BaseTemperatureMultiplier.Value);
        FSE_FuelConsumptionIntervalMultiplier.Value          :=ReadFloat  (sec,'FSE_FuelConsumptionIntervalMultiplier',            FSE_FuelConsumptionIntervalMultiplier.Value);
        SE_MaxTrainCars.Value                                :=ReadInteger(sec,'SE_MaxTrainCars',                                  SE_MaxTrainCars.Value);
        ChB_IgnorePVPMountedWeaponryRestrictions.Checked     :=ReadBool   (sec,'ChB_IgnorePVPMountedWeaponryRestrictions',         ChB_IgnorePVPMountedWeaponryRestrictions.Checked);
        ChB_AllowTeslaCoilCaveBuildingPVP.Checked            :=ReadBool   (sec,'ChB_AllowTeslaCoilCaveBuildingPVP',                ChB_AllowTeslaCoilCaveBuildingPVP.Checked);
        Edit_WorldBossKingKaijuSpawnTime.Text                :=ReadString (sec,'Edit_WorldBossKingKaijuSpawnTime',                 Edit_WorldBossKingKaijuSpawnTime.Text);
        ChB_WorldBossKingKaijuSpawnTime_UTC.Checked          :=ReadBool   (sec,'ChB_WorldBossKingKaijuSpawnTime_UTC',              ChB_WorldBossKingKaijuSpawnTime_UTC.Checked);
        ChB_ForceGachaUnhappyInCaves.Checked                 :=ReadBool   (sec,'ChB_ForceGachaUnhappyInCaves',                     ChB_ForceGachaUnhappyInCaves.Checked);
        SE_ArmadoggoDeathCooldown.Value                      :=ReadInteger(sec,'SE_ArmadoggoDeathCooldown',                        SE_ArmadoggoDeathCooldown.Value);
        SE_MaxBlueprintDinoLevel.Value                       :=ReadInteger(sec,'SE_MaxBlueprintDinoLevel',                         SE_MaxBlueprintDinoLevel.Value);
        SE_MaxBlueprintDinoQuality.Value                     :=ReadInteger(sec,'SE_MaxBlueprintDinoQuality',                       SE_MaxBlueprintDinoQuality.Value);
        SE_MaxBlueprintItemQuality.Value                     :=ReadInteger(sec,'SE_MaxBlueprintItemQuality',                       SE_MaxBlueprintItemQuality.Value);
        SE_MaxBlueprintScoutQuality.Value                    :=ReadInteger(sec,'SE_MaxBlueprintScoutQuality',                      SE_MaxBlueprintScoutQuality.Value);
        ChB_bAllowBuildingInNoBuildZone.Checked              :=ReadBool   (sec,'ChB_bAllowBuildingInNoBuildZone',                  ChB_bAllowBuildingInNoBuildZone.Checked);
        ChB_bUseCorpseLocator.Checked                        :=ReadBool   (sec,'ChB_bUseCorpseLocator',                            ChB_bUseCorpseLocator.Checked);
        ChB_bAllowFlyerDinoSubmerging.Checked                :=ReadBool   (sec,'ChB_bAllowFlyerDinoSubmerging',                    ChB_bAllowFlyerDinoSubmerging.Checked);

        SE_YoungIceFoxDeathCooldown.Value                    :=ReadInteger(sec,'SE_YoungIceFoxDeathCooldown',                      SE_YoungIceFoxDeathCooldown.Value);
        SE_CompanionsDeathCooldown.Value                     :=ReadInteger(sec,'SE_CompanionsDeathCooldown',                       SE_CompanionsDeathCooldown.Value);

        FSE_TribeTowerBonusMultiplier.Value                  :=ReadFloat  (sec,'FSE_TribeTowerBonusMultiplier',                    FSE_TribeTowerBonusMultiplier.Value);

        ChB_LimitBunkersPerTribe.Checked                     :=ReadBool   (sec,'ChB_LimitBunkersPerTribe',                         ChB_LimitBunkersPerTribe.Checked);
        SE_LimitBunkersPerTribeNum.Value                     :=ReadInteger(sec,'SE_LimitBunkersPerTribeNum',                       SE_LimitBunkersPerTribeNum.Value);
        ChB_AllowBunkersInPreventionZones.Checked            :=ReadBool   (sec,'ChB_AllowBunkersInPreventionZones',                ChB_AllowBunkersInPreventionZones.Checked);
        ChB_AllowRidingDinosInsideBunkers.Checked            :=ReadBool   (sec,'ChB_AllowRidingDinosInsideBunkers',                ChB_AllowRidingDinosInsideBunkers.Checked);
        ChB_AllowBunkerModulesAboveGround.Checked            :=ReadBool   (sec,'ChB_AllowBunkerModulesAboveGround',                ChB_AllowBunkerModulesAboveGround.Checked);
        ChB_AllowDinoAIInsideBunkers.Checked                 :=ReadBool   (sec,'ChB_AllowDinoAIInsideBunkers',                     ChB_AllowDinoAIInsideBunkers.Checked);
        ChB_AllowBunkerModulesInPreventionZones.Checked      :=ReadBool   (sec,'ChB_AllowBunkerModulesInPreventionZones',          ChB_AllowBunkerModulesInPreventionZones.Checked);
        FSE_MinDistanceBetweenBunkers.Value                  :=ReadFloat  (sec,'FSE_MinDistanceBetweenBunkers',                    FSE_MinDistanceBetweenBunkers.Value);
        FSE_EnemyAccessBunkerHPThreshold.Value               :=ReadFloat  (sec,'FSE_EnemyAccessBunkerHPThreshold',                 FSE_EnemyAccessBunkerHPThreshold.Value);
        FSE_BunkerUnderHPThresholdDmgMultiplier.Value        :=ReadFloat  (sec,'FSE_BunkerUnderHPThresholdDmgMultiplier',          FSE_BunkerUnderHPThresholdDmgMultiplier.Value);

        FSE_CryoHospitalHoursToRegenHP.Value                 :=ReadFloat  (sec,'FSE_CryoHospitalHoursToRegenHP',                   FSE_CryoHospitalHoursToRegenHP.Value);
        FSE_CryoHospitalHoursToRegenFood.Value               :=ReadFloat  (sec,'FSE_CryoHospitalHoursToRegenFood',                 FSE_CryoHospitalHoursToRegenFood.Value);
        FSE_CryoHospitalHoursToDrainTorpor.Value             :=ReadFloat  (sec,'FSE_CryoHospitalHoursToDrainTorpor',               FSE_CryoHospitalHoursToDrainTorpor.Value);
        FSE_CryoHospitalMatingCooldownReduction.Value        :=ReadFloat  (sec,'FSE_CryoHospitalMatingCooldownReduction',          FSE_CryoHospitalMatingCooldownReduction.Value);

        FSE_BloodforgeReinforceExtraDurability.Value         :=ReadFloat  (sec,'FSE_BloodforgeReinforceExtraDurability',           FSE_BloodforgeReinforceExtraDurability.Value);
        FSE_BloodforgeReinforceResourceCostMultiplier.Value  :=ReadFloat  (sec,'FSE_BloodforgeReinforceResourceCostMultiplier',    FSE_BloodforgeReinforceResourceCostMultiplier.Value);
        FSE_BloodforgeReinforceSpeedMultiplier.Value         :=ReadFloat  (sec,'FSE_BloodforgeReinforceSpeedMultiplier',           FSE_BloodforgeReinforceSpeedMultiplier.Value);

        SE_MaxActiveOutposts.Value                           :=ReadInteger(sec,'SE_MaxActiveOutposts',                             SE_MaxActiveOutposts.Value);
        SE_MaxActiveResourceCaches.Value                     :=ReadInteger(sec,'SE_MaxActiveResourceCaches',                       SE_MaxActiveResourceCaches.Value);
        SE_MaxActiveCityOutposts.Value                       :=ReadInteger(sec,'SE_MaxActiveCityOutposts',                         SE_MaxActiveCityOutposts.Value);
      end;

      sec := 'VisualHUD';
      begin
        ChB_AllowHitMarkers.Checked                          :=ReadBool   (sec,'ChB_AllowHitMarkers',                              ChB_AllowHitMarkers.Checked);
        ChB_AllowThirdPersonPlayer.Checked                   :=ReadBool   (sec,'ChB_AllowThirdPersonPlayer',                       ChB_AllowThirdPersonPlayer.Checked);
        ChB_DisableWeatherFog.Checked                        :=ReadBool   (sec,'ChB_DisableWeatherFog',                            ChB_DisableWeatherFog.Checked);
        ChB_ServerCrosshair.Checked                          :=ReadBool   (sec,'ChB_ServerCrosshair',                              ChB_ServerCrosshair.Checked);
        ChB_ServerForceNoHUD.Checked                         :=ReadBool   (sec,'ChB_ServerForceNoHUD',                             ChB_ServerForceNoHUD.Checked);
        ChB_ShowFloatingDamageText.Checked                   :=ReadBool   (sec,'ChB_ShowFloatingDamageText',                       ChB_ShowFloatingDamageText.Checked);
        ChB_ShowMapPlayerLocation.Checked                    :=ReadBool   (sec,'ChB_ShowMapPlayerLocation',                        ChB_ShowMapPlayerLocation.Checked);
        ChB_bDisablePhotoMode.Checked                        :=ReadBool   (sec,'ChB_bDisablePhotoMode',                            ChB_bDisablePhotoMode.Checked);

        RG_Cosmetic_Kind.ItemIndex                           :=ReadInteger(sec,'RG_Cosmetic_Kind',                                 RG_Cosmetic_Kind.ItemIndex);
        Edit_Cosmetic_URL.Text                               :=ReadString (sec,'Edit_Cosmetic_URL',                                Edit_Cosmetic_URL.Text);
        Edit_Cosmetic_LocalFile.Text                         :=ReadString (sec,'Edit_Cosmetic_LocalFile',                          Edit_Cosmetic_LocalFile.Text);
        SG_Cosmetic.RowCount                                 :=ReadInteger(sec,'SG_Cosmetic_RowCount',                             SG_Cosmetic.RowCount) +1;
        for i := 1 to SG_Cosmetic.RowCount -1 do
        begin
          SG_Cosmetic.Rows[i].CommaText                      :=ReadString (sec,'SG_Cosmetic_Text' + IntToStr(i),                   '');
        end;
      end;

      sec := 'Player';
      begin
        FSE_PlayerBaseStatMultipliers0.Value                  :=ReadFloat  (sec,'FSE_PlayerBaseStatMultipliers0',                  FSE_PlayerBaseStatMultipliers0.Value);
        FSE_PlayerBaseStatMultipliers1.Value                  :=ReadFloat  (sec,'FSE_PlayerBaseStatMultipliers1',                  FSE_PlayerBaseStatMultipliers1.Value);
        FSE_PlayerBaseStatMultipliers2.Value                  :=ReadFloat  (sec,'FSE_PlayerBaseStatMultipliers2',                  FSE_PlayerBaseStatMultipliers2.Value);
        FSE_PlayerBaseStatMultipliers3.Value                  :=ReadFloat  (sec,'FSE_PlayerBaseStatMultipliers3',                  FSE_PlayerBaseStatMultipliers3.Value);
        FSE_PlayerBaseStatMultipliers4.Value                  :=ReadFloat  (sec,'FSE_PlayerBaseStatMultipliers4',                  FSE_PlayerBaseStatMultipliers4.Value);
        FSE_PlayerBaseStatMultipliers5.Value                  :=ReadFloat  (sec,'FSE_PlayerBaseStatMultipliers5',                  FSE_PlayerBaseStatMultipliers5.Value);
        FSE_PlayerBaseStatMultipliers6.Value                  :=ReadFloat  (sec,'FSE_PlayerBaseStatMultipliers6',                  FSE_PlayerBaseStatMultipliers6.Value);
        FSE_PlayerBaseStatMultipliers7.Value                  :=ReadFloat  (sec,'FSE_PlayerBaseStatMultipliers7',                  FSE_PlayerBaseStatMultipliers7.Value);
        FSE_PlayerBaseStatMultipliers8.Value                  :=ReadFloat  (sec,'FSE_PlayerBaseStatMultipliers8',                  FSE_PlayerBaseStatMultipliers8.Value);
        FSE_PlayerBaseStatMultipliers9.Value                  :=ReadFloat  (sec,'FSE_PlayerBaseStatMultipliers9',                  FSE_PlayerBaseStatMultipliers9.Value);
        FSE_PlayerBaseStatMultipliers10.Value                 :=ReadFloat  (sec,'FSE_PlayerBaseStatMultipliers10',                 FSE_PlayerBaseStatMultipliers10.Value);
        FSE_PlayerBaseStatMultipliers11.Value                 :=ReadFloat  (sec,'FSE_PlayerBaseStatMultipliers11',                 FSE_PlayerBaseStatMultipliers11.Value);
        FSE_PerLevelStatsMultiplier_Player0.Value             :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_Player0',             FSE_PerLevelStatsMultiplier_Player0.Value);
        FSE_PerLevelStatsMultiplier_Player1.Value             :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_Player1',             FSE_PerLevelStatsMultiplier_Player1.Value);
        FSE_PerLevelStatsMultiplier_Player2.Value             :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_Player2',             FSE_PerLevelStatsMultiplier_Player2.Value);
        FSE_PerLevelStatsMultiplier_Player3.Value             :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_Player3',             FSE_PerLevelStatsMultiplier_Player3.Value);
        FSE_PerLevelStatsMultiplier_Player4.Value             :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_Player4',             FSE_PerLevelStatsMultiplier_Player4.Value);
        FSE_PerLevelStatsMultiplier_Player5.Value             :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_Player5',             FSE_PerLevelStatsMultiplier_Player5.Value);
        FSE_PerLevelStatsMultiplier_Player6.Value             :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_Player6',             FSE_PerLevelStatsMultiplier_Player6.Value);
        FSE_PerLevelStatsMultiplier_Player7.Value             :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_Player7',             FSE_PerLevelStatsMultiplier_Player7.Value);
        FSE_PerLevelStatsMultiplier_Player8.Value             :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_Player8',             FSE_PerLevelStatsMultiplier_Player8.Value);
        FSE_PerLevelStatsMultiplier_Player9.Value             :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_Player9',             FSE_PerLevelStatsMultiplier_Player9.Value);
        FSE_PerLevelStatsMultiplier_Player10.Value            :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_Player10',            FSE_PerLevelStatsMultiplier_Player10.Value);
        FSE_PerLevelStatsMultiplier_Player11.Value            :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_Player11',            FSE_PerLevelStatsMultiplier_Player11.Value);
        FSE_OxygenSwimSpeedStatMultiplier.Value               :=ReadFloat  (sec,'FSE_OxygenSwimSpeedStatMultiplier',               FSE_OxygenSwimSpeedStatMultiplier.Value);
        FSE_PlayerCharacterHealthRecoveryMultiplier.Value     :=ReadFloat  (sec,'FSE_PlayerCharacterHealthRecoveryMultiplier',     FSE_PlayerCharacterHealthRecoveryMultiplier.Value);
        FSE_PlayerCharacterWaterDrainMultiplier.Value         :=ReadFloat  (sec,'FSE_PlayerCharacterWaterDrainMultiplier',         FSE_PlayerCharacterWaterDrainMultiplier.Value);
        FSE_PlayerResistanceMultiplier.Value                  :=ReadFloat  (sec,'FSE_PlayerResistanceMultiplier',                  FSE_PlayerResistanceMultiplier.Value);
        FSE_PlayerCharacterFoodDrainMultiplier.Value          :=ReadFloat  (sec,'FSE_PlayerCharacterFoodDrainMultiplier',          FSE_PlayerCharacterFoodDrainMultiplier.Value);
        FSE_PlayerCharacterStaminaDrainMultiplier.Value       :=ReadFloat  (sec,'FSE_PlayerCharacterStaminaDrainMultiplier',       FSE_PlayerCharacterStaminaDrainMultiplier.Value);
        FSE_PlayerDamageMultiplier.Value                      :=ReadFloat  (sec,'FSE_PlayerDamageMultiplier',                      FSE_PlayerDamageMultiplier.Value);
        FSE_PoopIntervalMultiplier.Value                      :=ReadFloat  (sec,'FSE_PoopIntervalMultiplier',                      FSE_PoopIntervalMultiplier.Value);
        FSE_PlayerHarvestingDamageMultiplier.Value            :=ReadFloat  (sec,'FSE_PlayerHarvestingDamageMultiplier',            FSE_PlayerHarvestingDamageMultiplier.Value);
        ChB_PreventSpawnAnimations.Checked                    :=ReadBool   (sec,'ChB_PreventSpawnAnimations',                      ChB_PreventSpawnAnimations.Checked);
        ChB_bAllowUnlimitedRespecs.Checked                    :=ReadBool   (sec,'ChB_bAllowUnlimitedRespecs',                      ChB_bAllowUnlimitedRespecs.Checked);
        FSE_MaxFallSpeedMultiplier.Value                      :=ReadFloat  (sec,'FSE_MaxFallSpeedMultiplier',                      FSE_MaxFallSpeedMultiplier.Value);
        FSE_UseCorpseLifeSpanMultiplier.Value                 :=ReadFloat  (sec,'FSE_UseCorpseLifeSpanMultiplier',                 FSE_UseCorpseLifeSpanMultiplier.Value);
        SE_ImplantSuicideCD.Value                             :=ReadInteger(sec,'SE_ImplantSuicideCD',                             SE_ImplantSuicideCD.Value);
        SE_MaxHexagonsPerCharacter.Value                      :=ReadInteger(sec,'SE_MaxHexagonsPerCharacter',                      SE_MaxHexagonsPerCharacter.Value);
        FSE_BaseHexagonRewardMultiplier.Value                 :=ReadFloat  (sec,'FSE_BaseHexagonRewardMultiplier',                 FSE_BaseHexagonRewardMultiplier.Value);
        FSE_HexagonCostMultiplier.Value                       :=ReadFloat  (sec,'FSE_HexagonCostMultiplier',                       FSE_HexagonCostMultiplier.Value);
      end;

      sec := 'TamedDino';
      begin
        FSE_PerLevelStatsMultiplier_DinoTamed0.Value          :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed0',          FSE_PerLevelStatsMultiplier_DinoTamed0.Value);
        FSE_PerLevelStatsMultiplier_DinoTamed1.Value          :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed1',          FSE_PerLevelStatsMultiplier_DinoTamed1.Value);
        FSE_PerLevelStatsMultiplier_DinoTamed2.Value          :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed2',          FSE_PerLevelStatsMultiplier_DinoTamed2.Value);
        FSE_PerLevelStatsMultiplier_DinoTamed3.Value          :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed3',          FSE_PerLevelStatsMultiplier_DinoTamed3.Value);
        FSE_PerLevelStatsMultiplier_DinoTamed4.Value          :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed4',          FSE_PerLevelStatsMultiplier_DinoTamed4.Value);
        FSE_PerLevelStatsMultiplier_DinoTamed5.Value          :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed5',          FSE_PerLevelStatsMultiplier_DinoTamed5.Value);
        FSE_PerLevelStatsMultiplier_DinoTamed6.Value          :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed6',          FSE_PerLevelStatsMultiplier_DinoTamed6.Value);
        FSE_PerLevelStatsMultiplier_DinoTamed7.Value          :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed7',          FSE_PerLevelStatsMultiplier_DinoTamed7.Value);
        FSE_PerLevelStatsMultiplier_DinoTamed8.Value          :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed8',          FSE_PerLevelStatsMultiplier_DinoTamed8.Value);
        FSE_PerLevelStatsMultiplier_DinoTamed9.Value          :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed9',          FSE_PerLevelStatsMultiplier_DinoTamed9.Value);
        FSE_PerLevelStatsMultiplier_DinoTamed10.Value         :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed10',         FSE_PerLevelStatsMultiplier_DinoTamed10.Value);
        FSE_PerLevelStatsMultiplier_DinoTamed_Affinity0.Value :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Affinity0', FSE_PerLevelStatsMultiplier_DinoTamed_Affinity0.Value);
        FSE_PerLevelStatsMultiplier_DinoTamed_Affinity1.Value :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Affinity1', FSE_PerLevelStatsMultiplier_DinoTamed_Affinity1.Value);
        FSE_PerLevelStatsMultiplier_DinoTamed_Affinity2.Value :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Affinity2', FSE_PerLevelStatsMultiplier_DinoTamed_Affinity2.Value);
        FSE_PerLevelStatsMultiplier_DinoTamed_Affinity3.Value :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Affinity3', FSE_PerLevelStatsMultiplier_DinoTamed_Affinity3.Value);
        FSE_PerLevelStatsMultiplier_DinoTamed_Affinity4.Value :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Affinity4', FSE_PerLevelStatsMultiplier_DinoTamed_Affinity4.Value);
        FSE_PerLevelStatsMultiplier_DinoTamed_Affinity5.Value :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Affinity5', FSE_PerLevelStatsMultiplier_DinoTamed_Affinity5.Value);
        FSE_PerLevelStatsMultiplier_DinoTamed_Affinity6.Value :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Affinity6', FSE_PerLevelStatsMultiplier_DinoTamed_Affinity6.Value);
        FSE_PerLevelStatsMultiplier_DinoTamed_Affinity7.Value :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Affinity7', FSE_PerLevelStatsMultiplier_DinoTamed_Affinity7.Value);
        FSE_PerLevelStatsMultiplier_DinoTamed_Affinity8.Value :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Affinity8', FSE_PerLevelStatsMultiplier_DinoTamed_Affinity8.Value);
        FSE_PerLevelStatsMultiplier_DinoTamed_Affinity9.Value :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Affinity9', FSE_PerLevelStatsMultiplier_DinoTamed_Affinity9.Value);
        FSE_PerLevelStatsMultiplier_DinoTamed_Affinity10.Value:=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Affinity10',FSE_PerLevelStatsMultiplier_DinoTamed_Affinity10.Value);
        ChB_AllowAnyoneBabyImprintCuddle.Checked              :=ReadBool   (sec,'ChB_AllowAnyoneBabyImprintCuddle',                ChB_AllowAnyoneBabyImprintCuddle.Checked);
        FSE_BabyCuddleGracePeriodMultiplier.Value             :=ReadFloat  (sec,'FSE_BabyCuddleGracePeriodMultiplier',             FSE_BabyCuddleGracePeriodMultiplier.Value);
        FSE_BabyCuddleIntervalMultiplier.Value                :=ReadFloat  (sec,'FSE_BabyCuddleIntervalMultiplier',                FSE_BabyCuddleIntervalMultiplier.Value);
        FSE_BabyCuddleLoseImprintQualitySpeedMultiplier.Value :=ReadFloat  (sec,'FSE_BabyCuddleLoseImprintQualitySpeedMultiplier', FSE_BabyCuddleLoseImprintQualitySpeedMultiplier.Value);
        FSE_BabyFoodConsumptionSpeedMultiplier.Value          :=ReadFloat  (sec,'FSE_BabyFoodConsumptionSpeedMultiplier',          FSE_BabyFoodConsumptionSpeedMultiplier.Value);
        FSE_BabyImprintAmountMultiplier.Value                 :=ReadFloat  (sec,'FSE_BabyImprintAmountMultiplier',                 FSE_BabyImprintAmountMultiplier.Value);
        FSE_BabyImprintingStatScaleMultiplier.Value           :=ReadFloat  (sec,'FSE_BabyImprintingStatScaleMultiplier',           FSE_BabyImprintingStatScaleMultiplier.Value);
        FSE_BabyMatureSpeedMultiplier.Value                   :=ReadFloat  (sec,'FSE_BabyMatureSpeedMultiplier',                   FSE_BabyMatureSpeedMultiplier.Value);
        FSE_EggHatchSpeedMultiplier.Value                     :=ReadFloat  (sec,'FSE_EggHatchSpeedMultiplier',                     FSE_EggHatchSpeedMultiplier.Value);
        FSE_LayEggIntervalMultiplier.Value                    :=ReadFloat  (sec,'FSE_LayEggIntervalMultiplier',                    FSE_LayEggIntervalMultiplier.Value);
        ChB_AllowRaidDinoFeeding.Checked                      :=ReadBool   (sec,'ChB_AllowRaidDinoFeeding',                        ChB_AllowRaidDinoFeeding.Checked);
        ChB_PreventMateBoost.Checked                          :=ReadBool   (sec,'ChB_PreventMateBoost',                            ChB_PreventMateBoost.Checked);
        ChB_DisableImprintDinoBuff.Checked                    :=ReadBool   (sec,'ChB_DisableImprintDinoBuff',                      ChB_DisableImprintDinoBuff.Checked);
        SE_DestroyTamesOverLevelClamp.Value                   :=ReadInteger(sec,'SE_DestroyTamesOverLevelClamp',                   SE_DestroyTamesOverLevelClamp.Value);
        FSE_RaidDinoCharacterFoodDrainMultiplier.Value        :=ReadFloat  (sec,'FSE_RaidDinoCharacterFoodDrainMultiplier',        FSE_RaidDinoCharacterFoodDrainMultiplier.Value);
        FSE_DinoHarvestingDamageMultiplier.Value              :=ReadFloat  (sec,'FSE_DinoHarvestingDamageMultiplier',              FSE_DinoHarvestingDamageMultiplier.Value);
        FSE_MatingIntervalMultiplier.Value                    :=ReadFloat  (sec,'FSE_MatingIntervalMultiplier',                    FSE_MatingIntervalMultiplier.Value);
        ChB_bFlyerPlatformAllowUnalignedDinoBasing.Checked    :=ReadBool   (sec,'ChB_bFlyerPlatformAllowUnalignedDinoBasing',      ChB_bFlyerPlatformAllowUnalignedDinoBasing.Checked);
        ChB_bPassiveDefensesDamageRiderlessDinos.Checked      :=ReadBool   (sec,'ChB_bPassiveDefensesDamageRiderlessDinos',        ChB_bPassiveDefensesDamageRiderlessDinos.Checked);
        FSE_TamedDinoDamageMultiplier.Value                   :=ReadFloat  (sec,'FSE_TamedDinoDamageMultiplier',                   FSE_TamedDinoDamageMultiplier.Value);
        FSE_TamedDinoResistanceMultiplier.Value               :=ReadFloat  (sec,'FSE_TamedDinoResistanceMultiplier',               FSE_TamedDinoResistanceMultiplier.Value);
        FSE_TamedDinoCharacterFoodDrainMultiplier.Value       :=ReadFloat  (sec,'FSE_TamedDinoCharacterFoodDrainMultiplier',       FSE_TamedDinoCharacterFoodDrainMultiplier.Value);
        FSE_TamedDinoTorporDrainMultiplier.Value              :=ReadFloat  (sec,'FSE_TamedDinoTorporDrainMultiplier',              FSE_TamedDinoTorporDrainMultiplier.Value);
        FSE_MatingSpeedMultiplier.Value                       :=ReadFloat  (sec,'FSE_MatingSpeedMultiplier',                       FSE_MatingSpeedMultiplier.Value);
        ChB_bUseDinoLevelUpAnimations.Checked                 :=ReadBool   (sec,'ChB_bUseDinoLevelUpAnimations',                   ChB_bUseDinoLevelUpAnimations.Checked);
        SE_MaxCosmoWeaponAmmo.Value                           :=ReadInteger(sec,'SE_MaxCosmoWeaponAmmo',                           SE_MaxCosmoWeaponAmmo.Value);
        SE_CosmoWeaponAmmoReloadAmount.Value                  :=ReadInteger(sec,'SE_CosmoWeaponAmmoReloadAmount',                  SE_CosmoWeaponAmmoReloadAmount.Value);
      end;

      sec := 'Wiladino';
      begin
        FSE_PerLevelStatsMultiplier_DinoWild0.Value           :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoWild0',           FSE_PerLevelStatsMultiplier_DinoWild0.Value);
        FSE_PerLevelStatsMultiplier_DinoWild1.Value           :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoWild1',           FSE_PerLevelStatsMultiplier_DinoWild1.Value);
        FSE_PerLevelStatsMultiplier_DinoWild2.Value           :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoWild2',           FSE_PerLevelStatsMultiplier_DinoWild2.Value);
        FSE_PerLevelStatsMultiplier_DinoWild3.Value           :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoWild3',           FSE_PerLevelStatsMultiplier_DinoWild3.Value);
        FSE_PerLevelStatsMultiplier_DinoWild4.Value           :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoWild4',           FSE_PerLevelStatsMultiplier_DinoWild4.Value);
        FSE_PerLevelStatsMultiplier_DinoWild5.Value           :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoWild5',           FSE_PerLevelStatsMultiplier_DinoWild5.Value);
        FSE_PerLevelStatsMultiplier_DinoWild6.Value           :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoWild6',           FSE_PerLevelStatsMultiplier_DinoWild6.Value);
        FSE_PerLevelStatsMultiplier_DinoWild7.Value           :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoWild7',           FSE_PerLevelStatsMultiplier_DinoWild7.Value);
        FSE_PerLevelStatsMultiplier_DinoWild8.Value           :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoWild8',           FSE_PerLevelStatsMultiplier_DinoWild8.Value);
        FSE_PerLevelStatsMultiplier_DinoWild9.Value           :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoWild9',           FSE_PerLevelStatsMultiplier_DinoWild9.Value);
        FSE_PerLevelStatsMultiplier_DinoWild10.Value          :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoWild10',          FSE_PerLevelStatsMultiplier_DinoWild10.Value);
        FSE_PerLevelStatsMultiplier_DinoTamed_Add0.Value      :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Add0',      FSE_PerLevelStatsMultiplier_DinoTamed_Add0.Value);
        FSE_PerLevelStatsMultiplier_DinoTamed_Add1.Value      :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Add1',      FSE_PerLevelStatsMultiplier_DinoTamed_Add1.Value);
        FSE_PerLevelStatsMultiplier_DinoTamed_Add2.Value      :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Add2',      FSE_PerLevelStatsMultiplier_DinoTamed_Add2.Value);
        FSE_PerLevelStatsMultiplier_DinoTamed_Add3.Value      :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Add3',      FSE_PerLevelStatsMultiplier_DinoTamed_Add3.Value);
        FSE_PerLevelStatsMultiplier_DinoTamed_Add4.Value      :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Add4',      FSE_PerLevelStatsMultiplier_DinoTamed_Add4.Value);
        FSE_PerLevelStatsMultiplier_DinoTamed_Add5.Value      :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Add5',      FSE_PerLevelStatsMultiplier_DinoTamed_Add5.Value);
        FSE_PerLevelStatsMultiplier_DinoTamed_Add6.Value      :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Add6',      FSE_PerLevelStatsMultiplier_DinoTamed_Add6.Value);
        FSE_PerLevelStatsMultiplier_DinoTamed_Add7.Value      :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Add7',      FSE_PerLevelStatsMultiplier_DinoTamed_Add7.Value);
        FSE_PerLevelStatsMultiplier_DinoTamed_Add8.Value      :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Add8',      FSE_PerLevelStatsMultiplier_DinoTamed_Add8.Value);
        FSE_PerLevelStatsMultiplier_DinoTamed_Add9.Value      :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Add9',      FSE_PerLevelStatsMultiplier_DinoTamed_Add9.Value);
        FSE_PerLevelStatsMultiplier_DinoTamed_Add10.Value     :=ReadFloat  (sec,'FSE_PerLevelStatsMultiplier_DinoTamed_Add10',     FSE_PerLevelStatsMultiplier_DinoTamed_Add10.Value);
        FSE_DinoCharacterFoodDrainMultiplier.Value            :=ReadFloat  (sec,'FSE_DinoCharacterFoodDrainMultiplier',            FSE_DinoCharacterFoodDrainMultiplier.Value);
        FSE_DinoCharacterHealthRecoveryMultiplier.Value       :=ReadFloat  (sec,'FSE_DinoCharacterHealthRecoveryMultiplier',       FSE_DinoCharacterHealthRecoveryMultiplier.Value);
        FSE_DinoCharacterStaminaDrainMultiplier.Value         :=ReadFloat  (sec,'FSE_DinoCharacterStaminaDrainMultiplier',         FSE_DinoCharacterStaminaDrainMultiplier.Value);
        FSE_DinoDamageMultiplier.Value                        :=ReadFloat  (sec,'FSE_DinoDamageMultiplier',                        FSE_DinoDamageMultiplier.Value);
        FSE_DinoResistanceMultiplier.Value                    :=ReadFloat  (sec,'FSE_DinoResistanceMultiplier',                    FSE_DinoResistanceMultiplier.Value);
        FSE_TamingSpeedMultiplier.Value                       :=ReadFloat  (sec,'FSE_TamingSpeedMultiplier',                       FSE_TamingSpeedMultiplier.Value);
        FSE_DinoTurretDamageMultiplier.Value                  :=ReadFloat  (sec,'FSE_DinoTurretDamageMultiplier',                  FSE_DinoTurretDamageMultiplier.Value);
        FSE_PassiveTameIntervalMultiplier.Value               :=ReadFloat  (sec,'FSE_PassiveTameIntervalMultiplier',               FSE_PassiveTameIntervalMultiplier.Value);
        FSE_WildDinoCharacterFoodDrainMultiplier.Value        :=ReadFloat  (sec,'FSE_WildDinoCharacterFoodDrainMultiplier',        FSE_WildDinoCharacterFoodDrainMultiplier.Value);
        FSE_WildDinoTorporDrainMultiplier.Value               :=ReadFloat  (sec,'FSE_WildDinoTorporDrainMultiplier',               FSE_WildDinoTorporDrainMultiplier.Value);
        FSE_OverrideBondedPassImprintMultiplier.Value         :=ReadFloat  (sec,'FSE_OverrideBondedPassImprintMultiplier',         FSE_OverrideBondedPassImprintMultiplier.Value);
      end;

      sec := 'Spawn';
      begin
        rowcnt := SL_SpawnList.RowCount;
        rowcnt := ReadInteger(sec,'SL_SpawnList_RowCount',rowcnt);
        for i:=1 to rowcnt-1 do
        begin
          sl.CommaText := ReadString (sec,'SL_SpawnList'+inttostr(i),'0,0,0,err');
          SL_SpawnList.Cells[1,i]:=sl[0];
          SL_SpawnList.Cells[2,i]:=sl[1];
          SL_SpawnList.Cells[3,i]:=sl[2];
          SL_SpawnList.Cells[4,i]:=sl[3];
        end;

        NewDinoGrid := ReadBool(sec,'New_SpawnList',false);
        if not NewDinoGrid then
        begin
          try
            SL_SpawnList2.RowCount:=1;
            rowcnt := SL_SpawnList.RowCount;
            rowcnt := ReadInteger(sec,'SL_SpawnList_RowCount',rowcnt);
            for i:=1 to rowcnt-1 do
            begin
              Lst_DinoBP := sl_DinoList.Values[sl_DinoList.Names[i-1]];
              Old_DinoBP := ReadString (sec,'SL_SpawnList'+inttostr(i),'');
              if (Old_DinoBP = '') then continue;
              if (Lst_DinoBP <> Old_DinoBP) then
              begin
                SL_SpawnList2.RowCount := SL_SpawnList2.RowCount +1;
                sl.CommaText := Old_DinoBP;
                SL_SpawnList2.Cells[0,SL_SpawnList2.RowCount-1]:=sl_DinoList.Names[i-1];
                SL_SpawnList2.Cells[2,SL_SpawnList2.RowCount-1]:=sl[0];
                SL_SpawnList2.Cells[3,SL_SpawnList2.RowCount-1]:=sl[1];
                SL_SpawnList2.Cells[4,SL_SpawnList2.RowCount-1]:=sl[2];
                SL_SpawnList2.Cells[5,SL_SpawnList2.RowCount-1]:=sl[3];
                SL_SpawnList2.Cells[6,SL_SpawnList2.RowCount-1]:=sl_DinoList.Names[i-1];

                sl.CommaText := Lst_DinoBP;
                SL_SpawnList2.Cells[1,SL_SpawnList2.RowCount-1]:=sl[3];
              end;
            end;
          finally
          end;
        end;
      end;

      sec := 'Spawn2';
      begin
        if NewDinoGrid then
        begin
          SL_SpawnList2.RowCount:=1;
          rowcnt := ReadInteger(sec,'SL_SpawnList_RowCount',rowcnt);
          for i:=1 to rowcnt-1 do
          begin
            sl.CommaText := ReadString (sec,'SL_SpawnList'+inttostr(i),'');
            if (sl.Count >= 6) then
            begin
              SL_SpawnList2.RowCount := SL_SpawnList2.RowCount +1;
              SL_SpawnList2.Cells[6,SL_SpawnList2.RowCount-1]:=sl[0];
              SL_SpawnList2.Cells[0,SL_SpawnList2.RowCount-1]:=sl[0];
              SL_SpawnList2.Cells[1,SL_SpawnList2.RowCount-1]:=sl[1];
              SL_SpawnList2.Cells[2,SL_SpawnList2.RowCount-1]:=sl[2];
              SL_SpawnList2.Cells[3,SL_SpawnList2.RowCount-1]:=sl[3];
              SL_SpawnList2.Cells[4,SL_SpawnList2.RowCount-1]:=sl[4];
              SL_SpawnList2.Cells[5,SL_SpawnList2.RowCount-1]:=sl[5];
            end;
          end;
        end;
      end;

      sec := 'Structure';
      begin
        CB_OverrideStructurePlatformPrevention.Checked        :=ReadBool   (sec,'CB_OverrideStructurePlatformPrevention',          CB_OverrideStructurePlatformPrevention.Checked);
        FSE_PlatformSaddleBuildAreaBoundsMultiplier.Value     :=ReadFloat  (sec,'FSE_PlatformSaddleBuildAreaBoundsMultiplier',     FSE_PlatformSaddleBuildAreaBoundsMultiplier.Value);
        FSE_StructurePickupHoldDuration.Value                 :=ReadFloat  (sec,'FSE_StructurePickupHoldDuration',                 FSE_StructurePickupHoldDuration.Value);
        FSE_StructurePreventResourceRadiusMultiplier.Value    :=ReadFloat  (sec,'FSE_StructurePreventResourceRadiusMultiplier',    FSE_StructurePreventResourceRadiusMultiplier.Value);
        SE_TheMaxStructuresInRange.Value                      :=ReadInteger(sec,'SE_TheMaxStructuresInRange',                      SE_TheMaxStructuresInRange.Value);
        FSE_PerPlatformMaxStructuresMultiplier.Value          :=ReadFloat  (sec,'FSE_PerPlatformMaxStructuresMultiplier',          FSE_PerPlatformMaxStructuresMultiplier.Value);
        FSE_StructurePickupTimeAfterPlacement.Value           :=ReadFloat  (sec,'FSE_StructurePickupTimeAfterPlacement',           FSE_StructurePickupTimeAfterPlacement.Value);
        FSE_StructureResistanceMultiplier.Value               :=ReadFloat  (sec,'FSE_StructureResistanceMultiplier',               FSE_StructureResistanceMultiplier.Value);
        ChB_AllowMultipleAttachedC4.Checked                   :=ReadBool   (sec,'ChB_AllowMultipleAttachedC4',                     ChB_AllowMultipleAttachedC4.Checked);
        ChB_AlwaysAllowStructurePickup.Checked                :=ReadBool   (sec,'ChB_AlwaysAllowStructurePickup',                  ChB_AlwaysAllowStructurePickup.Checked);
        FSE_StructureDamageMultiplier.Value                   :=ReadFloat  (sec,'FSE_StructureDamageMultiplier',                   FSE_StructureDamageMultiplier.Value);
        SE_StructureDamageRepairCooldown.Value                :=ReadInteger(sec,'SE_StructureDamageRepairCooldown',                SE_StructureDamageRepairCooldown.Value);
        FSE_AutoDestroyOldStructuresMultiplier.Value          :=ReadFloat  (sec,'FSE_AutoDestroyOldStructuresMultiplier',          FSE_AutoDestroyOldStructuresMultiplier.Value);
        ChB_AllowCrateSpawnsOnTopOfStructures.Checked         :=ReadBool   (sec,'ChB_AllowCrateSpawnsOnTopOfStructures',           ChB_AllowCrateSpawnsOnTopOfStructures.Checked);
        ChB_ForceAllStructureLocking.Checked                  :=ReadBool   (sec,'ChB_ForceAllStructureLocking',                    ChB_ForceAllStructureLocking.Checked);

        ChB_bHardLimitTurretsInRange.Checked                  :=ReadBool   (sec,'ChB_bHardLimitTurretsInRange',                    ChB_bHardLimitTurretsInRange.Checked);
        ChB_bLimitTurretsInRange.Checked                      :=ReadBool   (sec,'ChB_bLimitTurretsInRange',                        ChB_bLimitTurretsInRange.Checked);
        SE_LimitTurretsNum.Value                              :=ReadInteger(sec,'SE_LimitTurretsNum',                              SE_LimitTurretsNum.Value);
        FSE_LimitTurretsRange.Value                           :=ReadFloat  (sec,'FSE_LimitTurretsRange',                           FSE_LimitTurretsRange.Value);
        SE_MaxPlatformSaddleStructureLimit.Value              :=ReadInteger(sec,'SE_MaxPlatformSaddleStructureLimit',              SE_MaxPlatformSaddleStructureLimit.Value);
        SE_MaxGateFrameOnSaddles.Value                        :=ReadInteger(sec,'SE_MaxGateFrameOnSaddles',                        SE_MaxGateFrameOnSaddles.Value);
        ChB_bAllowPlatformSaddleMultiFloors.Checked           :=ReadBool   (sec,'ChB_bAllowPlatformSaddleMultiFloors',             ChB_bAllowPlatformSaddleMultiFloors.Checked);
      end;

      sec := 'Engrams';
      begin
        FSE_CraftingSkillBonusMultiplier.Value               :=ReadFloat  (sec,'FSE_CraftingSkillBonusMultiplier',                 FSE_CraftingSkillBonusMultiplier.Value);
        FSE_CustomRecipeEffectivenessMultiplier.Value        :=ReadFloat  (sec,'FSE_CustomRecipeEffectivenessMultiplier',          FSE_CustomRecipeEffectivenessMultiplier.Value);
        FSE_CustomRecipeSkillMultiplier.Value                :=ReadFloat  (sec,'FSE_CustomRecipeSkillMultiplier',                  FSE_CustomRecipeSkillMultiplier.Value);
        ChB_DisableCryopodEnemyCheck.Checked                 :=ReadBool   (sec,'ChB_DisableCryopodEnemyCheck',                     ChB_DisableCryopodEnemyCheck.Checked);
        ChB_AllowCryoFridgeOnSaddle.Checked                  :=ReadBool   (sec,'ChB_AllowCryoFridgeOnSaddle',                      ChB_AllowCryoFridgeOnSaddle.Checked);
        ChB_DisableCryopodFridgeRequirement.Checked          :=ReadBool   (sec,'ChB_DisableCryopodFridgeRequirement',              ChB_DisableCryopodFridgeRequirement.Checked);
        ChB_OnlyAllowSpecifiedEngrams.Checked                :=ReadBool   (sec,'ChB_OnlyAllowSpecifiedEngrams',                    ChB_OnlyAllowSpecifiedEngrams.Checked);
        ChB_bAllowCustomRecipes.Checked                      :=ReadBool   (sec,'ChB_bAllowCustomRecipes',                          ChB_bAllowCustomRecipes.Checked);
        FSE_SupplyCrateLootQualityMultiplier.Value           :=ReadFloat  (sec,'FSE_SupplyCrateLootQualityMultiplier',             FSE_SupplyCrateLootQualityMultiplier.Value);
        FSE_FishingLootQualityMultiplier.Value               :=ReadFloat  (sec,'FSE_FishingLootQualityMultiplier',                 FSE_FishingLootQualityMultiplier.Value);
        SE_CryopodFridgeCooldowntime.Value                   :=ReadInteger(sec,'SE_CryopodFridgeCooldowntime',                     SE_CryopodFridgeCooldowntime.Value);

        FSE_CryopodNerfDamageMult.Value                      :=ReadFloat  (sec,'FSE_CryopodNerfDamageMult',                        FSE_CryopodNerfDamageMult.Value);
        FSE_CryopodNerfDuration.Value                        :=ReadFloat  (sec,'FSE_CryopodNerfDuration',                          FSE_CryopodNerfDuration.Value);
        FSE_CryopodNerfIncomingDamageMultPercent.Value       :=ReadFloat  (sec,'FSE_CryopodNerfIncomingDamageMultPercent',         FSE_CryopodNerfIncomingDamageMultPercent.Value);
        ChB_EnableCryopodNerf.Checked                        :=ReadBool   (sec,'ChB_EnableCryopodNerf',                            ChB_EnableCryopodNerf.Checked);
        ChB_EnableCryoSicknessPVE.Checked                    :=ReadBool   (sec,'ChB_EnableCryoSicknessPVE',                        ChB_EnableCryoSicknessPVE.Checked);

        rowcnt := ReadInteger(sec,'SL_OverrideNamedEngramEntries_RowCount',0);
        SL_OverrideNamedEngramEntries.RowCount:=rowcnt+1;
        for i:= 1 to rowcnt do
        begin
          sl.CommaText := ReadString (sec,'SL_OverrideNamedEngramEntries'+inttostr(i),'');
          if (sl.Count>=7) then
          begin
            SL_OverrideNamedEngramEntries.Cells[1,i] := sl[0];
            SL_OverrideNamedEngramEntries.Cells[2,i] := sl[1];
            SL_OverrideNamedEngramEntries.Cells[3,i] := sl[2];
            SL_OverrideNamedEngramEntries.Cells[4,i] := sl[3];
            SL_OverrideNamedEngramEntries.Cells[5,i] := sl[4];
            SL_OverrideNamedEngramEntries.Cells[6,i] := sl[5];
            SL_OverrideNamedEngramEntries.Cells[7,i] := sl[0];
            SL_OverrideNamedEngramEntries.Cells[8,i] := sl[1];
            SL_OverrideNamedEngramEntries.Cells[9,i] := sl[6];
          end;
        end;
      end;

      sec := 'XP';
      begin
        FSE_XPMultiplier.Value                                :=ReadFloat  (sec,'FSE_XPMultiplier',                                FSE_XPMultiplier.Value);
        FSE_GenericXPMultiplier.Value                         :=ReadFloat  (sec,'FSE_GenericXPMultiplier',                         FSE_GenericXPMultiplier.Value);
        FSE_CraftXPMultiplier.Value                           :=ReadFloat  (sec,'FSE_CraftXPMultiplier',                           FSE_CraftXPMultiplier.Value);
        FSE_HarvestXPMultiplier.Value                         :=ReadFloat  (sec,'FSE_HarvestXPMultiplier',                         FSE_HarvestXPMultiplier.Value);
        FSE_KillXPMultiplier.Value                            :=ReadFloat  (sec,'FSE_KillXPMultiplier',                            FSE_KillXPMultiplier.Value);
        FSE_SpecialXPMultiplier.Value                         :=ReadFloat  (sec,'FSE_SpecialXPMultiplier',                         FSE_SpecialXPMultiplier.Value);

        FSE_ExplorerNoteXPMultiplier.Value                    :=ReadFloat  (sec,'FSE_ExplorerNoteXPMultiplier',                    FSE_ExplorerNoteXPMultiplier.Value);
        FSE_BossKillXPMultiplier.Value                        :=ReadFloat  (sec,'FSE_BossKillXPMultiplier',                        FSE_BossKillXPMultiplier.Value);
        FSE_CaveKillXPMultiplier.Value                        :=ReadFloat  (sec,'FSE_CaveKillXPMultiplier',                        FSE_CaveKillXPMultiplier.Value);
        FSE_WildKillXPMultiplier.Value                        :=ReadFloat  (sec,'FSE_WildKillXPMultiplier',                        FSE_WildKillXPMultiplier.Value);
        FSE_TamedKillXPMultiplier.Value                       :=ReadFloat  (sec,'FSE_TamedKillXPMultiplier',                       FSE_TamedKillXPMultiplier.Value);
        FSE_UnclaimedKillXPMultiplier.Value                   :=ReadFloat  (sec,'FSE_UnclaimedKillXPMultiplier',                   FSE_UnclaimedKillXPMultiplier.Value);
        FSE_AlphaKillXPMultiplier.Value                       :=ReadFloat  (sec,'FSE_AlphaKillXPMultiplier',                       FSE_AlphaKillXPMultiplier.Value);
      end;

      sec := 'RCONHistory';
      begin
        rowcnt :=  ReadInteger(sec,'HistoryCount',0);
        for i:= 0 to rowcnt do
        begin
          CB_RCON_Command.Items.Add(ReadString(sec,'Command'+inttostr(i),''));
        end;

        for i := CB_RCON_Command.Items.Count-1 DownTo 0 do
        begin
          if (CB_RCON_Command.Items.Strings[i] = '') then CB_RCON_Command.Items.Delete(i);
        end;
      end;

      sec := 'SvrCMDHistory';
      begin
        rowcnt :=  ReadInteger(sec,'HistoryCount',0);
        for i:= 0 to rowcnt do
        begin
          CB_SvrCMD_Command.Items.Add(ReadString(sec,'Command'+inttostr(i),''));
        end;

        for i := CB_SvrCMD_Command.Items.Count-1 DownTo 0 do
        begin
          if (CB_SvrCMD_Command.Items.Strings[i] = '') then CB_SvrCMD_Command.Items.Delete(i);
        end;
      end;

      sec := 'BroadcacstTxtHistory';
      begin
        rowcnt :=  ReadInteger(sec,'HistoryCount',0);
        for i:= 0 to rowcnt do
        begin
          CB_SvrCMD_BroadcastHist.Items.Add(ReadString(sec,'Command'+inttostr(i),''));
        end;

        for i := CB_SvrCMD_BroadcastHist.Items.Count-1 DownTo 0 do
        begin
          if (CB_SvrCMD_BroadcastHist.Items.Strings[i] = '') then CB_SvrCMD_BroadcastHist.Items.Delete(i);
        end;
      end;

      sec := 'Mod1';
      begin
        ChB_Mod1_Enabled.Checked                              :=ReadBool   (sec,'ChB_Mod1_Enabled',                                ChB_Mod1_Enabled.Checked);
        ChB_Mod1_ForceUseINISettings.Checked                  :=ReadBool   (sec,'ChB_Mod1_ForceUseINISettings',                    ChB_Mod1_ForceUseINISettings.Checked);
        ChB_Mod1_DisableCryoSickness.Checked                  :=ReadBool   (sec,'ChB_Mod1_DisableCryoSickness',                    ChB_Mod1_DisableCryoSickness.Checked);
        ChB_Mod1_PreventDeployInCaves.Checked                 :=ReadBool   (sec,'ChB_Mod1_PreventDeployInCaves',                   ChB_Mod1_PreventDeployInCaves.Checked);
        FSE_Mod1_CryoTime.Value                               :=ReadFloat  (sec,'FSE_Mod1_CryoTime',                               FSE_Mod1_CryoTime.Value);
        FSE_Mod1_CryoTimeInCombat.Value                       :=ReadFloat  (sec,'FSE_Mod1_CryoTimeInCombat',                       FSE_Mod1_CryoTimeInCombat.Value);
        SE_Mod1_CryoSicknessTimer.Value                       :=ReadInteger(sec,'SE_Mod1_CryoSicknessTimer',                       SE_Mod1_CryoSicknessTimer.Value);
        ChB_Mod1_DisableAutoCycle.Checked                     :=ReadBool   (sec,'ChB_Mod1_DisableAutoCycle',                       ChB_Mod1_DisableAutoCycle.Checked);
        SE_Mod1_CryogunRangeFoundations.Value                 :=ReadInteger(sec,'SE_Mod1_CryogunRangeFoundations',                 SE_Mod1_CryogunRangeFoundations.Value);
        SE_Mod1_CryogunCooldownSeconds.Value                  :=ReadInteger(sec,'SE_Mod1_CryogunCooldownSeconds',                  SE_Mod1_CryogunCooldownSeconds.Value);
        SE_Mod1_NeutergunRangeFoundations.Value               :=ReadInteger(sec,'SE_Mod1_NeutergunRangeFoundations',               SE_Mod1_NeutergunRangeFoundations.Value);
        SE_Mod1_NeutergunCooldownSeconds.Value                :=ReadInteger(sec,'SE_Mod1_NeutergunCooldownSeconds',                SE_Mod1_NeutergunCooldownSeconds.Value);
        ChB_Mod1_DisableCryopodsRequirement.Checked           :=ReadBool   (sec,'ChB_Mod1_DisableCryopodsRequirement',             ChB_Mod1_DisableCryopodsRequirement.Checked);
        FSE_Mod1_CryoTerminalCaptureInterval.Value            :=ReadFloat  (sec,'FSE_Mod1_CryoTerminalCaptureInterval',            FSE_Mod1_CryoTerminalCaptureInterval.Value);
        SE_Mod1_CryoTerminalMaxRadiusFoundations.Value        :=ReadInteger(sec,'SE_Mod1_CryoTerminalMaxRadiusFoundations',        SE_Mod1_CryoTerminalMaxRadiusFoundations.Value);
        ChB_Mod1_PassImprintToDeployer.Checked                :=ReadBool   (sec,'ChB_Mod1_PassImprintToDeployer',                  ChB_Mod1_PassImprintToDeployer.Checked);
        SE_Mod1_ImprintAmountToGive.Value                     :=ReadInteger(sec,'SE_Mod1_ImprintAmountToGive',                     SE_Mod1_ImprintAmountToGive.Value);
        ChB_Mod1_FullyGrownBabies.Checked                     :=ReadBool   (sec,'ChB_Mod1_FullyGrownBabies',                       ChB_Mod1_FullyGrownBabies.Checked);
        ChB_Mod1_AllowCryoterminalOnPlatforms.Checked         :=ReadBool   (sec,'ChB_Mod1_AllowCryoterminalOnPlatforms',           ChB_Mod1_AllowCryoterminalOnPlatforms.Checked);
        ChB_Mod1_AllowAdminCaptureAll.Checked                 :=ReadBool   (sec,'ChB_Mod1_AllowAdminCaptureAll',                   ChB_Mod1_AllowAdminCaptureAll.Checked);
        SE_Mod1_MaxCryoterminalsInRange.Value                 :=ReadInteger(sec,'SE_Mod1_MaxCryoterminalsInRange',                 SE_Mod1_MaxCryoterminalsInRange.Value);
        SE_Mod1_LimitCryoterminalsRange.Value                 :=ReadInteger(sec,'SE_Mod1_LimitCryoterminalsRange',                 SE_Mod1_LimitCryoterminalsRange.Value);
        ChB_Mod1_AllowDeployInBossArenas.Checked              :=ReadBool   (sec,'ChB_Mod1_AllowDeployInBossArenas',                ChB_Mod1_AllowDeployInBossArenas.Checked);
        FSE_Mod1_CryopodChargeSpeedMultiplier.Value           :=ReadFloat  (sec,'FSE_Mod1_CryopodChargeSpeedMultiplier',           FSE_Mod1_CryopodChargeSpeedMultiplier.Value);
        ChB_Mod1_DisableCryopodChargeNeed.Checked             :=ReadBool   (sec,'ChB_Mod1_DisableCryopodChargeNeed',               ChB_Mod1_DisableCryopodChargeNeed.Checked);
        ChB_Mod1_GiveTemporaryCryopodsInCryoterminal.Checked  :=ReadBool   (sec,'ChB_Mod1_GiveTemporaryCryopodsInCryoterminal',    ChB_Mod1_GiveTemporaryCryopodsInCryoterminal.Checked);
        SE_Mod1_CryofridgeInventorySlots.Value                :=ReadInteger(sec,'SE_Mod1_CryofridgeInventorySlots',                SE_Mod1_CryofridgeInventorySlots.Value);
        SE_Mod1_CryoterminalInventorySlots.Value              :=ReadInteger(sec,'SE_Mod1_CryoterminalInventorySlots',              SE_Mod1_CryoterminalInventorySlots.Value);
      end;

      sec := 'Mod2';
      begin
        ChB_Mod2_Enabled.Checked                              :=ReadBool   (sec,'ChB_Mod2_Enabled',                                ChB_Mod2_Enabled.Checked);
        ChB_Mod2_DisableNightVision.Checked                   :=ReadBool   (sec,'ChB_Mod2_DisableNightVision',                     ChB_Mod2_DisableNightVision.Checked);
        ChB_Mod2_DisablePredatorVision.Checked                :=ReadBool   (sec,'ChB_Mod2_DisablePredatorVision',                  ChB_Mod2_DisablePredatorVision.Checked);
        ChB_Mod2_DisableOutlineMode.Checked                   :=ReadBool   (sec,'ChB_Mod2_DisableOutlineMode',                     ChB_Mod2_DisableOutlineMode.Checked);
        ChB_Mod2_DisableSupplyDropInfo.Checked                :=ReadBool   (sec,'ChB_Mod2_DisableSupplyDropInfo',                  ChB_Mod2_DisableSupplyDropInfo.Checked);
        ChB_Mod2_DisableItembagInfo.Checked                   :=ReadBool   (sec,'ChB_Mod2_DisableItembagInfo',                     ChB_Mod2_DisableItembagInfo.Checked);
        ChB_Mod2_DisableStructureInfo.Checked                 :=ReadBool   (sec,'ChB_Mod2_DisableStructureInfo',                   ChB_Mod2_DisableStructureInfo.Checked);
        ChB_Mod2_DisableBuffInfo.Checked                      :=ReadBool   (sec,'ChB_Mod2_DisableBuffInfo',                        ChB_Mod2_DisableBuffInfo.Checked);
        ChB_Mod2_DisableTameFoodInfo.Checked                  :=ReadBool   (sec,'ChB_Mod2_DisableTameFoodInfo',                    ChB_Mod2_DisableTameFoodInfo.Checked);
        ChB_Mod2_DisableEggInfo.Checked                       :=ReadBool   (sec,'ChB_Mod2_DisableEggInfo',                         ChB_Mod2_DisableEggInfo.Checked);
        ChB_Mod2_DisableTheSpyglassOnEnemyTribes.Checked      :=ReadBool   (sec,'ChB_Mod2_DisableTheSpyglassOnEnemyTribes',        ChB_Mod2_DisableTheSpyglassOnEnemyTribes.Checked);
        ChB_Mod2_OnlyShowStatsForTames.Checked                :=ReadBool   (sec,'ChB_Mod2_OnlyShowStatsForTames',                  ChB_Mod2_OnlyShowStatsForTames.Checked);
        ChB_Mod2_DisableGPS.Checked                           :=ReadBool   (sec,'ChB_Mod2_DisableGPS',                             ChB_Mod2_DisableGPS.Checked);
        ChB_Mod2_DisableCrosshair.Checked                     :=ReadBool   (sec,'ChB_Mod2_DisableCrosshair',                       ChB_Mod2_DisableCrosshair.Checked);
        ChB_Mod2_OnlyHPonEnemyTribeDinos.Checked              :=ReadBool   (sec,'ChB_Mod2_OnlyHPonEnemyTribeDinos',                ChB_Mod2_OnlyHPonEnemyTribeDinos.Checked);
        SE_Mod2_OutlineRange.Value                            :=ReadInteger(sec,'SE_Mod2_OutlineRange',                            SE_Mod2_OutlineRange.Value);
        ChB_Mod2_UseESPOutline.Checked                        :=ReadBool   (sec,'ChB_Mod2_UseESPOutline',                          ChB_Mod2_UseESPOutline.Checked);
        ChB_Mod2_UseESPOutlineFill.Checked                    :=ReadBool   (sec,'ChB_Mod2_UseESPOutlineFill',                      ChB_Mod2_UseESPOutlineFill.Checked);
        ChB_Mod2_DontShowAnyStatsOnWildDino.Checked           :=ReadBool   (sec,'ChB_Mod2_DontShowAnyStatsOnWildDino',             ChB_Mod2_DontShowAnyStatsOnWildDino.Checked);
      end;

      sec := 'Mod3';
      begin
        ChB_Mod3_Enabled.Checked                              :=ReadBool   (sec,'ChB_Mod3_Enabled',                                ChB_Mod3_Enabled.Checked);
        ChB_Mod3_IsAdminOnly.Checked                          :=ReadBool   (sec,'ChB_Mod3_IsAdminOnly',                            ChB_Mod3_IsAdminOnly.Checked);
        SE_Mod3_MarkerLimit.Value                             :=ReadInteger(sec,'SE_Mod3_MarkerLimit',                             SE_Mod3_MarkerLimit.Value);
      end;

      sec := 'Mod4';
      begin
        ChB_Mod4_AA_Ceratosaurus.Checked                      :=ReadBool   (sec,'ChB_Mod4_AA_Ceratosaurus',                        ChB_Mod4_AA_Ceratosaurus.Checked);
        ChB_Mod4_AA_Archelon.Checked                          :=ReadBool   (sec,'ChB_Mod4_AA_Archelon',                            ChB_Mod4_AA_Archelon.Checked);
        ChB_Mod4_AA_Deinotherium.Checked                      :=ReadBool   (sec,'ChB_Mod4_AA_Deinotherium',                        ChB_Mod4_AA_Deinotherium.Checked);
        ChB_Mod4_AA_Brachiosaurus.Checked                     :=ReadBool   (sec,'ChB_Mod4_AA_Brachiosaurus',                       ChB_Mod4_AA_Brachiosaurus.Checked);
        ChB_Mod4_AA_Deinosuchus.Checked                       :=ReadBool   (sec,'ChB_Mod4_AA_Deinosuchus',                         ChB_Mod4_AA_Deinosuchus.Checked);
        ChB_Mod4_AA_Helicoprion.Checked                       :=ReadBool   (sec,'ChB_Mod4_AA_Helicoprion',                         ChB_Mod4_AA_Helicoprion.Checked);
        ChB_Mod4_AA_Xiphactinus.Checked                       :=ReadBool   (sec,'ChB_Mod4_AA_Xiphactinus',                         ChB_Mod4_AA_Xiphactinus.Checked);
        ChB_Mod4_AA_Anomalocaris.Checked                      :=ReadBool   (sec,'ChB_Mod4_AA_Anomalocaris',                        ChB_Mod4_AA_Anomalocaris.Checked);
        ChB_Mod4_AA_Acrocanthosaurus.Checked                  :=ReadBool   (sec,'ChB_Mod4_AA_Acrocanthosaurus',                    ChB_Mod4_AA_Acrocanthosaurus.Checked);
      end;

      sec := 'Mod5';
      begin
        ChB_Mod5_Enabled.Checked                              :=ReadBool   (sec,'ChB_Mod5_Enabled',                                ChB_Mod5_Enabled.Checked);
        CB_Mod5_RemoveFloorRequirementFromStructurePlacement.Checked
                                                              :=ReadBool   (sec,'CB_Mod5_RemoveFloorRequirementFromStructurePlacement',
                                                                                                                                   CB_Mod5_RemoveFloorRequirementFromStructurePlacement.Checked);
        CB_Mod5_DisableResourcePulling.Checked                :=ReadBool   (sec,'CB_Mod5_DisableResourcePulling',                  CB_Mod5_DisableResourcePulling.Checked);
        FSE_Mod5_ResourceTransferCooldown.Value               :=ReadFloat  (sec,'FSE_Mod5_ResourceTransferCooldown',               FSE_Mod5_ResourceTransferCooldown.Value);
        ChB_Mod5_PullingIgnoresPinCodes.Checked               :=ReadBool   (sec,'ChB_Mod5_PullingIgnoresPinCodes',                 ChB_Mod5_PullingIgnoresPinCodes.Checked);
        ChB_Mod5_EnableExtendedDeathCache.Checked             :=ReadBool   (sec,'ChB_Mod5_EnableExtendedDeathCache',               ChB_Mod5_EnableExtendedDeathCache.Checked);
        ChB_Mod5_EnableUpdateDurability.Checked               :=ReadBool   (sec,'ChB_Mod5_EnableUpdateDurability',                 ChB_Mod5_EnableUpdateDurability.Checked);
        ChB_Mod5_AllowTekItemBlueprintCreation.Checked        :=ReadBool   (sec,'ChB_Mod5_AllowTekItemBlueprintCreation',          ChB_Mod5_AllowTekItemBlueprintCreation.Checked);
        ChB_Mod5_AllowMakingWeaponsAndArmorBPs.Checked        :=ReadBool   (sec,'ChB_Mod5_AllowMakingWeaponsAndArmorBPs',          ChB_Mod5_AllowMakingWeaponsAndArmorBPs.Checked);
        ChB_Mod5_DisableMultiToolDinoKillMode.Checked         :=ReadBool   (sec,'ChB_Mod5_DisableMultiToolDinoKillMode',           ChB_Mod5_DisableMultiToolDinoKillMode.Checked);
        ChB_Mod5_DisableMultiToolDinoChibiMode.Checked        :=ReadBool   (sec,'ChB_Mod5_DisableMultiToolDinoChibiMode',          ChB_Mod5_DisableMultiToolDinoChibiMode.Checked);
        ChB_Mod5_AllowMultiToolNeuterAll.Checked              :=ReadBool   (sec,'ChB_Mod5_AllowMultiToolNeuterAll',                ChB_Mod5_AllowMultiToolNeuterAll.Checked);
        ChB_Mod5_AllowGrindingMissionRewards.Checked          :=ReadBool   (sec,'ChB_Mod5_AllowGrindingMissionRewards',            ChB_Mod5_AllowGrindingMissionRewards.Checked);
        ChB_Mod5_EnableStructureSound.Checked                 :=ReadBool   (sec,'ChB_Mod5_EnableStructureSound',                   ChB_Mod5_EnableStructureSound.Checked);
        ChB_Mod5_DisableBlueprintInstall.Checked              :=ReadBool   (sec,'ChB_Mod5_DisableBlueprintInstall',                ChB_Mod5_DisableBlueprintInstall.Checked);
        SE_Mod5_PropagatorFuelInterval.Value                  :=ReadInteger(sec,'SE_Mod5_PropagatorFuelInterval',                  SE_Mod5_PropagatorFuelInterval.Value);
        SE_Mod5_PropagatorModCostMutate.Value                 :=ReadInteger(sec,'SE_Mod5_PropagatorModCostMutate',                 SE_Mod5_PropagatorModCostMutate.Value);
        ChB_Mod5_PropagatorDisableDinoMods.Checked            :=ReadBool   (sec,'ChB_Mod5_PropagatorDisableDinoMods',              ChB_Mod5_PropagatorDisableDinoMods.Checked);
        ChB_Mod5_PropagatorRespectMutationLimit.Checked       :=ReadBool   (sec,'ChB_Mod5_PropagatorRespectMutationLimit',         ChB_Mod5_PropagatorRespectMutationLimit.Checked);
        ChB_Mod5_PropagatorDisableEggDrop.Checked             :=ReadBool   (sec,'ChB_Mod5_PropagatorDisableEggDrop',               ChB_Mod5_PropagatorDisableEggDrop.Checked);
        SE_Mod5_TribePropagatorLimit.Value                    :=ReadInteger(sec,'SE_Mod5_TribePropagatorLimit',                    SE_Mod5_TribePropagatorLimit.Value);
        SE_Mod5_NannyMaxImprint.Value                         :=ReadInteger(sec,'SE_Mod5_NannyMaxImprint',                         SE_Mod5_NannyMaxImprint.Value);
        SE_Mod5_NannyIntervalInSeconds.Value                  :=ReadInteger(sec,'SE_Mod5_NannyIntervalInSeconds',                  SE_Mod5_NannyIntervalInSeconds.Value);
        SE_Mod5_NannyFeedingStartThreshold.Value              :=ReadInteger(sec,'SE_Mod5_NannyFeedingStartThreshold',              SE_Mod5_NannyFeedingStartThreshold.Value);
        SE_Mod5_BeeHiveHoneyIntervalInSeconds.Value           :=ReadInteger(sec,'SE_Mod5_BeeHiveHoneyIntervalInSeconds',           SE_Mod5_BeeHiveHoneyIntervalInSeconds.Value);
        SE_Mod5_MutatorBuffMaxStackCount.Value                :=ReadInteger(sec,'SE_Mod5_MutatorBuffMaxStackCount',                SE_Mod5_MutatorBuffMaxStackCount.Value);
        ChB_Mod5_MutatorAllowBreedingNeutered.Checked         :=ReadBool   (sec,'ChB_Mod5_MutatorAllowBreedingNeutered',           ChB_Mod5_MutatorAllowBreedingNeutered.Checked);
        ChB_Mod5_DisableHitchingPostMatingBonus.Checked       :=ReadBool   (sec,'ChB_Mod5_DisableHitchingPostMatingBonus',         ChB_Mod5_DisableHitchingPostMatingBonus.Checked);
        SE_Mod5_HitchingPostRange.Value                       :=ReadInteger(sec,'SE_Mod5_HitchingPostRange',                       SE_Mod5_HitchingPostRange.Value);
        SE_Mod5_HitchingPostDinoLimit.Value                   :=ReadInteger(sec,'SE_Mod5_HitchingPostDinoLimit',                   SE_Mod5_HitchingPostDinoLimit.Value);
        SE_Mod5_HitchingPostTribeLimit.Value                  :=ReadInteger(sec,'SE_Mod5_HitchingPostTribeLimit',                  SE_Mod5_HitchingPostTribeLimit.Value);
        SE_Mod5_GrinderResourceReturnPercent.Value            :=ReadInteger(sec,'SE_Mod5_GrinderResourceReturnPercent',            SE_Mod5_GrinderResourceReturnPercent.Value);
        SE_Mod5_GrinderResourceReturnMax.Value                :=ReadInteger(sec,'SE_Mod5_GrinderResourceReturnMax',                SE_Mod5_GrinderResourceReturnMax.Value);
        ChB_Mod5_GrinderReturnBlockedResources.Checked        :=ReadBool   (sec,'ChB_Mod5_GrinderReturnBlockedResources',          ChB_Mod5_GrinderReturnBlockedResources.Checked);
        SE_Mod5_SmallStorageSlotCount.Value                   :=ReadInteger(sec,'SE_Mod5_SmallStorageSlotCount',                   SE_Mod5_SmallStorageSlotCount.Value);
        SE_Mod5_LargeStorageSlotCount.Value                   :=ReadInteger(sec,'SE_Mod5_LargeStorageSlotCount',                   SE_Mod5_LargeStorageSlotCount.Value);
        SE_Mod5_MetalStorageSlotCount.Value                   :=ReadInteger(sec,'SE_Mod5_MetalStorageSlotCount',                   SE_Mod5_MetalStorageSlotCount.Value);
        SE_Mod5_PropagatorSlotCount.Value                     :=ReadInteger(sec,'SE_Mod5_PropagatorSlotCount',                     SE_Mod5_PropagatorSlotCount.Value);
        SE_Mod5_NannySlotCount.Value                          :=ReadInteger(sec,'SE_Mod5_NannySlotCount',                          SE_Mod5_NannySlotCount.Value);
        SE_Mod5_TransmutatorSlotCount.Value                   :=ReadInteger(sec,'SE_Mod5_TransmutatorSlotCount',                   SE_Mod5_TransmutatorSlotCount.Value);
        SE_Mod5_GardenerSlotCount.Value                       :=ReadInteger(sec,'SE_Mod5_GardenerSlotCount',                       SE_Mod5_GardenerSlotCount.Value);
        SE_Mod5_FarmerSlotCount.Value                         :=ReadInteger(sec,'SE_Mod5_FarmerSlotCount',                         SE_Mod5_FarmerSlotCount.Value);
        SE_Mod5_BeeHiveSlotCount.Value                        :=ReadInteger(sec,'SE_Mod5_BeeHiveSlotCount',                        SE_Mod5_BeeHiveSlotCount.Value);
        SE_Mod5_AmmoBoxSlotCount.Value                        :=ReadInteger(sec,'SE_Mod5_AmmoBoxSlotCount',                        SE_Mod5_AmmoBoxSlotCount.Value);
        SE_Mod5_GrinderSlotCount.Value                        :=ReadInteger(sec,'SE_Mod5_GrinderSlotCount',                        SE_Mod5_GrinderSlotCount.Value);
        SE_Mod5_IndustrialForgeSlotCount.Value                :=ReadInteger(sec,'SE_Mod5_IndustrialForgeSlotCount',                SE_Mod5_IndustrialForgeSlotCount.Value);
        SE_Mod5_GeneratorSlotCount.Value                      :=ReadInteger(sec,'SE_Mod5_GeneratorSlotCount',                      SE_Mod5_GeneratorSlotCount.Value);
        SE_Mod5_ReplicatorSlotCount.Value                     :=ReadInteger(sec,'SE_Mod5_ReplicatorSlotCount',                     SE_Mod5_ReplicatorSlotCount.Value);
        SE_Mod5_FridgeSlotCount.Value                         :=ReadInteger(sec,'SE_Mod5_FridgeSlotCount',                         SE_Mod5_FridgeSlotCount.Value);
        SE_Mod5_PreservingBinSlotCount.Value                  :=ReadInteger(sec,'SE_Mod5_PreservingBinSlotCount',                  SE_Mod5_PreservingBinSlotCount.Value);
        SE_Mod5_FabricatorSlotCount.Value                     :=ReadInteger(sec,'SE_Mod5_FabricatorSlotCount',                     SE_Mod5_FabricatorSlotCount.Value);
        SE_Mod5_TekGeneratorSlotCount.Value                   :=ReadInteger(sec,'SE_Mod5_TekGeneratorSlotCount',                   SE_Mod5_TekGeneratorSlotCount.Value);
        FSE_Mod5_RaidTimerLimitMultiplier.Value               :=ReadFloat  (sec,'FSE_Mod5_RaidTimerLimitMultiplier',               FSE_Mod5_RaidTimerLimitMultiplier.Value);
        FSE_Mod5_PropagatorMatingSpeedMultiplier.Value        :=ReadFloat  (sec,'FSE_Mod5_PropagatorMatingSpeedMultiplier',        FSE_Mod5_PropagatorMatingSpeedMultiplier.Value);
        FSE_Mod5_PropagatorMatingIntervalMultiplier.Value     :=ReadFloat  (sec,'FSE_Mod5_PropagatorMatingIntervalMultiplier',     FSE_Mod5_PropagatorMatingIntervalMultiplier.Value);
        FSE_Mod5_GrinderScaleMultiplier.Value                 :=ReadFloat  (sec,'FSE_Mod5_GrinderScaleMultiplier',                 FSE_Mod5_GrinderScaleMultiplier.Value);
        FSE_Mod5_IndustrialForgeScaleMultiplier.Value         :=ReadFloat  (sec,'FSE_Mod5_IndustrialForgeScaleMultiplier',         FSE_Mod5_IndustrialForgeScaleMultiplier.Value);
        FSE_Mod5_ReplicatorScaleMultiplier.Value              :=ReadFloat  (sec,'FSE_Mod5_ReplicatorScaleMultiplier',              FSE_Mod5_ReplicatorScaleMultiplier.Value);
        SE_Mod5_GrinderCraftingSpeed.Value                    :=ReadInteger(sec,'SE_Mod5_GrinderCraftingSpeed',                    SE_Mod5_GrinderCraftingSpeed.Value);
        SE_Mod5_IndustrialForgeCraftingSpeed.Value            :=ReadInteger(sec,'SE_Mod5_IndustrialForgeCraftingSpeed',            SE_Mod5_IndustrialForgeCraftingSpeed.Value);
        SE_Mod5_ReplicatorCraftingSpeed.Value                 :=ReadInteger(sec,'SE_Mod5_ReplicatorCraftingSpeed',                 SE_Mod5_ReplicatorCraftingSpeed.Value);
        SE_Mod5_FridgeCraftingSpeed.Value                     :=ReadInteger(sec,'SE_Mod5_FridgeCraftingSpeed',                     SE_Mod5_FridgeCraftingSpeed.Value);
        SE_Mod5_PreservingBinCraftingSpeed.Value              :=ReadInteger(sec,'SE_Mod5_PreservingBinCraftingSpeed',              SE_Mod5_PreservingBinCraftingSpeed.Value);
        SE_Mod5_FabricatorCraftingSpeed.Value                 :=ReadInteger(sec,'SE_Mod5_FabricatorCraftingSpeed',                 SE_Mod5_FabricatorCraftingSpeed.Value);
        SE_Mod5_ResourcePullRangeInFoundations.Value          :=ReadInteger(sec,'SE_Mod5_ResourcePullRangeInFoundations',          SE_Mod5_ResourcePullRangeInFoundations.Value);
        SE_Mod5_BeeHiveWateringRangeInFoundations.Value       :=ReadInteger(sec,'SE_Mod5_BeeHiveWateringRangeInFoundations',       SE_Mod5_BeeHiveWateringRangeInFoundations.Value);
        SE_Mod5_MaxMutatorRangeInFoundations.Value            :=ReadInteger(sec,'SE_Mod5_MaxMutatorRangeInFoundations',            SE_Mod5_MaxMutatorRangeInFoundations.Value);
        SE_Mod5_MaxPowerRangeInFoundations.Value              :=ReadInteger(sec,'SE_Mod5_MaxPowerRangeInFoundations',              SE_Mod5_MaxPowerRangeInFoundations.Value);
        SE_Mod5_GardenerRangeInFoundations.Value              :=ReadInteger(sec,'SE_Mod5_GardenerRangeInFoundations',              SE_Mod5_GardenerRangeInFoundations.Value);
        SE_Mod5_FarmerRangeInFoundations.Value                :=ReadInteger(sec,'SE_Mod5_FarmerRangeInFoundations',                SE_Mod5_FarmerRangeInFoundations.Value);
        SE_Mod5_NannyRangeInFoundations.Value                 :=ReadInteger(sec,'SE_Mod5_NannyRangeInFoundations',                 SE_Mod5_NannyRangeInFoundations.Value);
        CG_Mod5_MutatorModeBlacklist.Checked[0]               :=ReadBool   (sec,'CG_Mod5_MutatorModeBlacklist0',                   CG_Mod5_MutatorModeBlacklist.Checked[0]);
        CG_Mod5_MutatorModeBlacklist.Checked[1]               :=ReadBool   (sec,'CG_Mod5_MutatorModeBlacklist1',                   CG_Mod5_MutatorModeBlacklist.Checked[1]);
        CG_Mod5_MutatorModeBlacklist.Checked[2]               :=ReadBool   (sec,'CG_Mod5_MutatorModeBlacklist2',                   CG_Mod5_MutatorModeBlacklist.Checked[2]);
        CG_Mod5_MutatorModeBlacklist.Checked[3]               :=ReadBool   (sec,'CG_Mod5_MutatorModeBlacklist3',                   CG_Mod5_MutatorModeBlacklist.Checked[3]);
        CG_Mod5_MutatorModeBlacklist.Checked[4]               :=ReadBool   (sec,'CG_Mod5_MutatorModeBlacklist4',                   CG_Mod5_MutatorModeBlacklist.Checked[4]);
        CG_Mod5_MutatorModeBlacklist.Checked[5]               :=ReadBool   (sec,'CG_Mod5_MutatorModeBlacklist5',                   CG_Mod5_MutatorModeBlacklist.Checked[5]);
        CG_Mod5_MutatorModeBlacklist.Checked[6]               :=ReadBool   (sec,'CG_Mod5_MutatorModeBlacklist6',                   CG_Mod5_MutatorModeBlacklist.Checked[6]);
        Edit_Mod5_MutatorPulseCost.Text                       :=ReadString (sec,'Edit_Mod5_MutatorPulseCost',                      Edit_Mod5_MutatorPulseCost.Text);
        Edit_Mod5_MutatorPulseCooldowns.Text                  :=ReadString (sec,'Edit_Mod5_MutatorPulseCooldowns',                 Edit_Mod5_MutatorPulseCooldowns.Text);
        Edit_Mod5_MutatorDinoBlacklist.Text                   :=ReadString (sec,'Edit_Mod5_MutatorDinoBlacklist',                  Edit_Mod5_MutatorDinoBlacklist.Text);
        Edit_Mod5_PullResourceAdditions.Text                  :=ReadString (sec,'Edit_Mod5_PullResourceAdditions',                 Edit_Mod5_PullResourceAdditions.Text);
        Edit_Mod5_PullResourceRemovals.Text                   :=ReadString (sec,'Edit_Mod5_PullResourceRemovals',                  Edit_Mod5_PullResourceRemovals.Text);
        Edit_Mod5_AdvTransferItemBlacklist.Text               :=ReadString (sec,'Edit_Mod5_AdvTransferItemBlacklist',              Edit_Mod5_AdvTransferItemBlacklist.Text);
        Edit_Mod5_QoLPlusEngramWhitelist.Text                 :=ReadString (sec,'Edit_Mod5_QoLPlusEngramWhitelist',                Edit_Mod5_QoLPlusEngramWhitelist.Text);
        Edit_Mod5_OmniToolBlacklist.Text                      :=ReadString (sec,'Edit_Mod5_OmniToolBlacklist',                     Edit_Mod5_OmniToolBlacklist.Text);
        Edit_Mod5_MultiToolBlacklist.Text                     :=ReadString (sec,'Edit_Mod5_MultiToolBlacklist',                    Edit_Mod5_MultiToolBlacklist.Text);
        Edit_Mod5_PropagatorDinoBlacklist.Text                :=ReadString (sec,'Edit_Mod5_PropagatorDinoBlacklist',               Edit_Mod5_PropagatorDinoBlacklist.Text);
        Edit_Mod5_PropagatorFuelClass.Text                    :=ReadString (sec,'Edit_Mod5_PropagatorFuelClass',                   Edit_Mod5_PropagatorFuelClass.Text);
        Edit_Mod5_PropagatorModCostItemClass.Text             :=ReadString (sec,'Edit_Mod5_PropagatorModCostItemClass',            Edit_Mod5_PropagatorModCostItemClass.Text);
      end;

      sec := 'iniFiles';
      begin
        ChB_GUS_Override.Checked                              :=ReadBool   (sec,'ChB_GUS_Override',                                ChB_GUS_Override.Checked);
        cnt                                                   :=ReadInteger(sec,'Memo_GameUserSettings_Override_LineCount',        0);
        for i:=0 to cnt -1 do
        begin
          Memo_GameUserSettings_Override.Lines.Add(             ReadString (sec,'Memo_GameUserSettings_Override'+InttoStr(i),      ''));
        end;

        ChB_GUS_Append.Checked                                :=ReadBool   (sec,'ChB_GUS_Append',                                  ChB_GUS_Append.Checked);
        cnt                                                   :=ReadInteger(sec,'Memo_GameUserSettings_Append_LineCount',          0);
        for i:=0 to cnt -1 do
        begin
          Memo_GameUserSettings_Append.Lines.Add(               ReadString (sec,'Memo_GameUserSettings_Append'+InttoStr(i),        ''));
        end;

        ChB_GS_Override.Checked                               :=ReadBool   (sec,'ChB_GS_Override',                                 ChB_GS_Override.Checked);
        cnt                                                   :=ReadInteger(sec,'Memo_GameIni_Override_LineCount',                 0);
        for i:=0 to cnt -1 do
        begin
          Memo_GameIni_Override.Lines.Add(                      ReadString (sec,'Memo_GameIni_Override'+InttoStr(i),               ''));
        end;

        ChB_GS_Append.Checked                                 :=ReadBool   (sec,'ChB_GS_Append',                                   ChB_GS_Append.Checked);
        cnt                                                   :=ReadInteger(sec,'Memo_GameIni_Append_LineCount',                   0);
        for i:=0 to cnt -1 do
        begin
          Memo_GameIni_Append.Lines.Add(                        ReadString (sec,'Memo_GameIni_Append'+InttoStr(i),               ''));
        end;
      end;

      sec := 'Experimental';
      begin
        ChB_ER_Tame.Checked                                   :=ReadBool   (sec,'ChB_ER_Tame',                                     ChB_ER_Tame.Checked);
        ChB_ER_Harvesting.Checked                             :=ReadBool   (sec,'ChB_ER_Harvesting',                               ChB_ER_Harvesting.Checked);
        ChB_ER_Experience.Checked                             :=ReadBool   (sec,'ChB_ER_Experience',                               ChB_ER_Experience.Checked);
        ChB_ER_Breeding.Checked                               :=ReadBool   (sec,'ChB_ER_Breeding',                                 ChB_ER_Breeding.Checked);
        ChB_ER_Hexagons.Checked                               :=ReadBool   (sec,'ChB_ER_Hexagons',                                 ChB_ER_Hexagons.Checked);
        FSE_ER_Tame.Value                                     :=ReadFloat  (sec,'FSE_ER_Tame',                                     FSE_ER_Tame.Value);
        FSE_ER_Harvesting.Value                               :=ReadFloat  (sec,'FSE_ER_Harvesting',                               FSE_ER_Harvesting.Value);
        FSE_ER_Experience.Value                               :=ReadFloat  (sec,'FSE_ER_Experience',                               FSE_ER_Experience.Value);
        FSE_ER_Breeding.Value                                 :=ReadFloat  (sec,'FSE_ER_Breeding',                                 FSE_ER_Breeding.Value);
        FSE_ER_Breeding2.Value                                :=ReadFloat  (sec,'FSE_ER_Breeding2',                                FSE_ER_Breeding2.Value);
        FSE_ER_Breeding3.Value                                :=ReadFloat  (sec,'FSE_ER_Breeding3',                                FSE_ER_Breeding3.Value);
        FSE_ER_Hexagons.Value                                 :=ReadFloat  (sec,'FSE_ER_Hexagons',                                 FSE_ER_Hexagons.Value);
        Edit_Export.Text                                      :=ReadString (sec,'Edit_Export',                                     ExtractFileDir(ParamStr0)+'\Profile\Backup');
        if (Edit_Export.Text = '') then Edit_Export.Text := ExtractFileDir(ParamStr0)+'\Profile\Backup';
        ChB_CleanBackup.Checked                               :=ReadBool   (sec,'ChB_CleanBackup',                                 ChB_CleanBackup.Checked);

        ChB_UseEngineINI.Checked                              :=ReadBool   (sec,'ChB_UseEngineINI',                                ChB_UseEngineINI.Checked);
        FSE_InitialConnectTimeout.Value                       :=ReadFloat  (sec,'FSE_InitialConnectTimeout',                       FSE_InitialConnectTimeout.Value);
        FSE_ConnectionTimeout.Value                           :=ReadFloat  (sec,'FSE_ConnectionTimeout',                           FSE_ConnectionTimeout.Value);
        SE_P2PConnectionTimeout.Value                         :=ReadInteger(sec,'SE_P2PConnectionTimeout',                         SE_P2PConnectionTimeout.Value);

        SE_HttpTimeout.Value                                  :=ReadInteger(sec,'SE_HttpTimeout',                                  SE_HttpTimeout.Value);
        SE_HttpConnectionTimeout.Value                        :=ReadInteger(sec,'SE_HttpConnectionTimeout',                        SE_HttpConnectionTimeout.Value);
        SE_HttpReceiveTimeout.Value                           :=ReadInteger(sec,'SE_HttpReceiveTimeout',                           SE_HttpReceiveTimeout.Value);
        SE_HttpSendTimeout.Value                              :=ReadInteger(sec,'SE_HttpSendTimeout',                              SE_HttpSendTimeout.Value);
      end;
    end;
  finally
    dataset.Free;
    sl.Free;
    Mods_Change(nil);
    SetProfileLog('Profile Loaded.');
  end;
end;

procedure TAsaFrame.loadProfileFromIni(profieName:string;shooterGamePath:string);
var
  GUSIniPath,
  GSIniPath  :string;
  sl         :TStringList;
  i          :integer;
  s          :string;
  sec        :string;
  ASEMode    :boolean;
const
  cSec_SvrS = '[ServerSettings]';
  cSec_SesS = '[SessionSettings]';
  cSec_MOTD = '[MessageOfTheDay]';
  cSec_Mod1 = '[Cryopods]';
  cSec_Mod2 = '[SuperSpyglassPlus]';
  cSec_Mod3 = '[DerDinoFinder]';
  cSec_Mod5 = '[QoLPlus]';
  cSec_ShGM = '[/Script/ShooterGame.ShooterGameMode]';
begin
  GUSIniPath  := shooterGamePath + '\GameUserSettings.ini';
  GSIniPath   := shooterGamePath + '\Game.ini';
  beforeProfileName             :=profieName;

  Memo_GameUserSettings_Append.Lines.Clear;
  Memo_GameUserSettings_Override.Lines.Clear;
  Memo_GameIni_Append.Lines.Clear;
  Memo_GameIni_Override.Lines.Clear;

  sl := TStringList.Create;
  try
    s := '';
    sl.Clear;
    if (FileExists(GUSIniPath)) then sl.LoadFromFile(GUSIniPath);
    ASEMode := false;
    if (sl.IndexOfName('MaxPlayers') <> -1) then ASEMode := True;
    for i := 0 to sl.Count -1 do
    begin
      try
        s := sl.Strings[i];

        //ServerSettings
        if          ((sec=cSec_SvrS)and(pos('ActiveMods'             ,s)=1)and (not ASEMode)) then begin Edit_Mods                                      .Text :=            stringReplace(s,'ActiveMods='                              ,'',[rfReplaceAll, rfIgnoreCase]);
        end else if ((sec=cSec_SvrS)and(pos('ActiveMapMod'           ,s)=1)and (not ASEMode)) then begin Edit_ActiveMapMod_Val                          .Text :=            stringReplace(s,'ActiveMapMod='                            ,'',[rfReplaceAll, rfIgnoreCase]);
        end else if ((sec=cSec_SvrS)and(pos('AdminLogging'                            ,s)=1)) then begin ChB_AdminLogging                            .Checked := StrToBool (stringReplace(s,'AdminLogging='                            ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('AllowAnyoneBabyImprintCuddle'            ,s)=1)) then begin ChB_AllowAnyoneBabyImprintCuddle            .Checked := StrToBool (stringReplace(s,'AllowAnyoneBabyImprintCuddle='            ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('AllowCaveBuildingPvE'                    ,s)=1)) then begin ChB_AllowCaveBuildingPvE                    .Checked := StrToBool (stringReplace(s,'AllowCaveBuildingPvE='                    ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('AllowCaveBuildingPvP'                    ,s)=1)) then begin ChB_AllowCaveBuildingPvP                    .Checked := StrToBool (stringReplace(s,'AllowCaveBuildingPvP='                    ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('AllowFlyerCarryPvE'                      ,s)=1)) then begin ChB_AllowFlyerCarryPvE                      .Checked := StrToBool (stringReplace(s,'AllowFlyerCarryPvE='                      ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('AllowHideDamageSourceFromLogs'           ,s)=1)) then begin ChB_AllowHideDamageSourceFromLogs           .Checked := StrToBool (stringReplace(s,'AllowHideDamageSourceFromLogs='           ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('AllowHitMarkers'                         ,s)=1)) then begin ChB_AllowHitMarkers                         .Checked := StrToBool (stringReplace(s,'AllowHitMarkers='                         ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('AllowMultipleAttachedC4'                 ,s)=1)) then begin ChB_AllowMultipleAttachedC4                 .Checked := StrToBool (stringReplace(s,'AllowMultipleAttachedC4='                 ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('AllowRaidDinoFeeding'                    ,s)=1)) then begin ChB_AllowRaidDinoFeeding                    .Checked := StrToBool (stringReplace(s,'AllowRaidDinoFeeding='                    ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('AllowThirdPersonPlayer'                  ,s)=1)) then begin ChB_AllowThirdPersonPlayer                  .Checked := StrToBool (stringReplace(s,'AllowThirdPersonPlayer='                  ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('AlwaysAllowStructurePickup'              ,s)=1)) then begin ChB_AlwaysAllowStructurePickup              .Checked := StrToBool (stringReplace(s,'AlwaysAllowStructurePickup='              ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('AutoSavePeriodMinutes'                   ,s)=1)) then begin FSE_AutoSavePeriodMinutes                     .Value := StrToFloat(stringReplace(s,'AutoSavePeriodMinutes='                   ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('ClampItemSpoilingTimes'                  ,s)=1)) then begin ChB_ClampItemSpoilingTimes                  .Checked := StrToBool (stringReplace(s,'ClampItemSpoilingTimes='                  ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('ClampResourceHarvestDamage'              ,s)=1)) then begin ChB_ClampResourceHarvestDamage              .Checked := StrToBool (stringReplace(s,'ClampResourceHarvestDamage='              ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('ClampItemStats'                          ,s)=1)) then begin ChB_ClampItemStats                          .Checked := StrToBool (stringReplace(s,'ClampItemStats='                          ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('DayCycleSpeedScale'                      ,s)=1)) then begin FSE_DayCycleSpeedScale                        .Value := StrToFloat(stringReplace(s,'DayCycleSpeedScale='                      ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('DayTimeSpeedScale'                       ,s)=1)) then begin FSE_DayTimeSpeedScale                         .Value := StrToFloat(stringReplace(s,'DayTimeSpeedScale='                       ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('NightTimeSpeedScale'                     ,s)=1)) then begin FSE_NightTimeSpeedScale                       .Value := StrToFloat(stringReplace(s,'NightTimeSpeedScale='                     ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('DifficultyOffset'                        ,s)=1)) then begin FSE_DifficultyOffset                          .Value := StrToFloat(stringReplace(s,'DifficultyOffset='                        ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('DinoCharacterFoodDrainMultiplier'        ,s)=1)) then begin FSE_DinoCharacterFoodDrainMultiplier          .Value := StrToFloat(stringReplace(s,'DinoCharacterFoodDrainMultiplier='        ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('DinoCharacterHealthRecoveryMultiplier'   ,s)=1)) then begin FSE_DinoCharacterHealthRecoveryMultiplier     .Value := StrToFloat(stringReplace(s,'DinoCharacterHealthRecoveryMultiplier='   ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('DinoCharacterStaminaDrainMultiplier'     ,s)=1)) then begin FSE_DinoCharacterStaminaDrainMultiplier       .Value := StrToFloat(stringReplace(s,'DinoCharacterStaminaDrainMultiplier='     ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('DinoDamageMultiplier'                    ,s)=1)) then begin FSE_DinoDamageMultiplier                      .Value := StrToFloat(stringReplace(s,'DinoDamageMultiplier='                    ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('DinoResistanceMultiplier'                ,s)=1)) then begin FSE_DinoResistanceMultiplier                  .Value := StrToFloat(stringReplace(s,'DinoResistanceMultiplier='                ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('DisableDinoDecayPvE'                     ,s)=1)) then begin ChB_DisableDinoDecayPvE                     .Checked := StrToBool (stringReplace(s,'DisableDinoDecayPvE='                     ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('DisableImprintDinoBuff'                  ,s)=1)) then begin ChB_DisableImprintDinoBuff                  .Checked := StrToBool (stringReplace(s,'DisableImprintDinoBuff='                  ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('DisablePvEGamma'                         ,s)=1)) then begin ChB_DisablePvEGamma                         .Checked := StrToBool (stringReplace(s,'DisablePvEGamma='                         ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('DisableStructureDecayPvE'                ,s)=1)) then begin ChB_DisableStructureDecayPvE                .Checked := StrToBool (stringReplace(s,'DisableStructureDecayPvE='                ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('DisableWeatherFog'                       ,s)=1)) then begin ChB_DisableWeatherFog                       .Checked := StrToBool (stringReplace(s,'DisableWeatherFog='                       ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('DontAlwaysNotifyPlayerJoined'            ,s)=1)) then begin ChB_DontAlwaysNotifyPlayerJoined            .Checked := StrToBool (stringReplace(s,'DontAlwaysNotifyPlayerJoined='            ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('EnableExtraStructurePreventionVolumes'   ,s)=1)) then begin ChB_EnableExtraStructurePreventionVolumes   .Checked := StrToBool (stringReplace(s,'EnableExtraStructurePreventionVolumes='   ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('AutoDestroyDecayedDinos'                 ,s)=1)) then begin ChB_AutoDestroyDecayedDinos                 .Checked := StrToBool (stringReplace(s,'AutoDestroyDecayedDinos='                 ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('bForceCanRideFliers'                     ,s)=1)) then begin ChB_bForceCanRideFliers                     .Checked := StrToBool (stringReplace(s,'bForceCanRideFliers='                     ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('EnablePvPGamma'                          ,s)=1)) then begin ChB_EnablePvPGamma                          .Checked := StrToBool (stringReplace(s,'EnablePvPGamma='                          ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('globalVoiceChat'                         ,s)=1)) then begin ChB_globalVoiceChat                         .Checked := StrToBool (stringReplace(s,'globalVoiceChat='                         ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('HarvestAmountMultiplier'                 ,s)=1)) then begin FSE_HarvestAmountMultiplier                   .Value := StrToFloat(stringReplace(s,'HarvestAmountMultiplier='                 ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('HarvestHealthMultiplier'                 ,s)=1)) then begin FSE_HarvestHealthMultiplier                   .Value := StrToFloat(stringReplace(s,'HarvestHealthMultiplier='                 ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('ItemStackSizeMultiplier'                 ,s)=1)) then begin FSE_ItemStackSizeMultiplier                   .Value := StrToFloat(stringReplace(s,'ItemStackSizeMultiplier='                 ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('KickIdlePlayersPeriod'                   ,s)=1)) then begin FSE_KickIdlePlayersPeriod                     .Value := StrToFloat(stringReplace(s,'KickIdlePlayersPeriod='                   ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('MaxPersonalTamedDinos'                   ,s)=1)) then begin SE_MaxPersonalTamedDinos                      .Value := StrToInt  (stringReplace(s,'MaxPersonalTamedDinos='                   ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('MaxTamedDinos'                           ,s)=1)) then begin FSE_MaxTamedDinos                             .Value := StrToFloat(stringReplace(s,'MaxTamedDinos='                           ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('DestroyTamesOverTheSoftTameLimit'        ,s)=1)) then begin ChB_DestroyTamesOverTheSoftTameLimit        .Checked := StrToBool (stringReplace(s,'DestroyTamesOverTheSoftTameLimit='        ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('MaxTamedDinos_SoftTameLimit'             ,s)=1)) then begin SE_MaxTamedDinos_SoftTameLimit                .Value := StrToInt  (stringReplace(s,'MaxTamedDinos_SoftTameLimit='             ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('MaxTamedDinos_SoftTameLimit_CountdownForDeletionDuration'
                                                                                      ,s)=1)) then begin SE_MaxTamedDinos_SoftTameLimit_CountdownForDeletionDuration.Value
                                                                                                                                                              := StrToInt  (stringReplace(s,'MaxTamedDinos_SoftTameLimit_CountdownForDeletionDuration='
                                                                                                                                                                                                                                       ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('MaxTributeDinos'                         ,s)=1)) then begin SE_MaxTributeDinos                            .Value := StrToInt  (stringReplace(s,'MaxTributeDinos='                         ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('MaxTributeItems'                         ,s)=1)) then begin SE_MaxTributeItems                            .Value := StrToInt  (stringReplace(s,'MaxTributeItems='                         ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('MaxTributeCharacters'                    ,s)=1)) then begin SE_MaxTributeCharacters                       .Value := StrToInt  (stringReplace(s,'MaxTributeCharacters='                    ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('NonPermanentDiseases'                    ,s)=1)) then begin CB_NonPermanentDiseases                     .Checked := StrToBool (stringReplace(s,'NonPermanentDiseases='                    ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('OverrideOfficialDifficulty'              ,s)=1)) then begin FSE_OverrideOfficialDifficulty                .Value := StrToFloat(stringReplace(s,'OverrideOfficialDifficulty='              ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('OverrideStructurePlatformPrevention'     ,s)=1)) then begin CB_OverrideStructurePlatformPrevention      .Checked := StrToBool (stringReplace(s,'OverrideStructurePlatformPrevention='     ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('OxygenSwimSpeedStatMultiplier'           ,s)=1)) then begin FSE_OxygenSwimSpeedStatMultiplier             .Value := StrToFloat(stringReplace(s,'OxygenSwimSpeedStatMultiplier='           ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('PerPlatformMaxStructuresMultiplier'      ,s)=1)) then begin FSE_PerPlatformMaxStructuresMultiplier        .Value := StrToFloat(stringReplace(s,'PerPlatformMaxStructuresMultiplier='      ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('PlatformSaddleBuildAreaBoundsMultiplier' ,s)=1)) then begin FSE_PlatformSaddleBuildAreaBoundsMultiplier   .Value := StrToFloat(stringReplace(s,'PlatformSaddleBuildAreaBoundsMultiplier=' ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('PlayerCharacterFoodDrainMultiplier'      ,s)=1)) then begin FSE_PlayerCharacterFoodDrainMultiplier        .Value := StrToFloat(stringReplace(s,'PlayerCharacterFoodDrainMultiplier='      ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('PlayerCharacterHealthRecoveryMultiplier' ,s)=1)) then begin FSE_PlayerCharacterHealthRecoveryMultiplier   .Value := StrToFloat(stringReplace(s,'PlayerCharacterHealthRecoveryMultiplier=' ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('PlayerCharacterStaminaDrainMultiplier'   ,s)=1)) then begin FSE_PlayerCharacterStaminaDrainMultiplier     .Value := StrToFloat(stringReplace(s,'PlayerCharacterStaminaDrainMultiplier='   ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('PlayerCharacterWaterDrainMultiplier'     ,s)=1)) then begin FSE_PlayerCharacterWaterDrainMultiplier       .Value := StrToFloat(stringReplace(s,'PlayerCharacterWaterDrainMultiplier='     ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('PlayerDamageMultiplier'                  ,s)=1)) then begin FSE_PlayerDamageMultiplier                    .Value := StrToFloat(stringReplace(s,'PlayerDamageMultiplier='                  ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('PlayerResistanceMultiplier'              ,s)=1)) then begin FSE_PlayerResistanceMultiplier                .Value := StrToFloat(stringReplace(s,'PlayerResistanceMultiplier='              ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('PreventDiseases'                         ,s)=1)) then begin ChB_PreventDiseases                         .Checked := StrToBool (stringReplace(s,'PreventDiseases='                         ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('PreventMateBoost'                        ,s)=1)) then begin ChB_PreventMateBoost                        .Checked := StrToBool (stringReplace(s,'PreventMateBoost='                        ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('PreventOfflinePvP'                       ,s)=1)) then begin ChB_PreventOfflinePvP                       .Checked := StrToBool (stringReplace(s,'PreventOfflinePvP='                       ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('PreventOfflinePvPInterval'               ,s)=1)) then begin FSE_PreventOfflinePvPInterval                 .Value := StrToFloat(stringReplace(s,'PreventOfflinePvPInterval='               ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('PreventSpawnAnimations'                  ,s)=1)) then begin ChB_PreventSpawnAnimations                  .Checked := StrToBool (stringReplace(s,'PreventSpawnAnimations='                  ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('PreventTribeAlliances'                   ,s)=1)) then begin ChB_PreventTribeAlliances                   .Checked := StrToBool (stringReplace(s,'PreventTribeAlliances='                   ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('ProximityChat'                           ,s)=1)) then begin ChB_ProximityChat                           .Checked := StrToBool (stringReplace(s,'ProximityChat='                           ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('PvEAllowStructuresAtSupplyDrops'         ,s)=1)) then begin ChB_PvEAllowStructuresAtSupplyDrops         .Checked := StrToBool (stringReplace(s,'PvEAllowStructuresAtSupplyDrops='         ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('PvEDinoDecayPeriodMultiplier'            ,s)=1)) then begin FSE_PvEDinoDecayPeriodMultiplier              .Value := StrToFloat(stringReplace(s,'PvEDinoDecayPeriodMultiplier='            ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('PvPDinoDecay'                            ,s)=1)) then begin ChB_PvPDinoDecay                            .Checked := StrToBool (stringReplace(s,'PvPDinoDecay='                            ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('PvPStructureDecay'                       ,s)=1)) then begin ChB_PvPStructureDecay                       .Checked := StrToBool (stringReplace(s,'PvPStructureDecay='                       ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('RaidDinoCharacterFoodDrainMultiplier'    ,s)=1)) then begin FSE_RaidDinoCharacterFoodDrainMultiplier      .Value := StrToFloat(stringReplace(s,'RaidDinoCharacterFoodDrainMultiplier='    ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('RandomSupplyCratePoints'                 ,s)=1)) then begin ChB_RandomSupplyCratePoints                 .Checked := StrToBool (stringReplace(s,'RandomSupplyCratePoints='                 ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('RCONEnabled'                             ,s)=1)) then begin CB_RCONEnabled                              .Checked := StrToBool (stringReplace(s,'RCONEnabled='                             ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('RCONPort'                                ,s)=1)) then begin SE_RCONPort                                   .Value := StrToInt  (stringReplace(s,'RCONPort='                                ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('RCONServerGameLogBuffer'                 ,s)=1)) then begin FSE_RCONServerGameLogBuffer                   .Value := StrToFloat(stringReplace(s,'RCONServerGameLogBuffer='                 ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('ResourcesRespawnPeriodMultiplier'        ,s)=1)) then begin FSE_ResourcesRespawnPeriodMultiplier          .Value := StrToFloat(stringReplace(s,'ResourcesRespawnPeriodMultiplier='        ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('ServerAdminPassword'                     ,s)=1)) then begin Edit_ServerAdminPassword                       .Text :=            stringReplace(s,'ServerAdminPassword='                     ,'',[rfReplaceAll, rfIgnoreCase]);
        end else if ((sec=cSec_SvrS)and(pos('ServerCrosshair'                         ,s)=1)) then begin ChB_ServerCrosshair                         .Checked := StrToBool (stringReplace(s,'ServerCrosshair='                         ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('ServerForceNoHUD'                        ,s)=1)) then begin ChB_ServerForceNoHUD                        .Checked := StrToBool (stringReplace(s,'ServerForceNoHUD='                        ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('ServerHardcore'                          ,s)=1)) then begin ChB_ServerHardcore                          .Checked := StrToBool (stringReplace(s,'ServerHardcore='                          ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('ServerPassword'                          ,s)=1)) then begin Edit_ServerPassword                            .Text :=            stringReplace(s,'ServerPassword='                          ,'',[rfReplaceAll, rfIgnoreCase]);
        end else if ((sec=cSec_SvrS)and(pos('serverPVE'                               ,s)=1)) then begin ChB_serverPVE                               .Checked := StrToBool (stringReplace(s,'serverPVE='                               ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('ShowFloatingDamageText'                  ,s)=1)) then begin ChB_ShowFloatingDamageText                  .Checked := StrToBool (stringReplace(s,'ShowFloatingDamageText='                  ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('ShowMapPlayerLocation'                   ,s)=1)) then begin ChB_ShowMapPlayerLocation                   .Checked := StrToBool (stringReplace(s,'ShowMapPlayerLocation='                   ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('StructurePickupHoldDuration'             ,s)=1)) then begin FSE_StructurePickupHoldDuration               .Value := StrToFloat(stringReplace(s,'StructurePickupHoldDuration='             ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('StructurePickupTimeAfterPlacement'       ,s)=1)) then begin FSE_StructurePickupTimeAfterPlacement         .Value := StrToFloat(stringReplace(s,'StructurePickupTimeAfterPlacement='       ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('StructurePreventResourceRadiusMultiplier',s)=1)) then begin FSE_StructurePreventResourceRadiusMultiplier  .Value := StrToFloat(stringReplace(s,'StructurePreventResourceRadiusMultiplier=','',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('StructureResistanceMultiplier'           ,s)=1)) then begin FSE_StructureResistanceMultiplier             .Value := StrToFloat(stringReplace(s,'StructureResistanceMultiplier='           ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('TamingSpeedMultiplier'                   ,s)=1)) then begin FSE_TamingSpeedMultiplier                     .Value := StrToFloat(stringReplace(s,'TamingSpeedMultiplier='                   ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('TheMaxStructuresInRange'                 ,s)=1)) then begin SE_TheMaxStructuresInRange                    .Value := StrToInt  (stringReplace(s,'TheMaxStructuresInRange='                 ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('TribeNameChangeCooldown'                 ,s)=1)) then begin FSE_TribeNameChangeCooldown                   .Value := StrToFloat(stringReplace(s,'TribeNameChangeCooldown='                 ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('XPMultiplier'                            ,s)=1)) then begin FSE_XPMultiplier                              .Value := StrToFloat(stringReplace(s,'XPMultiplier='                            ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('noTributeDownloads'                      ,s)=1)) then begin ChB_noTributeDownloads                      .Checked := StrToBool (stringReplace(s,'noTributeDownloads='                      ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('CrossARKAllowForeignDinoDownloads'       ,s)=1)) then begin ChB_CrossARKAllowForeignDinoDownloads       .Checked := StrToBool (stringReplace(s,'CrossARKAllowForeignDinoDownloads='       ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('PreventDownloadDinos'                    ,s)=1)) then begin ChB_PreventDownloadDinos                    .Checked := StrToBool (stringReplace(s,'PreventDownloadDinos='                    ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('PreventDownloadItems'                    ,s)=1)) then begin ChB_PreventDownloadItems                    .Checked := StrToBool (stringReplace(s,'PreventDownloadItems='                    ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('PreventDownloadSurvivors'                ,s)=1)) then begin ChB_PreventDownloadSurvivors                .Checked := StrToBool (stringReplace(s,'PreventDownloadSurvivors='                ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('PreventUploadDinos'                      ,s)=1)) then begin ChB_PreventUploadDinos                      .Checked := StrToBool (stringReplace(s,'PreventUploadDinos='                      ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('PreventUploadItems'                      ,s)=1)) then begin ChB_PreventUploadItems                      .Checked := StrToBool (stringReplace(s,'PreventUploadItems='                      ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('PreventUploadSurvivors'                  ,s)=1)) then begin ChB_PreventUploadSurvivors                  .Checked := StrToBool (stringReplace(s,'PreventUploadSurvivors='                  ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('DisableCryopodEnemyCheck'                ,s)=1)) then begin ChB_DisableCryopodEnemyCheck                .Checked := StrToBool (stringReplace(s,'DisableCryopodEnemyCheck='                ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('AllowCryoFridgeOnSaddle'                 ,s)=1)) then begin ChB_AllowCryoFridgeOnSaddle                 .Checked := StrToBool (stringReplace(s,'AllowCryoFridgeOnSaddle='                 ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('DisableCryopodFridgeRequirement'         ,s)=1)) then begin ChB_DisableCryopodFridgeRequirement         .Checked := StrToBool (stringReplace(s,'DisableCryopodFridgeRequirement='         ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('DinoCountMultiplier'                     ,s)=1)) then begin FSE_DinoCountMultiplier                       .Value := StrToFloat(stringReplace(s,'DinoCountMultiplier='                     ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('StructureDamageMultiplier'               ,s)=1)) then begin FSE_StructureDamageMultiplier                 .Value := StrToFloat(stringReplace(s,'StructureDamageMultiplier='               ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('AlwaysNotifyPlayerLeft'                  ,s)=1)) then begin ChB_AlwaysNotifyPlayerLeft                  .Checked := StrToBool (stringReplace(s,'AlwaysNotifyPlayerLeft='                  ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('PvEStructureDecayPeriodMultiplier'       ,s)=1)) then begin FSE_PvEStructureDecayPeriodMultiplier         .Value := StrToFloat(stringReplace(s,'PvEStructureDecayPeriodMultiplier='       ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('OverrideStartTime'                       ,s)=1)) then begin ChB_OverrideStartTime                       .Checked := StrToBool (stringReplace(s,'OverrideStartTime='                       ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('StartTimeHour'                           ,s)=1)) then begin FSE_StartTimeHour                             .Value := StrToFloat(stringReplace(s,'StartTimeHour='                           ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('bAllowCustomRecipes'                     ,s)=1)) then begin ChB_bAllowCustomRecipes                     .Checked := StrToBool (stringReplace(s,'bAllowCustomRecipes='                     ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('TamedDinoDamageMultiplier'               ,s)=1)) then begin FSE_TamedDinoDamageMultiplier                 .Value := StrToFloat(stringReplace(s,'TamedDinoDamageMultiplier='               ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('TamedDinoResistanceMultiplier'           ,s)=1)) then begin FSE_TamedDinoResistanceMultiplier             .Value := StrToFloat(stringReplace(s,'TamedDinoResistanceMultiplier='           ,'',[rfReplaceAll, rfIgnoreCase]));

        end else if ((sec=cSec_SvrS)and(pos('AutoRestartIntervalSeconds'              ,s)=1)) then begin FSE_AutoRestartIntervalSeconds                .Value := StrToFloat(stringReplace(s,'AutoRestartIntervalSeconds='              ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SesS)and(pos('PhotoModeRangeLimit'                     ,s)=1)) then begin SE_PhotoModeRangeLimit                        .Value := StrToInt  (stringReplace(s,'PhotoModeRangeLimit='                     ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('UpdateAllowedCheatersInterval'           ,s)=1)) then begin FSE_UpdateAllowedCheatersInterval             .Value := StrToFloat(stringReplace(s,'UpdateAllowedCheatersInterval='           ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('ServerAutoForceRespawnWildDinosInterval' ,s)=1)) then begin FSE_ServerAutoForceRespawnWildDinosInterval   .Value := StrToFloat(stringReplace(s,'ServerAutoForceRespawnWildDinosInterval=' ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('UseCharacterTracker'                     ,s)=1)) then begin ChB_UseCharacterTracker                     .Checked := StrToBool (stringReplace(s,'UseCharacterTracker='                     ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('BanListURL'                              ,s)=1)) then begin Edit_BanListURL                                .Text :=            stringReplace(s,'BanListURL='                              ,'',[rfReplaceAll, rfIgnoreCase]);
        end else if ((sec=cSec_SvrS)and(pos('CustomLiveTuningUrl'                     ,s)=1)) then begin Edit_CustomLiveTuningUrl                       .Text :=            stringReplace(s,'CustomLiveTuningUrl='                     ,'',[rfReplaceAll, rfIgnoreCase]);
        end else if ((sec=cSec_SvrS)and(pos('BadWordListURL'                          ,s)=1)) then begin Edit_BadWordListURL                            .Text :=            stringReplace(s,'BadWordListURL='                          ,'',[rfReplaceAll, rfIgnoreCase]);
        end else if ((sec=cSec_SvrS)and(pos('BadWordWhiteListURL'                     ,s)=1)) then begin Edit_BadWordWhiteListURL                       .Text :=            stringReplace(s,'BadWordWhiteListURL='                     ,'',[rfReplaceAll, rfIgnoreCase]);
        end else if ((sec=cSec_SvrS)and(pos('AdminListURL'                            ,s)=1)) then begin Edit_AdminListURL                              .Text :=            stringReplace(s,'AdminListURL='                            ,'',[rfReplaceAll, rfIgnoreCase]);
        end else if ((sec=cSec_SvrS)and(pos('MaxTrainCars'                            ,s)=1)) then begin SE_MaxTrainCars                               .Value := StrToInt  (stringReplace(s,'MaxTrainCars='                            ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('ImplantSuicideCD'                        ,s)=1)) then begin SE_ImplantSuicideCD                           .Value := StrToInt  (stringReplace(s,'ImplantSuicideCD='                        ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('AutoDestroyOldStructuresMultiplier'      ,s)=1)) then begin FSE_AutoDestroyOldStructuresMultiplier        .Value := StrToFloat(stringReplace(s,'AutoDestroyOldStructuresMultiplier='      ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('MaxPlatformSaddleStructureLimit'         ,s)=1)) then begin SE_MaxPlatformSaddleStructureLimit            .Value := StrToInt  (stringReplace(s,'MaxPlatformSaddleStructureLimit='         ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('MaxGateFrameOnSaddles'                   ,s)=1)) then begin SE_MaxGateFrameOnSaddles                      .Value := StrToInt  (stringReplace(s,'MaxGateFrameOnSaddles='                   ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('MaxBlueprintDinoLevel'                   ,s)=1)) then begin SE_MaxBlueprintDinoLevel                      .Value := StrToInt  (stringReplace(s,'MaxBlueprintDinoLevel='                   ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('MaxBlueprintDinoQuality'                 ,s)=1)) then begin SE_MaxBlueprintDinoQuality                    .Value := StrToInt  (stringReplace(s,'MaxBlueprintDinoQuality='                 ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('MaxBlueprintItemQuality'                 ,s)=1)) then begin SE_MaxBlueprintItemQuality                    .Value := StrToInt  (stringReplace(s,'MaxBlueprintItemQuality='                 ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('MaxBlueprintScoutQuality'                ,s)=1)) then begin SE_MaxBlueprintScoutQuality                   .Value := StrToInt  (stringReplace(s,'MaxBlueprintScoutQuality='                ,'',[rfReplaceAll, rfIgnoreCase]));

        end else if ((sec=cSec_SvrS)and(pos('TribeTowerBonusMultiplier'               ,s)=1)) then begin FSE_TribeTowerBonusMultiplier                 .Value := StrToFloat(stringReplace(s,'TribeTowerBonusMultiplier='               ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('LimitBunkersPerTribe'                    ,s)=1)) then begin ChB_LimitBunkersPerTribe                    .Checked := StrToBool (stringReplace(s,'LimitBunkersPerTribe='                    ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('LimitBunkersPerTribeNum'                 ,s)=1)) then begin SE_LimitBunkersPerTribeNum                    .Value := StrToInt  (stringReplace(s,'LimitBunkersPerTribeNum='                 ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('AllowBunkersInPreventionZones'           ,s)=1)) then begin ChB_AllowBunkersInPreventionZones           .Checked := StrToBool (stringReplace(s,'AllowBunkersInPreventionZones='           ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('AllowRidingDinosInsideBunkers'           ,s)=1)) then begin ChB_AllowRidingDinosInsideBunkers           .Checked := StrToBool (stringReplace(s,'AllowRidingDinosInsideBunkers='           ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('AllowBunkerModulesAboveGround'           ,s)=1)) then begin ChB_AllowBunkerModulesAboveGround           .Checked := StrToBool (stringReplace(s,'AllowBunkerModulesAboveGround='           ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('AllowDinoAIInsideBunkers'                ,s)=1)) then begin ChB_AllowDinoAIInsideBunkers                .Checked := StrToBool (stringReplace(s,'AllowDinoAIInsideBunkers='                ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('AllowBunkerModulesInPreventionZones'     ,s)=1)) then begin ChB_AllowBunkerModulesInPreventionZones     .Checked := StrToBool (stringReplace(s,'AllowBunkerModulesInPreventionZones='     ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('MinDistanceBetweenBunkers'               ,s)=1)) then begin FSE_MinDistanceBetweenBunkers                 .Value := StrToFloat(stringReplace(s,'MinDistanceBetweenBunkers='               ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('EnemyAccessBunkerHPThreshold'            ,s)=1)) then begin FSE_EnemyAccessBunkerHPThreshold              .Value := StrToFloat(stringReplace(s,'EnemyAccessBunkerHPThreshold='            ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('BunkerUnderHPThresholdDmgMultiplier'     ,s)=1)) then begin FSE_BunkerUnderHPThresholdDmgMultiplier       .Value := StrToFloat(stringReplace(s,'BunkerUnderHPThresholdDmgMultiplier='     ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('CryoHospitalHoursToRegenHP'              ,s)=1)) then begin FSE_CryoHospitalHoursToRegenHP                .Value := StrToFloat(stringReplace(s,'CryoHospitalHoursToRegenHP='              ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('CryoHospitalHoursToRegenFood'            ,s)=1)) then begin FSE_CryoHospitalHoursToRegenFood              .Value := StrToFloat(stringReplace(s,'CryoHospitalHoursToRegenFood='            ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('CryoHospitalHoursToDrainTorpor'          ,s)=1)) then begin FSE_CryoHospitalHoursToDrainTorpor            .Value := StrToFloat(stringReplace(s,'CryoHospitalHoursToDrainTorpor='          ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('CryoHospitalMatingCooldownReduction'     ,s)=1)) then begin FSE_CryoHospitalMatingCooldownReduction       .Value := StrToFloat(stringReplace(s,'CryoHospitalMatingCooldownReduction='     ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('BloodforgeReinforceExtraDurability'      ,s)=1)) then begin FSE_BloodforgeReinforceExtraDurability        .Value := StrToFloat(stringReplace(s,'BloodforgeReinforceExtraDurability='      ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('BloodforgeReinforceResourceCostMultiplier',s)=1)) then begin FSE_BloodforgeReinforceResourceCostMultiplier.Value := StrToFloat(stringReplace(s,'BloodforgeReinforceResourceCostMultiplier=','',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('BloodforgeReinforceSpeedMultiplier'      ,s)=1)) then begin FSE_BloodforgeReinforceSpeedMultiplier        .Value := StrToFloat(stringReplace(s,'BloodforgeReinforceSpeedMultiplier='      ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('MaxActiveOutposts'                       ,s)=1)) then begin SE_MaxActiveOutposts                          .Value := StrToInt  (stringReplace(s,'MaxActiveOutposts='                       ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('MaxActiveResourceCaches'                 ,s)=1)) then begin SE_MaxActiveResourceCaches                    .Value := StrToInt  (stringReplace(s,'MaxActiveResourceCaches='                 ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SvrS)and(pos('MaxActiveCityOutposts'                   ,s)=1)) then begin SE_MaxActiveCityOutposts                      .Value := StrToInt  (stringReplace(s,'MaxActiveCityOutposts='                   ,'',[rfReplaceAll, rfIgnoreCase]));









        //SessionSettings
        end else if ((sec=cSec_SesS)and(pos('Port'                                    ,s)=1)) then begin SE_Port                                       .Value := StrToInt  (stringReplace(s,'Port='                                    ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SesS)and(pos('QueryPort'                               ,s)=1)) then begin SE_QueryPort                                  .Value := StrToInt  (stringReplace(s,'QueryPort='                               ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_SesS)and(pos('SessionName'                             ,s)=1)) then begin Edit_SessionName                               .Text :=            stringReplace(s,'SessionName='                             ,'',[rfReplaceAll, rfIgnoreCase]);

        //MessageOfTheDay
        end else if ((sec=cSec_MOTD)and(pos('Message'                                 ,s)=1)) then begin Edit_Message                                   .Text :=            stringReplace(s,'Message='                                 ,'',[rfReplaceAll, rfIgnoreCase]);
        end else if ((sec=cSec_MOTD)and(pos('Duration'                                ,s)=1)) then begin SE_Duration                                   .Value := StrToInt  (stringReplace(s,'Duration='                                ,'',[rfReplaceAll, rfIgnoreCase]));

        //Mod1 Cryopods
        end else if ((sec=cSec_Mod1)and(pos('ForceUseINISettings'                     ,s)=1)) then begin ChB_Mod1_ForceUseINISettings                .Checked := StrToBool (stringReplace(s,'ForceUseINISettings='                     ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod1)and(pos('DisableCryoSickness'                     ,s)=1)) then begin ChB_Mod1_DisableCryoSickness                .Checked := StrToBool (stringReplace(s,'DisableCryoSickness='                     ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod1)and(pos('PreventDeployInCaves'                    ,s)=1)) then begin ChB_Mod1_PreventDeployInCaves               .Checked := StrToBool (stringReplace(s,'PreventDeployInCaves='                    ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod1)and(pos('CryoTime'                                ,s)=1)) then begin FSE_Mod1_CryoTime                             .Value := StrToFloat(stringReplace(s,'CryoTime='                                ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod1)and(pos('CryoTimeInCombat'                        ,s)=1)) then begin FSE_Mod1_CryoTimeInCombat                     .Value := StrToFloat(stringReplace(s,'CryoTimeInCombat='                        ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod1)and(pos('CryoSicknessTimer'                       ,s)=1)) then begin SE_Mod1_CryoSicknessTimer                     .Value := StrToInt  (stringReplace(s,'CryoSicknessTimer='                       ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod1)and(pos('DisableAutoCycle'                        ,s)=1)) then begin ChB_Mod1_DisableAutoCycle                   .Checked := StrToBool (stringReplace(s,'DisableAutoCycle='                        ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod1)and(pos('CryogunRangeFoundations'                 ,s)=1)) then begin SE_Mod1_CryogunRangeFoundations               .Value := StrToInt  (stringReplace(s,'CryogunRangeFoundations='                 ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod1)and(pos('CryogunCooldownSeconds'                  ,s)=1)) then begin SE_Mod1_CryogunCooldownSeconds                .Value := StrToInt  (stringReplace(s,'CryogunCooldownSeconds='                  ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod1)and(pos('NeutergunRangeFoundations'               ,s)=1)) then begin SE_Mod1_NeutergunRangeFoundations             .Value := StrToInt  (stringReplace(s,'NeutergunRangeFoundations='               ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod1)and(pos('NeutergunCooldownSeconds'                ,s)=1)) then begin SE_Mod1_NeutergunCooldownSeconds              .Value := StrToInt  (stringReplace(s,'NeutergunCooldownSeconds='                ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod1)and(pos('DisableCryopodsRequirement'              ,s)=1)) then begin ChB_Mod1_DisableCryopodsRequirement         .Checked := StrToBool (stringReplace(s,'DisableCryopodsRequirement='              ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod1)and(pos('CryoTerminalCaptureInterval'             ,s)=1)) then begin FSE_Mod1_CryoTerminalCaptureInterval          .Value := StrToFloat(stringReplace(s,'CryoTerminalCaptureInterval='             ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod1)and(pos('CryoTerminalMaxRadiusFoundations'        ,s)=1)) then begin SE_Mod1_CryoTerminalMaxRadiusFoundations      .Value := StrToInt  (stringReplace(s,'CryoTerminalMaxRadiusFoundations='        ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod1)and(pos('PassImprintToDeployer'                   ,s)=1)) then begin ChB_Mod1_PassImprintToDeployer              .Checked := StrToBool (stringReplace(s,'PassImprintToDeployer='                   ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod1)and(pos('ImprintAmountToGive'                     ,s)=1)) then begin SE_Mod1_ImprintAmountToGive                   .Value := StrToInt  (stringReplace(s,'ImprintAmountToGive='                     ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod1)and(pos('FullyGrownBabies'                        ,s)=1)) then begin ChB_Mod1_FullyGrownBabies                   .Checked := StrToBool (stringReplace(s,'FullyGrownBabies='                        ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod1)and(pos('AllowCryoterminalOnPlatforms'            ,s)=1)) then begin ChB_Mod1_AllowCryoterminalOnPlatforms       .Checked := StrToBool (stringReplace(s,'AllowCryoterminalOnPlatforms='            ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod1)and(pos('AllowAdminCaptureAll'                    ,s)=1)) then begin ChB_Mod1_AllowAdminCaptureAll               .Checked := StrToBool (stringReplace(s,'AllowAdminCaptureAll='                    ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod1)and(pos('MaxCryoterminalsInRange'                 ,s)=1)) then begin SE_Mod1_MaxCryoterminalsInRange               .Value := StrToInt  (stringReplace(s,'MaxCryoterminalsInRange='                 ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod1)and(pos('LimitCryoterminalsRange'                 ,s)=1)) then begin SE_Mod1_LimitCryoterminalsRange               .Value := StrToInt  (stringReplace(s,'LimitCryoterminalsRange='                 ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod1)and(pos('AllowDeployInBossArenas'                 ,s)=1)) then begin ChB_Mod1_AllowDeployInBossArenas            .Checked := StrToBool (stringReplace(s,'AllowDeployInBossArenas='                 ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod1)and(pos('CryopodChargeSpeedMultiplier'            ,s)=1)) then begin FSE_Mod1_CryopodChargeSpeedMultiplier         .Value := StrToFloat(stringReplace(s,'CryopodChargeSpeedMultiplier='            ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod1)and(pos('DisableCryopodChargeNeed'                ,s)=1)) then begin ChB_Mod1_DisableCryopodChargeNeed           .Checked := StrToBool (stringReplace(s,'DisableCryopodChargeNeed='                ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod1)and(pos('GiveTemporaryCryopodsInCryoterminal'     ,s)=1)) then begin ChB_Mod1_GiveTemporaryCryopodsInCryoterminal.Checked := StrToBool (stringReplace(s,'GiveTemporaryCryopodsInCryoterminal='     ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod1)and(pos('CryofridgeInventorySlots'                ,s)=1)) then begin SE_Mod1_CryofridgeInventorySlots              .Value := StrToInt  (stringReplace(s,'CryofridgeInventorySlots='                ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod1)and(pos('CryoterminalInventorySlots'              ,s)=1)) then begin SE_Mod1_CryoterminalInventorySlots            .Value := StrToInt  (stringReplace(s,'CryoterminalInventorySlots='              ,'',[rfReplaceAll, rfIgnoreCase]));

        //Mod2 SuperSpyglassPlus
        end else if ((sec=cSec_Mod2)and(pos('DisableNightVision'                      ,s)=1)) then begin ChB_Mod2_DisableNightVision                 .Checked := StrToBool (stringReplace(s,'DisableNightVision='                      ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod2)and(pos('DisablePredatorVision'                   ,s)=1)) then begin ChB_Mod2_DisablePredatorVision              .Checked := StrToBool (stringReplace(s,'DisablePredatorVision='                   ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod2)and(pos('DisableOutlineMode'                      ,s)=1)) then begin ChB_Mod2_DisableOutlineMode                 .Checked := StrToBool (stringReplace(s,'DisableOutlineMode='                      ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod2)and(pos('DisableSupplyDropInfo'                   ,s)=1)) then begin ChB_Mod2_DisableSupplyDropInfo              .Checked := StrToBool (stringReplace(s,'DisableSupplyDropInfo='                   ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod2)and(pos('DisableItembagInfo'                      ,s)=1)) then begin ChB_Mod2_DisableItembagInfo                 .Checked := StrToBool (stringReplace(s,'DisableItembagInfo='                      ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod2)and(pos('DisableStructureInfo'                    ,s)=1)) then begin ChB_Mod2_DisableStructureInfo               .Checked := StrToBool (stringReplace(s,'DisableStructureInfo='                    ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod2)and(pos('DisableBuffInfo'                         ,s)=1)) then begin ChB_Mod2_DisableBuffInfo                    .Checked := StrToBool (stringReplace(s,'DisableBuffInfo='                         ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod2)and(pos('DisableTameFoodInfo'                     ,s)=1)) then begin ChB_Mod2_DisableTameFoodInfo                .Checked := StrToBool (stringReplace(s,'DisableTameFoodInfo='                     ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod2)and(pos('DisableEggInfo'                          ,s)=1)) then begin ChB_Mod2_DisableEggInfo                     .Checked := StrToBool (stringReplace(s,'DisableEggInfo='                          ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod2)and(pos('DisableTheSpyglassOnEnemyTribes'         ,s)=1)) then begin ChB_Mod2_DisableTheSpyglassOnEnemyTribes    .Checked := StrToBool (stringReplace(s,'DisableTheSpyglassOnEnemyTribes='         ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod2)and(pos('OnlyShowStatsForTames'                   ,s)=1)) then begin ChB_Mod2_OnlyShowStatsForTames              .Checked := StrToBool (stringReplace(s,'OnlyShowStatsForTames='                   ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod2)and(pos('DisableGPS'                              ,s)=1)) then begin ChB_Mod2_DisableGPS                         .Checked := StrToBool (stringReplace(s,'DisableGPS='                              ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod2)and(pos('DisableCrosshair'                        ,s)=1)) then begin ChB_Mod2_DisableCrosshair                   .Checked := StrToBool (stringReplace(s,'DisableCrosshair='                        ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod2)and(pos('OnlyHPonEnemyTribeDinos'                 ,s)=1)) then begin ChB_Mod2_OnlyHPonEnemyTribeDinos            .Checked := StrToBool (stringReplace(s,'OnlyHPonEnemyTribeDinos='                 ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod2)and(pos('OutlineRange'                            ,s)=1)) then begin SE_Mod2_OutlineRange                          .Value := StrToInt  (stringReplace(s,'OutlineRange='                            ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod2)and(pos('UseESPOutline'                           ,s)=1)) then begin ChB_Mod2_UseESPOutline                      .Checked := StrToBool (stringReplace(s,'UseESPOutline='                           ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod2)and(pos('UseESPOutlineFill'                       ,s)=1)) then begin ChB_Mod2_UseESPOutlineFill                  .Checked := StrToBool (stringReplace(s,'UseESPOutlineFill='                       ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod2)and(pos('DontShowAnyStatsOnWildDino'              ,s)=1)) then begin ChB_Mod2_DontShowAnyStatsOnWildDino         .Checked := StrToBool (stringReplace(s,'DontShowAnyStatsOnWildDino='              ,'',[rfReplaceAll, rfIgnoreCase]));

        //Mod3 DerDinoFinder
        end else if ((sec=cSec_Mod3)and(pos('IsAdminOnly'                             ,s)=1)) then begin ChB_Mod3_IsAdminOnly                        .Checked := StrToBool (stringReplace(s,'IsAdminOnly='                             ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod3)and(pos('MarkerLimit'                             ,s)=1)) then begin SE_Mod3_MarkerLimit                           .Value := StrToInt  (stringReplace(s,'MarkerLimit='                             ,'',[rfReplaceAll, rfIgnoreCase]));

        //Mod4

        //Mod5 QoLPlus
        end else if ((sec=cSec_Mod5)and(pos('RemoveFloorRequirementFromStructurePlacement',s)=1)) then begin CB_Mod5_RemoveFloorRequirementFromStructurePlacement.Checked := StrToBool (stringReplace(s,'RemoveFloorRequirementFromStructurePlacement='
                                                                                                                                                                                                                   ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('DisableResourcePulling'                  ,s)=1)) then begin CB_Mod5_DisableResourcePulling              .Checked := StrToBool (stringReplace(s,'DisableResourcePulling='                  ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('ResourceTransferCooldown'                ,s)=1)) then begin FSE_Mod5_ResourceTransferCooldown             .Value := StrToFloat(stringReplace(s,'ResourceTransferCooldown='                ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('DisableResourcePulling'                  ,s)=1)) then begin CB_Mod5_DisableResourcePulling              .Checked := StrToBool (stringReplace(s,'DisableResourcePulling='                  ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('PullingIgnoresPinCodes'                  ,s)=1)) then begin ChB_Mod5_PullingIgnoresPinCodes             .Checked := StrToBool (stringReplace(s,'PullingIgnoresPinCodes='                  ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('EnableExtendedDeathCache'                ,s)=1)) then begin ChB_Mod5_EnableExtendedDeathCache           .Checked := StrToBool (stringReplace(s,'EnableExtendedDeathCache='                ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('EnableUpdateDurability'                  ,s)=1)) then begin ChB_Mod5_EnableUpdateDurability             .Checked := StrToBool (stringReplace(s,'EnableUpdateDurability='                  ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('AllowTekItemBlueprintCreation'           ,s)=1)) then begin ChB_Mod5_AllowTekItemBlueprintCreation      .Checked := StrToBool (stringReplace(s,'AllowTekItemBlueprintCreation='           ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('AllowMakingWeaponsAndArmorBPs'           ,s)=1)) then begin ChB_Mod5_AllowMakingWeaponsAndArmorBPs      .Checked := StrToBool (stringReplace(s,'AllowMakingWeaponsAndArmorBPs='           ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('DisableMultiToolDinoKillMode'            ,s)=1)) then begin ChB_Mod5_DisableMultiToolDinoKillMode       .Checked := StrToBool (stringReplace(s,'DisableMultiToolDinoKillMode='            ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('DisableMultiToolDinoChibiMode'           ,s)=1)) then begin ChB_Mod5_DisableMultiToolDinoChibiMode      .Checked := StrToBool (stringReplace(s,'DisableMultiToolDinoChibiMode='           ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('AllowMultiToolNeuterAll'                 ,s)=1)) then begin ChB_Mod5_AllowMultiToolNeuterAll            .Checked := StrToBool (stringReplace(s,'AllowMultiToolNeuterAll='                 ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('AllowGrindingMissionRewards'             ,s)=1)) then begin ChB_Mod5_AllowGrindingMissionRewards        .Checked := StrToBool (stringReplace(s,'AllowGrindingMissionRewards='             ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('EnableStructureSound'                    ,s)=1)) then begin ChB_Mod5_EnableStructureSound               .Checked := StrToBool (stringReplace(s,'EnableStructureSound='                    ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('DisableBlueprintInstall'                 ,s)=1)) then begin ChB_Mod5_DisableBlueprintInstall            .Checked := StrToBool (stringReplace(s,'DisableBlueprintInstall='                 ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('PropagatorFuelInterval'                  ,s)=1)) then begin SE_Mod5_PropagatorFuelInterval                .Value := StrToInt  (stringReplace(s,'PropagatorFuelInterval='                  ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('PropagatorModCostMutate'                 ,s)=1)) then begin SE_Mod5_PropagatorModCostMutate               .Value := StrToInt  (stringReplace(s,'PropagatorModCostMutate='                 ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('PropagatorDisableDinoMods'               ,s)=1)) then begin ChB_Mod5_PropagatorDisableDinoMods          .Checked := StrToBool (stringReplace(s,'PropagatorDisableDinoMods='               ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('PropagatorRespectMutationLimit'          ,s)=1)) then begin ChB_Mod5_PropagatorRespectMutationLimit     .Checked := StrToBool (stringReplace(s,'PropagatorRespectMutationLimit='          ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('PropagatorDisableEggDrop'                ,s)=1)) then begin ChB_Mod5_PropagatorDisableEggDrop           .Checked := StrToBool (stringReplace(s,'PropagatorDisableEggDrop='                ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('TribePropagatorLimit'                    ,s)=1)) then begin SE_Mod5_TribePropagatorLimit                  .Value := StrToInt  (stringReplace(s,'TribePropagatorLimit='                    ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('NannyMaxImprint'                         ,s)=1)) then begin SE_Mod5_NannyMaxImprint                       .Value := StrToInt  (stringReplace(s,'NannyMaxImprint='                         ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('DisableNannyImprinting'                  ,s)=1)) then begin ChB_Mod5_DisableNannyImprinting             .Checked := StrToBool (stringReplace(s,'DisableNannyImprinting='                  ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('NannyIntervalInSeconds'                  ,s)=1)) then begin SE_Mod5_NannyIntervalInSeconds                .Value := StrToInt  (stringReplace(s,'NannyIntervalInSeconds='                  ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('NannyFeedingStartThreshold'              ,s)=1)) then begin SE_Mod5_NannyFeedingStartThreshold            .Value := StrToInt  (stringReplace(s,'NannyFeedingStartThreshold='              ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('BeeHiveHoneyIntervalInSeconds'           ,s)=1)) then begin SE_Mod5_BeeHiveHoneyIntervalInSeconds         .Value := StrToInt  (stringReplace(s,'BeeHiveHoneyIntervalInSeconds='           ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('MutatorBuffMaxStackCount'                ,s)=1)) then begin SE_Mod5_MutatorBuffMaxStackCount              .Value := StrToInt  (stringReplace(s,'MutatorBuffMaxStackCount='                ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('MutatorAllowBreedingNeutered'            ,s)=1)) then begin ChB_Mod5_MutatorAllowBreedingNeutered       .Checked := StrToBool (stringReplace(s,'MutatorAllowBreedingNeutered='            ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('DisableHitchingPostMatingBonus'          ,s)=1)) then begin ChB_Mod5_DisableHitchingPostMatingBonus     .Checked := StrToBool (stringReplace(s,'DisableHitchingPostMatingBonus='          ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('HitchingPostRange'                       ,s)=1)) then begin SE_Mod5_HitchingPostRange                     .Value := StrToInt  (stringReplace(s,'HitchingPostRange='                       ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('HitchingPostDinoLimit'                   ,s)=1)) then begin SE_Mod5_HitchingPostDinoLimit                 .Value := StrToInt  (stringReplace(s,'HitchingPostDinoLimit='                   ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('HitchingPostTribeLimit'                  ,s)=1)) then begin SE_Mod5_HitchingPostTribeLimit                .Value := StrToInt  (stringReplace(s,'HitchingPostTribeLimit='                  ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('GrinderResourceReturnPercent'            ,s)=1)) then begin SE_Mod5_GrinderResourceReturnPercent          .Value := StrToInt  (stringReplace(s,'GrinderResourceReturnPercent='            ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('GrinderResourceReturnMax'                ,s)=1)) then begin SE_Mod5_GrinderResourceReturnMax              .Value := StrToInt  (stringReplace(s,'GrinderResourceReturnMax='                ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('GrinderReturnBlockedResources'           ,s)=1)) then begin ChB_Mod5_GrinderReturnBlockedResources      .Checked := StrToBool (stringReplace(s,'GrinderReturnBlockedResources='           ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('SmallStorageSlotCount'                   ,s)=1)) then begin SE_Mod5_SmallStorageSlotCount                 .Value := StrToInt  (stringReplace(s,'SmallStorageSlotCount='                   ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('LargeStorageSlotCount'                   ,s)=1)) then begin SE_Mod5_LargeStorageSlotCount                 .Value := StrToInt  (stringReplace(s,'LargeStorageSlotCount='                   ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('MetalStorageSlotCount'                   ,s)=1)) then begin SE_Mod5_MetalStorageSlotCount                 .Value := StrToInt  (stringReplace(s,'MetalStorageSlotCount='                   ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('PropagatorSlotCount'                     ,s)=1)) then begin SE_Mod5_PropagatorSlotCount                   .Value := StrToInt  (stringReplace(s,'PropagatorSlotCount='                     ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('NannySlotCount'                          ,s)=1)) then begin SE_Mod5_NannySlotCount                        .Value := StrToInt  (stringReplace(s,'NannySlotCount='                          ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('TransmutatorSlotCount'                   ,s)=1)) then begin SE_Mod5_TransmutatorSlotCount                 .Value := StrToInt  (stringReplace(s,'TransmutatorSlotCount='                   ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('GardenerSlotCount'                       ,s)=1)) then begin SE_Mod5_GardenerSlotCount                     .Value := StrToInt  (stringReplace(s,'GardenerSlotCount='                       ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('FarmerSlotCount'                         ,s)=1)) then begin SE_Mod5_FarmerSlotCount                       .Value := StrToInt  (stringReplace(s,'FarmerSlotCount='                         ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('BeeHiveSlotCount'                        ,s)=1)) then begin SE_Mod5_BeeHiveSlotCount                      .Value := StrToInt  (stringReplace(s,'BeeHiveSlotCount='                        ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('AmmoBoxSlotCount'                        ,s)=1)) then begin SE_Mod5_AmmoBoxSlotCount                      .Value := StrToInt  (stringReplace(s,'AmmoBoxSlotCount='                        ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('GrinderSlotCount'                        ,s)=1)) then begin SE_Mod5_GrinderSlotCount                      .Value := StrToInt  (stringReplace(s,'GrinderSlotCount='                        ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('IndustrialForgeSlotCount'                ,s)=1)) then begin SE_Mod5_IndustrialForgeSlotCount              .Value := StrToInt  (stringReplace(s,'IndustrialForgeSlotCount='                ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('GeneratorSlotCount'                      ,s)=1)) then begin SE_Mod5_GeneratorSlotCount                    .Value := StrToInt  (stringReplace(s,'GeneratorSlotCount='                      ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('ReplicatorSlotCount'                     ,s)=1)) then begin SE_Mod5_ReplicatorSlotCount                   .Value := StrToInt  (stringReplace(s,'ReplicatorSlotCount='                     ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('FridgeSlotCount'                         ,s)=1)) then begin SE_Mod5_FridgeSlotCount                       .Value := StrToInt  (stringReplace(s,'FridgeSlotCount='                         ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('PreservingBinSlotCount'                  ,s)=1)) then begin SE_Mod5_PreservingBinSlotCount                .Value := StrToInt  (stringReplace(s,'PreservingBinSlotCount='                  ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('FabricatorSlotCount'                     ,s)=1)) then begin SE_Mod5_FabricatorSlotCount                   .Value := StrToInt  (stringReplace(s,'FabricatorSlotCount='                     ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('TekGeneratorSlotCount'                   ,s)=1)) then begin SE_Mod5_TekGeneratorSlotCount                 .Value := StrToInt  (stringReplace(s,'TekGeneratorSlotCount='                   ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('RaidTimerLimitMultiplier'                ,s)=1)) then begin FSE_Mod5_RaidTimerLimitMultiplier             .Value := StrToFloat(stringReplace(s,'RaidTimerLimitMultiplier='                ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('PropagatorMatingSpeedMultiplier'         ,s)=1)) then begin FSE_Mod5_PropagatorMatingSpeedMultiplier      .Value := StrToFloat(stringReplace(s,'PropagatorMatingSpeedMultiplier='         ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('PropagatorMatingIntervalMultiplier'      ,s)=1)) then begin FSE_Mod5_PropagatorMatingIntervalMultiplier   .Value := StrToFloat(stringReplace(s,'PropagatorMatingIntervalMultiplier='      ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('GrinderScaleMultiplier'                  ,s)=1)) then begin FSE_Mod5_GrinderScaleMultiplier               .Value := StrToFloat(stringReplace(s,'GrinderScaleMultiplier='                  ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('IndustrialForgeScaleMultiplier'          ,s)=1)) then begin FSE_Mod5_IndustrialForgeScaleMultiplier       .Value := StrToFloat(stringReplace(s,'IndustrialForgeScaleMultiplier='          ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('ReplicatorScaleMultiplier'               ,s)=1)) then begin FSE_Mod5_ReplicatorScaleMultiplier            .Value := StrToFloat(stringReplace(s,'ReplicatorScaleMultiplier='               ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('GrinderCraftingSpeed'                    ,s)=1)) then begin SE_Mod5_GrinderCraftingSpeed                  .Value := StrToInt  (stringReplace(s,'GrinderCraftingSpeed='                    ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('IndustrialForgeCraftingSpeed'            ,s)=1)) then begin SE_Mod5_IndustrialForgeCraftingSpeed          .Value := StrToInt  (stringReplace(s,'IndustrialForgeCraftingSpeed='            ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('ReplicatorCraftingSpeed'                 ,s)=1)) then begin SE_Mod5_ReplicatorCraftingSpeed               .Value := StrToInt  (stringReplace(s,'ReplicatorCraftingSpeed='                 ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('FridgeCraftingSpeed'                     ,s)=1)) then begin SE_Mod5_FridgeCraftingSpeed                   .Value := StrToInt  (stringReplace(s,'FridgeCraftingSpeed='                     ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('PreservingBinCraftingSpeed'              ,s)=1)) then begin SE_Mod5_PreservingBinCraftingSpeed            .Value := StrToInt  (stringReplace(s,'PreservingBinCraftingSpeed='              ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('FabricatorCraftingSpeed'                 ,s)=1)) then begin SE_Mod5_FabricatorCraftingSpeed               .Value := StrToInt  (stringReplace(s,'FabricatorCraftingSpeed='                 ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('ResourcePullRangeInFoundations'          ,s)=1)) then begin SE_Mod5_ResourcePullRangeInFoundations        .Value := StrToInt  (stringReplace(s,'ResourcePullRangeInFoundations='          ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('BeeHiveWateringRangeInFoundations'       ,s)=1)) then begin SE_Mod5_BeeHiveWateringRangeInFoundations     .Value := StrToInt  (stringReplace(s,'BeeHiveWateringRangeInFoundations='       ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('MaxMutatorRangeInFoundations'            ,s)=1)) then begin SE_Mod5_MaxMutatorRangeInFoundations          .Value := StrToInt  (stringReplace(s,'MaxMutatorRangeInFoundations='            ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('MaxPowerRangeInFoundations'              ,s)=1)) then begin SE_Mod5_MaxPowerRangeInFoundations            .Value := StrToInt  (stringReplace(s,'MaxPowerRangeInFoundations='              ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('GardenerRangeInFoundations'              ,s)=1)) then begin SE_Mod5_GardenerRangeInFoundations            .Value := StrToInt  (stringReplace(s,'GardenerRangeInFoundations='              ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('FarmerRangeInFoundations'                ,s)=1)) then begin SE_Mod5_FarmerRangeInFoundations              .Value := StrToInt  (stringReplace(s,'FarmerRangeInFoundations='                ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('NannyRangeInFoundations'                 ,s)=1)) then begin SE_Mod5_NannyRangeInFoundations               .Value := StrToInt  (stringReplace(s,'NannyRangeInFoundations='                 ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_Mod5)and(pos('MutatorPulseCost'                        ,s)=1)) then begin Edit_Mod5_MutatorPulseCost                     .Text :=            stringReplace(s,'MutatorPulseCost='                        ,'',[rfReplaceAll, rfIgnoreCase]);
        end else if ((sec=cSec_Mod5)and(pos('MutatorPulseCooldowns'                   ,s)=1)) then begin Edit_Mod5_MutatorPulseCooldowns                .Text :=            stringReplace(s,'MutatorPulseCooldowns='                   ,'',[rfReplaceAll, rfIgnoreCase]);
        end else if ((sec=cSec_Mod5)and(pos('MutatorDinoBlacklist'                    ,s)=1)) then begin Edit_Mod5_MutatorDinoBlacklist                 .Text :=            stringReplace(s,'MutatorDinoBlacklist='                    ,'',[rfReplaceAll, rfIgnoreCase]);
        end else if ((sec=cSec_Mod5)and(pos('PullResourceAdditions'                   ,s)=1)) then begin Edit_Mod5_PullResourceAdditions                .Text :=            stringReplace(s,'PullResourceAdditions='                   ,'',[rfReplaceAll, rfIgnoreCase]);
        end else if ((sec=cSec_Mod5)and(pos('PullResourceRemovals'                    ,s)=1)) then begin Edit_Mod5_PullResourceRemovals                 .Text :=            stringReplace(s,'PullResourceRemovals='                    ,'',[rfReplaceAll, rfIgnoreCase]);
        end else if ((sec=cSec_Mod5)and(pos('AdvTransferItemBlacklist'                ,s)=1)) then begin Edit_Mod5_AdvTransferItemBlacklist             .Text :=            stringReplace(s,'AdvTransferItemBlacklist='                ,'',[rfReplaceAll, rfIgnoreCase]);
        end else if ((sec=cSec_Mod5)and(pos('QoLPlusEngramWhitelist'                  ,s)=1)) then begin Edit_Mod5_QoLPlusEngramWhitelist               .Text :=            stringReplace(s,'QoLPlusEngramWhitelist='                  ,'',[rfReplaceAll, rfIgnoreCase]);
        end else if ((sec=cSec_Mod5)and(pos('OmniToolBlacklist'                       ,s)=1)) then begin Edit_Mod5_OmniToolBlacklist                    .Text :=            stringReplace(s,'OmniToolBlacklist='                       ,'',[rfReplaceAll, rfIgnoreCase]);
        end else if ((sec=cSec_Mod5)and(pos('MultiToolBlacklist'                      ,s)=1)) then begin Edit_Mod5_MultiToolBlacklist                   .Text :=            stringReplace(s,'MultiToolBlacklist='                      ,'',[rfReplaceAll, rfIgnoreCase]);
        end else if ((sec=cSec_Mod5)and(pos('PropagatorDinoBlacklist'                 ,s)=1)) then begin Edit_Mod5_PropagatorDinoBlacklist              .Text :=            stringReplace(s,'PropagatorDinoBlacklist='                 ,'',[rfReplaceAll, rfIgnoreCase]);
        end else if ((sec=cSec_Mod5)and(pos('PropagatorFuelClass'                     ,s)=1)) then begin Edit_Mod5_PropagatorFuelClass                  .Text :=            stringReplace(s,'PropagatorFuelClass='                     ,'',[rfReplaceAll, rfIgnoreCase]);
        end else if ((sec=cSec_Mod5)and(pos('PropagatorModCostItemClass'              ,s)=1)) then begin Edit_Mod5_PropagatorModCostItemClass           .Text :=            stringReplace(s,'PropagatorModCostItemClass='              ,'',[rfReplaceAll, rfIgnoreCase]);

        end else begin
          if (pos('['                  ,s)=1) then sec := s;
          if (pos('[Cryopods]'         ,s)=1) then ChB_Mod1_Enabled.Checked := True;
          if (pos('[SuperSpyglassPlus]',s)=1) then ChB_Mod2_Enabled.Checked := True;
          if (pos('[DerDinoFinder]'    ,s)=1) then ChB_Mod3_Enabled.Checked := True;
          if (pos('[QoLPlus]'          ,s)=1) then ChB_Mod5_Enabled.Checked := True;
          if ASEMode then
          begin
            if (pos('ActiveTotalConversion',s)<>1) and
               (pos('DestroyUnconnectedWaterPipes',s)<>1) and
               (pos('AllowedCheatersURL',s)<>1) and
               (pos('MaxPlayers',s)<>1) then
            begin
              Memo_GameUserSettings_Append.Lines.Add(s);
            end;
          end else begin
            Memo_GameUserSettings_Append.Lines.Add(s);
          end;
        end;
      except
      end;
    end;

    s := '';
    sl.Clear;
    if (FileExists(GSIniPath)) then sl.LoadFromFile(GSIniPath);
    for i := 0 to sl.Count -1 do
    begin
      try
        s := sl.Strings[i];

        // [/Script/ShooterGame.ShooterGameMode]
        if          ((sec=cSec_ShGM)and(pos('BabyCuddleGracePeriodMultiplier'            ,s)=1)) then begin FSE_BabyCuddleGracePeriodMultiplier              .Value := StrToFloat(stringReplace(s,'BabyCuddleGracePeriodMultiplier='            ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('BabyCuddleIntervalMultiplier'               ,s)=1)) then begin FSE_BabyCuddleIntervalMultiplier                 .Value := StrToFloat(stringReplace(s,'BabyCuddleIntervalMultiplier='               ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('BabyCuddleLoseImprintQualitySpeedMultiplier',s)=1)) then begin FSE_BabyCuddleLoseImprintQualitySpeedMultiplier  .Value := StrToFloat(stringReplace(s,'BabyCuddleLoseImprintQualitySpeedMultiplier=','',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('BabyFoodConsumptionSpeedMultiplier'         ,s)=1)) then begin FSE_BabyFoodConsumptionSpeedMultiplier           .Value := StrToFloat(stringReplace(s,'BabyFoodConsumptionSpeedMultiplier='         ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('BabyImprintAmountMultiplier'                ,s)=1)) then begin FSE_BabyImprintAmountMultiplier                  .Value := StrToFloat(stringReplace(s,'BabyImprintAmountMultiplier='                ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('BabyImprintingStatScaleMultiplier'          ,s)=1)) then begin FSE_BabyImprintingStatScaleMultiplier            .Value := StrToFloat(stringReplace(s,'BabyImprintingStatScaleMultiplier='          ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('BabyMatureSpeedMultiplier'                  ,s)=1)) then begin FSE_BabyMatureSpeedMultiplier                    .Value := StrToFloat(stringReplace(s,'BabyMatureSpeedMultiplier='                  ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('EggHatchSpeedMultiplier'                    ,s)=1)) then begin FSE_EggHatchSpeedMultiplier                      .Value := StrToFloat(stringReplace(s,'EggHatchSpeedMultiplier='                    ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('LayEggIntervalMultiplier'                   ,s)=1)) then begin FSE_LayEggIntervalMultiplier                     .Value := StrToFloat(stringReplace(s,'LayEggIntervalMultiplier='                   ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('bAllowUnlimitedRespecs'                     ,s)=1)) then begin ChB_bAllowUnlimitedRespecs                     .Checked := StrToBool (stringReplace(s,'bAllowUnlimitedRespecs='                     ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('bDisableFriendlyFire'                       ,s)=1)) then begin ChB_bDisableFriendlyFire                       .Checked := StrToBool (stringReplace(s,'bDisableFriendlyFire='                       ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('bPvEDisableFriendlyFire'                    ,s)=1)) then begin ChB_bPvEDisableFriendlyFire                    .Checked := StrToBool (stringReplace(s,'bPvEDisableFriendlyFire='                    ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('bUseSingleplayerSettings'                   ,s)=1)) then begin ChB_bUseSingleplayerSettings                   .Checked := StrToBool (stringReplace(s,'bUseSingleplayerSettings='                   ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('CraftingSkillBonusMultiplier'               ,s)=1)) then begin FSE_CraftingSkillBonusMultiplier                 .Value := StrToFloat(stringReplace(s,'CraftingSkillBonusMultiplier='               ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('CraftXPMultiplier'                          ,s)=1)) then begin FSE_CraftXPMultiplier                            .Value := StrToFloat(stringReplace(s,'CraftXPMultiplier='                          ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('CropDecaySpeedMultiplier'                   ,s)=1)) then begin FSE_CropDecaySpeedMultiplier                     .Value := StrToFloat(stringReplace(s,'CropDecaySpeedMultiplier='                   ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('CropGrowthSpeedMultiplier'                  ,s)=1)) then begin FSE_CropGrowthSpeedMultiplier                    .Value := StrToFloat(stringReplace(s,'CropGrowthSpeedMultiplier='                  ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('CustomRecipeEffectivenessMultiplier'        ,s)=1)) then begin FSE_CustomRecipeEffectivenessMultiplier          .Value := StrToFloat(stringReplace(s,'CustomRecipeEffectivenessMultiplier='        ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('CustomRecipeSkillMultiplier'                ,s)=1)) then begin FSE_CustomRecipeSkillMultiplier                  .Value := StrToFloat(stringReplace(s,'CustomRecipeSkillMultiplier='                ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('DestroyTamesOverLevelClamp'                 ,s)=1)) then begin SE_DestroyTamesOverLevelClamp                    .Value := StrToInt  (stringReplace(s,'DestroyTamesOverLevelClamp='                 ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('GlobalItemDecompositionTimeMultiplier'      ,s)=1)) then begin FSE_GlobalItemDecompositionTimeMultiplier        .Value := StrToFloat(stringReplace(s,'GlobalItemDecompositionTimeMultiplier='      ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('GlobalSpoilingTimeMultiplier'               ,s)=1)) then begin FSE_GlobalSpoilingTimeMultiplier                 .Value := StrToFloat(stringReplace(s,'GlobalSpoilingTimeMultiplier='               ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('GenericXPMultiplier'                        ,s)=1)) then begin FSE_GenericXPMultiplier                          .Value := StrToFloat(stringReplace(s,'GenericXPMultiplier='                        ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('HarvestXPMultiplier'                        ,s)=1)) then begin FSE_HarvestXPMultiplier                          .Value := StrToFloat(stringReplace(s,'HarvestXPMultiplier='                        ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('KillXPMultiplier'                           ,s)=1)) then begin FSE_KillXPMultiplier                             .Value := StrToFloat(stringReplace(s,'KillXPMultiplier='                           ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('SpecialXPMultiplier'                        ,s)=1)) then begin FSE_SpecialXPMultiplier                          .Value := StrToFloat(stringReplace(s,'SpecialXPMultiplier='                        ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('ExplorerNoteXPMultiplier'                   ,s)=1)) then begin FSE_ExplorerNoteXPMultiplier                     .Value := StrToFloat(stringReplace(s,'ExplorerNoteXPMultiplier='                   ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('BossKillXPMultiplier'                       ,s)=1)) then begin FSE_BossKillXPMultiplier                         .Value := StrToFloat(stringReplace(s,'BossKillXPMultiplier='                       ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('CaveKillXPMultiplier'                       ,s)=1)) then begin FSE_CaveKillXPMultiplier                         .Value := StrToFloat(stringReplace(s,'CaveKillXPMultiplier='                       ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('WildKillXPMultiplier'                       ,s)=1)) then begin FSE_WildKillXPMultiplier                         .Value := StrToFloat(stringReplace(s,'WildKillXPMultiplier='                       ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('TamedKillXPMultiplier'                      ,s)=1)) then begin FSE_TamedKillXPMultiplier                        .Value := StrToFloat(stringReplace(s,'TamedKillXPMultiplier='                      ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('UnclaimedKillXPMultiplier'                  ,s)=1)) then begin FSE_UnclaimedKillXPMultiplier                    .Value := StrToFloat(stringReplace(s,'UnclaimedKillXPMultiplier='                  ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('AlphaKillXPMultiplier'                      ,s)=1)) then begin FSE_AlphaKillXPMultiplier                        .Value := StrToFloat(stringReplace(s,'AlphaKillXPMultiplier='                      ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PoopIntervalMultiplier'                     ,s)=1)) then begin FSE_PoopIntervalMultiplier                       .Value := StrToFloat(stringReplace(s,'PoopIntervalMultiplier='                     ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PlayerHarvestingDamageMultiplier'           ,s)=1)) then begin FSE_PlayerHarvestingDamageMultiplier             .Value := StrToFloat(stringReplace(s,'PlayerHarvestingDamageMultiplier='           ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('ResourceNoReplenishRadiusPlayers'           ,s)=1)) then begin FSE_ResourceNoReplenishRadiusPlayers             .Value := StrToFloat(stringReplace(s,'ResourceNoReplenishRadiusPlayers='           ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('ResourceNoReplenishRadiusStructures'        ,s)=1)) then begin FSE_ResourceNoReplenishRadiusStructures          .Value := StrToFloat(stringReplace(s,'ResourceNoReplenishRadiusStructures='        ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('DinoHarvestingDamageMultiplier'             ,s)=1)) then begin FSE_DinoHarvestingDamageMultiplier               .Value := StrToFloat(stringReplace(s,'DinoHarvestingDamageMultiplier='             ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('DinoTurretDamageMultiplier'                 ,s)=1)) then begin FSE_DinoTurretDamageMultiplier                   .Value := StrToFloat(stringReplace(s,'DinoTurretDamageMultiplier='                 ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('StructureDamageRepairCooldown'              ,s)=1)) then begin SE_StructureDamageRepairCooldown                 .Value := StrToFloat(stringReplace(s,'StructureDamageRepairCooldown='              ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('bDisableStructurePlacementCollision'        ,s)=1)) then begin ChB_bDisableStructurePlacementCollision        .Checked := StrToBool (stringReplace(s,'bDisableStructurePlacementCollision='        ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('bIgnoreStructuresPreventionVolumes'         ,s)=1)) then begin ChB_bIgnoreStructuresPreventionVolumes         .Checked := StrToBool (stringReplace(s,'bIgnoreStructuresPreventionVolumes='         ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('bUseCorpseLocator'                          ,s)=1)) then begin ChB_bUseCorpseLocator                          .Checked := StrToBool (stringReplace(s,'bUseCorpseLocator='                          ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('bAllowSpeedLeveling'                        ,s)=1)) then begin ChB_bAllowSpeedLeveling                        .Checked := StrToBool (stringReplace(s,'bAllowSpeedLeveling='                        ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('bAllowFlyerSpeedLeveling'                   ,s)=1)) then begin ChB_bAllowFlyerSpeedLeveling                   .Checked := StrToBool (stringReplace(s,'bAllowFlyerSpeedLeveling='                   ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('bAllowPlatformSaddleMultiFloors'            ,s)=1)) then begin ChB_bAllowPlatformSaddleMultiFloors            .Checked := StrToBool (stringReplace(s,'bAllowPlatformSaddleMultiFloors='            ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('MaxDifficulty'                              ,s)=1)) then begin ChB_MaxDifficulty                              .Checked := StrToBool (stringReplace(s,'MaxDifficulty='                              ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('bShowCreativeMode'                          ,s)=1)) then begin ChB_bShowCreativeMode                          .Checked := StrToBool (stringReplace(s,'bShowCreativeMode='                          ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('bDisableLootCrates'                         ,s)=1)) then begin ChB_bDisableLootCrates                         .Checked := StrToBool (stringReplace(s,'bDisableLootCrates='                         ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('bAutoPvETimer'                              ,s)=1)) then begin ChB_bAutoPvETimer                              .Checked := StrToBool (stringReplace(s,'bAutoPvETimer='                              ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('AutoPvEStartTimeSeconds'                    ,s)=1)) then begin SE_AutoPvEStartTimeSeconds                       .Value := StrToInt  (stringReplace(s,'AutoPvEStartTimeSeconds='                    ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('AutoPvEStopTimeSeconds'                     ,s)=1)) then begin SE_AutoPvEStopTimeSeconds                        .Value := StrToInt  (stringReplace(s,'AutoPvEStopTimeSeconds='                     ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('bAutoPvEUseSystemTime'                      ,s)=1)) then begin ChB_bAutoPvEUseSystemTime                      .Checked := StrToBool (stringReplace(s,'bAutoPvEUseSystemTime='                      ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('bPvEAllowTribeWar'                          ,s)=1)) then begin ChB_bPvEAllowTribeWar                          .Checked := StrToBool (stringReplace(s,'bPvEAllowTribeWar='                          ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('bPvEAllowTribeWarCancel'                    ,s)=1)) then begin ChB_bPvEAllowTribeWarCancel                    .Checked := StrToBool (stringReplace(s,'bPvEAllowTribeWarCancel='                    ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('bIncreasePvPRespawnInterval'                ,s)=1)) then begin ChB_bIncreasePvPRespawnInterval                .Checked := StrToBool (stringReplace(s,'bIncreasePvPRespawnInterval='                ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('IncreasePvPRespawnIntervalCheckPeriod'      ,s)=1)) then begin FSE_IncreasePvPRespawnIntervalCheckPeriod        .Value := StrToFloat(stringReplace(s,'IncreasePvPRespawnIntervalCheckPeriod='      ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('IncreasePvPRespawnIntervalMultiplier'       ,s)=1)) then begin FSE_IncreasePvPRespawnIntervalMultiplier         .Value := StrToFloat(stringReplace(s,'IncreasePvPRespawnIntervalMultiplier='       ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('IncreasePvPRespawnIntervalBaseAmount'       ,s)=1)) then begin FSE_IncreasePvPRespawnIntervalBaseAmount         .Value := StrToFloat(stringReplace(s,'IncreasePvPRespawnIntervalBaseAmount='       ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PvPZoneStructureDamageMultiplier'           ,s)=1)) then begin SE_PvPZoneStructureDamageMultiplier              .Value := StrToInt  (stringReplace(s,'PvPZoneStructureDamageMultiplier='           ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('GlobalCorpseDecompositionTimeMultiplier'    ,s)=1)) then begin FSE_GlobalCorpseDecompositionTimeMultiplier      .Value := StrToFloat(stringReplace(s,'GlobalCorpseDecompositionTimeMultiplier='    ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('MatingIntervalMultiplier'                   ,s)=1)) then begin FSE_MatingIntervalMultiplier                     .Value := StrToFloat(stringReplace(s,'MatingIntervalMultiplier='                   ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('MaxNumberOfPlayersInTribe'                  ,s)=1)) then begin SE_MaxNumberOfPlayersInTribe                     .Value := StrToInt  (stringReplace(s,'MaxNumberOfPlayersInTribe='                  ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('OverrideMaxExperiencePointsPlayer'          ,s)=1)) then begin SE_OverrideMaxExperiencePointsPlayer             .Value := StrToInt  (stringReplace(s,'OverrideMaxExperiencePointsPlayer='          ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('LimitNonPlayerDroppedItemsCount'            ,s)=1)) then begin SE_LimitNonPlayerDroppedItemsCount               .Value := StrToInt  (stringReplace(s,'LimitNonPlayerDroppedItemsCount='            ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('LimitNonPlayerDroppedItemsRange'            ,s)=1)) then begin SE_LimitNonPlayerDroppedItemsRange               .Value := StrToInt  (stringReplace(s,'LimitNonPlayerDroppedItemsRange='            ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('OverrideMaxExperiencePointsDino'            ,s)=1)) then begin SE_OverrideMaxExperiencePointsDino               .Value := StrToInt  (stringReplace(s,'OverrideMaxExperiencePointsDino='            ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('bFlyerPlatformAllowUnalignedDinoBasing'     ,s)=1)) then begin ChB_bFlyerPlatformAllowUnalignedDinoBasing     .Checked := StrToBool (stringReplace(s,'bFlyerPlatformAllowUnalignedDinoBasing='     ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('bPassiveDefensesDamageRiderlessDinos'       ,s)=1)) then begin ChB_bPassiveDefensesDamageRiderlessDinos       .Checked := StrToBool (stringReplace(s,'bPassiveDefensesDamageRiderlessDinos='       ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('SupplyCrateLootQualityMultiplier'           ,s)=1)) then begin FSE_SupplyCrateLootQualityMultiplier             .Value := StrToFloat(stringReplace(s,'SupplyCrateLootQualityMultiplier='           ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('FishingLootQualityMultiplier'               ,s)=1)) then begin FSE_FishingLootQualityMultiplier                 .Value := StrToFloat(stringReplace(s,'FishingLootQualityMultiplier='               ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('BaseTemperatureMultiplier'                  ,s)=1)) then begin FSE_BaseTemperatureMultiplier                    .Value := StrToFloat(stringReplace(s,'BaseTemperatureMultiplier='                  ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('FuelConsumptionIntervalMultiplier'          ,s)=1)) then begin FSE_FuelConsumptionIntervalMultiplier            .Value := StrToFloat(stringReplace(s,'FuelConsumptionIntervalMultiplier='          ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('MaxFallSpeedMultiplier'                     ,s)=1)) then begin FSE_MaxFallSpeedMultiplier                       .Value := StrToFloat(stringReplace(s,'MaxFallSpeedMultiplier='                     ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('UseCorpseLifeSpanMultiplier'                ,s)=1)) then begin FSE_UseCorpseLifeSpanMultiplier                  .Value := StrToFloat(stringReplace(s,'UseCorpseLifeSpanMultiplier='                ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('TamedDinoCharacterFoodDrainMultiplier'      ,s)=1)) then begin FSE_TamedDinoCharacterFoodDrainMultiplier        .Value := StrToFloat(stringReplace(s,'TamedDinoCharacterFoodDrainMultiplier='      ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('TamedDinoTorporDrainMultiplier'             ,s)=1)) then begin FSE_TamedDinoTorporDrainMultiplier               .Value := StrToFloat(stringReplace(s,'TamedDinoTorporDrainMultiplier='             ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('MatingSpeedMultiplier'                      ,s)=1)) then begin FSE_MatingSpeedMultiplier                        .Value := StrToFloat(stringReplace(s,'MatingSpeedMultiplier='                      ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PassiveTameIntervalMultiplier'              ,s)=1)) then begin FSE_PassiveTameIntervalMultiplier                .Value := StrToFloat(stringReplace(s,'PassiveTameIntervalMultiplier='              ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('WildDinoCharacterFoodDrainMultiplier'       ,s)=1)) then begin FSE_WildDinoCharacterFoodDrainMultiplier         .Value := StrToFloat(stringReplace(s,'WildDinoCharacterFoodDrainMultiplier='       ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('WildDinoTorporDrainMultiplier'              ,s)=1)) then begin FSE_WildDinoTorporDrainMultiplier                .Value := StrToFloat(stringReplace(s,'WildDinoTorporDrainMultiplier='              ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('bUseDinoLevelUpAnimations'                  ,s)=1)) then begin ChB_bUseDinoLevelUpAnimations                  .Checked := StrToBool (stringReplace(s,'bUseDinoLevelUpAnimations='                  ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('bDisableDinoRiding'                         ,s)=1)) then begin ChB_bDisableDinoRiding                         .Checked := StrToBool (stringReplace(s,'bDisableDinoRiding='                         ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('bDisableDinoTaming'                         ,s)=1)) then begin ChB_bDisableDinoTaming                         .Checked := StrToBool (stringReplace(s,'bDisableDinoTaming='                         ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('bDisableDinoBreeding'                       ,s)=1)) then begin ChB_bDisableDinoBreeding                       .Checked := StrToBool (stringReplace(s,'bDisableDinoBreeding='                       ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('bAutoUnlockAllEngrams'                      ,s)=1)) then begin ChB_bAutoUnlockAllEngrams                      .Checked := StrToBool (stringReplace(s,'bAutoUnlockAllEngrams='                      ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('bDisablePhotoMode'                          ,s)=1)) then begin ChB_bDisablePhotoMode                          .Checked := StrToBool (stringReplace(s,'bDisablePhotoMode='                          ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('MaxHexagonsPerCharacter'                    ,s)=1)) then begin SE_MaxHexagonsPerCharacter                       .Value := StrToInt  (stringReplace(s,'MaxHexagonsPerCharacter='                    ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('BaseHexagonRewardMultiplier'                ,s)=1)) then begin FSE_BaseHexagonRewardMultiplier                  .Value := StrToFloat(stringReplace(s,'BaseHexagonRewardMultiplier='                ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('HexagonCostMultiplier'                      ,s)=1)) then begin FSE_HexagonCostMultiplier                        .Value := StrToFloat(stringReplace(s,'HexagonCostMultiplier='                      ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('bHardLimitTurretsInRange'                   ,s)=1)) then begin ChB_bHardLimitTurretsInRange                   .Checked := StrToBool (stringReplace(s,'bHardLimitTurretsInRange='                   ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('bLimitTurretsInRange'                       ,s)=1)) then begin ChB_bLimitTurretsInRange                       .Checked := StrToBool (stringReplace(s,'bLimitTurretsInRange='                       ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('LimitTurretsNum'                            ,s)=1)) then begin SE_LimitTurretsNum                               .Value := StrToInt  (stringReplace(s,'LimitTurretsNum='                            ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('LimitTurretsRange'                          ,s)=1)) then begin FSE_LimitTurretsRange                            .Value := StrToFloat(stringReplace(s,'LimitTurretsRange='                          ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('bOnlyAllowSpecifiedEngrams'                 ,s)=1)) then begin ChB_OnlyAllowSpecifiedEngrams                  .Checked := StrToBool (stringReplace(s,'bOnlyAllowSpecifiedEngrams='                 ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_Player[0]'          ,s)=1)) then begin FSE_PerLevelStatsMultiplier_Player0              .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_Player[0]='          ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_Player[1]'          ,s)=1)) then begin FSE_PerLevelStatsMultiplier_Player1              .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_Player[1]='          ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_Player[2]'          ,s)=1)) then begin FSE_PerLevelStatsMultiplier_Player2              .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_Player[2]='          ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_Player[3]'          ,s)=1)) then begin FSE_PerLevelStatsMultiplier_Player3              .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_Player[3]='          ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_Player[4]'          ,s)=1)) then begin FSE_PerLevelStatsMultiplier_Player4              .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_Player[4]='          ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_Player[5]'          ,s)=1)) then begin FSE_PerLevelStatsMultiplier_Player5              .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_Player[5]='          ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_Player[6]'          ,s)=1)) then begin FSE_PerLevelStatsMultiplier_Player6              .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_Player[6]='          ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_Player[7]'          ,s)=1)) then begin FSE_PerLevelStatsMultiplier_Player7              .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_Player[7]='          ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_Player[8]'          ,s)=1)) then begin FSE_PerLevelStatsMultiplier_Player8              .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_Player[8]='          ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_Player[9]'          ,s)=1)) then begin FSE_PerLevelStatsMultiplier_Player9              .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_Player[9]='          ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_Player[10]'         ,s)=1)) then begin FSE_PerLevelStatsMultiplier_Player10             .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_Player[10]='         ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_Player[11]'         ,s)=1)) then begin FSE_PerLevelStatsMultiplier_Player11             .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_Player[11]='         ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoTamed[0]'       ,s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoTamed0           .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoTamed[0]='       ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoTamed[1]'       ,s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoTamed1           .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoTamed[1]='       ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoTamed[2]'       ,s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoTamed2           .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoTamed[2]='       ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoTamed[3]'       ,s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoTamed3           .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoTamed[3]='       ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoTamed[4]'       ,s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoTamed4           .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoTamed[4]='       ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoTamed[5]'       ,s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoTamed5           .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoTamed[5]='       ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoTamed[6]'       ,s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoTamed6           .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoTamed[6]='       ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoTamed[7]'       ,s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoTamed7           .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoTamed[7]='       ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoTamed[8]'       ,s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoTamed8           .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoTamed[8]='       ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoTamed[9]'       ,s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoTamed9           .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoTamed[9]='       ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoTamed[10]'      ,s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoTamed10          .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoTamed[10]='      ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoTamed_Add[0]'   ,s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoTamed_Add0       .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoTamed_Add[0]='   ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoTamed_Add[1]'   ,s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoTamed_Add1       .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoTamed_Add[1]='   ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoTamed_Add[2]'   ,s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoTamed_Add2       .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoTamed_Add[2]='   ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoTamed_Add[3]'   ,s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoTamed_Add3       .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoTamed_Add[3]='   ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoTamed_Add[4]'   ,s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoTamed_Add4       .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoTamed_Add[4]='   ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoTamed_Add[5]'   ,s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoTamed_Add5       .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoTamed_Add[5]='   ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoTamed_Add[6]'   ,s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoTamed_Add6       .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoTamed_Add[6]='   ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoTamed_Add[7]'   ,s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoTamed_Add7       .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoTamed_Add[7]='   ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoTamed_Add[8]'   ,s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoTamed_Add8       .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoTamed_Add[8]='   ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoTamed_Add[9]'   ,s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoTamed_Add9       .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoTamed_Add[9]='   ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoTamed_Add[10]'  ,s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoTamed_Add10      .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoTamed_Add[10]='  ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoTamed_Affinity[0]' ,s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoTamed_Affinity0 .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoTamed_Affinity[0]=' ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoTamed_Affinity[1]' ,s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoTamed_Affinity1 .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoTamed_Affinity[1]=' ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoTamed_Affinity[2]' ,s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoTamed_Affinity2 .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoTamed_Affinity[2]=' ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoTamed_Affinity[3]' ,s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoTamed_Affinity3 .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoTamed_Affinity[3]=' ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoTamed_Affinity[4]' ,s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoTamed_Affinity4 .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoTamed_Affinity[4]=' ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoTamed_Affinity[5]' ,s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoTamed_Affinity5 .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoTamed_Affinity[5]=' ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoTamed_Affinity[6]' ,s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoTamed_Affinity6 .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoTamed_Affinity[6]=' ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoTamed_Affinity[7]' ,s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoTamed_Affinity7 .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoTamed_Affinity[7]=' ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoTamed_Affinity[8]' ,s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoTamed_Affinity8 .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoTamed_Affinity[8]=' ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoTamed_Affinity[9]' ,s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoTamed_Affinity9 .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoTamed_Affinity[9]=' ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoTamed_Affinity[10]',s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoTamed_Affinity10.Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoTamed_Affinity[10]=','',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoWild[0]'        ,s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoWild0            .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoWild[0]='        ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoWild[1]'        ,s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoWild1            .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoWild[1]='        ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoWild[2]'        ,s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoWild2            .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoWild[2]='        ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoWild[3]'        ,s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoWild3            .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoWild[3]='        ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoWild[4]'        ,s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoWild4            .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoWild[4]='        ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoWild[5]'        ,s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoWild5            .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoWild[5]='        ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoWild[6]'        ,s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoWild6            .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoWild[6]='        ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoWild[7]'        ,s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoWild7            .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoWild[7]='        ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoWild[8]'        ,s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoWild8            .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoWild[8]='        ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoWild[9]'        ,s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoWild9            .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoWild[9]='        ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PerLevelStatsMultiplier_DinoWild[10]'       ,s)=1)) then begin FSE_PerLevelStatsMultiplier_DinoWild10           .Value := StrToFloat(stringReplace(s,'PerLevelStatsMultiplier_DinoWild[10]='       ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PlayerBaseStatMultipliers[0]'               ,s)=1)) then begin FSE_PlayerBaseStatMultipliers0                   .Value := StrToFloat(stringReplace(s,'PlayerBaseStatMultipliers[0]='               ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PlayerBaseStatMultipliers[1]'               ,s)=1)) then begin FSE_PlayerBaseStatMultipliers1                   .Value := StrToFloat(stringReplace(s,'PlayerBaseStatMultipliers[1]='               ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PlayerBaseStatMultipliers[2]'               ,s)=1)) then begin FSE_PlayerBaseStatMultipliers2                   .Value := StrToFloat(stringReplace(s,'PlayerBaseStatMultipliers[2]='               ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PlayerBaseStatMultipliers[3]'               ,s)=1)) then begin FSE_PlayerBaseStatMultipliers3                   .Value := StrToFloat(stringReplace(s,'PlayerBaseStatMultipliers[3]='               ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PlayerBaseStatMultipliers[4]'               ,s)=1)) then begin FSE_PlayerBaseStatMultipliers4                   .Value := StrToFloat(stringReplace(s,'PlayerBaseStatMultipliers[4]='               ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PlayerBaseStatMultipliers[5]'               ,s)=1)) then begin FSE_PlayerBaseStatMultipliers5                   .Value := StrToFloat(stringReplace(s,'PlayerBaseStatMultipliers[5]='               ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PlayerBaseStatMultipliers[6]'               ,s)=1)) then begin FSE_PlayerBaseStatMultipliers6                   .Value := StrToFloat(stringReplace(s,'PlayerBaseStatMultipliers[6]='               ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PlayerBaseStatMultipliers[7]'               ,s)=1)) then begin FSE_PlayerBaseStatMultipliers7                   .Value := StrToFloat(stringReplace(s,'PlayerBaseStatMultipliers[7]='               ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PlayerBaseStatMultipliers[8]'               ,s)=1)) then begin FSE_PlayerBaseStatMultipliers8                   .Value := StrToFloat(stringReplace(s,'PlayerBaseStatMultipliers[8]='               ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PlayerBaseStatMultipliers[9]'               ,s)=1)) then begin FSE_PlayerBaseStatMultipliers9                   .Value := StrToFloat(stringReplace(s,'PlayerBaseStatMultipliers[9]='               ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PlayerBaseStatMultipliers[10]'              ,s)=1)) then begin FSE_PlayerBaseStatMultipliers10                  .Value := StrToFloat(stringReplace(s,'PlayerBaseStatMultipliers[10]='              ,'',[rfReplaceAll, rfIgnoreCase]));
        end else if ((sec=cSec_ShGM)and(pos('PlayerBaseStatMultipliers[11]'              ,s)=1)) then begin FSE_PlayerBaseStatMultipliers11                  .Value := StrToFloat(stringReplace(s,'PlayerBaseStatMultipliers[11]='              ,'',[rfReplaceAll, rfIgnoreCase]));

        end else begin
          if (pos('[',s)=1) then sec := s;
          Memo_GameIni_Append.Lines.Add(s);
        end;
      except
      end;
    end;
  finally
    sl.Free;
  end;
end;

procedure TAsaFrame.loadArgsFromBat(batFile:string);
var
  bOverride:boolean;
  sArgs,str:string;
  sl       :TStringList;
  i        :integer;
begin
  bOverride := false;
  sArgs     := '';

  if (batFile = '')          then exit;
  if not FileExists(batFile) then exit;

  bOverride := True;
  sArgs     := ExtractFileName(batFile);

  sl := TStringList.Create;
  try
    sl.LoadFromFile(batFile);

    for i := 0 to sl.Count -1 do
    begin
      str := sl[i];
      if (pos('arkascendedserver',ansilowercase(str)) =1) then
      begin
        sArgs := str;
      end;
    end;
  finally
    sl.Free;
  end;

  ChB_CMD_override.Checked:=bOverride;
  MM_Command_Override.Lines.Add(sArgs);
end;

procedure TAsaFrame.updateServerStatus;
begin
  new_updateServerStatus;
  exit;
end;

procedure TAsaFrame.new_updateServerStatus;
var
  sl  :TStringList;
  strm:TFileStream;
  i   :integer;
  str : String;
  isRunning :boolean;
  isBackup  :boolean;
  discord_hook : TDiscord_Webhook;
  iFileTime,iTergetTime:int64;

  function IsSteamCMDInstalled:boolean;
  begin
    if DisableSteamcmdSharing then
    begin
      result := FileExists(Edit_Install_Location_Val.Text+'\steamcmd\steamerrorreporter.exe');
    end else begin
      result := FileExists(ExtractFilePath(ParamStr0)+'steamcmd\steamerrorreporter.exe');
    end;
  end;

  procedure ChkServerVersion;
  var
    SteamACFPath:string;
    sOldBuildID:string;
    iOldBuildID: integer;
    i  :integer;
    sTemp :string;
  begin
    SteamACFPath := Edit_Install_Location_Val.Text+'\steamapps\appmanifest_2430930.acf';

    iOldBuildID := 0;
    if FileExists(SteamACFPath) then
    begin
      sl := TStringList.Create;
      try
        sl.LoadFromFile(SteamACFPath);
        for i := 0 to sl.Count-1 do
        begin
          sTemp := sl.Strings[i];
          if (Pos('"buildid"',sTemp)<>0) then
          begin
            sTemp := StringReplace(sTemp,'buildid','',[rfReplaceAll, rfIgnoreCase]);
            sTemp := StringReplace(sTemp,#09,'',[rfReplaceAll, rfIgnoreCase]);
            sTemp := StringReplace(sTemp,#20,'',[rfReplaceAll, rfIgnoreCase]);
            sTemp := StringReplace(sTemp,'"','',[rfReplaceAll, rfIgnoreCase]);
            sOldBuildID := sTemp;
            break;
          end;
        end;
      finally
        sl.Free;
      end;
    end;
    iOldBuildID := StrToIntDef(sOldBuildID,0);
    if (iOldBuildID < iNewBuildID) then Pnl_ServerUpdate_Focus.Visible:=true
                                   else Pnl_ServerUpdate_Focus.Visible:=false;
  end;

begin
  isBackup := false;
  iMemUseMB := 0;
  iUptime := 0;

  //No SteamCMD
  if (not IsSteamCMDInstalled) then
  begin
    CB_SrvStatus_Val.ItemIndex := 0;
    CB_SrvStatus_ValChange(CB_SrvStatus_Val);
    exit;
  end;

  ChkServerVersion;

  //No ServerPRG
  if (not FileExists(ExtractFileDir(Edit_Install_Location_Val.Text+'\')+'\ShooterGame\Binaries\Win64\ArkAscendedServer.exe')) then
  begin
    CB_SrvStatus_Val.ItemIndex := 1;
    CB_SrvStatus_ValChange(CB_SrvStatus_Val);
    exit;
  end;

  //No Config
  if (not FileExists(ExtractFileDir(Edit_Install_Location_Val.Text+'\')+'\ShooterGame\Saved\Config\WindowsServer\GameUserSettings.ini')) or
     (not FileExists(ExtractFileDir(Edit_Install_Location_Val.Text+'\')+'\ShooterGame\Saved\Config\WindowsServer\Game.ini')) then
  begin
    CB_SrvStatus_Val.ItemIndex := 2;
    CB_SrvStatus_ValChange(CB_SrvStatus_Val);
    exit;
  end;

  //OFFLINE
  if not(IsExeRunning(ExtractFileDir(Edit_Install_Location_Val.Text+'\')+'\ShooterGame\Binaries\Win64\ArkAscendedServer.exe')) then
  begin
    isFirstExecute := true;
    if (CB_SrvStatus_Val.ItemIndex > 3) then
    begin
      if (NotificationKind[0,2]) then
      begin
        discord_hook := TDiscord_Webhook.Create;
        try
          discord_hook.SetURL(DiscordAdmHookURL);
          discord_hook.SetSvrStoppedMessage(DiscordAdmHookName,Edit_Profile.Text,CB_MapName.Text);
          discord_hook.send;
        finally
          discord_hook.Free;
        end;
      end;
      if (NotificationKind[2,2]) then
      begin
        TrayIcon_ASASM.Visible:=true;
        TrayIcon_ASASM.BalloonTitle:=format('[%s]Server Stopped!',[TrayNotificationName]);
        TrayIcon_ASASM.BalloonHint :=format('Prof=%s : Map=%s',[Edit_Profile.Text,CB_MapName.Text]);
        TrayIcon_ASASM.ShowBalloonHint;
      end;
    end;

    if (not bManuallyStopping) and (ChB_AutoRestart.Checked) and (CB_SrvStatus_Val.ItemIndex > 4) then
    begin
      Lbl_Profile_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Profile_Status_09.Caption;
      Lbl_Profile_Status.Repaint;
      sLast_Profile_Status :=Form_MessageTrans.Lbl_Hidden_Profile_Status_09.Caption;
      iLast_Profile_Status_Time := DateTimeToUnix(now);
      SetProfileLog('Server Restart.');

      if (NotificationKind[0,3]) then
      begin
        discord_hook := TDiscord_Webhook.Create;
        try
          discord_hook.SetURL(DiscordAdmHookURL);
          discord_hook.SetSvrRestartingMessage(DiscordAdmHookName,Edit_Profile.Text,CB_MapName.Text);
          discord_hook.send;
        finally
          discord_hook.Free;
        end;
      end;

      if (NotificationKind[2,3]) then
      begin
        TrayIcon_ASASM.Visible:=true;
        TrayIcon_ASASM.BalloonTitle:=format('[%s][Crash]Server restarting...',[TrayNotificationName]);
        TrayIcon_ASASM.BalloonHint :=format('Prof=%s : Sess=%s',[Edit_Profile.Text,Edit_SessionName.Text]);
        TrayIcon_ASASM.ShowBalloonHint;
      end;
      StartServer;
    end else begin
      SetProfileLog('Server OFFLINE.');
      bManuallyStopping := false;
      if (CB_SrvStatus_Val.ItemIndex > 3) then
      begin
        if (ChB_AutoBackup.Checked) and (CB_SrvStatus_Val.ItemIndex = 5) then
        begin
          isBackup := true;
        end else begin
          Lbl_Profile_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Profile_Status_11.Caption;
          Lbl_Profile_Status.Repaint;
          sLast_Profile_Status :=Form_MessageTrans.Lbl_Hidden_Profile_Status_11.Caption;
          iLast_Profile_Status_Time := DateTimeToUnix(now);
        end;
      end;
    end;

    CB_SrvStatus_Val.ItemIndex := 3;
    CB_SrvStatus_ValChange(CB_SrvStatus_Val);
    if (isBackup) then
    begin
      while (BusyFlg) do
      begin
        sleep(200);
        application.ProcessMessages;
      end;
      Button_DataBK2Click(Button_DataBK2);
    end;
    Timer_GetVerInfo.Enabled:=false;
    GB_RCON_COMMAND.Enabled:=false;
    Pnl_RCON.Enabled:=True;
    GB_SvrCMD_COMMAND.Enabled:=false;
    Pnl_SvrCMD.Enabled:=True;
  end else begin
    isRunning := false;

    if (CB_SrvStatus_Val.ItemIndex = 4) then
    begin
      iTergetTime := DateTimeToUnix(Now()) -5;
      iFileTime   := DateTimeToUnix(FileAge(Edit_Install_Location_Val.Text+'\ShooterGame\Saved\Logs\ShooterGame.log')) -5;
      if (iTergetTime < iFileTime) then
      begin
        sl := TStringList.Create;
        strm := TFileStream.Create(Edit_Install_Location_Val.Text+'\ShooterGame\Saved\Logs\ShooterGame.log',fmOpenRead or fmShareDenyNone);
        try
          sl.Clear;
          sl.LoadFromStream(strm);
          strm.Free;

          for i := 0 to sl.Count-1 do
          begin
            str := sl.Strings[i];
            if (pos('advertising for join.',str)<>0) then
            begin
              isRunning := true;
              break;
            end;
          end;
        finally
          sl.Free;
        end;
      end;
    end;
    if (CB_SrvStatus_Val.ItemIndex = 5) then isRunning := true;

    if isRunning then
    begin
      //ONLINE
      if (CB_SrvStatus_Val.ItemIndex < 4) then
      begin
        iExecime := ProcessTimePast(ExtractFileDir(Edit_Install_Location_Val.Text+'\')+'\ShooterGame\Binaries\Win64\ArkAscendedServer.exe');
      end;
      if (CB_SrvStatus_Val.ItemIndex < 5) then
      begin
        Lbl_Profile_Status.Caption:=Form_MessageTrans.Lbl_Hidden_Profile_Status_12.Caption;
        Lbl_Profile_Status.Repaint;
        sLast_Profile_Status :=Form_MessageTrans.Lbl_Hidden_Profile_Status_12.Caption;
        iLast_Profile_Status_Time      := DateTimeToUnix(now);
        iLast_AutoDestroyWildDino_Time := DateTimeToUnix(now);
      end;

      if (CB_SrvStatus_Val.ItemIndex < 5) then
      begin
        if (NotificationKind[0,1]) then
        begin
          discord_hook := TDiscord_Webhook.Create;
          try
            discord_hook.SetURL(DiscordAdmHookURL);
            discord_hook.SetSvrOnlineMessage(DiscordAdmHookName,Edit_Profile.Text,CB_MapName.Text);
            discord_hook.send;
          finally
            discord_hook.Free;
          end;
        end;
        if (NotificationKind[2,1]) then
        begin
          TrayIcon_ASASM.Visible:=true;
          TrayIcon_ASASM.BalloonTitle:=format('[%s]Server ONLINE',[TrayNotificationName]);
          TrayIcon_ASASM.BalloonHint :=format('Prof=%s : Map=%s',[Edit_Profile.Text,CB_MapName.Text]);
          TrayIcon_ASASM.ShowBalloonHint;
        end;
      end;

      CB_SrvStatus_Val.ItemIndex := 5;
      CB_SrvStatus_ValChange(CB_SrvStatus_Val);
      Timer_GetVerInfo.Enabled:=true;
      if not bManuallyStopping then
      begin
        SetProfileLog('Server ONLINE.');
        bManuallyStarting := false;
      end;

      if CB_RCONEnabled.Checked then GB_RCON_COMMAND.Enabled:=true;
      Pnl_RCON.Enabled:=False;
      if (CB_SvrCMDEnabled.Checked) and (not ChB_USE_AsaApiLoader.Checked) then GB_SvrCMD_COMMAND.Enabled:=true
                                                                           else GB_SvrCMD_COMMAND.Enabled:=false;
      Pnl_SvrCMD.Enabled:=False;
    end else begin
      //Starting...
      if (CB_SrvStatus_Val.ItemIndex < 4) then
      begin
        iExecime := ProcessTimePast(ExtractFileDir(Edit_Install_Location_Val.Text+'\')+'\ShooterGame\Binaries\Win64\ArkAscendedServer.exe');
      end;
      CB_SrvStatus_Val.ItemIndex := 4;
      CB_SrvStatus_ValChange(CB_SrvStatus_Val);
      Timer_GetVerInfo.Enabled:=false;
      GB_RCON_COMMAND.Enabled:=false;
      Pnl_RCON.Enabled:=False;
      GB_SvrCMD_COMMAND.Enabled:=false;
      Pnl_SvrCMD.Enabled:=False;
    end;
  end;
  if ARKestra and (CB_SrvStatus_Val.ItemIndex >= 4) then
  begin
    iMemUseMB := ProcessMemoryMB(ExtractFileDir(Edit_Install_Location_Val.Text+'\')+'\ShooterGame\Binaries\Win64\ArkAscendedServer.exe');
    iCPUCurrUSE := ProcessTimeUSE(ExtractFileDir(Edit_Install_Location_Val.Text+'\')+'\ShooterGame\Binaries\Win64\ArkAscendedServer.exe');
    iCPUCurrTime:= DateTimeToUnix(now);
    if ((iCPUCurrTime - iCPULastTime)<>0) then fCPU_Use := (iCPUCurrUSE - iCPULastUSE) / (iCPUCurrTime - iCPULastTime);
    if (fCPU_Use < 0.0) then fCPU_Use := 0.0;
    iCPULastTime := iCPUCurrTime;
    iCPULastUSE  := iCPUCurrUSE;
    iUptime := DateTimeToUnix(LocalTimeToUniversal(now)) - iExecime;
    sUptime := format('%2.2dh%2.2dm%2.2ds',[iUptime div (60*60),iUptime mod (60*60) div 60,iUptime mod 60])
  end;
  if (CB_SrvStatus_Val.ItemIndex = 5) and (ChB_ASASM_AutoDestroyWildDinosSeconds.Checked) then
  begin
    if (SE_ASASM_AutoDestroyWildDinosSeconds.Value > 0) then
    begin
      if ((DateTimeToUnix(now) - iLast_AutoDestroyWildDino_Time) > SE_ASASM_AutoDestroyWildDinosSeconds.Value) then
      begin
        Memo_RCONLogs.Lines.Add('**[ASASM]AutoDestroyWildDinos**');
        RCON_COMAND_Click(Button_DestroyWildDinos);

        iLast_AutoDestroyWildDino_Time := DateTimeToUnix(now);
      end;
    end;
  end;
end;

procedure TAsaFrame.SetProfileLog(message:string);
var
  sTime   :string;
  sProfile:string;
  sSession:string;
begin
  if not ARKestra then exit;
  if (sLastlogMessage = message) then exit;
  sLastlogMessage := message;
  sTime := DateTimeToStr(Now);
  sProfile := Edit_Profile.Text;
  sSession := Edit_SessionName.Text;
  sl_ProfileLog.Add(format('%s[%s](%s):%s',[sTime,sProfile,sSession,message]));
end;

end.


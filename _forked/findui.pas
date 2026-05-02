unit findui;

{$mode objfpc}{$H+}

interface

uses
  MessageTrans,
  lcltype,
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TFind_ui }

  TFind_ui = class(TForm)
    Button_Find: TButton;
    Edit_Find: TEdit;
    procedure Button_FindClick(Sender: TObject);
    procedure Edit_FindKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    cnt :integer;
    beforfind:string;
    function SetAltFileTxt(beforeTxt:string):string;
    function SetFindTarget(sComponentName:string):string;
  public
    ARKestra :boolean;
    form:TForm;
    constructor create(AOwner: TComponent);override;
  end;

var
  sl :TStringList;
  Find_ui: TFind_ui;

implementation

uses
  ComCtrls,
  mainui_arkestra, mainui, frameui;

{$R *.lfm}

{ TFind_ui }

constructor TFind_ui.create(AOwner: TComponent);
begin
  inherited;

  cnt := 0;
  beforfind := '';
  ARKestra := false;
end;

function TFind_ui.SetAltFileTxt(beforeTxt:string):string;
begin
  result := beforeTxt;
  if (pos('baby'      ,result)<>0) then result := StringReplace(result,'baby'    ,'babies'    ,[rfReplaceAll]);
  if (pos('babies'    ,result)<>0) then result := StringReplace(result,'babies'  ,'baby'      ,[rfReplaceAll]);
  if (pos('赤ちゃん'  ,result)<>0) then result := StringReplace(result,'赤ちゃん','ベビー'    ,[rfReplaceAll]);
  if (pos('ベビー'    ,result)<>0) then result := StringReplace(result,'ベビー'  ,'赤ちゃん'  ,[rfReplaceAll]);
  if (pos('うんこ'    ,result)<>0) then result := StringReplace(result,'うんこ'  ,'排泄'      ,[rfReplaceAll]);
  if (pos('ウンコ'    ,result)<>0) then result := StringReplace(result,'ウンコ'  ,'排泄'      ,[rfReplaceAll]);
  if (pos('脱糞'      ,result)<>0) then result := StringReplace(result,'脱糞'    ,'排泄'      ,[rfReplaceAll]);
  if (pos('くそ'      ,result)<>0) then result := StringReplace(result,'くそ'    ,'排泄'      ,[rfReplaceAll]);
  if (pos('クソ'      ,result)<>0) then result := StringReplace(result,'クソ'    ,'排泄'      ,[rfReplaceAll]);
  if (pos('排便'      ,result)<>0) then result := StringReplace(result,'排便'    ,'排泄'      ,[rfReplaceAll]);
  if (pos('kuso'      ,result)<>0) then result := StringReplace(result,'kuso'    ,'排泄'      ,[rfReplaceAll]);
  if (pos('糞'        ,result)<>0) then result := StringReplace(result,'糞'      ,'排泄'      ,[rfReplaceAll]);
  if (pos('排泄間隔'  ,result)<>0) then result := StringReplace(result,'排泄間隔','排泄の間隔',[rfReplaceAll]);
  if (pos('レベル'    ,result)<>0) then result := 'OverrideOfficialDifficulty';
  if (pos('150'       ,result)<>0) then result := 'OverrideOfficialDifficulty';
  if (pos('テイム倍率',result)<>0) then result := 'TamingSpeedMultiplier';

end;

function TFind_ui.SetFindTarget(sComponentName:string):string;
begin
  result := sComponentName;
  result := StringReplace(result,'Edit_','',[rfReplaceAll]);
  result := StringReplace(result,'CB_','',[rfReplaceAll]);
  result := StringReplace(result,'ChB_','',[rfReplaceAll]);
  result := StringReplace(result,'SE_','',[rfReplaceAll]);
  result := StringReplace(result,'FSE_','',[rfReplaceAll]);
  result := StringReplace(result,'CG_','',[rfReplaceAll]);
  result := StringReplace(result,'Mod4_AA_','',[rfReplaceAll]);
  result := StringReplace(result,'Mod1_','',[rfReplaceAll]);
  result := StringReplace(result,'Mod2_','',[rfReplaceAll]);
  result := StringReplace(result,'Mod3_','',[rfReplaceAll]);
  result := StringReplace(result,'Mod5_','',[rfReplaceAll]);
  result := AnsiLowerCase(result);
end;

procedure TFind_ui.Button_FindClick(Sender: TObject);
var
  compo :TComponent;
  frame :TAsaFrame;
  page  :TPageControl;
  winctl :TWinControl;
  winctl2 :TWinControl;
  i :integer;
  sCompo :string;
  str1,str2:string;
  s :string;
  sl2 :TStringList;
  sAltFindText :string;
begin
  if (Edit_Find.Text='') then exit;
  if (Edit_Find.Text<>beforfind) then
  begin
    cnt := 0;
    beforfind := Edit_Find.Text;
  end;

  // 特例検索文字列
  sAltFindText := SetAltFileTxt(Edit_Find.Text);

  if ARKestra then
  begin
    if (TARKestra_ui(form).ServerPage.PageCount=0) then exit;
    compo := TARKestra_ui(form).ServerPage.ActivePage.FindComponent('ASAServer'+inttostr(TARKestra_ui(form).ServerPage.ActivePageIndex));
  end else begin
    if (TAsa_ui(form).ServerPage.PageCount=0) then exit;
    compo := TAsa_ui(form).ServerPage.ActivePage.FindComponent('ASAServer'+inttostr(TAsa_ui(form).ServerPage.ActivePageIndex));
  end;
  if (compo = nil) then
  begin
    showmessage('bug:compo = nil');
    exit;
  end;
  frame := TAsaFrame(compo);
  if (frame = nil) then
  begin
    showmessage('bug:frame = nil');
    exit;
  end;
  page := TPageControl(frame.FindComponent('PageControl1'));
  if (page = nil) then
  begin
    showmessage('bug:page = nil');
    exit;
  end;

  for i := cnt to sl.Count-1 do
  begin
    cnt := i+1;
    if cnt > (sl.Count-1) then cnt := 0;
    sCompo := sl.Names[i];

    // componentの存在確認
    winctl := TWinControl(frame.FindComponent(sCompo));
    if (winctl = nil) then continue;

    // 検索対象文字列の生成1
    str1 := SetFindTarget(sCompo);

    // 検索対象文字列の生成2
    str2 := '';
    if (pos('CB_',sCompo)=1) or (pos('ChB_',sCompo)=1) or (pos('CG_',sCompo)=1) then
    begin
      str2 := winctl.Caption;
    end else begin
      s := sCompo;
      s := StringReplace(s,'Edit_','',[rfReplaceAll]);
      s := StringReplace(s,'FSE_','',[rfReplaceAll]);
      s := StringReplace(s,'SE_','',[rfReplaceAll]);
      s := 'Lbl_'+s;
      winctl2 := TWinControl(frame.FindComponent(s));
      if (winctl2 <> nil) then
      begin
        str2 := AnsiLowerCase(winctl2.Caption);
      end;
    end;

    // 比較
    if (pos(AnsiLowerCase(Edit_Find.Text),str1)<>0) or (pos(AnsiLowerCase(Edit_Find.Text),str2)<>0) or
       (pos(AnsiLowerCase(sAltFindText)  ,str1)<>0) or (pos(AnsiLowerCase(sAltFindText)  ,str2)<>0) then
    begin
      // 一致した
      sl2 := TStringList.Create;
      try
        sl2.CommaText:=sl.Values[sCompo];
        if (sl2.Count<>3) then continue;
        if (frame.FindComponent(sl2.Strings[0])<>nil) then
        begin
          if TTabSheet(frame.FindComponent(sl2.Strings[0])).TabVisible then
          begin
            page.ActivePage := TTabSheet(frame.FindComponent(sl2.Strings[0]));
          end else begin
            showmessage(format('[%s]',[winctl.Name])+#13#10+'Setting items exist in hidden tabs.');
            break;
          end;
        end else begin
          continue;
        end;
        if (sl2.Strings[1]<>'0') and (sl2.Strings[1]<>'0') then
        begin
          if (frame.FindComponent(sl2.Strings[1])<>nil) and (frame.FindComponent(sl2.Strings[2])<>nil) then
          begin
            TPageControl(frame.FindComponent(sl2.Strings[1])).ActivePage := TTabSheet(frame.FindComponent(sl2.Strings[2]));
          end;
        end;
        winctl.SetFocus;
        break;
      finally
        sl2.Free;
      end;
    end;
  end;
  if (i >= sl.Count-1) then showmessage(Form_MessageTrans.Lbl_Hidden_Find2End.Caption);
end;

procedure TFind_ui.Edit_FindKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_RETURN) and (Shift = []) then
  begin
    Button_FindClick(Sender);
    Edit_Find.SetFocus;
  end;
end;

initialization
  sl := TStringList.Create;
  //sl.Add('');
  sl.Add('Edit_Profile=Tab_general,0,0');
  sl.Add('Edit_Install_Location_Val=Tab_general,0,0');
  sl.Add('CB_MapName=Tab_general,0,0');

  // General-Args-System
  sl.Add('CB_Culture=Tab_general,PageControl2,Tab_Args');
  sl.Add('ChB_RedownloadModsOnServerRestart=Tab_general,PageControl2,Tab_Args');
  sl.Add('ChB_UseDynamicConfig=Tab_general,PageControl2,Tab_Args');
  sl.Add('ChB_NoBattlEye=Tab_general,PageControl2,Tab_Args');
  sl.Add('ChB_AltSaveDirectoryName=Tab_general,PageControl2,Tab_Args');
  sl.Add('Edit_AltSaveDirectoryName=Tab_general,PageControl2,Tab_Args');
  sl.Add('Edit_CustomNotificationURL_Val=Tab_general,PageControl2,Tab_Args');
  sl.Add('ChB_exclusivejoin=Tab_general,PageControl2,Tab_Args');
  sl.Add('ChB_NoAI=Tab_general,PageControl2,Tab_Args');
  sl.Add('ChB_DisableCustomCosmetics=Tab_general,PageControl2,Tab_Args');
  sl.Add('ChB_disableCharacterTracker=Tab_general,PageControl2,Tab_Args');
  sl.Add('ChB_ForceDupeLog=Tab_general,PageControl2,Tab_Args');
  sl.Add('ChB_DisableDupeLogDeletes=Tab_general,PageControl2,Tab_Args');
  sl.Add('ChB_ignoredupeditems=Tab_general,PageControl2,Tab_Args');
  sl.Add('ChB_UseItemDupeCheck=Tab_general,PageControl2,Tab_Args');
  sl.Add('ChB_FixThrallStats=Tab_general,PageControl2,Tab_Args');
  sl.Add('ChB_ForceCharRespec=Tab_general,PageControl2,Tab_Args');
  sl.Add('ChB_allowicefox=Tab_general,PageControl2,Tab_Args');

  // General-Args-Performance
  sl.Add('SE_WinLiveMaxPlayers_Val=Tab_general,PageControl2,Tab_Args');
  sl.Add('SE_GBUsageToForceRestart_Val=Tab_general,PageControl2,Tab_Args');
  sl.Add('ChB_AlwaysTickDedicatedSkeletalMeshes=Tab_general,PageControl2,Tab_Args');
  sl.Add('ChB_UnstasisDinoObstructionCheck=Tab_general,PageControl2,Tab_Args');
  sl.Add('ChB_UseServerNetSpeedCheck=Tab_general,PageControl2,Tab_Args');
  sl.Add('ChB_disabledinonetrangescaling=Tab_general,PageControl2,Tab_Args');
  sl.Add('ChB_StasisKeepControllers=Tab_general,PageControl2,Tab_Args');
  sl.Add('ChB_nosound=Tab_general,PageControl2,Tab_Args');
  sl.Add('ChB_noperfthreads=Tab_general,PageControl2,Tab_Args');
  sl.Add('ChB_forceuseperfthreads=Tab_general,PageControl2,Tab_Args');
  sl.Add('ChB_onethread=Tab_general,PageControl2,Tab_Args');
  sl.Add('ChB_NoTimeout=Tab_general,PageControl2,Tab_Args');

  // General-Args-IP
  sl.Add('ChB_MULTIHOME=Tab_general,PageControl2,Tab_Args');
  sl.Add('Edit_ipv4_Val=Tab_general,PageControl2,Tab_Args');
  sl.Add('Edit_ServerIPv4_Val=Tab_general,PageControl2,Tab_Args');

  // General-Args-ServerPlatform
  sl.Add('ChB_ServerPlatform_ALL=Tab_general,PageControl2,Tab_Args');
  sl.Add('ChB_ServerPlatform_PC=Tab_general,PageControl2,Tab_Args');
  sl.Add('ChB_ServerPlatform_PS5=Tab_general,PageControl2,Tab_Args');
  sl.Add('ChB_ServerPlatform_XSX=Tab_general,PageControl2,Tab_Args');
  sl.Add('ChB_ServerPlatform_MSStore=Tab_general,PageControl2,Tab_Args');

  // General-Args2
  sl.Add('CB_ActiveEvent2=Tab_general,PageControl2,Tab_Args2');

  // General-Args2-World
  sl.Add('ChB_ForceAllowCaveFlyers=Tab_general,PageControl2,Tab_Args2');
  sl.Add('ChB_AutoDestroyStructures=Tab_general,PageControl2,Tab_Args2');
  sl.Add('ChB_ForceClampItemQuality=Tab_general,PageControl2,Tab_Args2');
  sl.Add('ChB_ForceWipeTinkerExploit=Tab_general,PageControl2,Tab_Args2');
  sl.Add('ChB_ForceWipeTinkerExploitNoDinos=Tab_general,PageControl2,Tab_Args2');

  // General-Args2-Color
  sl.Add('ChB_EasterColors=Tab_general,PageControl2,Tab_Args2');
  sl.Add('ChB_OlympicColors=Tab_general,PageControl2,Tab_Args2');
  sl.Add('ChB_PrideColors=Tab_general,PageControl2,Tab_Args2');
  sl.Add('ChB_HalloweenColors=Tab_general,PageControl2,Tab_Args2');
  sl.Add('ChB_ServerUseEventColors=Tab_general,PageControl2,Tab_Args2');


  // General-Args2-Dino
  sl.Add('ChB_NoWildBabies=Tab_general,PageControl2,Tab_Args2');
  sl.Add('ChB_ForceRespawnDinos=Tab_general,PageControl2,Tab_Args2');
  sl.Add('ChB_nodinos=Tab_general,PageControl2,Tab_Args2');
  sl.Add('ChB_NoDinosExceptManualSpawn=Tab_general,PageControl2,Tab_Args2');
  sl.Add('ChB_NoDinosExceptForcedSpawn=Tab_general,PageControl2,Tab_Args2');
  sl.Add('ChB_NoDinosExceptStreamingSpawn=Tab_general,PageControl2,Tab_Args2');
  sl.Add('ChB_NoDinosExceptWaterSpawn=Tab_general,PageControl2,Tab_Args2');
  sl.Add('SE_DestroyTamesOverLevel=Tab_general,PageControl2,Tab_Args2');

  // General-RCON
  sl.Add('CB_RCONEnabled=Tab_general,PageControl2,Tab_RCON');
  sl.Add('Edit_ServerAdminPassword2=Tab_general,PageControl2,Tab_RCON');
  sl.Add('SE_RCONPort=Tab_general,PageControl2,Tab_RCON');
  sl.Add('FSE_RCONServerGameLogBuffer=Tab_general,PageControl2,Tab_RCON');
  sl.Add('ChB_servergamelog=Tab_general,PageControl2,Tab_RCON');
  sl.Add('ChB_servergamelogincludetribelogs=Tab_general,PageControl2,Tab_RCON');
  sl.Add('ChB_ServerRCONOutputTribeLogs=Tab_general,PageControl2,Tab_RCON');

  // Mods
  sl.Add('Edit_Mods=Tab_ExtraMod,0,0');
  sl.Add('Edit_AutoAddedModInArgs=Tab_ExtraMod,0,0');
  sl.Add('Edit_ActiveMapMod_Val=Tab_ExtraMod,0,0');
  sl.Add('Edit_passivemods=Tab_ExtraMod,0,0');
  sl.Add('Edit_ActiveMods_Val=Tab_ExtraMod,0,0');

  // Mods-OfficialMod
  sl.Add('CG_ActiveEvent=Tab_ExtraMod,PageControl5,Tab_OfficialMod');

  // Mods-AddDino
  sl.Add('ChB_Mod4_AA_Ceratosaurus=Tab_ExtraMod,PageControl5,Tab_Mod4');
  sl.Add('ChB_Mod4_AA_Archelon=Tab_ExtraMod,PageControl5,Tab_Mod4');
  sl.Add('ChB_Mod4_AA_Deinotherium=Tab_ExtraMod,PageControl5,Tab_Mod4');
  sl.Add('ChB_Mod4_AA_Brachiosaurus=Tab_ExtraMod,PageControl5,Tab_Mod4');
  sl.Add('ChB_Mod4_AA_Deinosuchus=Tab_ExtraMod,PageControl5,Tab_Mod4');
  sl.Add('ChB_Mod4_AA_Helicoprion=Tab_ExtraMod,PageControl5,Tab_Mod4');
  sl.Add('ChB_Mod4_AA_Xiphactinus=Tab_ExtraMod,PageControl5,Tab_Mod4');
  sl.Add('ChB_Mod4_AA_Anomalocaris=Tab_ExtraMod,PageControl5,Tab_Mod4');
  sl.Add('ChB_Mod4_AA_Acrocanthosaurus=Tab_ExtraMod,PageControl5,Tab_Mod4');

  // Mods-CryoStorage
  sl.Add('ChB_Mod1_Enabled=Tab_ExtraMod,PageControl5,Tab_Mod1');
  sl.Add('ChB_Mod1_ForceUseINISettings=Tab_ExtraMod,PageControl5,Tab_Mod1');
  sl.Add('ChB_Mod1_DisableCryoSickness=Tab_ExtraMod,PageControl5,Tab_Mod1');
  sl.Add('ChB_Mod1_PreventDeployInCaves=Tab_ExtraMod,PageControl5,Tab_Mod1');
  sl.Add('FSE_Mod1_CryoTime=Tab_ExtraMod,PageControl5,Tab_Mod1');
  sl.Add('FSE_Mod1_CryoTimeInCombat=Tab_ExtraMod,PageControl5,Tab_Mod1');
  sl.Add('SE_Mod1_CryoSicknessTimer=Tab_ExtraMod,PageControl5,Tab_Mod1');
  sl.Add('ChB_Mod1_DisableAutoCycle=Tab_ExtraMod,PageControl5,Tab_Mod1');
  sl.Add('SE_Mod1_CryogunRangeFoundations=Tab_ExtraMod,PageControl5,Tab_Mod1');
  sl.Add('SE_Mod1_CryogunCooldownSeconds=Tab_ExtraMod,PageControl5,Tab_Mod1');
  sl.Add('SE_Mod1_NeutergunRangeFoundations=Tab_ExtraMod,PageControl5,Tab_Mod1');
  sl.Add('SE_Mod1_NeutergunCooldownSeconds=Tab_ExtraMod,PageControl5,Tab_Mod1');
  sl.Add('ChB_Mod1_DisableCryopodsRequirement=Tab_ExtraMod,PageControl5,Tab_Mod1');
  sl.Add('FSE_Mod1_CryoTerminalCaptureInterval=Tab_ExtraMod,PageControl5,Tab_Mod1');
  sl.Add('SE_Mod1_CryoTerminalMaxRadiusFoundations=Tab_ExtraMod,PageControl5,Tab_Mod1');
  sl.Add('ChB_Mod1_PassImprintToDeployer=Tab_ExtraMod,PageControl5,Tab_Mod1');
  sl.Add('SE_Mod1_ImprintAmountToGive=Tab_ExtraMod,PageControl5,Tab_Mod1');
  sl.Add('ChB_Mod1_FullyGrownBabies=Tab_ExtraMod,PageControl5,Tab_Mod1');
  sl.Add('ChB_Mod1_AllowCryoterminalOnPlatforms=Tab_ExtraMod,PageControl5,Tab_Mod1');
  sl.Add('ChB_Mod1_AllowAdminCaptureAll=Tab_ExtraMod,PageControl5,Tab_Mod1');
  sl.Add('SE_Mod1_MaxCryoterminalsInRange=Tab_ExtraMod,PageControl5,Tab_Mod1');
  sl.Add('SE_Mod1_LimitCryoterminalsRange=Tab_ExtraMod,PageControl5,Tab_Mod1');
  sl.Add('ChB_Mod1_AllowDeployInBossArenas=Tab_ExtraMod,PageControl5,Tab_Mod1');
  sl.Add('FSE_Mod1_CryopodChargeSpeedMultiplier=Tab_ExtraMod,PageControl5,Tab_Mod1');
  sl.Add('ChB_Mod1_DisableCryopodChargeNeed=Tab_ExtraMod,PageControl5,Tab_Mod1');
  sl.Add('ChB_Mod1_GiveTemporaryCryopodsInCryoterminal=Tab_ExtraMod,PageControl5,Tab_Mod1');
  sl.Add('SE_Mod1_CryofridgeInventorySlots=Tab_ExtraMod,PageControl5,Tab_Mod1');
  sl.Add('SE_Mod1_CryoterminalInventorySlots=Tab_ExtraMod,PageControl5,Tab_Mod1');

  // Mods-SuperSpyglass
  sl.Add('ChB_Mod2_Enabled=Tab_ExtraMod,PageControl5,Tab_Mod2');
  sl.Add('ChB_Mod2_DisableNightVision=Tab_ExtraMod,PageControl5,Tab_Mod2');
  sl.Add('ChB_Mod2_DisablePredatorVision=Tab_ExtraMod,PageControl5,Tab_Mod2');
  sl.Add('ChB_Mod2_DisableOutlineMode=Tab_ExtraMod,PageControl5,Tab_Mod2');
  sl.Add('ChB_Mod2_DisableSupplyDropInfo=Tab_ExtraMod,PageControl5,Tab_Mod2');
  sl.Add('ChB_Mod2_DisableItembagInfo=Tab_ExtraMod,PageControl5,Tab_Mod2');
  sl.Add('ChB_Mod2_DisableStructureInfo=Tab_ExtraMod,PageControl5,Tab_Mod2');
  sl.Add('ChB_Mod2_DisableBuffInfo=Tab_ExtraMod,PageControl5,Tab_Mod2');
  sl.Add('ChB_Mod2_DisableTameFoodInfo=Tab_ExtraMod,PageControl5,Tab_Mod2');
  sl.Add('ChB_Mod2_DisableEggInfo=Tab_ExtraMod,PageControl5,Tab_Mod2');
  sl.Add('ChB_Mod2_DisableTheSpyglassOnEnemyTribes=Tab_ExtraMod,PageControl5,Tab_Mod2');
  sl.Add('ChB_Mod2_OnlyShowStatsForTames=Tab_ExtraMod,PageControl5,Tab_Mod2');
  sl.Add('ChB_Mod2_DisableGPS=Tab_ExtraMod,PageControl5,Tab_Mod2');
  sl.Add('ChB_Mod2_DisableCrosshair=Tab_ExtraMod,PageControl5,Tab_Mod2');
  sl.Add('ChB_Mod2_OnlyHPonEnemyTribeDinos=Tab_ExtraMod,PageControl5,Tab_Mod2');
  sl.Add('SE_Mod2_OutlineRange=Tab_ExtraMod,PageControl5,Tab_Mod2');
  sl.Add('ChB_Mod2_UseESPOutline=Tab_ExtraMod,PageControl5,Tab_Mod2');
  sl.Add('ChB_Mod2_UseESPOutlineFill=Tab_ExtraMod,PageControl5,Tab_Mod2');
  sl.Add('ChB_Mod2_DontShowAnyStatsOnWildDino=Tab_ExtraMod,PageControl5,Tab_Mod2');

  // Mods-DinoFinder
  sl.Add('ChB_Mod3_Enabled=Tab_ExtraMod,PageControl5,Tab_Mod3');
  sl.Add('ChB_Mod3_IsAdminOnly=Tab_ExtraMod,PageControl5,Tab_Mod3');
  sl.Add('SE_Mod3_MarkerLimit=Tab_ExtraMod,PageControl5,Tab_Mod3');

  // Mods-QoLPlus1
  sl.Add('ChB_Mod5_Enabled=Tab_ExtraMod,PageControl5,Tab_Mod5_1');
  sl.Add('CB_Mod5_RemoveFloorRequirementFromStructurePlacement=Tab_ExtraMod,PageControl5,Tab_Mod5_1');
  sl.Add('CB_Mod5_DisableResourcePulling=Tab_ExtraMod,PageControl5,Tab_Mod5_1');
  sl.Add('FSE_Mod5_ResourceTransferCooldown=Tab_ExtraMod,PageControl5,Tab_Mod5_1');
  sl.Add('ChB_Mod5_PullingIgnoresPinCodes=Tab_ExtraMod,PageControl5,Tab_Mod5_1');
  sl.Add('ChB_Mod5_EnableExtendedDeathCache=Tab_ExtraMod,PageControl5,Tab_Mod5_1');
  sl.Add('ChB_Mod5_EnableUpdateDurability=Tab_ExtraMod,PageControl5,Tab_Mod5_1');
  sl.Add('ChB_Mod5_AllowTekItemBlueprintCreation=Tab_ExtraMod,PageControl5,Tab_Mod5_1');
  sl.Add('ChB_Mod5_AllowMakingWeaponsAndArmorBPs=Tab_ExtraMod,PageControl5,Tab_Mod5_1');
  sl.Add('ChB_Mod5_DisableMultiToolDinoKillMode=Tab_ExtraMod,PageControl5,Tab_Mod5_1');
  sl.Add('ChB_Mod5_DisableMultiToolDinoChibiMode=Tab_ExtraMod,PageControl5,Tab_Mod5_1');
  sl.Add('ChB_Mod5_AllowMultiToolNeuterAll=Tab_ExtraMod,PageControl5,Tab_Mod5_1');
  sl.Add('ChB_Mod5_AllowGrindingMissionRewards=Tab_ExtraMod,PageControl5,Tab_Mod5_1');
  sl.Add('ChB_Mod5_EnableStructureSound=Tab_ExtraMod,PageControl5,Tab_Mod5_1');
  sl.Add('ChB_Mod5_DisableBlueprintInstall=Tab_ExtraMod,PageControl5,Tab_Mod5_1');
  sl.Add('SE_Mod5_PropagatorFuelInterval=Tab_ExtraMod,PageControl5,Tab_Mod5_1');
  sl.Add('SE_Mod5_PropagatorModCostMutate=Tab_ExtraMod,PageControl5,Tab_Mod5_1');
  sl.Add('ChB_Mod5_PropagatorDisableDinoMods=Tab_ExtraMod,PageControl5,Tab_Mod5_1');
  sl.Add('ChB_Mod5_PropagatorRespectMutationLimit=Tab_ExtraMod,PageControl5,Tab_Mod5_1');
  sl.Add('ChB_Mod5_PropagatorDisableEggDrop=Tab_ExtraMod,PageControl5,Tab_Mod5_1');
  sl.Add('SE_Mod5_TribePropagatorLimit=Tab_ExtraMod,PageControl5,Tab_Mod5_1');
  sl.Add('SE_Mod5_NannyMaxImprint=Tab_ExtraMod,PageControl5,Tab_Mod5_1');
  sl.Add('ChB_Mod5_DisableNannyImprinting=Tab_ExtraMod,PageControl5,Tab_Mod5_1');
  sl.Add('SE_Mod5_NannyIntervalInSeconds=Tab_ExtraMod,PageControl5,Tab_Mod5_1');
  sl.Add('SE_Mod5_NannyFeedingStartThreshold=Tab_ExtraMod,PageControl5,Tab_Mod5_1');
  sl.Add('SE_Mod5_BeeHiveHoneyIntervalInSeconds=Tab_ExtraMod,PageControl5,Tab_Mod5_1');
  sl.Add('SE_Mod5_MutatorBuffMaxStackCount=Tab_ExtraMod,PageControl5,Tab_Mod5_1');
  sl.Add('ChB_Mod5_MutatorAllowBreedingNeutered=Tab_ExtraMod,PageControl5,Tab_Mod5_1');
  sl.Add('ChB_Mod5_DisableHitchingPostMatingBonus=Tab_ExtraMod,PageControl5,Tab_Mod5_1');
  sl.Add('SE_Mod5_HitchingPostRange=Tab_ExtraMod,PageControl5,Tab_Mod5_1');
  sl.Add('SE_Mod5_HitchingPostDinoLimit=Tab_ExtraMod,PageControl5,Tab_Mod5_1');
  sl.Add('SE_Mod5_HitchingPostTribeLimit=Tab_ExtraMod,PageControl5,Tab_Mod5_1');
  sl.Add('SE_Mod5_GrinderResourceReturnPercent=Tab_ExtraMod,PageControl5,Tab_Mod5_1');
  sl.Add('SE_Mod5_GrinderResourceReturnMax=Tab_ExtraMod,PageControl5,Tab_Mod5_1');
  sl.Add('ChB_Mod5_GrinderReturnBlockedResources=Tab_ExtraMod,PageControl5,Tab_Mod5_1');

  // Mods-QoLPlus2
  sl.Add('SE_Mod5_SmallStorageSlotCount=Tab_ExtraMod,PageControl5,Tab_Mod5_2');
  sl.Add('SE_Mod5_LargeStorageSlotCount=Tab_ExtraMod,PageControl5,Tab_Mod5_2');
  sl.Add('SE_Mod5_MetalStorageSlotCount=Tab_ExtraMod,PageControl5,Tab_Mod5_2');
  sl.Add('SE_Mod5_MetalStorageSlotCount=Tab_ExtraMod,PageControl5,Tab_Mod5_2');
  sl.Add('SE_Mod5_NannySlotCount=Tab_ExtraMod,PageControl5,Tab_Mod5_2');
  sl.Add('SE_Mod5_TransmutatorSlotCount=Tab_ExtraMod,PageControl5,Tab_Mod5_2');
  sl.Add('SE_Mod5_GardenerSlotCount=Tab_ExtraMod,PageControl5,Tab_Mod5_2');
  sl.Add('SE_Mod5_FarmerSlotCount=Tab_ExtraMod,PageControl5,Tab_Mod5_2');
  sl.Add('SE_Mod5_BeeHiveSlotCount=Tab_ExtraMod,PageControl5,Tab_Mod5_2');
  sl.Add('SE_Mod5_AmmoBoxSlotCount=Tab_ExtraMod,PageControl5,Tab_Mod5_2');
  sl.Add('SE_Mod5_GrinderSlotCount=Tab_ExtraMod,PageControl5,Tab_Mod5_2');
  sl.Add('SE_Mod5_IndustrialForgeSlotCount=Tab_ExtraMod,PageControl5,Tab_Mod5_2');
  sl.Add('SE_Mod5_GeneratorSlotCount=Tab_ExtraMod,PageControl5,Tab_Mod5_2');
  sl.Add('SE_Mod5_ReplicatorSlotCount=Tab_ExtraMod,PageControl5,Tab_Mod5_2');
  sl.Add('SE_Mod5_FridgeSlotCount=Tab_ExtraMod,PageControl5,Tab_Mod5_2');
  sl.Add('SE_Mod5_PreservingBinSlotCount=Tab_ExtraMod,PageControl5,Tab_Mod5_2');
  sl.Add('SE_Mod5_FabricatorSlotCount=Tab_ExtraMod,PageControl5,Tab_Mod5_2');
  sl.Add('SE_Mod5_TekGeneratorSlotCount=Tab_ExtraMod,PageControl5,Tab_Mod5_2');
  sl.Add('FSE_Mod5_RaidTimerLimitMultiplier=Tab_ExtraMod,PageControl5,Tab_Mod5_2');
  sl.Add('FSE_Mod5_PropagatorMatingSpeedMultiplier=Tab_ExtraMod,PageControl5,Tab_Mod5_2');
  sl.Add('FSE_Mod5_PropagatorMatingIntervalMultiplier=Tab_ExtraMod,PageControl5,Tab_Mod5_2');
  sl.Add('FSE_Mod5_GrinderScaleMultiplier=Tab_ExtraMod,PageControl5,Tab_Mod5_2');
  sl.Add('FSE_Mod5_IndustrialForgeScaleMultiplier=Tab_ExtraMod,PageControl5,Tab_Mod5_2');
  sl.Add('FSE_Mod5_ReplicatorScaleMultiplier=Tab_ExtraMod,PageControl5,Tab_Mod5_2');
  sl.Add('SE_Mod5_GrinderCraftingSpeed=Tab_ExtraMod,PageControl5,Tab_Mod5_2');
  sl.Add('SE_Mod5_IndustrialForgeCraftingSpeed=Tab_ExtraMod,PageControl5,Tab_Mod5_2');
  sl.Add('SE_Mod5_ReplicatorCraftingSpeed=Tab_ExtraMod,PageControl5,Tab_Mod5_2');
  sl.Add('SE_Mod5_FridgeCraftingSpeed=Tab_ExtraMod,PageControl5,Tab_Mod5_2');
  sl.Add('SE_Mod5_PreservingBinCraftingSpeed=Tab_ExtraMod,PageControl5,Tab_Mod5_2');
  sl.Add('SE_Mod5_FabricatorCraftingSpeed=Tab_ExtraMod,PageControl5,Tab_Mod5_2');
  sl.Add('SE_Mod5_ResourcePullRangeInFoundations=Tab_ExtraMod,PageControl5,Tab_Mod5_2');
  sl.Add('SE_Mod5_BeeHiveWateringRangeInFoundations=Tab_ExtraMod,PageControl5,Tab_Mod5_2');
  sl.Add('SE_Mod5_MaxMutatorRangeInFoundations=Tab_ExtraMod,PageControl5,Tab_Mod5_2');
  sl.Add('SE_Mod5_MaxPowerRangeInFoundations=Tab_ExtraMod,PageControl5,Tab_Mod5_2');
  sl.Add('SE_Mod5_GardenerRangeInFoundations=Tab_ExtraMod,PageControl5,Tab_Mod5_2');
  sl.Add('SE_Mod5_FarmerRangeInFoundations=Tab_ExtraMod,PageControl5,Tab_Mod5_2');
  sl.Add('SE_Mod5_NannyRangeInFoundations=Tab_ExtraMod,PageControl5,Tab_Mod5_2');

  // Mods-QoLPlus3
  sl.Add('CG_Mod5_MutatorModeBlacklist=Tab_ExtraMod,PageControl5,Tab_Mod5_3');
  sl.Add('Edit_Mod5_MutatorPulseCost=Tab_ExtraMod,PageControl5,Tab_Mod5_3');
  sl.Add('Edit_Mod5_MutatorPulseCooldowns=Tab_ExtraMod,PageControl5,Tab_Mod5_3');
  sl.Add('Edit_Mod5_MutatorDinoBlacklist=Tab_ExtraMod,PageControl5,Tab_Mod5_3');
  sl.Add('Edit_Mod5_PullResourceAdditions=Tab_ExtraMod,PageControl5,Tab_Mod5_3');
  sl.Add('Edit_Mod5_PullResourceRemovals=Tab_ExtraMod,PageControl5,Tab_Mod5_3');
  sl.Add('Edit_Mod5_AdvTransferItemBlacklist=Tab_ExtraMod,PageControl5,Tab_Mod5_3');
  sl.Add('Edit_Mod5_QoLPlusEngramWhitelist=Tab_ExtraMod,PageControl5,Tab_Mod5_3');
  sl.Add('Edit_Mod5_OmniToolBlacklist=Tab_ExtraMod,PageControl5,Tab_Mod5_3');
  sl.Add('Edit_Mod5_MultiToolBlacklist=Tab_ExtraMod,PageControl5,Tab_Mod5_3');
  sl.Add('Edit_Mod5_PropagatorDinoBlacklist=Tab_ExtraMod,PageControl5,Tab_Mod5_3');
  sl.Add('Edit_Mod5_PropagatorFuelClass=Tab_ExtraMod,PageControl5,Tab_Mod5_3');
  sl.Add('Edit_Mod5_PropagatorModCostItemClass=Tab_ExtraMod,PageControl5,Tab_Mod5_3');

  // Server1
  sl.Add('Edit_SessionName=Tab_ServerSettings,0,0');
  sl.Add('SE_Port=Tab_ServerSettings,0,0');
  sl.Add('SE_QueryPort=Tab_ServerSettings,0,0');
  sl.Add('Edit_ServerPassword=Tab_ServerSettings,0,0');
  sl.Add('Edit_ServerAdminPassword=Tab_ServerSettings,0,0');
  sl.Add('FSE_AutoSavePeriodMinutes=Tab_ServerSettings,0,0');
  sl.Add('FSE_KickIdlePlayersPeriod=Tab_ServerSettings,0,0');

  // Server-CrossARK
  sl.Add('ChB_noTributeDownloads=Tab_ServerSettings,PageControl7,Tab_CrossARK');
  sl.Add('ChB_CrossARKAllowForeignDinoDownloads=Tab_ServerSettings,PageControl7,Tab_CrossARK');
  sl.Add('ChB_PreventDownloadItems=Tab_ServerSettings,PageControl7,Tab_CrossARK');
  sl.Add('ChB_PreventDownloadSurvivors=Tab_ServerSettings,PageControl7,Tab_CrossARK');
  sl.Add('ChB_PreventDownloadDinos=Tab_ServerSettings,PageControl7,Tab_CrossARK');
  sl.Add('ChB_PreventUploadItems=Tab_ServerSettings,PageControl7,Tab_CrossARK');
  sl.Add('ChB_PreventUploadSurvivors=Tab_ServerSettings,PageControl7,Tab_CrossARK');
  sl.Add('ChB_PreventUploadDinos=Tab_ServerSettings,PageControl7,Tab_CrossARK');
  sl.Add('SE_MaxTributeDinos=Tab_ServerSettings,PageControl7,Tab_CrossARK');
  sl.Add('SE_MaxTributeItems=Tab_ServerSettings,PageControl7,Tab_CrossARK');
  sl.Add('SE_MaxTributeCharacters=Tab_ServerSettings,PageControl7,Tab_CrossARK');
  sl.Add('SE_TributeItemExpirationSeconds=Tab_ServerSettings,PageControl7,Tab_CrossARK');
  sl.Add('SE_TributeCharacterExpirationSeconds=Tab_ServerSettings,PageControl7,Tab_CrossARK');
  sl.Add('SE_TributeDinoExpirationSeconds=Tab_ServerSettings,PageControl7,Tab_CrossARK');

  // Server-CrossARK-Args
  sl.Add('Edit_clusterid=Tab_ServerSettings,PageControl7,Tab_CrossARK');
  sl.Add('Edit_ClusterDirOverride=Tab_ServerSettings,PageControl7,Tab_CrossARK');
  sl.Add('ChB_NoTransferFromFiltering=Tab_ServerSettings,PageControl7,Tab_CrossARK');

  // Server-ChatAndMessage
  sl.Add('Edit_Message=Tab_ServerSettings,PageControl7,Tab_Message');
  sl.Add('SE_Duration=Tab_ServerSettings,PageControl7,Tab_Message');
  sl.Add('ChB_AdminLogging=Tab_ServerSettings,PageControl7,Tab_Message');
  sl.Add('ChB_AllowHideDamageSourceFromLogs=Tab_ServerSettings,PageControl7,Tab_Message');
  sl.Add('ChB_DontAlwaysNotifyPlayerJoined=Tab_ServerSettings,PageControl7,Tab_Message');
  sl.Add('ChB_globalVoiceChat=Tab_ServerSettings,PageControl7,Tab_Message');
  sl.Add('ChB_ProximityChat=Tab_ServerSettings,PageControl7,Tab_Message');
  sl.Add('ChB_AlwaysNotifyPlayerLeft=Tab_ServerSettings,PageControl7,Tab_Message');

  // Server-URLs
  sl.Add('Edit_BanListURL=Tab_ServerSettings,PageControl7,Tab_URLs');
  sl.Add('Edit_CustomLiveTuningUrl=Tab_ServerSettings,PageControl7,Tab_URLs');
  sl.Add('Edit_BadWordListURL=Tab_ServerSettings,PageControl7,Tab_URLs');
  sl.Add('Edit_BadWordWhiteListURL=Tab_ServerSettings,PageControl7,Tab_URLs');
  sl.Add('Edit_AdminListURL=Tab_ServerSettings,PageControl7,Tab_URLs');

  // Server2
  sl.Add('ChB_bShowCreativeMode=Tab_ServerSettings,0,0');
  sl.Add('ChB_OverrideStartTime=Tab_ServerSettings,0,0');
  sl.Add('FSE_StartTimeHour=Tab_ServerSettings,0,0');
  sl.Add('SE_OverrideMaxExperiencePointsPlayer=Tab_ServerSettings,0,0');
  sl.Add('SE_OverrideMaxExperiencePointsDino=Tab_ServerSettings,0,0');
  sl.Add('FSE_AutoRestartIntervalSeconds=Tab_ServerSettings,0,0');
  sl.Add('SE_PhotoModeRangeLimit=Tab_ServerSettings,0,0');
  sl.Add('FSE_UpdateAllowedCheatersInterval=Tab_ServerSettings,0,0');
  sl.Add('ChB_UseCharacterTracker=Tab_ServerSettings,0,0');
  sl.Add('FSE_ServerAutoForceRespawnWildDinosInterval=Tab_ServerSettings,0,0');
  sl.Add('ChB_ForceExploitedTameDeletion=Tab_ServerSettings,0,0');
  sl.Add('SE_LimitNonPlayerDroppedItemsCount=Tab_ServerSettings,0,0');
  sl.Add('SE_LimitNonPlayerDroppedItemsRange=Tab_ServerSettings,0,0');

  // World1
  sl.Add('FSE_DayCycleSpeedScale=Tab_WorldSetting,0,0');
  sl.Add('FSE_DayTimeSpeedScale=Tab_WorldSetting,0,0');
  sl.Add('FSE_NightTimeSpeedScale=Tab_WorldSetting,0,0');
  sl.Add('FSE_DifficultyOffset=Tab_WorldSetting,0,0');
  sl.Add('FSE_OverrideOfficialDifficulty=Tab_WorldSetting,0,0');
  sl.Add('ChB_MaxDifficulty=Tab_WorldSetting,0,0');
  sl.Add('ChB_ServerHardcore=Tab_WorldSetting,0,0');

  // PvE
  sl.Add('ChB_serverPVE=Tab_WorldSetting,PageControl3,Tab_PvE');
  sl.Add('ChB_AllowFlyerCarryPvE=Tab_WorldSetting,PageControl3,Tab_PvE');
  sl.Add('ChB_bPvEDisableFriendlyFire=Tab_WorldSetting,PageControl3,Tab_PvE');
  sl.Add('ChB_PvEAllowStructuresAtSupplyDrops=Tab_WorldSetting,PageControl3,Tab_PvE');
  sl.Add('ChB_bAutoPvETimer=Tab_WorldSetting,PageControl3,Tab_PvE');
  sl.Add('SE_AutoPvEStartTimeSeconds=Tab_WorldSetting,PageControl3,Tab_PvE');
  sl.Add('SE_AutoPvEStopTimeSeconds=Tab_WorldSetting,PageControl3,Tab_PvE');
  sl.Add('ChB_bAutoPvEUseSystemTime=Tab_WorldSetting,PageControl3,Tab_PvE');
  sl.Add('ChB_bPvEAllowTribeWar=Tab_WorldSetting,PageControl3,Tab_PvE');
  sl.Add('ChB_bPvEAllowTribeWarCancel=Tab_WorldSetting,PageControl3,Tab_PvE');
  sl.Add('ChB_DisablePvEGamma=Tab_WorldSetting,PageControl3,Tab_PvE');
  sl.Add('ChB_AllowCaveBuildingPvE=Tab_WorldSetting,PageControl3,Tab_PvE');
  sl.Add('ChB_DisableStructureDecayPvE=Tab_WorldSetting,PageControl3,Tab_PvE');
  sl.Add('FSE_PvEDinoDecayPeriodMultiplier=Tab_WorldSetting,PageControl3,Tab_PvE');
  sl.Add('ChB_DisableDinoDecayPvE=Tab_WorldSetting,PageControl3,Tab_PvE');
  sl.Add('FSE_PvEStructureDecayPeriodMultiplier=Tab_WorldSetting,PageControl3,Tab_PvE');

  // PvP
  sl.Add('ChB_PvPDinoDecay=Tab_WorldSetting,PageControl3,Tab_PvP');
  sl.Add('ChB_PvPStructureDecay=Tab_WorldSetting,PageControl3,Tab_PvP');
  sl.Add('ChB_AllowCaveBuildingPvP=Tab_WorldSetting,PageControl3,Tab_PvP');
  sl.Add('ChB_PreventOfflinePvP=Tab_WorldSetting,PageControl3,Tab_PvP');
  sl.Add('ChB_EnablePvPGamma=Tab_WorldSetting,PageControl3,Tab_PvP');
  sl.Add('FSE_PreventOfflinePvPInterval=Tab_WorldSetting,PageControl3,Tab_PvP');
  sl.Add('ChB_bIncreasePvPRespawnInterval=Tab_WorldSetting,PageControl3,Tab_PvP');
  sl.Add('FSE_IncreasePvPRespawnIntervalCheckPeriod=Tab_WorldSetting,PageControl3,Tab_PvP');
  sl.Add('FSE_IncreasePvPRespawnIntervalMultiplier=Tab_WorldSetting,PageControl3,Tab_PvP');
  sl.Add('FSE_IncreasePvPRespawnIntervalBaseAmount=Tab_WorldSetting,PageControl3,Tab_PvP');
  sl.Add('SE_PvPZoneStructureDamageMultiplier=Tab_WorldSetting,PageControl3,Tab_PvP');
  sl.Add('ChB_IgnorePVPMountedWeaponryRestrictions=Tab_WorldSetting,PageControl3,Tab_PvP');
  sl.Add('ChB_AllowTeslaCoilCaveBuildingPVP=Tab_WorldSetting,PageControl3,Tab_PvP');
  sl.Add('FSE_TribeTowerBonusMultiplier=Tab_WorldSetting,PageControl3,Tab_PvP');

  // Extinction
  sl.Add('Edit_WorldBossKingKaijuSpawnTime=Tab_WorldSetting,PageControl3,Tab_Extinction');
  sl.Add('ChB_ForceGachaUnhappyInCaves=Tab_WorldSetting,PageControl3,Tab_Extinction');
  sl.Add('ChB_bAllowFlyerDinoSubmerging=Tab_WorldSetting,PageControl3,Tab_Extinction');
  sl.Add('SE_ArmadoggoDeathCooldown=Tab_WorldSetting,PageControl3,Tab_Extinction');
  sl.Add('SE_MaxBlueprintDinoLevel=Tab_WorldSetting,PageControl3,Tab_Extinction');
  sl.Add('SE_MaxBlueprintDinoQuality=Tab_WorldSetting,PageControl3,Tab_Extinction');
  sl.Add('SE_MaxBlueprintItemQuality=Tab_WorldSetting,PageControl3,Tab_Extinction');
  sl.Add('SE_MaxBlueprintScoutQuality=Tab_WorldSetting,PageControl3,Tab_Extinction');

  // Ragnarok
  sl.Add('SE_YoungIceFoxDeathCooldown=Tab_WorldSetting,PageControl3,Tab_Ragnarok');
  sl.Add('SE_CompanionsDeathCooldown=Tab_WorldSetting,PageControl3,Tab_Ragnarok');

  // LostColony
  sl.Add('ChB_LimitBunkersPerTribe=Tab_WorldSetting,PageControl3,Tab_LostColony');
  sl.Add('SE_LimitBunkersPerTribeNum=Tab_WorldSetting,PageControl3,Tab_LostColony');
  sl.Add('ChB_AllowBunkersInPreventionZones=Tab_WorldSetting,PageControl3,Tab_LostColony');
  sl.Add('ChB_AllowRidingDinosInsideBunkers=Tab_WorldSetting,PageControl3,Tab_LostColony');
  sl.Add('ChB_AllowBunkerModulesAboveGround=Tab_WorldSetting,PageControl3,Tab_LostColony');
  sl.Add('ChB_AllowDinoAIInsideBunkers=Tab_WorldSetting,PageControl3,Tab_LostColony');
  sl.Add('ChB_AllowBunkerModulesInPreventionZones=Tab_WorldSetting,PageControl3,Tab_LostColony');
  sl.Add('FSE_MinDistanceBetweenBunkers=Tab_WorldSetting,PageControl3,Tab_LostColony');
  sl.Add('FSE_EnemyAccessBunkerHPThreshold=Tab_WorldSetting,PageControl3,Tab_LostColony');
  sl.Add('FSE_BunkerUnderHPThresholdDmgMultiplier=Tab_WorldSetting,PageControl3,Tab_LostColony');
  sl.Add('FSE_CryoHospitalHoursToRegenHP=Tab_WorldSetting,PageControl3,Tab_LostColony');
  sl.Add('FSE_CryoHospitalHoursToRegenFood=Tab_WorldSetting,PageControl3,Tab_LostColony');
  sl.Add('FSE_CryoHospitalHoursToDrainTorpor=Tab_WorldSetting,PageControl3,Tab_LostColony');
  sl.Add('FSE_CryoHospitalMatingCooldownReduction=Tab_WorldSetting,PageControl3,Tab_LostColony');
  sl.Add('FSE_BloodforgeReinforceExtraDurability=Tab_WorldSetting,PageControl3,Tab_LostColony');
  sl.Add('FSE_BloodforgeReinforceResourceCostMultiplier=Tab_WorldSetting,PageControl3,Tab_LostColony');
  sl.Add('FSE_BloodforgeReinforceSpeedMultiplier=Tab_WorldSetting,PageControl3,Tab_LostColony');
  sl.Add('SE_MaxActiveOutposts=Tab_WorldSetting,PageControl3,Tab_LostColony');
  sl.Add('SE_MaxActiveResourceCaches=Tab_WorldSetting,PageControl3,Tab_LostColony');
  sl.Add('SE_MaxActiveCityOutposts=Tab_WorldSetting,PageControl3,Tab_LostColony');

  // Multiplier
  sl.Add('FSE_HarvestAmountMultiplier=Tab_WorldSetting,PageControl3,Tab_Multiplier');
  sl.Add('FSE_HarvestHealthMultiplier=Tab_WorldSetting,PageControl3,Tab_Multiplier');
  sl.Add('FSE_ResourcesRespawnPeriodMultiplier=Tab_WorldSetting,PageControl3,Tab_Multiplier');
  sl.Add('FSE_ResourceNoReplenishRadiusPlayers=Tab_WorldSetting,PageControl3,Tab_Multiplier');
  sl.Add('FSE_ResourceNoReplenishRadiusStructures=Tab_WorldSetting,PageControl3,Tab_Multiplier');
  sl.Add('FSE_CropDecaySpeedMultiplier=Tab_WorldSetting,PageControl3,Tab_Multiplier');
  sl.Add('FSE_CropGrowthSpeedMultiplier=Tab_WorldSetting,PageControl3,Tab_Multiplier');
  sl.Add('FSE_ItemStackSizeMultiplier=Tab_WorldSetting,PageControl3,Tab_Multiplier');
  sl.Add('FSE_GlobalSpoilingTimeMultiplier=Tab_WorldSetting,PageControl3,Tab_Multiplier');
  sl.Add('FSE_GlobalCorpseDecompositionTimeMultiplier=Tab_WorldSetting,PageControl3,Tab_Multiplier');
  sl.Add('FSE_GlobalItemDecompositionTimeMultiplier=Tab_WorldSetting,PageControl3,Tab_Multiplier');
  sl.Add('FSE_FuelConsumptionIntervalMultiplier=Tab_WorldSetting,PageControl3,Tab_Multiplier');
  sl.Add('FSE_BaseTemperatureMultiplier=Tab_WorldSetting,PageControl3,Tab_Multiplier');


  // World-Tribe
  sl.Add('ChB_PreventTribeAlliances=Tab_WorldSetting,0,0');
  sl.Add('FSE_TribeNameChangeCooldown=Tab_WorldSetting,0,0');
  sl.Add('SE_MaxNumberOfPlayersInTribe=Tab_WorldSetting,0,0');

  // World2
  sl.Add('ChB_PreventDiseases=Tab_WorldSetting,0,0');
  sl.Add('CB_NonPermanentDiseases=Tab_WorldSetting,0,0');
  sl.Add('ChB_ClampItemSpoilingTimes=Tab_WorldSetting,0,0');
  sl.Add('ChB_ClampResourceHarvestDamage=Tab_WorldSetting,0,0');
  sl.Add('ChB_ClampItemStats=Tab_WorldSetting,0,0');
  sl.Add('ChB_bDisableDinoRiding=Tab_WorldSetting,0,0');
  sl.Add('ChB_bDisableDinoTaming=Tab_WorldSetting,0,0');
  sl.Add('ChB_bDisableDinoBreeding=Tab_WorldSetting,0,0');
  sl.Add('ChB_bAllowSpeedLeveling=Tab_WorldSetting,0,0');
  sl.Add('ChB_bAllowFlyerSpeedLeveling=Tab_WorldSetting,0,0');
  sl.Add('ChB_bDisableFriendlyFire=Tab_WorldSetting,0,0');
  sl.Add('ChB_bDisableLootCrates=Tab_WorldSetting,0,0');
  sl.Add('ChB_RandomSupplyCratePoints=Tab_WorldSetting,0,0');
  sl.Add('ChB_bUseSingleplayerSettings=Tab_WorldSetting,0,0');
  sl.Add('ChB_bAllowBuildingInNoBuildZone=Tab_WorldSetting,0,0');
  sl.Add('ChB_EnableExtraStructurePreventionVolumes=Tab_WorldSetting,0,0');
  sl.Add('ChB_bDisableStructurePlacementCollision=Tab_WorldSetting,0,0');
  sl.Add('ChB_AutoDestroyDecayedDinos=Tab_WorldSetting,0,0');
  sl.Add('ChB_bForceCanRideFliers=Tab_WorldSetting,0,0');
  sl.Add('SE_MaxTrainCars=Tab_WorldSetting,0,0');
  sl.Add('ChB_bIgnoreStructuresPreventionVolumes=Tab_WorldSetting,0,0');
  sl.Add('ChB_bUseCorpseLocator=Tab_WorldSetting,0,0');

  // Visual&HUD
  sl.Add('ChB_AllowHitMarkers=Tab_VisualSettings,0,0');
  sl.Add('ChB_AllowThirdPersonPlayer=Tab_VisualSettings,0,0');
  sl.Add('ChB_DisableWeatherFog=Tab_VisualSettings,0,0');
  sl.Add('ChB_ServerCrosshair=Tab_VisualSettings,0,0');
  sl.Add('ChB_ServerForceNoHUD=Tab_VisualSettings,0,0');
  sl.Add('ChB_ShowFloatingDamageText=Tab_VisualSettings,0,0');
  sl.Add('ChB_ShowMapPlayerLocation=Tab_VisualSettings,0,0');
  sl.Add('ChB_bDisablePhotoMode=Tab_VisualSettings,0,0');

  // Player-PlayerBaseStatMultipliers
  sl.Add('FSE_PlayerBaseStatMultipliers0=Tab_PlayerSetting,0,0');
  sl.Add('FSE_PlayerBaseStatMultipliers1=Tab_PlayerSetting,0,0');
  sl.Add('FSE_PlayerBaseStatMultipliers2=Tab_PlayerSetting,0,0');
  sl.Add('FSE_PlayerBaseStatMultipliers3=Tab_PlayerSetting,0,0');
  sl.Add('FSE_PlayerBaseStatMultipliers4=Tab_PlayerSetting,0,0');
  sl.Add('FSE_PlayerBaseStatMultipliers5=Tab_PlayerSetting,0,0');
  sl.Add('FSE_PlayerBaseStatMultipliers6=Tab_PlayerSetting,0,0');
  sl.Add('FSE_PlayerBaseStatMultipliers7=Tab_PlayerSetting,0,0');
  sl.Add('FSE_PlayerBaseStatMultipliers8=Tab_PlayerSetting,0,0');
  sl.Add('FSE_PlayerBaseStatMultipliers9=Tab_PlayerSetting,0,0');
  sl.Add('FSE_PlayerBaseStatMultipliers10=Tab_PlayerSetting,0,0');
  sl.Add('FSE_PlayerBaseStatMultipliers11=Tab_PlayerSetting,0,0');

  // Player-PlayerBaseStatMultipliers
  sl.Add('FSE_PerLevelStatsMultiplier_Player0=Tab_PlayerSetting,0,0');
  sl.Add('FSE_PerLevelStatsMultiplier_Player1=Tab_PlayerSetting,0,0');
  sl.Add('FSE_PerLevelStatsMultiplier_Player2=Tab_PlayerSetting,0,0');
  sl.Add('FSE_PerLevelStatsMultiplier_Player3=Tab_PlayerSetting,0,0');
  sl.Add('FSE_PerLevelStatsMultiplier_Player4=Tab_PlayerSetting,0,0');
  sl.Add('FSE_PerLevelStatsMultiplier_Player5=Tab_PlayerSetting,0,0');
  sl.Add('FSE_PerLevelStatsMultiplier_Player6=Tab_PlayerSetting,0,0');
  sl.Add('FSE_PerLevelStatsMultiplier_Player7=Tab_PlayerSetting,0,0');
  sl.Add('FSE_PerLevelStatsMultiplier_Player8=Tab_PlayerSetting,0,0');
  sl.Add('FSE_PerLevelStatsMultiplier_Player9=Tab_PlayerSetting,0,0');
  sl.Add('FSE_PerLevelStatsMultiplier_Player10=Tab_PlayerSetting,0,0');
  sl.Add('FSE_PerLevelStatsMultiplier_Player11=Tab_PlayerSetting,0,0');

  // Player-Hexagons
  sl.Add('SE_MaxHexagonsPerCharacter=Tab_PlayerSetting,0,0');
  sl.Add('FSE_BaseHexagonRewardMultiplier=Tab_PlayerSetting,0,0');
  sl.Add('FSE_HexagonCostMultiplier=Tab_PlayerSetting,0,0');

  // Player
  sl.Add('FSE_OxygenSwimSpeedStatMultiplier=Tab_PlayerSetting,0,0');
  sl.Add('FSE_PlayerCharacterHealthRecoveryMultiplier=Tab_PlayerSetting,0,0');
  sl.Add('FSE_PlayerCharacterWaterDrainMultiplier=Tab_PlayerSetting,0,0');
  sl.Add('FSE_PlayerResistanceMultiplier=Tab_PlayerSetting,0,0');
  sl.Add('FSE_PlayerHarvestingDamageMultiplier=Tab_PlayerSetting,0,0');
  sl.Add('ChB_PreventSpawnAnimations=Tab_PlayerSetting,0,0');
  sl.Add('ChB_bAllowUnlimitedRespecs=Tab_PlayerSetting,0,0');
  sl.Add('FSE_PlayerCharacterFoodDrainMultiplier=Tab_PlayerSetting,0,0');
  sl.Add('FSE_PlayerCharacterStaminaDrainMultiplier=Tab_PlayerSetting,0,0');
  sl.Add('FSE_PlayerDamageMultiplier=Tab_PlayerSetting,0,0');
  sl.Add('FSE_PoopIntervalMultiplier=Tab_PlayerSetting,0,0');
  sl.Add('FSE_MaxFallSpeedMultiplier=Tab_PlayerSetting,0,0');
  sl.Add('FSE_UseCorpseLifeSpanMultiplier=Tab_PlayerSetting,0,0');
  sl.Add('SE_ImplantSuicideCD=Tab_PlayerSetting,0,0');

  // Dino-TamedDino-PerLevelStatsMultiplier_DinoTamed
  sl.Add('FSE_PerLevelStatsMultiplier_DinoTamed0=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('FSE_PerLevelStatsMultiplier_DinoTamed1=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('FSE_PerLevelStatsMultiplier_DinoTamed2=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('FSE_PerLevelStatsMultiplier_DinoTamed3=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('FSE_PerLevelStatsMultiplier_DinoTamed4=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('FSE_PerLevelStatsMultiplier_DinoTamed5=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('FSE_PerLevelStatsMultiplier_DinoTamed6=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('FSE_PerLevelStatsMultiplier_DinoTamed7=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('FSE_PerLevelStatsMultiplier_DinoTamed8=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('FSE_PerLevelStatsMultiplier_DinoTamed9=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('FSE_PerLevelStatsMultiplier_DinoTamed10=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');

  // Dino-TamedDino-PerLevelStatsMultiplier_DinoTamed_Affinity
  sl.Add('FSE_PerLevelStatsMultiplier_DinoTamed_Affinity0=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('FSE_PerLevelStatsMultiplier_DinoTamed_Affinity1=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('FSE_PerLevelStatsMultiplier_DinoTamed_Affinity2=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('FSE_PerLevelStatsMultiplier_DinoTamed_Affinity3=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('FSE_PerLevelStatsMultiplier_DinoTamed_Affinity4=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('FSE_PerLevelStatsMultiplier_DinoTamed_Affinity5=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('FSE_PerLevelStatsMultiplier_DinoTamed_Affinity6=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('FSE_PerLevelStatsMultiplier_DinoTamed_Affinity7=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('FSE_PerLevelStatsMultiplier_DinoTamed_Affinity8=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('FSE_PerLevelStatsMultiplier_DinoTamed_Affinity9=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('FSE_PerLevelStatsMultiplier_DinoTamed_Affinity10=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');

  // Dino-TamedDino-BabyDino
  sl.Add('ChB_AllowAnyoneBabyImprintCuddle=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('FSE_BabyCuddleGracePeriodMultiplier=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('FSE_BabyCuddleIntervalMultiplier=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('FSE_BabyCuddleLoseImprintQualitySpeedMultiplier=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('FSE_BabyFoodConsumptionSpeedMultiplier=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('FSE_BabyImprintAmountMultiplier=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('FSE_BabyImprintingStatScaleMultiplier=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('FSE_BabyMatureSpeedMultiplier=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('FSE_EggHatchSpeedMultiplier=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('FSE_LayEggIntervalMultiplier=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('FSE_MatingIntervalMultiplier=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('FSE_MatingSpeedMultiplier=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');

  // Dino-TamedDino-TamedDino
  sl.Add('ChB_AllowRaidDinoFeeding=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('ChB_PreventMateBoost=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('ChB_DisableImprintDinoBuff=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('SE_DestroyTamesOverLevelClamp=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('FSE_RaidDinoCharacterFoodDrainMultiplier=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('FSE_DinoHarvestingDamageMultiplier=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('ChB_bFlyerPlatformAllowUnalignedDinoBasing=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('ChB_bPassiveDefensesDamageRiderlessDinos=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('FSE_TamedDinoDamageMultiplier=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('FSE_TamedDinoResistanceMultiplier=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('FSE_TamedDinoCharacterFoodDrainMultiplier=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('FSE_TamedDinoTorporDrainMultiplier=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');

  // Dino-TamedDino
  sl.Add('ChB_bUseDinoLevelUpAnimations=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('FSE_DinoCharacterFoodDrainMultiplier=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('FSE_DinoCharacterHealthRecoveryMultiplier=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('SE_MaxCosmoWeaponAmmo=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');
  sl.Add('SE_CosmoWeaponAmmoReloadAmount=Tab_TamedDinoSettings,PageControl4,Tab_TamedDino');

  // Dino-WildDino-PerLevelStatsMultiplier
  sl.Add('FSE_PerLevelStatsMultiplier_DinoWild0=Tab_TamedDinoSettings,PageControl4,Tab_WildDino');
  sl.Add('FSE_PerLevelStatsMultiplier_DinoWild1=Tab_TamedDinoSettings,PageControl4,Tab_WildDino');
  sl.Add('FSE_PerLevelStatsMultiplier_DinoWild2=Tab_TamedDinoSettings,PageControl4,Tab_WildDino');
  sl.Add('FSE_PerLevelStatsMultiplier_DinoWild3=Tab_TamedDinoSettings,PageControl4,Tab_WildDino');
  sl.Add('FSE_PerLevelStatsMultiplier_DinoWild4=Tab_TamedDinoSettings,PageControl4,Tab_WildDino');
  sl.Add('FSE_PerLevelStatsMultiplier_DinoWild5=Tab_TamedDinoSettings,PageControl4,Tab_WildDino');
  sl.Add('FSE_PerLevelStatsMultiplier_DinoWild6=Tab_TamedDinoSettings,PageControl4,Tab_WildDino');
  sl.Add('FSE_PerLevelStatsMultiplier_DinoWild7=Tab_TamedDinoSettings,PageControl4,Tab_WildDino');
  sl.Add('FSE_PerLevelStatsMultiplier_DinoWild8=Tab_TamedDinoSettings,PageControl4,Tab_WildDino');
  sl.Add('FSE_PerLevelStatsMultiplier_DinoWild9=Tab_TamedDinoSettings,PageControl4,Tab_WildDino');
  sl.Add('FSE_PerLevelStatsMultiplier_DinoWild10=Tab_TamedDinoSettings,PageControl4,Tab_WildDino');

  // Dino-WildDino-PerLevelStatsMultiplier_DinoTamed_Add
  sl.Add('FSE_PerLevelStatsMultiplier_DinoTamed_Add0=Tab_TamedDinoSettings,PageControl4,Tab_WildDino');
  sl.Add('FSE_PerLevelStatsMultiplier_DinoTamed_Add1=Tab_TamedDinoSettings,PageControl4,Tab_WildDino');
  sl.Add('FSE_PerLevelStatsMultiplier_DinoTamed_Add2=Tab_TamedDinoSettings,PageControl4,Tab_WildDino');
  sl.Add('FSE_PerLevelStatsMultiplier_DinoTamed_Add3=Tab_TamedDinoSettings,PageControl4,Tab_WildDino');
  sl.Add('FSE_PerLevelStatsMultiplier_DinoTamed_Add4=Tab_TamedDinoSettings,PageControl4,Tab_WildDino');
  sl.Add('FSE_PerLevelStatsMultiplier_DinoTamed_Add5=Tab_TamedDinoSettings,PageControl4,Tab_WildDino');
  sl.Add('FSE_PerLevelStatsMultiplier_DinoTamed_Add6=Tab_TamedDinoSettings,PageControl4,Tab_WildDino');
  sl.Add('FSE_PerLevelStatsMultiplier_DinoTamed_Add7=Tab_TamedDinoSettings,PageControl4,Tab_WildDino');
  sl.Add('FSE_PerLevelStatsMultiplier_DinoTamed_Add8=Tab_TamedDinoSettings,PageControl4,Tab_WildDino');
  sl.Add('FSE_PerLevelStatsMultiplier_DinoTamed_Add9=Tab_TamedDinoSettings,PageControl4,Tab_WildDino');
  sl.Add('FSE_PerLevelStatsMultiplier_DinoTamed_Add10=Tab_TamedDinoSettings,PageControl4,Tab_WildDino');

  // Dino-WildDino
  sl.Add('FSE_WildDinoCharacterFoodDrainMultiplier=Tab_TamedDinoSettings,PageControl4,Tab_WildDino');
  sl.Add('FSE_DinoCharacterStaminaDrainMultiplier=Tab_TamedDinoSettings,PageControl4,Tab_WildDino');
  sl.Add('FSE_WildDinoTorporDrainMultiplier=Tab_TamedDinoSettings,PageControl4,Tab_WildDino');
  sl.Add('FSE_DinoDamageMultiplier=Tab_TamedDinoSettings,PageControl4,Tab_WildDino');
  sl.Add('FSE_DinoResistanceMultiplier=Tab_TamedDinoSettings,PageControl4,Tab_WildDino');
  sl.Add('FSE_DinoTurretDamageMultiplier=Tab_TamedDinoSettings,PageControl4,Tab_WildDino');
  sl.Add('FSE_TamingSpeedMultiplier=Tab_TamedDinoSettings,PageControl4,Tab_WildDino');
  sl.Add('FSE_PassiveTameIntervalMultiplier=Tab_TamedDinoSettings,PageControl4,Tab_WildDino');
  sl.Add('FSE_DinoCountMultiplier=Tab_TamedDinoSettings,PageControl4,Tab_WildDino');
  sl.Add('SE_MaxPersonalTamedDinos=Tab_TamedDinoSettings,PageControl4,Tab_WildDino');
  sl.Add('FSE_MaxTamedDinos=Tab_TamedDinoSettings,PageControl4,Tab_WildDino');
  sl.Add('FSE_OverrideBondedPassImprintMultiplier=Tab_TamedDinoSettings,PageControl4,Tab_WildDino');

  // Dino-WildDino-SoftTame
  sl.Add('ChB_DestroyTamesOverTheSoftTameLimit=Tab_TamedDinoSettings,PageControl4,Tab_WildDino');
  sl.Add('SE_MaxTamedDinos_SoftTameLimit=Tab_TamedDinoSettings,PageControl4,Tab_WildDino');
  sl.Add('SE_MaxTamedDinos_SoftTameLimit_CountdownForDeletionDuration=Tab_TamedDinoSettings,PageControl4,Tab_WildDino');

  // Structure
  sl.Add('CB_OverrideStructurePlatformPrevention=Tab_StructureSettings,0,0');
  sl.Add('FSE_PlatformSaddleBuildAreaBoundsMultiplier=Tab_StructureSettings,0,0');
  sl.Add('FSE_StructurePickupHoldDuration=Tab_StructureSettings,0,0');
  sl.Add('FSE_StructurePreventResourceRadiusMultiplier=Tab_StructureSettings,0,0');
  sl.Add('SE_TheMaxStructuresInRange=Tab_StructureSettings,0,0');
  sl.Add('ChB_AllowMultipleAttachedC4=Tab_StructureSettings,0,0');
  sl.Add('ChB_AlwaysAllowStructurePickup=Tab_StructureSettings,0,0');
  sl.Add('ChB_AllowCrateSpawnsOnTopOfStructures=Tab_StructureSettings,0,0');
  sl.Add('ChB_ForceAllStructureLocking=Tab_StructureSettings,0,0');
  sl.Add('FSE_PerPlatformMaxStructuresMultiplier=Tab_StructureSettings,0,0');
  sl.Add('FSE_StructurePickupTimeAfterPlacement=Tab_StructureSettings,0,0');
  sl.Add('FSE_StructureResistanceMultiplier=Tab_StructureSettings,0,0');
  sl.Add('FSE_StructureDamageMultiplier=Tab_StructureSettings,0,0');
  sl.Add('SE_StructureDamageRepairCooldown=Tab_StructureSettings,0,0');
  sl.Add('FSE_AutoDestroyOldStructuresMultiplier=Tab_StructureSettings,0,0');
  sl.Add('SE_MaxPlatformSaddleStructureLimit=Tab_StructureSettings,0,0');
  sl.Add('SE_MaxGateFrameOnSaddles=Tab_StructureSettings,0,0');
  sl.Add('ChB_bAllowPlatformSaddleMultiFloors=Tab_StructureSettings,0,0');

  // Structure-Turret
  sl.Add('ChB_bHardLimitTurretsInRange=Tab_StructureSettings,0,0');
  sl.Add('ChB_bLimitTurretsInRange=Tab_StructureSettings,0,0');
  sl.Add('SE_LimitTurretsNum=Tab_StructureSettings,0,0');
  sl.Add('FSE_LimitTurretsRange=Tab_StructureSettings,0,0');


  // Engrams
  sl.Add('FSE_CraftingSkillBonusMultiplier=Tab_Engrams,0,0');
  sl.Add('FSE_CustomRecipeEffectivenessMultiplier=Tab_Engrams,0,0');
  sl.Add('FSE_CustomRecipeSkillMultiplier=Tab_Engrams,0,0');
  sl.Add('FSE_SupplyCrateLootQualityMultiplier=Tab_Engrams,0,0');
  sl.Add('FSE_FishingLootQualityMultiplier=Tab_Engrams,0,0');
  sl.Add('ChB_OnlyAllowSpecifiedEngrams=Tab_Engrams,0,0');
  sl.Add('ChB_bAllowCustomRecipes=Tab_Engrams,0,0');
  sl.Add('ChB_bAutoUnlockAllEngrams=Tab_Engrams,0,0');

  // Engrams-Cryopod
  sl.Add('ChB_AllowCryoFridgeOnSaddle=Tab_Engrams,0,0');
  sl.Add('ChB_DisableCryopodEnemyCheck=Tab_Engrams,0,0');
  sl.Add('ChB_DisableCryopodFridgeRequirement=Tab_Engrams,0,0');
  sl.Add('SE_CryopodFridgeCooldowntime=Tab_Engrams,0,0');
  sl.Add('ChB_EnableCryopodNerf=Tab_Engrams,0,0');
  sl.Add('ChB_EnableCryoSicknessPVE=Tab_Engrams,0,0');
  sl.Add('FSE_CryopodNerfDamageMult=Tab_Engrams,0,0');
  sl.Add('FSE_CryopodNerfDuration=Tab_Engrams,0,0');
  sl.Add('FSE_CryopodNerfIncomingDamageMultPercent=Tab_Engrams,0,0');

  // XP
  sl.Add('FSE_XPMultiplier=Tab_XP,0,0');
  sl.Add('FSE_GenericXPMultiplier=Tab_XP,0,0');
  sl.Add('FSE_CraftXPMultiplier=Tab_XP,0,0');
  sl.Add('FSE_HarvestXPMultiplier=Tab_XP,0,0');
  sl.Add('FSE_SpecialXPMultiplier=Tab_XP,0,0');
  sl.Add('FSE_ExplorerNoteXPMultiplier=Tab_XP,0,0');
  sl.Add('FSE_KillXPMultiplier=Tab_XP,0,0');
  sl.Add('FSE_BossKillXPMultiplier=Tab_XP,0,0');
  sl.Add('FSE_CaveKillXPMultiplier=Tab_XP,0,0');
  sl.Add('FSE_WildKillXPMultiplier=Tab_XP,0,0');
  sl.Add('FSE_TamedKillXPMultiplier=Tab_XP,0,0');
  sl.Add('FSE_UnclaimedKillXPMultiplier=Tab_XP,0,0');
  sl.Add('FSE_AlphaKillXPMultiplier=Tab_XP,0,0');

  // iniFiles-GameUserSettings.ini
  sl.Add('Memo_GameUserSettings=Tab_IniFiles,PageControl6,Tab_GameUserSettingsini');
  sl.Add('ChB_GUS_Override=Tab_IniFiles,PageControl6,Tab_GameUserSettingsini');
  sl.Add('Memo_GameUserSettings_Override=Tab_IniFiles,PageControl6,Tab_GameUserSettingsini');
  sl.Add('ChB_GUS_Append=Tab_IniFiles,PageControl6,Tab_GameUserSettingsini');
  sl.Add('Memo_GameUserSettings_Append=Tab_IniFiles,PageControl6,Tab_GameUserSettingsini');

  // iniFiles-GameUserSettings.ini
  sl.Add('Memo_GameIni=Tab_IniFiles,PageControl6,Tab_Gameini');
  sl.Add('ChB_GS_Override=Tab_IniFiles,PageControl6,Tab_Gameini');
  sl.Add('Memo_GameIni_Override=Tab_IniFiles,PageControl6,Tab_Gameini');
  sl.Add('ChB_GS_Append=Tab_IniFiles,PageControl6,Tab_Gameini');
  sl.Add('Memo_GameIni_Append=Tab_IniFiles,PageControl6,Tab_Gameini');

  // End_End_End
  sl.Add('End_End_End=Tab_End,0,0');

finalization
  sl.Free;

end.


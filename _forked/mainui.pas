unit mainui;

{$mode objfpc}{$H+}

interface

uses
  tracetime, discord,
  asaUtils, nbprocesswin,
  Windows, LCLType,
  frameui, aboutui, findui, importui, MessageTrans,
  FileUtil, LCLTranslator, IniFiles,
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ComCtrls,
  ExtCtrls, AsyncProcess, Menus;

type

  TPageControl = class(ComCtrls.TPageControl)
  private
    SVActiveIDX : integer;
    procedure CNDrawItem(var Message: TWMDrawItem); message WM_DRAWITEM;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  end;


  { TAsa_ui }

  TAsa_ui = class(TForm)
    AsyncProcess: TAsyncProcess;
    Button_CacheUpdate: TButton;
    Button_Find: TButton;
    Button_About: TButton;
    DelSrv: TButton;
    Edit_Find: TEdit;
    Lbl_ver_val: TLabel;
    NewSrv: TButton;
    Pnl_About_Focus: TPanel;
    Pnl_CacheUpdate_Focus: TPanel;
    Pnl_Find: TPanel;
    ServerPage: TPageControl;
    Timer_SvrStsChk: TTimer;
    Timer_FirstPage: TTimer;
    TrayIcon_ASASM: TTrayIcon;
    procedure Button_AboutClick(Sender: TObject);
    procedure Button_CacheUpdateClick(Sender: TObject);
    procedure Button_FindClick(Sender: TObject);
    procedure DelSrvClick(Sender: TObject);
    procedure Edit_FindEnter(Sender: TObject);
    procedure Edit_FindExit(Sender: TObject);
    procedure Edit_FindKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure NewSrvClick(Sender: TObject);
    procedure Pnl_FindClick(Sender: TObject);
    procedure ServerPageChange(Sender: TObject);
    procedure ServerPageChanging(Sender: TObject; var AllowChange: Boolean);
    procedure Timer_FirstPageTimer(Sender: TObject);
    procedure Timer_SvrStsChkTimer(Sender: TObject);
    procedure TrayIcon_ArkestraClick(Sender: TObject);
  private
    LastASASMPath   : string;
    unuse_bat       : boolean;
    UseBuiltinRCON  : boolean;
    DebugUpdate     : boolean;
    OldModList      : boolean;
    ARKestra        : boolean;
    DisableSteamcmdSharing:boolean;
    EnableShareUpdate:boolean;
    ASASMFullStartup:boolean;
    bServerCMD   :boolean;
    UseBetaASASM :boolean;
    HiddenTabs   : string;
    DiscordAdmHookKind: string;
    DiscordAdmHookURL : string;
    DiscordAdmHookName: string;
    TrayNotificationKind: string;
    TrayNotificationName: string;
    ACloseAction :TCloseAction;
    iLastSvrStsChk:integer;
    iLastNewVerChk:integer;
    NotificationKind: array [0..2,0..9] of boolean;
    procedure SaveAllIniFile;
    procedure ServerPageCreate(idx:integer);
    procedure SystemVersionCheck;
  public
    BusyFlg : boolean;
    StrongClean:boolean;
    SvrDelVisible:boolean;
    CountCreateSec:boolean;
    bVerChkInterval:boolean;
    iVerChkInterval:integer;
    iNewBuildID:integer;
  end;

var
  ActiveTabColor :DWORD;
  ProfileTabColor:DWORD;
  FocusColor     :DWORD;
  DarkMode       :boolean;
  AppVer :string;
  BuildVer :integer;
  Buildver_Old:integer;
  Asa_ui: TAsa_ui;

implementation

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
    DrawTextEx(hDC, PChar(Page[itemID].Caption), -1, rcItem, DT_CENTER or
      DT_VCENTER or DT_SINGLELINE, nil);
  end;
  Message.Result := 1;
end;

{ TAsa_ui }

procedure TAsa_ui.NewSrvClick(Sender: TObject);
var
  i :integer;
  newtab :TTabSheet;
  newsheet:TAsaFrame;
  targetPath,
  targetBat,
  targetProfile : string;
  sl :TStringList;
  str,
  sDir,sName1,sName2,
  serverPlayer:string;
  srcPath,
  dstPath:string;
  procedure sub_FlgsSetup;
  begin
    newsheet.Parent := newtab;
    newsheet.SetTrans;
    newsheet.AppVer         :=AppVer;
    newsheet.StrongClean    :=StrongClean;
    newsheet.DarkMode       :=DarkMode;
    newsheet.unuse_bat      :=unuse_bat;
    newsheet.FocusColor     :=FocusColor;
    newsheet.ActiveTabColor :=ProfileTabColor;
    newsheet.UseBuiltinRCON :=UseBuiltinRCON;
    newsheet.DebugUpdate    :=DebugUpdate;
    newsheet.OldModList     :=OldModList;
    newsheet.DisableSteamcmdSharing:=DisableSteamcmdSharing;
    newsheet.EnableShareUpdate:=EnableShareUpdate;
    newsheet.ARKestra       :=ARKestra;
    newsheet.HiddenTabs     :=HiddenTabs;
    newsheet.DiscordAdmHookKind:=DiscordAdmHookKind;
    newsheet.DiscordAdmHookURL :=DiscordAdmHookURL;
    newsheet.DiscordAdmHookName:=DiscordAdmHookName;
    newsheet.bServerCMD     :=bServerCMD;
    newsheet.iNewBuildID    :=iNewBuildID;
    newsheet.TrayIcon_ASASM :=TrayIcon_ASASM;
    newsheet.TrayNotificationKind:=TrayNotificationKind;
    newsheet.TrayNotificationName:=TrayNotificationName;
    newsheet.FlgsSetup;
  end;
  procedure sub_CreateIni;
  begin
    newsheet.createArgs;
    newsheet.createGUSIni;
    newsheet.createGameIni;
    newsheet.updateServerStatus;
    //newsheet.Timer_SvrStatus.Enabled:=True;
    newsheet.canEditIni := true;
  end;
  procedure sub_NewTab;
  begin
    newtab := ServerPage.AddTabSheet;
    newtab.Name:=targetProfile;
    newtab.Caption:=targetProfile;
  end;
  procedure sub_SheetSetup;
  begin
    newsheet.Align:=alClient;
    newsheet.beforeProfileName:=newtab.Name;
    newsheet.Edit_Profile.Text:=newtab.Name;
    newsheet.createDinoGrid;
  end;
  procedure sub_SetServerPage;
  begin
    ServerPage.TabIndex:=ServerPage.PageCount-1;
    ServerPage.SVActiveIDX := ServerPage.ActivePageIndex;
    ServerPage.Repaint;
  end;
const
  ServerX = 'ServerX';
  CDRIVE  = 'C:';
  LOCALPLAYER = 'LocalPlayer';
begin
  if BusyFlg then exit;
  targetProfile := ServerX;
  targetPath    := CDRIVE;

  Asa_import_ui.sProfileListComma:='';
  for i := 0 to ServerPage.PageCount-1 do
  begin
    Asa_import_ui.sProfileListComma := Asa_import_ui.sProfileListComma + ServerPage.Pages[i].Caption + ',';
  end;

  Asa_import_ui.Top:=Asa_ui.Top;
  Asa_import_ui.Left:=Asa_ui.Left;
  Asa_import_ui.ShowModal;

  if (Asa_import_ui.bGoProc) then
  begin
    Screen.Cursor:=crHourGlass;
    if (Asa_import_ui.RG_Import_proc.ItemIndex = 0) then
    begin
      // New Profile
      for i := ServerPage.PageCount + 1 to 999 do
      begin
        targetProfile := 'Server'+inttostr(i);
        if ServerPage.FindComponent(targetProfile) = nil then break;
      end;
      targetPath := ExtractFilePath(ParamStr0)+targetProfile;
      sub_NewTab;
      newsheet := TAsaFrame.Create(newtab);
      newsheet.Name:='ASAServer'+inttostr(ServerPage.PageCount-1);

      sub_FlgsSetup;
      sub_SheetSetup;

      newsheet.Edit_Install_Location_Val.Text:= targetPath;
      if Asa_import_ui.ChB_New_CopyProfile.Checked then
      begin
        srcPath := format('%sProfile\%s.ini',[ExtractFilePath(ParamStr0),Asa_import_ui.CB_ProfileName.Text]);
        dstPath := format('%s%s\ShooterGame\Saved\Profile.ini',[ExtractFilePath(ParamStr0),targetProfile]);
        if FileExists(srcPath) then
        begin
          ForceDirectories(ExtractFilePath(dstPath));
          sl := TStringList.Create;
          try
            sl.LoadFromFile(srcPath);
            sl.SaveToFile(dstPath);
          finally
            sl.Free;
          end;
        end;
        if FileExists(dstPath) then
        begin
          newsheet.flg_backup:=true;
          newsheet.loadProfile(targetProfile);
          newsheet.flg_backup:=false;
        end;
      end;
      sub_CreateIni;
      sub_SetServerPage;
    end;

    if (Asa_import_ui.RG_Import_proc.ItemIndex = 1) then
    begin
      // Import ServerData
      targetProfile := Asa_import_ui.Edit_Import_ProfileName.Text;
      targetBat     := Asa_import_ui.Edit_Import_bat_Path.Text;
      targetPath    := ExtractFileDir(Asa_import_ui.Edit_Import_Path.Text);
      sub_NewTab;
      newsheet := TAsaFrame.Create(newtab);
      newsheet.Name:='ASAServer'+inttostr(ServerPage.PageCount-1);

      sub_FlgsSetup;
      sub_SheetSetup;

      newsheet.loadProfileFromIni(targetProfile,targetPath+DIR_SHOOTERGM+DIR_CONFIG);
      newsheet.Edit_Install_Location_Val.Text:= targetPath;
      newsheet.loadArgsFromBat(targetBat);
      newsheet.CB_MapName.Text:=Asa_import_ui.CB_Import_Mapdata.Text;
      newsheet.ConditionCheck_Mods;
      sub_CreateIni;
      sub_SetServerPage;
    end;

    if (Asa_import_ui.RG_Import_proc.ItemIndex = 2) then
    begin
      // Restore Profile
      targetProfile := Asa_import_ui.CB_Restore_ProfileName.Text;
      if (targetProfile<>'') then
      begin
        i := ServerPage.PageCount;
        sub_NewTab;
        newsheet := TAsaFrame.Create(newtab);
        newsheet.Name:='ASAServer'+inttostr(i-1);

        sub_FlgsSetup;

        newsheet.Align:=alClient;
        newsheet.createDinoGrid;
        newsheet.loadProfile(targetProfile);
        newsheet.ConditionCheck_Mods;
        sub_CreateIni;
        sub_SetServerPage;
      end;
    end;

    if (Asa_import_ui.RG_Import_proc.ItemIndex = 3) then
    begin
      begin
        srcPath := Asa_import_ui.Edit_Convert_Path.Text                         +DIR_SAVEDARKL;
        dstPath := Asa_import_ui.Edit_Convert_InstallLocation.Text+DIR_SHOOTERGM+DIR_SAVEDARK;
        CopyDirTree(srcPath,dstPath,[cffOverwriteFile,cffCreateDestDirectory,cffPreserveTime]);
      end;
      begin
        srcPath := Asa_import_ui.Edit_Convert_Path.Text                         +DIR_SAVEGAME;
        dstPath := Asa_import_ui.Edit_Convert_InstallLocation.Text+DIR_SHOOTERGM+DIR_SAVEGAME;
        CopyDirTree(srcPath,dstPath,[cffOverwriteFile,cffCreateDestDirectory,cffPreserveTime]);
      end;
      if DirectoryExists(Asa_import_ui.Edit_Convert_Path.Text+DIR_USER) then
      begin
        serverPlayer := '';
        sl := FindAllFiles(Asa_import_ui.Edit_Convert_Path.Text+DIR_USER+'\', FILTER_EXT_SAV, false);
        try
          for i := 0 to sl.Count -1 do
          begin
            str := ExtractFileName(sl[i]);
            if (pos(FILTER_EXT_ONL_SAV,str)<>0) then
            begin
              serverPlayer := stringReplace(str,FILTER_EXT_ONL_SAV,'',[rfReplaceAll, rfIgnoreCase]);
              break;
            end;
          end;
        finally
          sl.Free;
        end;
        if (serverPlayer<>'') then
        begin
          sl := FindAllDirectories(Asa_import_ui.Edit_Convert_InstallLocation.Text+DIR_SHOOTERGM+DIR_SAVEDARK,false);
          try
            for i := 0 to sl.Count -1 do
            begin
              sDir  := sl[i]+'\';
              sName1:= sDir + LOCALPLAYER  + EXT_ARLPROFILE;
              sName2:= sDir + serverPlayer + EXT_ARLPROFILE;
              if FileExists(sName1) then RenameFile(sName1,sName2);
            end;
          finally
            sl.Free;
          end;
        end;
      end;

      sl := TStringList.Create;
      try
        ForceDirectories(Asa_import_ui.Edit_Convert_InstallLocation.Text+DIR_CONFIG);
        begin
          sl.Clear;
          sl.LoadFromFile(Asa_import_ui.Edit_Convert_Path.Text                       +DIR_CONFIGL+'\'+FILE_GUSINI);
          sl.SaveToFile(Asa_import_ui.Edit_Convert_InstallLocation.Text+DIR_SHOOTERGM+DIR_CONFIG +'\'+FILE_GUSINI);
        end;
        begin
          sl.Clear;
          sl.LoadFromFile(Asa_import_ui.Edit_Convert_Path.Text                       +DIR_CONFIGL+'\'+FILE_GAMEINI);
          sl.SaveToFile(Asa_import_ui.Edit_Convert_InstallLocation.Text+DIR_SHOOTERGM+DIR_CONFIG +'\'+FILE_GAMEINI);
        end;
      finally
        sl.Free;
      end;
      begin
        // Import ServerData
        targetProfile := Asa_import_ui.Edit_Convert_ProfileName.Text;
        targetBat     := '';
        targetPath    := Asa_import_ui.Edit_Convert_InstallLocation.Text;
        sub_NewTab;
        newsheet := TAsaFrame.Create(newtab);
        newsheet.Name:='ASAServer'+inttostr(ServerPage.PageCount-1);

        sub_FlgsSetup;
        sub_SheetSetup;

        newsheet.loadProfileFromIni(targetProfile,targetPath+DIR_SHOOTERGM+DIR_CONFIG);
        newsheet.Edit_Install_Location_Val.Text:= targetPath;
        newsheet.loadArgsFromBat(targetBat);
        newsheet.CB_MapName.Text:=Asa_import_ui.CB_Convert_Mapdata.Text;
        newsheet.ConditionCheck_Mods;
        sub_CreateIni;
        sub_SetServerPage;
      end;
    end;
    Screen.Cursor:=crDefault;
  end;
end;

procedure TAsa_ui.Pnl_FindClick(Sender: TObject);
begin
  Edit_Find.SetFocus;
end;

procedure TAsa_ui.ServerPageChange(Sender: TObject);
begin
  ServerPageCreate(ServerPage.ActivePageIndex);
  Screen.Cursor:=crDefault;
end;

procedure TAsa_ui.ServerPageChanging(Sender: TObject; var AllowChange: Boolean);
begin
  AllowChange := true;
end;

procedure TAsa_ui.ServerPageCreate(idx:integer);
var
  newsheet:TAsaFrame;
begin
  ClearTraceResult;
  if (ServerPage.Pages[idx].ControlCount = 0) then
  begin
    Screen.Cursor:=crHourGlass;
    {}StopTrace('st_');StartTrace('Crt');
    newsheet       := TAsaFrame.Create(ServerPage.Pages[idx]);
    {}StopTrace('Crt');StartTrace('Cr2');
    newsheet.Name  :='ASAServer'+inttostr(idx);
    {}StopTrace('Cr2');StartTrace('Cr3');
    //newsheet.Parent:= ServerPage.Pages[idx];
    //newsheet.Align :=alClient;
    {}StopTrace('Cr3');StartTrace('Trn');
    newsheet.SetTrans;
    {}StopTrace('Trn');StartTrace('Flg');

    // flags
    newsheet.AppVer         :=AppVer;
    newsheet.StrongClean    :=StrongClean;
    newsheet.DarkMode       :=DarkMode;
    newsheet.unuse_bat      :=unuse_bat;
    newsheet.FocusColor     :=FocusColor;
    newsheet.ActiveTabColor :=ProfileTabColor;
    newsheet.UseBuiltinRCON :=UseBuiltinRCON;
    newsheet.DebugUpdate    :=DebugUpdate;
    newsheet.OldModList     :=OldModList;
    newsheet.DisableSteamcmdSharing:=DisableSteamcmdSharing;
    newsheet.EnableShareUpdate:=EnableShareUpdate;
    newsheet.ARKestra       :=ARKestra;
    newsheet.HiddenTabs     :=HiddenTabs;
    newsheet.DiscordAdmHookKind:=DiscordAdmHookKind;
    newsheet.DiscordAdmHookURL :=DiscordAdmHookURL;
    newsheet.DiscordAdmHookName:=DiscordAdmHookName;
    newsheet.bServerCMD     :=bServerCMD;
    newsheet.iNewBuildID    :=iNewBuildID;
    newsheet.TrayIcon_ASASM :=TrayIcon_ASASM;
    newsheet.TrayNotificationKind:=TrayNotificationKind;
    newsheet.TrayNotificationName:=TrayNotificationName;
    newsheet.FlgsSetup;
    {}StopTrace('Flg');StartTrace('Pr1');

    // frame init
    newsheet.createDinoGrid;
    {}StopTrace('Pr1');StartTrace('Ldp');
    newsheet.loadProfile(ServerPage.Pages[idx].Caption);
    {}StopTrace('Ldp');StartTrace('Cck');
    newsheet.ConditionCheck_Mods;
    {}StopTrace('Cck');StartTrace('Arg');
    newsheet.createArgs;
    {}StopTrace('Arg');StartTrace('GUS');
    newsheet.createGUSIni;
    {}StopTrace('GUS');StartTrace('GME');
    newsheet.createGameIni;
    {}StopTrace('GME');
    newsheet.updateServerStatus;
    {}StartTrace('Tmr');
    //newsheet.Timer_SvrStatus.Enabled:=True;
    {}StopTrace('Tmr');StartTrace('Pr2');
    newsheet.canEditIni := true;
    {}StopTrace('Pr2');StartTrace('Pr3');

    {}newsheet.Parent:= ServerPage.Pages[idx];
    {}newsheet.Align :=alClient;
    {}StopTrace('Pr3');

    if CountCreateSec then ShowTraceResult;
    ClearTraceResult;
  end;
end;

procedure TAsa_ui.Timer_FirstPageTimer(Sender: TObject);
var
  i :integer;
begin
  Timer_FirstPage.Enabled:=False;
  while (BusyFlg) do
  begin
    sleep(200);
    application.ProcessMessages;
  end;
  BusyFlg := true;
  begin
    if ASASMFullStartup then
    begin
      Screen.Cursor:=crHourGlass;
      for i := 0 to ServerPage.PageCount -1 do
      begin
        ServerPageCreate(i);
      end;
      Screen.Cursor:=crDefault;
    end else begin
      if (ServerPage.PageCount > 0) then
      begin
        ServerPageChange(Sender);
      end;
    end;
  end;

  iLastSvrStsChk := GetTickCount64 -500 -1000 * iVerChkInterval;
  iLastNewVerChk := iLastSvrStsChk;
  Timer_SvrStsChk.Enabled := true;

  if (length(ParamStr0) >= 70) then
  begin
    showmessage('ASASMの起動PATHが長いため、ASAサーバーの動作に支障をきたす可能性があります');
  end;
  if (length(ParamStr0)*2 > ByteLength(UnicodeString(ParamStr0))) then
  begin
    showmessage('ASASMの起動PATHに日本語が含まれるため、ASAサーバーの動作に支障をきたす可能性があります');
  end;
  if (LastASASMPath <> ParamStr0) and (ServerPage.PageCount > 0) then
  begin
    showmessage('前回のASASM起動から起動PATHが変更されてます'+LineEnding+'各プロファイルのInstall Locationが正しいか確認してください');
  end;
  BusyFlg := false;
end;

procedure TAsa_ui.Timer_SvrStsChkTimer(Sender: TObject);
var
  iTickNow:integer;
  Tabsheet :TAsaFrame;
  i        :Integer;
begin
  iTickNow := GetTickCount64;
  Timer_SvrStsChk.Enabled := false;
  try
    if (iTickNow > (iLastSvrStsChk + 1000)) then
    begin
      for i:= 0 to ServerPage.PageCount -1 do
      begin
        if (ServerPage.Pages[i].ControlCount >= 1) then
        begin
          Tabsheet := TAsaFrame(ServerPage.Pages[i].Controls[0]);
          Tabsheet.Timer_SvrStatusTimer(Tabsheet.Timer_SvrStatus);
        end;
      end;
      iLastSvrStsChk := GetTickCount64;
    end;
    if bVerChkInterval and (iTickNow > (iLastNewVerChk + 1000 * iVerChkInterval)) then
    begin
      SystemVersionCheck;
      iLastNewVerChk := GetTickCount64;
    end;
  finally
    Timer_SvrStsChk.Enabled := true;
  end;
end;

procedure TAsa_ui.SystemVersionCheck;
const
  URL_INFO      = 'https://drive.usercontent.google.com/download?id=1-6TpKBqd5as6RCDqKn-hAVWBHXsNGC_A';
  URL_INFO_BETA = 'https://drive.usercontent.google.com/download?id=15VIQV6TnBhqI2KTWWAR4oDazwmkXOT7t';
var
  iBuildVer_Self : integer;
  iBuildVer_GDrv : integer;
  sURL_Info :string;
  isBeta  :boolean;
  ini :TIniFile;
  rtnstr:string;
  sl :TStringList;
  sl2:TStringList;
  i  :integer;
  str:string;
  sVer_Self :string;
  sVer_Gdrv :string;
  ASASMVer:TAsasmVersion;
  OldTitleBarString:string;
  NewTitleBarString:string;
  SteamCmdPath:string;
  command :string;
  flg1,flg2:boolean;
  sTemp :string;
  sNewBuildID:string;
  sOldBuildID:string;
  Tabsheet :TAsaFrame;
  SteamACFPath:string;
  iOldBuildID: integer;

  function GetCmdFullPath:string;
  var
    TergetPath:string;
  begin
    TergetPath := ExpandFileName(ExtractFilePath(ParamStr(0))+'steamcmd/steamcmd.exe');
    if FileExists(TergetPath) then
    begin
      result := TergetPath;
    end else begin
      result := '';
    end;
  end;

  procedure Discord_ASASM(sVer:string);
  var
    discord_hook : TDiscord_Webhook;
  begin
    if (NotificationKind[0,4]) then
    begin
      discord_hook := TDiscord_Webhook.Create;
      try
        discord_hook.SetURL(DiscordAdmHookURL);
        discord_hook.SetNewASASMMessage(DiscordAdmHookName,sVer);
        discord_hook.send;
      finally
        discord_hook.Free;
      end;
    end;
    if (NotificationKind[2,4]) then
    begin
      TrayIcon_ASASM.Visible:=true;
      TrayIcon_ASASM.BalloonTitle:=format('%s: ASASM new version arrived',[TrayNotificationName]);
      TrayIcon_ASASM.BalloonHint :=format('Ver: %s',[sVer]);
      TrayIcon_ASASM.ShowBalloonHint;
    end;
  end;

  procedure Discord_ServerApp(sVer:string);
  var
    discord_hook : TDiscord_Webhook;
  begin
    if (NotificationKind[0,5]) then
    begin
      discord_hook := TDiscord_Webhook.Create;
      try
        discord_hook.SetURL(DiscordAdmHookURL);
        discord_hook.SetNewServerAppMessage(DiscordAdmHookName,sVer);
        discord_hook.send;
      finally
        discord_hook.Free;
      end;
    end;
    if (NotificationKind[2,5]) then
    begin
      TrayIcon_ASASM.Visible:=true;
      TrayIcon_ASASM.BalloonTitle:=format('%s: ServerApp new version arrived',[TrayNotificationName]);
      TrayIcon_ASASM.BalloonHint :=format('BuildID: %s',[sVer]);
      TrayIcon_ASASM.ShowBalloonHint;
    end;
  end;

begin
  OldTitleBarString := Asa_ui.Caption;
  if EnableShareUpdate then Button_CacheUpdate.Enabled := false;
  try
    // ASASM Ver.
    begin
      Asa_ui.Caption := OldTitleBarString + ' >>> [ASASM]Checking new version...';

      iBuildVer_GDrv := 0;
      isBeta := false;
      sURL_Info := URL_INFO;
      ini := TIniFile.Create('AsaServerManegerWin.ini');
      try
        isBeta := ini.ReadBool  ('ASASM_Updater','BetaBranch',false);
        if isBeta then
        begin
          sURL_Info := ini.ReadString('ASASM_Updater','BetaBranchURL_INFO',URL_INFO_BETA);
        end;
      finally
        ini.Free;
      end;
      rtnstr := AsyncGet(sURL_Info);
      sl := TStringList.Create;
      sl2:= TStringList.Create;
      try
        sl.Text:=rtnstr;
        for i := 0 to sl.Count -1 do
        begin
          if i = 0 then
          begin
            str := sl.Strings[i];
            str := StringReplace(str,'.',',',[rfReplaceAll]);
            sl2.CommaText:=str;
            if (sl2.Count >= 4) then
            begin
              iBuildVer_GDrv:=StrToIntDef(sl2[3],0);
              sVer_Gdrv := format('%s.%S.%s.%s',[sl2[0],sl2[1],sl2[2],sl2[3]]);
            end;
          end;
        end;
      finally
        sl.Free;
        sl2.Free;
      end;

      ASASMVer := GetASASMVersion;
      iBuildVer_Self := ASASMVer.FileVersion[3];
      sVer_Self := format('%d.%d.%d.%d',[ASASMVer.FileVersion[0],
                                         ASASMVer.FileVersion[1],
                                         ASASMVer.FileVersion[2],
                                         ASASMVer.FileVersion[3]]);

      if (iBuildVer_Self < iBuildVer_GDrv) then
      begin
        NewTitleBarString:=Format('ASA Server Maneger (ASASM):Ver.%s >>> (ASASM):Ver.%s new update has arrived.',[sVer_Self,sVer_Gdrv]);
        Discord_ASASM(format('%s >>> %s',[sVer_Self,sVer_Gdrv]));
        Button_About.Hint := format('ASASM new version arrived: Ver: %s >>> %s',[sVer_Self,sVer_Gdrv]);
        Pnl_About_Focus.Visible:=true;
        Asa_about_ui.Pnl_About_Focus.Visible:=true;
      end else begin
        NewTitleBarString:=OldTitleBarString;
        Pnl_About_Focus.Visible:=false;
        Asa_about_ui.Pnl_About_Focus.Visible:=false;
      end;
    end;

    // Server Ver.
    //if false then
    begin
      Asa_ui.Caption := OldTitleBarString + ' >>> [Server App]Checking new version...';
      SteamCmdPath := GetCmdFullPath;
      sNewBuildID := '';
      if (SteamCmdPath <> '') and (FileExists(SteamCmdPath)) then
      begin
        command := format('"%s" %s',[SteamCmdPath,'+login anonymous +app_info_update 1 +app_info_print 2430930 +quit']);
        sl := TStringList.Create;
        try
          if (RunAsyncNBProcess(command,sl)) then
          begin
            flg1 := false;
            flg2 := false;
            for i := 0 to sl.Count-1 do
            begin
              sTemp := sl.Strings[i];
              if (Pos('"branches"',sTemp)<>0) then
              begin
                flg1 := true;
                flg2 := false;
              end;
              if (Pos('"public"',sTemp)<>0) then
              begin
                if flg1 then flg2 := true;
              end;
              if (Pos('"buildid"',sTemp)<>0) then
              begin
                if (flg1 and flg2) then
                begin
                  sTemp := StringReplace(sTemp,'buildid','',[rfReplaceAll, rfIgnoreCase]);
                  sTemp := StringReplace(sTemp,#09,'',[rfReplaceAll, rfIgnoreCase]);
                  sTemp := StringReplace(sTemp,#20,'',[rfReplaceAll, rfIgnoreCase]);
                  sTemp := StringReplace(sTemp,'"','',[rfReplaceAll, rfIgnoreCase]);
                  sNewBuildID := sTemp;
                  break;
                end;
              end;
            end;
          end;
        finally
          sl.Free;
        end;
      end;
      if (sNewBuildID <> '') then
      begin
        iNewBuildID := StrToIntDef(sNewBuildID,0);

        for i:= 0 to ServerPage.PageCount -1 do
        begin
          if (ServerPage.Pages[i].ControlCount >= 1) then
          begin
            Tabsheet := TAsaFrame(ServerPage.Pages[i].Controls[0]);
            Tabsheet.iNewBuildID:=iNewBuildID;
          end;
        end;

        if EnableShareUpdate then
        begin
          Pnl_CacheUpdate_Focus.Visible:=false;
          SteamACFPath := ExtractFileDir(ParamStr0)+'\Profile\UpdateChache\steamapps\appmanifest_2430930.acf';

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
          if (iOldBuildID < iNewBuildID) then
          begin
            Discord_ServerApp(format('%s >>> %s',[sOldBuildID,sNewBuildID]));
            Button_CacheUpdate.Hint := format('ServerAPP new version arrived: BuildID: %s >>> %s',[sOldBuildID,sNewBuildID]);
            Pnl_CacheUpdate_Focus.Visible:=true;
          end else begin
            Button_CacheUpdate.Hint := '';
            Pnl_CacheUpdate_Focus.Visible:=false;
          end;
        end;
      end;
    end;
  finally
    if EnableShareUpdate then Button_CacheUpdate.Enabled := true;
    Asa_ui.Caption:=NewTitleBarString;
  end;
end;

procedure TAsa_ui.TrayIcon_ArkestraClick(Sender: TObject);
begin
  if self.Visible then
  begin
    if (not Asa_about_ui.Visible) and (not Asa_import_ui.Visible) and (not SvrDelVisible) then
    begin
      self.Hide;
    end;
  end else begin
    self.Show;
  end;
end;

procedure TAsa_ui.FormCreate(Sender: TObject);
var
  ini :TIniFile;
  i :integer;
  cnt:Integer;
  newtab :TTabSheet;
  H,W:integer;
  tergetProfile :string;
  langpos : integer;
  r,g,b : integer;
  sl :TStringList;
begin
  DefaultFormatSettings.DecimalSeparator := '.';
  BusyFlg := false;
  SvrDelVisible := false;
  ACloseAction := caHide;
  Application.Title:='ASA Server Maneger (ASASM)';

  ini := TIniFile.Create(ASASMINI);
  try
    LastASASMPath     :=    ini.ReadString('mainui','LastASASMPath',ParamStr0);
    unuse_bat         :=    ini.ReadBool('mainui','Unuse_bat'         ,False);
    Buildver_Old      :=    ini.ReadInteger('mainui','BuildVer',0);

    r                 :=    ini.ReadInteger('mainui','ActiveTabColor_R',249);
    g                 :=    ini.ReadInteger('mainui','ActiveTabColor_G',203);
    b                 :=    ini.ReadInteger('mainui','ActiveTabColor_B',156);
    ActiveTabColor    :=    RGB(r,g,b);
    aboutui.Asa_about_ui.ColorButton_ActiveTabColor.ButtonColor:=ActiveTabColor;

    r                 :=    ini.ReadInteger('mainui','ProfileTabColor_R',217);
    g                 :=    ini.ReadInteger('mainui','ProfileTabColor_G',234);
    b                 :=    ini.ReadInteger('mainui','ProfileTabColor_B',211);
    ProfileTabColor   :=    RGB(r,g,b);
    aboutui.Asa_about_ui.ColorButton_ProfActiveTabColor.ButtonColor:=ProfileTabColor;

    r                 :=    ini.ReadInteger('mainui','FocusColor_R',255);
    g                 :=    ini.ReadInteger('mainui','FocusColor_G',255);
    b                 :=    ini.ReadInteger('mainui','FocusColor_B',  0);
    FocusColor        :=    RGB(r,g,b);
    aboutui.Asa_about_ui.ColorButton_FocusColor.ButtonColor:=FocusColor;

    UseBuiltinRCON    :=    ini.ReadBool('mainui','UseBuiltinRCON'    ,False);
    aboutui.Asa_about_ui.ChB_Use_builtin_RCON.Checked:=UseBuiltinRCON;

    DebugUpdate       :=    ini.ReadBool('mainui','DebugUpdate'      ,False);
    aboutui.Asa_about_ui.ChB_SvrUpd_Debug.Checked:=DebugUpdate;

    OldModList        :=    ini.ReadBool('mainui','OldModList'       ,False);
    aboutui.Asa_about_ui.ChB_OldModList.Checked:=OldModList;

    DisableSteamcmdSharing:=ini.ReadBool('mainui','DisableSteamcmdSharing',False);
    aboutui.Asa_about_ui.ChB_DisableSteamcmdSharing.Checked:=DisableSteamcmdSharing;

    EnableShareUpdate:=     ini.ReadBool('mainui','EnableShareUpdate',False);
    aboutui.Asa_about_ui.ChB_EnableShareUpdate.Checked:=EnableShareUpdate;
    Button_CacheUpdate.Enabled:=EnableShareUpdate;

    ASASMFullStartup :=     ini.ReadBool('mainui','ASASMFullStartup',False);
    aboutui.Asa_about_ui.ChB_ASASMFullStartup.Checked:=ASASMFullStartup;

    StrongClean      :=     ini.ReadBool('mainui','Strong_CleanUpdate',False);
    aboutui.Asa_about_ui.ChB_StrongClean.Checked:=StrongClean;

    DarkMode         :=     ini.ReadBool('mainui','DarkMode',False);
    aboutui.Asa_about_ui.ChB_DarkMode.Checked:=DarkMode;
    if DarkMode then Pnl_Find.Color := RGB(42,42,42);

    bServerCMD       :=     ini.ReadBool('mainui','bServerCMD',True);

    bVerChkInterval  :=     ini.ReadBool('mainui','bVerChkInterval',False);
    iVerChkInterval  :=     ini.ReadInteger('mainui','iVerChkInterval',1800);
    aboutui.Asa_about_ui.ChB_VerChkInterval.Checked:=bVerChkInterval;
    aboutui.Asa_about_ui.SE_VerChkInterval.Value   :=iVerChkInterval;

    UseBetaASASM     :=     ini.ReadBool('ASASM_Updater','BetaBranch',False);
    aboutui.Asa_about_ui.ChB_USeBeta.Checked:=UseBetaASASM;

    begin
      HiddenTabs := ini.ReadString('mainui','HiddenTabs','0,0,0,0,0,0,0,0,0,0,0');
      sl := TStringList.Create;
      try
        sl.CommaText:=HiddenTabs;
        for i := 0 to sl.Count-1 do
        begin
          if (sl.Strings[i] = '1') then
          begin
            aboutui.Asa_about_ui.CG_Hiddentabs.Checked[i] := true;
          end;
        end;
      finally
        sl.Free;
      end;
    end;

    begin
      DiscordAdmHookURL       := ini.ReadString('Discord','Hook_Admin_URL'      ,'');
      aboutui.Asa_about_ui.Edit_DiscordHook_Admin_URL.Text       := DiscordAdmHookURL;

      DiscordAdmHookName := ini.ReadString('Discord','Hook_Admin_ASASMNAME','ASASM');
      aboutui.Asa_about_ui.Edit_DiscordHook_Admin_ASASMNAME.Text := DiscordAdmHookName;

      DiscordAdmHookKind := ini.ReadString('Discord','Hook_Admin_Kind','0,0,0,0,0,0,0,0');
      sl := TStringList.Create;
      try
        sl.CommaText:=DiscordAdmHookKind;
        cnt := sl.Count;
        if (cnt > aboutui.Asa_about_ui.CG_DiscordHook_Admin_Kind.Items.Count) then cnt := aboutui.Asa_about_ui.CG_DiscordHook_Admin_Kind.Items.Count;
        for i := 0 to cnt-1 do
        begin
          if (sl.Strings[i] = '1') then
          begin
            aboutui.Asa_about_ui.CG_DiscordHook_Admin_Kind.Checked[i] := true;
          end;
          if (sl.Strings[i] = '1') then NotificationKind[0,i] := true
                                   else NotificationKind[0,i] := false;
        end;
      finally
        sl.Free;
      end;
    end;

    begin
      TrayNotificationName := ini.ReadString('TrayNotification','TrayNotificationName','ASASM');
      aboutui.Asa_about_ui.Edit_TrayNotification_ASASMNAME.Text := TrayNotificationName;

      TrayNotificationKind := ini.ReadString('TrayNotification','TrayNotificationKind','0,0,0,0,0,0,0,0');
      sl := TStringList.Create;
      try
        sl.CommaText:=TrayNotificationKind;
        cnt := sl.Count;
        if (cnt > aboutui.Asa_about_ui.CG_TrayNotification_Kind.Items.Count) then cnt := aboutui.Asa_about_ui.CG_TrayNotification_Kind.Items.Count;
        for i := 0 to cnt-1 do
        begin
          if (sl.Strings[i] = '1') then
          begin
            aboutui.Asa_about_ui.CG_TrayNotification_Kind.Checked[i] := true;
          end;
          if (sl.Strings[i] = '1') then NotificationKind[2,i] := true
                                   else NotificationKind[2,i] := false;
        end;
      finally
        sl.Free;
      end;
    end;

    ARKestra          :=    ini.ReadBool('mainui','ARKestra'       ,False);
    CountCreateSec    :=    ini.ReadBool('mainui','CountCreateSec' ,False);

    H := Monitor.Height;
    W := Monitor.Width;
    self.BorderStyle:=bsSizeable;

    Asa_ui.Height     :=ini.ReadInteger('mainui','Height',720);
    Asa_ui.Width      :=ini.ReadInteger('mainui','Width',720);
    // Formのポジション・サイズが異常な場合は補正する
    if not (Asa_ui.Height >  720) then Asa_ui.Height := 720;
    if not (Asa_ui.Height <    H) then Asa_ui.Height := 720;
    if not (Asa_ui.Width  >  720) then Asa_ui.Width  := 720;
    if not (Asa_ui.Width  <    W) then Asa_ui.Width  := 720;

    Asa_ui.Left       :=ini.ReadInteger('mainui','Left',0);
    Asa_ui.Top        :=ini.ReadInteger('mainui','Top',0);
    // Formのポジション・サイズが異常な場合は補正する2
    if not (Asa_ui.Top    >    0) then Asa_ui.Top    := 0;
    if not (Asa_ui.Top    <    H) then Asa_ui.Top    := 0;
    if not (Asa_ui.Left   >    0) then Asa_ui.Left   := 0;
    if not (Asa_ui.Left   <    W) then Asa_ui.Left   := 0;

    langpos :=ini.ReadInteger('mainui','language',2);
    if langpos < 0 then langpos := 0;

    aboutui.Asa_about_ui.LangList.ItemIndex := langpos;
    SetDefaultLang(aboutui.slLangList.Values[aboutui.slLangList.Names[langpos]],ExtractFilePath(ParamStr0)+'lang');

    if OldModList and FileExists(FILE_MODLIST_OLD) then
    begin
      sl_ModList.LoadFromFile(FILE_MODLIST_OLD);
    end else begin
      if FileExists(FILE_MODLIST_NEW) then sl_ModList.LoadFromFile(FILE_MODLIST_NEW);
    end;

    cnt:= ini.ReadInteger('mainui','PageCount',0);
    ServerPage.SVActiveIDX := 0;
    for i:=0 to cnt -1 do
    begin
      Application.ProcessMessages;
      tergetProfile := ini.ReadString('Profiles','Tab'+InttoStr(i),'err'+InttoStr(i));
      newtab := ServerPage.AddTabSheet;
      newtab.Name   :=tergetProfile;
      newtab.Caption:=tergetProfile;
    end;
  finally
    ini.Free;
  end;
end;

procedure TAsa_ui.FormDestroy(Sender: TObject);
begin
end;

procedure TAsa_ui.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState
  );
begin
  if (Key = VK_F3) and (Shift = []) then
  begin
    find_ui.form:= Asa_ui;
    find_ui.Edit_Find.Text:=Edit_Find.Text;
    find_ui.Button_FindClick(Sender);
  end;
  if (Key = VK_F) and (Shift = [ssCtrl]) then
  begin
    Key := VK_UNKNOWN;
    Edit_Find.SetFocus;
  end;
end;

procedure TAsa_ui.FormShow(Sender: TObject);
var
  ASASMVer   : TAsasmVersion;
begin
  ASASMVer := GetASASMVersion;

  BuildVer := ASASMVer.FileVersion[3];
  AppVer := format('%d.%d.%d.%d',[ASASMVer.FileVersion[0],
                                  ASASMVer.FileVersion[1],
                                  ASASMVer.FileVersion[2],
                                  ASASMVer.FileVersion[3]]);

  Asa_ui.Caption:=Format('ASA Server Maneger (ASASM):Ver.%s',[AppVer]);
end;

procedure TAsa_ui.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  SaveAllIniFile;
  if BusyFlg then
  begin
    CanClose := False;
    exit;
  end;
  CanClose := True;
end;

procedure TAsa_ui.SaveAllIniFile;
var
  ini      :TIniFile;
  Tabsheet :TAsaFrame;
  i        :Integer;
  r,g,b : integer;
  sl :TStringList;
begin
  ini := TIniFile.Create(ASASMINI);
  try
    ini.WriteString ('mainui','LastASASMPath',ParamStr0);
    ini.WriteString ('mainui','Appversion'   ,AppVer);
    ini.WriteInteger('mainui','BuildVer'     ,BuildVer);
    ini.WriteInteger('mainui','language'     ,aboutui.Asa_about_ui.LangList.ItemIndex);
    ini.WriteInteger('mainui','PageCount'    ,ServerPage.PageCount);

    ActiveTabColor := aboutui.Asa_about_ui.ColorButton_ActiveTabColor.ButtonColor;
    r := red  (ActiveTabColor);
    g := Green(ActiveTabColor);
    b := Blue (ActiveTabColor);
    ini.WriteInteger('mainui','ActiveTabColor_R',r);
    ini.WriteInteger('mainui','ActiveTabColor_G',g);
    ini.WriteInteger('mainui','ActiveTabColor_B',b);

    ProfileTabColor := aboutui.Asa_about_ui.ColorButton_ProfActiveTabColor.ButtonColor;
    r := red  (ProfileTabColor);
    g := Green(ProfileTabColor);
    b := Blue (ProfileTabColor);
    ini.WriteInteger('mainui','ProfileTabColor_R',r);
    ini.WriteInteger('mainui','ProfileTabColor_G',g);
    ini.WriteInteger('mainui','ProfileTabColor_B',b);

    FocusColor     := aboutui.Asa_about_ui.ColorButton_FocusColor.ButtonColor;
    r := red  (FocusColor);
    g := Green(FocusColor);
    b := Blue (FocusColor);
    ini.WriteInteger('mainui','FocusColor_R',r);
    ini.WriteInteger('mainui','FocusColor_G',g);
    ini.WriteInteger('mainui','FocusColor_B',b);

    UseBuiltinRCON    := aboutui.Asa_about_ui.ChB_Use_builtin_RCON.Checked;
    ini.WriteBool('mainui','UseBuiltinRCON'    ,UseBuiltinRCON);

    DebugUpdate    := aboutui.Asa_about_ui.ChB_SvrUpd_Debug.Checked;
    ini.WriteBool('mainui','DebugUpdate'    ,DebugUpdate);

    OldModList     := aboutui.Asa_about_ui.ChB_OldModList.Checked;
    ini.WriteBool('mainui','OldModList'     ,OldModList);

    DisableSteamcmdSharing:=aboutui.Asa_about_ui.ChB_DisableSteamcmdSharing.Checked;
    ini.WriteBool('mainui','DisableSteamcmdSharing',DisableSteamcmdSharing);

    EnableShareUpdate:=aboutui.Asa_about_ui.ChB_EnableShareUpdate.Checked;
    ini.WriteBool('mainui','EnableShareUpdate',EnableShareUpdate);

    ASASMFullStartup:=aboutui.Asa_about_ui.ChB_ASASMFullStartup.Checked;
    ini.WriteBool('mainui','ASASMFullStartup',ASASMFullStartup);

    StrongClean:=aboutui.Asa_about_ui.ChB_StrongClean.Checked;
    ini.WriteBool('mainui','Strong_CleanUpdate',StrongClean);

    DarkMode:=aboutui.Asa_about_ui.ChB_DarkMode.Checked;
    ini.WriteBool('mainui','DarkMode',DarkMode);

    bVerChkInterval:=aboutui.Asa_about_ui.ChB_VerChkInterval.Checked;
    iVerChkInterval:=aboutui.Asa_about_ui.SE_VerChkInterval.Value;
    ini.WriteBool   ('mainui','bVerChkInterval',bVerChkInterval);
    ini.WriteInteger('mainui','iVerChkInterval',iVerChkInterval);


    UseBetaASASM:=aboutui.Asa_about_ui.ChB_USeBeta.Checked;
    ini.WriteBool('ASASM_Updater','BetaBranch',UseBetaASASM);

    begin
      sl := TStringList.Create;
      try
        for i := 0 to aboutui.Asa_about_ui.CG_Hiddentabs.Items.Count -1 do
        begin
          if aboutui.Asa_about_ui.CG_Hiddentabs.Checked[i] then sl.Add('1')
                                                           else sl.Add('0');
        end;
        ini.WriteString('mainui','HiddenTabs',sl.CommaText);
      finally
        sl.Free;
      end;
    end;

    begin
      ini.WriteString('Discord','Hook_Admin_URL'      ,aboutui.Asa_about_ui.Edit_DiscordHook_Admin_URL.Text);
      ini.WriteString('Discord','Hook_Admin_ASASMNAME',aboutui.Asa_about_ui.Edit_DiscordHook_Admin_ASASMNAME.Text);

      sl := TStringList.Create;
      try
        for i := 0 to aboutui.Asa_about_ui.CG_DiscordHook_Admin_Kind.Items.Count -1 do
        begin
          if aboutui.Asa_about_ui.CG_DiscordHook_Admin_Kind.Checked[i] then sl.Add('1')
                                                                       else sl.Add('0');
        end;
        ini.WriteString('Discord','Hook_Admin_Kind',sl.CommaText);
      finally
        sl.Free;
      end;
    end;

    begin
      ini.WriteString('TrayNotification','TrayNotificationName',aboutui.Asa_about_ui.Edit_TrayNotification_ASASMNAME.Text);

      sl := TStringList.Create;
      try
        for i := 0 to aboutui.Asa_about_ui.CG_TrayNotification_Kind.Items.Count -1 do
        begin
          if aboutui.Asa_about_ui.CG_TrayNotification_Kind.Checked[i] then sl.Add('1')
                                                                      else sl.Add('0');
        end;
        ini.WriteString('TrayNotification','TrayNotificationKind',sl.CommaText);
      finally
        sl.Free;
      end;
    end;

    Asa_ui.WindowState := wsNormal;
    ini.WriteInteger('mainui','Left'       ,Asa_ui.Left);
    ini.WriteInteger('mainui','Top'        ,Asa_ui.Top);
    ini.WriteInteger('mainui','Height'     ,Asa_ui.Height);
    ini.WriteInteger('mainui','Width'      ,Asa_ui.Width);

    ini.EraseSection('Profiles');
    for i:= 0 to ServerPage.PageCount -1 do
    begin
      ini.WriteString('Profiles','Tab'+InttoStr(i),ServerPage.Pages[i].Caption);
    end;
    for i:= 0 to ServerPage.PageCount -1 do
    begin
      if (ServerPage.Pages[i].ControlCount >= 1) then
      begin
        Tabsheet := TAsaFrame(ServerPage.Pages[i].Controls[0]);
        Tabsheet.saveProfile;
      end;
    end;
  finally
    ini.Free;
  end;
end;

procedure TAsa_ui.DelSrvClick(Sender: TObject);
var
  ans :TModalResult;
begin
  if BusyFlg then exit;
  SvrDelVisible := true;
  try
    ans := MessageDlg(Form_MessageTrans.Lbl_Hidden_Warning.Caption,Form_MessageTrans.Lbl_Hidden_DeleteServer.Caption,mtConfirmation,[mbYes, mbNo],0);
    if ans=mrYes then
    begin
      ServerPage.Pages[ServerPage.ActivePageIndex].Free;
    end;
  finally
    SvrDelVisible := false;
  end;
end;

procedure TAsa_ui.Edit_FindEnter(Sender: TObject);
begin
  Pnl_Find.Visible:=false;
  if DarkMode then exit;
  Edit_Find.Color:=FocusColor;
end;

procedure TAsa_ui.Edit_FindExit(Sender: TObject);
begin
  if (Edit_Find.Text='') then
  begin
    Pnl_Find.Visible:=true;
  end;
  if DarkMode then exit;
  Edit_Find.Color:=clDefault;
end;

procedure TAsa_ui.Edit_FindKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_RETURN) and (Shift = []) then
  begin
    find_ui.form:= Asa_ui;
    find_ui.Edit_Find.Text:=Edit_Find.Text;
    find_ui.Button_FindClick(Sender);
  end;
end;

procedure TAsa_ui.Button_AboutClick(Sender: TObject);
var
  LOffset :integer;
begin
  LOffset := 5;

  Asa_about_ui.AppVer := AppVer;
  Asa_about_ui.Top:=Asa_ui.Top;
  Asa_about_ui.Left:=Asa_ui.Left +LOffset;
  Asa_about_ui.Image_ARKestra.Visible := false;
  Asa_about_ui.Image_LOGO_ARKestra.Visible := false;
  Asa_about_ui.TrayIcon_ASASM := TrayIcon_ASASM;
  Asa_about_ui.Caption:=Format('About ASASM(Ver.%s)',[AppVer]);

  Asa_about_ui.Show;
end;

procedure TAsa_ui.Button_CacheUpdateClick(Sender: TObject);
var
  sPath_SteamChk :string;
  sCMD_Steam2 :string;
  sCMD_ASADL :string;
  sCMD_ASADLPRM1 :string;
  sCMD_ASADLPRM2 :string;
  sCMD_ASADLPRM3 :string;
  Tabsheet : TAsaFrame;
  bTryClean: boolean;
begin
  if BusyFlg then exit;

  BusyFlg := true;
  Screen.Cursor:=crHourGlass;
  try
    Tabsheet := TAsaFrame(ServerPage.ActivePage.Controls[0]);
    bTryClean := Tabsheet.CB_Install_TryClean.Checked;
    if bTryClean then
    begin
      DeleteFile(ExtractFileDir(ParamStr0)+'\Profile\UpdateChache\steamapps\appmanifest_2430930.acf');
    end;

    sPath_SteamChk := ExtractFilePath(ParamStr0)+'steamcmd\steamerrorreporter.exe';
    sCMD_Steam2 := ExtractFileDir(ParamStr0) +'\steamcmd\steamcmd.exe +quit';
    sCMD_ASADLPRM1:=ExtractFilePath(ParamStr0)  + 'Profile\UpdateChache';
    sCMD_ASADLPRM2:=ExtractFilePath(ParamStr0)  + 'Profile\UpdateChache\ShooterGame\Saved\Config\WindowsServer';
    sCMD_ASADLPRM3:=ExtractFilePath(ParamStr0)  + 'Profile\UpdateChache\ShooterGame\Content\Movies';

    if (DebugUpdate) and FileExists('AsaServerManegerWin_asa_dl_debug.bat') then
    begin
      sCMD_ASADL:='AsaServerManegerWin_asa_dl_debug.bat';
    end else begin
      sCMD_ASADL:='AsaServerManegerWin_asa_dl.bat';
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
      UnZip('steamcmd.zip',ExtractFileDir(ParamStr0)+'\steamcmd');

      AsyncProcess.CommandLine:=sCMD_Steam2;
      AsyncProcess.Execute;
      WaitProcess(AsyncProcess);
      AsyncProcess.CommandLine:='';
    end;
    SetCurrentDir(ExtractFileDir(ParamStr0));

    AsyncProcess.Executable:= sCMD_ASADL;
    AsyncProcess.Parameters.Clear;
    AsyncProcess.Parameters.Add(sCMD_ASADLPRM1);
    AsyncProcess.Parameters.Add(sCMD_ASADLPRM2);
    AsyncProcess.Parameters.Add(sCMD_ASADLPRM3);
    AsyncProcess.Execute;
    WaitProcess(AsyncProcess);
  finally
    Pnl_CacheUpdate_Focus.Visible:=false;
    Screen.Cursor:=crDefault;
    BusyFlg := false;
  end;
end;

procedure TAsa_ui.Button_FindClick(Sender: TObject);
begin
  find_ui.form:= Asa_ui;
  find_ui.Edit_Find.Text:=StringReplace(Edit_Find.Text,' ','',[rfReplaceAll]);
  find_ui.Button_FindClick(Sender);
end;

initialization
  Asa_about_ui := TAsa_about_ui.Create(nil);

finalization
  Asa_about_ui.Free;

end.


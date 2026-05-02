unit mainui_arkestra;

{$mode ObjFPC}{$H+}

interface

uses
  tracetime,
  shortcut,
  asaUtils, aboutui, frameui, splashui, findui, MessageTrans, importui,
  Windows, FileInfo, FileUtil,LCLType, IniFiles, LCLTranslator, LMessages,
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls,
  StdCtrls, Grids, Menus, AsyncProcess, Spin;

type

  TPageControl = class(ComCtrls.TPageControl)
  private
    ActiveTabColor :DWORD;
    NonActiveTabColor :DWORD;
    SVActiveIDX : integer;
    procedure CNDrawItem(var Message: TWMDrawItem); message WM_DRAWITEM;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  end;

  { TARKestra_ui }

  TARKestra_ui = class(TForm)
    AsyncProcess: TAsyncProcess;
    Button_Add_ARKestraLinkAdd: TButton;
    Button_Add_ARKestraLinkDel: TButton;
    Button_ARKestra_Commands: TButton;
    Button_ARKestra_RCON_Send: TButton;
    Button_CacheUpdate: TButton;
    Button_Find: TButton;
    CG_ARKestra_Commands: TCheckGroup;
    ChB_ARKestra_ServerAll: TCheckBox;
    ComboBox1: TComboBox;
    ComboBox2: TComboBox;
    DelSrv: TButton;
    Edit_Add_ARKestraLinkIP: TEdit;
    Edit_Add_ARKestraLinkName: TEdit;
    Edit_ARKestraLink_SecondaryPW: TEdit;
    Edit_ARKestraLink_SecondaryIP: TEdit;
    Edit_Add_ARKestraLinkPW: TEdit;
    Edit_Find: TEdit;
    GB_ARKestra_RCON: TGroupBox;
    GB_AddARKestraLink: TGroupBox;
    ImageList_Button: TImageList;
    Img_Btn_Close: TImage;
    Img_Btn_About: TImage;
    Img_Icon: TImage;
    Lbl_Add_ARKestraLinkIP: TLabel;
    Lbl_Add_ARKestraLinkName: TLabel;
    Lbl_Add_ARKestraLinkPort: TLabel;
    Lbl_Add_ARKestraLinkPW: TLabel;
    Lbl_ARKestraLink_SecondaryPort: TLabel;
    Lbl_ARKestraLink_SecondaryPW: TLabel;
    Lbl__ARKestraLink_SecondaryIP: TLabel;
    Lbl_Title: TLabel;
    Memo_ARKestra_Logs: TMemo;
    MenuItem_ShowARKestra: TMenuItem;
    MenuItem_CloseARKestra: TMenuItem;
    NewSrv: TButton;
    PC_ARKestraMode: TPageControl;
    PC_ARKestra: TPageControl;
    PC_ARKestra_Main: TPageControl;
    PopupMenu_ARKestra: TPopupMenu;
    Pnl_ARKestra_Titlebar: TPanel;
    PC_ARKestra_Top: TPageControl;
    RG_ARKestraMode: TRadioGroup;
    Separator1: TMenuItem;
    ServerPage: TPageControl;
    SE_Add_ARKestraLinkPort: TSpinEdit;
    SG_ServerList: TStringGrid;
    SE_ARKestraLink_SecondaryPort: TSpinEdit;
    SG_ARKestraLinkList: TStringGrid;
    Tab_ARKestraMode1: TTabSheet;
    Tab_ARKestraMode2: TTabSheet;
    Tab_ARKestraMode3: TTabSheet;
    Tab_ARKestra: TTabSheet;
    Tab_ARKestraTab: TTabSheet;
    Tab_ARKestra_DynamicConfig: TTabSheet;
    Tab_ARKestra_Maintenance: TTabSheet;
    Tab_ARKestra_Schedule: TTabSheet;
    Tab_ARKestra_Settings: TTabSheet;
    Tab_ServerList: TTabSheet;
    Tab_ServerListTab: TTabSheet;
    Timer_FirstPage: TTimer;
    Timer_LogDisp: TTimer;
    Toggle_RegStartUpARkestra: TToggleBox;
    Toggle_ARKestra_TrayIcon: TToggleBox;
    TrayIcon_Arkestra: TTrayIcon;
    UpDown1: TUpDown;
    procedure Button_CacheUpdateClick(Sender: TObject);
    procedure Button_FindClick(Sender: TObject);
    procedure DelSrvClick(Sender: TObject);
    procedure Edit_FindKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Img_Btn_AboutClick(Sender: TObject);
    procedure Img_Btn_CloseClick(Sender: TObject);
    procedure Img_Btn_MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Img_Btn_MouseEnter(Sender: TObject);
    procedure Img_Btn_MouseLeave(Sender: TObject);
    procedure Img_Btn_MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure MenuItem_CloseARKestraClick(Sender: TObject);
    procedure NewSrvClick(Sender: TObject);
    procedure PC_ARKestraChange(Sender: TObject);
    procedure PC_ARKestra_TopChange(Sender: TObject);
    procedure PC_ARKestra_TopChanging(Sender: TObject; var AllowChange: Boolean
      );
    procedure Pnl_ARKestra_TitlebarMouseDown(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure RG_ARKestraModeClick(Sender: TObject);
    procedure ServerPageChange(Sender: TObject);
    procedure ServerPageChanging(Sender: TObject; var AllowChange: Boolean);
    procedure Timer_FirstPageTimer(Sender: TObject);
    procedure Timer_LogDispTimer(Sender: TObject);
    procedure Toggle_ARKestra_TrayIconClick(Sender: TObject);
    procedure Toggle_RegStartUpARkestraChange(Sender: TObject);
    procedure TrayIcon_ArkestraClick(Sender: TObject);
  private
    ActiveTabColor :DWORD;
    ProfileTabColor:DWORD;
    FocusColor     :DWORD;
    AppVer :string;
    BuildVer :integer;
    Buildver_Old:integer;
    LastASASMPath   : string;
    ARKestra        : boolean;
    unuse_bat       : boolean;
    UseBuiltinRCON  : boolean;
    DebugUpdate     : boolean;
    OldModList      : boolean;
    DisableSteamcmdSharing:boolean;
    EnableShareUpdate:boolean;
    HiddenTabs   : string;
    ACloseAction :TCloseAction;
    sl_ARKestra_Log :TStringList;
    LocalServerRecs : Array of TServerRec;
    NearServerRecs : Array of TServerRec;
    procedure GetLocalServerRecs;
    procedure GetNearServerRecs;
    procedure SetARKestraLog(message:string);
    procedure SaveAllIniFile;
    procedure ServerPageCreate(idx:integer);
    procedure CloseARKestraMsg(var Message: TWMDrawItem); message WM_APP;
  public
    BusyFlg : boolean;
    SvrDelVisible:boolean;
    StrongClean:boolean;
    CountCreateSec:boolean;
  end;

var
  DarkMode       :boolean;
  ARKestra_ui: TARKestra_ui;

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
                              else BrushColor := NonActiveTabColor;

    BrushHandle := CreateSolidBrush(BrushColor);
    FillRect(hDC, rcItem, BrushHandle);
    SetBkMode(hDC, TRANSPARENT);
    DrawTextEx(hDC, PChar(Page[itemID].Caption), -1, rcItem, DT_CENTER or
      DT_VCENTER or DT_SINGLELINE, nil);
  end;
  Message.Result := 1;
end;

{ TARKestra_ui }

procedure TARKestra_ui.Img_Btn_CloseClick(Sender: TObject);
begin
  close;
end;

procedure TARKestra_ui.FormShow(Sender: TObject);
var
  VersionInfo: TVersionInfo;
begin
  //version
  VersionInfo := TVersionInfo.Create;
  try
    VersionInfo.Load(HINSTANCE);
    BuildVer := VersionInfo.FixedInfo.FileVersion[3];
    AppVer := format('%d.%d.%d.%d',[VersionInfo.FixedInfo.FileVersion[0],
                                    VersionInfo.FixedInfo.FileVersion[1],
                                    VersionInfo.FixedInfo.FileVersion[2],
                                    VersionInfo.FixedInfo.FileVersion[3]]);

    Lbl_Title.Caption:=Format('ARKestra(ɑːkəstrə)-ASASM(Ver.%s)',[AppVer])
  finally
    VersionInfo.Free;
  end;
end;

procedure TARKestra_ui.Img_Btn_AboutClick(Sender: TObject);
var
  LOffset :integer;
begin
  LOffset := 5;

  Asa_about_ui.AppVer := AppVer;
  Asa_about_ui.Top:=self.Top;
  Asa_about_ui.Left:=self.Left +LOffset;
  Asa_about_ui.Image_ASASM.Visible := false;
  Asa_about_ui.Image_LOGO.Visible := false;
  Asa_about_ui.Caption:=Format('About ARKestra-ASASM(Ver.%s)',[AppVer]);

  Asa_about_ui.Show;
end;

procedure TARKestra_ui.FormCreate(Sender: TObject);
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
  BusyFlg := false;
  SvrDelVisible := false;
  //ACloseAction := caHide;
  ACloseAction := caNone;
  sl_ARKestra_Log := TStringList.Create;
  sl_ARKestra_Log.Clear;
  SetLength(LocalServerRecs,0);
  SetLength(NearServerRecs,0);
  Application.Title:='ARKestra(ɑːkəstrə)-ASASM';
  //Application.Icon.LoadFromFile();

  ini := TIniFile.Create(ASASMINI);
  try
    LastASASMPath     :=    ini.ReadString('mainui','LastASASMPath',ParamStr0);
    unuse_bat         :=    ini.ReadBool('mainui','Unuse_bat'         ,False);
    StrongClean       :=    ini.ReadBool('mainui','Strong_CleanUpdate',False);
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

    StrongClean      :=     ini.ReadBool('mainui','Strong_CleanUpdate',False);
    aboutui.Asa_about_ui.ChB_StrongClean.Checked:=StrongClean;

    DarkMode         :=     ini.ReadBool('mainui','DarkMode',False);
    aboutui.Asa_about_ui.ChB_DarkMode.Checked:=DarkMode;
    //if DarkMode then Pnl_Find.Color := RGB(42,42,42);
    if DarkMode then Pnl_ARKestra_Titlebar.Color := RGB(42,42,42);

    ServerPage.ActiveTabColor        := ActiveTabColor;
    ServerPage.NonActiveTabColor     := ColorToRGB(clBtnFace);
    PC_ARKestra_Top.ActiveTabColor   := RGB(224,102,102);
    PC_ARKestra_Top.NonActiveTabColor:= RGB(234,153,153);
    PC_ARKestra.ActiveTabColor       := RGB(234,153,153);
    PC_ARKestra.NonActiveTabColor    := ColorToRGB(clBtnFace);

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

    CountCreateSec    :=    ini.ReadBool('mainui','CountCreateSec' ,False);

    begin
      ARKestra          :=    ini.ReadBool('mainui','ARKestra'       ,False);
      Toggle_ARKestra_TrayIcon.Checked   := ini.ReadBool   ('ARKestra','ARKestra_TrayIcon' ,False);
      Toggle_RegStartUpARkestra.Checked  := ini.ReadBool   ('ARKestra','RegStartUpARkestra',False);
      RG_ARKestraMode.ItemIndex          := ini.ReadInteger('ARKestra','ARKestraMode'      ,    0);
      PC_ARKestraMode.ActivePageIndex    := RG_ARKestraMode.ItemIndex;
      SE_ARKestraLink_SecondaryPort.Value:= ini.ReadInteger('ARKestra','SecondaryPort'     , 8180);
      Edit_ARKestraLink_SecondaryPW.Text := ini.ReadString ('ARKestra','SecondaryPW'       ,   '');

      SG_ARKestraLinkList.RowCount       := ini.ReadInteger('ARKestra','ARKestraLinkCnt'   ,    0) +1;
      for i := 1 to SG_ARKestraLinkList.RowCount -1 do
      begin
        SG_ARKestraLinkList.Rows[i].CommaText:=ini.ReadString ('ARKestra','ARKestraLinkInfo'+IntToStr(i),'');
      end;
      for i := SG_ARKestraLinkList.RowCount -1 downto 1 do
      begin
        if (SG_ARKestraLinkList.Cells[0,i] = '') then
        begin
          SG_ARKestraLinkList.DeleteRow(i);
        end;
      end;
    end;

    H := Monitor.Height;
    W := Monitor.Width;
    if not ARKestra then
    begin
      //self.BorderStyle:=bsSizeable;
      //GB_ARKestra.Visible:=false;
      //ServerPage.Left:=0;
      //ServerPage.Width:=self.Width;
      //Edit_Find.Left:=0;
      //Button_Find.Left:=352;
      //Button_CacheUpdate.Left:=416;

      //Asa_ui.Height     :=ini.ReadInteger('mainui','Height',720);
      //Asa_ui.Width      :=ini.ReadInteger('mainui','Width',720);
      //// Formのポジション・サイズが異常な場合は補正する
      //begin
      //  if not (Asa_ui.Height >  720) then Asa_ui.Height := 720;
      //  if not (Asa_ui.Height <    H) then Asa_ui.Height := 720;
      //  if not (Asa_ui.Width  >  720) then Asa_ui.Width  := 720;
      //  if not (Asa_ui.Width  <    W) then Asa_ui.Width  := 720;
      //end;
    end;
    self.Left       :=ini.ReadInteger('mainui','Left',0);
    self.Top        :=ini.ReadInteger('mainui','Top',0);
    // Formのポジション・サイズが異常な場合は補正する2
    if not (self.Top    >    0) then self.Top    := 0;
    if not (self.Top    <    H) then self.Top    := 0;
    if not (self.Left   >    0) then self.Left   := 0;
    if not (self.Left   <    W) then self.Left   := 0;

    langpos :=ini.ReadInteger('mainui','language',0);
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
    SG_ServerList.RowCount:=cnt+1;
    for i:=0 to cnt -1 do
    begin
      Application.ProcessMessages;
      tergetProfile := ini.ReadString('Profiles','Tab'+InttoStr(i),'err'+InttoStr(i));
      newtab := ServerPage.AddTabSheet;
      newtab.Name   :=tergetProfile;
      newtab.Caption:=tergetProfile;
    end;
  finally
    if ARKestra then SetARKestraLog('Log Starting...');
    ini.Free;
  end;
end;

procedure TARKestra_ui.FormDestroy(Sender: TObject);
var
  sFileName:string;
  sFilePath:string;
  i :integer;
begin
  if ARKestra then
  begin
    SetARKestraLog('Log Close.');
    for i := 0 to sl_ARKestra_Log.Count-1 do
    begin
      Memo_ARKestra_Logs.Lines.Add(sl_ARKestra_Log.Strings[i]);
    end;
    sl_ARKestra_Log.Clear;

    sFileName := FormatDateTime('yyyymmdd_hhnnsszzz',now) + '.ARKestra.log';
    sFilePath := ExtractFilePath(ParamStr0) +'Profile\logs\';
    ForceDirectories(sFilePath);
    Memo_ARKestra_Logs.Lines.SaveToFile(sFilePath+sFileName);
  end;
  sl_ARKestra_Log.Free;
end;

procedure TARKestra_ui.Edit_FindKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_RETURN) and (Shift = []) then
  begin
    find_ui.ARKestra:=true;
    find_ui.form:= self;
    find_ui.Edit_Find.Text:=Edit_Find.Text;
    find_ui.Button_FindClick(Sender);
  end;
end;

procedure TARKestra_ui.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  SaveAllIniFile;
  if BusyFlg then
  begin
    CanClose := False;
    exit;
  end;
  if ARKestra then
  begin
    if (ACloseAction = caHide) then
    begin
      CanClose := False;
      self.Hide;
    end else begin
      CanClose := True;
    end;
  end else begin
    CanClose := True;
  end;
  //CanClose := True;
end;

procedure TARKestra_ui.Button_FindClick(Sender: TObject);
begin
  find_ui.ARKestra:=true;
  find_ui.form:= self;
  find_ui.Edit_Find.Text:=Edit_Find.Text;
  find_ui.Button_FindClick(Sender);
end;

procedure TARKestra_ui.Button_CacheUpdateClick(Sender: TObject);
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
    Screen.Cursor:=crDefault;
    BusyFlg := false;
  end;
end;

procedure TARKestra_ui.DelSrvClick(Sender: TObject);
var
  ans :TModalResult;
begin
  if BusyFlg then exit;
  SvrDelVisible := true;
  try
    ans := MessageDlg(Form_MessageTrans.Lbl_Hidden_Warning.Caption,Form_MessageTrans.Lbl_Hidden_DeleteServer.Caption,mtConfirmation,[mbYes, mbNo],0);
    if ans=mrYes then
    begin
      ServerPage.ActivePage.Destroy;
      ServerPageChange(Sender);
    end;
  finally
    SvrDelVisible := false;
  end;
end;

procedure TARKestra_ui.Img_Btn_MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (Button = mbLeft) and (ssLeft in Shift) and (X > -1) and (Y > -1) then
  begin
    if (Sender = Img_Btn_Close) then ImageList_Button.GetBitmap(2,Img_Btn_Close.Picture.Bitmap);
    if (Sender = Img_Btn_About) then ImageList_Button.GetBitmap(5,Img_Btn_About.Picture.Bitmap);
  end;
end;

procedure TARKestra_ui.Img_Btn_MouseEnter(Sender: TObject);
begin
  if (Sender = Img_Btn_Close) then ImageList_Button.GetBitmap(1,Img_Btn_Close.Picture.Bitmap);
  if (Sender = Img_Btn_About) then ImageList_Button.GetBitmap(4,Img_Btn_About.Picture.Bitmap);
end;

procedure TARKestra_ui.Img_Btn_MouseLeave(Sender: TObject);
begin
  if (Sender = Img_Btn_Close) then ImageList_Button.GetBitmap(0,Img_Btn_Close.Picture.Bitmap);
  if (Sender = Img_Btn_About) then ImageList_Button.GetBitmap(3,Img_Btn_About.Picture.Bitmap);
end;

procedure TARKestra_ui.Img_Btn_MouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (Button <> mbExtra2) and not(ssExtra2 in Shift) and (X > -1) and (Y > -1) then
  begin
    if (Sender = Img_Btn_Close) then ImageList_Button.GetBitmap(0,Img_Btn_Close.Picture.Bitmap);
    if (Sender = Img_Btn_About) then ImageList_Button.GetBitmap(3,Img_Btn_About.Picture.Bitmap);
  end;
end;

procedure TARKestra_ui.MenuItem_CloseARKestraClick(Sender: TObject);
begin
  ACloseAction := caNone;
  close;
end;

procedure TARKestra_ui.CloseARKestraMsg(var Message: TWMDrawItem);
begin
  ACloseAction := caNone;
  close;
  Message.Result:=0;
end;

procedure TARKestra_ui.NewSrvClick(Sender: TObject);
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
    newsheet.FlgsSetup;
  end;
  procedure sub_CreateIni;
  begin
    newsheet.createArgs;
    newsheet.createGUSIni;
    newsheet.createGameIni;
    newsheet.updateServerStatus;
    newsheet.Timer_SvrStatus.Enabled:=True;
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

  Asa_import_ui.Top:=self.Top;
  Asa_import_ui.Left:=self.Left;
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

procedure TARKestra_ui.PC_ARKestraChange(Sender: TObject);
begin
  Screen.Cursor:=crDefault;
end;

procedure TARKestra_ui.PC_ARKestra_TopChange(Sender: TObject);
begin
  PC_ARKestra_Main.ActivePageIndex:=PC_ARKestra_Top.ActivePageIndex;
  PC_ARKestraChange(PC_ARKestra_Main);
end;

procedure TARKestra_ui.PC_ARKestra_TopChanging(Sender: TObject;
  var AllowChange: Boolean);
begin
  Screen.Cursor:=crHourGlass;
  AllowChange := true;
end;

procedure TARKestra_ui.Pnl_ARKestra_TitlebarMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (Button = mbLeft) and (ssLeft in Shift) and (X > -1) and (Y > -1) then
  begin
    ReleaseCapture;
    SendMessage(self.Handle, LM_SYSCOMMAND, 61458, 0) ;
  end;
end;

procedure TARKestra_ui.RG_ARKestraModeClick(Sender: TObject);
begin
  PC_ARKestraMode.ActivePageIndex := RG_ARKestraMode.ItemIndex;
end;

procedure TARKestra_ui.ServerPageChange(Sender: TObject);
begin
  ServerPageCreate(ServerPage.ActivePageIndex);
  Screen.Cursor:=crDefault;
end;

procedure TARKestra_ui.ServerPageChanging(Sender: TObject;
  var AllowChange: Boolean);
begin
  Screen.Cursor:=crHourGlass;
  AllowChange := true;
end;

procedure TARKestra_ui.Timer_FirstPageTimer(Sender: TObject);
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
    if ARKestra then
    begin
      //Form_Splash_ARKestra.Left:=self.Left+77;
      //Form_Splash_ARKestra.Top :=self.Top +220;
      Form_Splash_ARKestra.Show;
      Form_Splash_ARKestra.Refresh;
      for i := 0 to ServerPage.PageCount -1 do
      begin
        ServerPageCreate(i);
      end;
    end else begin
      if (ServerPage.PageCount > 0) then
      begin
        ServerPageChange(Sender);
      end;
    end;
  end;
  if ARKestra then
  begin
    Timer_LogDisp.Enabled:=true;
    Toggle_ARKestra_TrayIconClick(Toggle_ARKestra_TrayIcon);
    Toggle_RegStartUpARkestraChange(Toggle_RegStartUpARkestra);
    PC_ARKestra_TopChange(PC_ARKestra_Top);
    Edit_ARKestraLink_SecondaryIP.Text:=GetLocalIP;
    if ARKestra then SetARKestraLog('ARKestra Started.');
    Form_Splash_ARKestra.Hide;
    Screen.Cursor:=crDefault;
  end;
  if (LastASASMPath <> ParamStr0) then
  begin
    showmessage('前回のASASM起動から起動PATHが変更されてます'+LineEnding+'各プロファイルのInstall Locationが正しいか確認してください');
  end;
  BusyFlg := false;
end;

procedure TARKestra_ui.SaveAllIniFile;
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

    StrongClean:=aboutui.Asa_about_ui.ChB_StrongClean.Checked;
    ini.WriteBool('mainui','Strong_CleanUpdate',StrongClean);

    DarkMode:=aboutui.Asa_about_ui.ChB_DarkMode.Checked;
    ini.WriteBool('mainui','DarkMode',DarkMode);

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
      ini.WriteBool   ('ARKestra','ARKestra_TrayIcon' ,Toggle_ARKestra_TrayIcon.Checked);
      ini.WriteBool   ('ARKestra','RegStartUpARkestra',Toggle_RegStartUpARkestra.Checked);
      ini.WriteInteger('ARKestra','ARKestraMode'      ,RG_ARKestraMode.ItemIndex);
      ini.WriteInteger('ARKestra','SecondaryPort'     ,SE_ARKestraLink_SecondaryPort.Value);
      ini.WriteString ('ARKestra','SecondaryPW'       ,Edit_ARKestraLink_SecondaryPW.Text);

      for i := SG_ARKestraLinkList.RowCount -1 downto 1 do
      begin
        if (SG_ARKestraLinkList.Cells[0,i] = '') then
        begin
          SG_ARKestraLinkList.DeleteRow(i);
        end;
      end;
      ini.WriteInteger('ARKestra','ARKestraLinkCnt'   , SG_ARKestraLinkList.RowCount -1);
      for i := 1 to SG_ARKestraLinkList.RowCount -1 do
      begin
        ini.WriteString ('ARKestra','ARKestraLinkInfo'+IntToStr(i),SG_ARKestraLinkList.Rows[i].CommaText);
      end;
    end;

    self.WindowState := wsNormal;
    ini.WriteInteger('mainui','Left'       ,self.Left);
    ini.WriteInteger('mainui','Top'        ,self.Top);
    //if not ARKestra then
    //begin
    //  ini.WriteInteger('mainui','Height'     ,Asa_ui.Height);
    //  ini.WriteInteger('mainui','Width'      ,Asa_ui.Width);
    //end;

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

procedure TARKestra_ui.GetLocalServerRecs;
var
  newsheet:TAsaFrame;
  OldRecCnt :integer;
  NewRecCnt :integer;
  i :integer;
  j :integer;
  bRCON :boolean;
  password :string;
  RCONPort :string;
begin
  OldRecCnt := Length(LocalServerRecs);
  NewRecCnt := ServerPage.PageCount;

  SetLength(LocalServerRecs,NewRecCnt);
  if (OldRecCnt < NewRecCnt) then
  begin
    for i := OldRecCnt to NewRecCnt -1 do
    begin
      LocalServerRecs[i].Checked:='0';
    end;
  end;
  for i := 0 to NewRecCnt -1 do
  begin
    if (ServerPage.Pages[i].ControlCount <> 0) then
    begin
      newsheet := TAsaFrame(ServerPage.Pages[i].FindComponent('ASAServer'+inttostr(i)));
      if (newsheet <> nil) then
      begin
        begin
          bRCON    := newsheet.CB_RCONEnabled.Checked;
          password := newsheet.Edit_ServerAdminPassword.Text;
          RCONPort := newsheet.SE_RCONPort.Text;
          if (newsheet.ChB_USE_AsaApiLoader.Checked) then LocalServerRecs[i].ApiLoader := '*'
                                                     else LocalServerRecs[i].ApiLoader := '';
          LocalServerRecs[i].ProfileName := newsheet.Edit_Profile.Text;
          LocalServerRecs[i].SessionName := newsheet.Edit_SessionName.Text;
          LocalServerRecs[i].MapName := newsheet.CB_MapName.Text;
          LocalServerRecs[i].InstVer := newsheet.Lbl_InstVer_Val.Caption;
          LocalServerRecs[i].Port := newsheet.SE_Port.Text;
          if (bRCON) and (password <> '') then LocalServerRecs[i].RCONPort := RCONPort
                                          else LocalServerRecs[i].RCONPort := '-';
          LocalServerRecs[i].sSrvStatus := newsheet.CB_SrvStatus_Val.Items[newsheet.CB_SrvStatus_Val.ItemIndex];
          LocalServerRecs[i].iSrvStatus := IntToStr(newsheet.CB_SrvStatus_Val.ItemIndex);
          LocalServerRecs[i].Players    :='';
          if (newsheet.CB_SrvStatus_Val.ItemIndex >= 4) and
             (newsheet.fCPU_Use<>0.0) then LocalServerRecs[i].CPU_Use := format('%2.2fCore',[newsheet.fCPU_Use / 1000])
                                      else LocalServerRecs[i].CPU_Use := '';
          if (newsheet.CB_SrvStatus_Val.ItemIndex >= 4) and
             (newsheet.iMemUseMB<>0) then LocalServerRecs[i].MemUseMB := format('%2.1fGB',[newsheet.iMemUseMB / 1024])
                                     else LocalServerRecs[i].MemUseMB := '';
          if (newsheet.CB_SrvStatus_Val.ItemIndex >= 4) and
             (newsheet.iUptime<>0) then LocalServerRecs[i].Uptime := newsheet.sUptime
                                   else LocalServerRecs[i].Uptime := '';
        end;
        for j := 0 to newsheet.sl_ProfileLog.Count-1 do
        begin
          Memo_ARKestra_Logs.Lines.Add(newsheet.sl_ProfileLog.Strings[j]);
        end;
        newsheet.sl_ProfileLog.Clear;
      end else begin
        LocalServerRecs[i].ProfileName := 'N';
      end;
    end;
  end;
end;

procedure TARKestra_ui.GetNearServerRecs;
begin

end;

procedure TARKestra_ui.Timer_LogDispTimer(Sender: TObject);
var
  i :integer;
  j :integer;
  procedure SetCell(Col,Row:Integer;str:string);
  begin
    if (SG_ServerList.Cells[Col,Row] <> str) then SG_ServerList.Cells[Col,Row] := str;
  end;
begin
  for j := 0 to sl_ARKestra_Log.Count-1 do
  begin
    Memo_ARKestra_Logs.Lines.Add(sl_ARKestra_Log.Strings[j]);
  end;
  sl_ARKestra_Log.Clear;

  SG_ServerList.BeginUpdate;
  GetLocalServerRecs;
  SG_ServerList.RowCount := Length(LocalServerRecs)+1;
  for i := 1 to Length(LocalServerRecs) do
  begin
    if (SG_ServerList.Cells[ 0,i] = '') then
    begin
      SG_ServerList.Cells[ 0,i] := LocalServerRecs[i - 1].Checked;
      SetCell( 0,i,LocalServerRecs[i - 1].Checked);
    end else begin
      LocalServerRecs[i - 1].Checked := SG_ServerList.Cells[ 0,i];
    end;
    SetCell( 1,i,LocalServerRecs[i - 1].ApiLoader);
    SetCell( 2,i,LocalServerRecs[i - 1].ProfileName);
    SetCell( 3,i,LocalServerRecs[i - 1].SessionName);
    SetCell( 4,i,LocalServerRecs[i - 1].MapName);
    SetCell( 5,i,LocalServerRecs[i - 1].InstVer);
    SetCell( 6,i,LocalServerRecs[i - 1].Port);
    SetCell( 7,i,LocalServerRecs[i - 1].RCONPort);
    SetCell( 8,i,LocalServerRecs[i - 1].sSrvStatus);
    SetCell( 9,i,LocalServerRecs[i - 1].iSrvStatus);
    SetCell(10,i,LocalServerRecs[i - 1].Players);
    SetCell(11,i,LocalServerRecs[i - 1].CPU_Use);
    SetCell(12,i,LocalServerRecs[i - 1].MemUseMB);
    SetCell(13,i,LocalServerRecs[i - 1].Uptime);
  end;
  SG_ServerList.EndUpdate(true);
end;

procedure TARKestra_ui.Toggle_ARKestra_TrayIconClick(Sender: TObject);
begin
  TrayIcon_Arkestra.Visible:=Toggle_ARKestra_TrayIcon.Checked;
  if Toggle_ARKestra_TrayIcon.Checked then ACloseAction := caHide
                                      else ACloseAction := caNone;
end;

procedure TARKestra_ui.Toggle_RegStartUpARkestraChange(Sender: TObject);
begin
  if Toggle_RegStartUpARkestra.Checked then
  begin
    if not HasStartup(ParamStr0) then CreateStartup(ParamStr0);
  end else begin
    if HasStartup(ParamStr0) then DeleteStartup(ParamStr0);
  end;
end;

procedure TARKestra_ui.TrayIcon_ArkestraClick(Sender: TObject);
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

procedure TARKestra_ui.ServerPageCreate(idx:integer);
var
  newsheet:TAsaFrame;
begin
  ClearTraceResult;
  if (ServerPage.Pages[idx].ControlCount = 0) then
  begin
    Screen.Cursor:=crHourGlass;
    {}StopTrace('st_');StartTrace('Crt');
    SetARKestraLog(format('[%s]Create',[ServerPage.Pages[idx].Caption]));
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
    newsheet.FlgsSetup;
    {}StopTrace('Flg');StartTrace('Pr1');

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
    {}StopTrace('GME');StartTrace('Sts');
    newsheet.updateServerStatus;
    {}StopTrace('Sts');StartTrace('Tmr');
    newsheet.Timer_SvrStatus.Enabled:=True;
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

procedure TARKestra_ui.SetARKestraLog(message:string);
var
  sTime   :string;
begin
  sTime := DateTimeToStr(Now);
  sl_ARKestra_Log.Add(format('%s[ARKestra]:%s',[sTime,message]));
end;

initialization
  Asa_about_ui := TAsa_about_ui.Create(nil);

finalization
  Asa_about_ui.Free;

end.


unit aboutui;

{$mode objfpc}{$H+}

interface

uses
  asaUtils, discord, nbprocesswin,
  ShellApi, Classes, SysUtils, Forms, Controls, Dialogs, ExtCtrls,
  StdCtrls, AsyncProcess, ComCtrls, Spin, Buttons;

type

  { TAsa_about_ui }

  TAsa_about_ui = class(TForm)
    AsyncProcess: TAsyncProcess;
    AsyncProcess_update: TAsyncProcess;
    Btn_About_Data_goodwords: TButton;
    Btn_About_Data_BanList: TButton;
    Btn_About_Data_dynamicconfig: TButton;
    Btn_About_Data_featured: TButton;
    Btn_About_Data_BuildID: TButton;
    Btn_About_Data_officialtributeenabled: TButton;
    Btn_About_Data_news: TButton;
    Btn_About_Data_OfficialCosmeticWhitelist: TButton;
    Btn_About_Data_officialserverstatus: TButton;
    Btn_About_Data_badwords: TButton;
    Btn_About_Data_livetuningoverloads: TButton;
    Btn_About_Data_pcnotification: TButton;
    Btn_DiscordHook_Admin_Test: TButton;
    Btn_TrayNotification_Test: TButton;
    Button_ExternalIP_Check: TButton;
    Button_LocalIP_Check: TButton;
    Button_Reinstall_Steamcmd: TButton;
    CB_About_ARKData: TComboBox;
    CG_DiscordHook_Admin_Kind: TCheckGroup;
    CG_TrayNotification_Kind: TCheckGroup;
    CG_Hiddentabs: TCheckGroup;
    ChB_ASASMFullStartup: TCheckBox;
    ChB_DarkMode: TCheckBox;
    ChB_DisableSteamcmdSharing: TCheckBox;
    ChB_EnableShareUpdate: TCheckBox;
    ChB_OldModList: TCheckBox;
    ChB_StrongClean: TCheckBox;
    ChB_SvrUpd_Debug: TCheckBox;
    ChB_USeBeta: TCheckBox;
    ChB_Use_builtin_RCON: TCheckBox;
    ChB_VerChkInterval: TCheckBox;
    ColorButton_ActiveTabColor: TColorButton;
    ColorButton_FocusColor: TColorButton;
    ColorButton_ProfActiveTabColor: TColorButton;
    Edit_About_ARKData: TEdit;
    Edit_DiscordHook_Admin_ASASMNAME: TEdit;
    Edit_TrayNotification_ASASMNAME: TEdit;
    Edit_DiscordHook_Admin_URL: TEdit;
    Edit_ExternalIP: TEdit;
    Edit_LocalIP: TEdit;
    Image_ARKestra: TImage;
    Image_ASASM_Bug: TImage;
    Image_ASASM_DL: TImage;
    Image_ASASM_NewDL: TImage;
    Image_ASASM_QA: TImage;
    Image_LOGO: TImage;
    Image_LOGO_ARKestra: TImage;
    Image_ASASM: TImage;
    Image_Twitter: TImage;
    Image_YT_DSOUKO: TImage;
    Image_YT_DYG: TImage;
    Lbl_Thanks_Arkwiki: TLabel;
    Lbl_Thanks_LazarusIDE: TLabel;
    Lbl_Thanks_XRay: TLabel;
    Lbl_Thanks_mcrcon: TLabel;
    Lbl_TrayNotification: TLabel;
    Lbl_TrayNotification_ASASMNAME: TLabel;
    Lbl_TrayNotification_Test: TLabel;
    Lbl_Discord_Webhook: TLabel;
    Label3: TLabel;
    LangList: TComboBox;
    Lbl_About_Data: TLabel;
    Lbl_About_SpecialThanks: TLabel;
    Lbl_ActiveTabColor: TLabel;
    Lbl_ASASM_Bug: TLabel;
    Lbl_ASASM_DL: TLabel;
    Lbl_ASASM_NewDL: TLabel;
    Lbl_ASASM_QA: TLabel;
    Lbl_Creator: TLabel;
    Lbl_DiscordHook_Admin_ASASMNAME: TLabel;
    Lbl_DiscordHook_Admin_Test: TLabel;
    Lbl_ExternalIP: TLabel;
    Lbl_ExternalIP_Site: TLabel;
    Lbl_FocusColor: TLabel;
    Lbl_Lang: TLabel;
    Lbl_LocalIP: TLabel;
    Lbl_ProfileTabColor: TLabel;
    Lbl_Twitter: TLabel;
    Lbl_VerChkInterval: TLabel;
    Lbl_YT1: TLabel;
    Lbl_YT_DSOUKO: TLabel;
    Lbl_YT_DYG: TLabel;
    Memo_About_ARKData: TMemo;
    PC_Discord: TPageControl;
    PC_SubSettings: TPageControl;
    Pnl_About_Focus: TPanel;
    PC_About: TPageControl;
    Pnl_About_ARKData: TPanel;
    SBox_About_ARKData: TScrollBox;
    SBtn_Thanks_LazarusIDE: TSpeedButton;
    SBtn_Thanks_Xray: TSpeedButton;
    SBtn_Thanks_mcrcon: TSpeedButton;
    SE_VerChkInterval: TSpinEdit;
    SBtn_Thanks_Arkwiki: TSpeedButton;
    Tab_SubSettings_TrayNotification: TTabSheet;
    Tab_DiscordHook_Admin: TTabSheet;
    Tab_Discord_Player: TTabSheet;
    Tab_SubSettings_DiscordWebhook: TTabSheet;
    Tab_About_ARKData: TTabSheet;
    Tab_About_Link: TTabSheet;
    Tab_About_Settings: TTabSheet;
    Tab_About_SpecialThanks: TTabSheet;
    Toggle_DiscordHook_Admin_URL: TToggleBox;
    procedure Btn_About_DataClick(Sender: TObject);
    procedure Btn_DiscordHook_Admin_TestClick(Sender: TObject);
    procedure Btn_TrayNotification_TestClick(Sender: TObject);
    procedure Button_IPCheck_Click(Sender: TObject);
    procedure Button_Reinstall_SteamcmdClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ICON_Link_Click(Sender: TObject);
    procedure SBtn_Thanks_URLClick(Sender: TObject);
    procedure ToggleBox_DiscordChange(Sender: TObject);
  private
    function  GetBusyFlg : Boolean;
    procedure SetBusyFlg(const AValue : Boolean);
  public
    TrayIcon_ASASM: TTrayIcon;
    AppVer :string;
    property  BusyFlg : Boolean Read GetBusyFlg Write SetBusyFlg;
  end;

var
  slLangList:TStringList;
  Asa_about_ui: TAsa_about_ui;

implementation
uses
  mainui;

{$R *.lfm}

{ TAsa_about_ui }

procedure TAsa_about_ui.FormCreate(Sender: TObject);
var
  i :integer;
  path :string;
begin
  //languagelist
  path := ExtractFilePath(ParamStr0)+DIR_LANG+FILE_LANGLIST;
  slLangList.LoadFromFile(path);
  for i := 0 to slLangList.Count -1 do
  begin
    if (pos('=',slLangList.Strings[i])<>0) then
    begin
      LangList.Items.Add(slLangList.Names[i]);
    end;
  end;
  if (LangList.Items.Count<>0) then LangList.ItemIndex:=0;


end;

procedure TAsa_about_ui.Button_IPCheck_Click(Sender: TObject);
begin
  if (Sender = Button_LocalIP_Check)    then Edit_LocalIP.Text   := GetLocalIP;
  if (Sender = Button_ExternalIP_Check) then Edit_ExternalIP.Text:= GetExternalIP;
end;

procedure TAsa_about_ui.Btn_DiscordHook_Admin_TestClick(Sender: TObject);
var
  discord_hook : TDiscord_Webhook;
  sResponse :string;
begin
  discord_hook := TDiscord_Webhook.Create;
  try
    discord_hook.SetURL(Edit_DiscordHook_Admin_URL.Text);
    discord_hook.SetTestMessage(Edit_DiscordHook_Admin_ASASMNAME.Text,'Test Message.');
    discord_hook.send;
    sResponse := discord_hook.GetLastResponse;
    if (sResponse = '') then sResponse:= 'OK';
    Lbl_DiscordHook_Admin_Test.Caption:= sResponse;
  finally
    discord_hook.Free;
  end;
end;

procedure TAsa_about_ui.Btn_TrayNotification_TestClick(Sender: TObject);
begin
  if (TrayIcon_ASASM <> nil) then
  begin
    TrayIcon_ASASM.Visible:=true;
    TrayIcon_ASASM.BalloonTitle:=format('[TEST]%s',[Edit_TrayNotification_ASASMNAME.Text]);
    TrayIcon_ASASM.BalloonHint :='Test Notification.';
    TrayIcon_ASASM.ShowBalloonHint;
    Lbl_TrayNotification_Test.Caption:= 'Notification completed.';
  end else begin
    Lbl_TrayNotification_Test.Caption:= 'Notification failed.';
  end;
end;

procedure TAsa_about_ui.Btn_About_DataClick(Sender: TObject);
begin
  SBox_About_ARKData.Enabled:=false;
  try
    if (Sender = Btn_About_Data_pcnotification           ) then CB_About_ARKData.ItemIndex := 0;
    if (Sender = Btn_About_Data_dynamicconfig            ) then CB_About_ARKData.ItemIndex := 1;
    if (Sender = Btn_About_Data_OfficialCosmeticWhitelist) then CB_About_ARKData.ItemIndex := 2;
    if (Sender = Btn_About_Data_BanList                  ) then CB_About_ARKData.ItemIndex := 3;
    if (Sender = Btn_About_Data_officialserverstatus     ) then CB_About_ARKData.ItemIndex := 4;
    if (Sender = Btn_About_Data_news                     ) then CB_About_ARKData.ItemIndex := 5;
    if (Sender = Btn_About_Data_featured                 ) then CB_About_ARKData.ItemIndex := 6;
    if (Sender = Btn_About_Data_officialtributeenabled   ) then CB_About_ARKData.ItemIndex := 7;
    if (Sender = Btn_About_Data_badwords                 ) then CB_About_ARKData.ItemIndex := 8;
    if (Sender = Btn_About_Data_goodwords                ) then CB_About_ARKData.ItemIndex := 9;
    if (Sender = Btn_About_Data_livetuningoverloads      ) then CB_About_ARKData.ItemIndex :=10;
    //if (Sender = Btn_About_Data_BuildID                  ) then CB_About_ARKData.ItemIndex :=11;

    Edit_About_ARKData.Text := CB_About_ARKData.Text;
    if (Sender = Btn_About_Data_OfficialCosmeticWhitelist) then Memo_About_ARKData.Lines.CommaText := AsyncGet(CB_About_ARKData.Text)
                                                           else Memo_About_ARKData.Lines.Text      := AsyncGet(CB_About_ARKData.Text);

  finally
    SBox_About_ARKData.Enabled:=true;
  end;
end;

procedure TAsa_about_ui.Button_Reinstall_SteamcmdClick(Sender: TObject);
begin
  if BusyFlg then exit;

  BusyFlg := true;
  try
    Button_Reinstall_Steamcmd.Enabled:=false;
    DeleteFolder(ExtractFileDir(ParamStr0)+DIR_STEAM);
    DeleteFile(FILE_STEAMZIP);

    sleep(2000);

    if not FileExists(ExtractFileDir(ParamStr0)+DIR_STEAM+'\'+FILE_STEAMERR) then
    begin
      AsyncProcess.Executable:=ASABAT_STEAM_DL;
      AsyncProcess.Execute;
      while (AsyncProcess.Running) do
      begin
        sleep(200);
        Application.ProcessMessages;
      end;
    end;
  finally
    Button_Reinstall_Steamcmd.Enabled:=true;
    BusyFlg := true;
  end;


end;

procedure TAsa_about_ui.ICON_Link_Click(Sender: TObject);
var
  url :string;
const
  OPEN = 'open';
begin
  if (Sender = Image_ASASM_DL)    then ShellExecute(0, OPEN, PChar(String(URL_OFFISIAL)), nil, nil, 0);
  if (Sender = Image_ASASM_QA)    then ShellExecute(0, OPEN, PChar(String(URL_OFFISIALQA)), nil, nil, 0);
  if (Sender = Image_ASASM_Bug)   then
  begin
    url := URL_OFFISIALFORM + AppVer;
    ShellExecute(0, OPEN, PChar(String(url)), nil, nil, 0);
  end;

  if (Sender = Image_ASASM_NewDL) then
  begin
    if FileExists(FILE_UPDATER) then
    begin
      AsyncProcess_update.Executable:=FILE_UPDATER;
      AsyncProcess_update.Execute;
    end else begin
      ShellExecute(0, OPEN, PChar(String(URL_DOWNLOAD)), nil, nil, 0);
    end;
  end;

  if (Sender = Image_YT_DYG)      then ShellExecute(0, OPEN, PChar(String(URL_YT_MAIN)), nil, nil, 0);
  if (Sender = Image_YT_DSOUKO)   then ShellExecute(0, OPEN, PChar(String(URL_YT_SOUKO)), nil, nil, 0);
  if (Sender = Image_Twitter)     then ShellExecute(0, OPEN, PChar(String(URL_TWITTER)), nil, nil, 0);
end;

procedure TAsa_about_ui.SBtn_Thanks_URLClick(Sender: TObject);
var
  sURL:string;
begin
  sURL := '';
  if (Sender = SBtn_Thanks_Arkwiki)    then sURL := 'https://ark.wiki.gg/wiki/Server_configuration';
  if (Sender = SBtn_Thanks_Xray)       then sURL := 'https://mrxray.on.coocan.jp/Delphi/plSamples/330_AppProcessList.htm';
  if (Sender = SBtn_Thanks_mcrcon)     then sURL := 'https://github.com/Tiiffi/mcrcon';
  if (Sender = SBtn_Thanks_LazarusIDE) then sURL := 'https://www.lazarus-ide.org/';

  if (sURL <> '') then ShellExecute(0, 'open', PChar(sURL), nil, nil, 0);
end;

procedure TAsa_about_ui.ToggleBox_DiscordChange(Sender: TObject);
begin
  if (Sender = Toggle_DiscordHook_Admin_URL) then
  begin
    if (Toggle_DiscordHook_Admin_URL.State = cbChecked) then Edit_DiscordHook_Admin_URL.PasswordChar:= #0
                                                        else Edit_DiscordHook_Admin_URL.PasswordChar:= '*';
  end;
end;

function  TAsa_about_ui.GetBusyFlg : Boolean;
var
  mainui : TAsa_ui;
begin
  mainui := Asa_ui;
  result := mainui.BusyFlg;
end;

procedure TAsa_about_ui.SetBusyFlg(const AValue : Boolean);
var
  mainui : TAsa_ui;
begin
  mainui := Asa_ui;
  mainui.BusyFlg:=AValue;
end;

initialization
  slLangList := TStringList.Create;

finalization
  slLangList.Free;

end.


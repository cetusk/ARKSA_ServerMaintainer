unit asasm_upd_ui;

{$mode objfpc}{$H+}

interface

uses
  opensslsockets,
  asaUtils, fphttpclient,
  fileutil,
  LazFileUtils,
  windows, IniFiles, //StrUtils,
  winpeimagereader, fileinfo, Classes,
  SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  AsyncProcess;

type

  { TForm_update }

  TForm_update = class(TForm)
    AsyncProcess_startASASM: TAsyncProcess;
    AsyncProcess_curl: TAsyncProcess;
    Button_Cancel: TButton;
    Button_update: TButton;
    ChB_RunAgain: TCheckBox;
    FPHTTPClient1: TFPHTTPClient;
    Image_update: TImage;
    Lbl_Status: TLabel;
    Lbl_oldver: TLabel;
    Lbl_newver: TLabel;
    Lbl_oldver_val: TLabel;
    Lbl_newver_val: TLabel;
    Lbl_Beta: TLabel;
    Memo_update_detail: TMemo;
    Timer_once: TTimer;
    procedure Button_CancelClick(Sender: TObject);
    procedure Button_updateClick(Sender: TObject);
    procedure ChB_RunAgainChange(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormShow(Sender: TObject);
    procedure Timer_onceTimer(Sender: TObject);
    procedure updateASASM;
  private
    isBeta  :boolean;
    sURL_Info :string;
    sURL_DL :string;
    running :boolean;
    oldver_1:integer;
    oldver_2:integer;
    oldver_3:integer;
    oldver_4:integer;
    newver_1:integer;
    newver_2:integer;
    newver_3:integer;
    newver_4:integer;
  public

  end;

const
  URL_INFO      = 'https://drive.usercontent.google.com/download?id=1-6TpKBqd5as6RCDqKn-hAVWBHXsNGC_A';
  URL_DL        = 'https://drive.usercontent.google.com/download?id=1rWyVTd7XrRE8nqsZmjDha4IJOjxVWnem';
  URL_INFO_BETA = 'https://drive.usercontent.google.com/download?id=15VIQV6TnBhqI2KTWWAR4oDazwmkXOT7t';
  URL_DL_BETA   = 'https://drive.usercontent.google.com/download?id=1dFyO5zTEwns-7eVhd0fb2TptuXrdDCFi';

var
  Form_update: TForm_update;

implementation

{$R *.lfm}

{ TForm_update }

procedure TForm_update.FormShow(Sender: TObject);
var
  VersionInfo: TVersionInfo;
  appver_1:integer;
  appver_2:integer;
  appver_3:integer;
  appver_4:integer;

begin
  running := false;

  VersionInfo := TVersionInfo.Create;
  try
    VersionInfo.Load(HINSTANCE);
    appver_1 := VersionInfo.FixedInfo.FileVersion[0];
    appver_2 := VersionInfo.FixedInfo.FileVersion[1];
    appver_3 := VersionInfo.FixedInfo.FileVersion[2];
    appver_4 := VersionInfo.FixedInfo.FileVersion[3];
    Form_update.Caption:=Format('ASASM Update:Ver.%d.%d.%d.%d',[appver_1,appver_2,appver_3,appver_4]);
  finally
    VersionInfo.Free;
  end;

  oldver_1 := 0;
  oldver_2 := 0;
  oldver_3 := 0;
  oldver_4 := 0;

  if FileExists('AsaServerManegerWin.exe') then
  begin
    VersionInfo := TVersionInfo.Create;
    try
      VersionInfo.Load('AsaServerManegerWin.exe');
      oldver_1 := VersionInfo.FixedInfo.FileVersion[0];
      oldver_2 := VersionInfo.FixedInfo.FileVersion[1];
      oldver_3 := VersionInfo.FixedInfo.FileVersion[2];
      oldver_4 := VersionInfo.FixedInfo.FileVersion[3];
    finally
      VersionInfo.Free;
    end;
  end;
  Lbl_oldver_val.Caption:=format('%d.%d.%d.%d',[oldver_1,oldver_2,oldver_3,oldver_4]);
end;

procedure TForm_update.Button_CancelClick(Sender: TObject);
begin
  close;
end;

procedure TForm_update.updateASASM;
var
  sDir:String;
  AResult : boolean;
  srcdir,
  dstdir:string;
  slFileList: TStringList;
  sFile:string;
  i :integer;
begin
  try
    Lbl_Status.Caption:='アップデート環境作成中';
    Application.ProcessMessages;
    begin
      ChB_RunAgain.Enabled:=false;
      Button_update.Enabled:=false;
      Button_Cancel.Enabled:=false;
      running := true;

      sDir       := ExtractFileDir(Paramstr(0))+'\Profile';
      dstdir     := ExtractFileDir(Paramstr(0));
      if not DirectoryExists(sDir) then
      begin
        CreateDir(sDir);
      end;

      if FileExists(sDir + '\asasmup.zip') then
      begin
        DeleteFile(sDir + '\asasmup.zip');
      end;

      if DirectoryExists(sDir+'\asasmup') then
      begin
        AResult:=DeleteDirectory(sDir+'\asasmup',True);
        if AResult then
        begin
          AResult:=RemoveDirUTF8(sDir+'\asasmup');
        end;
      end;
    end;

    Lbl_Status.Caption:='ダウンロード中';
    Application.ProcessMessages;
    begin
      FPHTTPClient1.AllowRedirect:=true;

      //if isBeta then FPHTTPClient1.Get(URL_DL_BETA,sDir + '\asasmup.zip')
      //          else FPHTTPClient1.Get(URL_DL     ,sDir + '\asasmup.zip');
      FPHTTPClient1.Get(sURL_DL,sDir + '\asasmup.zip');

      //FPHTTPClient1.Get(URL_DL,sDir + '\asasmup.zip');

      if not FileExists(sDir + '\asasmup.zip') then
      begin
        Lbl_Status.Caption:='ダウンロード失敗';
        Application.ProcessMessages;
        exit;
      end;
    end;

    Lbl_Status.Caption:='展開中';
    Application.ProcessMessages;
    begin
      sleep(1000);
      UnZip(sDir+'\asasmup.zip',sDir+'\asasmup');
    end;

    Lbl_Status.Caption:='ASASM終了中';
    Application.ProcessMessages;
    begin
      closeServer        (ExtractFileDir(Paramstr(0))+'\ARKestra.exe');
      closeServer        (ExtractFileDir(Paramstr(0))+'\DodoRCON.exe');
      closeServer        (ExtractFileDir(Paramstr(0))+'\RCONHelper.exe');
      closeServer        (ExtractFileDir(Paramstr(0))+'\AsaServerPanel.exe');
      closeServer        (ExtractFileDir(Paramstr(0))+'\AsaServerCointrolPanel.exe');
      closeServer        (ExtractFileDir(Paramstr(0))+'\AsaServerManegerWin.exe');
      closeARKestraServer(ExtractFileDir(Paramstr(0))+'\AsaServerManegerWin.exe');
    end;

    Lbl_Status.Caption:='ファイルコピー中';
    Application.ProcessMessages;
    begin
      sleep(1000);
      srcdir     := ExtractFileDir(Paramstr(0))+'\Profile\asasmup\ASA Server Manager_x86-64_upd';
      if not DirectoryExists(srcdir) then
      begin
        srcdir     := ExtractFileDir(Paramstr(0))+'\Profile\asasmup\ASA Server Manager_x86-64';
      end;
      fileutil.CopyDirTree(srcdir+'\lang'  ,dstdir+'\lang'  ,[cffOverwriteFile,cffCreateDestDirectory,cffPreserveTime]);
      fileutil.CopyDirTree(srcdir+'\mcrcon',dstdir+'\mcrcon',[cffOverwriteFile,cffCreateDestDirectory,cffPreserveTime]);

      slFileList := TStringList.Create;
      try
        FindAllFiles(slFileList,srcdir,'*.*',false);

        for i := 0 to slFileList.Count-1 do
        begin
          sFile := ExtractFilename(slFileList.Strings[i]);

          if (sFile = 'AsaServerManegerWin.ini')    then continue;
          if (sFile = 'ASASM_Updater.exe')          then continue;
          if (sFile = 'ASASM_Updater_check.bat')    then continue;
          if (sFile = 'ASASM_Updater_download.bat') then continue;

          Lbl_Status.Caption:='ファイルコピー中:'+sFile;
          Application.ProcessMessages;

          fileutil.CopyFile   (srcdir+'\'+sFile,dstdir+'\'+sFile,[cffOverwriteFile,cffCreateDestDirectory,cffPreserveTime]);
        end;
      finally
        slFileList.Free;
      end;
    end;

    Lbl_Status.Caption:='アップデート完了';
    Application.ProcessMessages;
    begin
      running := false;

      AsyncProcess_startASASM.CommandLine:=ExtractFileDir(Paramstr(0))+'\AsaServerManegerWin.exe AfterUpdate';
      AsyncProcess_startASASM.Execute;

      sleep(200);
      Application.ProcessMessages;
      sleep(200);
      Application.ProcessMessages;
      sleep(200);
      Application.ProcessMessages;
      sleep(200);
      Application.ProcessMessages;
      sleep(200);
      Application.ProcessMessages;
      close;
    end;

  finally
    running := false;
  end;
end;

procedure TForm_update.Button_updateClick(Sender: TObject);
var
  ans :TModalResult;
begin
  ans := MessageDlg('確認','ASASMアップデートを実行しますか？'+#13#10+'ASAサーバー起動中もアップデート出来ます',mtConfirmation,[mbYes, mbNo],0);
  if ans=mrYes then
  begin
    updateASASM;
    Button_Cancel.Enabled:=true;
  end;
end;

procedure TForm_update.ChB_RunAgainChange(Sender: TObject);
begin
  if (ChB_RunAgain.Checked) then
  begin
    Button_update.Enabled:=true;
  end else begin
    Button_update.Enabled:=false;
  end;
end;

procedure TForm_update.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  if running then CanClose := false;
end;

procedure TForm_update.Timer_onceTimer(Sender: TObject);
var
  sl :TStringList;
  sl2:TStringList;
  i  :integer;
  str:string;
  bAuto:boolean;
  rtnstr:string;
  ini :TIniFile;
  sID1:string;
  sID2:string;
begin
  Timer_once.Enabled:=false;

  isBeta := false;
  sURL_Info := URL_INFO;
  sURL_DL   := URL_DL;
  ini := TIniFile.Create('AsaServerManegerWin.ini');
  try
    isBeta := ini.ReadBool  ('ASASM_Updater','BetaBranch',false);
    if isBeta then
    begin
      sURL_Info := ini.ReadString('ASASM_Updater','BetaBranchURL_INFO',URL_INFO_BETA);
      sURL_DL   := ini.ReadString('ASASM_Updater','BetaBranchURL_DL',URL_DL_BETA);

      sID1 := StringReplace(sURL_Info,'https://drive.usercontent.google.com/download?id=','',[]);
      sID2 := StringReplace(sURL_DL  ,'https://drive.usercontent.google.com/download?id=','',[]);

      //Lbl_Beta.Caption:=Lbl_Beta.Caption+ ' : ' +sURL_Info;
      Lbl_Beta.Caption := format('%s : %s,%s',[Lbl_Beta.Caption,sID1,sID2]);
      Lbl_Beta.Visible:=isBeta;
    end;
  finally
    ini.Free;
  end;

  if (ParamCount = 1) and (ParamStr(1)='AutoUpdate') then
  begin
    bAuto := true;
    Button_Cancel.Enabled:=false;
    running := true;
  end else begin
    bAuto := false;
  end;

  //if isBeta then rtnstr := FPHTTPClient1.SimpleGet(URL_INFO_BETA)
  //          else rtnstr := FPHTTPClient1.SimpleGet(URL_INFO);
  rtnstr := FPHTTPClient1.SimpleGet(sURL_Info);

  begin
    sl := TStringList.Create;
    sl2:= TStringList.Create;
    try
      sl.Text:=rtnstr;
      Memo_update_detail.Lines.BeginUpdate;
      for i := 0 to sl.Count -1 do
      begin
        if i = 0 then
        begin
          str := sl.Strings[i];
          str := StringReplace(str,'.',',',[rfReplaceAll]);
          sl2.CommaText:=str;
          if (sl2.Count >= 4) then
          begin
            newver_1:=StrToIntDef(sl2[0],0);
            newver_2:=StrToIntDef(sl2[1],0);
            newver_3:=StrToIntDef(sl2[2],0);
            newver_4:=StrToIntDef(sl2[3],0);

            Lbl_newver_val.Caption:=format('%d.%d.%d.%d',[newver_1,newver_2,newver_3,newver_4]);
          end;
        end else begin
          Memo_update_detail.Lines.Add(sl.Strings[i]);
        end;
      end;
      Memo_update_detail.SelStart:=0;
      Memo_update_detail.SelLength:=0;
      Memo_update_detail.Perform(EM_SCROLLCARET, 0, 0);
      Memo_update_detail.Lines.EndUpdate;
    finally
      sl.Free;
      sl2.Free;
    end;
  end;
  if (newver_4 > oldver_4) then
  begin
    Button_update.Enabled:=true;
    Lbl_Status.Caption:='最新版にアップデート出来ます';
    Application.ProcessMessages;
    if bAuto then
    begin
      updateASASM;
    end;
  end else begin
    Lbl_Status.Caption:='ASASMは最新です';
    Application.ProcessMessages;
    if bAuto then
    begin
      running := false;
      sleep(2000);
      close;
    end else begin
      ChB_RunAgain.Visible:=True;
    end;
  end;


end;

end.


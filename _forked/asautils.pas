//=============================================================================
// Mr.XRAY様の以下の記事を参考に作成
// http://mrxray.on.coocan.jp/Delphi/plSamples/330_AppProcessList.htm
//-----------------------------------------------------------------------------
//  Created by Dの人
//=============================================================================

unit asaUtils;

{$mode objfpc}{$H+}

interface

uses
  dialogs,
  tracetime, IdIPWatch,
  LConvEncoding,
  opensslsockets, fphttpclient,
  AsyncProcess, jwaPsApi,
  Zipper, LazFileUtils, FileUtil, StrUtils, fileinfo,
  Forms, Controls, LCLType, ComCtrls,
  Windows, jwatlhelp32, plPrivilegeUnit,
  Classes, SysUtils;

type
  TServerRec = record
    Checked     : string;
    ApiLoader   : string;
    ProfileName : string;
    SessionName : string;
    MapName     : string;
    InstVer     : string;
    Port        : string;
    RCONPort    : string;
    sSrvStatus  : string;
    iSrvStatus  : string;
    Players     : string;
    CPU_Use     : string;
    MemUseMB    : string;
    Uptime      : string;
  end;

  TAsasmVersion = record
    FileVersion : Array [0..3] of integer;
  end;

  THTTPGetThread = class(TThread)
  private
    FURL: string;
    FResponse: string;
    FErrorMessage: string;
    FIsDone: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(const AURL: string);
    property Response: string read FResponse;
    property ErrorMessage: string read FErrorMessage;
    property IsDone: Boolean read FIsDone;
  end;

  TZipProgressHandler = class
  public
    bar:TProgressBar;
    procedure ZipProgress(Sender : TObject; Const Pct : Double);
  end;

function isExecuting(exepath:string):boolean;
function IsExeRunning(const AFullExePath: string): Boolean;
function IsProcessRunning(APid: Cardinal): Boolean;
function EnumWndProc(hWindow: HWND; lPar: Int64):LongBool; Stdcall;
function EnumARKestraWndProc(hWindow: HWND; lPar: Int64):LongBool; Stdcall;
function GetProcessIDFromPath(AExeFullPath: String): Cardinal;
procedure closeServer(fullpath:string);
procedure closeARKestraServer(fullpath:string);
procedure SwitchToThisWindow(h1:HWND;x:bool);stdcall;external user32 Name 'SwitchToThisWindow';
function ZipDirectory(srcPath,destFilePath:string;bar:TProgressBar = nil):boolean;
procedure UnZip(srcFilePath,destPath:string);
procedure CheckZip(srcFilePath,destPath:string);
function  DeleteFolder(FolderName:string):boolean;
procedure HttpGetFile(URL:string;FilePath:string);
function  HttpGet(URL:string):string;
procedure WaitProcess(Proc:TAsyncProcess);
function  ProcessMemoryMB(fullpath:string):integer;
function  ProcessTimeUSE(fullpath:string):integer;
function  ProcessTimePast(fullpath:string):integer;
function  MaybeGetInstVer(fullpath:string):string;
function  GetASASMVersion:TAsasmVersion;

function GetLocalIP:string;
function GetExternalIP:string;

function AsyncGet(const AURL: string): string;

function QueryFullProcessImageNameW(Process: THandle; Flags: DWORD; Buffer: PChar; Size: PDWORD): Boolean; stdcall; external 'kernel32.dll' name 'QueryFullProcessImageNameW';
function QueryFullProcessImageNameA(Process: THandle; Flags: DWORD; Buffer: PChar; Size: PDWORD): Boolean; stdcall; external 'kernel32.dll' name 'QueryFullProcessImageNameA';
function CreateFileW(lpFileName:LPCSTR; dwDesiredAccess:DWORD; dwShareMode:DWORD; lpSecurityAttributes:LPSECURITY_ATTRIBUTES; dwCreationDisposition:DWORD;dwFlagsAndAttributes:DWORD; hTemplateFile:HANDLE):HANDLE; external 'kernel32' name 'CreateFileW';


var
  ParamStr0 :String;
  sl_ModList :TStringList;
  sl_DinoList :TStringList;

const
  FILE_MODLIST_NEW = 'ModList.txt';
  FILE_MODLIST_OLD = 'ModList_OLD.txt';
  FILE_LANGLIST    = 'LangList.txt';
  FILE_STEAMZIP    = 'steamcmd.zip';
  FILE_STEAMERR    = 'steamerrorreporter.exe';
  FILE_UPDATER     = 'ASASM_Updater.exe';
  FILE_GUSINI      = 'GameUserSettings.ini';
  FILE_GAMEINI     = 'Game.ini';
  FILE_UPDEXE      = 'ASASM_Updater.exe';
  FILE_UPDCHK      = 'ASASM_Updater_check.bat';
  FILE_UPDBAT      = 'ASASM_Updater_download.bat';

  ASABAT_STEAM_DL  = 'AsaServerManegerWin_steamcmd_dl.bat';
  ASASMINI         = 'AsaServerManegerWin.ini';

  DIR_LANG      = 'lang\';
  DIR_PROF      = 'Profile\';
  DIR_STEAM     = '\steamcmd';
  DIR_SHOOTERGM = '\ShooterGame';
  DIR_SAVEDARK  = '\Saved\SavedArks';
  DIR_SAVEDARKL = '\Saved\SavedArksLocal';
  DIR_SAVEGAME  = '\Saved\SaveGames';
  DIR_USER      = '\Saved\PersistentUser';
  DIR_CONFIG    = '\Saved\Config\WindowsServer';
  DIR_CONFIGL   = '\Saved\Config\Windows';
  DIR_UPD_OLD   = '\Profile\asasmup\ASA Server Manager_x86-64';
  DIR_UPD_NEW   = '\Profile\asasmup\ASA Server Manager_x86-64_upd';

  URL_IPINFO       = 'http://ipinfo.io/ip';
  URL_OFFISIAL     = 'https://sites.google.com/view/asa-server-manager';
  URL_OFFISIALQA   = 'https://sites.google.com/view/asa-server-manager/QandA';
  URL_OFFISIALFORM = 'https://docs.google.com/forms/d/e/1FAIpQLSffBZYCxqvtxcOhML0wmbEWMAFDM1aD0Hu2_i2GscFyaD4BZg/viewform?usp=pp_url&entry.1686772079=Ver_';
  URL_DOWNLOAD     = 'https://drive.google.com/uc?export=download&id=1oV6mOe5Ng5ZKmtm_6tUDH0qYLEspmJ7T';
  URL_YT_MAIN = 'https://www.youtube.com/@DYG_ch';
  URL_YT_SOUKO = 'https://www.youtube.com/@D_souko';
  URL_TWITTER = 'https://x.com/ASASM_JP';

  FILTER_EXT_SAV     = '*.sav';
  FILTER_EXT_ONL_SAV = '.online.sav';
  EXT_ARLPROFILE     = '.arkprofile';

  ARGS_Update = 'AfterUpdate';

implementation

procedure HttpGetFile(URL:string;FilePath:string);
var
  http : TFPHTTPClient;
begin
  http := TFPHTTPClient.Create(nil);
  try
    http.AllowRedirect:=true;
    http.Get(URL,FilePath);
  finally
    http.Free;
  end;
end;

function  HttpGet(URL:string):string;
var
  http : TFPHTTPClient;
begin
  http := TFPHTTPClient.Create(nil);
  try
    result := http.SimpleGet(URL);
  finally
    http.Free;
  end;
end;

procedure WaitProcess(Proc:TAsyncProcess);
begin
  while (Proc.Running) do
  begin
    sleep(200);
    Application.ProcessMessages;
  end;
end;

procedure closeServer(fullpath:string);
var
  ExeFullPath : String;
  ProcessID   : Int64;
begin
  ExeFullPath := ExpandFileName(fullpath);
  ExeFullPath := fullpath;

  //ExeFullPathのプロセスIDを取得
  //ExeFullPathのプログラムが起動していないと取得できない
  ProcessID := GetProcessIDFromPath(ExeFullPath);

  if ProcessID > 0 then begin
    //EnumWindowsのコールバック関数内でアプリの閉じる作業を実行
    EnumWindows(@EnumWndProc, ProcessID);
  end;

  sleep(1000);
  ProcessID := GetProcessIDFromPath(ExeFullPath);

  if ProcessID > 0 then begin
    //EnumWindowsのコールバック関数内でアプリの閉じる作業を実行
    EnumWindows(@EnumWndProc, ProcessID);
  end;
end;

procedure closeARKestraServer(fullpath:string);
var
  ExeFullPath : String;
  ProcessID   : Int64;
begin
  ExeFullPath := ExpandFileName(fullpath);
  ExeFullPath := fullpath;

  //ExeFullPathのプロセスIDを取得
  //ExeFullPathのプログラムが起動していないと取得できない
  ProcessID := GetProcessIDFromPath(ExeFullPath);

  if ProcessID > 0 then begin
    //EnumWindowsのコールバック関数内でアプリの閉じる作業を実行
    EnumWindows(@EnumARKestraWndProc, ProcessID);
  end;

  sleep(1000);
  ProcessID := GetProcessIDFromPath(ExeFullPath);

  if ProcessID > 0 then begin
    //EnumWindowsのコールバック関数内でアプリの閉じる作業を実行
    EnumWindows(@EnumARKestraWndProc, ProcessID);
  end;
end;

function  ProcessMemoryMB(fullpath:string):integer;
var
  ExeFullPath : String;
  ProcessID   : Int64;
  hProcess : HANDLE;
  pmc : PROCESS_MEMORY_COUNTERS;
begin
  result := 0;
  pmc.WorkingSetSize := 0;
  ExeFullPath := ExpandFileName(fullpath);
  ExeFullPath := fullpath;

  //ExeFullPathのプロセスIDを取得
  //ExeFullPathのプログラムが起動していないと取得できない
  ProcessID := GetProcessIDFromPath(ExeFullPath);

  if ProcessID > 0 then
  begin
    hProcess := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, FALSE, processID );
    if (0 = hProcess) then
    begin
      Writeln('openprocess failed with error-code = ', GetLastError);
      exit;
    end;

    if ( GetProcessMemoryInfo( hProcess, pmc, sizeof(pmc)) ) then
    begin
      result := pmc.WorkingSetSize div (1024 * 1024);
    end;
  end;
end;

function  ProcessTimeUSE(fullpath:string):integer;
var
  ExeFullPath : String;
  ProcessID   : Int64;
  hProcess : HANDLE;
  ProcessTimesCreationTime: TFileTime;
  ProcessTimesExitTime: TFileTime;
  ProcessTimesKernelTime: TFileTime;
  ProcessTimesUserTime: TFileTime;
begin
  result := 0;
  ProcessTimesCreationTime.dwLowDateTime:=0;
  ProcessTimesExitTime.dwLowDateTime:=0;
  ProcessTimesKernelTime.dwLowDateTime:=0;
  ProcessTimesUserTime.dwLowDateTime:=0;
  ExeFullPath := ExpandFileName(fullpath);
  ExeFullPath := fullpath;

  //ExeFullPathのプロセスIDを取得
  //ExeFullPathのプログラムが起動していないと取得できない
  ProcessID := GetProcessIDFromPath(ExeFullPath);

  if ProcessID > 0 then
  begin
    hProcess := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, FALSE, processID );
    if (0 = hProcess) then
    begin
      Writeln('openprocess failed with error-code = ', GetLastError);
      exit;
    end;

    if ( GetProcessTimes(hProcess, ProcessTimesCreationTime, ProcessTimesExitTime, ProcessTimesKernelTime, ProcessTimesUserTime) ) then
    begin
      result := (ProcessTimesKernelTime.dwLowDateTime + ProcessTimesUserTime.dwLowDateTime) div 10000;
    end;
  end;
end;

function  ProcessTimePast(fullpath:string):integer;
var
  ExeFullPath : String;
  ProcessID   : Int64;
  hProcess : HANDLE;
  ProcessTimesKernelTime: TFileTime;
  ProcessTimesUserTime: TFileTime;
  ProcessTimesCreationTime: TFileTime;
  ProcessTimesExitTime: TFileTime;
  u64time : QWord;
begin
  result := 0;
  ProcessTimesCreationTime.dwLowDateTime:=0;
  ProcessTimesExitTime.dwLowDateTime:=0;
  ProcessTimesKernelTime.dwLowDateTime:=0;
  ProcessTimesUserTime.dwLowDateTime:=0;
  ExeFullPath := ExpandFileName(fullpath);
  ExeFullPath := fullpath;

  //ExeFullPathのプロセスIDを取得
  //ExeFullPathのプログラムが起動していないと取得できない
  ProcessID := GetProcessIDFromPath(ExeFullPath);

  if ProcessID > 0 then
  begin
    hProcess := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, FALSE, processID );
    if (0 = hProcess) then
    begin
      Writeln('openprocess failed with error-code = ', GetLastError);
      exit;
    end;

    if ( GetProcessTimes(hProcess, ProcessTimesCreationTime, ProcessTimesExitTime, ProcessTimesKernelTime, ProcessTimesUserTime) ) then
    begin
      //result := (ProcessTimesCreationTime.dwLowDateTime) div 10000000;
      u64time := ProcessTimesCreationTime.dwHighDateTime * $100000000 +
                 ProcessTimesCreationTime.dwLowDateTime;
      result := (u64time - 116444736000000000) div 10000000;
    end;
  end;
end;

function  isExecuting(exepath:string):boolean;
var
  ExeFullPath : String;
  hFileHandle : HFILE;
  ErrorID     : Cardinal;
begin
  ExeFullPath := ExpandFileName(exepath);
  hFileHandle := CreateFile(PChar(UTF8ToCP932(ExeFullPath)),
                             GENERIC_READ or GENERIC_WRITE,
                             0,
                             nil,
                             OPEN_EXISTING,
                             FILE_ATTRIBUTE_NORMAL,
                             0);
  try
    ErrorID := GetLastError;
    if hFileHandle = INVALID_HANDLE_VALUE then
    begin
      if ErrorID = ERROR_SHARING_VIOLATION then
      begin
        result := True;
      end else begin
        result := False;
      end;
    end else begin
      result := False;
    end;
  finally
    CloseHandle(hFileHandle);
  end;
end;

function IsExeRunning(const AFullExePath: string): Boolean;
var
  Snapshot: THandle;
  ProcessEntry: TProcessEntry32;
  ProcessHandle: THandle;
  Modules: array[0..1023] of HMODULE;
  CBNeeded: DWORD;
  ExePath: array[0..MAX_PATH] of Char;
  TargetFullPath: string;
begin
  Result := False;
  TargetFullPath := ExpandFileName(AFullExePath); // パスを正規化

  // システムのプロセススナップショットを作成
  Snapshot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if Snapshot = INVALID_HANDLE_VALUE then Exit;

  try
    ProcessEntry.dwSize := SizeOf(TProcessEntry32);

    // 最初のプロセスを取得
    if Process32First(Snapshot, ProcessEntry) then
    begin
      repeat
        // プロセスIDからハンドルを取得 (パス取得のためには最低限 PROCESS_QUERY_INFORMATION | PROCESS_VM_READ が必要)
        ProcessHandle := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, False, ProcessEntry.th32ProcessID);

        if ProcessHandle <> 0 then
        begin
          try
            // プロセスのメインモジュールのフルパスを取得
            if EnumProcessModules(ProcessHandle, @Modules, SizeOf(Modules), CBNeeded) then
            begin
              if GetModuleFileNameEx(ProcessHandle, Modules[0], ExePath, SizeOf(ExePath)) > 0 then
              begin
                // 取得したパスと対象のパスを比較 (Windowsなので大文字小文字を区別しない)
                if SameFileName(string(ExePath), TargetFullPath) then
                begin
                  Result := True;
                  Break;
                end;
              end;
            end;
          finally
            CloseHandle(ProcessHandle);
          end;
        end;
      until not Process32Next(Snapshot, ProcessEntry);
    end;
  finally
    CloseHandle(Snapshot);
  end;
end;

function IsProcessRunning(APid: Cardinal): Boolean;
var
  Handle: THandle;
begin
  Result := False;
  // プロセスのハンドル取得を試みる
  // PROCESS_QUERY_LIMITED_INFORMATION は Windows Vista 以降で推奨
  Handle := OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, False, APid);

  // 古いOSや権限の関係で失敗した場合は PROCESS_QUERY_INFORMATION を試す
  if Handle = 0 then
    Handle := OpenProcess(PROCESS_QUERY_INFORMATION, False, APid);

  if Handle <> 0 then
  begin
    try
      // ハンドルが取得できれば実行中と判断
      Result := True;
    finally
      CloseHandle(Handle);
    end;
  end;
end;

function EnumWndProc(hWindow: HWND; lPar: Int64):LongBool; Stdcall;
var
  dwProcessID : Cardinal;
begin
  Result := True;
  dwProcessID := 0;

  if IsWindowVisible(hWindow) then
  begin
    GetWindowThreadProcessId(hWindow, dwProcessID);
    if dwProcessID = lPar then
    begin
      PostMessage(hWindow, WM_CLOSE, 0, 0);
    end;
  end;
end;

function EnumARKestraWndProc(hWindow: HWND; lPar: Int64):LongBool; Stdcall;
var
  dwProcessID : Cardinal;
begin
  Result := True;
  dwProcessID := 0;

  if IsWindowVisible(hWindow) then
  begin
    GetWindowThreadProcessId(hWindow, dwProcessID);
    if dwProcessID = lPar then
    begin
      PostMessage(hWindow, WM_APP, 0, 0);
    end;
  end;
end;

function GetProcessIDFromPath(AExeFullPath: String): Cardinal;
const
  PROCESS_QUERY_LIMITED_INFORMATION = $1000;
var
  ListHandle  : Cardinal;
  ProcEntry   : TProcessEntry32;
  ProcessID   : DWORD;
  hProcHandle : THandle;
  ExePath     : String;
  Buff        : array[0..MAX_PATH-1] of Char;
  PCbuff      :PChar;
  STR_SIZE    : DWORD;
begin
  Result := 0;

  //デバッグの特権を有効にする
  plPrivilegeUnit.SetPrivilege(SE_DEBUG_NAME, True);

  //プロセスのスナップショットのハンドルを取得
  ListHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if ListHandle > 0 then begin
    try
      //最初のプロセスに関する情報をTProcessEntry32レコード型に取得
      ProcEntry.dwSize := SizeOf(TProcessEntry32);
      Process32First(ListHandle, ProcEntry);
      repeat
        ExePath := '';
        FillChar(Buff, SizeOf(Buff), #0);

        //プロセスIDを取得
        ProcessID := ProcEntry.th32ProcessID;
        //プロセスID値からプロセスのオープンハンドルを取得
        hProcHandle := OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION,
                                   False,
                                   ProcessID);
        try
          //オープンハンドルからパス名を取得
          if hProcHandle > 0 then begin
            //オープンハンドルからパス名を取得
            STR_SIZE := Length(Buff);
            if QueryFullProcessImageNameA(hProcHandle,
            //if QueryFullProcessImageNameW(hProcHandle,
                                          0,
                                          @Buff,
                                          @STR_SIZE) then begin
              PCbuff := @Buff;
              ExePath := PCbuff;
              //実行ファイル名が同じだったら終了
              //if Trim(ExePath) = Trim(AExeFullPath) then begin
              if Trim(ExePath) = Trim(UTF8ToCP932(AExeFullPath)) then begin
                Result := ProcessID;
                break;
              end;
            end;
          end;
        finally
          CloseHandle(hProcHandle);
        end;
      //次のプロセスに関する情報をTProcessEntry32レコード型に取得
      until Process32Next(ListHandle, ProcEntry) = False;
    finally
      CloseHandle(ListHandle);
    end;
  end;
end;

function ZipDirectory(srcPath,destFilePath:string;bar:TProgressBar = nil):boolean;
var
  AZipper: TZipper;
  szPathEntry: String;
  i: Integer;
  ZEntries: TZipFileEntries;
  TheFileList: TStringList;
  RelativeDirectory: String;
  ZipHandler: TZipProgressHandler;
const
  CERROESTR = 'Zipfile could not be created%sReason: %s';
begin
  AZipper := TZipper.Create;
  ZipHandler := TZipProgressHandler.Create;
  try
    AZipper.OnProgress:=@ZipHandler.ZipProgress;
    ZipHandler.bar:=bar;
    //if (bar <> nil) then bar.Visible:=true;
    try
      AZipper.Filename := destFilePath;
      RelativeDirectory:=srcPath;
      AZipper.Clear;
      ZEntries := TZipFileEntries.Create(TZipFileEntry);
      // Verify valid directory
      If DirPathExists(RelativeDirectory) then
      begin
        // Construct the path to the directory BELOW RelativeDirectory
        // If user specifies 'C:\MyFolder\Subfolder' it returns 'C:\MyFolder\'
        // If user specifies 'C:\MyFolder' it returns 'C:\'
        // If user specifies 'C:\' it returns 'C:\'
        i:=RPos(PathDelim,ChompPathDelim(RelativeDirectory));
        szPathEntry:=LeftStr(RelativeDirectory,i);

        // Use the FileUtils.FindAllFiles function to get everything (files and folders) recursively
        TheFileList:=TstringList.Create;
        try
          FindAllFiles(TheFileList, RelativeDirectory);
          for i:=0 to TheFileList.Count -1 do
          begin
            // Make sure the RelativeDirectory files are not in the root of the ZipFile
            //ZEntries.AddFileEntry(TheFileList[i],CreateRelativePath(TheFileList[i],szPathEntry));
            ZEntries.AddFileEntry(TheFileList[i],UTF8ToCP932(CreateRelativePath(TheFileList[i],szPathEntry)));
          end;
        finally
          TheFileList.Free;
        end;
      end;
      if (ZEntries.Count > 0) then
        AZipper.ZipFiles(ZEntries);
    except
      On E: EZipError do
        E.CreateFmt(CERROESTR, [LineEnding, E.Message])
    end;
    result := True;
  finally
    FreeAndNil(ZEntries);
    AZipper.Free;
    ZipHandler.Free;
    //if (bar <> nil) then bar.Visible:=false;
  end;
end;

procedure UnZip(srcFilePath,destPath:string);
var
  UnZipper: TUnZipper;
begin
  UnZipper := TUnZipper.Create;
  try
    UnZipper.FileName := srcFilePath;
    UnZipper.OutputPath := destPath;
    UnZipper.Examine;
    UnZipper.UnZipAllFiles;
  finally
    UnZipper.Free;
  end;
end;

Procedure TZipProgressHandler.ZipProgress(Sender : TObject; Const Pct : Double);
begin
  if (bar <> nil) then
  begin
    bar.Position:=Trunc(Pct);
    Application.ProcessMessages;
  end;
end;

procedure CheckZip(srcFilePath,destPath:string);
var
  UnZipper: TUnZipper;
begin
  UnZipper := TUnZipper.Create;
  try
    UnZipper.FileName := srcFilePath;
    UnZipper.OutputPath := destPath;
    UnZipper.Examine;
  finally
    UnZipper.Free;
  end;
end;

function  DeleteFolder(FolderName:string):boolean;
begin
  Result:=DeleteDirectory(FolderName,True);
  if Result then
  begin
    Result:=RemoveDirUTF8(FolderName);
  end;
end;

function GetLocalIP:string;
var
  IPW  : TIdIPWatch;
begin
  result := '';
  IPW := TIdIPWatch.Create;
  try
    IPW.HistoryEnabled:=false;
    result := IPW.LocalIP;
  finally
    IPW.Free;
  end;
end;

function GetExternalIP:string;
begin
  result := HttpGet(URL_IPINFO);
end;

function  MaybeGetInstVer(fullpath:string):string;
var
  VersionInfo: TVersionInfo;
  i : integer;
  str:string;
begin
  result := '';
  if FileExists(fullpath) then
  begin
    VersionInfo := TVersionInfo.Create;
    try
      VersionInfo.Load(fullpath);

      for i := 0 to VersionInfo.StringFileInfo.Count -1 do
      begin
        str := VersionInfo.StringFileInfo.Items[i].Values['ArkVersion'];
        if (str <> '') then
        begin
          result:=format('%s',[str]);
          exit;
        end;
      end;
    finally
      VersionInfo.Free;
    end;
  end;
end;

function  GetASASMVersion:TAsasmVersion;
var
  VersionInfo: TVersionInfo;
begin
  //version
  VersionInfo := TVersionInfo.Create;
  try
    VersionInfo.Load(HINSTANCE);
    result.FileVersion[0] := VersionInfo.FixedInfo.FileVersion[0];
    result.FileVersion[1] := VersionInfo.FixedInfo.FileVersion[1];
    result.FileVersion[2] := VersionInfo.FixedInfo.FileVersion[2];
    result.FileVersion[3] := VersionInfo.FixedInfo.FileVersion[3];
  finally
    VersionInfo.Free;
  end;
end;

function AsyncGet(const AURL: string): string;
var
  Thread: THTTPGetThread;
begin
  Thread := THTTPGetThread.Create(AURL);
  try
    // スレッドの処理が終わるまで待機しつつ、UIのメッセージループを回す
    // これによりメインスレッドがフリーズしません
    while not Thread.IsDone do
    begin
      Application.ProcessMessages;
      Sleep(10); // CPU負荷を下げるためのウェイト
    end;

    // スレッド内でエラーが発生していた場合は例外を発生させる
    if Thread.ErrorMessage <> '' then
      raise Exception.Create('HTTP通信エラー: ' + Thread.ErrorMessage);

    Result := Thread.Response;
  finally
    Thread.Free;
  end;
end;

constructor THTTPGetThread.Create(const AURL: string);
begin
  inherited Create(False); // Falseを指定すると即座にスレッドが開始される
  FreeOnTerminate := False; // AsyncGet関数内で手動で解放するためFalseにする
  FURL := AURL;
  FIsDone := False;
end;

procedure THTTPGetThread.Execute;
var
  Client: TFPHTTPClient;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    try
      Client.AllowRedirect := True; // リダイレクトを許可

      // バックグラウンドでGETリクエストを実行
      FResponse := Client.Get(FURL);
    except
      on E: Exception do
        FErrorMessage := E.Message; // エラーが発生した場合はメッセージを保持
    end;
  finally
    Client.Free;
    FIsDone := True; // 処理完了フラグを立てる
  end;
end;

initialization
  ParamStr0 := AnsiToUtf8(ParamStr(0));
  sl_ModList    := TStringList.Create;
  sl_DinoList := TStringList.Create;
  sl_DinoList.LoadFromFile(ExtractFilePath(ParamStr(0))+'DinoData.txt');

finalization
  sl_ModList.Free;
  sl_DinoList.Free;


end.


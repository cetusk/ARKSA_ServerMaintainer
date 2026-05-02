program AsaServerManegerWin;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  winpeimagereader, fileinfo, fileutil, IniFiles,
  Base64, Windows, Forms, sysutils,
  mainui, mainui_arkestra, findui, importui, asaUtils, tracetime, sort_ui,
  MessageTrans, splashui, notify_ui, other_proc_ctl,
  uDarkStyleParams, uDarkStyleSchemes, uMetaDarkStyle, discord
  { you can add units after this };

{$R *.res}

function IsARKestra:boolean;
var
  ini :TIniFile;
begin
  result := false;
  ini := TIniFile.Create(ASASMINI);
  try
    result := ini.ReadBool('mainui','ARKestra',False);
  finally
    ini.Free;
  end;
end;

function IsDarkMode:boolean;
var
  ini :TIniFile;
begin
  result := false;
  ini := TIniFile.Create(ASASMINI);
  try
    result := ini.ReadBool('mainui','DarkMode',False);
  finally
    ini.Free;
  end;
end;

function IsPrevAppExist(AName: string):Boolean;
var
  b64:string;
  errNo :DWord;
begin
  Result := False;
  b64 := EncodeStringBase64(AName);
  CreateMutex(nil, True, PChar(b64));
  errNo := GetLastError;
  if errNo = ERROR_ALREADY_EXISTS then
  begin
    Result := True;
  end;
end;

procedure AfterUpdate;
var
  oldver_4:integer;
  newver_4:integer;
  oldUpdExeDir:string;
  NewUpdExeDir:string;
  oldUpdExe:string;
  NewUpdExe:string;
  VersionInfo: TVersionInfo;
  bAfterUpdate:boolean;
  i :integer;
begin
  bAfterUpdate := false;
  for i := 1 to ParamCount do
  begin
    if ParamStr(i) = ARGS_Update then bAfterUpdate := true;
  end;

  if bAfterUpdate then
  begin
    oldUpdExeDir:=ExtractFileDir(ParamStr0);
    NewUpdExeDir:=ExtractFileDir(ParamStr0)+DIR_UPD_NEW;
    if not DirectoryExists(NewUpdExeDir) then
    begin
      NewUpdExeDir:=ExtractFileDir(ParamStr0)+DIR_UPD_OLD;
    end;
    oldUpdExe := oldUpdExeDir + '\'+FILE_UPDEXE;
    NewUpdExe := NewUpdExeDir + '\'+FILE_UPDEXE;
    oldver_4:=0;
    newver_4:=0;

    if FileExists(oldUpdExe) then
    begin
      VersionInfo := TVersionInfo.Create;
      try
        VersionInfo.Load(oldUpdExe);
        oldver_4 := VersionInfo.FixedInfo.FileVersion[3];
      finally
        VersionInfo.Free;
      end;
    end;

    if FileExists(NewUpdExe) then
    begin
      VersionInfo := TVersionInfo.Create;
      try
        VersionInfo.Load(NewUpdExe);
        newver_4 := VersionInfo.FixedInfo.FileVersion[3];
      finally
        VersionInfo.Free;
      end;
    end;

    if (oldver_4 < newver_4) then
    begin
      closeServer(oldUpdExeDir+'\'+FILE_UPDEXE);
      sleep(1000);
      if FileExists(NewUpdExeDir+'\'+FILE_UPDEXE) then fileutil.CopyFile(NewUpdExeDir+'\'+FILE_UPDEXE,oldUpdExeDir+'\'+FILE_UPDEXE,[cffOverwriteFile,cffCreateDestDirectory,cffPreserveTime]);
      if FileExists(NewUpdExeDir+'\'+FILE_UPDCHK) then fileutil.CopyFile(NewUpdExeDir+'\'+FILE_UPDCHK,oldUpdExeDir+'\'+FILE_UPDCHK,[cffOverwriteFile,cffCreateDestDirectory,cffPreserveTime]);
      if FileExists(NewUpdExeDir+'\'+FILE_UPDBAT) then fileutil.CopyFile(NewUpdExeDir+'\'+FILE_UPDBAT,oldUpdExeDir+'\'+FILE_UPDBAT,[cffOverwriteFile,cffCreateDestDirectory,cffPreserveTime]);
    end;
  end;
end;

begin
  StartTrace('st_');
  RequireDerivedFormResource:=True;

  if IsDarkMode then
  begin
    PreferredAppMode := pamForceDark;
    uMetaDarkStyle.ApplyMetaDarkStyle(DefaultDark);
  end;

  Application.Initialize;

  AfterUpdate;
  if IsPrevAppExist(ParamStr0) then
  begin
    Application.CreateForm(TASA_Notification, ASA_Notification);
  end else begin
    if IsARKestra then Application.CreateForm(TARKestra_ui, ARKestra_ui)
                  else Application.CreateForm(TAsa_ui, Asa_ui);
    Application.CreateForm(TFind_ui, Find_ui);
    Application.CreateForm(TAsa_import_ui, Asa_import_ui);
    Application.CreateForm(Tsortui, sortui);
    Application.CreateForm(TForm_MessageTrans, Form_MessageTrans);
    Application.CreateForm(TForm_Splash_ARKestra, Form_Splash_ARKestra);
  end;

  Application.Run;
end.


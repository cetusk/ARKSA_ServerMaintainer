program AsaServerCommander;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces,
  Classes, SysUtils, IniFiles, asaUtils, other_proc_ctl;

{$R *.res}

var
  ProfName      :string;
  ProfIniPath   :string;
  ProfRelPath   :boolean;
  ProfExePath   :string;
  ProfExeProcId :integer;
  ProfMapName   :string;
  ServerCommand :string;
  i             :integer;
  ini           :TIniFile;
  InstLoc       :string;

begin
  if (ParamCount < 2) then
  begin
    writeln('Bad ARGS.');
    exit;
  end;

  ProfName      := ParamStr(1);
  ServerCommand := ParamStr(2);
  for i := 3 to ParamCount do
  begin
    ServerCommand := ServerCommand + ' ' + ParamStr(i);
  end;

  ProfIniPath := ExtractFilePath(ParamStr(0)) + format('Profile\%s.ini',[ProfName]);
  if not FileExists(ProfIniPath) then
  begin
    writeln(format('Profile Not Found: %s',[ProfIniPath]));
    exit;
  end;

  ini := TIniFile.Create(ProfIniPath);
  try
    ProfRelPath := ini.ReadBool('General','Sys_RelativePath',false);
    InstLoc     := ini.ReadString('General','Edit_Install_Location_Val','');
    ProfMapName := ini.ReadString('General','CB_MapName_Text','');
    if ProfRelPath then
    begin
      ProfExePath := format('%s%s\ShooterGame\Binaries\Win64\ArkAscendedServer.exe',[ExtractFilePath(ParamStr(0)),InstLoc]);
    end else begin
      ProfExePath := format('%s\ShooterGame\Binaries\Win64\ArkAscendedServer.exe',[InstLoc]);
    end;
  finally
    ini.Free;
  end;

  if not FileExists(ProfExePath) then
  begin
    writeln(format('ServerEXE Not Found: %s',[ProfExePath]));
    exit;
  end;

  ProfExeProcId := GetProcessIDFromPath(ProfExePath);
  if (ProfExeProcId = 0) then
  begin
    writeln(format('ServerEXE Not Running: %s',[ProfExePath]));
    exit;
  end;

  begin
    writeln(format('Send ServerCommand to %s[%s]: %s',[ProfName,ProfMapName,ServerCommand]));
    SendCmdOtherWindow(ProfExeProcId,ServerCommand);
  end;

end.


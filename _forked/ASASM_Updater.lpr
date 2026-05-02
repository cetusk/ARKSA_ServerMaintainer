program ASASM_Updater;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Base64, Windows,
  Forms, asasm_upd_ui
  { you can add units after this };

{$R *.res}

function IsPrevAppExist(AName: string):Boolean;
var
  b64:string;
  errNo :DWord;
begin
  Result := False;
  b64 := EncodeStringBase64(AName);
  CreateMutex(nil, True, PChar(b64));
  errNo := GetLastError;
  if errNo = ERROR_ALREADY_EXISTS then begin
    //ShowMessage(format('ASASM [%s] is already executed.',[AName]));
    Result := True;
  end;
end;


begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TForm_update, Form_update);
  if IsPrevAppExist(paramStr(0)) then exit;
  Application.Run;
end.


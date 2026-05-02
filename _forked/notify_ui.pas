unit notify_ui;

{$mode ObjFPC}{$H+}

interface

uses
  asaUtils,
  IniFiles, Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TASA_Notification }

  TASA_Notification = class(TForm)
    Button_OK: TButton;
    Lbl_OK: TLabel;
    Lbl_OK1: TLabel;
    procedure Button_OKClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private

  public

  end;

var
  bARKestra :boolean;
  ASA_Notification: TASA_Notification;

implementation

{$R *.lfm}

{ TASA_Notification }

function IsARKestra:boolean;
var
  ini :TIniFile;
begin
  result := false;
  ini := TIniFile.Create('AsaServerManegerWin.ini');
  try
    result := ini.ReadBool('mainui','ARKestra',False);
  finally
    ini.Free;
  end;
end;

procedure TASA_Notification.Button_OKClick(Sender: TObject);
begin
  close;
end;

procedure TASA_Notification.FormShow(Sender: TObject);
begin
  Lbl_OK.Caption:=format(Lbl_OK.Caption,[ParamStr0]);

  bARKestra := IsARKestra;
  if not bARKestra then
  begin
    Lbl_OK1.Visible:=false;
  end else begin
    Lbl_OK.Visible:=false;
  end;
end;

end.


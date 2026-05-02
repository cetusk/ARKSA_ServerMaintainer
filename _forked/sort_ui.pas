unit sort_ui;

{$mode objfpc}{$H+}

interface

uses
  asaUtils,
  Classes, SysUtils, Forms, Controls, StdCtrls, Grids,
  ComCtrls;

type

  { Tsortui }

  Tsortui = class(TForm)
    Button_Sort_Cancel: TButton;
    Button_Sort_OK: TButton;
    GB_Sort_ModPriority: TGroupBox;
    Lbl_Sort_High: TLabel;
    Lbl_Sort_Low: TLabel;
    SG_Sort: TStringGrid;
    UD_Sort: TUpDown;
    procedure Button_Sort_CancelClick(Sender: TObject);
    procedure Button_Sort_OKClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure UD_SortClick(Sender: TObject; Button: TUDBtnType);
  private
    modlist : TstringList;
  public
    OldModList:boolean;
    beforeMods : string;
    afterMods  : string;
  end;

var
  sortui: Tsortui;

implementation

{$R *.lfm}

{ Tsortui }

procedure Tsortui.Button_Sort_CancelClick(Sender: TObject);
begin
  close;
end;

procedure Tsortui.Button_Sort_OKClick(Sender: TObject);
var
  i :integer;
begin
  afterMods := '';
  for i:=1 to SG_Sort.RowCount -1 do
  begin
    if (i > 1) then afterMods := afterMods + ',';
    afterMods := afterMods + SG_Sort.Cells[0,i];
  end;

  close;
end;

procedure Tsortui.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if (afterMods = '') then afterMods := beforeMods;
  CloseAction := caHide;
end;

procedure Tsortui.FormCreate(Sender: TObject);
begin
  modlist := TStringList.Create;
  modlist.Clear;
  afterMods := '';
end;

procedure Tsortui.FormDestroy(Sender: TObject);
begin
  modlist.Free;
end;

procedure Tsortui.FormShow(Sender: TObject);
var
  sl :TStringList;
  i : integer;
begin
  afterMods := '';
  if (beforeMods = '') then
  begin
    close;
  end;

  if OldModList and FileExists(FILE_MODLIST_OLD) then
  begin
    modlist.LoadFromFile(FILE_MODLIST_OLD);
  end else begin
    if FileExists(FILE_MODLIST_NEW) then modlist.LoadFromFile(FILE_MODLIST_NEW);
  end;

  sl := TStringList.Create;
  try
    sl.CommaText:=beforeMods;
    if sl.Count>0 then
    begin
      SG_Sort.RowCount:=sl.Count+1;
      for i := 0 to sl.Count -1 do
      begin
        SG_Sort.Cells[0,i+1] := sl.Strings[i];
        SG_Sort.Cells[1,i+1] := modlist.Values[sl.Strings[i]];
      end;
    end;
  finally
    sl.Free;
  end;
end;

procedure Tsortui.UD_SortClick(Sender: TObject; Button: TUDBtnType);
var
  str:string;
begin
  if (Button = btNext) then
  begin
    if SG_Sort.Row > 1 then
    begin
      str                             := SG_Sort.Cells[0,SG_Sort.Row];
      SG_Sort.Cells[0,SG_Sort.Row]    := SG_Sort.Cells[0,SG_Sort.Row -1];
      SG_Sort.Cells[0,SG_Sort.Row -1] := str;
      str                             := SG_Sort.Cells[1,SG_Sort.Row];
      SG_Sort.Cells[1,SG_Sort.Row]    := SG_Sort.Cells[1,SG_Sort.Row -1];
      SG_Sort.Cells[1,SG_Sort.Row -1] := str;
      SG_Sort.Row := SG_Sort.Row -1;
    end;

  end else begin
    if SG_Sort.Row < SG_Sort.RowCount -1 then
    begin
      str                             := SG_Sort.Cells[0,SG_Sort.Row];
      SG_Sort.Cells[0,SG_Sort.Row]    := SG_Sort.Cells[0,SG_Sort.Row +1];
      SG_Sort.Cells[0,SG_Sort.Row +1] := str;
      str                             := SG_Sort.Cells[1,SG_Sort.Row];
      SG_Sort.Cells[1,SG_Sort.Row]    := SG_Sort.Cells[1,SG_Sort.Row +1];
      SG_Sort.Cells[1,SG_Sort.Row +1] := str;
      SG_Sort.Row := SG_Sort.Row +1;
    end;
  end;
end;

end.


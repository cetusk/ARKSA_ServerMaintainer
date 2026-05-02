unit importui;

{$mode objfpc}{$H+}

interface

uses
  asaUtils,
  MessageTrans,
  FileUtil,
  Classes, SysUtils, Forms, Controls, Dialogs, ExtCtrls, StdCtrls, ComCtrls;

type

  { TAsa_import_ui }

  TAsa_import_ui = class(TForm)
    Button_Convert_InstallLocation: TButton;
    Button_Convert_Path: TButton;
    Button_Execute: TButton;
    Button_Cancel: TButton;
    Button_Import_bat_Path: TButton;
    Button_Import_Path: TButton;
    CB_Convert_Mapdata: TComboBox;
    CB_Import_Mapdata: TComboBox;
    CB_Restore_ProfileName: TComboBox;
    ChB_New_CopyProfile: TCheckBox;
    CB_ProfileName: TComboBox;
    Edit_Convert_InstallLocation: TEdit;
    Edit_Convert_Path: TEdit;
    Edit_Convert_ProfileName: TEdit;
    Edit_Import_bat_Path: TEdit;
    Edit_Import_Path: TEdit;
    Edit_Import_ProfileName: TEdit;
    GB_Import_Proc_Convert: TGroupBox;
    GB_Import_Proc_Import: TGroupBox;
    GB_Import_Proc_Restore: TGroupBox;
    GB_Import_Proc_New: TGroupBox;
    Lbl_Import1: TLabel;
    Lbl_Import2: TLabel;
    Lbl_Import3: TLabel;
    Lbl_Import4: TLabel;
    Lbl_Import5: TLabel;
    Lbl_Import6: TLabel;
    Lbl_Import7: TLabel;
    Lbl_Import8: TLabel;
    Lbl_Import9: TLabel;
    OpenDialog1: TOpenDialog;
    PC_Import: TPageControl;
    RG_Import_proc: TRadioGroup;
    SelectDirectoryDialog1: TSelectDirectoryDialog;
    Tab_Import_NewASASMProfile: TTabSheet;
    Tab_Import_NonASASMServer: TTabSheet;
    Tab_Import_RestoreASASMProfile: TTabSheet;
    Tab_Import_ConvertLocalData: TTabSheet;
    procedure Button_Import_bat_PathClick(Sender: TObject);
    procedure CloseBtnClick(Sender: TObject);
    procedure Button_Import_PathClick(Sender: TObject);
    procedure Edit_Convert_PathExit(Sender: TObject);
    procedure Edit_Import_PathExit(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormShow(Sender: TObject);
    procedure RG_Import_procSelectionChanged(Sender: TObject);
  private
    beforeImportPath :string;
    beforeConvertPath :string;
    closeFlg :boolean;
  public
    bGoProc : boolean;
    sProfileListComma :String;
  end;

var
  Asa_import_ui: TAsa_import_ui;

implementation

{$R *.lfm}

{ TAsa_import_ui }

procedure TAsa_import_ui.Button_Import_PathClick(Sender: TObject);
begin
  if (SelectDirectoryDialog1.Execute) then
  begin
    if (Sender = Button_Import_Path) then
    begin
      Edit_Import_Path.Text := SelectDirectoryDialog1.FileName;
      Edit_Import_PathExit(Edit_Import_Path);
    end;

    if (Sender = Button_Convert_Path) then
    begin
      Edit_Convert_Path.Text := SelectDirectoryDialog1.FileName;
      Edit_Convert_PathExit(Edit_Convert_Path);
    end;

    if (Sender = Button_Convert_InstallLocation) then
    begin
      Edit_Convert_InstallLocation.Text := SelectDirectoryDialog1.FileName;
    end;
  end;
end;

procedure TAsa_import_ui.Edit_Convert_PathExit(Sender: TObject);
var
  targetDir:string;
  SearchResults: TStringList;
  Item: string;
begin
  if (beforeConvertPath<>Edit_Convert_Path.Text) then
  begin
    beforeConvertPath := Edit_Convert_Path.Text;
    CB_Import_Mapdata.Items.Clear;

    targetDir := Edit_Convert_Path.Text + DIR_SAVEDARKL;
    if DirectoryExists(targetDir) then
    begin
      SearchResults := FindAllDirectories(targetDir, false);
      try
        if SearchResults.Count > 0 then
        begin
          for Item in SearchResults do
          begin
            CB_Convert_Mapdata.Items.Add(ExtractFileName(Item));
          end;
          CB_Convert_Mapdata.ItemIndex:=0;
        end;
      finally
        SearchResults.Free;
      end;
    end;
  end;
end;

procedure TAsa_import_ui.Edit_Import_PathExit(Sender: TObject);
var
  targetDir:string;
  SearchResults: TStringList;
  Item: string;
begin
  if (beforeImportPath<>Edit_Import_Path.Text) then
  begin
    beforeImportPath := Edit_Import_Path.Text;
    CB_Import_Mapdata.Items.Clear;

    targetDir := Edit_Import_Path.Text + DIR_SAVEDARK;
    if DirectoryExists(targetDir) then
    begin
      SearchResults := FindAllDirectories(targetDir, false);
      try
        if SearchResults.Count > 0 then
        begin
          for Item in SearchResults do
          begin
            CB_Import_Mapdata.Items.Add(ExtractFileName(Item));
          end;
          CB_Import_Mapdata.ItemIndex:=0;
        end;
      finally
        SearchResults.Free;
      end;
    end;
  end;
end;

procedure TAsa_import_ui.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  CanClose := closeFlg;
end;

procedure TAsa_import_ui.FormShow(Sender: TObject);
begin
  begin
    RG_Import_proc.Items.Clear;
    RG_Import_proc.Items.Add(Form_MessageTrans.Lbl_Hidden_NewASASMProfile.Caption);
    RG_Import_proc.Items.Add(Form_MessageTrans.Lbl_Hidden_ImportNonASASMServer.Caption);
    RG_Import_proc.Items.Add(Form_MessageTrans.Lbl_Hidden_RestoreASASMProfile.Caption);
    RG_Import_proc.Items.Add(Form_MessageTrans.Lbl_Hidden_ConvertLocalData.Caption);
  end;

  closeFlg := true;
  bGoProc := False;
  beforeImportPath := '';
  beforeConvertPath:= '';
  RG_Import_proc.ItemIndex:=0;

  Edit_Import_Path.Text         := '';
  Edit_Import_ProfileName.Text  := '';
  CB_Import_Mapdata.Text        := '';
  CB_Import_Mapdata.Items.Clear;
  GB_Import_Proc_Import.Enabled := False;

  CB_Restore_ProfileName.Text    := '';
  CB_Restore_ProfileName.Items.Clear;
  GB_Import_Proc_Restore.Enabled := False;

  Edit_Convert_Path.Text           := '';
  Edit_Convert_ProfileName.Text    := '';
  Edit_Convert_InstallLocation.Text := '';
  CB_Convert_Mapdata.Text          := '';
  CB_Convert_Mapdata.Items.Clear;
  GB_Import_Proc_Convert.Enabled   := False;

  PC_Import.ShowTabs:=false;
end;

procedure TAsa_import_ui.RG_Import_procSelectionChanged(Sender: TObject);
var
  SearchResults: TStringList;
  Item: string;
  s : string;
  profileInisComma :string;
  i :integer;
const
  SSVR = 'Server';
  SINI = '*.ini';
begin
  GB_Import_Proc_New    .Enabled := False;
  GB_Import_Proc_Import .Enabled := False;
  GB_Import_Proc_Restore.Enabled := False;
  GB_Import_Proc_Convert.Enabled := False;

  if (RG_Import_proc.ItemIndex = 0) then
  begin
    GB_Import_Proc_New.Enabled := True;

    CB_ProfileName.Items.CommaText:=sProfileListComma;
    for i := CB_ProfileName.Items.Count -1 downto 0 do
    begin
      if (CB_ProfileName.Items[i]='') then CB_ProfileName.Items.Delete(i);
    end;
    CB_ProfileName.ItemIndex:=0;
  end;

  if (RG_Import_proc.ItemIndex = 1) then
  begin
    GB_Import_Proc_Import.Enabled := True;

    profileInisComma := '';
    SearchResults := FindAllFiles(ExtractFilePath(ParamStr0)+DIR_PROF, SINI, false);
    try
      if SearchResults.Count > 0 then
      begin
        for Item in SearchResults do
        begin
          s := ExtractFileName(ChangeFileExt(Item,''));
          profileInisComma := profileInisComma + s + ',';
        end;
      end;

      for i := 1 to 99 do
      begin
        if (pos(SSVR+InttoStr(i),profileInisComma)=0) then
        begin
          Edit_Import_ProfileName.Text := SSVR+InttoStr(i);
          break;
        end;
      end;
    finally
      SearchResults.Free;
    end;
  end;

  if (RG_Import_proc.ItemIndex = 2) then
  begin
    GB_Import_Proc_Restore.Enabled := True;

    CB_Restore_ProfileName.Items.Clear;
    SearchResults := FindAllFiles(ExtractFilePath(ParamStr0)+DIR_PROF, SINI, false);
    try
      if SearchResults.Count > 0 then
      begin
        for Item in SearchResults do
        begin
          s := ExtractFileName(ChangeFileExt(Item,''));
          if (pos(s,sProfileListComma)=0) then CB_Restore_ProfileName.Items.Add(s);
        end;
      end;
      if (CB_Restore_ProfileName.Items.Count <> 0) then CB_Restore_ProfileName.ItemIndex := 0;
    finally
      SearchResults.Free;
    end;
  end;

  if (RG_Import_proc.ItemIndex = 3) then
  begin
    GB_Import_Proc_Convert.Enabled := True;

    profileInisComma := '';
    SearchResults := FindAllFiles(ExtractFilePath(ParamStr0)+DIR_PROF, SINI, false);
    try
      if SearchResults.Count > 0 then
      begin
        for Item in SearchResults do
        begin
          s := ExtractFileName(ChangeFileExt(Item,''));
          profileInisComma := profileInisComma + s + ',';
        end;
      end;

      for i := 1 to 99 do
      begin
        if (pos(SSVR+InttoStr(i),profileInisComma)=0) then
        begin
          Edit_Convert_ProfileName.Text    := SSVR+InttoStr(i);
          Edit_Convert_InstallLocation.Text := ExtractFilePath(ParamStr0)+Edit_Convert_ProfileName.Text;
          break;
        end;
      end;
    finally
      SearchResults.Free;
    end;
  end;

  PC_Import.ActivePageIndex:=RG_Import_proc.ItemIndex;
end;

procedure TAsa_import_ui.CloseBtnClick(Sender: TObject);
const
  SMES_SHOOTERGAME = 'Please Input [ShooterGame]Path.';
  SMES_PROFNAME    = 'Please Input ProfileName.';
  SMES_DUPLICATE   = 'ProfileName[%s] is duplicate.';
  SMES_INSTALLLOC  = 'Please Input InstallLocation.';
begin
  if (Sender = Button_Execute) then
  begin
    if (RG_Import_proc.ItemIndex = 1) then
    begin
      if (Edit_Import_Path.Text = '') then
      begin
        showmessage(SMES_SHOOTERGAME);
        Edit_Import_Path.SetFocus;
        exit;
      end;
      if (Edit_Import_ProfileName.Text = '') then
      begin
        showmessage(SMES_PROFNAME);
        Edit_Import_ProfileName.SetFocus;
        exit;
      end;
      if (pos(Edit_Import_ProfileName.Text+',',sProfileListComma) <> 0) then
      begin
        showmessage(format(SMES_DUPLICATE,[Edit_Import_ProfileName.Text]));
        Edit_Import_ProfileName.SetFocus;
        exit;
      end;
    end;

    if (RG_Import_proc.ItemIndex = 3) then
    begin
      if (Edit_Convert_Path.Text = '') then
      begin
        showmessage(SMES_SHOOTERGAME);
        Edit_Convert_Path.SetFocus;
        exit;
      end;
      if (Edit_Convert_InstallLocation.Text = '') then
      begin
        showmessage(SMES_INSTALLLOC);
        Edit_Convert_InstallLocation.SetFocus;
        exit;
      end;
      if (Edit_Convert_ProfileName.Text = '') then
      begin
        showmessage(SMES_PROFNAME);
        Edit_Convert_ProfileName.SetFocus;
        exit;
      end;
      if (pos(Edit_Convert_ProfileName.Text+',',sProfileListComma) <> 0) then
      begin
        showmessage(format(SMES_DUPLICATE,[Edit_Convert_ProfileName.Text]));
        Edit_Convert_ProfileName.SetFocus;
        exit;
      end;
    end;
    bGoProc := True;
  end;

  Asa_import_ui.Close;
end;

procedure TAsa_import_ui.Button_Import_bat_PathClick(Sender: TObject);
begin
  if (OpenDialog1.Execute) then
  begin
    if (Sender = Button_Import_bat_Path) then
    begin
      Edit_Import_bat_Path.Text := OpenDialog1.FileName;
    end;
  end;
end;

end.


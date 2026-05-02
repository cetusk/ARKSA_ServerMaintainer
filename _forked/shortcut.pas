unit shortcut;

{$mode objfpc}{$H+}

interface

uses
  Base64, SysUtils,
  WinDirs,
  windows;

  procedure CreateStartup(exepath:string);
  procedure DeleteStartup(exepath:string);
  function HasStartup(exepath:string):boolean;
  function createShortcut(lnkpos : widestring; dstfn,dstargs,dstwdir,descr,iconfn : AnsiString; iconnum : longint) : boolean;
  function startupdir:string;
  function ARKestraPath:string;
  function HashBase64(src:string):string;

implementation

type
  REFCLSID = PGUID;
  REFIID   = PGUID;

const
  CLSID_ShellLink  : TGUID = '{00021401-0000-0000-C000-000000000046}';
  IID_IShellLink   : TGUID = '{000214EE-0000-0000-C000-000000000046}';
  IID_IPersistFile : TGUID = '{0000010b-0000-0000-C000-000000000046}';
  CLSCTX_INPROC_SERVER  = 1;

  function CoInitialize(p : pointer) : HRESULT; stdcall;  external 'ole32.dll';
  function CoUninitialize(p : pointer) : HRESULT; stdcall;  external 'ole32.dll';
  function CoCreateInstance(a:REFCLSID; b:pointer; c:DWORD; d:REFIID; e:pointer)  : HRESULT; stdcall;  external 'ole32.dll';

type
  PPISHellLink = ^PISHellLink;
  PISHellLink = ^ISHellLink;
  ISHellLink = packed record
    QueryInterface : function(basis,id,p : pointer) : Hresult; stdcall;
    AddRef : function(basis : pointer) : Hresult; stdcall;
    Release : function(basis : pointer) : Hresult; stdcall;
    GetPath : pointer;
    GetIDList : pointer;
    SetIDList : pointer;
    GetDescription : pointer;
    SetDescription : function(basis : pointer; descr : Pchar) : Hresult; stdcall;
    GetWorkingDirectory : pointer;
    SetWorkingDirectory : function(basis : pointer; descr : Pchar) : Hresult; stdcall;
    GetArguments : pointer;
    SetArguments : function(basis : pointer; args : Pchar) : Hresult; stdcall;
    GetHotkey : pointer;
    SetHotkey : pointer;
    GetShowCmd : pointer;
    SetShowCmd : pointer;
    GetIconLocation : pointer;
    SetIconLocation : function(basis : pointer; iconfile : Pchar; icon : longint) : Hresult; stdcall;
    SetRelativePath : pointer;
    Resolve : pointer;
    SetPath : function(basis : pointer; path : Pchar) : Hresult; stdcall;
  end;

  PPIPersistFile = ^PIPersistFile;
  PIPersistFile  = ^IPersistFile;
  IPersistFile   = packed record
    QueryInterface : function(basis,id,p : pointer) : Hresult; stdcall;
    AddRef : function(basis : pointer) : Hresult; stdcall;
    Release : function(basis : pointer) : Hresult; stdcall;
    GetClassID : function(basis,p : pointer) : Hresult; stdcall;
    IsDirty : function(basis : pointer) : Hresult; stdcall;
    Load : function(basis : pointer; fn : Pchar; dw : dword) : Hresult; stdcall;
    Save : function(basis : pointer; fn : Pchar; dw : dword) : Hresult; stdcall;
    SaveCompleted : function(basis : pointer; fn : Pchar) : Hresult; stdcall;
    GetCurFile : function(basis : pointer; fn : PPchar) : Hresult; stdcall;
  end;

procedure CreateStartup(exepath:string);
var
  lnkpos : widestring;
  dstfn,
  dstargs,
  dstwdir,
  descr,
  iconfn : AnsiString;
  iconnum : longint;
begin
  lnkpos := widestring(startupdir + format('ARKestra_%s.lnk',[HashBase64(exepath)]));
  dstfn  := exepath;
  dstargs:= '';
  dstwdir:= ExtractFilePath(exepath);
  descr  := format('ARKestra Scheduler [%s]',[exepath]);
  iconfn := exepath;
  iconnum:= 0;

  createShortcut(lnkpos,dstfn,dstargs,dstwdir,descr,iconfn,iconnum);
end;

procedure DeleteStartup(exepath:string);
var
  lnkpos : string;
  plnkpos: PChar;
begin
  lnkpos := startupdir + format('ARKestra_%s.lnk',[HashBase64(exepath)]);
  plnkpos:= PChar(lnkpos);
  DeleteFile(plnkpos);
end;

function HasStartup(exepath:string):boolean;
var
  lnkpos : string;
begin
  lnkpos := startupdir + format('ARKestra_%s.lnk',[HashBase64(exepath)]);
  result := FileExists(lnkpos);
end;

function startupdir:string;
begin
  result := GetWindowsSpecialDir(CSIDL_COMMON_STARTUP,false);
end;

function ARKestraPath:string;
begin
  result := ExtractFilePath(ParamStr(0))+'ARKestra.exe';
end;

function HashBase64(src:string):string;
var
  b64 :string;
  //b :Array [0..7] of Byte;
begin
  b64 := EncodeStringBase64(src);
  result := b64;
end;

function createShortcut(lnkpos : widestring; dstfn,dstargs,dstwdir,descr,iconfn : AnsiString; iconnum : longint) : boolean;
var
  psl : PPISHellLink; psp : PPIPersistFile;
begin
  createShortcut := FALSE;
  if CoCreateInstance(@CLSID_ShellLink,nil,CLSCTX_INPROC_SERVER,@IID_IShellLink,@psl)=0 then
  begin
    if  (psl^^.setPath(psl,@dstfn[1])                    =0) and
        (psl^^.SetArguments(psl,@dstargs[1])             =0) and
        (psl^^.SetWorkingDirectory(psl,@dstwdir[1])      =0) and
        (psl^^.SetDescription(psl,@descr[1])             =0) and
        (psl^^.SetIconLocation(psl,@iconfn[1],iconnum)   =0) and
        (psl^^.queryInterface(psl,@IID_IPersistFile,@psp)=0) then
    begin
      if psp^^.save(psp,@lnkpos[1],0)=0 then createShortcut := true;
      psp^^.release(psp);
    end;
    psl^^.Release(psl);
  end;
end;

begin
  CoInitialize(nil);
end.


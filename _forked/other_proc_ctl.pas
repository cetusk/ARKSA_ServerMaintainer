unit other_proc_ctl;

{$mode ObjFPC}{$H+}

interface

uses
  ClipBrd, Windows,
  Classes, SysUtils, Dialogs;

procedure SendCmdOtherWindow(PID:integer;cmd:string);
function GetHWNDFromPID(PID:integer):HWND;
function EnumPIDWndProc(hWindow: HWND; lPar: Int64):LongBool; Stdcall;


implementation

var
  _hWindow: HWND;

procedure SendCmdOtherWindow(PID:integer;cmd:string);
var
  hWindow :HWND;
begin
  hWindow := GetHWNDFromPID(PID);
  if (hWindow = 0) then
  begin
    exit;
  end;
  Clipboard.AsText := cmd;
  SetForeGroundWindow(hWindow);

  Keybd_Event(VK_CONTROL, 1, 0, 0);
  Keybd_Event(VK_A      , 1, 0, 0);
  Keybd_Event(VK_A      , 1, KEYEVENTF_KEYUP, 0);
  Keybd_Event(VK_V      , 1, 0, 0);
  Keybd_Event(VK_V      , 1, KEYEVENTF_KEYUP, 0);
  Keybd_Event(VK_CONTROL, 1, KEYEVENTF_KEYUP, 0);
  Keybd_Event(VK_RETURN , 1, 0, 0);
  Keybd_Event(VK_RETURN , 1, KEYEVENTF_KEYUP, 0);
end;

function GetHWNDFromPID(PID:integer):HWND;
begin
  _hWindow := 0;
  EnumWindows(@EnumPIDWndProc, PID);
  result := _hWindow;
end;

function EnumPIDWndProc(hWindow: HWND; lPar: Int64):LongBool; Stdcall;
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
      _hWindow := hWindow;
    end;
  end;
end;

end.


program NBCall;

{$mode objfpc}{$H+}

uses
  Sysutils, Classes, Windows;

type
  HPCON = Pointer;
  PProcThreadAttributeList = Pointer;

  _STARTUPINFOEXW = record
    StartUpInfo     : TStartupInfow;
    lpAttributeList : PProcThreadAttributeList;
  end;
  STARTUPINFOEXW = _STARTUPINFOEXW;
  TStartUpInfoExW = STARTUPINFOEXW;

  TCreatePseudoConsole = function(size: COORD; hInput,hOutput: THandle; dwFlags: DWORD; out phPC: HPCON): HRESULT; stdcall;
  TClosePseudoConsole = procedure(hPC: HPCON); stdcall;
  TResizePseudoConsole = function(hPC: HPCON; size: COORD): HRESULT; stdcall;

  TInitializeProcThreadAttributeList = function(lpAttributeList : PProcThreadAttributeList; dwAttributeCount: DWORD; dwFlags: DWORD; var lpSize: PtrUInt):BOOL; stdcall;
  TUpdateProcThreadAttribute = function(lpAttributeList : PProcThreadAttributeList; dwFlags: DWORD; Attribute: PtrUInt; lpValue: Pointer; cbSize:PtrUInt; lpPreviousValue: Pointer; lpReturnSize: PPointer):Bool; stdcall;
  TDeleteProcThreadAttributeList = procedure(lpAttributeList : PProcThreadAttributeList); stdcall;

const
  PROC_THREAD_ATTRIBUTE_PSEUDOCONSOLE = $00020016;
  EXTENDED_STARTUPINFO_PRESENT = $00080000;

  ENABLE_VIRTUAL_TERMINAL_PROCESSING = $0004;
  DISABLE_NEWLINE_AUTO_RETURN = $0008;

var
  CreatePseudoConsole : TCreatePseudoConsole;
  ClosePseudoConsole : TClosePseudoConsole;
  ResizePseudoConsole : TResizePseudoConsole;
  InitializeProcThreadAttributeList : TInitializeProcThreadAttributeList;
  UpdateProcThreadAttribute : TUpdateProcThreadAttribute;
  DeleteProcThreadAttributeList : TDeleteProcThreadAttributeList;

type
  TInputForwerderThread = class(TThread)
  private
    FhStdIn: THandle;
    FhPtyInWrite: THandle;
  protected
    procedure Execute; override;
  public
    constructor Create(hPtyInWrite: THandle);
  end;

constructor TInputForwerderThread.Create(hPtyInWrite: THandle);
begin
  inherited Create(false);
  FreeOnTerminate := true;
  FhStdIn := getStdHandle(STD_INPUT_HANDLE);
  FhPtyInWrite := hPtyInWrite;
end;

procedure TInputForwerderThread.Execute;
var
  Buffer: array[0..1023] of byte;
  BytesRead,BytesWritten: DWORD;
begin
  while (not Terminated) do
  begin
    if (ReadFile(FhStdIn,Buffer, sizeof(Buffer), BytesRead, nil)) then
    begin
      if (BytesRead > 0) then
      begin
        WriteFile(FhPtyInWrite, Buffer, BytesRead, BytesWritten, nil);
      end;
    end else begin
      break
    end;
  end;
end;

function LoadConPTYAPIs:boolean;
var
  hKernel32: HMODULE;
begin
  hKernel32 := GetModulehandle('kernel32.dll');
  if (hKernel32 = 0) then exit(false);

  CreatePseudoConsole := TCreatePseudoConsole(GetProcAddress(hKernel32,'CreatePseudoConsole'));
  ClosePseudoConsole := TClosePseudoConsole(GetProcAddress(hKernel32,'ClosePseudoConsole'));
  ResizePseudoConsole := TResizePseudoConsole(GetProcAddress(hKernel32,'ResizePseudoConsole'));
  InitializeProcThreadAttributeList := TInitializeProcThreadAttributeList(GetProcAddress(hKernel32,'InitializeProcThreadAttributeList'));
  UpdateProcThreadAttribute := TUpdateProcThreadAttribute(GetProcAddress(hKernel32,'UpdateProcThreadAttribute'));
  DeleteProcThreadAttributeList := TDeleteProcThreadAttributeList(GetProcAddress(hKernel32,'DeleteProcThreadAttributeList'));

  result := Assigned(CreatePseudoConsole) and
            Assigned(ClosePseudoConsole) and
            Assigned(ResizePseudoConsole) and
            Assigned(InitializeProcThreadAttributeList) and
            Assigned(UpdateProcThreadAttribute) and
            Assigned(DeleteProcThreadAttributeList);
end;

function ConsoleCtrlHandler(dwCtrlType: DWORD): BOOL; stdcall;
begin
  case dwCtrlType of
  CTRL_C_EVENT, CTRL_BREAK_EVENT:
    result := true;
  else
    result := false;
  end;
end;

function RunNBProcess(Command:UnicodeString):integer;
var
  hPtyInRead, hPtyInWrite: THandle;
  hPtyOutRead, hPtyOutWrite: THandle;
  hStdOut, hStdIn: THandle;
  sa: TSecurityAttributes;
  hPC: HPCON;
  ConsoleSize, CurrentConsoleSize: COORD;
  csbi: TConsoleScreenBufferInfo;
  pi: TProcessInformation;
  siEx: TStartUpInfoExW;
  AttrListSize: PtrUInt;
  CmdLine: UnicodeString;
  Buffer: array[0..4095] of byte;
  BytesRead,BytesWritten: DWORD;
  AvailBytes: DWORD;
  ProcExitCode: DWORD;
  ProcessExited: boolean;
  ExitWaitCount: integer;
  ResizeCheckCounter: integer;
  OriginalOutMode, OriginalInMode: DWORD;
  OriginalOutCP, OriginalCP: UINT;
begin
  result := 1;
  hPtyInRead   := 0;
  hPtyInWrite  := 0;
  hPtyOutRead  := 0;
  hPtyOutWrite := 0;
  hPC := nil;

  hStdOut := GetStdHandle(STD_OUTPUT_HANDLE);
  hStdIn  := GetStdHandle(STD_INPUT_HANDLE);

  OriginalOutCP := GetConsoleOutputCP;
  OriginalCP    := GetConsoleCP;
  GetConsoleMode(hStdOut, OriginalOutMode);
  GetConsoleMode(hStdIn , OriginalInMode );

  SetConsoleCtrlhandler(@ConsoleCtrlHandler,true);

  try
    SetConsoleOutputCP(65001);
    SetConsoleCP(65001);
    SetConsoleMode(hStdOut, OriginalOutMode or ENABLE_VIRTUAL_TERMINAL_PROCESSING or DISABLE_NEWLINE_AUTO_RETURN);

    if (not LoadConPTYAPIs) then
    begin
      WriteLn(ErrOutPut, 'Error: Windows Pseudo Console (ConPTY) in not supperted on this OS version.');
      exit;
    end;

    sa.nLength              := sizeof(TSecurityAttributes);
    sa.bInheritHandle       := true;
    sa.lpSecurityDescriptor := nil;

    if (not CreatePipe(hPtyInRead ,hPtyInWrite ,@sa,0)) then exit;
    if (not CreatePipe(hPtyOutRead,hPtyOutWrite,@sa,0)) then exit;

    try
      SetHandleInformation(hPtyInWrite, HANDLE_FLAG_INHERIT, 0);
      SetHandleInformation(hPtyOutRead, HANDLE_FLAG_INHERIT, 0);

      if (GetConsoleScreenBufferInfo(hStdOut, csbi)) then
      begin
        ConsoleSize.X := csbi.srWindow.Right  - csbi.srWindow.Left +1;
        ConsoleSize.Y := csbi.srWindow.Bottom - csbi.srWindow.Top  +1;
      end else begin
        ConsoleSize.X := 80;
        ConsoleSize.Y := 25;
      end;

      if (CreatePseudoConsole(ConsoleSize, hPtyInRead, hPtyOutWrite, 0, hPC) <> S_OK) then exit;

      try
        FillChar(siEx, sizeof(siEx), 0);
        siEx.StartUpInfo.cb := sizeof(TStartUpInfoExW);
        AttrListSize := 0;

        InitializeProcThreadAttributeList(nil, 1, 0, AttrListSize);
        GetMem(siEx.lpAttributeList, AttrListSize);
        try
          if (not InitializeProcThreadAttributeList(siEx.lpAttributeList, 1, 0, AttrListSize)) then exit;
          try
            UpdateProcThreadAttribute(siEx.lpAttributeList, 0, PROC_THREAD_ATTRIBUTE_PSEUDOCONSOLE, hPC, sizeof(hPC), nil, nil);

            CmdLine := Command;
            UniqueString(CmdLine);

            if (createProcessW(nil, PWideChar(CmdLine), nil, nil, false, EXTENDED_STARTUPINFO_PRESENT, nil, nil, siEx.StartUpInfo, pi)) then
            begin
              Closehandle(hPtyInRead)  ; hPtyInRead   := 0;
              Closehandle(hPtyOutWrite); hPtyOutWrite := 0;

              TInputForwerderThread.Create(hPtyOutWrite);

              try
                ProcessExited    := false;
                ExitWaitCount    := 0;
                ResizeCheckCounter := 0;

                while true do
                begin
                  inc(ResizeCheckCounter);
                  if (ResizeCheckCounter > 10) then
                  begin
                    ResizeCheckCounter := 0;
                    if (getConsoleScreenBufferInfo(hStdOut, csbi)) then
                    begin
                      CurrentConsoleSize.X := csbi.srWindow.Right  - csbi.srWindow.Left +1;
                      CurrentConsoleSize.Y := csbi.srWindow.Bottom - csbi.srWindow.Top  +1;
                      if ((CurrentConsoleSize.X <> ConsoleSize.X) or (CurrentConsoleSize.Y <> ConsoleSize.Y)) then
                      begin
                        ConsoleSize := CurrentConsoleSize;
                        if (assigned(ResizePseudoConsole)) then ResizePseudoConsole(hPC, ConsoleSize);
                      end;
                    end;
                  end;

                  AvailBytes := 0;
                  if (not PeekNamedPipe(hPtyOutRead, nil, 0, nil, @AvailBytes, nil)) then break;

                  if (AvailBytes > 0) then
                  begin
                    if (ReadFile(hPtyOutRead, Buffer, sizeof(Buffer), BytesRead, nil)) then
                    begin
                      if (BytesRead > 0) then WriteFile(hStdOut, Buffer, BytesRead, BytesWritten, nil);
                      if (ProcessExited) then ExitWaitCount := 0;
                    end else begin
                      break;
                    end;
                  end else begin
                    if (not ProcessExited) then
                    begin
                      if (waitForSingleObject(pi.hProcess, 10) = WAIT_OBJECT_0) then ProcessExited := true;
                    end else begin
                      inc(ExitWaitCount);
                      if (ExitWaitCount > 20) then break;
                      sleep(10);
                    end;
                  end;
                end;

                if (GetExitCodeProcess(pi.hProcess, ProcExitCode)) then result := integer(ProcExitCode)
                                                                   else result := 0;
              finally
                CloseHandle(pi.hThread);
                CloseHandle(pi.hProcess);
              end;
            end else begin
              WriteLn(ErrOutput, 'Error: Failed to execute command. System Error Code: ', GetLastError);
              result := integer(GetLastError);
            end;
          finally
            DeleteProcThreadAttributeList(siEx.lpAttributeList);
          end;
        finally
          FreeMem(siEx.lpAttributeList);
        end;
      finally
        ClosePseudoConsole(hPC);
      end;
    finally
      if (hPtyInRead   <> 0) then CloseHandle(hPtyInRead);
      if (hPtyInWrite  <> 0) then CloseHandle(hPtyInWrite);
      if (hPtyOutRead  <> 0) then CloseHandle(hPtyOutRead);
      if (hPtyOutWrite <> 0) then CloseHandle(hPtyOutWrite);
    end;
  finally
    SetConsoleCtrlHandler(@ConsoleCtrlHandler,false);
    SetConsoleMode(hStdOut,OriginalOutMode);
    SetConsoleMode(hStdIn ,OriginalInMode);
    SetConsoleOutputCP(OriginalOutCP);
    SetConsoleCP(OriginalCP);
  end;
end;

var
  CmdLineW : UnicodeString;
  P        : PWideChar;
  InQuotes : Boolean;
  ExitCode : Integer;

begin
  if (ParamCount = 0) then
  begin
    WriteLn('Usage: ', ExtractFileName(ParamStr(0)), ' <command>');
    exit;
  end;

  P := GetCommandLineW;
  InQuotes := False;

  While (P^ <> #0) do
  begin
    if (P^ = '"') then
    begin
      InQuotes := not InQuotes;
    end else begin
      if (P^ = ' ') and (not InQuotes) then
      begin
        Inc(P);
        Break;
      end;
    end;
    Inc(P);
  end;

  while (P^ = ' ') do Inc(P);

  CmdLineW := UnicodeString(P);

  if (CmdLineW = '') then
  begin
    WriteLn('Usage: ', ExtractFileName(ParamStr(0)), ' <command>');
    exit;
  end;

  ExitCode := RunNBProcess(CmdLineW);

  Halt(ExitCode);

end.


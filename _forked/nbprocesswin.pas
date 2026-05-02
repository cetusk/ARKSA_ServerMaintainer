unit nbprocesswin;

interface

uses
  Classes, Forms;

var
  NBReturn: string;
  NBOutputCount: Integer;

function RunAsyncNBProcess(cmd: string; output: TStrings): boolean;

implementation

uses
  SysUtils, Process, AsyncProcess, LazUTF8;

function StripANSI(const S: string): string;
var
  i, j: Integer;
begin
  Result := S;
  i := 1;
  while i <= Length(Result) do
  begin
    if Result[i] = #27 then
    begin
      j := i + 1;
      if (j <= Length(Result)) and (Result[j] = '[') then
      begin
        Inc(j);
        while (j <= Length(Result)) and not (Result[j] in ['a'..'z', 'A'..'Z', '@', '^', '~']) do
          Inc(j);
        Delete(Result, i, j - i + 1);
      end
      else
        Delete(Result, i, 1);
    end
    else
      Inc(i);
  end;
end;

function RunAsyncNBProcess(cmd: string; output: TStrings): boolean;
var
  AProcess: TAsyncProcess;
  Buffer: array[1..2048] of Byte;
  BytesRead: Integer;
  sAnsi, sRaw: AnsiString;
  i, LastLineBreak: Integer;
begin
  Result := False;
  NBReturn := '';
  NBOutputCount := 0;
  if output = nil then Exit;
  if not FileExists('NBCall.exe') then Exit;

  AProcess := TAsyncProcess.Create(nil);
  try
    // Use the console proxy wrapper to prevent freezing/buffering issues
    AProcess.Executable := 'NBCall.exe';
    AProcess.Parameters.Add(cmd); 
    AProcess.Options := [poUsePipes, poStderrToOutPut];
    AProcess.ShowWindow := swoHide;
    
    try
      AProcess.Execute;
    except
      on E: Exception do
      begin
        NBReturn := 'Failed to execute: ' + E.Message;
        Exit;
      end;
    end;

    sRaw := '';
    // Continue polling as long as process runs OR there is unread data
    while AProcess.Running or (AProcess.Output.NumBytesAvailable > 0) do
    begin
      Application.ProcessMessages; // process GUI events
      
      if AProcess.Output.NumBytesAvailable > 0 then
      begin
        BytesRead := AProcess.Output.Read(Buffer, Length(Buffer));
        if BytesRead > 0 then
        begin
          SetString(sAnsi, PAnsiChar(@Buffer[1]), BytesRead);
          sRaw := sRaw + sAnsi;

          // Process all complete lines currently in the buffer
          repeat
            LastLineBreak := -1;
            for i := 1 to Length(sRaw) do
            begin
              if (sRaw[i] = #10) or (sRaw[i] = #13) then
              begin
                if (i > 1) then
                begin
                  output.Add(StripANSI(ConsoleToUTF8(Copy(sRaw, 1, i - 1))));
                  Inc(NBOutputCount);
                end
                else if (i = 1) then
                begin
                  output.Add(''); // Add empty line
                  Inc(NBOutputCount);
                end;
                
                if (i < Length(sRaw)) and (sRaw[i] = #13) and (sRaw[i+1] = #10) then
                begin
                  Delete(sRaw, 1, i + 1);
                end
                else
                begin
                  Delete(sRaw, 1, i);
                end;
                
                LastLineBreak := i;
                break; // start over from the new beginning of sRaw
              end;
            end;
          until LastLineBreak = -1;
        end;
      end
      else
      begin
        Sleep(10); // Prevent 100% CPU core usage during polling
      end;
    end;

    // Add any remaining text without a trailing newline
    if Length(sRaw) > 0 then
    begin
      output.Add(StripANSI(ConsoleToUTF8(sRaw)));
      Inc(NBOutputCount);
    end;

    Result := True;
  finally
    AProcess.Free;
  end;
end;

end.

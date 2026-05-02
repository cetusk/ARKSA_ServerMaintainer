unit tracetime;

{$mode objfpc}{$H+}

interface

uses
  Forms, Dialogs, Classes, SysUtils;

procedure StartTrace(ProcStr:string = '');
procedure StopTrace(ProcStr:string = '');
procedure ShowTraceResult;
procedure ClearTraceResult;


implementation

var
  sTraceDataAll :string;
  sTraceCountAll:string;
  sTraceStartAll:string;
  slTraceData :TStringList;
  slTraceCount:TStringList;
  slTraceStart:TStringList;

procedure StartTrace(ProcStr:string);
begin
  if (ProcStr<>'') then
  begin
    slTraceStart.Values[ProcStr] := IntToStr(GetTickCount64);
  end else begin
    sTraceStartAll := IntToStr(GetTickCount64);
  end;
end;

procedure StopTrace(ProcStr:string);
var
  EndTime :integer;
  sTemp :string;
begin
  EndTime := GetTickCount64;
  if (ProcStr<>'') then
  begin
    if (slTraceStart.IndexOfName(ProcStr) >= 0) then
    begin
      sTemp := slTraceStart.Values[ProcStr];
      slTraceData.Values[ProcStr] := IntToStr(StrToIntDef(slTraceData.Values[ProcStr],0) + EndTime - StrToIntDef(sTemp,EndTime));
      sTemp := slTraceCount.Values[ProcStr];
      slTraceCount.Values[ProcStr] := IntToStr(StrToIntDef(sTemp,0) + 1);

      slTraceStart.Delete(slTraceStart.IndexOfName(ProcStr));
    end;
  end else begin
    sTraceDataAll := IntToStr(StrToIntDef(sTraceDataAll,0) + EndTime - StrToIntDef(sTraceStartAll,EndTime));
    sTraceCountAll:= IntToStr(StrToIntDef(sTraceCountAll,0) + 1);
  end;
end;

procedure ShowTraceResult;
var
  sl  :TStringList;
  i   :integer;
  key :string;
  iAll:integer;
begin
  sl := TStringList.Create;
  try
    iAll := 0;
    for i := 0 to slTraceData.Count -1 do
    begin
      key := slTraceData.Names[i];
      iAll:= iAll + StrToIntDef(slTraceData.ValueFromIndex[i],0);
      sl.Add(format('%s:%s:%s',[key,slTraceCount.ValueFromIndex[i],slTraceData.ValueFromIndex[i]]));
    end;
    if (sTraceDataAll <> '') then
    begin
      iAll:= iAll + StrToIntDef(sTraceDataAll,0);
      sl.Add(format('---:%s:%s',[sTraceCountAll,sTraceDataAll]));
    end;
    sl.Add(format('ALL:---:%d',[iAll]));
    showmessage(sl.Text);
  finally
    sl.Free;
  end;

end;

procedure ClearTraceResult;
begin
  slTraceData.Clear;
  slTraceCount.Clear;
  sTraceDataAll  := '';
  sTraceCountAll := '';
end;

initialization
  slTraceData := TStringList.Create;
  slTraceCount:= TStringList.Create;
  slTraceStart:= TStringList.Create;
  sTraceDataAll  := '';
  sTraceCountAll := '';
  sTraceStartAll := '';

finalization
  slTraceData.Free;
  slTraceCount.Free;
  slTraceStart.Free;

end.


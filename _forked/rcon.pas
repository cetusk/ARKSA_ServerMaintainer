unit rcon;

{$mode objfpc}{$H+}

interface

uses
  LConvEncoding,
  IdTCPClient,
  Forms,
  Classes, SysUtils;

type
  RcvData =record
    PacketID  :integer;
    PacketType:integer;
    PacketBody:string;
  end;

  TRCON = class
  protected
    ffPackedID:integer;
    FSendPacket:Array of byte;
    FRecvPacket:Array of byte;
    FPacketSize:integer;
    FPacketID  :Integer;
    FLastErrCD :integer;
    FLastError :string;
    FReturnStr :string;
    FClient : TIdTCPClient;
    FRcvData : RcvData;
    FRunning:Boolean;
  private
    function Recieve_Data:boolean;
    function Recieve_Data2:boolean;
    function Recieve_AUTH:boolean;
    procedure CreatePacket(PacketType:integer;command:string);
    procedure CreateCheckPacket;
    procedure ClearRecvPacket;
    procedure SavePacket;
  public
    bDebug :boolean;
    ip :string;
    port:integer;
    password:string;
    debugstrings :TStrings;
    constructor Create;
    destructor Destroy;override;
    function sendcmd(cmd:string):boolean;
  public
    property LastErrCD :integer read FLastErrCD;
    property LastError :string  read FLastError;
    property ReturnStr :string  read FReturnStr;
    property isRunning :Boolean read FRunning;
  end;

const
  CD_OK                 =   0;
  CD_COMMAND_EMPTY      =  -1;
  CD_PASSWORD_EMPTY     =  -2;
  CD_COMMAND_TOO_LARGE  =  -3;
  CD_REFUSE_REQUEST     = -10;
  CD_REFUSE_AUTH        = -11;
  CD_REFUSE_CONNECTION  = -12;
  CD_ERROR_AUTH_PROCESS = -21;
  CD_ERROR_CMD_PROCESS  = -22;

  SERVERDATA_AUTH           = 3;
  SERVERDATA_AUTH_RESPONSE  = 2;
  SERVERDATA_EXECCOMMAND    = 2;
  SERVERDATA_RESPONSE_VALUE = 0;
  SERVERDATA_CHECK          = 0;

  RECIEVE_BYTES = 4096;
  PACKETSIZE_THRESHOLD = 3072;

implementation

constructor TRCON.Create;
begin
  bDebug := false;
  FLastErrCD :=  0;
  FLastError := '';
  FReturnStr := '';

  ffPackedID := 0;
  ffPackedID := ffPackedID + $FF;
  ffPackedID := ffPackedID + $FF*256;
  ffPackedID := ffPackedID + $FF*256*256;
  ffPackedID := ffPackedID + $FF*256*256;

  FRunning := False;

  ip       := 'localhost';
  port     := 27015;
  password := '';

  FClient := TIdTCPClient.Create;
  FClient.Name:= 'FClient';
  FClient.ReadTimeout:=5000;
end;

destructor TRCON.Destroy;
begin
  FClient.Free;

  inherited;
end;

function TRCON.sendcmd(cmd:string):boolean;
var
  sCMD :string;
begin
  result := False;

  FRunning := True;
  try
    if (cmd = '') then
    begin
      FLastErrCD := CD_COMMAND_EMPTY;
      FLastError := 'Command Empty.';
      exit;
    end;

    if (Length(cmd) >= 4096 - 14) then
    begin
      FLastErrCD := CD_COMMAND_TOO_LARGE;
      FLastError := 'Command Too Large.';
      exit;
    end;

    if (password = '') then
    begin
      FLastErrCD := CD_PASSWORD_EMPTY;
      FLastError := 'Password Empty.';
      exit;
    end;

    try
      FPacketID := Random(65535);
      FClient.Host:=ip;
      FClient.Port:=port;
      FClient.Connect;
    except
      FLastErrCD := CD_REFUSE_CONNECTION;
      FLastError := 'Connection Refused.';
      exit;
    end;

    try
      CreatePacket(SERVERDATA_AUTH,password);
      FClient.IOHandler.Write(FSendPacket,Length(FSendPacket));

      while (not Recieve_AUTH) do
      begin
        sleep(100);
        Application.ProcessMessages;
      end;
      if (FRcvData.PacketID = ffPackedID) then
      begin
        FLastErrCD := CD_REFUSE_AUTH;
        FLastError := 'AUTH Failed.';
        exit;
      end;
    except
      FLastErrCD := CD_ERROR_AUTH_PROCESS;
      FLastError := 'AUTH Process Error.';
      exit;
    end;

    try
      sCMD := cmd;
      CreatePacket(SERVERDATA_EXECCOMMAND,sCMD);
      FClient.IOHandler.Write(FSendPacket,Length(FSendPacket));
      while (not Recieve_Data) do
      begin
        sleep(100);
        Application.ProcessMessages;
      end;

      if (Length(FRcvData.PacketBody)>PACKETSIZE_THRESHOLD) then
      begin
        CreateCheckPacket;
        FClient.IOHandler.Write(FSendPacket,Length(FSendPacket));
        try
          while (not Recieve_Data2) do
          begin
            sleep(100);
            Application.ProcessMessages;
          end;
        except
          FLastErrCD := CD_OK;
          FLastError := '';
        end;
      end;
    except
      FLastErrCD := CD_ERROR_CMD_PROCESS;
      FLastError := 'Command Process Error.';
      exit;
    end;

    FReturnStr := FRcvData.PacketBody;
    FLastErrCD := CD_OK;
    FLastError := '';
  finally
    FClient.Disconnect;
    FRunning := False;
  end;

  result := True;
end;

procedure TRCON.SavePacket;
var
  fs :TFileStream;
  sl :TStringList;
  FileName : string;
  i :integer;
begin
  FileName := FormatDateTime('YYYYMMDD_hhnnss_zzz',now);

  fs := TFileStream.Create(FileName+'.bin1',fmCreate);
  try
    fs.Write(FSendPacket,Length(FSendPacket));
  finally
    fs.Free;
  end;
  fs := TFileStream.Create(FileName+'.bin2',fmCreate);
  try
    for i := 0 to Length(FSendPacket) -1 do
    begin
      fs.Write(FSendPacket[i],1);
    end;
  finally
    fs.Free;
  end;
  sl := TStringList.Create;
  try
    for i := 0 to Length(FSendPacket) -1 do
    begin
      sl.Add(format('%2.2x',[FSendPacket[i]]));
    end;
    sl.SaveToFile(FileName+'.txt');
  finally
    sl.Free;
  end;


end;

procedure TRCON.CreatePacket(PacketType:integer;command:string);
var
  PacketSize :integer;
  i :integer;
begin
  PacketSize := Length(command) +10;

  SetLength(FSendPacket,PacketSize +4);
  for i := 0 to Length(FSendPacket) -1 do FSendPacket[i] := $00;

  // PacketSize (little endian)
  FSendPacket[ 0] := Byte( PacketSize              mod $100);
  FSendPacket[ 1] := Byte((PacketSize div $100)    mod $100);
  FSendPacket[ 2] := Byte((PacketSize div $10000)  mod $100);
  FSendPacket[ 3] := Byte((PacketSize div $1000000)        );

  // PacketID (little endian)
  FSendPacket[ 4] := Byte( FPacketID              mod $100);
  FSendPacket[ 5] := Byte((FPacketID div $100)    mod $100);
  FSendPacket[ 6] := Byte((FPacketID div $10000)  mod $100);
  FSendPacket[ 7] := Byte((FPacketID div $1000000)        );

  // PacketType (little endian)
  FSendPacket[ 8] := Byte( PacketType             mod $100);
  FSendPacket[ 9] := Byte((PacketType div $100)   mod $100);
  FSendPacket[10] := Byte((PacketType div $1000)  mod $100);
  FSendPacket[11] := Byte((PacketType div $100000)       );

  // body
  for i := 0 to Length(command) -1 do
  begin
    FSendPacket[12+i] := Byte(command[i+1]);
  end;
end;

procedure TRCON.CreateCheckPacket;
var
  PacketSize :integer;
  PacketType:integer;
  PackedID:integer;
  i :integer;
begin
  PacketSize := 10;

  SetLength(FSendPacket,PacketSize +4);
  for i := 0 to Length(FSendPacket) -1 do FSendPacket[i] := $00;

  // PacketSize (little endian)
  FSendPacket[ 0] := Byte( PacketSize              mod $100);
  FSendPacket[ 1] := Byte((PacketSize div $100)    mod $100);
  FSendPacket[ 2] := Byte((PacketSize div $10000)  mod $100);
  FSendPacket[ 3] := Byte((PacketSize div $1000000)        );

  // PacketID (little endian)
  PackedID := 0;
  FSendPacket[ 4] := Byte( PackedID              mod $100);
  FSendPacket[ 5] := Byte((PackedID div $100)    mod $100);
  FSendPacket[ 6] := Byte((PackedID div $10000)  mod $100);
  FSendPacket[ 7] := Byte((PackedID div $1000000)        );

  // PacketType (little endian)
  PacketType := SERVERDATA_CHECK;
  FSendPacket[ 8] := Byte( PacketType             mod $100);
  FSendPacket[ 9] := Byte((PacketType div $100)   mod $100);
  FSendPacket[10] := Byte((PacketType div $1000)  mod $100);
  FSendPacket[11] := Byte((PacketType div $100000)       );
end;

procedure TRCON.ClearRecvPacket;
var
  i :integer;
begin
  SetLength(FRecvPacket,RECIEVE_BYTES);
  for i := 0 to Length(FRecvPacket) -1 do FRecvPacket[i] := $00;
end;

function TRCON.Recieve_AUTH:boolean;
var
  PacketSize :integer;
  PackedID:integer;
  PacketType :integer;
begin
  result := false;

  PacketSize := 0;
  PacketType := 0;
  PackedID   := 0;

  ClearRecvPacket;
  FClient.IOHandler.ReadBytes(FRecvPacket,4,False);
  PacketSize := PacketSize + FRecvPacket[0];
  PacketSize := PacketSize + FRecvPacket[1]*256;
  PacketSize := PacketSize + FRecvPacket[2]*256*256;
  PacketSize := PacketSize + FRecvPacket[3]*256*256;

  ClearRecvPacket;
  FClient.IOHandler.ReadBytes(FRecvPacket,PacketSize,False);
  PackedID := PackedID + FRecvPacket[0];
  PackedID := PackedID + FRecvPacket[1]*256;
  PackedID := PackedID + FRecvPacket[2]*256*256;
  PackedID := PackedID + FRecvPacket[3]*256*256;
  if (PackedID <> ffPackedID) and (PackedID <> FPacketID) then exit;

  PacketType := PacketType + FRecvPacket[4];
  PacketType := PacketType + FRecvPacket[5]*256;
  PacketType := PacketType + FRecvPacket[6]*256*256;
  PacketType := PacketType + FRecvPacket[7]*256*256;
  if (PacketType <> SERVERDATA_AUTH_RESPONSE) then exit;

  FRcvData.PacketType:=PacketType;
  FRcvData.PacketID  :=PackedID;
  FRcvData.PacketBody:='';

  result := true;
end;

function TRCON.Recieve_Data:boolean;
var
  PacketSize :integer;
  PackedID:integer;
  PacketType :integer;
  str : string;
  i   :integer;
begin
  result := false;

  PacketSize := 0;
  PacketType := 0;
  PackedID   := 0;

  ClearRecvPacket;
  FClient.IOHandler.ReadBytes(FRecvPacket,4,False);
  PacketSize := PacketSize + FRecvPacket[0];
  PacketSize := PacketSize + FRecvPacket[1]*256;
  PacketSize := PacketSize + FRecvPacket[2]*256*256;
  PacketSize := PacketSize + FRecvPacket[3]*256*256;

  ClearRecvPacket;
  FClient.IOHandler.ReadBytes(FRecvPacket,PacketSize,False);
  PackedID := PackedID + FRecvPacket[0];
  PackedID := PackedID + FRecvPacket[1]*256;
  PackedID := PackedID + FRecvPacket[2]*256*256;
  PackedID := PackedID + FRecvPacket[3]*256*256;
  if (PackedID <> FPacketID) then exit;

  PacketType := PacketType + FRecvPacket[4];
  PacketType := PacketType + FRecvPacket[5]*256;
  PacketType := PacketType + FRecvPacket[6]*256*256;
  PacketType := PacketType + FRecvPacket[7]*256*256;
  if (PacketType <> SERVERDATA_RESPONSE_VALUE) then exit;

  str := '';
  for i := 8 to PacketSize -3 do
  begin
    if (FRecvPacket[i] = 10) then str := str + #13#10
                             else str := str + char(FRecvPacket[i]);
  end;

  FRcvData.PacketType:=PacketType;
  FRcvData.PacketID  :=PackedID;
  FRcvData.PacketBody:=str;

  result := true;
end;

function TRCON.Recieve_Data2:boolean;
var
  PacketSize :integer;
  PackedID:integer;
  PacketType :integer;
  str : string;
  i   :integer;
begin
  result := false;

  PacketSize := 0;
  PacketType := 0;
  PackedID   := 0;

  ClearRecvPacket;
  FClient.IOHandler.ReadBytes(FRecvPacket,4,False);
  PacketSize := PacketSize + FRecvPacket[0];
  PacketSize := PacketSize + FRecvPacket[1]*256;
  PacketSize := PacketSize + FRecvPacket[2]*256*256;
  PacketSize := PacketSize + FRecvPacket[3]*256*256;
  if (PacketSize = 10) then
  begin
    result := true;
    exit;
  end;

  ClearRecvPacket;
  FClient.IOHandler.ReadBytes(FRecvPacket,PacketSize,False);
  PackedID := PackedID + FRecvPacket[0];
  PackedID := PackedID + FRecvPacket[1]*256;
  PackedID := PackedID + FRecvPacket[2]*256*256;
  PackedID := PackedID + FRecvPacket[3]*256*256;
  if (PackedID <> FPacketID) then exit;

  PacketType := PacketType + FRecvPacket[4];
  PacketType := PacketType + FRecvPacket[5]*256;
  PacketType := PacketType + FRecvPacket[6]*256*256;
  PacketType := PacketType + FRecvPacket[7]*256*256;
  if (PacketType <> SERVERDATA_RESPONSE_VALUE) then exit;

  str := '';
  for i := 8 to PacketSize -3 do
  begin
    if (FRecvPacket[i] = 10) then str := str + #13#10
                             else str := str + char(FRecvPacket[i]);
  end;
  debugstrings.Add(str);

  FRcvData.PacketBody:=FRcvData.PacketBody + str;

  if (Length(str) < PACKETSIZE_THRESHOLD) then result := true;
end;

end.


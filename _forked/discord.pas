unit discord;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fphttpclient, opensslsockets, syncobjs, Dialogs, Forms;

type
  // 前方宣言
  TDiscord_Webhook = class;

  // 送信完了時のイベントハンドラ型
  TRequestResultEvent = procedure(Sender: TObject; Success: boolean; ResponseBody: string) of object;

  // 内部使用：送信リクエストデータ
  TRequestItem = class
  public
    URL: string;
    Message: string;
    Source: TDiscord_Webhook; // 送信元インスタンスへの参照
    Cancelled: boolean;       // 送信元が破棄されたかどうかのフラグ
    PCompleteFlag: ^boolean;  // 同期待機用の完了フラグへのポインタ（追加）
  end;

  { TDiscordSenderThread }
  // 送信を順次処理するためのワーカースレッド
  TDiscordSenderThread = class(TThread)
  private
    FQueue: TList;
    FLock: TCriticalSection;
    FEvent: TEvent; // 新しいリクエストが来たことを通知するイベント

    // Synchronize用の一時変数
    FCurrentItem: TRequestItem;
    FCurrentSuccess: boolean;
    FCurrentResponse: string;

    procedure SyncNotify; // メインスレッドで実行される通知メソッド
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddRequest(Item: TRequestItem);
  end;

  { TDiscord_Webhook }
  TDiscord_Webhook = class
  private
    _URL          : string;
    _Message      : string;
    _lastResponse : string;
    _PendingRequests: TList; // このインスタンスが投げた未完了のリクエスト一覧
    _OnResponse   : TRequestResultEvent;

    // スレッドから結果を受け取るメソッド
    procedure HandleRequestComplete(Item: TRequestItem; Success: boolean; ResponseBody: string);
  public
    constructor Create;
    destructor Destroy; override;
  public
    procedure SetURL(sURL:string);
    procedure SetTestMessage(asasm_name,sMessage:string);
    procedure SetSvrStartingMessage(asasm_name,sProfile,sMap:string);
    procedure SetSvrRestartingMessage(asasm_name,sProfile,sMap:string);
    procedure SetSvrOnlineMessage(asasm_name,sProfile,sMap:string);
    procedure SetSvrStoppedMessage(asasm_name,sProfile,sMap:string);
    procedure SetNewASASMMessage(asasm_name,sMessage:string);
    procedure SetNewServerAppMessage(asasm_name,sMessage:string);
  public
    // 非同期送信キューに追加し、完了するまでProcessMessagesしながら待機します。
    // UIをブロックせずに同期的な挙動を実現します。
    function Send:boolean;

    function GetSendResponse:string;
    function GetLastResponse:string;

    // 送信完了時に呼ばれるイベント
    property OnResponse: TRequestResultEvent read _OnResponse write _OnResponse;
  end;

var
  // シングルトンの送信スレッド
  SenderThread: TDiscordSenderThread = nil;

implementation

{ TDiscordSenderThread }

constructor TDiscordSenderThread.Create;
begin
  inherited Create(False); // Start immediately
  FreeOnTerminate := False;
  FQueue := TList.Create;
  FLock := TCriticalSection.Create;
  FEvent := TSimpleEvent.Create;
end;

destructor TDiscordSenderThread.Destroy;
var
  i: Integer;
begin
  Terminate;
  FEvent.SetEvent; // 待機中のスレッドを起こす
  WaitFor;         // スレッドの終了を待つ

  FLock.Enter;
  try
    for i := 0 to FQueue.Count - 1 do
      TObject(FQueue[i]).Free;
    FQueue.Free;
  finally
    FLock.Leave;
  end;

  FLock.Free;
  FEvent.Free;
  inherited Destroy;
end;

procedure TDiscordSenderThread.AddRequest(Item: TRequestItem);
begin
  FLock.Enter;
  try
    FQueue.Add(Item);
  finally
    FLock.Leave;
  end;
  FEvent.SetEvent; // 新しいアイテムがあることを通知
end;

procedure TDiscordSenderThread.SyncNotify;
begin
  // メインスレッドで実行される
  // 送信元が生きていれば（キャンセルされていなければ）、結果を通知する
  if (FCurrentItem <> nil) and (not FCurrentItem.Cancelled) then
  begin
    FCurrentItem.Source.HandleRequestComplete(FCurrentItem, FCurrentSuccess, FCurrentResponse);
  end;
end;

procedure TDiscordSenderThread.Execute;
var
  Req: TRequestItem;
  http: TFPHTTPClient;
  RespStream: TStringStream;
begin
  http := TFPHTTPClient.Create(nil);
  RespStream := TStringStream.Create('');
  try
    while not Terminated do
    begin
      // キューが空なら待機
      FLock.Enter;
      if FQueue.Count = 0 then
      begin
        FEvent.ResetEvent;
        FLock.Leave;
        FEvent.WaitFor(INFINITE); // イベントが来るまで寝る
        if Terminated then break;
        FLock.Enter; // 起きたら再度ロック
      end;

      // キューから取り出し（FIFO）
      if FQueue.Count > 0 then
      begin
        Req := TRequestItem(FQueue[0]);
        FQueue.Delete(0);
      end
      else
        Req := nil;

      FLock.Leave;

      if Req <> nil then
      begin
        // キャンセルされていなければ送信処理
        if not Req.Cancelled then
        begin
          FCurrentSuccess := False;
          FCurrentResponse := '';
          FCurrentItem := Req;

          try
            http.RequestHeaders.Clear;
            http.AddHeader('Content-Type', 'application/json');
            http.RequestBody := TRawByteStringStream.Create(Req.Message);
            try
              RespStream.Size := 0;
              http.Post(Req.URL, RespStream);
              FCurrentResponse := RespStream.DataString;
              if FCurrentResponse = '' then
                FCurrentSuccess := True; // 空レスポンスを成功とみなす（元のロジック準拠）
            except
              on E: Exception do
              begin
                FCurrentSuccess := False;
                FCurrentResponse := 'Error: ' + E.Message;
              end;
            end;
          finally
            http.RequestBody.Free;
          end;

          // メインスレッドに通知
          if not Terminated then
            Synchronize(@SyncNotify);

          self.Sleep(2000);
        end;

        // リクエストアイテムの破棄
        Req.Free;
      end;
    end;
  finally
    http.Free;
    RespStream.Free;
  end;
end;


{ TDiscord_Webhook }

constructor TDiscord_Webhook.Create;
begin
  _URL          := '';
  _Message      := '';
  _lastResponse := '';
  _PendingRequests := TList.Create;
end;

destructor TDiscord_Webhook.Destroy;
var
  i: Integer;
begin
  // このインスタンスが破棄されるため、
  // 処理待ちのリクエストに対してキャンセル（無効化）を通知する
  for i := 0 to _PendingRequests.Count - 1 do
    TRequestItem(_PendingRequests[i]).Cancelled := True;

  _PendingRequests.Free;
  inherited;
end;

procedure TDiscord_Webhook.SetURL(sURL:string);
begin
  _URL := sURL;
end;

procedure TDiscord_Webhook.SetTestMessage(asasm_name,sMessage:string);
const
  //JSON = '{ "content": "%s[%s] : %s" }';
  JSON = '{ "embeds": [{"title":"[Test]Webhook Message","description":"%s","color": 65280,"footer":{"text":"From %s[%s]"}}] }';
var
  sDateTimeNow:string;
begin
  sDateTimeNow := DateTimeToStr(Now());
  //_Message := format(JSON,[asasm_name,sDateTimeNow,sMessage]);
  _Message := format(JSON,[sMessage,asasm_name,sDateTimeNow]);
end;

procedure TDiscord_Webhook.SetSvrStartingMessage(asasm_name,sProfile,sMap:string);
const
  JSON = '{ "embeds": [{"title":"Server Starting...","description":"Profile:%s (%s)","color": 16753920,"footer":{"text":"From %s[%s]"}}] }';
var
  sDateTimeNow:string;
begin
  sDateTimeNow := DateTimeToStr(Now());
  _Message := format(JSON,[sProfile,sMap,asasm_name,sDateTimeNow]);
end;

procedure TDiscord_Webhook.SetSvrRestartingMessage(asasm_name,sProfile,sMap:string);
const
  JSON = '{ "embeds": [{"title":"[Crash]Server restarting...","description":"Profile:%s (%s)","color": 16753920,"footer":{"text":"From %s[%s]"}}] }';
var
  sDateTimeNow:string;
begin
  sDateTimeNow := DateTimeToStr(Now());
  _Message := format(JSON,[sProfile,sMap,asasm_name,sDateTimeNow]);
end;

procedure TDiscord_Webhook.SetSvrOnlineMessage(asasm_name,sProfile,sMap:string);
const
  JSON = '{ "embeds": [{"title":"Server ONLINE","description":"Profile:%s (%s)","color": 65280,"footer":{"text":"From %s[%s]"}}] }';
var
  sDateTimeNow:string;
begin
  sDateTimeNow := DateTimeToStr(Now());
  _Message := format(JSON,[sProfile,sMap,asasm_name,sDateTimeNow]);
end;

procedure TDiscord_Webhook.SetSvrStoppedMessage(asasm_name,sProfile,sMap:string);
const
  JSON = '{ "embeds": [{"title":"Server Stopped!","description":"Profile:%s (%s)","color": 16711680,"footer":{"text":"From %s[%s]"}}] }';
var
  sDateTimeNow:string;
begin
  sDateTimeNow := DateTimeToStr(Now());
  _Message := format(JSON,[sProfile,sMap,asasm_name,sDateTimeNow]);
end;

procedure TDiscord_Webhook.SetNewASASMMessage(asasm_name,sMessage:string);
const
  JSON = '{ "embeds": [{"title":"ASASM: new version arrived","description":"Ver: %s","color": 16777215,"footer":{"text":"From %s[%s]"}}] }';
var
  sDateTimeNow:string;
begin
  sDateTimeNow := DateTimeToStr(Now());
  _Message := format(JSON,[sMessage,asasm_name,sDateTimeNow]);
end;

procedure TDiscord_Webhook.SetNewServerAppMessage(asasm_name,sMessage:string);
const
  JSON = '{ "embeds": [{"title":"ServerApp: new version arrived","description":"BuildID: %s","color": 16777215,"footer":{"text":"From %s[%s]"}}] }';
var
  sDateTimeNow:string;
begin
  sDateTimeNow := DateTimeToStr(Now());
  _Message := format(JSON,[sMessage,asasm_name,sDateTimeNow]);
end;

procedure TDiscord_Webhook.HandleRequestComplete(Item: TRequestItem; Success: boolean; ResponseBody: string);
begin
  // 処理済みリストから削除
  _PendingRequests.Remove(Item);

  // 結果の更新
  _lastResponse := ResponseBody;

  // 待機中のSendメソッドがあれば、フラグを立ててループを終わらせる
  if Item.PCompleteFlag <> nil then
    Item.PCompleteFlag^ := True;

  // イベント発火
  if Assigned(_OnResponse) then
    _OnResponse(Self, Success, ResponseBody);
end;

function TDiscord_Webhook.Send:boolean;
var
  Req: TRequestItem;
  IsFinished: boolean; // 完了待機用フラグ
begin
  result := false;
  IsFinished := false;

  // バリデーション
  if (_URL = '') then
  begin
    _lastResponse := 'Please set URL.';
    exit;
  end;
  if (_Message = '') then
  begin
    _lastResponse := 'No message.';
    exit;
  end;

  // 送信スレッドがなければ作成（安全策）
  if SenderThread = nil then
    SenderThread := TDiscordSenderThread.Create;

  // リクエストアイテムの作成
  Req := TRequestItem.Create;
  Req.URL := _URL;
  Req.Message := _Message;
  Req.Source := Self;
  Req.Cancelled := False;
  Req.PCompleteFlag := @IsFinished; // 待機フラグのアドレスを渡す

  // 管理リストに追加（Destroy時のキャンセルのため）
  _PendingRequests.Add(Req);

  // スレッドキューに追加
  SenderThread.AddRequest(Req);

  _lastResponse := 'Sending...';

  // 完了まで待機（UIブロック回避）
  // スレッドからのSynchronizeコールバックで IsFinished が True になるのを待つ
  while not IsFinished do
  begin
    Application.ProcessMessages;
    Sleep(1); // CPU負荷軽減
  end;

  // 送信完了後の結果判定（レスポンスが空なら成功）
  if _lastResponse = '' then
    result := true
  else
    result := false;
end;

function TDiscord_Webhook.GetSendResponse:string;
begin
  result := _Message;
end;

function TDiscord_Webhook.GetLastResponse:string;
begin
  result := _lastResponse;
end;

// ユニットの初期化と終了処理
initialization
  SenderThread := TDiscordSenderThread.Create;

finalization
  if SenderThread <> nil then
  begin
    SenderThread.Free;
    SenderThread := nil;
  end;

end.

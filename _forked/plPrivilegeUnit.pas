//{$WARNINGS OFF}
//{$WARN SYMBOL_PLATFORM OFF}
//{$WARN UNIT_PLATFORM OFF}
//=============================================================================
//  DEKOさんの「ちっぷす」の以下の記事をユニットにしたもの
//
//  [特権を有効にする]
//  http://ht-deko.minim.ne.jp/tech043.html#tech089
//
//-----------------------------------------------------------------------------
//
//  【履歴】
//
//  2014年08月16日
//
//-----------------------------------------------------------------------------
//
//  【動作確認環境】
//
//  Windows 7 U64(SP1) + Delphi XE(UP1) Pro
//
//  Presented by Mr.XRAY
//  http://mrxray.on.coocan.jp/
//-----------------------------------------------------------------------------
//  modified by Dの人
//  Windows10(64bit)+Lazarus2.0.0の環境で使用できるように改変
//=============================================================================
unit plPrivilegeUnit;

interface

uses Windows;

const
  SE_ASSIGNPRIMARYTOKEN_NAME  = 'SeAssignPrimaryTokenPrivilege';
  SE_AUDIT_NAME               = 'SeAuditPrivilege';
  SE_BACKUP_NAME              = 'SeBackupPrivilege';
  SE_CHANGE_NOTIFY_NAME       = 'SeChangeNotifyPrivilege';
  SE_CREATE_PAGEFILE_NAME     = 'SeCreatePagefilePrivilege';
  SE_CREATE_PERMANENT_NAME    = 'SeCreatePermanentPrivilege';
  SE_CREATE_TOKEN_NAME        = 'SeCreateTokenPrivilege';
  SE_DEBUG_NAME               = 'SeDebugPrivilege';
  SE_INC_BASE_PRIORITY_NAME   = 'SeIncreaseBasePriorityPrivilege';
  SE_INCREASE_QUOTA_NAME      = 'SeIncreaseQuotaPrivilege';
  SE_LOAD_DRIVER_NAME         = 'SeLoadDriverPrivilege';
  SE_LOCK_MEMORY_NAME         = 'SeLockMemoryPrivilege';
  SE_MACHINE_ACCOUNT_NAME     = 'SeMachineAccountPrivilege';
  SE_PROF_SINGLE_PROCESS_NAME = 'SeProfileSingleProcessPrivilege';
  SE_REMOTE_SHUTDOWN_NAME     = 'SeRemoteShutdownPrivilege';
  SE_RESTORE_NAME             = 'SeRestorePrivilege';
  SE_SECURITY_NAME            = 'SeSecurityPrivilege';
  SE_SHUTDOWN_NAME            = 'SeShutdownPrivilege';
  SE_SYSTEM_ENVIRONMENT_NAME  = 'SeSystemEnvironmentPrivilege';
  SE_SYSTEM_PROFILE_NAME      = 'SeSystemProfilePrivilege';
  SE_SYSTEMTIME_NAME          = 'SeSystemtimePrivilege';
  SE_TAKE_OWNERSHIP_NAME      = 'SeTakeOwnershipPrivilege';
  SE_TCB_NAME                 = 'SeTcbPrivilege';
  SE_UNSOLICITED_INPUT_NAME   = 'SeUnsolicitedInputPrivilege';


function SetPrivilege(szPrivilege: String; aEnabled: Boolean): Boolean;

implementation

function SetPrivilege(szPrivilege: String; aEnabled: Boolean): Boolean;
var
  TokenHandle: THandle;
  NewState: TTokenPrivileges;
  OldState: TTokenPrivileges;
  ReturnLength: DWORD;
begin
  result := False;
  TokenHandle := 0;
  NewState.PrivilegeCount:=0;
  OldState.PrivilegeCount:=0;
  ReturnLength := 0;
  if OpenProcessToken(GetCurrentProcess, TOKEN_ADJUST_PRIVILEGES, TokenHandle) then
  begin
    if LookupPrivilegeValue(nil, PChar(szPrivilege), NewState.Privileges[0].Luid) then
    begin
      NewState.PrivilegeCount := 1;
      if aEnabled then
      begin
        NewState.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;
        result := AdjustTokenPrivileges(TokenHandle, False, NewState, SizeOf(NewState), OldState, ReturnLength);
      end else begin
        NewState.Privileges[0].Attributes := 0;
        result := AdjustTokenPrivileges(TokenHandle, True, NewState, 0, OldState, ReturnLength);
      end;
    end;
    CloseHandle(TokenHandle);
  end;
end;

end.

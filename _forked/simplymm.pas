                                                                               {
Memory manager for Free Pascal and Lazarus.

A part of OpenSIMPLY project.

Copyright (C) 2015-2022 Dmitry Yershov

Home page: <opensimply.org/smm/>

Ask a question or report an issue: <opensimply.org/feedback>

This source is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License version 3 as published
by the Free Software Foundation.

This code is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
A PARTICULAR PURPOSE. See the GNU General Public License for more details.

A copy of the GNU General Public License is available on the World Wide Web
at <http://www.gnu.org/copyleft/gpl.html>. You can also obtain it by writing
to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
MA 02111-1307, USA.
                                                                               }

                                                                               {
=== Scope of use 

The Simply Memory Manager (SMM) is a replacement for the native memory
manager for Free Pascal and Lazarus projects on Windows.

Simulation modeling of large and complex systems (and not only simulation)
requires multiple reuse of the maximum amount of available memory.

Free Pascal's memory manager uses certain Windows functions for memory
allocation and freeing, which cause fatal errors when large amount of memory 
is reusing multiple times. In addition, it runs in this case rather slow.

The SMM prevents such errors by using a different approach, and it is much
faster on avalanche-like memory allocation requests.
Run the "TestMemMgr" project to compare the performance.

The SMM has a "reserved memory" feature for the real "out of memory" case
that may prevent critical error.

In some cases, the SMM may be a bit slower than the native memory manager.
This is due to the fact that when using Lazarus IDE, some memory blocks
were already allocated, even when the SMM was the first unit in the "uses"
statement. Therefore, the SMM must also recognize and process requests to
free and reallocate memory blocks already allocated by the native memory
manager. This additional processing can reduce performance somewhat. The
slowdown might probably be noticeable in some cases in the GUI due to the
constant redrawing of graphical controls that use memory reallocation.

=== How to use

Place the SimplySMM unit the first in the "uses" statement.

uses
  SimplyMM,
  ....
  
 
=== The SMM and memory leaks tracing

Do not use the SMM when heap trace manager (HeapTrc) is active. 
In such cases, exclude the SimplySMM unit from the "uses" statement.

uses
  // SimplyMM,
  .... 

                                                                               }

{ $I simdefines.inc}  // Disable this when using out of OpenSIMPLY project.

{$B-} {$R-} {$Q-} {$S-} {$I-} {$OPTIMIZATION LEVEL3}
{$VARSTRINGCHECKS OFF}
{$TYPEDADDRESS OFF}
{$WRITEABLECONST OFF}
{$ASSERTIONS OFF}
{$MINENUMSIZE 1}
{$AsmMode Intel}
{$ImplicitExceptions Off}
{$macro On}

{$ifNdef SIM_DEFINES}
  {$mode objfpc}

{ $define Use_ShortStrings}        // Force enable ShortStrings.

  {$if defined(FPC) and (FPC_VERSION<3)}
    {$define OLD_FPC}
  {$endif}
  {$if defined(OLD_FPC) or defined(Use_ShortStrings)}
    {$H-}
    {$define Use_ShortStrings}
  {$else}
     {$define Use_UTF16}
  {$endif}
{$endif NO SIM_DEFINES}

unit SimplyMM;
                                                                               {
Enable the "Use_Threads_Support" conditional in case of multithreading.
Multithreading support for Unix is not implemented, and, will not.
This option slows down in case of single-thread mode.
                                                                               }
{$define Use_Threads_Support}

                                                                               {
If the "Use_Spinlock" conditional is disabled, the critical section is used.
                                                                               }
{$define Use_Spinlock}

                                                                               {
Enable the "Gather_Heap_Stats" conditional when the "GetHeapStatus" or the
"GetFPCHeapStatus" functions are called frequently. The "MaxHeapSize" and
the "MaxHeapUsed" values for "TFPCHeapStatus" will be gathered too.
This option slows down.
                                                                               }
{$define Gather_Heap_Stats}

                                                                               {
Enable the "Gather_Usage_Stats" conditional for FSB usage stats gathering.
This option slows down.
                                                                               }
{ $define Gather_Usage_Stats}

                                                                               {
Enable the "Gather_Spinlock_Stats" conditional for Spinlock stats gathering.
This option slows down.
                                                                               }
{ $define Gather_Spinlock_Stats}

interface

type

  // Native integer type.
  NInt = NativeInt;

  // Native unsigned integer type.
  NUInt = NativeUInt;

  // An extended error code type.
  TExtErr = LongInt;

  // SMM runtime errors. Can be retrieved using the "SMMLastError".
  TSMMErrors = (
    smmeNoError,
    smmeGetMemoryFailed,
    smmeFreeMemoryFailed,
    smmeUnexpectedFreeBlock,
    smmeMemoryStatusFailed,
    smmeMemoryAccessFailed,
    smmeCheckMemoryFailed,
    smmeInvalidHeader,
    smmeNoFSBInitialized
  );

  // Program termination handler type.
  TTerminateProgram = procedure(ExitCode: TExtErr);


  // Basic string type.
  TSMMString = {$ifdef Use_UTF16}
               UnicodeString
               {$else}
               ShortString
               {$endif};

  // Error handler type.
  TShowError = procedure(Msg: TSMMString; ExtErrorCode: TExtErr);

const

  KiB = 1024;
  MiB = KiB*KiB;

var

  // The reserved memory default value.
  // Change it if necessary.
  ReservedMemorySize: NInt = 10*MiB;

  // It becomes "true" on "Out of memory error".
  IsOutOfMemory: boolean = false;

  // Controls the actions on "Out of memory" error.
  // If it is "true", no actions will be done.
  IsOutOfMemoryIgnored: boolean = false;

  // Custom program termination handler.
  CustomTerminateProgram: TTerminateProgram = nil;

  // Custom error handler.
  CustomShowError: TShowError = nil;

  // Custom "Out of memory" notifier.
  CustomNotifyOutOfMemory: procedure = nil;

  // Custom "Out of memory" fatal error handler.
  CustomFatalErrorOutOfMemory: procedure = nil;

type

  TOutTextMM = procedure(Msg: TSMMString; IsEOL: boolean = false);
  TPOutTextMM = ^TOutTextMM;

  TVersion = record
    case boolean of
    true: (Major, Minor: Byte);
    false: (Value: Word;)
  end;

var

  // Custom text output handler.
  // It is used for error and data output.
  CustomOutTextMM: TOutTextMM = nil;

  // Pointer to custom text output handler.
  // It is used for error and data output.
  PCustomOutTextMM: TPOutTextMM = nil;


// Returns "true" is Simply Memory Manager is set.
function IsUsed: boolean;

// Returns the SMM version.
function GetVersion: TVersion;

// Returns the SMM version as a text string.
function GetVersionAsStr: TSMMString;

// Returns the last error saved value and resets the saved value.
function SMMLastError: TSMMErrors;

// Checks and reserves the Reserved memory block.
procedure AllocateReservedMemory;

// Sets the size of reserved memory block and allocates it.
// If reserved memory block was already allocated, it is freed.
procedure SetReservedMemorySize(SizeInBytes: NInt);

// Restores saved memory manager.
function RestoreSavedMemoryManager(DoForce: boolean = false): boolean;

// Sets SMM as memory manager.
procedure SetSimplyMemoryManager;

// Displays fixed size block containers information.
procedure ShowFSBContInfo;

// Checks fixed size blocks memory alignment.
procedure CheckFSBMemAddr;

// Displays statistics of fixed size block containers usage.
procedure ShowFSBContUsageStats(NoWarning: boolean = false);

// Sets the parameters of fixed size block container.
function SetFSBContainer(AIndex,AUnitsPerBlock,ANumBlocks: NInt): boolean;

// Initializes the FSBs.
function InitFBSContainers: boolean;

// Displays spinlock statistics.
procedure ShowSpinlockStat(NoWarning: boolean = false);

// Displays heap information.
procedure ShowHeapStatus(NoWarning: boolean = false);

implementation

{$Hints Off} {$Warnings Off} {$B-}

uses
  {$ifdef MSWindows}
  Windows;
  {$endif MSWindows}
  {$ifdef Unix}
  {$undef Use_Threads_Support}
  BaseUnix;
  {$endif Unix}

const

  Version: TVersion = (Major: 2; Minor: 2);

                                                                               {
  SMM uses fixed size blocks (FSB) and variable size blocks (VSB).

  The FSBs have a limited number of possible sizes.

  The VSBs can have any size but not less than the size of a maximum FSB.
  This value is defined on runtime from the "FSBMaxDataSize". So it is a
  flexible one and can be changed manually.

  The FSBs of the same size are grouped into FSB-container (FSBC). These
  containers are created on SMM unit initialization. It is possible to
  change the FSBC parameters to custom values even on runtime.
  
  The maximum number of FSB-containers is "MaxFSBCTypes".
                                                                               }
  MaxFSBCTypeIndex = 255;
  MaxFSBCTypes = MaxFSBCTypeIndex + 1;

                                                                               {
  Every FSB consists of a certain number of memory units.
  The maximum number of units of FSB is the "MaxUnits".
                                                                               }
  MaxUnits = MaxFSBCTypes*MaxFSBCTypes-1;

                                                                               {
  The standard unit size is 16 bytes. Use any other if necessary.
  The size of the unit must be a multiple of 16.
                                                                               }
  UnitSize = 16;

                                                                               {
  The FSBCs of a particular type can contain a different number of FSBs at
  initialization and at runtime to quickly increase the pool of available
  blocks of a specified size.

  However, the maximum FSBC size is limited. That means that the total memory
  size of all blocks in one FSBC cannot exceed the "MaxFSBCSize" value.
  Change this value for each platform as needed.
                                                                               }
  MaxFSBCSize = {$ifdef CPU32}4*MiB;{$endif CPU32}
                {$ifdef CPU64}8*MiB;{$endif CPU64}

                                                                               {
  The number of the FSBC types is defined for each platform. Change this
  value for each platform when other number of types will be used.
  The maximum value is "MaxFSBCTypes".
                                                                               }
  CustomMaxFSBCType = {$ifdef CPU32}181;{$endif CPU32}
                      {$ifdef CPU64}180;{$endif CPU64}

  {$if CustomMaxFSBCType>MaxFSBCTypes}
  {$error The CustomMaxFSBCType exceeds the MaxFSBCTypes value}
  {$endif}

                                                                               {
  The number of units per FSB for the container with the maximum index.
  Change this value for each platform respectively if necessary.
  The maximum value is "MaxUnits".
                                                                               }

  FSBMaxUnits = {$ifdef CPU32}12166;{$endif CPU32}
                {$ifdef CPU64}12286;{$endif CPU64}

  {$if FSBMaxUnits>MaxUnits}
  {$error The FSBMaxUnits exceeds the MaxUnits value}
  {$endif}

type

  TBlockID = Longint;
  TPBlockID = ^TBlockID;

const

  // These values identify the SMM blocks on freeing and relocating.

  FSB_ID = TBlockID($ccc055aa);
  VSB_ID     = TBlockID($ccc155aa);
  FREE_FSB   = TBlockID($cccf55aa);

  // Basic values.

  BlockIDSize = SizeOf(TBlockID);

  PtrSize = SizeOf(Pointer);

  CustomMaxFSBCTypeIndex = CustomMaxFSBCType - 1;

type

  TLockValue = Longint;
  TPLockValue = ^TLockValue;

  TPVSB = ^TVSB;

  TVSBHeader = packed record
    Pred,
    Suc: TPVSB;
    {$ifdef CPU32}
    AligningPadding1: Longint;
    AligningPadding2: Longint;
    {$endif CPU32}
    Locked: TLockValue;
    DataSize,
    BlockSize: Longint;
    BlockID: TBlockID;
  end;

  TVSB = packed record
    Header: TVSBHeader;
    Data: Pointer;
  end;

  TPPVSB = ^TPVSB;

  TPCont = ^TContHeader;

  TPFSB = ^TFSB;

  TContHeader = packed record
    Main,
    Pred,
    Suc: TPCont;
    FreePFSB: TPFSB;
    {$ifdef CPU32}
    {$ifdef Gather_Heap_Stats}
    Overhead: Longint;
    AligningPadding1: Longint;
    {$else}
    AligningPadding1: Longint;
    AligningPadding2: Longint;
    {$endif}
    {$endif CPU32}
    {$ifdef CPU64}
    {$ifdef Gather_Heap_Stats}
    Overhead: Longint;
    AligningPadding1: Longint;
    AligningPadding2: Pointer;
    {$else}
    AligningPadding1: Pointer;
    AligningPadding2: Pointer;
    {$endif}
    {$endif CPU64}
    Locked: TLockValue;
    Index,
    BlockSize,
    UnitsPerBlock,
    NumBlocks,
    DataSize,
    DataUnitsPerBlock,
    FreeBlockCount,
    Size,
    SizeLimit,
    StdCount,
    SizeLimitCountInc: Longint;
  end;

  TFSBHeader = packed record
    PCont: TPCont;
    {$ifdef CPU64}
    AligningPadding: Longint;
    {$endif CPU64}
    BlockID: TBlockID;
  end;

  TFSB = packed record
    Header: TFSBHeader;
    case boolean of
    true:  (PFreeFSB: TPFSB);
    false: (Data: Pointer);
  end;

  TContInitData = record
    UnitsPerBlock,
    NumBlocks: NInt;
  end;

const

  FSBHeaderSize = SizeOf(TFSBHeader);

  {$if FSBHeaderSize>UnitSize}
  {$fatal The size of TFSBHeader exceeds UnitSize}
  {$endif}

  VSBHeaderSize = SizeOf(TVSBHeader);
  ContHeaderSize = SizeOf(TContHeader);
  StdMaxUnitsIndex = FSBMaxUnits;

  FSBFirstUnitDataSize = UnitSize - FSBHeaderSize;

  MinUnitsPerBlock = {$if FSBFirstUnitDataSize>0}1{$else}2{$endif};

  LockValue   = 1;
  UnlockValue = 0;

  FSBContSysMaxIndex = 255;

  MaxBlocks = 4096;

var

  FSBContMaxIndex: NInt = -1;
  FSBMaxDataSize: NInt = 0;

  Granularity: NInt;

  CorrespondenceTable: array [0..StdMaxUnitsIndex] of byte;

  FSBContainersInitialized: boolean = false;
  FSBContainers: array [0..CustomMaxFSBCTypeIndex] of TContHeader;
  PVSBs: TPVSB;

  {$ifdef Gather_Usage_Stats}
  FSBStatsGetMem,
  FSBStatsFreeMem: array [0..StdMaxUnitsIndex] of NInt;

  AddFSBContainerCount,
  FreeFSBContainerCount: NInt;
  {$endif Gather_Usage_Stats}

  SimplyMM_IsUsed: boolean = false;

  SimplyMemoryManager,
  SavedMemoryManager: TMemoryManager;

  PReservedMemory: Pointer = nil;

  {$ifdef Use_Threads_Support}
  CheckMemoryLock: TLockValue = UnlockValue;

  {$ifNdef Use_Spinlock}
  CSCount: NInt = 0;
  CS: TCriticalSection;
  {$endif}
  {$endif Use_Threads_Support}
  

  SimplyMMFPCHeapStatus: TFPCHeapStatus;

  SimplyOverhead: NInt;

  {$ifdef Gather_Heap_Stats}
  SimplyHeapStatLock: TLockValue = UnlockValue;
  {$endif Gather_Heap_Stats}

  _SMMLastError: TSMMErrors = smmeNoError;

const

  EOL = LineEnding;
  DEOL = EOL + EOL;
  TEOL = DEOL + EOL;

  {$ifdef Unix}
  clib = 'c';
  {$endif Unix}

{$ifdef Unix}
function usleep(usec: Longword):Longint; cdecl; external clib name 'usleep';
{$endif Unix}

function IsUsed: boolean;
begin
  result:=SimplyMM_IsUsed;
end;


function SMMLastError: TSMMErrors;
begin
  result:=_SMMLastError;
  _SMMLastError:=smmeNoError;
end;

//------------------------------------------------------------------------------

const
  ConvStrMaxLength = 23;

type
  TConvString = string[ConvStrMaxLength];

function IntToStr(Value: NInt; Len: byte = 0): TConvString;
begin
  if Len>ConvStrMaxLength then
    Len:=ConvStrMaxLength;

  Str(Value:Len,result);
end;

const
  PtrHexStrLength = PtrSize*2;

function UIntToHex(Value: NUInt; Len: Smallint = PtrHexStrLength): TConvString;
const
  HexDig: array[0..$F] of TAnsiChar = '0123456789ABCDEF';
var
  i,j: NInt;
  TruncZeros: boolean;
begin
  result:='';

  if Len<0 then
    exit;

  if Len=0 then
  begin
    TruncZeros:=true;
    Len:=PtrHexStrLength;

    if Len=0 then
      exit;
  end
  else
    TruncZeros:=false;

  SetLength(result,Len);

  for i:=0 to Len-1 do
  begin
    result[Len-i]:=HexDig[(Value and $F)];
    Value:=Value shr 4;
  end;

  if TruncZeros then
  begin
    j:=1;

    for i:=1 to PtrHexStrLength-1 do
     if result[i]<>'0' then
     begin
       j:=i;
       break;
     end;

    result:=Copy(result,j,PtrHexStrLength);
  end;
end;

function PtrToHex(Value: Pointer; Len: Smallint = PtrHexStrLength): TConvString;
begin
  result:=UIntToHex(NUInt(Value),Len);
end;

function GetVersion: TVersion;
begin
  result:=Version;
end;

function GetVersionAsStr: TSMMString;
begin
  result:=IntToStr(Version.Major) + '.' + IntToStr(Version.Minor);
end;


//------------------------------------------------------------------------------

procedure StdTerminateProgram(ExitCode: TExtErr);
begin
  {$ifdef MSWindows}
  TerminateProcess(GetCurrentProcess,Longword(ExitCode));
  {$endif MSWindows}
  {$ifdef Unix}
  fpExit(2);
  {$endif Unix}
end;

procedure TerminateProgram(ExitCode: TExtErr);
begin
  if Assigned(CustomTerminateProgram) then
    CustomTerminateProgram(ExitCode)
  else
    StdTerminateProgram(ExitCode);
end;

procedure StdOutTextMM(Msg: TSMMString; IsEOL: boolean = false);
begin
  if not IsConsole then
    exit;

  Write(Msg);

  if IsEOL then
    WriteLn;
end;

procedure OutTextMM(Msg: TSMMString; IsEOL: boolean = false);
begin
  if Assigned(CustomOutTextMM) then
    CustomOutTextMM(Msg,IsEOL)
  else
    if Assigned(PCustomOutTextMM) then
      PCustomOutTextMM^(Msg,IsEOL)
    else
      StdOutTextMM(Msg,IsEOL);
end;

const
  TxtPressEnter = 'Press <enter> ';

procedure ConfirmTTY(Msg: TSMMString = '');
begin
  if not IsConsole then
    exit;

  if Msg='' then
    Msg:='to continue.';

  OutTextMM(TxtPressEnter+Msg,true);
  ReadLn;
end;

type

  TSMMPChar = {$ifdef Use_UTF16}
              PWideChar
              {$else}
              PAnsiChar
              {$endif};


procedure StdGUIShowError(Msg: TSMMPChar);
{$ifdef MSWINDOWS}
begin
  {$ifdef Use_UTF16}
  MessageBoxW
  {$else}
  MessageBoxA
  {$endif}
    (0,Msg,'',MB_OK or MB_TASKMODAL or MB_DEFAULT_DESKTOP_ONLY);
{$else}
begin
{$endif}
end;

procedure StdShowError(Msg: TSMMString; ExtError: TExtErr);
const
  Header = EOL+'SIMPLY MEMORY MANAGER: CRITICAL ERROR OCCURRED'+TEOL;
  TxtForPrgTerm = 'for program termination.';
{$ifNdef Use_UTF16}
var
  S: AnsiString;
{$endif}
begin
  if Msg='' then
    Msg:='Error code: '+IntToStr(ExtError);

  if IsConsole then
  begin
    OutTextMM(Header,true);
    OutTextMM(Msg,true);
    OutTextMM(TEOL,true);
    ConfirmTTY(TxtForPrgTerm);
  end
  else
  begin
    {$ifdef Use_UTF16}
    StdGUIShowError(TSMMPChar(Header+Msg+TEOL+TxtPressEnter+TxtForPrgTerm));
    {$else}
    S:=Header+Msg+TEOL+TxtPressEnter+TxtForPrgTerm;
    StdGUIShowError(TSMMPChar(S));
    {$endif};
  end;

  TerminateProgram(ExtError);
end;

procedure ShowError(Msg: TSMMString; ExtError: TExtErr);
begin
  if Assigned(CustomShowError) then
    CustomShowError(Msg,ExtError)
  else
    StdShowError(Msg,ExtError);
end;

procedure StdNotifyOutOfMemory;
begin
  IsOutOfMemory:=true;
end;

procedure NotifyOutOfMemory;
begin
  if Assigned(CustomNotifyOutOfMemory) then
    CustomNotifyOutOfMemory
  else
    StdNotifyOutOfMemory;
end;

procedure StdFatalErrorOutOfMemory;
begin
  ShowError('Out of memory.',1);
end;

procedure FatalErrorOutOfMemory;
begin
  if Assigned(CustomFatalErrorOutOfMemory) then
    CustomFatalErrorOutOfMemory
  else
    StdFatalErrorOutOfMemory;
end;

{$ifNdef Use_Threads_Support}
{$undef Use_Spinlock}
{$endif Use_Spinlock}

{$ifNdef Use_Spinlock}
{$undef Gather_Spinlock_Stats}
{$endif Use_Spinlock}

{$ifdef Use_Threads_Support}

{$ifdef Use_Spinlock}

{ $define Use_Sleep}

{$ifdef Gather_Spinlock_Stats}
var
  LocalSpinlockCount: NInt;
  SpinlockCount: NInt = 0;
  MaxSpinlockCount: array[0..63] of NInt;
{$endif Gather_Spinlock_Stats}

procedure ThreadLock(BoolPtr: Pointer); assembler; nostackframe;
asm
{$ifdef CPU32}
            {$ifdef Use_Sleep}
            mov     [esp-4],eax
            mov     [esp-8],ebx
            lea     esp,[esp-8]
            mov     ebx,4
            {$endif Use_Sleep}

            mov     ecx,eax

            {$ifdef Gather_Spinlock_Stats}
            mov     LocalSpinlockCount,0
            {$endif Gather_Spinlock_Stats}

@_repeat:   xor     eax,eax
            mov     dl,1
       lock cmpxchg [ecx],dl
            test    al,al
            je      @_exit

            {$ifdef Use_Sleep}
            push    ebx

            {$ifdef MSWindows}
            call    Sleep
            {$endif MSWindows}
            {$ifdef Unix}
            call    uSleep
            add     esp,4
            {$endif Unix}

            shl     ebx,1
            mov     ecx,[esp+4]
            {$endif Use_Sleep}

            {$ifdef Gather_Spinlock_Stats}
            inc     SpinlockCount
            inc     LocalSpinlockCount
            {$endif Gather_Spinlock_Stats}

            jmp     @_repeat
@_exit:
            {$ifdef Gather_Spinlock_Stats}
            mov     eax,LocalSpinlockCount
            shl     eax,2
            inc     dword ptr MaxSpinlockCount[eax]
            {$endif Gather_Spinlock_Stats}

            {$ifdef Use_Sleep}
            mov     ebx,[esp]
            lea     esp,[esp+8]
            {$endif Use_Sleep}
{$endif CPU32}
{$ifdef CPU64}
  {$ifdef MSWindows}{$define MSW}{$endif}
            {$ifdef Use_Sleep}
            // rsp == 0x0___8
            // [rsp]  ret
            //  $20 bytes for MS call shadow space on x64.

            push    r12
            push    r13
            mov     r12,{$ifdef MSW}rcx{$else}rdi{$endif}
            xor     r13,r13
            mov     r13b,4

            {$ifdef MSW}
            lea     rsp,[rsp-$28]
            {$else Unix}
            lea     rsp,[rsp-$8]
            {$endif}
            {$endif Use_Sleep}

            {$ifdef Gather_Spinlock_Stats}
            xor     rax,rax
            mov     [rip+LocalSpinlockCount],rax
            {$endif Gather_Spinlock_Stats}

@_repeat:   xor      rax,rax
            mov      dl,1
       lock cmpxchg  byte ptr [{$ifdef MSW}rcx{$else}rdi{$endif}],dl
            test     al,al
            je       @_exit

            {$ifdef Use_Sleep}
            {$ifdef MSW}
            mov    rcx,r13
            {$else Unix}
            mov    rdi,r13
            {$endif}

            {$ifdef MSW}
            call    Sleep
            {$else Unix}
            call    uSleep
            {$endif}

            shl     r13,1
            mov     rcx,r12
            {$endif Use_Sleep}

            {$ifdef Gather_Spinlock_Stats}
            inc     [rip+SpinlockCount]
            inc     [rip+LocalSpinlockCount]
            {$endif Gather_Spinlock_Stats}

            jmp     @_repeat
@_exit:
            {$ifdef Gather_Spinlock_Stats}
            mov     rax,[rip+LocalSpinlockCount]
            shl     rax,3
            xchg    rax,rcx
            lea     rax,[rip+MaxSpinlockCount]
            add     rax,rcx
            inc     [rax]
            {$endif Gather_Spinlock_Stats}

            {$ifdef Use_Sleep}
            {$ifdef MSW}
            lea     rsp,[rsp+$28]
            {$else Unix}
            lea     rsp,[rsp+$8]
            {$endif}
            pop     r13
            pop     r12
            {$endif Use_Sleep}
{$endif CPU64}
end;
{$else UseCriticalSection}
procedure ThreadLock(PLockValue: TPLockValue);
begin
  if CSCount=0 then
    exit;

  EnterCriticalSection(CS);
  Inc(CSCount);
  PLockValue^:=LockValue;
  LeaveCriticalSection(CS);
  Dec(CSCount);
end;
{$endif}

{$endif Use_Threads_Support}

function SimplyGetMem(Size: PtrUInt): Pointer; forward;
function SimplyFreeMem(MemPtr: Pointer): PtrUInt; forward;

procedure FreeReservedMemory;
begin
  {$ifdef Use_Threads_Support}
  ThreadLock(@CheckMemoryLock);
  {$endif Use_Threads_Support}

  if Assigned(PReservedMemory) then
  begin
    SimplyFreeMem(PReservedMemory);
    PReservedMemory:=nil;
  end;

  {$ifdef Use_Threads_Support}
  CheckMemoryLock:=UnlockValue;
  {$endif Use_Threads_Support}
end;

procedure AllocateReservedMemory;
begin
  {$ifdef Use_Threads_Support}
  ThreadLock(@CheckMemoryLock);
  {$endif Use_Threads_Support}

  if PReservedMemory<>nil then
  begin
    {$ifdef Use_Threads_Support}
    CheckMemoryLock:=UnlockValue;
    {$endif Use_Threads_Support}
    exit;
  end;

  if ReservedMemorySize<>0 then
    PReservedMemory:=SimplyGetMem(ReservedMemorySize);

  {$ifdef Use_Threads_Support}
  CheckMemoryLock:=UnlockValue;
  {$endif Use_Threads_Support}

  if (ReservedMemorySize<>0) and (PReservedMemory=nil) then
  begin
    _SMMLastError:=smmeCheckMemoryFailed;
    FatalErrorOutOfMemory;
  end;
end;

procedure SetReservedMemorySize(SizeInBytes: NInt);
begin
  if SizeInBytes<0 then
    exit;

  if ReservedMemorySize=SizeInBytes then
    exit;

  FreeReservedMemory;
  ReservedMemorySize:=SizeInBytes;
  AllocateReservedMemory
end;

function AddFSBContainer(AMain: TPCont): TPCont;
var
  {$ifdef Gather_Heap_Stats}
  LOverhead,
  {$endif Gather_Heap_Stats}
  LStdCount,LStdCountInc,LSize: NInt;
  LPCont: TPCont;
begin
  LSize:=AMain^.Size;
  {$ifdef Gather_Heap_Stats}
  LOverhead:=AMain^.Overhead;
  {$endif Gather_Heap_Stats}
  LStdCount:=AMain^.StdCount;

  if LStdCount>3 then
  begin
    LStdCountInc:=LStdCount div 2;

    if LStdCountInc>AMain^.SizeLimitCountInc then
    begin
      LStdCountInc:=AMain^.SizeLimitCountInc;
      LSize:=AMain^.SizeLimit;
    end
    else
      LSize:=LSize*LStdCountInc;
    {$ifdef Gather_Heap_Stats}
     LOverhead:=LOverhead*LStdCountInc;
    {$endif Gather_Heap_Stats}
  end
  else
   LStdCountInc:=1;

  {$ifdef MSWindows}
  LPCont:=VirtualAlloc(nil,LSize,MEM_COMMIT or MEM_RESERVE,PAGE_READWRITE);

  if LPCont=nil then
  {$endif MSWindows}
  {$ifdef Unix}
  LPCont:=fpmmap(nil,LSize,3,MAP_PRIVATE+MAP_ANONYMOUS,-1,0);

  if LPCont=MAP_FAILED then
  {$endif Unix}
  begin
    {$ifdef Use_Threads_Support}
    AMain^.Locked:=UnlockValue;
    {$endif Use_Threads_Support}
    _SMMLastError:=smmeGetMemoryFailed;
    exit(nil)
  end;

  {$ifdef Gather_Heap_Stats}
  {$ifdef Use_Threads_Support}
  ThreadLock(@SimplyHeapStatLock);
  {$endif Use_Threads_Support}

  with SimplyMMFPCHeapStatus do
  begin
    CurrHeapSize:=CurrHeapSize+LSize;

    if MaxHeapSize<CurrHeapSize then
      MaxHeapSize:=CurrHeapSize;

    CurrHeapUsed:=CurrHeapUsed+LOverhead;

    if MaxHeapUsed<CurrHeapUsed then
      MaxHeapUsed:=CurrHeapUsed;
  end;

  SimplyOverhead:=SimplyOverhead+LOverhead;

  {$ifdef Use_Threads_Support}
  SimplyHeapStatLock:=UnlockValue;
  {$endif Use_Threads_Support}
  {$endif Gather_Heap_Stats}

  LPCont^:=AMain^;

  inc(AMain^.StdCount,LStdCountInc);

  LPCont^.StdCount:=LStdCountInc;

  if LStdCountInc>1 then
  begin
    LPCont^.Size:=LSize;
    {$ifdef Gather_Heap_Stats}
     LPCont^.Overhead:=LOverhead;
    {$endif Gather_Heap_Stats}
    LPCont^.NumBlocks:=LPCont^.NumBlocks*LStdCountInc;
  end;

  LPCont^.FreeBlockCount:=LPCont^.NumBlocks;
  LPCont^.FreePFSB:=Pointer(NUInt(LPCont)+ContHeaderSize);

  LPCont^.Suc^.Pred:=LPCont;
  LPCont^.Pred:=AMain;
  AMain^.Suc:=LPCont;

  {$ifdef Gather_Usage_Stats}
  inc(AddFSBContainerCount);
  {$endif Gather_Usage_Stats}

  result:=LPCont;
end;

function AddVSB(Size: NInt): Pointer;
var
  LTotalSize,LBlockSize: NInt;
  LPVSB,LSuc: TPVSB;
begin
  // No Size check.
  LTotalSize:=VSBHeaderSize + Size;
  LBlockSize:=(LTotalSize div Granularity)*Granularity;

  if LTotalSize - LBlockSize>0 then
    inc(LBlockSize,Granularity);

  {$ifdef MSWindows}
  LPVSB:=VirtualAlloc(nil,LBlockSize,MEM_COMMIT or MEM_RESERVE,PAGE_READWRITE);
  if LPVSB=nil then
  {$endif MSWindows}
  {$ifdef Unix}
  LPVSB:=fpmmap(nil,LBlockSize,3,MAP_PRIVATE+MAP_ANONYMOUS,-1,0);

  if LPVSB=MAP_FAILED then
  {$endif Unix}
  begin
    _SMMLastError:=smmeGetMemoryFailed;
    exit(nil);
  end;

{$ifdef Gather_Heap_Stats}
  {$ifdef Use_Threads_Support}
  ThreadLock(@SimplyHeapStatLock);
  {$endif Use_Threads_Support}

  with SimplyMMFPCHeapStatus do
  begin
    CurrHeapSize:=CurrHeapSize + LTotalSize;

    if MaxHeapSize < CurrHeapSize then
      MaxHeapSize:=CurrHeapSize;

    CurrHeapUsed:=CurrHeapUsed + LTotalSize;

    if MaxHeapUsed < CurrHeapUsed then
      MaxHeapUsed:=CurrHeapUsed;
  end;

  SimplyOverhead:=SimplyOverhead + VSBHeaderSize;

  {$ifdef Use_Threads_Support}
  SimplyHeapStatLock:=UnlockValue;
  {$endif Use_Threads_Support}
{$endif Gather_Heap_Stats}

  with LPVSB^.Header do
  begin
    DataSize:=LBlockSize - VSBHeaderSize;
    BlockSize:=LBlockSize;
    BlockID:=VSB_ID;
  end;

  LSuc:=PVSBs;

  if LSuc<>nil then
  begin
    {$ifdef Use_Threads_Support}
    ThreadLock(@LSuc^.Header.Locked);
    LPVSB^.Header.Locked:=LockValue;
    {$endif Use_Threads_Support}

    LSuc^.Header.Pred:=LPVSB;
  end;

  LPVSB^.Header.Pred:=nil;
  LPVSB^.Header.Suc:=LSuc;
  PVSBs:=LPVSB;

  {$ifdef Use_Threads_Support}
  if LSuc<>nil then
    LSuc^.Header.Locked:=UnlockValue;

  LPVSB^.Header.Locked:=UnlockValue;
  {$endif Use_Threads_Support}

  result:=@LPVSB^.Data;
end;

function SimplyGetMemInternal(Size: NInt): Pointer;
var
  LMain,LPCont,LSuc: TPCont;
  LFreePFSB: TPFSB;
  {$ifdef CPU32}
  DeltaSize,
  {$endif CPU32}
  NumUnits: NInt;
begin
  if Size<1 then
    exit(nil);

  if Size>FSBMaxDataSize then
    exit(AddVSB(Size));

  {$ifdef CPU32}
  DeltaSize:=Size - FSBFirstUnitDataSize;
  NumUnits:=DeltaSize div UnitSize;

  if DeltaSize>NumUnits*UnitSize then
    inc(NumUnits);

  inc(NumUnits);
  {$endif CPU32}
  {$ifdef CPU64}
  NumUnits:=Size div UnitSize;

  if Size>NumUnits*UnitSize then
    inc(NumUnits);
  {$endif CPU64}

  LMain:=@FSBContainers[CorrespondenceTable[NumUnits]];

  {$ifdef Use_Threads_Support}
  ThreadLock(@LMain^.Locked);
  {$endif Use_Threads_Support}

  if LMain^.Suc^.FreeBlockCount=0 then
  begin
    LPCont:=AddFSBContainer(LMain);

    if LPCont=nil then
      exit(nil)
  end
  else
    LPCont:=LMain^.Suc;

  LFreePFSB:=LPCont^.FreePFSB;
  Dec(LPCont^.FreeBlockCount);

  if LPCont^.FreeBlockCount=0 then
  begin
    LSuc:=LPCont^.Suc;

    if LSuc<>LMain then
    begin
      LMain^.Suc:=LSuc;
      LSuc^.Pred:=LMain;
      LPCont^.Suc:=LMain;
      LPCont^.Pred:=LMain^.Pred;
      LMain^.Pred:=LPCont;
      LPCont^.Pred^.Suc:=LPCont;
    end;
  end
  else
    if LFreePFSB^.Header.BlockID=FREE_FSB then
      LPCont^.FreePFSB:=LFreePFSB^.PFreeFSB
    else
      LPCont^.FreePFSB:=Pointer(NUInt(LPCont^.FreePFSB)+LPCont^.BlockSize);

  LFreePFSB^.Header.PCont:=LPCont;
  LFreePFSB^.Header.BlockID:=FSB_ID;

  {$ifdef Use_Threads_Support}
  LMain^.Locked:=UnlockValue;
  {$endif Use_Threads_Support}

  {$ifdef Gather_Usage_Stats}
  inc(FSBStatsGetMem[CorrespondenceTable[NumUnits]]);
  {$endif Gather_Usage_Stats}

  {$ifdef Gather_Heap_Stats}
  {$ifdef Use_Threads_Support}
  ThreadLock(@SimplyHeapStatLock);
  {$endif Use_Threads_Support}

  with SimplyMMFPCHeapStatus do
  begin
    CurrHeapUsed:=CurrHeapUsed+LPCont^.DataSize;

    if MaxHeapUsed<CurrHeapUsed then
      MaxHeapUsed:=CurrHeapUsed;
  end;

  {$ifdef Use_Threads_Support}
  SimplyHeapStatLock:=UnlockValue;
  {$endif Use_Threads_Support}
  {$endif Gather_Heap_Stats}

  result:=@LFreePFSB^.Data;
end;

function SimplyFreeMem(MemPtr: Pointer): PtrUInt;
var
  LPCont,LMain: TPCont;
  LPFSB: TPFSB;
  LPVB,LVarSuc,LVarPred: TPVSB;
  {$ifdef Gather_Heap_Stats}
  LOverhead: NInt;
  {$endif Gather_Heap_Stats}
begin
  if MemPtr=nil then
    exit(0);

  case TPBlockID(NUInt(MemPtr)-BlockIDSize)^ of
    FSB_ID:
      begin
        LPFSB:=Pointer(NUInt(MemPtr)-FSBHeaderSize);

        if LPFSB=nil then
        begin
          _SMMLastError:=smmeInvalidHeader;
          exit(0);
        end;

        LPCont:=LPFSB^.Header.PCont;
        result:=LPCont^.DataSize;
        LMain:=LPCont^.Main;

        {$ifdef Gather_Usage_Stats}
        inc(FSBStatsFreeMem[LMain^.Index]);
        {$endif Gather_Usage_Stats}

        {$ifdef Gather_Heap_Stats}
        {$ifdef Use_Threads_Support}
        ThreadLock(@SimplyHeapStatLock);
        {$endif Use_Threads_Support}

        with SimplyMMFPCHeapStatus do
          CurrHeapUsed:=CurrHeapUsed-result;

        {$ifdef Use_Threads_Support}
        SimplyHeapStatLock:=UnlockValue;
        {$endif Use_Threads_Support}
        {$endif Gather_Heap_Stats}

        {$ifdef Use_Threads_Support}
        ThreadLock(@LMain^.Locked);
        {$endif Use_Threads_Support}

        LPFSB^.Header.BlockID:=FREE_FSB;
        LPFSB^.PFreeFSB:=LPCont^.FreePFSB;
        LPCont^.FreePFSB:=LPFSB;

        inc(LPCont^.FreeBlockCount);

        if LPCont^.FreeBlockCount=LPCont^.NumBlocks then
        begin
          {$ifdef Gather_Heap_Stats}
          {$ifdef Use_Threads_Support}
          ThreadLock(@SimplyHeapStatLock);
          {$endif Use_Threads_Support}

          with SimplyMMFPCHeapStatus do
          begin
            CurrHeapSize:=CurrHeapSize-LPCont^.Size;
            CurrHeapUsed:=CurrHeapUsed-LPCont^.Overhead;
          end;

          SimplyOverhead:=SimplyOverhead-LPCont^.Overhead;

          {$ifdef Use_Threads_Support}
          SimplyHeapStatLock:=UnlockValue;
          {$endif Use_Threads_Support}
          {$endif Gather_Heap_Stats}

          Dec(LMain^.StdCount,LPCont^.StdCount);

          LPCont^.Pred^.Suc:=LPCont^.Suc;
          LPCont^.Suc^.Pred:=LPCont^.Pred;

          {$ifdef Use_Threads_Support}
          LMain^.Locked:=UnlockValue;
          {$endif Use_Threads_Support}

          {$ifdef Gather_Usage_Stats}
          inc(FreeFSBContainerCount);
          {$endif Gather_Usage_Stats}

          {$ifdef MSWindows}
          if not VirtualFree(LPCont,0,MEM_RELEASE) then
          {$endif MSWindows}
          {$ifdef Unix}
          if fpmunmap(vPCont,vPCont^.Size)<>0 then
          {$endif Unix}
            _SMMLastError:=smmeFreeMemoryFailed;
        end
        else
        begin
          if (LPCont^.FreeBlockCount=1) and (LMain^.Suc<>LPCont) then
          begin
            LPCont^.Pred^.Suc:=LPCont^.Suc;
            LPCont^.Suc^.Pred:=LPCont^.Pred;
            LPCont^.Pred:=LMain;
            LPCont^.Suc:=LMain^.Suc;
            LMain^.Suc:=LPCont;
            LPCont^.Suc^.Pred:=LPCont;
          end;

          {$ifdef Use_Threads_Support}
          LMain^.Locked:=UnlockValue;
          {$endif Use_Threads_Support}
        end;
      end;
    VSB_ID:
      begin
        LPVB:=Pointer(NUInt(MemPtr)-VSBHeaderSize);
        result:=LPVB^.Header.DataSize;

        {$ifdef Gather_Heap_Stats}
        LOverhead:=VSBHeaderSize;
        {$endif Gather_Heap_Stats}

        {$ifdef Use_Threads_Support}
        ThreadLock(@LPVB^.Header.Locked);
        {$endif Use_Threads_Support}

        LVarSuc:=LPVB^.Header.Suc;

        {$ifdef Use_Threads_Support}
        if LVarSuc<>nil then
          ThreadLock(@LVarSuc^.Header.Locked);
        {$endif Use_Threads_Support}

        LVarPred:=LPVB^.Header.Pred;

        {$ifdef Use_Threads_Support}
        if LVarPred<>nil then
          ThreadLock(@LVarPred^.Header.Locked);
        {$endif Use_Threads_Support}

        if LVarPred<>nil then
          LVarPred^.Header.Suc:=LVarSuc
        else
          PVSBs:=LVarSuc;

        if LVarSuc<>nil then
        begin
          LVarSuc^.Header.Pred:=LVarPred;
          {$ifdef Use_Threads_Support}
          LVarSuc^.Header.Locked:=UnlockValue;
          {$endif Use_Threads_Support}
        end;

        {$ifdef Use_Threads_Support}
        if LVarPred<>nil then
          LVarPred^.Header.Locked:=UnlockValue;
        {$endif Use_Threads_Support}

        {$ifdef MSWindows}
        if not VirtualFree(LPVB,0,MEM_RELEASE) then
        {$endif MSWindows}
        {$ifdef Unix}
        if fpmunmap(vPVB,vPVB^.Header.BlockSize)<>0 then
        {$endif Unix}
         begin
          _SMMLastError:=smmeFreeMemoryFailed;
          exit(0);
        end;

        {$ifdef Gather_Heap_Stats}
        {$ifdef Use_Threads_Support}
        ThreadLock(@SimplyHeapStatLock);
        {$endif Use_Threads_Support}

        with SimplyMMFPCHeapStatus do
        begin
          CurrHeapSize:=CurrHeapSize-result;
          CurrHeapUsed:=CurrHeapUsed-result;
        end;
        SimplyOverhead:=SimplyOverhead-LOverhead;

        {$ifdef Use_Threads_Support}
        SimplyHeapStatLock:=UnlockValue;
        {$endif Use_Threads_Support}
        {$endif Gather_Heap_Stats}
      end;
    FREE_FSB:
      begin
        _SMMLastError:=smmeUnexpectedFreeBlock;
        result:=0
      end
    else
      result:=SavedMemoryManager.FreeMem(MemPtr)
  end;
end;

function SimplyMemSize(MemPtr: Pointer): NUInt;
var
  LBlockID: TBlockID;
begin
  if MemPtr=nil then
    exit(0);

  LBlockID:=TPBlockID(NUInt(MemPtr)-BlockIDSize)^;

  if LBlockID=FSB_ID then
    result:=TPFSB(NUInt(MemPtr)-FSBHeaderSize)^.Header.PCont^.DataSize
  else
    if LBlockID=VSB_ID then
      result:=TPVSB(NUInt(MemPtr)-VSBHeaderSize)^.Header.DataSize
    else
      if LBlockID=FREE_FSB then
      begin
        _SMMLastError:=smmeUnexpectedFreeBlock;
        result:=0
      end
      else
        result:=SavedMemoryManager.MemSize(MemPtr);
end;

function SimplyFreeMemSize(MemPtr: Pointer; Size: PtrUInt): NUInt;
begin
  if Size>0 then
    result:=SimplyFreeMem(MemPtr)
  else
    result:=0
end;

// No check for MemPtr=nil and Size<0
function SimplyReAllocMemInternal(var MemPtr: Pointer; Size: NInt): Pointer;
var
  OldSize: NInt;
begin
  case TPBlockID(NUInt(MemPtr)-BlockIDSize)^ of
    FSB_ID:
      OldSize:=TPFSB(NUInt(MemPtr)-FSBHeaderSize)^.Header.PCont^.DataSize;
    VSB_ID:
      OldSize:=TPVSB(NUInt(MemPtr)-VSBHeaderSize)^.Header.DataSize;
    FREE_FSB:
      begin
        _SMMLastError:=smmeUnexpectedFreeBlock;
        exit(nil);
      end
    else
      begin                                   // FPC block
        result:=SimplyGetMemInternal(Size);

        if result=nil then
          exit;

        Move(MemPtr^,result^,Size);
        SavedMemoryManager.FreeMem(MemPtr);
        MemPtr:=result;
        exit;
      end;
    end;

  // The freeing analyzer (if any) should be placed at this point.

  if not ((Size + Size shr 2 > OldSize) or (OldSize > Size + Size shr 2)) then
    exit(MemPtr);

  result:=SimplyGetMemInternal(Size);

  if result=nil then
    exit;
                                          // copying existing data
  if OldSize < Size then
    Move(MemPtr^,result^,OldSize)
  else	
    Move(MemPtr^,result^,Size);     
	
  SimplyFreeMem(MemPtr);
  MemPtr:=result;
end;

function SimplyGetMem(Size: PtrUInt): Pointer;
begin
  result:=SimplyGetMemInternal(Size);

  if (result=nil) and (Size>0) then
  begin
    if not ReturnNilIfGrowHeapfails then
       RunError(203);

    if IsOutOfMemoryIgnored then
      exit;

    FreeReservedMemory;

    if Assigned(CustomNotifyOutOfMemory) then
      CustomNotifyOutOfMemory;

    result:=SimplyGetMemInternal(Size);

    if result=nil then
      FatalErrorOutOfMemory;
  end;
end;

function SimplyAllocMem(Size: PtrUInt): Pointer;
begin
  result:=SimplyGetMem(Size);

  if result=nil then
    exit;

  FillChar(result^,Size,#0);
end;

function SimplyReAllocMem(var MemPtr: Pointer; Size: PtrUInt): Pointer;
begin
  if Size=0 then
  begin
    if MemPtr=nil then
      exit(nil);

    SimplyFreeMem(MemPtr);
    MemPtr:=nil;
    exit(nil);
  end;

  if MemPtr=nil then
  begin
    result:=SimplyGetMemInternal(Size);
    MemPtr:=result;
  end
  else
    result:=SimplyReAllocMemInternal(MemPtr,Size);

  if result=nil then
  begin
    if not ReturnNilIfGrowHeapfails then
      RunError(203);

    if IsOutOfMemoryIgnored then
      exit;

    FreeReservedMemory;

    if Assigned(CustomNotifyOutOfMemory) then
      CustomNotifyOutOfMemory;

    if MemPtr=nil then
    begin
      result:=SimplyGetMemInternal(Size);
      MemPtr:=result;
    end
    else
      result:=SimplyReAllocMemInternal(MemPtr,Size);

    if result=nil then
      FatalErrorOutOfMemory;
  end;
end;

function SimplyGetFPCHeapStatus: TFPCHeapStatus;
{$ifNdef Gather_Heap_Stats}
var
  PVarBlocks: TPVSB;
  i,Overhead: NInt;
  SucCont,MainCont: TPCont;
{$endif}
begin
{$ifdef Gather_Heap_Stats}
  {$ifdef Use_Threads_Support}
  ThreadLock(@SimplyHeapStatLock);
  {$endif Use_Threads_Support}

  result:=SimplyMMFPCHeapStatus;

  {$ifdef Use_Threads_Support}
  SimplyHeapStatLock:=UnlockValue;
  {$endif Use_Threads_Support}

  with result do
    CurrHeapFree:=CurrHeapSize-CurrHeapUsed;
{$else}
  Overhead:=0;

  with result do
  begin
    CurrHeapSize:=0;
    CurrHeapUsed:=0;
    MaxHeapSize:=0;
    MaxHeapUsed:=0;
  end;

  for i:=0 to FSBContMaxIndex do
  begin
    MainCont:=FSBContainers[i].Main;
    SucCont:=FSBContainers[i].Suc;

    if SucCont<>MainCont then
    repeat
      result.CurrHeapSize:=result.CurrHeapSize+SucCont^.Size;
      result.CurrHeapUsed:=result.CurrHeapUsed+
        SucCont^.DataSize*(SucCont^.NumBlocks-SucCont^.FreeBlockCount)+
          {$ifdef Gather_Heap_Stats}
          SucCont^.Overhead;
          {$else}
          SucCont^.Size-SucCont^.NumBlocks*SucCont^.DataSize;
      {$endif}

      {$ifdef Gather_Heap_Stats}
      Overhead:=Overhead+SucCont^.Overhead;
      {$else}
      Overhead:=SucCont^.Size-SucCont^.NumBlocks*SucCont^.DataSize;
      {$endif}
      SucCont:=SucCont^.Suc;
    until SucCont=MainCont;
  end;

  PVarBlocks:=PVSBs;

  while PVarBlocks<>nil do
  begin
    result.CurrHeapSize:=result.CurrHeapSize+PVarBlocks^.Header.BlockSize;
    result.CurrHeapUsed:=result.CurrHeapUsed+PVarBlocks^.Header.DataSize;
    Overhead:=Overhead+VSBHeaderSize;
    PVarBlocks:=PVarBlocks^.Header.Suc;
  end;

  SimplyOverhead:=Overhead;

  with result do
    CurrHeapFree:=CurrHeapSize-CurrHeapUsed;
{$endif}
end;

function SimplyGetHeapStatus: THeapStatus;
var
  FPCHeapStatus: TFPCHeapStatus;
begin
  FPCHeapStatus:=SimplyGetFPCHeapStatus;

  with FPCHeapStatus do
  begin
    result.TotalAllocated:=CurrHeapUsed;
    result.TotalFree:=CurrHeapFree;
    result.TotalAddrSpace:=CurrHeapSize;
    result.Overhead:=SimplyOverhead;
  end;

  result.TotalUncommitted:=0;
  result.TotalCommitted:=0;
  result.FreeSmall:=0;
  result.FreeBig:=0;
  result.Unused:=0;
  result.HeapErrorCode:=0;
end;

const
                                                                               {
  There are below the predefined sets of container types for 32-bit and
  64-bit platforms. The number of container types are limited only by
  the "CustomMaxFSBCType" constant. If necessary, change this value at the
  top of this source to expand or shrink the range.

  The changes of the container type data (Units,Blocks) are allowed
  to be made not only on unit initialization, but even on runtime.
                                                                               }

  {$ifdef CPU32}
  StdContInitData: array [0..CustomMaxFSBCTypeIndex] of TContInitData = (

  (UnitsPerBlock:    1; NumBlocks:4092;),(UnitsPerBlock:    2; NumBlocks:2046;),
  (UnitsPerBlock:    3; NumBlocks:1364;),(UnitsPerBlock:    4; NumBlocks:1023;),
  (UnitsPerBlock:    5; NumBlocks: 818;),(UnitsPerBlock:    6; NumBlocks: 682;),
  (UnitsPerBlock:    7; NumBlocks: 584;),(UnitsPerBlock:    8; NumBlocks: 511;),
  (UnitsPerBlock:    9; NumBlocks: 454;),(UnitsPerBlock:   10; NumBlocks: 409;),
  (UnitsPerBlock:   11; NumBlocks: 372;),(UnitsPerBlock:   12; NumBlocks: 341;),
  (UnitsPerBlock:   13; NumBlocks: 314;),(UnitsPerBlock:   14; NumBlocks: 292;),
  (UnitsPerBlock:   15; NumBlocks: 272;),(UnitsPerBlock:   16; NumBlocks: 255;),
  (UnitsPerBlock:   17; NumBlocks: 240;),(UnitsPerBlock:   18; NumBlocks: 227;),
  (UnitsPerBlock:   19; NumBlocks: 215;),(UnitsPerBlock:   20; NumBlocks: 204;),
  (UnitsPerBlock:   21; NumBlocks: 194;),(UnitsPerBlock:   22; NumBlocks: 186;),
  (UnitsPerBlock:   23; NumBlocks: 177;),(UnitsPerBlock:   24; NumBlocks: 170;),
  (UnitsPerBlock:   25; NumBlocks: 163;),(UnitsPerBlock:   26; NumBlocks: 157;),
  (UnitsPerBlock:   27; NumBlocks: 151;),(UnitsPerBlock:   28; NumBlocks: 146;),
  (UnitsPerBlock:   29; NumBlocks: 141;),(UnitsPerBlock:   30; NumBlocks: 136;),
  (UnitsPerBlock:   31; NumBlocks: 132;),(UnitsPerBlock:   32; NumBlocks: 127;),
  (UnitsPerBlock:   34; NumBlocks: 240;),(UnitsPerBlock:   36; NumBlocks: 227;),
  (UnitsPerBlock:   38; NumBlocks: 215;),(UnitsPerBlock:   40; NumBlocks: 204;),
  (UnitsPerBlock:   42; NumBlocks: 194;),(UnitsPerBlock:   44; NumBlocks: 186;),
  (UnitsPerBlock:   46; NumBlocks: 178;),(UnitsPerBlock:   48; NumBlocks: 170;),
  (UnitsPerBlock:   50; NumBlocks: 163;),(UnitsPerBlock:   52; NumBlocks: 157;),
  (UnitsPerBlock:   54; NumBlocks: 151;),(UnitsPerBlock:   56; NumBlocks: 146;),
  (UnitsPerBlock:   58; NumBlocks: 141;),(UnitsPerBlock:   60; NumBlocks: 136;),
  (UnitsPerBlock:   62; NumBlocks: 132;),(UnitsPerBlock:   64; NumBlocks: 127;),
  (UnitsPerBlock:   66; NumBlocks: 124;),(UnitsPerBlock:   68; NumBlocks: 120;),
  (UnitsPerBlock:   70; NumBlocks: 116;),(UnitsPerBlock:   72; NumBlocks: 113;),
  (UnitsPerBlock:   74; NumBlocks: 110;),(UnitsPerBlock:   76; NumBlocks: 107;),
  (UnitsPerBlock:   78; NumBlocks: 104;),(UnitsPerBlock:   80; NumBlocks: 102;),
  (UnitsPerBlock:   82; NumBlocks:  99;),(UnitsPerBlock:   84; NumBlocks:  97;),
  (UnitsPerBlock:   86; NumBlocks:  95;),(UnitsPerBlock:   88; NumBlocks:  93;),
  (UnitsPerBlock:   89; NumBlocks:  92;),(UnitsPerBlock:   92; NumBlocks:  89;),
  (UnitsPerBlock:   94; NumBlocks:  87;),(UnitsPerBlock:   96; NumBlocks:  85;),
  (UnitsPerBlock:  100; NumBlocks: 122;),(UnitsPerBlock:  104; NumBlocks: 118;),
  (UnitsPerBlock:  108; NumBlocks: 113;),(UnitsPerBlock:  112; NumBlocks: 109;),
  (UnitsPerBlock:  116; NumBlocks: 105;),(UnitsPerBlock:  120; NumBlocks: 102;),
  (UnitsPerBlock:  124; NumBlocks:  99;),(UnitsPerBlock:  129; NumBlocks:  95;),
  (UnitsPerBlock:  133; NumBlocks:  92;),(UnitsPerBlock:  137; NumBlocks:  89;),
  (UnitsPerBlock:  141; NumBlocks:  87;),(UnitsPerBlock:  145; NumBlocks:  84;),
  (UnitsPerBlock:  149; NumBlocks:  82;),(UnitsPerBlock:  153; NumBlocks:  80;),
  (UnitsPerBlock:  157; NumBlocks:  78;),(UnitsPerBlock:  161; NumBlocks:  76;),
  (UnitsPerBlock:  165; NumBlocks:  74;),(UnitsPerBlock:  169; NumBlocks:  72;),
  (UnitsPerBlock:  173; NumBlocks:  71;),(UnitsPerBlock:  177; NumBlocks:  69;),
  (UnitsPerBlock:  180; NumBlocks:  68;),(UnitsPerBlock:  183; NumBlocks:  67;),
  (UnitsPerBlock:  186; NumBlocks:  66;),(UnitsPerBlock:  191; NumBlocks:  64;),
  (UnitsPerBlock:  194; NumBlocks:  63;),(UnitsPerBlock:  198; NumBlocks:  62;),
  (UnitsPerBlock:  201; NumBlocks:  61;),(UnitsPerBlock:  204; NumBlocks:  60;),
  (UnitsPerBlock:  208; NumBlocks:  59;),(UnitsPerBlock:  211; NumBlocks:  58;),
  (UnitsPerBlock:  215; NumBlocks:  57;),(UnitsPerBlock:  219; NumBlocks:  56;),
  (UnitsPerBlock:  227; NumBlocks:  72;),(UnitsPerBlock:  234; NumBlocks:  70;),
  (UnitsPerBlock:  240; NumBlocks:  68;),(UnitsPerBlock:  248; NumBlocks:  66;),
  (UnitsPerBlock:  255; NumBlocks:  64;),(UnitsPerBlock:  263; NumBlocks:  62;),
  (UnitsPerBlock:  271; NumBlocks:  60;),(UnitsPerBlock:  277; NumBlocks:  59;),
  (UnitsPerBlock:  285; NumBlocks:  57;),(UnitsPerBlock:  292; NumBlocks:  56;),
  (UnitsPerBlock:  297; NumBlocks:  55;),(UnitsPerBlock:  303; NumBlocks:  54;),
  (UnitsPerBlock:  309; NumBlocks:  53;),(UnitsPerBlock:  315; NumBlocks:  52;),
  (UnitsPerBlock:  321; NumBlocks:  51;),(UnitsPerBlock:  327; NumBlocks:  50;),
  (UnitsPerBlock:  334; NumBlocks:  49;),(UnitsPerBlock:  341; NumBlocks:  48;),
  (UnitsPerBlock:  348; NumBlocks:  47;),(UnitsPerBlock:  356; NumBlocks:  46;),
  (UnitsPerBlock:  364; NumBlocks:  45;),(UnitsPerBlock:  372; NumBlocks:  44;),
  (UnitsPerBlock:  380; NumBlocks:  43;),(UnitsPerBlock:  388; NumBlocks:  42;),
  (UnitsPerBlock:  396; NumBlocks:  41;),(UnitsPerBlock:  399; NumBlocks:  41;),
  (UnitsPerBlock:  407; NumBlocks:  40;),(UnitsPerBlock:  420; NumBlocks:  39;),
  (UnitsPerBlock:  428; NumBlocks:  38;),(UnitsPerBlock:  431; NumBlocks:  38;),
  (UnitsPerBlock:  439; NumBlocks:  37;),(UnitsPerBlock:  442; NumBlocks:  37;),
  (UnitsPerBlock:  455; NumBlocks:  45;),(UnitsPerBlock:  465; NumBlocks:  44;),
  (UnitsPerBlock:  476; NumBlocks:  43;),(UnitsPerBlock:  487; NumBlocks:  42;),
  (UnitsPerBlock:  499; NumBlocks:  41;),(UnitsPerBlock:  511; NumBlocks:  40;),
  (UnitsPerBlock:  525; NumBlocks:  39;),(UnitsPerBlock:  538; NumBlocks:  38;),
  (UnitsPerBlock:  553; NumBlocks:  37;),(UnitsPerBlock:  568; NumBlocks:  36;),
  (UnitsPerBlock:  584; NumBlocks:  35;),(UnitsPerBlock:  600; NumBlocks:  34;),
  (UnitsPerBlock:  616; NumBlocks:  33;),(UnitsPerBlock:  639; NumBlocks:  32;),
  (UnitsPerBlock:  655; NumBlocks:  31;),(UnitsPerBlock:  682; NumBlocks:  30;),
  (UnitsPerBlock:  700; NumBlocks:  29;),(UnitsPerBlock:  731; NumBlocks:  28;),
  (UnitsPerBlock:  751; NumBlocks:  27;),(UnitsPerBlock:  783; NumBlocks:  26;),
  (UnitsPerBlock:  815; NumBlocks:  25;),(UnitsPerBlock:  847; NumBlocks:  24;),
  (UnitsPerBlock:  882; NumBlocks:  23;),(UnitsPerBlock:  922; NumBlocks:  22;),
  (UnitsPerBlock:  966; NumBlocks:  21;),(UnitsPerBlock: 1014; NumBlocks:  20;),
  (UnitsPerBlock: 1068; NumBlocks:  19;),(UnitsPerBlock: 1127; NumBlocks:  18;),
  (UnitsPerBlock: 1193; NumBlocks:  17;),(UnitsPerBlock: 1268; NumBlocks:  16;),
  (UnitsPerBlock: 1352; NumBlocks:  15;),(UnitsPerBlock: 1449; NumBlocks:  14;),
  (UnitsPerBlock: 1521; NumBlocks:  16;),(UnitsPerBlock: 1622; NumBlocks:  15;),
  (UnitsPerBlock: 1738; NumBlocks:  14;),(UnitsPerBlock: 1872; NumBlocks:  13;),
  (UnitsPerBlock: 2028; NumBlocks:  12;),(UnitsPerBlock: 2212; NumBlocks:  11;),
  (UnitsPerBlock: 2433; NumBlocks:  10;),(UnitsPerBlock: 2704; NumBlocks:   9;),
  (UnitsPerBlock: 3042; NumBlocks:   8;),(UnitsPerBlock: 3476; NumBlocks:   7;),
  (UnitsPerBlock: 4055; NumBlocks:   6;),(UnitsPerBlock: 4866; NumBlocks:   5;),
  (UnitsPerBlock: 5677; NumBlocks:   5;),(UnitsPerBlock: 6488; NumBlocks:   5;),
  (UnitsPerBlock: 7300; NumBlocks:   5;),(UnitsPerBlock: 8111; NumBlocks:   5;),
  (UnitsPerBlock: 8922; NumBlocks:   5;),(UnitsPerBlock: 9733; NumBlocks:   5;),
  (UnitsPerBlock:10544; NumBlocks:   5;),(UnitsPerBlock:11355; NumBlocks:   5;),
  (UnitsPerBlock:FSBMaxUnits; NumBlocks:   5;));
  {$endif CPU32}

  {$ifdef CPU64}
  StdContInitData: array [0..CustomMaxFSBCTypeIndex] of TContInitData = (

  (UnitsPerBlock:    2; NumBlocks:2044;),
  (UnitsPerBlock:    3; NumBlocks:1362;),(UnitsPerBlock:    4; NumBlocks:1022;),
  (UnitsPerBlock:    5; NumBlocks: 817;),(UnitsPerBlock:    6; NumBlocks: 681;),
  (UnitsPerBlock:    7; NumBlocks: 584;),(UnitsPerBlock:    8; NumBlocks: 511;),
  (UnitsPerBlock:    9; NumBlocks: 454;),(UnitsPerBlock:   10; NumBlocks: 408;),
  (UnitsPerBlock:   11; NumBlocks: 371;),(UnitsPerBlock:   12; NumBlocks: 340;),
  (UnitsPerBlock:   13; NumBlocks: 314;),(UnitsPerBlock:   14; NumBlocks: 292;),
  (UnitsPerBlock:   15; NumBlocks: 272;),(UnitsPerBlock:   16; NumBlocks: 255;),
  (UnitsPerBlock:   17; NumBlocks: 240;),(UnitsPerBlock:   18; NumBlocks: 227;),
  (UnitsPerBlock:   19; NumBlocks: 215;),(UnitsPerBlock:   20; NumBlocks: 204;),
  (UnitsPerBlock:   21; NumBlocks: 194;),(UnitsPerBlock:   22; NumBlocks: 185;),
  (UnitsPerBlock:   23; NumBlocks: 177;),(UnitsPerBlock:   24; NumBlocks: 170;),
  (UnitsPerBlock:   25; NumBlocks: 163;),(UnitsPerBlock:   26; NumBlocks: 157;),
  (UnitsPerBlock:   27; NumBlocks: 151;),(UnitsPerBlock:   28; NumBlocks: 146;),
  (UnitsPerBlock:   29; NumBlocks: 140;),(UnitsPerBlock:   30; NumBlocks: 136;),
  (UnitsPerBlock:   31; NumBlocks: 131;),(UnitsPerBlock:   32; NumBlocks: 127;),
  (UnitsPerBlock:   34; NumBlocks: 240;),(UnitsPerBlock:   36; NumBlocks: 227;),
  (UnitsPerBlock:   38; NumBlocks: 215;),(UnitsPerBlock:   40; NumBlocks: 204;),
  (UnitsPerBlock:   42; NumBlocks: 194;),(UnitsPerBlock:   44; NumBlocks: 186;),
  (UnitsPerBlock:   46; NumBlocks: 177;),(UnitsPerBlock:   48; NumBlocks: 170;),
  (UnitsPerBlock:   50; NumBlocks: 163;),(UnitsPerBlock:   52; NumBlocks: 157;),
  (UnitsPerBlock:   54; NumBlocks: 151;),(UnitsPerBlock:   56; NumBlocks: 146;),
  (UnitsPerBlock:   58; NumBlocks: 141;),(UnitsPerBlock:   60; NumBlocks: 136;),
  (UnitsPerBlock:   62; NumBlocks: 132;),(UnitsPerBlock:   64; NumBlocks: 127;),
  (UnitsPerBlock:   66; NumBlocks: 124;),(UnitsPerBlock:   68; NumBlocks: 120;),
  (UnitsPerBlock:   70; NumBlocks: 116;),(UnitsPerBlock:   72; NumBlocks: 113;),
  (UnitsPerBlock:   74; NumBlocks: 110;),(UnitsPerBlock:   76; NumBlocks: 107;),
  (UnitsPerBlock:   78; NumBlocks: 104;),(UnitsPerBlock:   80; NumBlocks: 102;),
  (UnitsPerBlock:   82; NumBlocks:  99;),(UnitsPerBlock:   84; NumBlocks:  97;),
  (UnitsPerBlock:   86; NumBlocks:  95;),(UnitsPerBlock:   88; NumBlocks:  93;),
  (UnitsPerBlock:   93; NumBlocks:  88;),(UnitsPerBlock:   95; NumBlocks:  86;),
  (UnitsPerBlock:   97; NumBlocks:  84;),(UnitsPerBlock:   99; NumBlocks:  82;),
  (UnitsPerBlock:  103; NumBlocks: 119;),(UnitsPerBlock:  107; NumBlocks: 114;),
  (UnitsPerBlock:  111; NumBlocks: 110;),(UnitsPerBlock:  115; NumBlocks: 106;),
  (UnitsPerBlock:  119; NumBlocks: 103;),(UnitsPerBlock:  123; NumBlocks:  99;),
  (UnitsPerBlock:  127; NumBlocks:  96;),(UnitsPerBlock:  131; NumBlocks:  93;),
  (UnitsPerBlock:  136; NumBlocks:  90;),(UnitsPerBlock:  140; NumBlocks:  87;),
  (UnitsPerBlock:  144; NumBlocks:  85;),(UnitsPerBlock:  149; NumBlocks:  82;),
  (UnitsPerBlock:  153; NumBlocks:  80;),(UnitsPerBlock:  157; NumBlocks:  78;),
  (UnitsPerBlock:  161; NumBlocks:  76;),(UnitsPerBlock:  165; NumBlocks:  74;),
  (UnitsPerBlock:  169; NumBlocks:  72;),(UnitsPerBlock:  172; NumBlocks:  71;),
  (UnitsPerBlock:  175; NumBlocks:  70;),(UnitsPerBlock:  179; NumBlocks:  68;),
  (UnitsPerBlock:  183; NumBlocks:  67;),(UnitsPerBlock:  186; NumBlocks:  66;),
  (UnitsPerBlock:  190; NumBlocks:  64;),(UnitsPerBlock:  194; NumBlocks:  63;),
  (UnitsPerBlock:  198; NumBlocks:  62;),(UnitsPerBlock:  201; NumBlocks:  61;),
  (UnitsPerBlock:  204; NumBlocks:  60;),(UnitsPerBlock:  208; NumBlocks:  59;),
  (UnitsPerBlock:  211; NumBlocks:  58;),(UnitsPerBlock:  215; NumBlocks:  57;),
  (UnitsPerBlock:  219; NumBlocks:  56;),(UnitsPerBlock:  223; NumBlocks:  55;),
  (UnitsPerBlock:  230; NumBlocks:  71;),(UnitsPerBlock:  237; NumBlocks:  69;),
  (UnitsPerBlock:  244; NumBlocks:  67;),(UnitsPerBlock:  251; NumBlocks:  65;),
  (UnitsPerBlock:  259; NumBlocks:  63;),(UnitsPerBlock:  267; NumBlocks:  61;),
  (UnitsPerBlock:  275; NumBlocks:  59;),(UnitsPerBlock:  282; NumBlocks:  58;),
  (UnitsPerBlock:  290; NumBlocks:  56;),(UnitsPerBlock:  297; NumBlocks:  55;),
  (UnitsPerBlock:  303; NumBlocks:  54;),(UnitsPerBlock:  308; NumBlocks:  53;),
  (UnitsPerBlock:  314; NumBlocks:  52;),(UnitsPerBlock:  321; NumBlocks:  51;),
  (UnitsPerBlock:  327; NumBlocks:  50;),(UnitsPerBlock:  334; NumBlocks:  49;),
  (UnitsPerBlock:  341; NumBlocks:  48;),(UnitsPerBlock:  348; NumBlocks:  47;),
  (UnitsPerBlock:  356; NumBlocks:  46;),(UnitsPerBlock:  363; NumBlocks:  45;),
  (UnitsPerBlock:  371; NumBlocks:  44;),(UnitsPerBlock:  379; NumBlocks:  43;),
  (UnitsPerBlock:  387; NumBlocks:  42;),(UnitsPerBlock:  389; NumBlocks:  42;),
  (UnitsPerBlock:  397; NumBlocks:  41;),(UnitsPerBlock:  399; NumBlocks:  41;),
  (UnitsPerBlock:  407; NumBlocks:  40;),(UnitsPerBlock:  419; NumBlocks:  39;),
  (UnitsPerBlock:  427; NumBlocks:  38;),(UnitsPerBlock:  430; NumBlocks:  38;),
  (UnitsPerBlock:  439; NumBlocks:  37;),(UnitsPerBlock:  442; NumBlocks:  37;),
  (UnitsPerBlock:  454; NumBlocks:  45;),(UnitsPerBlock:  465; NumBlocks:  44;),
  (UnitsPerBlock:  476; NumBlocks:  43;),(UnitsPerBlock:  487; NumBlocks:  42;),
  (UnitsPerBlock:  499; NumBlocks:  41;),(UnitsPerBlock:  511; NumBlocks:  40;),
  (UnitsPerBlock:  524; NumBlocks:  39;),(UnitsPerBlock:  538; NumBlocks:  38;),
  (UnitsPerBlock:  553; NumBlocks:  37;),(UnitsPerBlock:  568; NumBlocks:  36;),
  (UnitsPerBlock:  584; NumBlocks:  35;),(UnitsPerBlock:  600; NumBlocks:  34;),
  (UnitsPerBlock:  616; NumBlocks:  33;),(UnitsPerBlock:  639; NumBlocks:  32;),
  (UnitsPerBlock:  655; NumBlocks:  31;),(UnitsPerBlock:  682; NumBlocks:  30;),
  (UnitsPerBlock:  699; NumBlocks:  29;),(UnitsPerBlock:  731; NumBlocks:  28;),
  (UnitsPerBlock:  751; NumBlocks:  27;),(UnitsPerBlock:  783; NumBlocks:  26;),
  (UnitsPerBlock:  815; NumBlocks:  25;),(UnitsPerBlock:  847; NumBlocks:  24;),
  (UnitsPerBlock:  882; NumBlocks:  23;),(UnitsPerBlock:  922; NumBlocks:  22;),
  (UnitsPerBlock:  966; NumBlocks:  21;),(UnitsPerBlock: 1014; NumBlocks:  20;),
  (UnitsPerBlock: 1067; NumBlocks:  19;),(UnitsPerBlock: 1127; NumBlocks:  18;),
  (UnitsPerBlock: 1193; NumBlocks:  17;),(UnitsPerBlock: 1267; NumBlocks:  16;),
  (UnitsPerBlock: 1352; NumBlocks:  15;),(UnitsPerBlock: 1448; NumBlocks:  14;),
  (UnitsPerBlock: 1521; NumBlocks:  16;),(UnitsPerBlock: 1622; NumBlocks:  15;),
  (UnitsPerBlock: 1738; NumBlocks:  14;),(UnitsPerBlock: 1872; NumBlocks:  13;),
  (UnitsPerBlock: 2028; NumBlocks:  12;),(UnitsPerBlock: 2212; NumBlocks:  11;),
  (UnitsPerBlock: 2433; NumBlocks:  10;),(UnitsPerBlock: 2703; NumBlocks:   9;),
  (UnitsPerBlock: 3041; NumBlocks:   8;),(UnitsPerBlock: 3475; NumBlocks:   7;),
  (UnitsPerBlock: 4055; NumBlocks:   6;),(UnitsPerBlock: 4865; NumBlocks:   5;),
  (UnitsPerBlock: 5677; NumBlocks:   5;),(UnitsPerBlock: 6488; NumBlocks:   5;),
  (UnitsPerBlock: 7299; NumBlocks:   5;),(UnitsPerBlock: 8110; NumBlocks:   5;),
  (UnitsPerBlock: 8921; NumBlocks:   5;),(UnitsPerBlock: 9732; NumBlocks:   5;),
  (UnitsPerBlock:10543; NumBlocks:   5;),(UnitsPerBlock:11354; NumBlocks:   5;),
  (UnitsPerBlock:FSBMaxUnits; NumBlocks:   5;));
  {$endif CPU64}

procedure RaiseSetFSBContainerError(Msg1,Msg2,Ssg3: TSMMString);
const
  SetFSBContainerTxt = 'SetFSBContainer function error' + DEOL;
begin
  ShowError(SetFSBContainerTxt + Msg1 + Msg2 + Ssg3,1);
end;
procedure SetFSBContainerError(ParName: TSMMString; Par,Value: NInt; IsMax: boolean);
var
  S: TSMMString;
begin
  if IsMax then
    S:='maximum'
  else
    S:='minimum';

  RaiseSetFSBContainerError(ParName + ' parameter value "' + IntToStr(Par),
    '" exceeds the ' + S, ' ( ' + IntToStr(Value) + ' )');
end;

function SetFSBContainer(AIndex,AUnitsPerBlock,ANumBlocks: NInt): boolean;
const
  AContNumTxt = 'Containter #';
  AIndexTxt = 'AIndex';
  AUnitsPerBlockTxt = 'AUnitsPerBlock';
  ANumBlocksTxt = 'ANumBlocks';
var
  LDataUnitsPerBlock,
  CorTableIndex,
  UnitsLowBound,
  SizeGran,TmpSize: NInt;
  MainCont: TPCont;
begin
  result:=false;

  if AIndex > FSBContMaxIndex+1 then
    SetFSBContainerError(AIndexTxt,AIndex,FSBContMaxIndex+1,true);

  if AIndex > FSBContSysMaxIndex then
    SetFSBContainerError(AIndexTxt,AIndex,FSBContSysMaxIndex,true);

  if AIndex < 0 then
    SetFSBContainerError(AIndexTxt,AIndex,0,false);

  if AUnitsPerBlock > FSBMaxUnits then
    SetFSBContainerError(AUnitsPerBlockTxt,AUnitsPerBlock,FSBMaxUnits,true);

  if AUnitsPerBlock < MinUnitsPerBlock then
    SetFSBContainerError(AUnitsPerBlockTxt,AUnitsPerBlock,MinUnitsPerBlock,false);

  if ANumBlocks > MaxBlocks then
    SetFSBContainerError(ANumBlocksTxt,ANumBlocks,MaxBlocks,true);

  if ANumBlocks < 1 then
    SetFSBContainerError(ANumBlocksTxt,ANumBlocks,1,false);

  {$ifdef CPU64}
  {$endif CPU64}

  // Upper bound is not checked !

  if FSBContMaxIndex > -1 then
  begin
    with FSBContainers[AIndex] do  // Is already in use.
      if Suc<>Main then
        RaiseSetFSBContainerError(AContNumTxt, IntToStr(AIndex),
          ' is already set');

    if FSBContainers[AIndex-1].UnitsPerBlock > AUnitsPerBlock then
      RaiseSetFSBContainerError(AContNumTxt, IntToStr(AIndex) +
        AUnitsPerBlockTxt, ' is less the previous ');

    //if (AIndex < FSBContMaxIndex) and
    //  (FSBContainers[AIndex+1].UnitsPerBlock < AUnitsPerBlock) then
    //  exit;
  end;

  MainCont:=@FSBContainers[AIndex];

  {$ifdef Use_Threads_Support}
  if AIndex<FSBContMaxIndex then
    ThreadLock(@MainCont^.Locked);
  {$endif Use_Threads_Support}

  with FSBContainers[AIndex] do
  begin
    Index:=AIndex;
    {$ifdef Use_Threads_Support}
    Locked:=LockValue;
    {$endif Use_Threads_Support}
    Main:=MainCont;
    Pred:=MainCont;
    Suc:=MainCont;
    FreePFSB:=nil;
    StdCount:=0;
    UnitsPerBlock:=AUnitsPerBlock;
    NumBlocks:=ANumBlocks;
    FreeBlockCount:=0;
    BlockSize:=UnitsPerBlock*UnitSize;
    DataSize:=BlockSize-FSBHeaderSize;
    LDataUnitsPerBlock:=DataSize div UnitSize;
    DataUnitsPerBlock:=LDataUnitsPerBlock;
    TmpSize:=BlockSize*NumBlocks+ContHeaderSize;
    SizeGran:=TmpSize div Granularity;

    if (TmpSize mod Granularity)>0 then
      Inc(SizeGran);

    Size:=SizeGran*Granularity;
    SizeLimitCountInc:=MaxFSBCSize div Size;
    SizeLimit:=SizeLimitCountInc*Size;
    {$ifdef Gather_Heap_Stats}
    Overhead:=Size-NumBlocks*DataSize;
    {$endif Gather_Heap_Stats}
  end;

  if AIndex=0 then
    UnitsLowBound:=-1
  else
    UnitsLowBound:=FSBContainers[AIndex-1].DataUnitsPerBlock;

  for CorTableIndex:=UnitsLowBound + 1 to LDataUnitsPerBlock do
     CorrespondenceTable[CorTableIndex]:=AIndex;

  {$ifdef Use_Threads_Support}
  MainCont^.Locked:=UnlockValue;
  {$endif Use_Threads_Support}

  if AIndex>FSBContMaxIndex then
  begin
    FSBContMaxIndex:=AIndex;
    FSBMaxDataSize:=FSBContainers[AIndex].DataSize;
  end;

  result:=true;
end;

function InitFBSContainers: boolean;
var
  Index: NInt;
begin
  result:=false;

  for Index:=0 to CustomMaxFSBCTypeIndex do
  with StdContInitData[Index] do
    if not SetFSBContainer(Index,UnitsPerBlock,NumBlocks) then
      exit;

  FSBContainersInitialized:=true;
  result:=true;
end;

procedure SetSimplyMemoryManager;
const
  TxtAlign16 = DEOL + 'It must be aligned to 16.';
  Divider = {$ifdef CPU32} 8{$endif CPU32}
            {$ifdef CPU64}16{$endif CPU64};

{$if defined(Gather_Usage_Stats) or defined(Gather_Spinlock_Stats)}
var
  i: NInt;
{$endif}
begin
  if SimplyMM_IsUsed then
    exit;

  {$ifNdef FPC}
  ShowError('Simply Memory Manager can be useful only for Free Pascal / '+
    'Lazarus on Windows.' + DEOL +
    'Read the preamble at the top of this source.',1);
  {$endif FPC}

  if UnitSize mod 16 > 0 then
    ShowError('The "UnitSize" value is '+IntToStr(UnitSize)+TxtAlign16,1);

  {$ifNdef Use_Threads_Support}
  if IsMultiThread then
    {$ifdef MSWindows}
    ShowError('"Use_Threads_Support" is undefined in case of multithreading.'+DEOL+
    'Enable the "$define Use_Threads_Support" conditional.',1);
    {$endif MSWindows}
    {$ifdef Unix}
    ShowError('Multithreading support is not implemented and will not.'+DEOL+
     'Use native memory manager instead.',1);
    {$endif Unix}
 {$endif Use_Threads_Support}

  GetMemoryManager(SavedMemoryManager);

  SimplyMemoryManager:=SavedMemoryManager;

  with SimplyMemoryManager do
  begin
    GetMem:=@SimplyGetMem;
    AllocMem:=@SimplyAllocMem;
    ReAllocMem:=@SimplyReAllocMem;
    FreeMem:=@SimplyFreeMem;
    FreeMemSize:=@SimplyFreeMemSize;
    MemSize:=@SimplyMemSize;
    GetFPCHeapStatus:=@SimplyGetFPCHeapStatus;
    GetHeapStatus:=@SimplyGetHeapStatus;
  end;

  FillChar(SimplyMMFPCHeapStatus,SizeOf(SimplyMMFPCHeapStatus),0);

  Granularity:=65536;

  if not FSBContainersInitialized then
  begin
    PVSBs:=nil;

    if not InitFBSContainers then
      ShowError('Error initialize FSB containers.',1);
  end;

  {$ifdef Gather_Usage_Stats}
  for i:=0 to MaxFSBCTypeIndex do
  begin
    FSBStatsGetMem[i]:=0;
    FSBStatsFreeMem[i]:=0;
  end;

  AddFSBContainerCount:=0;
  FreeFSBContainerCount:=0;
  {$endif Gather_Usage_Stats}

  {$if defined(Use_Spinlock) and defined(Gather_Spinlock_Stats)}
  for i:=0 to 63 do
    MaxSpinlockCount[i]:=0;
  {$endif}

  {$if defined(Use_Threads_Support) and not defined(Use_Spinlock)}
  InitCriticalSection(CS);
  CSCount:=0;
  {$endif}

  SetMemoryManager(SimplyMemoryManager);
  SimplyMM_IsUsed:=true;
  AllocateReservedMemory;
end;

function RestoreSavedMemoryManager(DoForce: boolean = false): boolean;
var
  Index: NInt;
begin
  result:=false;

  if not SimplyMM_IsUsed then
    exit;

  if not DoForce then
  begin
    for Index:=0 to FSBContMaxIndex do
      if FSBContainers[Index].Suc<>nil then
        exit;

    if (PVSBs<>nil) or (PVSBs<>PReservedMemory) then
      exit;
  end;

  FreeReservedMemory;
  SetMemoryManager(SavedMemoryManager);

  {$if defined(Use_Threads_Support) and not defined(Use_Spinlock)}
  DoneCriticalSection(CS);
  {$endif}
  SimplyMM_IsUsed:=false;
  result:=true;
end;

const

  NoFSBContInitTxt = 'FBS containers are not initialized.';

procedure ShowFSBContInfo;
var
  Index: NInt;
begin
  OutTextMM(DEOL+'*** Fixed size blocks containers information ***'+DEOL,true);
  OutTextMM('OS memory granularity: '+IntToStr(Granularity)+
    '       Unit size: '+IntToStr(UnitSize)+' bytes.'+DEOL,true);
  OutTextMM('             Gran.   Overhead   Cont.   Min.        Size',true);
  OutTextMM('Index  Units  num.  Bytes   %%  Size   Blocks  Block    Data',true);
  OutTextMM('_____________________________________________________________',
    true);

  if not FSBContainersInitialized then
    if not InitFBSContainers then
    begin
      OutTextMM(NoFSBContInitTxt,true);
      exit;
    end;

  for Index:=0 to FSBContMaxIndex do
    with FSBContainers[Index] do
    OutTextMM(
      IntToStr(Index,4)+'   '+
      IntToStr(UnitsPerBlock,5)+'  '+
      IntToStr(Size div Granularity,2)+'    '+
      {$ifdef Gather_Heap_Stats}
      IntToStr(Overhead,5)+'  '+
      IntToStr((1000*Overhead) div Size,3)+' '+
      {$else}
      IntToStr(Size-NumBlocks*DataSize,5)+'  '+
      IntToStr((1000*(Size-NumBlocks*DataSize)) div Size,3)+' '+
      {$endif}
      IntToStr(Size,6)+'   '+
      IntToStr(NumBlocks,4)+' '+
      IntToStr(BlockSize,7)+' '+
      IntToStr(DataSize,7),true);
end;

procedure CheckFSBMemAddr;
const
  ProcName = '*** Fixed size block data address check';

  {$define STRICT_ADDRESS}

  ValidValues =
  {$ifdef STRICT_ADDRESS}
    {$ifdef CPU32}[0] {$endif CPU32}
    {$ifdef CPU64}[0] {$endif CPU64};
  {$else}
    {$ifdef CPU32}[0,4,8,12] {$endif CPU32}
    {$ifdef CPU64}[0,8] {$endif CPU64};
  {$endif}
var
  Index,
  i,MaxBlocksIndex: NInt;
  IsFound: boolean;
  MemPtrs: array of Pointer;
begin
  OutTextMM(DEOL + ProcName + EOL,true);

  if not FSBContainersInitialized then
  begin
    OutTextMM(DEOL + 'FSB containers were not initialized.' + EOL,true);
    exit;
  end;

  for Index:=0 to FSBContMaxIndex do
  with FSBContainers[Index] do
  begin
    MaxBlocksIndex:=FSBContainers[Index].NumBlocks*2 - 1;
    SetLength(MemPtrs,MaxBlocksIndex + 1);

    for i:=0 to MaxBlocksIndex do
      MemPtrs[i]:=GetMem(DataSize);

    IsFound:=false;

    for i:=0 to MaxBlocksIndex do
      if not ((NUInt(MemPtrs[i]) and $f) in ValidValues) then
      begin
        OutTextMM('MemBlock #: ' + IntToStr(i) +
        ', UnitsPerBlock: ' + IntToStr(UnitsPerBlock) +
        ', BlockSize: ' + IntToStr(BlockSize) +
        ', NumBlocks:  ' + IntToStr(NumBlocks) +
        ', MemPtr: $' + PtrToHex(MemPtrs[i]) + EOL,true);

        IsFound:=true;
        break;
       end;

    for i:=0 to MaxBlocksIndex do
      FreeMem(MemPtrs[i]);

    SetLength(MemPtrs,0);

    if IsFound then
      exit;
  end;

  OutTextMM(IntToStr(FSBContMaxIndex) + ' containers were checked.' + EOL,true);
end;

procedure ItIsDisabled(Msg1,Msg2: TSMMString; IsConfirm: boolean = true);
begin
   OutTextMM(' >>>> ' + Msg1 + ' is disabled <<<<' + DEOL +
    ' Enable it with {$define ' + Msg2 +'} in the SimplyMM.pas file.'+DEOL);

  if IsConfirm then
    ConfirmTTY('continue');
end;

procedure StatsDisabled(Msg: TSMMString; IsConfirm: boolean = true);
begin
  ItIsDisabled('Stats gathering',Msg,IsConfirm);
end;


procedure ShowFSBContUsageStats(NoWarning: boolean = false);
{$ifdef Gather_Usage_Stats}
const
  Separator1 =
    '-------------------------------------------------------------------------';
  Separator2 = '  |';
  Separator3 = '    |';

var
  i: NInt;
{$endif}
begin
  OutTextMM(DEOL+'         ' +
    '*** Fixed size blocks containers usage stats ***'+EOL,true);

  {$ifdef Gather_Usage_Stats}
  if not FSBContainersInitialized then
   if not InitFBSContainers then
   begin
     OutTextMM(NoFSBContInitTxt,true);
     exit;
   end;

  OutTextMM('FSB containers count   added: '+IntToStr(AddFSBContainerCount)+
    ',   released: '+IntToStr(FreeFSBContainerCount)+EOL,true);
  OutTextMM(Separator1,true);
  OutTextMM('  Index |   Units   | Data size | Get memory |' +
    ' Free memory |   Count',true);
  OutTextMM('  (type)| per block |  (bytes)  |    count   |' +
    '    count    | difference',true);
  OutTextMM(Separator1,true);

  for i:=0 to MaxFSBCTypeIndex do
    if (FSBStatsGetMem[i]<>0) or (FSBStatsFreeMem[i]<>0) then
     OutTextMM(IntToStr(i,6) + Separator2 +
       IntToStr(FSBContainers[i].UnitsPerBlock,7) + Separator3 +
       IntToStr(FSBContainers[i].DataSize,9) + Separator2+
       IntToStr(FSBStatsGetMem[i],10) + Separator2 +
       IntToStr(FSBStatsFreeMem[i],11) + Separator2 +
       IntToStr(FSBStatsGetMem[i] - FSBStatsFreeMem[i],10),true);

  OutTextMM(Separator1,true);
  OutTextMM(EOL);
  {$else}
  if NoWarning then
    exit;

  StatsDisabled('Gather_Usage_Stats');
  {$endif}
end;

procedure ShowSpinlockStat(NoWarning: boolean = false);
{$ifdef Gather_Spinlock_Stats}
const
  Txt_times =' time(s)';
var
  i: integer;
{$endif Gather_Spinlock_Stats}
begin
  OutTextMM(DEOL+'     *** Spinlock usage stats ***'+EOL,true);
  {$ifdef Use_Spinlock}
  {$ifdef Gather_Spinlock_Stats}
  OutTextMM('Total spinlock waiting loop count: '+
    IntToStr(SpinlockCount)+EOL,true);

  if MaxSpinlockCount[0]<>0 then
      OutTextMM('Spinlock did not wait: ' +
        IntToStr(MaxSpinlockCount[0]) + Txt_times );

  for i:=1 to 63 do
    if MaxSpinlockCount[i]<>0 then
      OutTextMM('The case of ' + IntToStr(i) + ' cycle(s) happened '+
        IntToStr(MaxSpinlockCount[i]) + Txt_times );

  OutTextMM(EOL,true);
  {$else}
  if not NoWarning then
    StatsDisabled('Gather_Spinlock_Stats');
  {$endif}
  {$else}
  {$ifdef Use_Threads_Support}
  if not NoWarning then
    ItIsDisabled('Spinlock','Use_Spinlock');
  {$else}
   if not NoWarning then
     ItIsDisabled('Threads support','Use_Threads_Support');
  {$endif NO Use_Threads_Support}
  {$endif NO Spinlock}
end;

 procedure ShowHeapStatus(NoWarning: boolean = false);
 {$ifNdef Gather_Heap_Stats}    {$endif}
 var
   FPCHeapStatus: TFPCHeapStatus;

 begin
   OutTextMM(DEOL+'     *** Heap Status ***'+EOL,true);

   FPCHeapStatus:=SimplyGetFPCHeapStatus;

   with FPCHeapStatus do
   begin
     OutTextMM('Current Heap Free: '+IntToStr(CurrHeapFree),true);
     OutTextMM('Current Heap Size: '+IntToStr(CurrHeapSize),true);
     OutTextMM('Current Heap Used: '+IntToStr(CurrHeapUsed),true);
     {$ifdef Gather_Heap_Stats}
     OutTextMM('Maximum Heap Size: '+IntToStr(MaxHeapSize),true);
     OutTextMM('Maximum Heap Used: '+IntToStr(MaxHeapUsed),true);
     {$else}
     if NoWarning then
       exit;

     OutTextMM(EOL);
     StatsDisabled('Gather_Heap_Stats',false);
     {$endif}
   end;
 end;

initialization
  SetSimplyMemoryManager;
finalization
  RestoreSavedMemoryManager;
end.

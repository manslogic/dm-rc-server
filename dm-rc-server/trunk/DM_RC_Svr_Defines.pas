unit DM_RC_Svr_Defines;

interface

uses
 Classes,
 Wizard;

type
 TUpdateDLInfoProc = procedure (Mode: Integer = 3) of object;
 TDoActionFunc = function(const Cmd, Param: String): String of object;

const
 CRLF = #13#10;
 CRLFSet: TCharSet = [#13, #10];
 SPCSet: TCharSet = [' '];

 IniFileName: string = 'DM_RC_Svr.ini';

 MaxWord: Word = 65535;

 Port_Default: Word = 10000;

 //
 tknCmd = 'cmd';
 tknParam = 'prm';

 //settings
 sSettings = 'Settings';
 sConnection = 'Connection';
 sPortLoc = 'PortLocal';
 sPortRem = 'PortRemote';
 sPortExt = 'PortExternal';
 sIPList = 'IPList';

 //
 iConnLocal = $0001;
 iConnRemote = $0002;
 iConnExternal = $0004;

 //No cansel form option
 sNoCancel = 'NOCANCEL';

 //additional DLInfo modes
 dsAll = 9;

 //mutex name for multithreading
 DMRC_DLInfo_MutexName = 'DMRemoteControlDLInfo';

var
 PluginsPath : String = '';

 //DLInfo is downloads info in form of <id>=<xmldata>
 DLInfo: TStrings = nil;

 Mutex_DLInfo: THandle = 0;


procedure DLInfoFree;
procedure DLInfoMutexCreate;
procedure DLInfoMutexFree;

implementation

uses
 Windows,
 SysUtils;

{ Common stuff }

procedure DLInfoFree;
begin
 if Assigned(DLInfo) then
   FreeAndNil(DLInfo);
end;

procedure DLInfoMutexCreate;
begin
 Mutex_DLInfo := CreateMutex(NIL, FALSE, DMRC_DLInfo_MutexName);
 if Mutex_DLInfo = 0 then
   RaiseLastOSError;
end;

procedure DLInfoMutexFree;
begin
 if Mutex_DLInfo<>0 then
  begin
   if CloseHandle(Mutex_DLInfo) then
     Mutex_DLInfo:=0
   else
     RaiseLastOSError;
  end;
end;

end.

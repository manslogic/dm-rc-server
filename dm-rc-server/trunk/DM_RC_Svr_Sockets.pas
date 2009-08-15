unit DM_RC_Svr_Sockets;

interface

uses
 Classes,
 OverbyteIcsWSocket, OverbyteIcsWSocketS;

type
  TSendThread = class(TThread)
  private
    { Private declarations }
  protected
    procedure Execute; override;
  end;

const
 tknSrv = 'srv';
 tknCli = 'cli';
 tknCls = 'cls';
 sSrvLoc = 'Local';
 sSrvRem = 'Remote';
 sSrvExt = 'External';

var
 WSSLocal: TWSocketServer = nil;
 WSSRemote: TWSocketServer = nil;
 WSSExternal: TWSocketServer = nil;

function SocketServerStart(var WSS: TWSocketServer; evtOnClientConnect: TWSocketClientConnectEvent): Boolean;
procedure SocketServerFree(var WSS: TWSocketServer);
function SocketServerGetConnected(WSS: TWSocketServer; List: TStrings; ClearList: Boolean = false): Integer;

procedure SendThreadStart;
procedure SendThreadResume;
procedure SendThreadFree;

procedure AddToSendQueue(const Owner, Msg: String);

function ClientIndex(WSS: TWSocketServer; Client: TWSocketClient): Integer;

implementation

uses
 Windows,
 SysUtils,
 DM_RC_Svr_Defines,
 DM_RC_Svr_Tokens,
 DM_RC_Svr_Settings,
 DM_RC_Svr_ExternalIP,
 Tokens;

//const
 //mutex name for multithreading
 //DMRC_SendQueue_MutexName = 'DMRemoteControlSendQueue';

var
 CS_SndQ: TRTLCriticalSection;
 //messages to send is encoded as <srv>server</srv><cli>client</cli><cmd>text</cmd>
 SendQueue: TStrings = nil;
 //Mutex_SendQueue: THandle = 0;
 SendThread: TSendThread = nil;

{ Common stuff }

procedure SendQueueMutexCreate;
begin
 {
 Mutex_SendQueue := CreateMutex(NIL, FALSE, DMRC_SendQueue_MutexName);
 if Mutex_SendQueue = 0 then
   RaiseLastOSError;
 }
 InitializeCriticalSection(CS_SndQ);
end;

procedure SendQueueMutexFree;
begin
 {
 if Mutex_SendQueue<>0 then
  begin
   if CloseHandle(Mutex_SendQueue) then
     Mutex_SendQueue:=0
   else
     RaiseLastOSError;
  end;
 }
 DeleteCriticalSection(CS_SndQ);
end;

procedure SendQueueFree;
begin
 if Assigned(SendQueue) then
   FreeAndNil(SendQueue);
end;

procedure SendThreadStart;
begin
 SendThreadFree;
 SendQueueMutexCreate;
 SendQueue:=TStringList.Create;
 SendThread:=TSendThread.Create(true);
 SendThread.Priority:=tpLower;
end;

procedure SendThreadResume;
begin
 if SendThread.Suspended then
   SendThread.Resume;
end;

procedure SendThreadFree;
begin
 if Assigned(SendThread) then
  begin
   SendThread.Terminate;
   if not SendThread.Suspended then
     SendThread.WaitFor;
   FreeAndNil(SendThread);
  end;
 SendQueueFree;
 SendQueueMutexFree;
end;

procedure AddToSendQueue(const Owner, Msg: String);
begin
 //MessageBox(0, PChar('Adding '+Msg+' ...'), 'Sender', MB_OK or MB_ICONWARNING); //debug
 //WaitForSingleObject(Mutex_SendQueue, INFINITE);
 EnterCriticalSection(CS_SndQ);
 SendQueue.Add(Owner+EncodeToken(tknCmd, Msg));
 //ReleaseMutex(Mutex_SendQueue);
 LeaveCriticalSection(CS_SndQ);
 //MessageBox(0, 'Done.', 'Sender', MB_OK or MB_ICONWARNING); //debug
end;

function SocketServerStart(var WSS: TWSocketServer; evtOnClientConnect: TWSocketClientConnectEvent): Boolean;
begin
 if Assigned(WSS) then
   SocketServerFree(WSS);
 WSS := TWSocketServer.Create(nil);
 WSS.OnClientConnect := evtOnClientConnect;
 WSS.Banner          := ''; //tknBanner;
 WSS.Proto           := 'tcp';         { Use TCP protocol  }
 if WSS = WSSLocal then
  begin
   //local connection
   WSS.Addr:='127.0.0.1';
   WSS.Port:=Settings[sPortLoc];
  end;
 if WSS = WSSRemote then
  begin
   //remote connection
   if Settings[sIPList]>0 then
     WSS.Addr:=Settings.Group[sIPList, 0]
   else
     WSS.Addr:='';
   WSS.Port:=Settings[sPortRem];
  end;
 if WSS = WSSExternal then
  begin
   //external connection
   WSS.Addr:=GetExternalIP(Settings[sEIPURL], Settings[sEIPPrefix], Settings[sEIPProxy], StrToIntDef(Settings[sEIPPort], EIPPort_Default), Settings[sEIPUser], Settings[sEIPPass]);
   if (WSS.Addr=eieSiteNotFound) or
      (WSS.Addr=eiePrefixNotFound) then
     WSS.Addr:='';
   WSS.Port:=Settings[sPortExt];
  end;
 Result:=WSS.Addr<>'';
 if Result then
  begin
   WSS.ClientClass     := TWSocketClient;{ Use our component }
   WSS.Listen;                           { Start litening    }
  end
 else
   SocketServerFree(WSS);
end;

procedure SocketServerFree(var WSS: TWSocketServer);
begin
 if Assigned(WSS) then
  begin
   WSS.DisconnectAll;
   FreeAndNil(WSS);
  end;
end;

function SocketServerGetConnected(WSS: TWSocketServer; List: TStrings; ClearList: Boolean = false): Integer;
 var
  i: Integer;
begin
 Result:=-1;
 if Assigned(WSS) and Assigned(List) then
  begin
   Inc(Result);
   if ClearList then List.Clear;
   for i := 0 to WSS.ClientCount - 1 do
    begin
     //List.Add((WSS.Client[i] As TWSocketClient).Addr);
     List.Add((WSS.Client[i] As TWSocketClient).PeerAddr);
     //List.Add((WSS.Client[i] As TWSocketClient).DnsResult);
     //List.Add((WSS.Client[i] As TWSocketClient).Proto);
     //List.Add((WSS.Client[i] As TWSocketClient).LocalAddr);
     Inc(Result);
    end;
  end;
end;

{ TSendThread }

procedure TSendThread.Execute;
 var
  i: Integer;
  WSS: TWSocketServer;
  Cmd, Srv, Cli, Txt: String;
  NeedClose: Boolean;
begin
 while not Terminated do
  begin
   if Assigned(SendQueue) then
    begin
     if SendQueue.Count>0 then
      begin
       //FIFO
       //WaitForSingleObject(Mutex_SendQueue, INFINITE);
       EnterCriticalSection(CS_SndQ);
       Cmd:=SendQueue[0];
       SendQueue.Delete(0);
       //ReleaseMutex(Mutex_SendQueue);
       LeaveCriticalSection(CS_SndQ);
       //get message text
       Txt:=ExtractToken(tknCmd, Cmd);
       //lookup for server
       Srv:=ExtractToken(tknSrv, Cmd);
       WSS:=nil;
       if Srv=sSrvLoc then
         WSS:=WSSLocal;
       if Srv=sSrvRem then
         WSS:=WSSRemote;
       if Srv=sSrvExt then
         WSS:=WSSExternal;
       //send from available server
       if Assigned(WSS) then
        begin
         Cli:=ExtractToken(tknCli, Cmd);
         NeedClose:=StrToBoolDef(ExtractToken(tknCls, Cmd), false);
         {
         for i:=0 to WSS.ClientCount-1 do
          begin
           if (WSS.Client[i] as TWSocketClient).PeerAddr=Cli then
            begin
             (WSS.Client[i] as TWSocketClient).SendStr(Txt+CRLF);
             if NeedClose then
               (WSS.Client[i] as TWSocketClient).Close;
             //(WSS.Client[i] as TWSocketClient).StartConnection;
             //Break;
            end;
          end;
         }
         i:=StrToIntDef(Cli, -1);
         if (i>=0) and (i<WSS.ClientCount) then
          begin
           //MessageBox(0, PChar('['+Txt+']'), 'Sender', MB_OK or MB_ICONWARNING); //debug
           (WSS.Client[i] as TWSocketClient).SendStr(Txt+CRLF);
           if NeedClose then
             (WSS.Client[i] as TWSocketClient).Close;
          end;
        end;
       Sleep(100); //small pause to have a rest ;)
      end
     else
       Suspend; //no items in queue
    end
   else
     Suspend; //no queue
  end;
end;

function ClientIndex(WSS: TWSocketServer; Client: TWSocketClient): Integer;
begin
 if Assigned(WSS) and Assigned(Client) then
  begin
   Result:=WSS.ClientCount-1;
   while (WSS.Client[Result]<>Client) and (Result>=0) do
     Dec(Result);
  end
 else
   Result:=-1;
end;


end.

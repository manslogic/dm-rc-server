unit DM_RC_Svr_Commands;

interface

uses
  Classes,
  DM_RC_Svr_Defines;

type
  TIncomingThread = class(TThread)
  private
    { Private declarations }
    FDoAction: TDoActionFunc;
    FCmd, FParams, FResult: String;
    procedure DoStdAction;
  protected
    procedure Execute; override;
  public
    constructor Create(DoActionFunc: TDoActionFunc);
  end;

  TCommandsThread = class(TThread)
  private
    { Private declarations }
    FUpdate: TUpdateDLInfoProc;
    FMode: Integer;
    procedure SimpleUpdate;
  protected
    procedure Execute; override;
  public
    constructor Create(UpdateProc: TUpdateDLInfoProc);
  end;

var
 CommandsThread: TCommandsThread = nil;

 Mutex_Commands: THandle = 0;

procedure IncomingThreadStart(DoActionFunction: TDoActionFunc);
procedure IncomingThreadResume;
procedure IncomingThreadFree;

procedure AddToIncomingQueue(const Owner, Msg: String);

procedure CommandsThreadFree;
procedure CommandsMutexCreate;
procedure CommandsMutexFree;

implementation

uses
 Windows,
 SysUtils,
 DMAPI,
 DM_RC_Svr_Tokens,
 DM_RC_Svr_Sockets,
 Tokens,
 Wizard;

const
 //mutex name for multithreading
 DMRC_Commands_MutexName = 'DMRemoteControlCommands';
 //DMRC_IncomingQueue_MutexName = 'DMRemoteControlIncomingQueue';

var
 CS_IncQ: TRTLCriticalSection;
 //messages to send is encoded as <srv>server</srv><cli>client</cli><cmd>text</cmd>
 IncomingQueue: TStrings = nil;
 //Mutex_IncomingQueue: THandle = 0;
 IncomingThread: TIncomingThread = nil;

{ Common stuff }

procedure IncomingQueueMutexCreate;
begin
 {
 Mutex_IncomingQueue := CreateMutex(NIL, FALSE, DMRC_IncomingQueue_MutexName);
 if Mutex_IncomingQueue = 0 then
   RaiseLastOSError;
 }
 InitializeCriticalSection(CS_IncQ);
end;

procedure IncomingQueueMutexFree;
begin
 {
 if Mutex_IncomingQueue<>0 then
  begin
   if CloseHandle(Mutex_IncomingQueue) then
     Mutex_IncomingQueue:=0
   else
     RaiseLastOSError;
  end;
 }
 DeleteCriticalSection(CS_IncQ);
end;

procedure IncomingQueueFree;
begin
 if Assigned(IncomingQueue) then
   FreeAndNil(IncomingQueue);
end;

procedure IncomingThreadStart(DoActionFunction: TDoActionFunc);
begin
 IncomingThreadFree;
 IncomingQueueMutexCreate;
 IncomingQueue:=TStringList.Create;
 IncomingThread:=TIncomingThread.Create(DoActionFunction);
end;

procedure IncomingThreadResume;
begin
 if IncomingThread.Suspended then
   IncomingThread.Resume;
end;

procedure IncomingThreadFree;
begin
 if Assigned(IncomingThread) then
  begin
   IncomingThread.Terminate;
   if not IncomingThread.Suspended then
     IncomingThread.WaitFor;
   FreeAndNil(IncomingThread);
  end;
 IncomingQueueFree;
 IncomingQueueMutexFree;
end;

procedure AddToIncomingQueue(const Owner, Msg: String);
begin
 //WaitForSingleObject(Mutex_IncomingQueue, INFINITE);
 EnterCriticalSection(CS_IncQ);
 IncomingQueue.Add(Owner+EncodeToken(tknCmd, Msg));
 //ReleaseMutex(Mutex_IncomingQueue);
 LeaveCriticalSection(CS_IncQ);
end;

procedure CommandsThreadFree;
begin
 if Assigned(CommandsThread) then
  begin
   CommandsThread.Terminate;
   if not CommandsThread.Suspended then
     CommandsThread.WaitFor;
   FreeAndNil(CommandsThread);
  end;
end;

procedure CommandsMutexCreate;
begin
 Mutex_Commands := CreateMutex(NIL, FALSE, DMRC_Commands_MutexName);
 if Mutex_Commands = 0 then
   RaiseLastOSError;
end;

procedure CommandsMutexFree;
begin
 if Mutex_Commands<>0 then
  begin
   if CloseHandle(Mutex_Commands) then
     Mutex_Commands:=0
   else
     RaiseLastOSError;
  end;
end;

{ TIncomingThread }

constructor TIncomingThread.Create(DoActionFunc: TDoActionFunc);
begin
 inherited Create(true);
 Priority:=tpLower;
 FDoAction:=DoActionFunc;
 FResult:='';
 FCmd:='';
 FParams:='';
end;

procedure TIncomingThread.DoStdAction;
begin
 if Assigned(FDoAction) then
   FResult:=FDoAction(FCmd, FParams);
end;

procedure TIncomingThread.Execute;
 var
  Txt, Owner, CmdText, CmdWord, Cmd, Params: String;
begin
 while not Terminated do
  begin
   if Assigned(IncomingQueue) then
    begin
     if IncomingQueue.Count>0 then
      begin
       //FIFO
       //WaitForSingleObject(Mutex_IncomingQueue, INFINITE);
       EnterCriticalSection(CS_IncQ);
       Txt:=IncomingQueue[0];
       IncomingQueue.Delete(0);
       //ReleaseMutex(Mutex_IncomingQueue);
       LeaveCriticalSection(CS_IncQ);
       //recognize command
       Owner:=CopyToken(tknSrv, Txt)+CopyToken(tknCli, Txt);
       CmdText:=ExtractToken(tknCmd, Txt);
       Cmd:=ExtractWord(1, CmdText, SPCSet);
       if Cmd='GET' then
        begin
         //browser in air!
         Owner:=Owner+EncodeToken(tknCls, '1');
         CmdWord:=ExtractWord(2, CmdText, SPCSet);
         Cmd:=Copy(CmdWord, 2, Length(CmdWord));
         if Cmd='' then
           Cmd:=cmdSendBanner;
         //TODO: parse command & params
        end;
       //process "kernel" actions
       //MessageBox(0, PChar(Owner+' '+Cmd), 'Incoming', MB_OK or MB_ICONQUESTION); //debug
       if DefaultActions.IndexOf(Cmd)>=0 then
        begin
         FParams:=Trim(Copy(CmdText, Pos(Cmd, CmdText)+Length(Cmd), Length(CmdText)));
         FCmd:=Cmd;
         Synchronize(DoStdAction);
         AddToSendQueue(Owner, FResult);
         SendThreadResume;
        end;
       //process browser connection request
       if SameText(Cmd, cmdSendBanner) then
        begin
         AddToSendQueue(Owner, tknBanner);
         SendThreadResume;
        end;
       if SameText(Cmd, 'help') then
        begin
         AddToSendQueue(Owner, 'Расширенные комманды: starturl <url>, addurl <url>, ls [State], start <ID>, stop <ID>, info <ID>; Остальные комманды стандартные');
         SendThreadResume;
        end;
       Sleep(100);
      end
     else
       Suspend;
    end
   else
     Suspend;
  end;
end;

{ TCommandsThread }

constructor TCommandsThread.Create(UpdateProc: TUpdateDLInfoProc);
begin
 inherited Create(true);
 FUpdate:=UpdateProc;
 FMode:=-1;
end;

procedure TCommandsThread.SimpleUpdate;
begin
 if Assigned(FUpdate) then
   FUpdate(FMode);
end;

procedure TCommandsThread.Execute;
begin
  { Place thread code here }
end;

end.

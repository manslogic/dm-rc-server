unit DM_RC_Svr_Commands;

interface

uses
  Classes,
  DM_RC_Svr_Defines;

type
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

const

 //tags


 //mutex name for multithreading
 DMRC_Commands_MutexName = 'DMRemoteControlCommands';

var
 CommandsThread: TCommandsThread = nil;

 Mutex_Commands: THandle = 0;


procedure CommandsThreadFree;
procedure CommandsMutexCreate;
procedure CommandsMutexFree;

implementation

uses
 Windows,
 SysUtils,
 Tokens;

{ Important: Methods and properties of objects in visual components can only be
  used in a method called using Synchronize, for example,

      Synchronize(UpdateCaption);

  and UpdateCaption could look like,

    procedure TCommandsThread.UpdateCaption;
    begin
      Form1.Caption := 'Updated in a thread';
    end; }

{ Common stuff }

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

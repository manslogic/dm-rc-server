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
    function DoAction(const Cmd, Params: String): String;
  protected
    procedure Execute; override;
  public
    constructor Create(DoActionFunc: TDoActionFunc);
  end;
  (*
  TCommandsThread = class(TThread)
  private
    { Private declarations }
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
  *)

const
 chDefURLDelimiter = '|';

procedure IncomingThreadStart(DoActionFunction: TDoActionFunc);
procedure IncomingThreadResume;
procedure IncomingThreadFree;

procedure AddToIncomingQueue(const CmdOwner, Msg: String);
(*
procedure CommandsThreadFree;
procedure CommandsMutexCreate;
procedure CommandsMutexFree;
*)
implementation

uses
 Windows,
 SysUtils,
 HTTPApp,
 DMAPI,
 DM_RC_Svr_Settings,
 DM_RC_Svr_Tokens,
 DM_RC_Svr_Sockets,
 DM_RC_Svr_DLInfo,
 DM_RC_Svr_Web,
 DM_RC_Svr_Users,
 DM_RC_Svr_Controlled,
 Tokens,
 Wizard;

const
 {
 //mutex name for multithreading
 DMRC_Commands_MutexName = 'DMRemoteControlCommands';
 }

 //AddingURL parameters
 AddingUrl: array [0..15] of string = ('referer', 'description',
 'savepath', 'filename', 'user', 'password', 'sectionslimit',
 'priority', 'cookies', 'post', 'start', 'mirror1',
 'mirror2', 'mirror3', 'mirror4', 'mirror5');

var
 CS_IncQ: TRTLCriticalSection;
 //messages to send is encoded as <srv>server</srv><cli>client</cli><cmd>text</cmd>
 IncomingQueue: TStrings = nil;
 IncomingThread: TIncomingThread = nil;

{ Common stuff }

function GetUnknownParameter(Cmd: String; HasParameters: Boolean = true): String;
 var
  s: String;
begin
 s:=StUpCase(Cmd);
 if HasParameters then
   Result:=Format('Invalid parameter in command %s. To receive help about parameters please send:\n%s ?', [Cmd, Cmd])//GetMessage(imrcm_ParameterUnknown, [s, s])
 else
   Result:=Format('Invalid parameter in command %s. The command has no parameters.', [Cmd]);//GetMessage(imrcm_ParameterNone, [s]);
end;

//декодирование лишь при необходимости
function Check4Decode(URL: String): String;
 var
  p: Integer;
begin
 Result:=URL;
 repeat
  p:=Pos('%', Result);
  if p>0 then
    Result:=HTTPDecode(Result);
 until p=0;
end;

function GetAddingURLParams(InStr: String): String;
 var
  Param, URL, URLParam, v: String;
  i, t, k: Integer;
  f: Boolean;
begin
  Result:='';
  //http detection & fix
  Param:=StLoCase(Copy(InStr, 1, 7));
  if (Pos('h', Param)=1) and (Pos('p://', Param)=4) then
    Result:='http://'+Copy(InStr, 8, Length(InStr));
  if Result='' then
   begin
    //ftp detection
    Param:=StLoCase(Copy(InStr, 1, 6));
    if Pos('ftp://', Param)=1 then
      Result:=InStr;
   end;
  if Result<>'' then
   begin
    v:=Result;
    Result:='';
    i:=WordCount(v, [chDefURLDelimiter]); //считаем количество параметров
    //определяем ссылку
    if i=1 then
     begin
      URL:=Check4Decode(v);
      (* TODO
      //внутренний хак для корректной обработки "менеджера сайтов"
      Answer:=GetURLParams(UIN, URL);
      if Answer<>'' then //нашли параметры
       begin
        v:=URL+cDefURLDelimiter+Answer; //дописываем параметры к строке
        i:=WordCount(v, [cDefURLDelimiter]); //переустанавливаем их количество
       end;
      *)
     end
    else
      URL:=Check4Decode(ExtractWord(1, v, [chDefURLDelimiter])); //вырезаем ссылку
    (* TODO
    //
    if ((LogOptions and cLogUse)>0) and Assigned(LogFile) and ((LogOptions and cLogCmd)>0) then
      LogFile.Add(TimeToStr(Time), cLogCommand, 'Найден URL: '+URL);
    *)
    (* TODO
    //выбираем чё делать
    Param:=ExtractFileExt(URL); //расширение типа .xxx
    if ExtStrings.IndexOf(StLoCase(Copy(Param, 2, Length(Param))))<0 then //ссылка-нестандарт
     begin
      if ((LogOptions and cLogUse)>0) and Assigned(LogFile) and ((LogOptions and cLogCmd)>0) then
        LogFile.Add(TimeToStr(Time), cLogCommand, 'Нестандартная ссылка: расширение '+Param);
      //
      Mode:=Sets[cLinksMode];
     end
    else
      Mode:=cLMDM;
    LeaveToDM:=false;
    case Mode of
     cLMDM:
      begin
       LeaveToDm:=true;
      end;
     cLMClip:
      begin
       CopyToClipboard(URL);
       AddToQueue(UIN, 'Ссылка скопирована в буфер обмена:'+#13#10+URL+#13#10+'Кто знает, что с ней стало...');
      end;
     cLMUSD:
      begin
       if FitsToUSD(URL) then
        begin
         USDurls.Add(URL);
         AddToQueue(UIN, 'Ссылка подготовлена для передачи в USDownloader:'+#13#10+URL);
        end
       else
        begin
         if Sets[cUSDNone]=cUSDDM then
           LeaveToDM:=true
         else
           AddToQueue(UIN, 'Ссылка не опознана как подходящая для закачки:'+#13#10+URL);
        end;
      end;
     else
      begin
       AddToQueue(UIN, 'Ссылка не опознана как подходящая для закачки:'+#13#10+URL);
      end;
     end;
    *)
    //if LeaveToDM then
     begin
       //ссылка оставлена для DM
       //AddedIDs.Add(URL+'='+EncodeToken(tUIN, UIN)); //кладём адрес и номер в список добавленных плагином закачек
       // защита от = в ссылке
       // TODO //AddedIDs.Add(HTTPEncode(URL)+'='+EncodeToken(tUIN, UIN)); //кладём адрес и номер в список добавленных плагином закачек
       if i=1 then //только ссылка
        begin
         Result:=EncodeToken('url', URL)+EncodeToken('hidden', '1');
         (* TODO
         if Sets[cUINAsFolder] then //если папка не задана, но используется UIN
           Command:=Command+EncodeToken('savepath', DMDefaultSaveFolder+UIN+'\');
         myIDmInterface.DoAction('AddingURL', Command);
         if ((LogOptions and cLogDld)>0) and Assigned(LogFile) then
           LogFile.Add(TimeToStr(Time), cLogDownload, 'Добавление: '+Command);
         *)
        end
       else
        begin
         Result:=EncodeToken('url', URL)+EncodeToken('hidden', '1');
         // TODO //NoSavePath:=true;
         for t:=2 to i do //перебираем параметры
          begin
           Param:=ExtractWord(t, v, [chDefURLDelimiter]); //вырезаем очередной
           if WordCount(Param, ['='])>1 then //точно типа параметр?
            begin
             URLParam:=StLoCase(ExtractWord(1, Param, ['='])); //вырезаем параметр
             k:=Low(AddingUrl);
             repeat // ищем в списке параметров наш
              f:=URLParam=AddingUrl[k];
              inc(k);
             until f or (k>High(AddingUrl));
             if f then //если нашли - добавляем
              begin
               if URLParam='savepath' then //юзер задал папку
                begin
                 // TODO //NoSavePath:=false;
                 (* TODO
                 if Sets[cUINAsFolder] then //в качестве папки используется UIN
                  begin
                   if Sets[cUAFStrict] then //и принудительно
                     Command:=Command+EncodeToken(Answer, DMDefaultSaveFolder+UIN+'\')
                   else
                     Command:=Command+EncodeToken(Answer, ExtractWord(2, Param, ['=']));
                  end
                 else
                 *)
                   Result:=Result+EncodeToken(URLParam, ExtractWord(2, Param, ['=']));
                end
               else
                begin
                 if Pos('mirror', URLParam)=1 then
                   Result:=Result+EncodeToken(URLParam, Check4Decode(ExtractWord(2, Param, ['='])))
                 else
                  begin
                   if URLParam='post' then
                    begin
                     v:=ExtractWord(2, Param, ['=']);
                     for k:=3 to WordCount(Param, ['=']) do
                       v:=v+'='+ExtractWord(k, Param, ['=']);
                     Result:=Result+EncodeToken(URLParam, v);
                    end
                   else
                     Result:=Result+EncodeToken(URLParam, ExtractWord(2, Param, ['=']));
                  end;
                end;
              end;
            end;
          end;
         (* TODO
         if NoSavePath and Sets[cUINAsFolder] then //если папка не задана, но используется UIN
           Command:=Command+EncodeToken('savepath', DMDefaultSaveFolder+UIN+'\');
         *)
         (* TODO
         if ((LogOptions and cLogDld)>0) and Assigned(LogFile) then
           LogFile.Add(TimeToStr(Time), cLogDownload, 'Добавление: '+Command);
         *)
        end;
     end;
   end;
end;

function GetNthParameter(LinkParams: String; N: Integer): String;
begin
 //parameters are separated by '&'
 Result:=ExtractWord(N, LinkParams, AMPSet);
 //name & value are separated by '='
 if Result<>'' then
   Result:=ExtractWord(2, Result, EQSet);
end;

function GetParameter(LinkParams: String; Parameter: String): String;
 var
  i: Integer;
  s: String;
begin
 Result:='';
 for i:=1 to WordCount(LinkParams, AMPSet) do
  begin
   //parameters are separated by '&'
   s:=ExtractWord(i, LinkParams, AMPSet);
   //name & value are separated by '='
   if ExtractWord(1, s, EQSet) = Parameter then
    begin
     Result:=ExtractWord(2, s, EQSet);
     Break;
    end;
  end;
end;

procedure IncomingQueueMutexCreate;
begin
 InitializeCriticalSection(CS_IncQ);
end;

procedure IncomingQueueMutexFree;
begin
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
 if Assigned(IncomingThread) then
  begin
   if IncomingThread.Suspended then
     IncomingThread.Resume;
  end;
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

procedure AddToIncomingQueue(const CmdOwner, Msg: String);
begin
 if Assigned(IncomingQueue) then
  begin
   EnterCriticalSection(CS_IncQ);
   IncomingQueue.Add(CmdOwner+EncodeToken(tknCmd, Msg));
   LeaveCriticalSection(CS_IncQ);
  end;
end;

(*
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
*)

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
 //MessageBox(0, PChar(FCmd+' '+FParams), 'Before action...', MB_OK or MB_ICONQUESTION); //debug
 if Assigned(FDoAction) then
   FResult:=FDoAction(FCmd, FParams)
 else
   FResult:='No action defined!';
end;

function TIncomingThread.DoAction(const Cmd, Params: String): String;
begin
 if Assigned(FDoAction) then
   Result:=FDoAction(FCmd, FParams)
 else
   FResult:='Kernel panic!';
end;

procedure TIncomingThread.Execute;
 var
  Txt, CmdOwner, CmdText, CmdWord, Cmd, Params, Answer: String;
  Browser, Unknown: Boolean;
  i: Integer;
begin
 while not Terminated do
  begin
   if Assigned(IncomingQueue) then
    begin
     EnterCriticalSection(CS_IncQ);
     if IncomingQueue.Count>0 then
      begin
       Browser:=false;
       Unknown:=true;
       //FIFO
       Txt:=IncomingQueue[0];
       IncomingQueue.Delete(0);
       LeaveCriticalSection(CS_IncQ);
       //recognize command
       CmdOwner:=CopyToken(tknSrv, Txt)+CopyToken(tknCli, Txt)+CommandOwner(Txt);
       CmdText:=ExtractToken(tknCmd, Txt);
       Cmd:=ExtractWord(1, CmdText, SPCSet);
       if Cmd='GET' then
        begin
         //browser in air!
         Browser:=true;
         CmdOwner:=CmdOwner+EncodeToken(tknCls, '1');
         CmdWord:=ExtractWord(2, CmdText, SPCSet);
         CmdText:=CmdWord;
         //MessageBox(0, PChar(CmdOwner+' >'+CmdWord+'<'), 'Incoming', MB_OK or MB_ICONQUESTION); //debug
         Cmd:=Copy(CmdWord, 2, Length(CmdWord));
         //MessageBox(0, PChar(CmdOwner+' >'+Cmd+'<'), 'Incoming', MB_OK or MB_ICONQUESTION); //debug
         if Cmd='' then
           Cmd:=cmdSendBanner;
         //TODO: parse command & params
         //<command>?<param1>=<value1>&<param2>=<value2>...
         Params:=HTTPDecode(ExtractWord(2, Cmd, ['?']));
         Cmd:=ExtractWord(1, Cmd, ['?']);
         //MessageBox(0, PChar(Cmd+' '+Params), 'Incoming', MB_OK or MB_ICONQUESTION); //debug
        end
       else
         Params:=Trim(Copy(CmdText, Pos(Cmd, CmdText)+Length(Cmd), Length(CmdText)));
       Answer:='';
       //process "kernel" actions
       //MessageBox(0, PChar(CmdOwner+' >'+Cmd+'<'), 'Incoming', MB_OK or MB_ICONQUESTION); //debug
       if Assigned(DefaultActions) then
        begin
         if DefaultActions.IndexOf(Cmd)>=0 then
          begin
           if Settings[sDMAPI] then
            begin
             FParams:=Trim(Copy(CmdText, Pos(Cmd, CmdText)+Length(Cmd), Length(CmdText)));
             FCmd:=Cmd;
             //Synchronize(DoStdAction);  //??? blocks
             //Answer:=FResult;
             Answer:=DoAction(FCmd, FParams);
             Unknown:=false;
            end
           else
            begin
             Answer:='Direct DM API is disabled.';
             Unknown:=false;
            end;
          end;
        end
       else
         MessageBox(0, 'Not defined!', 'Default Actions', MB_OK or MB_ICONERROR); //debug
       //process browser connection request
       if SameText(Cmd, cmdSendBanner) then
        begin
         Answer:=webBanner;
         //Answer:=webLogin;
         //MessageBox(0, PChar(Answer), 'Default', MB_OK or MB_ICONQUESTION); //debug
         Unknown:=false;
        end;
       //process commands
       if SameText(Cmd, 'addurl') then
        begin
         if Params='' then
          begin
           if Browser=true then
             Answer:=webAddUrl
           else
             Answer:=GetUnknownParameter(Cmd);
          end
         else
          begin
           FCmd:='AddingURL';
           if Browser then
             FParams:=GetAddingURLParams(GetNthParameter(Params, 1)+chDefURLDelimiter+GetNthParameter(Params, 2))
           else
             FParams:=GetAddingURLParams(Params);
           //add URL to download
           DoAction(FCmd, FParams);
           //add URL to controlled
           AddCtrldURL(CmdOwnerToUserID(CmdOwner), ExtractToken(dliURL, FParams));
           //
           if Browser then
             Answer:=webUrlAdded
           else
             Answer:='Ссылка добавлена.';
          end;
         Unknown:=false;
        end;
       if SameText(Cmd, 'list') then
        begin
         FParams:='';
         if Browser then
          begin
           if Params='' then
            begin
             Answer:=webList;
             FParams:='';
            end
           else
            begin
             FParams:=GetParameter(Params, dliState);
            end;
          end
         else
          begin
           FParams:=Params;
          end;
         if FParams='9' then
           FParams:='';
         if Answer='' then
          begin
           //MessageBox(0, 'Before Critical...', 'LIST', MB_OK or MB_ICONQUESTION); //debug
           EnterCriticalSection(CS_DLInfo);
           //MessageBox(0, PChar(IntToStr(DLInfo.Count)), 'LIST', MB_OK or MB_ICONQUESTION); //debug
           for i:=0 to DLInfo.Count-1 do
            begin
             if Answer='' then
              begin
               if (FParams='') or (FParams=ExtractToken(dliState, DLInfo.ValueFromIndex[i])) then
                 Answer:=DLInfo.Names[i]+' '+ExtractFileName(ExtractToken(dliSave, DLInfo.ValueFromIndex[i]));
              end
             else
              begin
               if (FParams='') or (FParams=ExtractToken(dliState, DLInfo.ValueFromIndex[i])) then
                 Answer:=Answer+InternalLineSep+DLInfo.Names[i]+' '+ExtractFileName(ExtractToken(dliSave, DLInfo.ValueFromIndex[i]));
              end;
            end;
           LeaveCriticalSection(CS_DLInfo);
           if Browser then
             Answer:=Format(webListData, [Answer]);
          end;
         Unknown:=false;
        end;
       //
       if SameText(Cmd, 'help') then
        begin
         Answer:='Справка в разработке.';
         Unknown:=false;
        end;
       //
       if Unknown then
        begin
         if TokenExist(tknCls, CmdOwner) then
          begin
           if Browser then
            begin
             AddToSendQueue(CmdOwner, 'Неизвестная команда.');
             SendThreadResume;
            end;
          end
         else
          begin
           AddToSendQueue(CmdOwner, 'Неизвестная команда.');
           SendThreadResume;
          end;
        end
       else
        begin
         AddToSendQueue(CmdOwner, Answer);
         SendThreadResume;
        end;
       Sleep(100);
      end
     else
      begin
       LeaveCriticalSection(CS_IncQ);
       Sleep(100);
       Suspend;
      end;
    end
   else
     Suspend;
  end;
end;
(*
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
*)
end.

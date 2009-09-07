unit dmtest_pluginImpl;

interface

uses
  DMPluginIntf, Classes,
  Controls,
  StrUtils, //splitfns,
  OverbyteIcsWSocketS,
  DM_RC_Svr_Sockets;
const
  //укажите здесь информацию о своем плагине
  myPluginID = '{F78D5E99-7CC4-4E5C-8839-50BEEF99884D}';//обязательно укажите свой уникальный номер плагина (используйте Ctrl+Shift+G для генерации)
  myPluginName = 'Download Master Remote Control Server';//название плагина на английском языке
  myPluginVersion = '0.2';
  myPluginEmail = 'korneysan@tut.by';
  myPluginHomePage = 'none';
  myPluginCopyRight = chr(169)+'2008 Andrew++ '+chr(169)+'2009 Korney San';
  myMinNeedAppVersion = '5.0.2';//версия указывается без билда
  //описание плагина. Должно быть представлено на русском и английском языках. Может содержать подробную инструкцию по пользованию плагином.
  myPluginDescription = 'Download Master Remote Control Server';
  myPluginDescriptionRussian = 'Сервер удалённого управления Download Master';

type
  TDMTestPlugIn = class(TInterfacedObject, IDMPlugIn)
    private
      myIDmInterface: IDmInterface;
      //
      procedure DefineSettings;
      function LoadSettings: Boolean;
      procedure SaveSettings(Update: Boolean = true);
      procedure FormClosed(ModalResult: TModalResult = mrNone);
      procedure DoServers;
      procedure SettingsReady;
    protected

    public
      function getID: WideString; stdcall;
      //-----info
      function GetName: WideString; stdcall;//получаем инфу о плагине
      function GetVersion: WideString; stdcall;//получаем инфу о плагине
      function GetDescription(language: WideString): WideString; stdcall;//получаем инфу о плагине
      function GetEmail: WideString; stdcall;//получаем инфу о плагине
      function GetHomepage: WideString; stdcall;//получаем инфу о плагине
      function GetCopyright: WideString; stdcall;//получаем инфу о плагине
      function GetMinAppVersion: WideString; stdcall;//получаем минимальную версию ДМ-а с которой может работать плагин

      //------
      procedure PluginInit(_IDmInterface: IDmInterface); stdcall;//инициализация плагина и передача интерфейса для доступа к ДМ
      procedure PluginConfigure(params: WideString); stdcall;//вызов окна конфигурации плагина (окно конфигурации реализуется вами самостоятельно)
      procedure BeforeUnload; stdcall;//вызывается перед удалением плагина

      function EventRaised(eventType: WideString; eventData: WideString): WideString; stdcall;//вызывается из ДМ-ма при возникновении какого либо события
      { идентификатор плагина }
      property ID: WideString read getID;

      //------
      procedure ClientDataAvailable(Sender: TObject; Error: Word);//получили информацию от клиента
      procedure ClientConnect(Sender: TObject; Client: TWSocketClient; Error: Word);//подключился клиент
      //procedure TranslateMsg(const Owner, Msg: string);//передаем сообщения всем подключенным клиентам
      //procedure DoAction(const Owner, Cmd, Params: string);//обработка комманд
      //function GetInfo(DownloadId: string): string;
      //function GetShortInfo(DownloadId: string): string;
      //команда кодирована как <srv>сервер</srv><cli>адрес клиента</cli><cmd>команда</cmd>
      //procedure ProcessSingleCommand(Command: String); //обработка одной строки-команды
      function DoAnyAction(const Cmd, Params: String): String;
    published
  end;

  //TState = (dsPause, dsPausing, dsDownloaded, dsDownloading, dsError, dsErroring, dsQueue);

implementation

uses
 Windows,
 SysUtils,
 Variants,
 StringsSettings,
 DMAPI,
 DM_RC_Svr_Defines,
 DM_RC_Svr_Store,
 DM_RC_Svr_Users,
 DM_RC_Svr_DLInfo,
 DM_RC_Svr_Form,
 DM_RC_Svr_Commands,
 DM_RC_Svr_Controlled,
 DM_RC_Svr_Tokens,
 DM_RC_Svr_ExternalIP,
 DMSettings,
 Tokens,
 xIniFile,
 Wizard;

//------------------------------------------------------------------------------
function TDMTestPlugIn.GetName: WideString;//получаем инфу о плагине
begin
  Result := myPluginName;
end;
//------------------------------------------------------------------------------
function TDMTestPlugIn.GetVersion: WideString;//получаем инфу о плагине
begin
  Result := myPluginVersion;
end;
//------------------------------------------------------------------------------
function TDMTestPlugIn.GetDescription(language: WideString): WideString;//получаем инфу о плагине
begin
  if (language = 'russian') or (language = 'ukrainian') or (language = 'belarusian') then
    Result := myPluginDescriptionRussian
  else
    Result := myPluginDescription;
end;
//------------------------------------------------------------------------------
function TDMTestPlugIn.getID: WideString; stdcall;
begin
  Result:= myPluginID;
end;
(*
//------------------------------------------------------------------------------
procedure TDMTestPlugIn.TranslateMsg(const Owner, Msg: string);
{
var
  i: integer;
}
begin
 {
 if Assigned(WSS) then
  for i := 0 to WSS.ClientCount - 1 do
    (WSS.Client[i] As TWSocketClient).SendStr(Msg + CRLF);
 }
 //put message to send queue
 AddToSendQueue(Owner, Msg);
 //start sending thread
 SendThreadResume;
end;
*)
//------------------------------------------------------------------------------
procedure TDMTestPlugIn.ClientDataAvailable(Sender: TObject; Error: Word);
var
  RcvdLine: string;
  IndStart: integer;
  Srv, Cli, CmdOwner, Cmd: String;
begin
  with Sender as TWSocketClient do
  begin
    RcvdLine := ReceiveStr;
    //MessageBox(0, PChar('['+RcvdLine+']'), myPluginName, MB_OK or MB_ICONINFORMATION); //debug
    //Cli := PeerAddr;
    Cli := IntToStr(ClientIndex(Server as TWSocketServer, Sender as TWSocketClient));
    Srv := '';
    if (Server as TWSocketServer) = WSSLocal then
      Srv := sSrvLoc;
    if (Server as TWSocketServer) = WSSRemote then
      Srv := sSrvRem;
    if (Server as TWSocketServer) = WSSExternal then
      Srv := sSrvExt;
    //MessageBox(0, PChar(Srv+' '+Cli), myPluginName, MB_OK or MB_ICONINFORMATION); //debug
    CmdOwner:=EncodeToken(tknSrv, Srv)+EncodeToken(tknCli, Cli);
    if TokenExist(tknCmd, RcvdLine) then
     begin
      //XML encoded command
      CmdOwner:=CmdOwner+CommandOwner(RcvdLine);
      Cmd:=ExtractToken(tknCmd, RcvdLine);
      for IndStart:=1 to WordCount(Cmd, CRLFZSet) do
       begin
        AddToIncomingQueue(CmdOwner, ExtractWord(IndStart, Cmd, CRLFZSet));
        IncomingThreadResume;
       end;
     end
    else
     begin
      //direct/clean command
      for IndStart:=1 to WordCount(RcvdLine, CRLFSet) do
       begin
        //ProcessSingleCommand(EncodeToken(tknSrv, Srv)+EncodeToken(tknCli, Cli)+EncodeToken(tknCmd, ExtractWord(IndStart, RcvdLine, CRLFSet)));
        AddToIncomingQueue(CmdOwner, ExtractWord(IndStart, RcvdLine, CRLFSet));
        IncomingThreadResume;
       end;
      end;
  end;
end;
(*
//------------------------------------------------------------------------------
procedure TDMTestPlugIn.ProcessSingleCommand(Command: String);
 var
  Owner, CmdText, CmdWord, Cmd, Params: string;
begin
 Owner:=CopyToken(tknSrv, Command)+CopyToken(tknCli, Command);
 CmdText:=ExtractToken(tknCmd, Command);
 //TODO: add HTML processing

 //process [almost] standard command
 Cmd:=ExtractWord(1, CmdText, SPCSet);
 //MessageBox(0, PChar('['+Cmd+']'), myPluginName, MB_OK or MB_ICONINFORMATION); //debug
 if Cmd='GET' then
  begin
   //browser in air!
   Owner:=Owner+EncodeToken(tknCls, '1');
   CmdWord:=ExtractWord(2, CmdText, SPCSet);
   Cmd:=Copy(CmdWord, 2, Length(CmdWord));
   if Cmd='' then
     Cmd:=cmdSendBanner;
  end;
 MessageBox(0, PChar(Owner+' '+Cmd), myPluginName, MB_OK or MB_ICONQUESTION); //debug
 if DefaultActions.IndexOf(Cmd)>=0 then
  begin
   Params:=Trim(Copy(CmdText, Pos(Cmd, CmdText)+Length(Cmd), Length(CmdText)));
   DoAction(Owner, Cmd, Params);
  end;
 if SameText(Cmd, 'help') or SameText(Cmd, cmdSendBanner) then
   DoAction(Owner, Cmd, '');
 //process external commands
end;
//------------------------------------------------------------------------------
procedure TDMTestPlugIn.DoAction(const Owner, Cmd, Params: string);
var
  Answer: string;
  Lst: TStringList;
  i: integer;
begin
  Answer:='';
  if SameText(Cmd, cmdSendBanner) then
    Answer := tknBanner;
  if SameText(Cmd, 'help') then
    TranslateMsg(Owner, 'Расширенные комманды: starturl <url>, addurl <url>, ls [State], start <ID>, stop <ID>, info <ID>; Остальные комманды стандартные')
  else if SameText(Cmd, 'starturl') then
    Answer := myIDmInterface.DoAction('AddingURL', '<url>' + Params +
      '</url> <hidden>1</hidden>')
  else if SameText(Cmd, 'addurl') then
    Answer := myIDmInterface.DoAction('AddingURL', '<url>' + Params +
      '</url> <hidden>1</hidden> <start>0</start>')
  else if SameText(Cmd, 'start') then
    Answer := myIDmInterface.DoAction('StartDownloads', Params)
  else if SameText(Cmd, 'stop') then
    Answer := myIDmInterface.DoAction('StopDownloads', Params)
  {else if SameText(Cmd, 'ls') then
  begin
    Answer := myIDmInterface.DoAction('GetDownloadIDsList', Params);
    Lst    := TStringList.Create;
    Split(Answer, [' '], Lst);
    for i := 0 to Lst.Count - 1 do Lst[i] := GetShortInfo(Lst[i]);
    Answer := Lst.Text;
    Lst.Free;
  end else if SameText(Cmd, 'info') then
    Answer := GetInfo(Params)
  }
  ;
  {
  else
    Answer := myIDmInterface.DoAction(Cmd, Params);}

  if Length(Answer) > 0 then TranslateMsg(Owner, Answer);
end;
*)
(*
//------------------------------------------------------------------------------
function TDMTestPlugIn.GetInfo(DownloadId: string): string;
begin
  Result := myIDmInterface.DoAction('GetDownloadInfoByID', DownloadId);
  Result := Format('ID: %sURL: %sSave to: %sState: %s, Downloaded: %s/%s (Speed: %s)',
    [DownloadId + #13,
     GetStringBetween(Result, '<url>', '</url>') + #13,
     GetStringBetween(Result, '<saveto>', '</saveto>') + #13,
     //Ini.ReadString('State', GetStringBetween(Result, '<state>', '</state>'), ''),
     GetStringBetween(Result, '<downloadedsize>', '</downloadedsize>'),
     GetStringBetween(Result, '<size>', '</size>'),
     GetStringBetween(Result, '<speed>', '</speed>')]) + #13;
end;
//------------------------------------------------------------------------------
function TDMTestPlugIn.GetShortInfo(DownloadId: string): string;
begin
  Result := myIDmInterface.DoAction('GetDownloadInfoByID', DownloadId);
  Result := Format('ID: %s, URL: %s, State: %s',
    [DownloadId,
     GetStringBetween(Result, '<url>', '</url>'){,
     Ini.ReadString('State', GetStringBetween(Result, '<state>', '</state>'), '')}]) + #13;
end;
*)
//------------------------------------------------------------------------------
procedure TDMTestPlugIn.ClientConnect(Sender: TObject;
  Client: TWSocketClient; Error: Word);
begin
  Client.LineMode            := TRUE;
  Client.LineEdit            := TRUE;
  Client.OnDataAvailable     := ClientDataAvailable;
  //Client.OnLineLimitExceeded := ClientLineLimitExceeded;
  //Client.OnBgException       := ClientBgException;
end;
//------------------------------------------------------------------------------
procedure TDMTestPlugIn.PluginInit(_IDmInterface: IDmInterface);//инициализация плагина и передача интерфейса для доступа к ДМ
begin
 try
  myIDmInterface := _IDmInterface;
  //получаем необходимые папки и ключи
  PluginsPath:=IncludeTrailingPathDelimiter(myIDmInterface.DoAction('GetPluginDir', ''));
  IniName:=PluginsPath+'DM_RC_Svr.ini';
  IDIniName:=PluginsPath+'DM_RC_Svr_ID.ini';
  IniKey:=sRegPath+'\DM_RC_Svr';
  IDIniKey:=IniKey+'\ID';
  //создаем мутексы
  try
  DLInfoCreate;
  except
   on E: Exception do
     MessageBox(0, PChar(E.Message), 'DL info error!', MB_OK or MB_ICONERROR);
  end;
  //CommandsMutexCreate;
  CtrldCreate;
  //создаём пользователей
  try
  UsersCreate;
  except
   on E: Exception do
     MessageBox(0, PChar(E.Message), 'Users error!', MB_OK or MB_ICONERROR);
  end;
  //создаём потоки
  try
  IncomingThreadStart(DoAnyAction);
  SendThreadStart;
  except
   on E: Exception do
     MessageBox(0, PChar(E.Message), 'Threads error!', MB_OK or MB_ICONERROR);
  end;
  //создаём настройки
  try
  DefineSettings;
  except
   on E: Exception do
     MessageBox(0, PChar(E.Message), 'Settings error!', MB_OK or MB_ICONERROR);
  end;
  //читаем настройки
  if LoadSettings then
    try
    SettingsReady
    except
     on E: Exception do
       MessageBox(0, PChar(E.Message), 'Settings ready error!', MB_OK or MB_ICONERROR);
    end
  else
    PluginConfigure(sNoCancel);
 except
  on E: Exception do
    MessageBox(0, PChar(E.Message), 'Initalisation error!', MB_OK or MB_ICONERROR);
 end;
end;
//------------------------------------------------------------------------------
procedure TDMTestPlugIn.BeforeUnload;
begin
  myIDmInterface := nil;
  //убиваем форму (на всякий случай)
  CfgFormFree;
  //убиваем инфо закачек
  DLInfoFree;
  CtrldFree;
  //убиваем мутексы
  //CommandsMutexFree;
  //убиваем пользователей
  UsersFree;
  //убиваем настройки
  if Settings[sDumpMain]=cTimeExit then
    SaveSettings(false);
  xIniFree(SetMain);
  if Assigned(SetUser) and (Settings[sDumpUser]=cTimeExit) then
    SetUser.UpdateFile;
  xIniFree(SetUser);
  SettingsFree;
  //убиваем серверы
  SocketServerFree(WSSExternal);
  SocketServerFree(WSSRemote);
  SocketServerFree(WSSLocal);
  //убиваем потоки
  SendThreadFree;
  IncomingThreadFree;
end;
//------------------------------------------------------------------------------
procedure TDMTestPlugIn.PluginConfigure(params: WideString);//вызов окна конфигурации плагина
begin
 if not Assigned(CfgForm) then
  begin
   CfgForm:=TCfgForm.Create(nil);
  end;
 CfgForm.Settings:=Settings;
 if params=sNoCancel then
  begin
   CfgForm.BitBtn2.Enabled:=false;
   FormClosed(CfgForm.ShowModal);
  end
 else
   CfgForm.Show;
end;
//------------------------------------------------------------------------------
function TDMTestPlugIn.EventRaised(eventType: WideString; eventData: WideString): WideString;//вызывается из ДМ-ма при возникновении какого либо события
 var
  ID, IDI, URL: string;
  i, ds: Integer;
begin
  if eventType = 'dm_timer_5' then
   begin
    //проверяем форму на то, что она есть, но закрыта
    if Assigned(CfgForm) then
     begin
      if not CfgForm.Showing then
        //читаем настройки из формы и убиваем её
        FormClosed(CfgForm.ModalResult);
     end;
    //обновляем инфу о закачках
    UpdateDLInfo(myIDmInterface, dsAll);
    //сохраняем настройки, если нужно
    if Settings[sDumpMain]=cTime05 then
      SaveSettings(false);
    if Assigned(SetUser) and (Settings[sDumpUser]=cTime05) then
      SetUser.UpdateFile;
   end;
  if eventType = 'dm_timer_10' then
   begin
    //
    if Settings[sDumpMain]=cTime10 then
      SaveSettings(false);
    if Assigned(SetUser) and (Settings[sDumpUser]=cTime10) then
      SetUser.UpdateFile;
   end;
  if eventType = 'dm_timer_60' then
   begin
    //
    if Settings[sDumpMain]=cTime60 then
      SaveSettings(false);
    if Assigned(SetUser) and (Settings[sDumpUser]=cTime60) then
      SetUser.UpdateFile;
   end;
  {
  if eventType = 'dm_download_added' then
   begin
   end;
  }
  if eventType = 'dm_download_state' then
   begin
    ID:=ExtractWord(1, eventData, SPCSet);
    ds:=StrToIntDef(ExtractWord(2, eventData, SPCSet), -1);
    i:=CtrldIDIndex(ID);
    case ds of
     dsDownloaded:
      begin
       if i>=0 then
        begin
         //delete downloaded
         DelCtrld(i);
        end;
      end;
     dsDownloading:
      begin
       IDI:=myIDmInterface.DoAction('GetDownloadInfoByID', ID);
       //URL detect
       if i<0 then
        begin
         URL:=ExtractToken(dliURL, IDI);
         i:=CtrldURLIndex(URL);
         if i>=0 then
           RplCtrldURLbyID(URL, ID);
        end;
       //
       if i>=0 then
        begin
         //
        end;
      end;
     end;
   end;
end;
//------------------------------------------------------------------------------
function TDMTestPlugIn.GetEmail: WideString;//получаем инфу о плагине
begin
  Result:= myPluginEmail;
end;
//------------------------------------------------------------------------------
function TDMTestPlugIn.GetHomepage: WideString;//получаем инфу о плагине
begin
  Result:= myPluginHomePage;
end;
//------------------------------------------------------------------------------
function TDMTestPlugIn.GetCopyright: WideString;//получаем инфу о плагине
begin
  Result:= myPluginCopyright;
end;
//------------------------------------------------------------------------------
function TDMTestPlugIn.GetMinAppVersion: WideString;//получаем минимальную версию ДМ-а с которой может работать плагин
begin
  Result:= myMinNeedAppVersion;
end;
//------------------------------------------------------------------------------
procedure TDMTestPlugIn.DefineSettings;
begin
 SettingsFree;
 Settings:=TStringsSettings.Create;
 //
 Settings.AddAnyValue(sStore, varInteger, xitIni, xitIni, xitReg, ssSettings, true, true);
 Settings.AddAnyValue(sDumpMain, varInteger, cTimeNone, cTimeNone, cTime60, ssSettings);
 Settings.AddAnyValue(sDumpUser, varInteger, cTimeNone, cTimeNone, cTimeEvery, ssSettings);
 //
 Settings.AddAnyValue(sConnection, varInteger, iConnLocal, 0, iConnLocal or iConnRemote or iConnExternal, ssSettings);
 Settings.AddAnyValue(sPortLoc, varWord, Port_Default, 0, MaxWord, ssSettings);
 Settings.AddAnyValue(sPortRem, varWord, Port_Default, 0, MaxWord, ssSettings);
 Settings.AddAnyValue(sPortExt, varWord, Port_Default, 0, MaxWord, ssSettings);
 Settings.AddGroup(sIPList, 0, 100, varString, '', Null, Null, ssSettings, sIPList);
 Settings.AddAnyValue(sDMAPI, varBoolean, false, Null, Null, ssSettings);
 //external IP settings
 Settings.AddAnyValue(sEIPURL, varString, '', Null, Null, ssEIP, true);
 Settings.AddAnyValue(sEIPPrefix, varString, '', Null, Null, ssEIP, true);
 Settings.AddAnyValue(sEIPProxy, varString, '', Null, Null, ssEIP, true);
 Settings.AddAnyValue(sEIPPort, varWord, EIPPort_Default, 0, MaxWord, ssEIP, true);
 Settings.AddAnyValue(sEIPAuth, varBoolean, false, Null, Null, ssEIP, true);
 Settings.AddAnyValue(sEIPUser, varString, '', Null, Null, ssEIP, true);
 Settings.AddAnyValue(sEIPPass, varString, '', Null, Null, ssEIP, true);
 //users settings
 Settings.AddGroup(ssUsers, 0, cUsersMax, varString, '', Null, Null, ssSettings, ssUsers, true);
 //controlled downloads
 Settings.AddGroup(ssDownloads, 0, cDLMax, varString, '', Null, Null, ssSettings, ssDownloads, true);
end;
//------------------------------------------------------------------------------
function TDMTestPlugIn.LoadSettings: Boolean;
 var
  CreateMode: Integer;
begin
 //Result:=Settings.LoadValuesFromIni(PluginsPath+IniFIleName)=vreOK;
 Result:=false;
 try
 if (not Assigned(SetMain)) or (not Assigned(SetUser)) then
  begin
   if FileExists(IniName) then
     CreateMode:=xitIni
   else
    begin
     if RegistryKeyExists(IniKey) then
       CreateMode:=xitReg
     else
       CreateMode:=xitIni;
    end;
   case CreateMode of
    xitReg:
     begin
      SetMain:=TxIniFile.Create(IniKey, xitReg);
      SetUser:=TxIniFile.Create(IDIniKey, xitReg);
      Result:=Settings.LoadValuesFromReg(SetMain.Reg)=vreOK;
      Settings[sStore]:=xitReg;
     end;
    else
     begin
      SetMain:=TxIniFile.Create(IniName);
      SetUser:=TxIniFile.Create(IDIniName);
      Result:=Settings.LoadValuesFromIni(SetMain.Ini)=vreOK;
      Settings[sStore]:=xitIni;
     end
    end;
  end
 else
  begin
   case Settings[sStore] of
    xitReg:
      Result:=Settings.LoadValuesFromReg(SetMain.Reg, IniKey)=vreOK;
    else
      Result:=Settings.LoadValuesFromIni(SetMain.Ini)=vreOK;
    end;
  end;
 except
  on E: Exception do
    MessageBox(0, PChar(E.Message), 'Settings load error!', MB_OK or MB_ICONERROR);
 end;
end;
//------------------------------------------------------------------------------
procedure TDMTestPlugIn.SaveSettings(Update: Boolean = true);
begin
 //Settings.SaveValuesToIni(PluginsPath+IniFileName);
 CtrldToSettings(Settings);
 try
 case Settings[sStore] of
  xitReg:
    Settings.SaveValuesToReg(SetMain.Reg, IniKey);
  else
    Settings.SaveValuesToIni(SetMain.Ini);
  end;
 except
  on E: Exception do
    MessageBox(0, PChar(E.Message), 'Settings save error!', MB_OK or MB_ICONERROR);
 end;
 if Update then
   SettingsReady;
end;
//------------------------------------------------------------------------------
procedure TDMTestPlugIn.FormClosed(ModalResult: TModalResult = mrNone);
begin
 if Assigned(CfgForm) then
  begin
   if ModalResult=mrOK then
    begin
     Settings.Clear;
     Settings.AddStrings(CfgForm.Settings);
     SaveSettings();
    end;
   FreeAndNil(CfgForm);
  end;
end;
//------------------------------------------------------------------------------
procedure TDMTestPlugIn.DoServers;
begin
 if (Settings[sConnection] and iConnLocal)>0 then
  //try
   SocketServerStart(WSSLocal, ClientConnect)
  {
  except
   on E: Exception do MessageBox(0, PChar(E.Message), PChar(myPluginName+' (Local)'), MB_OK or MB_ICONERROR);
  end
  }
 else
   SocketServerFree(WSSLocal);
 //
 if (Settings[sConnection] and iConnRemote)>0 then
  //try
   SocketServerStart(WSSRemote, ClientConnect)
  {
  except
   on E: Exception do MessageBox(0, PChar(E.Message), PChar(myPluginName+' (Remote)'), MB_OK or MB_ICONERROR);
  end
  }
 else
   SocketServerFree(WSSRemote);
 //
 if (Settings[sConnection] and iConnExternal)>0 then
  //try
   SocketServerStart(WSSExternal, ClientConnect)
  {
  except
   on E: Exception do MessageBox(0, PChar(E.Message), PChar(myPluginName+' (External)'), MB_OK or MB_ICONERROR);
  end
  }
 else
   SocketServerFree(WSSExternal);
end;
//------------------------------------------------------------------------------
procedure TDMTestPlugIn.SettingsReady;
begin
 //here is a list of operations to do when settings are loaded or changed
 DoServers;
 EnterCriticalSection(CS_Users);
 UsersFromSettings(Settings);
 LeaveCriticalSection(CS_Users);
 EnterCriticalSection(CS_Ctrld);
 CtrldFromSettings(Settings);
 LeaveCriticalSection(CS_Ctrld);
end;
//------------------------------------------------------------------------------
function TDMTestPlugIn.DoAnyAction(const Cmd, Params: String): String;
begin
 Result:=myIDmInterface.DoAction(Cmd, Params);
end;
//------------------------------------------------------------------------------

end.

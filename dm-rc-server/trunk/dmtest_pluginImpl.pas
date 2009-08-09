unit dmtest_pluginImpl;

interface

uses
  DMPluginIntf, Classes, Dialogs,
  StrUtils, splitfns,
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
  myPluginDescriptionRussian = 'Сервер Download Master Remote Control';

type
  TDMTestPlugIn = class(TInterfacedObject, IDMPlugIn)
    private
      myIDmInterface: IDmInterface;
      //
      procedure DefineSettings;
      function LoadSettings: Boolean;
      procedure SaveSettings;
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
      procedure TranslateMsg(const Msg: string);//передаем сообщения всем подключенным клиентам
      procedure DoAction(const Cmd, Params: string);//обработка комманд
      function GetInfo(DownloadId: string): string;
      function GetShortInfo(DownloadId: string): string;
    published
  end;
  
  //TState = (dsPause, dsPausing, dsDownloaded, dsDownloading, dsError, dsErroring, dsQueue);

implementation

uses
 SysUtils,
 Variants,
 Controls,
 StringsSettings,
 DM_RC_Svr_Defines,
 DM_RC_Svr_Settings,
 DM_RC_Svr_Form;

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
//------------------------------------------------------------------------------
procedure TDMTestPlugIn.TranslateMsg(const Msg: string);
var
  i: integer;
begin
  for i := 0 to WSocketServer.ClientCount - 1 do
    (WSocketServer.Client[i] As TWSocketClient).SendStr(Msg + #13#10);
end;
//------------------------------------------------------------------------------
procedure TDMTestPlugIn.ClientDataAvailable(Sender: TObject; Error: Word);
var
  RcvdLine: string;
  IndStart: integer;
  Cmd, Params: string;
begin
  with Sender as TWSocketClient do
  begin
    { We use line mode. We will receive complete lines }
    RcvdLine := ReceiveStr;
    { Remove trailing CR/LF }
    while (Length(RcvdLine) > 0) and
          (RcvdLine[Length(RcvdLine)] in [#13, #10]) do
      RcvdLine := Copy(RcvdLine, 1, Length(RcvdLine) - 1);

    IndStart := AnsiPos(' ', RcvdLine);
    if IndStart = 0 then IndStart := length(RcvdLine) + 1;

    Cmd    := copy(RcvdLine, 0, IndStart-1);
    Params := copy(RcvdLine, IndStart+1, length(RcvdLine));
    DoAction(Cmd, Params);

    //RcvdLine := myIDmInterface.DoAction(Cmd, Params);
    //if Length(RcvdLine) > 0 then TranslateMsg(RcvdLine);
  end;
end;
//------------------------------------------------------------------------------
procedure TDMTestPlugIn.DoAction(const Cmd, Params: string);
var
  Answer: string;
  Lst: TStringList;
  i: integer;
begin
  if CompareText(Cmd, 'help') = 0 then
    TranslateMsg('Расширенные комманды: starturl <url>, addurl <url>, ls [State], start <ID>, stop <ID>, info <ID>; Остальные комманды стандартные')
  else if CompareText(Cmd, 'starturl') = 0 then
    Answer := myIDmInterface.DoAction('AddingURL', '<url>' + Params +
      '</url> <hidden>1</hidden>')
  else if CompareText(Cmd, 'addurl') = 0 then
    Answer := myIDmInterface.DoAction('AddingURL', '<url>' + Params +
      '</url> <hidden>1</hidden> <start>0</start>')
  else if CompareText(Cmd, 'start') = 0 then
    Answer := myIDmInterface.DoAction('StartDownloads', Params)
  else if CompareText(Cmd, 'stop') = 0 then
    Answer := myIDmInterface.DoAction('StopDownloads', Params)
  else if CompareText(Cmd, 'ls') = 0 then
  begin
    Answer := myIDmInterface.DoAction('GetDownloadIDsList', Params);
    Lst    := TStringList.Create;
    Split(Answer, [' '], Lst);
    for i := 0 to Lst.Count - 1 do Lst[i] := GetShortInfo(Lst[i]);
    Answer := Lst.Text;
    Lst.Free;
  end else if CompareText(Cmd, 'info') = 0 then
    Answer := GetInfo(Params)
  else
    Answer := myIDmInterface.DoAction(Cmd, Params);

  if Length(Answer) > 0 then TranslateMsg(Answer);
end;
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
  myIDmInterface := _IDmInterface;

  //получаем папку с плагинами
  PluginsPath:=IncludeTrailingPathDelimiter(myIDmInterface.DoAction('GetPluginDir', ''));
  //создаём настройки
  DefineSettings;
  //читаем настройки
  if not LoadSettings then
    PluginConfigure(sNoCancel);
  //создаем сервер и запускаем его
  SocketServerStart(ClientConnect);
end;
//------------------------------------------------------------------------------
procedure TDMTestPlugIn.BeforeUnload;
begin
  myIDmInterface := nil;
  //убиваем настройки
  SettingsFree;
  //убиваем форму (на всякий случай)
  CfgFormFree;
  //убиваем сервер
  SocketServerFree;
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
   if CfgForm.ShowModal=mrOK then
    begin
     Settings.Clear;
     Settings.AddStrings(CfgForm.Settings);
     SaveSettings;
    end;
   FreeAndNil(CfgForm);
  end
 else
   CfgForm.Show;
end;
//------------------------------------------------------------------------------
function TDMTestPlugIn.EventRaised(eventType: WideString; eventData: WideString): WideString;//вызывается из ДМ-ма при возникновении какого либо события
var
  IndStart: integer;
  ID, State: string;
begin
  IndStart := AnsiPos(' ', eventData);
  ID       := copy(eventData, 0, IndStart-1);
  State    := copy(eventData, IndStart+1, length(eventData));

  if eventType = 'dm_timer_5' then
   begin
    //проверяем форму на то, что она есть, но закрыта
    if Assigned(CfgForm) then
     begin
      if not CfgForm.Showing then
       begin
        //читаем настройки из формы и убиваем её
        if CfgForm.ModalResult=mrOK then
         begin
          Settings.Clear;
          Settings.AddStrings(CfgForm.Settings);
          SaveSettings;
         end;
        FreeAndNil(CfgForm);
       end;
     end;
   end;

  if AnsiStartsText('dm_download', eventType) then
   {
    TranslateMsg(Ini.ReadString('Events', eventType, eventType) + ' ' + ID + ' ' +
      Ini.ReadString('State', State, State));
    }
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
 Settings.AddAnyValue(sConnection, varInteger, iConnLocal, iConnLocal, iConnRemote, sSettings);
 Settings.AddAnyValue(sPort, varWord, Port_Default, 0, MaxWord, sSettings);
 Settings.AddGroup(sIPList, 0, 100, varString, '', Null, Null, sSettings, sIPList);
end;
//------------------------------------------------------------------------------
function TDMTestPlugIn.LoadSettings: Boolean;
begin
 Result:=Settings.LoadValuesFromIni(PluginsPath+IniFIleName)=vreOK;
end;
//------------------------------------------------------------------------------
procedure TDMTestPlugIn.SaveSettings;
begin
 Settings.SaveValuesToIni(PluginsPath+IniFIleName);
end;
//------------------------------------------------------------------------------






end.

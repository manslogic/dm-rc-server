library DM_RC_Client;

uses
  Windows,
  Messages,
  CommCtrl,
  SysUtils,
  m_globaldefs in 'api\m_globaldefs.pas',
  m_api in 'api\m_api.pas',
  dbsettings in 'api\dbsettings.pas',
  DM_RC_Client_Defines in 'DM_RC_Client_Defines.pas',
  OverbyteIcsWSocketS in 'ICS\OverbyteIcsWSocketS.pas',
  OverbyteIcsLogger in 'ICS\OverbyteIcsLogger.pas',
  OverbyteIcsTypes in 'ICS\OverbyteIcsTypes.pas',
  OverbyteIcsWinSock in 'ICS\OverbyteIcsWinsock.pas',
  OverbyteIcsWSocket in 'ICS\OverbyteIcsWSocket.pas',
  OverbyteIcsLibrary in 'ICS\OverbyteIcsLibrary.pas',
  OverbyteIcsWndControl in 'ICS\OverbyteIcsWndControl.pas',
  OverbyteIcsWSockBuf in 'ICS\OverbyteIcsWSockBuf.pas',
  Wizard in 'WIZARD.PAS',
  DM_RC_Client_Utils in 'DM_RC_Client_Utils.pas',
  DM_RC_Svr_Tokens in 'DM_RC_Svr_Tokens.pas',
  Tokens in 'Tokens.pas';

{$R *.res}

const
  PluginInfoEx: TPLUGININFOEX = (
    cbSize: SizeOf(TPLUGININFOEX);
    shortName: piShortName;
    version: piVersion;
    description: piDescription;
    author: piAuthor;
    authorEmail: piAuthorEmail;
    copyright: piCopyright;
    homepage: piHomepage;
    flags: UNICODE_AWARE;
    //flags: 0;
    replacesDefaultModule: 0;
    uuid: '{58896483-8268-4CC6-9D9E-8133847BD0B5}';
  );

var
  PluginInterfaces:array [0..1] of MUUID;

function MirandaPluginInfo(mirandaVersion:DWORD):PPLUGININFOEX; cdecl;
begin
  result:=@PluginInfoEx;
  PluginInfoEx.cbSize:=SizeOf(TPLUGININFO);
  PluginInfoEx.uuid  :=PluginInfoEx.uuid;
end;

function MirandaPluginInfoEx(mirandaVersion:DWORD):PPLUGININFOEX; cdecl;
begin
  result:=@PluginInfoEx;
  PluginInfoEx.cbSize:=SizeOf(TPLUGININFOEX);
  PluginInfoEx.uuid  :=PluginInfoEx.uuid;
end;

{$IFDEF _UNICODE}
type
  tstring = WideString;
const
  PREF_TCHAR2 = PREF_UTF;
{$ELSE}
type
 tstring = String;
const
 PREF_TCHAR2 = 0;
{$ENDIF}

procedure ClientInit; forward;
function GetContactUID(hContact: THandle; const szProto: PAnsiChar): String; forward;

{$include api\m_helpers.inc}

{$include DM_RC_Client_Options.inc}

{$include DM_RC_Client_TCP.inc}

{$include DM_RC_Client_Messages.inc}

function PreShutdown(wParam:WPARAM;lParam:LPARAM):int; cdecl;
begin
  result:=0;
  //FreeGroups;
  PluginLink^.UnhookEvent(hHookShutdown);
  PluginLink^.UnhookEvent(hHookOptions);
  PluginLink^.UnhookEvent(hHookFilterAdd);
  {
  PluginLink^.DestroyHookableEvent(hHookChanged);
  PluginLink^.DestroyHookableEvent(hevinout);
  PluginLink^.DestroyServiceFunction(hfree);
  PluginLink^.DestroyServiceFunction(hget);
  PluginLink^.DestroyServiceFunction(hrun);
  PluginLink^.DestroyServiceFunction(hrung);
  PluginLink^.DestroyServiceFunction(hinout);
  PluginLink^.DestroyServiceFunction(hsel);
  }
  //
  ClientFree;
end;

function OnModulesLoaded(wParam:WPARAM;lParam:LPARAM):int; cdecl;
{
var
  upd:TUpdate;
  buf:array [0..63] of AnsiChar;
}
begin
  Result:=0;
  PluginLink^.UnhookEvent(hHookOnLoad);
  hHookShutdown:=PluginLink^.HookEvent(ME_SYSTEM_SHUTDOWN, @PreShutdown);
  hHookOptions:=PluginLink^.HookEvent(ME_OPT_INITIALISE, @OnOptInitialise);
  hHookFilterAdd:=PluginLink^.HookEvent(ME_DB_EVENT_FILTER_ADD, @OnFilterAdd);
  (*
  LoadGroups;
  InitHelpFile;
  RegisterIcons;
  PluginLink^.NotifyEventHooks(hHookChanged,ACTM_LOADED,0);

  if PluginLink^.ServiceExists(MS_UPDATE_REGISTER)<>0 then
  begin
    with upd do
    begin
      cbSize              :=SizeOf(upd);
      szComponentName     :=PluginInfo.ShortName;
      szVersionURL        :=VersionURL;
      pbVersionPrefix     :=VersionPrefix;
      cpbVersionPrefix    :=StrLen(VersionPrefix);//length(VersionPrefix);
      szUpdateURL         :=UpdateURL;
      szBetaVersionURL    :=BetaVersionURL;
      pbBetaVersionPrefix :=BetaVersionPrefix;
      cpbBetaVersionPrefix:=StrLen(pbBetaVersionPrefix);//length(pbBetaVersionPrefix);
      szBetaUpdateURL     :=BetaUpdateURL;
      pbVersion           :=CreateVersionStringPlugin(@pluginInfo,buf);
      cpbVersion          :=StrLen(pbVersion);
      szBetaChangelogURL  :=BetaChangelogURL;
    end;
    PluginLink^.CallService(MS_UPDATE_REGISTER,0,dword(@upd));
  end;
  //CallService('DBEditorpp/RegisterSingleModule',dword(PluginShort),0);
  *)
  //
  ClientInit;
end;

function Load(link:PPLUGINLINK):int; cdecl;
begin
  Result:=0;
  PluginLink:=Pointer(link);
  InitMMI;
  {
  hHookChanged:=PluginLink^.CreateHookableEvent(ME_ACT_CHANGED);
  hevinout    :=PluginLink^.CreateHookableEvent(ME_ACT_INOUT);

  hfree :=PluginLink^.CreateServiceFunction(MS_ACT_FREELIST ,@ActFreeList);
  hget  :=PluginLink^.CreateServiceFunction(MS_ACT_GETLIST  ,@ActGetList);
  hrun  :=PluginLink^.CreateServiceFunction(MS_ACT_RUNBYID  ,@ActRun);
  hrung :=PluginLink^.CreateServiceFunction(MS_ACT_RUNBYNAME,@ActRunGroup);
  hinout:=PluginLink^.CreateServiceFunction(MS_ACT_INOUT    ,@ActInOut);
  hsel  :=PluginLink^.CreateServiceFunction(MS_ACT_SELECT   ,@ActSelect);
  }
  hHookOnLoad:=PluginLink^.HookEvent(ME_SYSTEM_MODULESLOADED, @OnModulesLoaded);
end;

function Unload: int; cdecl;
begin
  Result:=0;
end;

function MirandaPluginInterfaces:PMUUID; cdecl;
begin
  PluginInterfaces[0]:=PluginInfoEx.uuid;
  PluginInterfaces[1]:=MIID_LAST;
  result:=@PluginInterfaces;
end;

exports
  Load, Unload,
  MirandaPluginInfo,
  MirandaPluginInterfaces,
  MirandaPluginInfoEx;

end.

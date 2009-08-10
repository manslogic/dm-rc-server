unit DMAPI;

interface

uses
 Classes;

var
 DefaultActions: TStrings = nil;
 DefaultEvents: TStrings = nil;

procedure DefaultActionsSet;
procedure DefaultActionsFree;
procedure DefaultEventsSet;
procedure DefaultEventsFree;

implementation

uses
 SysUtils;

procedure DefaultActionsSet;
begin
 if Assigned(DefaultActions) then
  begin
   DefaultActions.Add('AddingURL');
   DefaultActions.Add('GetDownloadInfoByID');
   DefaultActions.Add('GetMaxSectionsByID');
   DefaultActions.Add('GetDownloadIDsList');
   DefaultActions.Add('GetTempDir');
   DefaultActions.Add('GetPluginDir');
   DefaultActions.Add('GetListDir');
   DefaultActions.Add('GetProgramDir');
   DefaultActions.Add('GetLanguage');
   DefaultActions.Add('GetProgramName');
   DefaultActions.Add('GetCategoriesList');
   DefaultActions.Add('GetSpeedsList');
   DefaultActions.Add('GetConnectionsList');
   DefaultActions.Add('GetLogDir');
   DefaultActions.Add('StartSheduled');
   DefaultActions.Add('StopSheduled');
   DefaultActions.Add('StartAll');
   DefaultActions.Add('StopAll');
   DefaultActions.Add('StartNode');
   DefaultActions.Add('StopNode');
   DefaultActions.Add('StartDownloads');
   DefaultActions.Add('StopDownloads');
   DefaultActions.Add('ChangeSpeed');
   DefaultActions.Add('RunApp');
   DefaultActions.Add('ConnectRAS');
   DefaultActions.Add('DisconnectRAS');
   DefaultActions.Add('ShutDown');
   DefaultActions.Add('HibernateMode');
   DefaultActions.Add('StandByMode');
   DefaultActions.Add('Exit');
   DefaultActions.Add('ChangeMaxDownloads');
   DefaultActions.Add('AddStringToLog');
  end;
end;

procedure DefaultActionsFree;
begin
 if Assigned(DefaultActions) then
   FreeAndNil(DefaultActions);
end;

procedure DefaultEventsSet;
begin
 DefaultEvents.Add('plugin_start');
 DefaultEvents.Add('plugin_stop');
 DefaultEvents.Add('dm_timer_60');
 DefaultEvents.Add('dm_timer_10');
 DefaultEvents.Add('dm_timer_5');
 DefaultEvents.Add('dm_download_state');
 DefaultEvents.Add('dm_download_added');
 DefaultEvents.Add('dm_downloadall');
 DefaultEvents.Add('dm_start');
 DefaultEvents.Add('dm_connect');
 DefaultEvents.Add('dm_changelanguage');
end;

procedure DefaultEventsFree;
begin
 if Assigned(DefaultEvents) then
   FreeAndNil(DefaultEvents);
end;

initialization

 DefaultActions:=TStringList.Create;
 DefaultActionsSet;
 DefaultEvents:=TStringList.Create;
 DefaultEventsSet;

finalization

 DefaultEventsFree;
 DefaultActionsFree;

end.
 
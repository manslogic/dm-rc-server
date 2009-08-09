unit DM_RC_Svr_Settings;

interface

uses
 StringsSettings;

var
 Settings: TStringsSettings = nil;

procedure SettingsFree;

implementation

uses
 SysUtils;

 {Common stuff}

procedure SettingsFree;
begin
 if Assigned(Settings) then
   FreeAndNil(Settings);
end;

end.
 
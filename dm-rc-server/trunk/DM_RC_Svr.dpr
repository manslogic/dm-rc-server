library DM_RC_Svr;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters. }

uses
  SysUtils,
  Classes,
  dmtest_pluginImpl in 'dmtest_pluginImpl.pas',
  DMPluginIntf in 'DMPluginIntf.pas',
  DM_RC_Svr_Form in 'DM_RC_Svr_Form.pas' {CfgForm},
  DM_RC_Svr_Defines in 'DM_RC_Svr_Defines.pas',
  DM_RC_Svr_Store in 'DM_RC_Svr_Store.pas',
  DM_RC_Svr_Sockets in 'DM_RC_Svr_Sockets.pas',
  StringsSettings in 'Utils\StringsSettings.pas',
  Tokens in 'Utils\Tokens.pas',
  DM_RC_Svr_Commands in 'DM_RC_Svr_Commands.pas',
  Wizard in 'Utils\WIZARD.PAS',
  DMSettings in 'DMSettings.pas',
  DMAPI in 'DMAPI.pas',
  DM_RC_Svr_ExternalIP in 'DM_RC_Svr_ExternalIP.pas',
  DM_RC_Svr_Tokens in 'DM_RC_Svr_Tokens.pas',
  DM_RC_Svr_DLInfo in 'DM_RC_Svr_DLInfo.pas',
  DMXMLParsers in 'DMXMLParsers.pas',
  DM_RC_Svr_Web in 'DM_RC_Svr_Web.pas',
  DM_RC_Svr_Users in 'DM_RC_Svr_Users.pas',
  xIniFile in 'Utils\xIniFile.pas',
  DM_RC_Svr_Controlled in 'DM_RC_Svr_Controlled.pas';

{$R *.res}
function RegisterPlugIn: IDMPlugIn; stdcall;
begin
  try
    Result := TDMTestPlugIn.Create;
  except
    Result := nil;
  end;
end;
exports RegisterPlugIn;

begin
end.

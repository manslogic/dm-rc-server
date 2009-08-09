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
  splitfns in 'splitfns.pas',
  DM_RC_Svr_Form in 'DM_RC_Svr_Form.pas' {CfgForm},
  DM_RC_Svr_Defines in 'DM_RC_Svr_Defines.pas',
  DM_RC_Svr_Sockets in 'DM_RC_Svr_Sockets.pas',
  DM_RC_Svr_Settings in 'DM_RC_Svr_Settings.pas',
  StringsSettings in 'StringsSettings.pas',
  Tokens in 'Tokens.pas';

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

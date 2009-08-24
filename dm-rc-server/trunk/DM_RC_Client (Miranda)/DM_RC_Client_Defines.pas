unit DM_RC_Client_Defines;

interface

uses
 Wizard;

const
  piFullName = 'Download Master Remote Control Client for Miranda';
  piShortName = 'DMRCClient';
  piVersion   = $00010000;
  piDescription =  'Intercepts messages from any protocol and send parsed commands to DM RC Server (plugin of Download Master).';
  piAuthor = 'Alexander Kornienko AKA Korney San';
  piauthorEmail = 'korneysan@tut.by';
  picopyright = '(c) 2009 Alexander Kornienko';
  pihomepage = '';
  piisTransient = 0;
  pireplacesDefaultModule = 0;

  MaxWord = 65535;

  CRLF = #13#10;
  CRLFSet: TCharSet = [#13, #10];
  CRLFZSet: TCharSet = [#0, #13, #10];

var
  hHookShutdown: THandle = 0;
  hHookOnLoad: THandle = 0;
  hHookOptions: THandle = 0;
  hHookFilterAdd: THandle = 0;

implementation

end.

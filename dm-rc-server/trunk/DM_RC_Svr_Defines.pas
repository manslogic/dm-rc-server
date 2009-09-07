unit DM_RC_Svr_Defines;

interface

uses
 Classes,
 DM_RC_Svr_Tokens,
 Wizard;

type
 TObjProc = procedure of object;
 TDoActionFunc = function(const Cmd, Params: String): String of object;

const
 CRLF = #13#10;
 CRLFSet: TCharSet = [#13, #10];
 CRLFZSet: TCharSet = [InternalLineSep, #13, #10];
 SPCSet: TCharSet = [' '];
 AMPSet: TCharSet = ['&'];
 EQSet: TCharSet = ['='];

 IniFileName: string = 'DM_RC_Svr.ini';

 MaxWord: Word = 65535;

 Port_Default: Word = 10000;

 //settings
 sConnection = 'Connection';
 sPortLoc = 'PortLocal';
 sPortRem = 'PortRemote';
 sPortExt = 'PortExternal';
 sIPList = 'IPList';
 sDMAPI = 'DMAPI';

 //
 iConnLocal = $0001;
 iConnRemote = $0002;
 iConnExternal = $0004;

 //No cansel form option
 sNoCancel = 'NOCANCEL';

var
 PluginsPath : String = '';

implementation

end.

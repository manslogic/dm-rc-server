unit DM_RC_Svr_Defines;

interface

uses
 Classes,
 Wizard;

type
 TObjProc = procedure of object;
 TDoActionFunc = function(const Cmd, Params: String): String of object;

const
 CRLF = #13#10;
 CRLFSet: TCharSet = [#13, #10];
 InternalLineSep = #0;
 CRLFZSet: TCharSet = [InternalLineSep, #13, #10];
 SPCSet: TCharSet = [' '];

 IniFileName: string = 'DM_RC_Svr.ini';

 MaxWord: Word = 65535;

 Port_Default: Word = 10000;

 //
 tknCmd = 'cmd';
 tknParam = 'prm';

 //settings
 ssSettings = 'Settings';
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

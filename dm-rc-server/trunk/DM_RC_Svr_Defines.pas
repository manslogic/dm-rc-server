unit DM_RC_Svr_Defines;

interface

const
 IniFileName: string = 'DM_RC_Svr.ini';

 MaxWord: Word = 65535;

 Port_Default: Word = 10000;

 //settings
 sSettings = 'Settings';
 sConnection = 'Connection';
 sPort = 'Port';
 sIPList = 'IPList';

 //
 iConnLocal = 0;
 iConnRemote = 1;

 //No cansel form option
 sNoCancel = 'NOCANCEL';

var
 PluginsPath : String = '';

implementation

end.

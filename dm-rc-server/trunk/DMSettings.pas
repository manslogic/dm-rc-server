unit DMSettings;

interface

const
 sRegPath = 'Software\2VG\Download Master';
 sAppPath = 'Download Master';
 sListsPath = 'lists';

 //Simple Shutdown Modes
 iHangUp = 0;
 iShutdown = 1; //DM registry value
 iHibernate = 2; //DM registry value
 iStandBy = 3; //DM registry value
 iQuit = 4;
 //
 iaHangUp = $01;
 iaShutdown = $02;
 iaHibernate = $04;
 iaStandby = $08;
 iaQuit = $10;
 //
 smMax    = 0;
 smNormal = 1;
 smLow    = 2;
 smAuto   = 3;
 smAdjust = 4;
 //
 dsPause = 0;
 dsPausing = 1;
 dsDownloaded = 2;
 dsDownloading = 3;
 dsError = 4;
 dsErroring = 5;
 dsQueue = 6;
 //
 ltOut = 0;
 ltIn = 1;
 ltInfo = 2;
 ltError = 3;

function DMShutdownMode: Integer;
function DMShutdownOnce(Mode: Integer): Boolean;
function DMShutdownModeAll: Integer;
function DMShutdownOnceAll: Integer;
function HasModeAll(ModeAll: Integer; Mode: Integer): Boolean;
function DMAutoDesc(Language: String; FirstCap: Boolean = false): String;
function DMShutdownModeDesc(Mode: Integer; Language: String; FirstCap: Boolean = false; EmptyIfNone: Boolean = false): String;
function DMShutdownOnceDesc(Once: Boolean; Language: String; FirstCap: Boolean = false; EmptyIfNone: Boolean = false): String;
function DMMaxDownloads: Integer;
function DMMaxSections: Integer;
function DMSpeedMode: Integer;
function DMSpeedModeDesc(Mode: Integer; Language: String; FirstCap: Boolean = false): String;
function DMDefaultDownloadList: String;
function DMUseIEProxy: Boolean;
function DMUseHTTPProxy: Boolean;
function DMUseFTPProxy: Boolean;
function DMDefaultSaveFolder: String;
//
function DMDownloadExtensions: String;
//
function DMNodelist: String;
function DMHistory: String;

implementation

uses
 ShlObj,
 SysUtils,
 StrUtils,
 Registry;

const
 sRegHang = 'AutoHangUp';
 sRegHangOnce = 'AutoHangUpOnce';
 sRegQuit = 'AutoQuit';
 sRegQuitOnce = 'AutoQuitOnce';
 sRegShutdown = 'AutoShutDown';
 sRegShutdownOnce = 'AutoShutDownOnce';
 //
 sMaxDownloads = 'MaxNumberSimultaneouslyDownloads';
 sMaxSections = 'MaxNumberSections';
 //
 sSpeedMode = 'SpeedMode';
 sManualSpeedLimit = 'ManualSpeedLimit';
 //
 sDefaultDownloadList = 'DefaultDownloadList';
 //
 sUseIEProxy = 'UseIEProxySettings';
 sUseHTTPProxy = 'UseHTTPProxy';
 sUseFTPProxy = 'UseFTPProxy';
 //
 sDownloadExtensions = 'DownloadExtensions';
 //
 sDefaultSaveFolder = 'DefaultSaveFolder';

 sNodeList = 'nodelist.xml';
 sDownloadsList = 'default.xml';
 sHistory = 'history.xml';

function DMShutdownMode: Integer;
 var
  i: Integer;
  RegIni: TRegIniFile;
begin
 Result:=-1;
 RegIni:=TRegIniFile.Create;
 RegIni.OpenKeyReadOnly(sRegPath);
 i:=RegIni.ReadInteger('', sRegHang, -1);
 if i>0 then
   Result:=iHangUp;
 if Result<0 then
  begin
   i:=RegIni.ReadInteger('', sRegShutdown, -1);
   if i>0 then
     Result:=i;
  end;
 if (Result<0) then
  begin
   i:=RegIni.ReadInteger('', sRegQuit, -1);
   if i>0 then
     Result:=iQuit;
  end;
 RegIni.Free;
end;

function DMShutdownModeAll: Integer;
 var
  i: Integer;
  RegIni: TRegIniFile;
begin
 Result:=0;
 RegIni:=TRegIniFile.Create;
 RegIni.OpenKeyReadOnly(sRegPath);
 i:=RegIni.ReadInteger('', sRegHang, -1);
 if i>0 then
   Result:=Result+iaHangUp;
 i:=RegIni.ReadInteger('', sRegShutdown, -1);
 if i>0 then
   case i of
    iShutdown: Result:=Result+iaShutdown;
    iHibernate: Result:=Result+iaHibernate;
    iStandby: Result:=Result+iaStandby;
    end;
 i:=RegIni.ReadInteger('', sRegQuit, -1);
 if i>0 then
   Result:=Result+iaQuit;
 RegIni.Free;
end;

function HasModeAll(ModeAll: Integer; Mode: Integer): Boolean;
begin
 Result:=false;
 if (ModeAll in [0..iaHangUp+iaShutdown+iaHibernate+iaStandby+iaQuit])
    and (Mode in [iHangUp, iShutdown, iHibernate, iStandby, iQuit]) then
  begin
   case Mode of
    iHangup: Result:=(ModeAll and iaHangup)>0;
    iShutdown: Result:=(ModeAll and iaShutdown)>0;
    iHibernate: Result:=(ModeAll and iaHibernate)>0;
    iStandby: Result:=(ModeAll and iaStandby)>0;
    iQuit: Result:=(ModeAll and iaQuit)>0;
    end;
  end;
end;

function DMShutdownOnce(Mode: Integer): Boolean;
 var
  RegIni: TRegIniFile;
begin
 Result:=false;
 RegIni:=TRegIniFile.Create;
 RegIni.OpenKeyReadOnly(sRegPath);
 case Mode of
  iHangUp:
    Result:=RegIni.ReadBool('', sRegHangOnce, false);
  iShutdown, iHibernate, iStandBy:
    Result:=RegIni.ReadBool('', sRegShutdownOnce, false);
  iQuit:
    Result:=RegIni.ReadBool('', sRegQuitOnce, false);
  end;
 RegIni.Free;
end;

function DMShutdownOnceAll: Integer;
 var
  RegIni: TRegIniFile;
begin
 Result:=0;
 RegIni:=TRegIniFile.Create;
 RegIni.OpenKeyReadOnly(sRegPath);
 if RegIni.ReadBool('', sRegHangOnce, false) then
   Result:=Result+iaHangUp;
 if RegIni.ReadBool('', sRegShutdownOnce, false) then
  begin
   Result:=Result+iaShutdown;
   Result:=Result+iaHibernate;
   Result:=Result+iaStandby;
  end;
 if RegIni.ReadBool('', sRegQuitOnce, false) then
   Result:=Result+iaQuit;
 RegIni.Free;
end;

function DMAutoDesc(Language: String; FirstCap: Boolean = false): String;
begin
 Result:='';
 if (Language = 'russian') or (Language = 'ukrainian') or (Language = 'belarusian') then
    Result:=IfThen(FirstCap, 'А', 'а')+'вто'
 else
  if language='translit' then
    Result:=IfThen(FirstCap, 'A', 'a')+'vto'
  else
    Result:=IfThen(FirstCap, 'A', 'a')+'uto';
end;

function DMShutdownModeDesc(Mode: Integer; Language: String; FirstCap: Boolean = false; EmptyIfNone: Boolean = false): String;
begin
 Result:='';
 if (Language = 'russian') or (Language = 'ukrainian') or (Language = 'belarusian') then
  begin
    case Mode of
     iHangUp: Result:=IfThen(FirstCap, 'О', 'о')+'тключиться от Интернет';
     iShutdown: Result:=IfThen(FirstCap, 'В', 'в')+'ыключить ПК';
     iHibernate: Result:=IfThen(FirstCap, 'С', 'с')+'пящий режим';
     iStandBy: Result:=IfThen(FirstCap, 'Ж', 'ж')+'дущий режим';
     iQuit: Result:=IfThen(FirstCap, 'В', 'в')+'ыйти из программы';
     else
      begin
       if not EmptyIfNone then
         Result:=IfThen(FirstCap, 'Н', 'н')+'ет';
      end;
     end;
  end
 else
  if language='translit' then
   begin
    case Mode of
     iHangUp: Result:=IfThen(FirstCap, 'O', 'o')+'tkluchit''sa ot Internet';
     iShutdown: Result:=IfThen(FirstCap, 'V', 'v')+'ykluchit'' PK';
     iHibernate: Result:=IfThen(FirstCap, 'S', 's')+'pyaschij rezhim';
     iStandBy: Result:=IfThen(FirstCap, 'Z', 'z')+'hduschij rezhim';
     iQuit: Result:=IfThen(FirstCap, 'V', 'v')+'yjti iz programmy';
     else
      begin
       if not EmptyIfNone then
         Result:=IfThen(FirstCap, 'N', 'n')+'et';
      end;
     end;
   end
  else
   begin
    case Mode of
     iHangUp: Result:=IfThen(FirstCap, 'D', 'd')+'isconnect';
     iShutdown: Result:=IfThen(FirstCap, 'S', 'S')+'hutdown PC';
     iHibernate: Result:=IfThen(FirstCap, 'H', 'h')+'ibernate PC';
     iStandBy: Result:=IfThen(FirstCap, 'S', 's')+'tandby mode';
     iQuit: Result:=IfThen(FirstCap, 'E', 'e')+'xit program';
     else
      begin
       if not EmptyIfNone then
         Result:=IfThen(FirstCap, 'N', 'n')+'one';
      end;
     end;
   end;
end;

function DMShutdownOnceDesc(Once: Boolean; Language: String; FirstCap: Boolean = false; EmptyIfNone: Boolean = false): String;
begin
 if (Language = 'russian') or (Language = 'ukrainian') or (Language = 'belarusian') then
  begin
   if Once then
     Result:=IfThen(FirstCap, 'Р', 'р')+'азово'
   else
    begin
     if not EmptyIfNone then
       Result:=IfThen(FirstCap, 'П', 'п')+'остоянно';
    end;
  end
 else
  if language='translit' then
   begin
   if Once then
     Result:=IfThen(FirstCap, 'R', 'r')+'azovo'
   else
    begin
     if not EmptyIfNone then
       Result:=IfThen(FirstCap, 'P', 'p')+'ostoyanno';
    end;
   end
  else
   begin
   if Once then
     Result:=IfThen(FirstCap, 'O', 'o')+'nce'
   else
    begin
     if not EmptyIfNone then
       Result:=IfThen(FirstCap, 'E', 'e')+'very time';
    end;
   end;
end;

function DMMaxDownloads: Integer;
 var
  RegIni: TRegIniFile;
begin
 RegIni:=TRegIniFile.Create;
 RegIni.OpenKeyReadOnly(sRegPath);
 Result:=RegIni.ReadInteger('', sMaxDownloads, 0);
 RegIni.Free;
end;

function DMMaxSections: Integer;
 var
  RegIni: TRegIniFile;
begin
 RegIni:=TRegIniFile.Create;
 RegIni.OpenKeyReadOnly(sRegPath);
 Result:=RegIni.ReadInteger('', sMaxSections, 0);
 RegIni.Free;
end;

function DMSpeedMode: Integer;
 var
  RegIni: TRegIniFile;
begin
 RegIni:=TRegIniFile.Create;
 RegIni.OpenKeyReadOnly(sRegPath);
 Result:=RegIni.ReadInteger('', sSpeedMode, -1);
 RegIni.Free;
end;

function DMSpeedModeDesc(Mode: Integer; Language: String; FirstCap: Boolean = false): String;
begin
 Result:='';
 if (Language = 'russian') or (Language = 'ukrainian') or (Language = 'belarusian') then
  begin
    case Mode of
     smMax: Result:=IfThen(FirstCap, 'М', 'м')+'аксимальная';
     smNormal: Result:=IfThen(FirstCap, 'С', 'с')+'редняя';
     smLow: Result:=IfThen(FirstCap, 'Н', 'н')+'изкая';
     smAuto: Result:=IfThen(FirstCap, 'А', 'а')+'втоматическая';
     smAdjust: Result:=IfThen(FirstCap, 'Р', 'р')+'егулируемая';
     end;
  end
 else
  if language='translit' then
   begin
    case Mode of
     smMax: Result:=IfThen(FirstCap, 'M', 'm')+'aksimal''naja';
     smNormal: Result:=IfThen(FirstCap, 'S', 's')+'rednaja';
     smLow: Result:=IfThen(FirstCap, 'N', 'n')+'izkaja';
     smAuto: Result:=IfThen(FirstCap, 'A', 'a')+'vtomaticheskaja';
     smAdjust: Result:=IfThen(FirstCap, 'R', 'r')+'reguliruemaja';
     end
   end
  else
   begin
    case Mode of
     smMax: Result:=IfThen(FirstCap, 'M', 'm')+'aximal';
     smNormal: Result:=IfThen(FirstCap, 'M', 'm')+'edium';
     smLow: Result:=IfThen(FirstCap, 'M', 'm')+'inimal';
     smAuto: Result:=IfThen(FirstCap, 'A', 'a')+'utomatic';
     smAdjust: Result:=IfThen(FirstCap, 'A', 'a')+'djustable';
     end;
   end;
end;

function DMDefaultDownloadList: String;
 var
  RegIni: TRegIniFile;
  Path: array [0..2048] of char;
begin
 RegIni:=TRegIniFile.Create;
 RegIni.OpenKeyReadOnly(sRegPath);
 Result:=RegIni.ReadString('', sDefaultDownloadList, '');
 if Result='' then
  begin
   if SHGetSpecialFolderPath(0, Path, CSIDL_APPDATA, false) then
     Result:=IncludeTrailingPathDelimiter(String(Path))
             +IncludeTrailingPathDelimiter(sAppPath)
             +IncludeTrailingPathDelimiter(sListsPath)
             +sDownloadsList;
  end;
 RegIni.Free;
end;

function DMUseIEProxy: Boolean;
 var
  RegIni: TRegIniFile;
begin
 RegIni:=TRegIniFile.Create;
 RegIni.OpenKeyReadOnly(sRegPath);
 Result:=RegIni.ReadBool('', sUseIEProxy, false);
 RegIni.Free;
end;

function DMUseHTTPProxy: Boolean;
 var
  RegIni: TRegIniFile;
begin
 RegIni:=TRegIniFile.Create;
 RegIni.OpenKeyReadOnly(sRegPath);
 Result:=RegIni.ReadBool('', sUseHTTPProxy, false);
 RegIni.Free;
end;

function DMUseFTPProxy: Boolean;
 var
  RegIni: TRegIniFile;
begin
 RegIni:=TRegIniFile.Create;
 RegIni.OpenKeyReadOnly(sRegPath);
 Result:=RegIni.ReadBool('', sUseFTPProxy, false);
 RegIni.Free;
end;

function DMNodelist: String;
 var
  Path: array [0..2048] of char;
begin
  if SHGetSpecialFolderPath(0, Path, CSIDL_APPDATA, false) then
    Result:=IncludeTrailingPathDelimiter(String(Path))+IncludeTrailingPathDelimiter(sAppPath)+sNodelist
  else
    Result:='';
end;

function DMHistory: String;
 var
  Path: array [0..2048] of char;
begin
  if SHGetSpecialFolderPath(0, Path, CSIDL_APPDATA, false) then
    Result:=IncludeTrailingPathDelimiter(String(Path))+IncludeTrailingPathDelimiter(sAppPath)+sHistory
  else
    Result:='';
end;

function DMDownloadExtensions: String;
 var
  RegIni: TRegIniFile;
begin
 RegIni:=TRegIniFile.Create;
 RegIni.OpenKeyReadOnly(sRegPath);
 Result:=RegIni.ReadString('', sDownloadExtensions, '');
 RegIni.Free;
end;

function DMDefaultSaveFolder: String;
 var
  RegIni: TRegIniFile;
begin
 RegIni:=TRegIniFile.Create;
 RegIni.OpenKeyReadOnly(sRegPath);
 Result:=RegIni.ReadString('', sDefaultSaveFolder, '');
 RegIni.Free;
end;

end.

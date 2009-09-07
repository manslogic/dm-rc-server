unit DM_RC_Svr_Store;
{$DEFINE DMRCSVR_STORE}

interface

uses
 StringsSettings,
 xIniFile;

const
 //settings
 ssSettings = 'Settings';
 sStore = 'Store';
 sDumpMain = 'DumpMain';
 sDumpUser = 'DumpUser';

 {$IFNDEF DMRCSVR_LOG}
 cTimeNone = 0;
 cTimeExit = 1;
 cTime05 = 2;
 cTime10 = 3;
 cTime60 = 4;
 {$ENDIF}
 cTimeEvery = 5;

 //defaults
 //cDefaultFormat = '#FN #DD #PR## #TM #TL';
 sDefaultFormat = '#ID #FN #DD #PR## #SP #TL'; //by G0rdon
 //cDefaultNotifyAdd = 'ID = #ID';
 sDefaultNotifyAdd = '#ID #FN'; //by G0rdon
 //cDefaultNotifyState = '#ID => #ST';
 sDefaultNotifyState = '#ID #FN => #ST'; //by G0rdon & me

 //per user settings
 sListAsAdmin = 'ListAsAdmin';
 sNotifyDelete = 'NotifyDelete';
 //
 sListDefault = 'ListDefault';
 sFormatA = 'FormatA';
 sFormatP = 'FormatP';
 sFormatD = 'FormatD';
 sFormatE = 'FormatE';
 sFormatQ = 'FormatQ';
 sFormatC = 'FormatC';
 sNotify = 'Notify';
 sNotifyAdd = 'NotifyAdd';
 sNotifyState = 'NotifyState';
 sNotifyStates = 'NotifyStates';
 //sIDNotify = 'IDNotify';
 sNotifyConnect = 'NotifyConnect';
 sMessageLength = 'MessageLength';
 cDefaultUnits = 0;
 sUnits = 'Units';
 sUnitsSpeed = 'UnitsSpeed';
 //
 sNotifyOther = 'NotifyOther';
 sNotifyAddOther = 'NotifyAddOther';
 sNotifyStateOther = 'NotifyStateOther';
 cNOAdd = $01;
 cNOState = $02;

var
 Settings: TStringsSettings = nil;
 IniName: String = '';
 IniKey: String = '';
 IDIniName: String = '';
 IDIniKey: String = '';
 SetMain: TxIniFile = nil;
 SetUser: TxIniFile = nil;

procedure SettingsFree;
procedure xIniFree(var xIni: TxIniFile);
//
function RegistryKeyExists(Key: String): Boolean;
//
function GetUserSetting(UserID, Key: String): String;
procedure SetUserSetting(UserID, Key, Value: String; UpdateNow: Boolean = false);
function GetUserListFormat(UserID: String; Mode: Integer): String;
procedure SetUserListFormat(UserID: String; Mode: Integer; Value: String; UpdateNow: Boolean = false);
//
function GetUnits(UserID: String; Speed: Boolean = false): Integer;

implementation

uses
 Registry,
 SysUtils,
 StrUtils,
 DMSettings,
 DM_RC_Svr_Defines,
 DM_RC_Svr_DLInfo;

{ Common stuff }

procedure SettingsFree;
begin
 if Assigned(Settings) then
   FreeAndNil(Settings);
end;

procedure xIniFree(var xIni: TxIniFile);
begin
 if Assigned(xIni) then
   FreeAndNil(xIni);
end;

function RegistryKeyExists(Key: String): Boolean;
 var
  Registry: TRegistry;
begin
 Registry:=TRegistry.Create;
 Result:=Registry.KeyExists(Key);
 Registry.Free;
end;

function GetUserSetting(UserID, Key: String): String;
begin
 Result:='';
 if Assigned(SetUser) then
  begin
   if SetUser.SectionExists(UserID) then
    begin
     if SetUser.ValueExists(UserID, Key) then
       Result:=SetUser.ReadString(UserID, Key, '');
    end;
  end;
end;

procedure SetUserSetting(UserID, Key, Value: String; UpdateNow: Boolean = false);
begin
 if Assigned(SetUser) then
  begin
   if Value='' then
    begin
     if SetUser.ValueExists(UserID, Key) then
       SetUser.DeleteKey(UserID, Key);
    end
   else
     SetUser.WriteString(UserID, Key, Value);
   if UpdateNow then
     SetUser.UpdateFile;
  end;
 //Changed:=true;
end;

function GetUserListFormat(UserID: String; Mode: Integer): String;
begin
 if Assigned(SetUser) then
  begin
   case Mode of
    dsPause: Result:=SetUser.ReadString(UserID, sFormatP, sDefaultFormat);
    dsDownloaded: Result:=SetUser.ReadString(UserID, sFormatC, sDefaultFormat);
    dsDownloading: Result:=SetUser.ReadString(UserID, sFormatD, sDefaultFormat);
    dsError: Result:=SetUser.ReadString(UserID, sFormatE, sDefaultFormat);
    dsQueue: Result:=SetUser.ReadString(UserID, sFormatQ, sDefaultFormat);
    dsAll: Result:=SetUser.ReadString(UserID, sFormatA, sDefaultFormat);
    else
      Result:='';
    end;
  end
 else
   Result:='';
end;

procedure SetUserListFormat(UserID: String; Mode: Integer; Value: String; UpdateNow: Boolean = false);
 var
  Erase: Boolean;
begin
 if Assigned(SetUser) then
  begin
   Erase:=Value='';
   case Mode of
    dsPause:
     begin
      if Erase then
       begin
        if SetUser.ValueExists(UserID, sFormatP) then
          SetUser.DeleteKey(UserID, sFormatP);
       end
      else
        SetUser.WriteString(UserID, sFormatP, Value);
     end;
    dsDownloaded:
     begin
      if Erase then
       begin
        if SetUser.ValueExists(UserID, sFormatC) then
          SetUser.DeleteKey(UserID, sFormatC);
       end
      else
        SetUser.WriteString(UserID, sFormatC, Value);
     end;
    dsDownloading:
     begin
      if Erase then
       begin
        if SetUser.ValueExists(UserID, sFormatD) then
          SetUser.DeleteKey(UserID, sFormatD);
       end
      else
        SetUser.WriteString(UserID, sFormatD, Value);
     end;
    dsError:
     begin
      if Erase then
       begin
        if SetUser.ValueExists(UserID, sFormatE) then
          SetUser.DeleteKey(UserID, sFormatE);
       end
      else
        SetUser.WriteString(UserID, sFormatE, Value);
     end;
    dsQueue:
     begin
      if Erase then
       begin
        if SetUser.ValueExists(UserID, sFormatQ) then
          SetUser.DeleteKey(UserID, sFormatQ);
       end
      else
        SetUser.WriteString(UserID, sFormatQ, Value);
     end;
    dsAll:
     begin
      if Erase then
       begin
        if SetUser.ValueExists(UserID, sFormatA) then
          SetUser.DeleteKey(UserID, sFormatA);
       end
      else
        SetUser.WriteString(UserID, sFormatA, Value);
     end;
    end;
   if UpdateNow then
     SetUser.UpdateFile;
  end;
 //Changed:=true;
end;

function GetUnits(UserID: String; Speed: Boolean = false): Integer;
begin
 if Assigned(SetUser) then
  begin
   Result:=StrToIntDef(SetUser.ReadString(UserID, IfThen(Speed, sUnitsSpeed, sUnits), ''), -1);
   if Result<0 then
     Result:=cDefaultUnits
   else
    begin
     if Result>High(SizeUnits) then
       Result:=0;
    end;
  end
 else
   Result:=0;
end;

end.
 
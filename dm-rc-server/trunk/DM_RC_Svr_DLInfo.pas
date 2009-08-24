unit DM_RC_Svr_DLInfo;

interface

uses
 Windows,
 Classes,
 DMPluginIntf;

const
 //additional DLInfo modes
 dsAll = 9;

var
 //DLInfo is downloads info in form of <id>=<xmldata>
 DLInfo: TStrings = nil;
 CS_DLInfo: TRTLCriticalSection;

procedure DLInfoCreate;
procedure DLInfoFree;

procedure UpdateDLInfo(const DMI: IDmInterface; Mode: Integer = 3); overload;
procedure UpdateDLInfo(const XMLName: String); overload;

implementation

uses
 SysUtils,
 DMXMLParsers,
 Wizard;

{ Common stuff }

procedure DLInfoCreate;
begin
 DLInfoFree;
 InitializeCriticalSection(CS_DLInfo);
 DLInfo:=TStringList.Create;
end;

procedure DLInfoFree;
begin
 if Assigned(DLInfo) then
   FreeAndNil(DLInfo);
 DeleteCriticalSection(CS_DLInfo);
end;

procedure UpdateDLInfo(const DMI: IDmInterface; Mode: Integer = 3);
 var
  i: Integer;
  s, ID, IDI: String;
begin
 if Assigned(DMI) then
  begin
   if TryEnterCriticalSection(CS_DLInfo) then
    begin
     if Mode=dsAll then
       s:=DMI.DoAction('GetDownloadIDsList', '')
     else
       s:=DMI.DoAction('GetDownloadIDsList', IntToStr(Mode));
     if s<>'' then
      begin
       DLInfo.Clear;
       for i:=1 to WordCount(s, [' ']) do
        begin
         ID:=ExtractWord(i, s, [' ']);
         if ID<>'' then
          begin
           IDI:=DMI.DoAction('GetDownloadInfoByID', ID);
           DLInfo.Add(ID+'='+IDI);
          end;
        end;
      end;
     LeaveCriticalSection(CS_DLInfo);
    end;
  end;
end;

procedure UpdateDLInfo(const XMLName: String);
begin
 if TryEnterCriticalSection(CS_DLInfo) then
  begin
   ParseXML(XMLName, DLInfo);
   LeaveCriticalSection(CS_DLInfo);
  end;
end;


end.
 
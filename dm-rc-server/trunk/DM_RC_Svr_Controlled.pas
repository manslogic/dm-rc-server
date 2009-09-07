unit DM_RC_Svr_Controlled;

interface

uses
 Windows,
 Classes,
 StringsSettings;

const
 cDLMax = 10000;
 ssDownloads = 'Downloads';

var
 CS_Ctrld: TRTLCriticalSection;

procedure CtrldCreate;
procedure CtrldFree;
//
function AddCtrldURL(UserID, URL: String; List: TStrings = nil): Integer;
function AddCtrldID(UserID, ID: String; List: TStrings = nil): Integer;
function CtrldURLIndex(URL: String; List: TStrings = nil): Integer;
function CtrldIDIndex(ID: String; List: TStrings = nil): Integer;
procedure RplCtrldURLbyID(URL, ID: String; List: TStrings = nil);
procedure DelCtrld(ID: String; List: TStrings = nil); overload;
procedure DelCtrld(Index: Integer; List: TStrings = nil); overload;
//
procedure CtrldFromSettings(ASettings: TStringsSettings; List: TStrings = nil);
procedure CtrldToSettings(ASettings: TStringsSettings; List: TStrings = nil);

implementation

uses
 SysUtils,
 HTTPApp,
 DM_RC_Svr_Tokens,
 Tokens;

const
 tknUserID = 'userid';
 tknDEL = 'deleted';

var
 Ctrld: TStrings = nil;

procedure CtrldCreate;
begin
 CtrldFree;
 InitializeCriticalSection(CS_Ctrld);
 Ctrld:=TStringList.Create;
end;

procedure CtrldFree;
begin
 if Assigned(Ctrld) then
   FreeAndNil(Ctrld);
 DeleteCriticalSection(CS_Ctrld);
end;

function AddCtrldURL(UserID, URL: String; List: TStrings = nil): Integer;
 var
  s: String;
begin
 if not Assigned(List) then
   List:=Ctrld;
 //
 if Assigned(List)then
  begin
   s:=HTTPEncode(URL);
   Result:=List.IndexOfName(s);
   if Result<0 then
    begin
     if List=Ctrld then
       EnterCriticalSection(CS_Ctrld);
     Result:=List.Add(s+'='+EncodeToken(tknUserID, UserID));
     if List=Ctrld then
       LeaveCriticalSection(CS_Ctrld);
    end;
  end
 else
   Result:=-1;
end;

function AddCtrldID(UserID, ID: String; List: TStrings = nil): Integer;
begin
 if not Assigned(List) then
   List:=Ctrld;
 //
 if Assigned(List)then
  begin
   Result:=List.IndexOfName(ID);
   if Result<0 then
    begin
     if List=Ctrld then
       EnterCriticalSection(CS_Ctrld);
     Result:=List.Add(ID+'='+EncodeToken(tknUserID, UserID));
     if List=Ctrld then
       LeaveCriticalSection(CS_Ctrld);
    end;
  end
 else
   Result:=-1;
end;

function CtrldURLIndex(URL: String; List: TStrings = nil): Integer;
 var
  s: String;
begin
 if not Assigned(List) then
   List:=Ctrld;
 //
 if Assigned(List)then
  begin
   s:=HTTPEncode(URL);
   Result:=List.IndexOfName(s);
  end
 else
   Result:=-1;
end;

function CtrldIDIndex(ID: String; List: TStrings = nil): Integer;
begin
 if not Assigned(List) then
   List:=Ctrld;
 //
 if Assigned(List)then
   Result:=List.IndexOfName(ID)
 else
   Result:=-1;
end;

procedure RplCtrldURLbyID(URL, ID: String; List: TStrings = nil);
 var
  i: Integer;
begin
 if not Assigned(List) then
   List:=Ctrld;
 //
 if Assigned(List)then
  begin
   i:=CtrldURLIndex(URL, List);
   if i>=0 then
    begin
     if List=Ctrld then
       EnterCriticalSection(CS_Ctrld);
     List[i]:=ID+'='+List.ValueFromIndex[i];
     if List=Ctrld then
       LeaveCriticalSection(CS_Ctrld);
    end;
  end;
end;

procedure DelCtrld(ID: String; List: TStrings = nil);
 var
  i: Integer;
begin
 if not Assigned(List) then
   List:=Ctrld;
 //
 if Assigned(List) then
  begin
   i:=CtrldIDIndex(ID, List);
   if i>=0 then
    begin
     if List=Ctrld then
       EnterCriticalSection(CS_Ctrld);
     List.Delete(i);
     if List=Ctrld then
       LeaveCriticalSection(CS_Ctrld);
    end;
  end;
end;

procedure DelCtrld(Index: Integer; List: TStrings = nil);
begin
 if not Assigned(List) then
   List:=Ctrld;
 //
 if Assigned(List) then
  begin
   if (Index>=0) and (Index<List.Count) then
    begin
     if List=Ctrld then
       EnterCriticalSection(CS_Ctrld);
     List.Delete(Index);
     if List=Ctrld then
       LeaveCriticalSection(CS_Ctrld);
    end;
  end;
end;

procedure CtrldFromSettings(ASettings: TStringsSettings; List: TStrings = nil);
 var
  i: Integer;
  s: String;
begin
 if not Assigned(List) then
   List:=Ctrld;
 //
 if Assigned(List) and Assigned(ASettings) then
  begin
   List.Clear;
   for i:=0 to ASettings[ssDownloads]-1 do
    begin
     s:=ASettings.Group[ssDownloads, i];
     AddCtrldID(ExtractToken(tknUserID, s), ExtractToken(tknID, s), List);
    end;
  end;
end;

procedure CtrldToSettings(ASettings: TStringsSettings; List: TStrings = nil);
 var
  i: Integer;
begin
 if not Assigned(List) then
   List:=Ctrld;
 //
 if Assigned(List) and Assigned(ASettings) then
  begin
   ASettings[ssDownloads]:=List.Count;
   for i:=0 to List.Count-1 do
    begin
     if not StrToBoolDef(ExtractToken(tknDEL, List.ValueFromIndex[i]), false) then
       ASettings.Group[ssDownloads, i]:=EncodeToken(tknID, List.Names[i])+EncodeToken(tknUserID, List.ValueFromIndex[i]);
    end;
  end;
end;

end.

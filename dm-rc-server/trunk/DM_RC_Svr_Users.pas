unit DM_RC_Svr_Users;

interface

uses
 Windows,
 Classes,
 StringsSettings;

const
 cUsersMax = 1000;

 //user types
 utSupervisor = 0;
 utAdmin = 1;
 utUser = 2;
 utNoBody = 3;
 utNotFound = utNoBody+1;

 MaxDumbTries = 5;
 DumbCountStart = 1000;

 //proto
 prWeb = 'Web';

 //settings ident
 ssUsers = 'Users';
 sIDAsFolder = 'IDAsFolder';
 sIDAFStrict = 'IDAFStrict';

var
 //user storage
 Users: TStrings = nil;
 CS_Users: TRTLCriticalSection;

procedure UsersCreate;
procedure UsersFree;

 {
 User operating routines
 List: any external user list to operate instead of internal storage defined above.
 }
 {
 Adds user to storage.
 AUser: ID of user (ICQ UIN, JID etc)
 AType: one of imrcu_* except utNotFound
 Update: set to true if u want to update existing user type
 Returns index of user in storage.
 }
function AddUser(AUser: String; AType: Integer; Update: Boolean = false; List: TStrings = nil): Integer;
 {
 Get user index in storage.
 AUser: ID of user (ICQ UIN, JID etc)
 Returns index of user in storage or -1 if no user found.
 }
function UserIndex(AUser: String; List: TStrings = nil): Integer;
 {
 Checks user type.
 AUser: ID of user (ICQ UIN, JID etc)
 AIndex: index in storage
 Returns type as one of imrcu_* or utNotFound if user not exists
 }
function GetUserType(AUser: String; List: TStrings = nil): Integer; overload;
function GetUserType(AIndex: Integer; List: TStrings = nil): Integer; overload;
procedure SetUserType(AUser: String; AType: Integer; List: TStrings = nil); overload;
procedure SetUserType(AIndex: Integer; AType: Integer; List: TStrings = nil); overload;
//
function GetDumbCount(AUser: String; List: TStrings = nil): Integer; overload;
function GetDumbCount(AIndex: Integer; List: TStrings = nil): Integer; overload;
procedure SetDumbCount(AUser: String; Count: Integer = 0; List: TStrings = nil); overload;
procedure SetDumbCount(AIndex: Integer; Count: Integer = 0; List: TStrings = nil); overload;
 {
 Deletes user from storage.
 AUser: ID of user (ICQ UIN, JID etc)
 }
procedure DeleteUser(AUser: String; List: TStrings = nil);
 {
 Clears all users with type greater than utUser from storage.
 }
procedure ClearInvalidUsers(List: TStrings = nil);
procedure GetSuperList(AList: TStrings; List: TStrings = nil);
//
procedure SetUsersImageIndexes(iiSupervisor, iiAdmin, iiUser: Integer);
//procedure UsersToILB(ILB: TJvImageListBox; List: TStrings = nil);
//
procedure UsersFromSettings(ASettings: TStringsSettings; List: TStrings = nil);
procedure UsersToSettings(ASettings: TStringsSettings; List: TStrings = nil);

implementation

uses
 SysUtils,
 DM_RC_Svr_Tokens,
 Tokens;

var
 ii_Supervisor: Integer;
 ii_Admin: Integer;
 ii_User: Integer;

procedure UsersCreate;
begin
 UsersFree;
 InitializeCriticalSection(CS_Users);
 Users:=TStringList.Create;
end;

procedure UsersFree;
begin
 if Assigned(Users) then
   FreeAndNil(Users);
 DeleteCriticalSection(CS_Users);
end;

{
Users are stored as
<ID>=<type><proto>
In the Settings they are stored in XML string list
UserX=<id>ID</id><type>Type</type>
}
function AddUser(AUser: String; AType: Integer; Update: Boolean = false; List: TStrings = nil): Integer;
 var
  NewType: Integer;
begin
 if not Assigned(List) then
   List:=Users;
 //
 if Assigned(List) then
  begin
   if List.Count<cUsersMax then
     Result:=0
   else
     Result:=-1;
   if AUser='' then
     Result:=-1;
  end
 else
   Result:=-1;
 if Result=0 then
  begin
   NewType:=AType;
   //
   if NewType<utSupervisor then
     NewType:=utSupervisor;
   //
   Result:=List.IndexOfName(AUser);
   if Result<0 then
     Result:=List.Add(AUser+'='+IntToStr(NewType))
   else
    begin
     if Update then
       List.ValueFromIndex[Result]:=IntToStr(NewType);
    end;
  end;
end;

function UserIndex(AUser: String; List: TStrings = nil): Integer;
begin
 if not Assigned(List) then
   List:=Users;
 //
 if Assigned(List) then
   Result:=List.IndexOfName(AUser)
 else
   Result:=-1;
end;

function GetUserType(AUser: String; List: TStrings = nil): Integer;
 var
  i: Integer;
begin
 if not Assigned(List) then
   List:=Users;
 //
 if Assigned(List) then
  begin
   i:=List.IndexOfName(AUser);
   if i<0 then
     Result:=utNotFound
   else
     Result:=StrToIntDef(List.ValueFromIndex[i], utNoBody) mod DumbCountStart;
  end
 else
   Result:=-1;
end;

function GetUserType(AIndex: Integer; List: TStrings = nil): Integer;
begin
 if not Assigned(List) then
   List:=Users;
 //
 if Assigned(List) then
  begin
   if (AIndex>=0) and (AIndex<List.Count) then
     Result:=StrToIntDef(List.ValueFromIndex[AIndex], utNoBody) mod DumbCountStart
   else
     Result:=utNotFound;
  end
 else
   Result:=-1;
end;

procedure SetUserType(AUser: String; AType: Integer; List: TStrings = nil); overload;
 var
  NewType: Integer;
  i, t: Integer;
begin
 if not Assigned(List) then
   List:=Users;
 //
 if Assigned(List) then
  begin
   NewType:=AType;
   //
   if NewType<utSupervisor then
     NewType:=utSupervisor;
   //
   i:=List.IndexOfName(AUser);
   if i>=0 then
    begin
     t:=GetDumbCount(i, List);
     List.ValueFromIndex[i]:=IntToStr(NewType + t*DumbCountStart);
    end;
  end;
end;

procedure SetUserType(AIndex: Integer; AType: Integer; List: TStrings = nil); overload;
 var
  NewType, t: Integer;
begin
 if not Assigned(List) then
   List:=Users;
 //
 if Assigned(List) then
  begin
   if (AIndex>=0) and (AIndex<List.Count) then
    begin
     NewType:=AType;
     //
     if NewType<utSupervisor then
       NewType:=utSupervisor;
     //
     t:=GetDumbCount(AIndex, List);
     List.ValueFromIndex[AIndex]:=IntToStr(NewType + t*DumbCountStart);
    end;
  end;
end;

function GetDumbCount(AUser: String; List: TStrings = nil): Integer; overload;
 var
  i: Integer;
begin
 if not Assigned(List) then
   List:=Users;
 //
 if Assigned(List) then
  begin
   i:=List.IndexOfName(AUser);
   if i<0 then
     Result:=0
   else
     Result:=StrToIntDef(List.ValueFromIndex[i], 0) div DumbCountStart;
  end
 else
   Result:=0;
end;

function GetDumbCount(AIndex: Integer; List: TStrings = nil): Integer; overload;
begin
 if not Assigned(List) then
   List:=Users;
 //
 if Assigned(List) then
  begin
   if (AIndex>=0) and (AIndex<List.Count) then
     Result:=StrToIntDef(List.ValueFromIndex[AIndex], 0) div DumbCountStart
   else
     Result:=0;
  end
 else
   Result:=0;
end;

procedure SetDumbCount(AUser: String; Count: Integer = 0; List: TStrings = nil); overload;
 var
  i, Typ: Integer;
begin
 if not Assigned(List) then
   List:=Users;
 //
 if Assigned(List) then
  begin
   i:=List.IndexOfName(AUser);
   if i>=0 then
    begin
     Typ:=GetUserType(i, List);
     List.ValueFromIndex[i]:=IntToStr(Typ+Count*DumbCountStart);
    end;
  end;
end;

procedure SetDumbCount(AIndex: Integer; Count: Integer = 0; List: TStrings = nil); overload;
 var
  Typ: Integer;
begin
 if not Assigned(List) then
   List:=Users;
 //
 if Assigned(List) then
  begin
   if (AIndex>=0) and (AIndex<List.Count) then
    begin
     Typ:=GetUserType(AIndex, List);
     List.ValueFromIndex[AIndex]:=IntToStr(Typ+Count*DumbCountStart);
    end;
  end;
end;

procedure DeleteUser(AUser: String; List: TStrings = nil);
 var
  i: Integer;
begin
 if not Assigned(List) then
   List:=Users;
 //
 if Assigned(List) then
  begin
   i:=List.IndexOfName(AUser);
   if i>=0 then
     List.Delete(i);
  end;
end;

procedure ClearInvalidUsers(List: TStrings = nil);
 var
  i: Integer;
begin
 if not Assigned(List) then
   List:=Users;
 //
 i:=0;
 if Assigned(List) then
  begin
   while i<List.Count do
    begin
     if GetUserType(i, List)>utUser then
       List.Delete(i)
     else
       Inc(i);
    end;
  end;
end;

procedure GetSuperList(AList: TStrings; List: TStrings = nil);
 var
  i: Integer;
begin
 if not Assigned(List) then
   List:=Users;
 //
 AList.Clear;
 if Assigned(List) then
  begin
   for i:=0 to List.Count-1 do
    begin
     if GetUserType(i, List)=utSupervisor then
       AList.Add(List.Names[i]);
    end;
  end;
end;

procedure SetUsersImageIndexes(iiSupervisor, iiAdmin, iiUser: Integer);
begin
 ii_Supervisor:=iiSupervisor;
 ii_Admin:=iiAdmin;
 ii_User:=iiUser;
end;

{
procedure UsersToILB(ILB: TJvImageListBox; List: TStrings = nil);
 var
  ii: TJvImageItem;
  i, t: Integer;
begin
 if not Assigned(List) then
   List:=Users;
 //
 ILB.Items.Clear;
 if Assigned(List) then
  begin
   for i:=0 to List.Count-1 do
    begin
     t:=StrToIntDef(List.ValueFromIndex[i], utNoBody) mod DumbCountStart;
     if t<utNoBody then
      begin
       ii:=ILB.Items.Add;
       ii.Text:=List.Names[i];
       case t of
        utSupervisor: ii.ImageIndex:=ii_Supervisor;
        utAdmin: ii.ImageIndex:=ii_Admin;
        utUser: ii.ImageIndex:=ii_User;
        end;
      end;
    end;
  end;
end;
}
procedure UsersFromSettings(ASettings: TStringsSettings; List: TStrings = nil);
 var
  i: Integer;
  s, ID, Typ: String;
begin
 if not Assigned(List) then
   List:=Users;
 //
 if Assigned(List) and Assigned(ASettings) then
  begin
   List.Clear;
   for i:=0 to ASettings[ssUsers]-1 do
    begin
     s:=ASettings.Group[ssUsers, i];
     ID:=ExtractToken(tknID, s);
     Typ:=ExtractToken(tknType, s);
     AddUser(ID, StrToIntDef(Typ, utNoBody), false, List);
    end;
  end;
end;

procedure UsersToSettings(ASettings: TStringsSettings; List: TStrings = nil);
 var
  i: Integer;
begin
 if not Assigned(List) then
   List:=Users;
 //
 if Assigned(List) and Assigned(ASettings) then
  begin
   ClearInvalidUsers(List);
   ASettings[ssUsers]:=List.Count;
   for i:=0 to List.Count-1 do
    begin
     ASettings.Group[ssUsers, i]:=EncodeToken(tknID, List.Names[i])+EncodeToken(tknType, List.ValueFromIndex[i]);
    end;
  end;
end;

end.
 
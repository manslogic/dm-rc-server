unit DM_RC_Svr_Uresr;

interface

uses
 Classes,
 StringsSettings;

const
 cUsersMax = 1000;

 //user types
 imrcu_Supervisor = 0;
 imrcu_Admin = 1;
 imrcu_User = 2;
 imrcu_NoBody = 3;
 imrcu_NotFound = imrcu_NoBody+1;

 //data tokens
 tknID   = 'id';
 {$IFNDEF IMRC_PROXIES}
 tknType = 'type';
 {$ENDIF}

 MaxDumbTries = 5;
 imrcu_DumbCountStart = 1000;

 //mutex name for multithreading
 IMRC_Users_MutexName = 'IMRemoteControlUsers';

 //settings ident
 ssUsers = 'Users';
 sIDAsFolder = 'IDAsFolder';
 sIDAFStrict = 'IDAFStrict';

var
 //user storage
 IMRC_Users: TStrings;
 Mutex_Users: THandle = 0;

 {
 User operating routines
 List: any external user list to operate instead of internal storage defined above.
 }
 {
 Adds user to storage.
 AUser: ID of user (ICQ UIN, JID etc)
 AType: one of imrcu_* except imrcu_NotFound
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
 Returns type as one of imrcu_* or imrcu_NotFound if user not exists
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
 Clears all users with type greater than imrcu_User from storage.
 }
procedure ClearInvalidUsers(List: TStrings = nil);
procedure GetSuperList(AList: TStrings; List: TStrings = nil);
//
procedure SetUsersImageIndexes(iiSupervisor, iiAdmin, iiUser: Integer);
procedure UsersToILB(ILB: TJvImageListBox; List: TStrings = nil);
//
procedure UsersFromSettings(ASettings: TStringsSettings; List: TStrings = nil);
procedure UsersToSettings(ASettings: TStringsSettings; List: TStrings = nil);

implementation

end.
 
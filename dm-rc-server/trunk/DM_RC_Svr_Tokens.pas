unit DM_RC_Svr_Tokens;

interface

const
 cmdSendBanner = 'SendBanner';
 tknBanner = 'Welcome to Download Master Remote Control Server';

 //data tokens
 tknID   = 'id';
 tknType = 'type';
 tknProto = 'proto';
 tknCmd = 'cmd';

function CommandOwner(Data: String): String;

implementation

uses
 Tokens;

function CommandOwner(Data: String): String;
begin
 Result:='';
 if TokenExist(tknID, Data) then
   Result:=Result+CopyToken(tknID, Data);
 if TokenExist(tknProto, Data) then
   Result:=Result+CopyToken(tknProto, Data);
end;

end.
 
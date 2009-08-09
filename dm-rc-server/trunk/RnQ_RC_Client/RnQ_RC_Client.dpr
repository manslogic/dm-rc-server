library RnQ_RC_Client;

uses
  forms,
  sysutils,
  types,
  ExtCtrls,
  Classes,
  windows,
  IniFiles,
  OverbyteIcsWSocket,
  OverbyteIcsWSocketS,
  OverbyteIcsWndControl,
  CallExec in 'CallExec.pas',
  plugin in 'plugin.pas',
  pluginutil in 'pluginutil.pas',
  RqUtils in 'RqUtils.pas';

const
 namepl='Download Master Remote Control RnQ Client 0.1';
 IniFileName: string = 'DM_RC_Client.ini';

type
  TMyWSocketClient = class(TWSocketClient)
  private
    procedure DataAvailable(Sender: TObject; ErrCode: Word);
  public
    constructor Create(aOwner: TComponent);reintroduce;
  end;

var
 path, userPath:string;
 curUIN:integer;
 uin, flags, APIver:integer;
 dt:TDateTime;
 msg:string;
 //--------------------------
 WSocketClient: TMyWSocketClient;
 Ini: TMemIniFile;
 OwnerUIN:integer;

// #############################################################################

constructor TMyWSocketClient.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  OnDataAvailable := DataAvailable;
end;
//------------------------------------------------------------------------------
procedure TMyWSocketClient.DataAvailable(Sender: TObject; ErrCode: Word);
begin
  //как только получили данные от DM пересылаем их хозяину
  RQ_SendMsg(OwnerUIN, 0, (Sender as TWSocket).ReceiveStr);
end;

// #############################################################################

function pluginFun(data:pointer):pointer; stdcall;
begin
result:=NIL;
if (data=NIL) or (_int_at(data)=0) then exit;
case _byte_at(data,4) of
  PM_EVENT:
    case _byte_at(data,5) of
      PE_INITIALIZE:
        begin
         // Parsing incoming string
         RQ__ParseInitString(data, callback, APIver, path, userPath, curUIN);

         Ini                 := TMemIniFile.Create(userPath + IniFileName);

         OwnerUIN            := Ini.ReadInteger('Owner', 'OwnerUIN', 0);

         WSocketClient       := TMyWSocketClient.Create(nil);
         WSocketClient.Proto := 'tcp';         { Use TCP protocol  }

         // Reply with plugin name
         result := str2comm(char(PM_DATA)+_istring(namepl)+_int(APIversion));
        end;
      PE_MSG_GOT:
        begin
         // Parsing incoming string
         RQ__ParseMsgGotString(data, uin, flags, dt, msg);

         try
          //получили данные от хозяина - пересылаем их DM
           if uin = OwnerUIN then
           begin
              if (CompareText(msg, 'dmlogin') = 0) and (WSocketClient.State <> wsConnected) then
              begin
                WSocketClient.Port := Ini.ReadString('Connect', 'Port', '10000');
                WSocketClient.Addr := Ini.ReadString('Connect', 'Addr', '127.0.0.1');
                WSocketClient.Connect;
              end else if (CompareText(msg, 'dmlogout') = 0) and (WSocketClient.State = wsConnected) then
                WSocketClient.Close
              else if WSocketClient.State = wsConnected then
                WSocketClient.SendStr(msg + #13#10);

              result:=str2comm(char(PM_ABORT));
           end;
         except
          on E: Exception do RQ_SendMsg(OwnerUIN, 0, E.Message);
         end;
        end;
      PE_MSG_SENT:
        begin
         // Parsing outgoing string
        end;
      PE_PREFERENCES:
        begin
         // Show Preference Windows here
        end;
      PE_FINALIZE:
        begin
         // Free your object here ;-)
         FreeAndNil(Ini);
         FreeAndNil(WSocketClient);
        end;
      end;//case
  end;//case
end; // pluginFun

exports
  pluginFun;

end.

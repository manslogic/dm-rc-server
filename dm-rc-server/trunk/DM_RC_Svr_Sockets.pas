unit DM_RC_Svr_Sockets;

interface

uses
 OverbyteIcsWSocket, OverbyteIcsWSocketS;

var
 WSocketServer: TWSocketServer = nil;

procedure SocketServerStart(evtOnClientConnect: TWSocketClientConnectEvent);
procedure SocketServerFree;

implementation

uses
 SysUtils,
 DM_RC_Svr_Defines,
 DM_RC_Svr_Settings;

 {Common stuff}

procedure SocketServerStart(evtOnClientConnect: TWSocketClientConnectEvent);
begin
 if Assigned(WSocketServer) then
  begin
   WSocketServer.Close;
  end
 else
   WSocketServer := TWSocketServer.Create(nil);
 WSocketServer.OnClientConnect := evtOnClientConnect;
 WSocketServer.Banner          := 'Welcome to Download Master Remote Control Server';
 WSocketServer.Proto           := 'tcp';         { Use TCP protocol  }
 //WSocketServer.Port            := Ini.ReadString('Connect', 'Port', '10000');
 WSocketServer.Port            := Settings[sPort];
 //WSocketServer.Addr            := Ini.ReadString('Connect', 'Addr', '127.0.0.1');
 case Settings[sConnection] of
  iConnRemote:
   begin
    if Settings[sIPList]>0 then
      WSocketServer.Addr:=Settings.Group[sIPList, 0];
   end;
  else
    WSocketServer.Addr:='127.0.0.1';
  end;
 WSocketServer.ClientClass     := TWSocketClient;{ Use our component }
 WSocketServer.Listen;                           { Start litening    }
end;

procedure SocketServerFree;
begin
 if Assigned(WSocketServer) then
   FreeAndNil(WSocketServer);
end;

end.

type
  TMyWSocketClient = class(TWSocketClient)
  private
    FBuffer: String;
    FDataReady: Boolean;
    procedure DataAvailable(Sender: TObject; ErrCode: Word);
  public
    constructor Create; reintroduce;
  end;

var
  WSClient: TMyWSocketClient = nil;

{ TMyWSocketClient }

constructor TMyWSocketClient.Create;
begin
  inherited Create(nil);
  OnDataAvailable := DataAvailable;
  FBuffer:='';
  FDataReady:=false;
end;

procedure TMyWSocketClient.DataAvailable(Sender: TObject; ErrCode: Word);
 var
  Rcv, Data, Txt, Line, opt: String;
  i: Integer;
  hContact: THandle;
  ci: TCONTACTINFO;
begin
  //Data:=(Sender as TWSocket).ReceiveStr;
  Rcv:=(Sender as TWSocket).ReceiveStr;
  //prebuffering
  if TokenExist(tknCmd, Rcv) then
   begin
    //whole command in line
    FBuffer:=Rcv;
    FDataReady:=true;
   end
  else
   begin
    FDataReady:=false;
    if TagExist(tknCmd, Rcv) then
     begin
      //opening tag exists
      if FBuffer='' then
        FBuffer:=Rcv
      else
       begin
        if TagExist(tknCmd, FBuffer) then
         begin
          //data lost
          FBuffer:=Rcv;
         end;
        if TagExist(tknCmd, FBuffer, true) then
         begin
          FBuffer:=Rcv+FBuffer;
          FDataReady:=true;
         end;
       end;
     end
    else
     begin
      if TagExist(tknCmd, Rcv, true) then
       begin
        if FBuffer='' then
          FBuffer:=Rcv
        else
         begin
          if TagExist(tknCmd, FBuffer) then
           begin
            FBuffer:=FBuffer+Rcv;
            FDataReady:=true;
           end
          else
           begin
            //data lost
            FBuffer:=Rcv;
           end;
         end;
       end
      else
       begin
        //clean data
        FBuffer:=Rcv;
        FDataReady:=true;
       end;
     end;
   end;
  if FDataReady then
   begin
    Data:=FBuffer;
    FDataReady:=false;
    FBuffer:='';
   end;
  MessageBox(0, PChar(Data), 'Answer', MB_OK or MB_ICONINFORMATION);
  if TokenExist(tknCmd, Data) then
   begin
    Txt:=ExtractToken(tknCmd, Data);
    FillChar(ci, SizeOf(TCONTACTINFO), #0);
    ci.cbSize:=SizeOf(TCONTACTINFO);
    opt:=ExtractToken(tknProto, Data);
    MessageBox(0, PChar(opt), 'User Proto', MB_OK or MB_ICONINFORMATION);
    ci.szProto:=PChar(opt);
    ci.dwFlag:=CNF_UNIQUEID;
    opt:=ExtractToken(tknID, Data);
    MessageBox(0, PChar(opt), 'User ID', MB_OK or MB_ICONINFORMATION);
    ci.retval.szVal:=TChar(opt);
    PluginLink^.CallService(MS_CONTACT_GETCONTACTINFO, 0, DWORD(@ci));
    MessageBox(0, PChar(IntToStr(ci.hContact)), 'User Handle', MB_OK or MB_ICONINFORMATION);
   end
  else
    Txt:=Data;
  {
  for i:=1 to WordCount(Txt, CRLFZSet) do
   begin
    //process received answers
    Line:=ExtractWord(i, Txt, CRLFZSet);
    MessageBox(0, PChar(Line), 'Message', MB_OK or MB_ICONINFORMATION);
   end;
  }
end;

procedure ClientFree;
begin
 if Assigned(WSClient) then
  begin
   WSClient.Close;
   FreeAndNil(WSClient);
  end;
end;

procedure ClientInit;
begin
 ClientFree;
 WSClient:= TMyWSocketClient.Create;
 WSClient.Port := IntToStr(DBGetContactSettingDword(0, piShortName, optPort, PortDefault));
 WSClient.Addr := '127.0.0.1';
 WSClient.Connect;
end;

procedure ClientSend(Text: String);
begin
 if not Assigned(WSClient) then
   ClientInit;
 if WSClient.State <> wsConnected then
   WSClient.Connect;
 if WSClient.State = wsConnected then
   WSClient.SendStr(Text + #13#10);
end;

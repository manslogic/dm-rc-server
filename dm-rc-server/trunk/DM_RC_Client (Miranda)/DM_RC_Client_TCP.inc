type
  TMyWSocketClient = class(TWSocketClient)
  private
    FBuffer: String;
    FDataReady: Boolean;
    procedure DataAvailable(Sender: TObject; ErrCode: Word);
  public
    constructor Create; reintroduce;
  end;

const
 TxtPrefix = 'DM RC Answer:'#0;
 TxtLength = 3000;

var
  WSClient: TMyWSocketClient = nil;

function IsContactProto(hContact: THandle; const szProto: PAnsiChar): int;
begin
 Result := PluginLink^.CallService(MS_PROTO_ISPROTOONCONTACT, wParam(hContact), lParam(szProto));
end;

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
  Rcv, Data, Line, uID, cID, Proto: String;
  Txt: WideString;
  //TxtChar: array [0..TxtLength-1] of Char;
  i, wc: Integer;
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
        if FBuffer='' then
         begin
          FBuffer:=Rcv;
          FDataReady:=true;
         end
        else
          FBuffer:=FBuffer+Rcv;
       end;
     end;
   end;
  if FDataReady then
   begin
    Data:=FBuffer;
    FDataReady:=false;
    FBuffer:='';
   end;
  //MessageBox(0, PChar(Data), 'Answer', MB_OK or MB_ICONINFORMATION);
  if TokenExist(tknCmd, Data) then
   begin
    Txt:=TxtPrefix+ExtractToken(tknCmd, Data);
    Proto:=ExtractToken(tknProto, Data);
    uID:=ExtractToken(tknID, Data);
   end
  else
   begin
    Txt:=Data;
    if TokenExist(tknID, Txt) then
     begin
      uID:=ExtractToken(tknID, Txt);
      DeleteToken(tknID, Txt);
     end
    else
      uID:='';
    if TokenExist(tknProto, Txt) then
     begin
      Proto:=ExtractToken(tknProto, Txt);
      DeleteToken(tknProto, Txt);
     end
    else
      Proto:='';
   end;
  //MessageBox(0, PChar(uID+#13+Proto), 'User Data', MB_OK or MB_ICONINFORMATION);
  if (uID<>'') and (Proto<>'') then
   begin
    hContact := pluginLink^.CallService(MS_DB_CONTACT_FINDFIRST, 0, 0);
    while hContact <> 0 do
     begin
      if IsContactProto(hContact, PChar(Proto)) = -1 Then
       begin
        cID:=GetContactUID(hContact, PChar(Proto));
        //MessageBox(0, PChar(uID+#13+cID), 'Compare ID', MB_OK or MB_ICONQUESTION);
        if SameText(uID, cID) then
         begin
          //send message
          //MessageBox(0, PChar('Right ID '+cID+' !'), 'Compare ID', MB_OK or MB_ICONINFORMATION);
          {
          FillChar(TxtChar, TxtLength, #0);
          StrPCopy(TxtChar, Txt);
          CallContactService(hContact, PSS_MESSAGE, PREF_CREATEREAD, DWORD(@TxtChar));
          }
          {
          for i:=1 to WordCount(Txt, CRLFZSet) do
           begin
            //process received answers
            Line:=ExtractWord(i, Txt, CRLFZSet);
            CallContactService(hContact, PSS_MESSAGE, 0, DWORD(@Line[1]));
            Sleep(10);
           end;
           }
          Line:='';
          i:=1;
          wc:=WordCount(Txt, CRLFZSet);
          repeat
           if Length(Line)<TxtLength then
            begin
             if Line='' then
               Line:=ExtractWord(i, Txt, CRLFZSet)
             else
               Line:=Line+CRLF+ExtractWord(i, Txt, CRLFZSet);
            end
           else
            begin
             //ReplaceEx(Line, #0, CRLF);
             CallContactService(hContact, PSS_MESSAGE, 0, DWORD(@Line[1]));
             Line:=ExtractWord(i, Txt, CRLFZSet);
            end;
           Inc(i);
          until i>wc;
          if Line<>'' then
            CallContactService(hContact, PSS_MESSAGE, 0, DWORD(@Line[1]));
          Break;
         end;
       end;
      hContact := pluginLink^.CallService(MS_DB_CONTACT_FINDNEXT, hContact, 0);
     end;
   end;
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

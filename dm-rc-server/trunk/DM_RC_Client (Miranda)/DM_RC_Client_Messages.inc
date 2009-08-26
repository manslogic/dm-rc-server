{
function mir_strdup(strA: PAnsiChar): PAnsiChar;
begin
 if Assigned(mmi.strdup) then //MIR_VER < 0x0600 aware
   result:=mmi.strdup(strA)
 else
  begin
   result:=mmi.malloc(lstrlena(strA)+1);
   if result<>nil then
     lstrcpya(result, strA);
  end;
end;
}
function GetContactUID(hContact: THandle; const szProto: PAnsiChar): String;
 var
  uid:pAnsiChar;
  //cws:TDBVARIANT;
  dw: DWord;
begin
 uid:=PAnsiChar(CallProtoService(szProto, PS_GETCAPS, PFLAG_UNIQUEIDSETTING, 0));
 dw:=DWord(CallProtoService(szProto, PS_GETCAPS, PFLAGNUM_1, 0));
 //messagebox(0, PChar(IntToStr(dw)), szProto, MB_OK or MB_ICONINFORMATION);
 if ((dw and PF1_NUMERICUSERID)>0) or (SameText(uid, 'UIN')) then
   Result:=IntToStr(DBReadDWord(hContact, szProto, uid))
 else
   Result:=StrPas(DBReadString(hContact, szProto, uid));
end;

function OnFilterAdd(wParam:WPARAM;lParam:LPARAM):int; cdecl;
 var
  hContact: THandle;
  dbei: TDBEVENTINFO;
  s, sb, se: String;
  msg_a: PAnsiChar;
  msg_u: PWideChar;
  MessageStr: tstring;
  ProtoName, Line: String;
  i: Integer;
  ToSend: Boolean;
begin
 Result:=0;
 //
 hContact:=THandle(wParam);
 dbei:=TDBEVENTINFO(Pointer(lParam)^);
 // if event is in protocol that is not monitored
 ProtoName:=dbei.szModule;
 s:='';
 if not ProtoInList(ProtoName, s) then
  begin
   // ...let the event go its way
   Result:=0;
   Exit;
  end;
 // if event is not a message, or if the message has been read or sent...
 if ((dbei.flags and DBEF_SENT)>0)
    or ((dbei.flags and DBEF_READ)>0)
    or (dbei.eventType <> EVENTTYPE_MESSAGE) then
  begin
   // ...let the event go its way
	 Result:=0;
   Exit;
  end;
 // if message is corrupted or empty it cannot be an answer.
 if (dbei.cbBlob=0) or not Assigned(dbei.pBlob) then
  begin
   // reject processing of the event
   Result:=1;
   Exit;
  end;
 //
 if (dbei.flags and DBEF_UTF)>0 then
  begin
   StrDup(msg_a, PAnsiChar(dbei.pBlob));
   UTF8toWide(msg_a, msg_u);
   {$ifdef _UNICODE}
		MessageStr := msg_u;
   {$else}
		MessageStr := mir_u2a(msg_u);
   {$endif}
  end
 else
  begin
    {$ifdef _UNICODE}
		MessageStr := mir_a2u(PAnsiChar(dbei.pBlob));
    {$else}
		MessageStr := PAnsiChar(dbei.pBlob);
    {$endif}
  end;
  //process message
  sb:=DBReadString(0, piShortName, optKWBegin);
  se:=DBReadString(0, piShortName, optKWEnd);
  ToSend:=false;
  for i:=1 to WordCount(MessageStr, CRLFZSet) do
   begin
    Line:=ExtractWord(i, MessageStr, CRLFZSet);
    //messagebox(0, PChar('['+Line+']'), PChar(ProtoName), MB_OK or MB_ICONINFORMATION);
    if not ToSend and SameText(Line, sb) then
     begin
      ToSend:=true;
      Continue;
     end;
    if ToSend and SameText(Line, se) then
     begin
      ToSend:=false;
      Continue;
     end;
    //messagebox(0, PChar(BoolToStr(ToSend, true)), PChar(ProtoName), MB_OK or MB_ICONINFORMATION);
    if ToSend then
     begin
      s:=GetContactUID(hContact, PChar(ProtoName));
      //messagebox(0, PChar('['+Line+']'), PChar(s), MB_OK or MB_ICONWARNING);
      ClientSend(EncodeToken(tknID, s)+EncodeToken(tknProto, ProtoName)+EncodeToken(tknCmd, Line));
     end;
   end;

  {
	// save message from contact
	dbei.flags := dbei.flags or DBEF_READ;
	PluginLink^.CallService(MS_DB_EVENT_ADD, DWORD(hContact), DWORD(@dbei));

	// reject processing of the event
	Result:=1;
  }
end;


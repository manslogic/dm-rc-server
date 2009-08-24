const
 //dialog IDs
 IDD_OPT = 1000;
 IDC_GRPCONN =1001;
 IDC_GRPKEYWRD = 1005;
 //IDC_STC1 = 1002;
 IDC_EDTPORT = 1003;
 //IDC_STC2 = 1004;
 //IDC_STC3 = 1006;
 //IDC_STC4 = 1007;
 IDC_EDTKWB = 1008;
 IDC_EDTKWE = 1009;
 IDC_LSTALL = 1011;
 IDC_LSTUSED = 1012;
 //IDC_STC5 = 1013;
 //IDC_STC6 = 1014;
 IDC_BTNATU = 1015;
 IDC_BTN1TU = 1016;
 IDC_BTN1TA = 1017;
 IDC_BTNATA = 1018;

 //base vars names
 optPort = 'Port';
 optKWBegin = 'KeyWordBegin';
 optKWEnd = 'KeyWordEnd';
 optProtoList = 'ProtoList';

 //defaults
 PortDefault = 10000;
 KWBeginDefault = '%DMRCBEGIN%';
 KWEndDefault = '%DMRCEND%';

 ProtoListSep = '|';

var
 optLoading: Boolean;

{$R DM_RC_Client_Options.RES}

//WIN32 API wrappers
function GetEnabled(hDlg: HWND; idCtrl: Integer): Boolean;
begin
 Result := IsWindowEnabled(GetDlgItem(hDlg, idCtrl));
end;

procedure SetEnabled(hDlg: HWND; idCtrl: Integer; Enabled: Boolean);
begin
 EnableWindow(GetDlgItem(hDlg, idCtrl), Enabled);
end;

function GetText(hDlg: HWND; idCtrl: Integer): String;
var
  dlg_text: array[0..1023] of Char;
begin
 ZeroMemory(@dlg_text, SizeOf(dlg_text));
 GetDlgItemText(hDlg, idCtrl, @dlg_text, 1023);
 Result := dlg_text;
end;

procedure SetText(hDlg: HWND; idCtrl: Integer; Text: String);
begin
 SetDlgItemText(hDlg, idCtrl, @Text[1]);
end;

procedure BoxClear(hDlg: HWND; idCtrl: Integer; CB: Boolean = false);
begin
 if CB then
   SendDlgItemMessage(hDlg, idCtrl, CB_RESETCONTENT, 0, 0)
 else
   SendDlgItemMessage(hDlg, idCtrl, LB_RESETCONTENT, 0, 0);
end;

function BoxAdd(hDlg: HWND; idCtrl: Integer; const Text: String; CB: Boolean = false): Integer;
begin
 if CB then
   Result:=SendDlgItemMessage(hDlg, idCtrl, CB_ADDSTRING, 0, DWORD(@Text[1]))
 else
   Result:=SendDlgItemMessage(hDlg, idCtrl, LB_ADDSTRING, 0, DWORD(@Text[1]));
end;

procedure BoxDel(hDlg: HWND; idCtrl, Index: Integer; CB: Boolean = false);
begin
 if CB then
   SendDlgItemMessage(hDlg, idCtrl, CB_DELETESTRING, Index, 0)
 else
   SendDlgItemMessage(hDlg, idCtrl, LB_DELETESTRING, Index, 0);
end;

function BoxCount(hDlg: HWND; idCtrl: Integer; CB: Boolean = false): Integer;
begin
 if CB then
   Result := SendDlgItemMessage(hDlg, idCtrl, CB_GETCOUNT, 0, 0)
 else
   Result := SendDlgItemMessage(hDlg, idCtrl, LB_GETCOUNT, 0, 0);
end;

function BoxGetIndex(hDlg: HWND; idCtrl: Integer; CB: Boolean = false): Integer;
begin
 if CB then
   Result := SendDlgItemMessage(hDlg, idCtrl, CB_GETCURSEL, 0, 0)
 else
   Result := SendDlgItemMessage(hDlg, idCtrl, LB_GETCURSEL, 0, 0);
end;

procedure BoxSetIndex(hDlg: HWND; idCtrl, Index: Integer; CB: Boolean = false);
begin
 if CB then
  begin
   if (Index>=0) and (Index<BoxCount(hDlg, idCtrl, CB)) then
     SendDlgItemMessage(hDlg, idCtrl, CB_SETCURSEL, Index, 0);
  end
 else
  begin
   if (Index>=0) and (Index<BoxCount(hDlg, idCtrl)) then
     SendDlgItemMessage(hDlg, idCtrl, LB_SETCURSEL, Index, 0);
  end;
end;

procedure BoxAddStrings(hDlg: HWND; idCtrl: Integer; Strings: TStrings; CB: Boolean = false);
 var
  i: Integer;
  Text: String;
begin
 BoxClear(hDlg, idCtrl, CB);
 if Assigned(Strings) then
  begin
   for i:=0 to Strings.Count-1 do
    begin
     Text:=Strings[i];
     if CB then
       SendDlgItemMessage(hDlg, idCtrl, CB_ADDSTRING, 0, DWORD(@Text[1]))
     else
       SendDlgItemMessage(hDlg, idCtrl, LB_ADDSTRING, 0, DWORD(@Text[1]));
    end;
  end;
end;

function BoxGetText(hDlg: HWND; idCtrl: Integer; Index: Integer = 0; CB: Boolean = false): String;
var
  dlg_text: array[0..1023] of Char;
begin
 ZeroMemory(@dlg_text, SizeOf(dlg_text));
 if CB then
   SendDlgItemMessage(hDlg, idCtrl, CB_GETLBTEXT, Index, DWORD(@dlg_text))
 else
   SendDlgItemMessage(hDlg, idCtrl, LB_GETTEXT, Index, DWORD(@dlg_text));
 Result := dlg_text;
end;

function ProtoInList(const Proto: String; var ProtoList: String): Boolean;
begin
 if ProtoList='' then
   ProtoList:=DBReadString(0, piShortName, optProtoList);
 Result:=Pos(Proto+ProtoListSep, ProtoList)>0;
end;

// WM_INITDIALOG message handler
function InitDlg(hDlg:HWnd): Integer;
 type
  apd = array [0..0] of TPROTOCOLDESCRIPTOROLD;
 var
  i, n: Integer;
  s, pn: String;
  proto:^PPROTOCOLDESCRIPTOR;
begin
  optLoading:=true;
  //display options
  s:=IntToStr(DBGetContactSettingDword(0, piShortName, optPort, PortDefault));
  SetText(hDlg, IDC_EDTPORT, s);
  s:=DBReadString(0, piShortName, optKWBegin);
  if s='' then
    s:=KWBeginDefault;
  SetText(hDlg, IDC_EDTKWB, s);
  s:=DBReadString(0, piShortName, optKWEnd);
  if s='' then
    s:=KWEndDefault;
  SetText(hDlg, IDC_EDTKWE, s);
  //load protocols
  s:=DBReadString(0, piShortName, optProtoList);
  BoxClear(hDlg, IDC_LSTALL);
  BoxClear(hDlg, IDC_LSTUSED);
  PluginLink^.CallService(MS_PROTO_ENUMPROTOCOLS, integer(@n), DWORD(@proto));
   begin
    for i:=0 to n-1 do
     begin
      if proto^^._type=PROTOTYPE_PROTOCOL then
       begin
        pn:=StrPas(proto^^.szName);
        if ProtoInList(pn, s) then
          BoxAdd(hDlg, IDC_LSTUSED, pn)
        else
          BoxAdd(hDlg, IDC_LSTALL, pn);
       end;
      Inc(proto);
     end;
   end;
  SetEnabled(hDlg, IDC_BTNATU, BoxCount(hDlg, IDC_LSTALL)>0);
  SetEnabled(hDlg, IDC_BTNATA, BoxCount(hDlg, IDC_LSTUSED)>0);
  //
  optLoading:=false;
  //
  Result := 0;
end;

procedure SaveChangedOptions(hDlg:HWnd);
var
 i: Integer;
 s: String;
begin
 i:=StrToIntDef(GetText(hDlg, IDC_EDTPORT), PortDefault);
 if i<0 then
   i:=0;
 if i>MaxWord then
   i:=MaxWord;
 DBWriteContactSettingDWord(0, piShortName, optPort, i);
 s:=GetText(hDlg, IDC_EDTKWB);
 if s='' then
   s:=KWBeginDefault;
 DBWriteContactSettingString(0, piShortName, optKWBegin, PChar(s));
 s:=GetText(hDlg, IDC_EDTKWE);
 if s='' then
   s:=KWEndDefault;
 DBWriteContactSettingString(0, piShortName, optKWEnd, PChar(s));
 //
 s:='';
 for i:=0 to BoxCount(hDlg, IDC_LSTUSED)-1 do
   s:=s+BoxGetText(hDlg, IDC_LSTUSED, i)+ProtoListSep;
 DBWriteContactSettingString(0, piShortName, optProtoList, PChar(s));
 //
 ClientInit;
end;

// WM_NOTIFY message handler
function NotifyDlg(hDlg:HWnd; idCtrl: Integer; nmhdr: TNMHDR): Integer;
begin
  Result := 0;
  if nmhdr.code <> PSN_APPLY then exit;
  Result := 1;
  // apply changes here
  SaveChangedOptions(hDlg);
end;

function CommandDlg(hDlg:HWnd; idCtrl: Integer; hCtrl: HWND; wNotifyCode: Integer): Integer;
 {
 var
  i, i_f, i_t, i_s, t: Integer;
 }
 var
  s: String;
  i: Integer;
 //
 (*
 function IsDifferent: Boolean;
 begin
  Result:=false;
  if cx_opt_Loading
    then Exit;
  i:=LB_ERR;
  i:=BoxGetIndex(hDlg, CX_IDC_LST);
  if (i>=0) and (Length(cx_CList)>i) then
   begin
    i_f:=BoxGetIndex(hDlg, CX_IDC_CBFROM, true);
    s:=BoxGetText(hDlg, CX_IDC_CBFROM, i_f, true);
    try
     Result:=Result or (s<>cx_CList[i].Currency);
    except
     MessageBox(hDlg, PChar('cx_Clist index error: '+IntToStr(i)), piShortName, MB_OK or MB_ICONERROR);
    end;
    i_t:=BoxGetIndex(hDlg, CX_IDC_CBTO, true);
    s:=BoxGetText(hDlg, CX_IDC_CBTO, i_t, true);
    try
     Result:=Result or (s<>cx_CList[i].StateIn);
    except
     MessageBox(hDlg, 'cx_Clist index error!', piShortName, MB_OK or MB_ICONERROR);
    end;
    i_s:=BoxGetIndex(hDlg, CX_IDC_CBSRC, true);
    s:=BoxGetText(hDlg, CX_IDC_CBSRC, i_s, true);
    try
     Result:=Result or (s<>cx_CList[i].Currency);
    except
     MessageBox(hDlg, 'cx_Clist index error!', piShortName, MB_OK or MB_ICONERROR);
    end;
    t:=Abs(StrToIntDef(GetText(hDlg, CX_IDC_EDTAMT), 1));
    try
     Result:=Result or (t<>cx_CList[i].Amount);
    except
     MessageBox(hDlg, 'cx_Clist index error!', piShortName, MB_OK or MB_ICONERROR);
    end;
   end;
 end;
 *)
begin
  Result := 0;
  case idCtrl of
   (*
   CX_IDC_BTNNEW:
    begin
     i_f:=BoxGetIndex(hDlg, CX_IDC_CBFROM, true);
     i_t:=BoxGetIndex(hDlg, CX_IDC_CBTO, true);
     i_s:=BoxGetIndex(hDlg, CX_IDC_CBSRC, true);
     i:=cx_FindRate(BoxGetText(hDlg, CX_IDC_CBFROM, i_f, true), BoxGetText(hDlg, CX_IDC_CBTO, i_t, true), BoxGetText(hDlg, CX_IDC_CBSRC, i_s, true), Abs(StrToIntDef(GetText(hDlg, CX_IDC_EDTAMT), 1)));
     if i<0 then
      begin
       if i_f=i_t then
         MessageBox(hDlg, Translate(cx_err_NoSame), Translate(cx_dlg_NewCaption), MB_OK or MB_ICONERROR)
       else
        begin
         //cx_AddRate(0, '', BoxGetText(CX_IDC_CBTO, i_f, true), BoxGetText(CX_IDC_CBSRC, i_t, true), BoxGetText(CX_IDC_CBFROM, i_s, true), 1);
         //LoadRates;
         i:=AddNewRateToCList;
         cx_CList[i].Source:=BoxGetText(hDlg, CX_IDC_CBSRC, i_s, true);
         cx_CList[i].StateIn:=BoxGetText(hDlg, CX_IDC_CBTO, i_t, true);
         cx_CList[i].Amount:=Abs(StrToIntDef(GetText(hDlg, CX_IDC_EDTAMT), 1));
         cx_CList[i].Currency:=BoxGetText(hDlg, CX_IDC_CBFROM, i_f, true);
         cx_CList[i].Name:=cx_CList[i].Currency+'/'+cx_CList[i].StateIn;
         cx_CList[i].CurrentRate:='0';
         cx_CList[i].hContact:=0;
         cx_CList[i].Changes:=cx_id_All;
         //
         UpdateRatesList;
         //
         SetText(hDlg, CX_IDC_EDTAMT, '1');
        end;
      end
     else
      begin
       BoxSetIndex(hDlg, CX_IDC_LST, i);
       if cx_Clist[i].Changes=cx_id_Delete then //has marked rate
        begin
         //unmark rate
         cx_Clist[i].Changes:=0;
         UpdateRatesList;
        end
       else
         MessageBox(hDlg, Translate(cx_err_Exists), Translate(cx_dlg_NewCaption), MB_OK or MB_ICONERROR);
      end;
     Result:=1;
    end;
   CX_IDC_BTNDEL:
    begin
     i:=BoxGetIndex(hDlg, CX_IDC_LST);
     if i>=0 then
      begin
       s:=Translate(cx_dlg_DeleteSure);
       if MessageBox(hDlg, PChar(Format(s, [cx_Clist[i].Currency,cx_Clist[i].StateIn,cx_Clist[i].Source])), Translate(cx_dlg_DeleteCaption), MB_YESNO or MB_DEFBUTTON2 or MB_ICONQUESTION)=IDYES then
        begin
         //mark rate to delete
         cx_Clist[i].Changes:=cx_id_Delete;
         UpdateRatesList;
        end;
       Result:=1;
      end;
    end;
   CX_IDC_BTNVAR:
    begin
     CreateDialog(hInstance, MakeIntResource(CX_IDD_VARS), hDlg, @cx_VarsDialogProc);
    end;
   CX_IDC_CBFROM, CX_IDC_CBTO, CX_IDC_CBSRC:
    begin
     if not cx_opt_Loading then
      begin
       if wNotifyCode = CBN_SELCHANGE then
        begin
         SetEnabled(hDlg, CX_IDC_BTNCHN, IsDifferent);
        end;
      end;
    end;
   CX_IDC_EDTAMT:
    begin
     if not cx_opt_Loading then
      begin
       if wNotifyCode = EN_CHANGE then
         SetEnabled(hDlg, CX_IDC_BTNCHN, IsDifferent);
      end;
    end;
   CX_IDC_BTNCHN:
    begin
     i_f:=BoxGetIndex(hDlg, CX_IDC_CBFROM, true);
     i_t:=BoxGetIndex(hDlg, CX_IDC_CBTO, true);
     i_s:=BoxGetIndex(hDlg, CX_IDC_CBSRC, true);
     i:=cx_FindRate(BoxGetText(hDlg, CX_IDC_CBFROM, i_f, true), BoxGetText(hDlg, CX_IDC_CBTO, i_t, true), BoxGetText(hDlg, CX_IDC_CBSRC, i_s, true), Abs(StrToIntDef(GetText(hDlg, CX_IDC_EDTAMT), 1)));
     if i<0 then
      begin
         i:=BoxGetIndex(hDlg, CX_IDC_LST);
         cx_CList[i].Source:=BoxGetText(hDlg, CX_IDC_CBSRC, i_s, true);
         cx_CList[i].StateIn:=BoxGetText(hDlg, CX_IDC_CBTO, i_t, true);
         cx_CList[i].Amount:=Abs(StrToIntDef(GetText(hDlg, CX_IDC_EDTAMT), 1));
         cx_CList[i].Currency:=BoxGetText(hDlg, CX_IDC_CBFROM, i_f, true);
         cx_CList[i].Name:=cx_CList[i].Currency+'/'+cx_CList[i].StateIn;
         cx_CList[i].Changes:=cx_id_Name or cx_id_Amount or cx_id_Currency or cx_id_StateIn or cx_id_Source;
         //
         UpdateRatesList;
         //
         SetText(hDlg, CX_IDC_EDTAMT, '1');
         //
       SetEnabled(hDlg, CX_IDC_BTNCHN, IsDifferent);
       //
       Result:=1;
      end
     else
      begin
       BoxSetIndex(hDlg, CX_IDC_LST, i);
       MessageBox(hDlg, Translate(cx_err_Exists), Translate(cx_dlg_ChangeCaption), MB_OK or MB_ICONERROR);
      end;
    end;
   CX_IDC_EDTCC:
    begin
     if wNotifyCode = EN_CHANGE then
      begin
       s:=GetText(hDlg, CX_IDC_EDTCC);
       SetText(hDlg, CX_IDC_EXCC, cx_FormatString(s));
       Result:=1;
      end;
    end;
   CX_IDC_EDTSM:
    begin
     if wNotifyCode = EN_CHANGE then
      begin
       s:=GetText(hDlg, CX_IDC_EDTSM);
       SetText(hDlg, CX_IDC_EXSM, cx_FormatString(s));
       Result:=1;
      end;
    end;
   CX_IDC_EDTHL:
    begin
     if wNotifyCode = EN_CHANGE then
      begin
       s:=GetText(hDlg, CX_IDC_EDTHL);
       SetText(hDlg, CX_IDC_EXHL, cx_FormatString(s));
       Result:=1;
      end;
    end;
   CX_IDC_EDTUN:
    begin
     if wNotifyCode = EN_CHANGE then
       Result:=1;
    end;
   CX_IDC_LST:
    begin
     if not cx_opt_Loading then
      begin
       case wNotifyCode of
        LBN_SELCHANGE:
         begin
          i:=BoxGetIndex(hDlg, CX_IDC_LST);
          SetEnabled(hDlg, CX_IDC_BTNDEL, i>=0);
          SetEnabled(hDlg, CX_IDC_BTNCHN, false);
          if i>=0 then
           begin
            i_f:=BoxIndexOf(hDlg, CX_IDC_CBFROM, cx_CList[i].Currency, true);
            BoxSetIndex(hDlg, CX_IDC_CBFROM, i_f, true);
            i_t:=BoxIndexOf(hDlg, CX_IDC_CBTO, cx_CList[i].StateIn, true);
            BoxSetIndex(hDlg, CX_IDC_CBTO, i_t, true);
            i_s:=BoxIndexOf(hDlg, CX_IDC_CBSRC, cx_CList[i].Source, true);
            BoxSetIndex(hDlg, CX_IDC_CBSRC, i_s, true);
            cx_opt_Loading:=true;
            SetText(hDlg, CX_IDC_EDTAMT, IntToStr(cx_CList[i].Amount));
            cx_opt_Loading:=false;
           end;
         end;
        end;
       //Result:=1;
      end;
    end;
    *)
   IDC_EDTPORT, IDC_EDTKWB, IDC_EDTKWE:
    begin
     if not optLoading then
      begin
       if wNotifyCode = EN_CHANGE then
         Result:=1;
      end;
    end;
   IDC_LSTALL:
    begin
     if not optLoading then
      begin
       case wNotifyCode of
        LBN_SELCHANGE:
         begin
          i:=BoxGetIndex(hDlg, IDC_LSTALL);
          SetEnabled(hDlg, IDC_BTN1TU, i>=0);
         end
        end;
      end;
    end;
   IDC_LSTUSED:
    begin
     if not optLoading then
      begin
       case wNotifyCode of
        LBN_SELCHANGE:
         begin
          i:=BoxGetIndex(hDlg, IDC_LSTUSED);
          SetEnabled(hDlg, IDC_BTN1TA, i>=0);
         end
        end;
      end;
    end;
   IDC_BTN1TU:
    begin
     i:=BoxGetIndex(hDlg, IDC_LSTALL);
     if i>=0 then
      begin
       s:=BoxGetText(hDlg, IDC_LSTALL, i);
       BoxAdd(hDlg, IDC_LSTUSED, s);
       BoxDel(hDlg, IDC_LSTALL, i);
       SetEnabled(hDlg, IDC_BTN1TU, false);
       SetEnabled(hDlg, IDC_BTNATU, BoxCount(hDlg, IDC_LSTALL)>0);
       SetEnabled(hDlg, IDC_BTNATA, BoxCount(hDlg, IDC_LSTUSED)>0);
      end;
    end;
   IDC_BTN1TA:
    begin
     i:=BoxGetIndex(hDlg, IDC_LSTUSED);
     if i>=0 then
      begin
       s:=BoxGetText(hDlg, IDC_LSTUSED, i);
       BoxAdd(hDlg, IDC_LSTALL, s);
       BoxDel(hDlg, IDC_LSTUSED, i);
       SetEnabled(hDlg, IDC_BTN1TA, false);
       SetEnabled(hDlg, IDC_BTNATU, BoxCount(hDlg, IDC_LSTALL)>0);
       SetEnabled(hDlg, IDC_BTNATA, BoxCount(hDlg, IDC_LSTUSED)>0);
      end;
    end;
   IDC_BTNATU:
    begin
     while BoxCount(hDlg, IDC_LSTALL)>0 do
      begin
       BoxSetIndex(hDlg, IDC_LSTALL, 0);
			 SendMessage(hDlg, WM_COMMAND, IDC_BTN1TU, 0);
      end;
    end;
   IDC_BTNATA:
    begin
     while BoxCount(hDlg, IDC_LSTUSED)>0 do
      begin
       BoxSetIndex(hDlg, IDC_LSTUSED, 0);
			 SendMessage(hDlg, WM_COMMAND, IDC_BTN1TA, 0);
      end;
    end;
   else
    Result := 0;
   end;
  if Result=1 then
   begin
    //if AreOptionsChanged then
      SendMessage(GetParent(hDlg), PSM_CHANGED, hDlg, 0);
   end;
end;

function DlgProcOpt(Dialog:HWnd; hMessage, wParam, lParam: dword):integer; stdcall;
begin
  Result := 0;
  case hMessage of
    WM_INITDIALOG:
     begin
      TranslateDialogDefault(Dialog);
      Result := InitDlg(Dialog);
     end;
    WM_NOTIFY: Result := NotifyDlg(Dialog, wParam, PNMHDR(lParam)^);
    WM_COMMAND: Result := CommandDlg(Dialog, LoWord(wParam), lParam, HiWord(wParam));
    WM_DESTROY: begin end;
  end;
end;

function OnOptInitialise(wParam:WPARAM;lParam:LPARAM):int; cdecl;
var
  odp: TOPTIONSDIALOGPAGE;
begin
  result:=0;
  //NoDescription  :=TranslateW('No Description');
  FillChar(odp, SizeOf(TOPTIONSDIALOGPAGE), 0);
  odp.cbSize     := sizeof(TOPTIONSDIALOGPAGE);
  odp.flags      :=ODPF_BOLDGROUPS;
  odp.Position   :=$00000000;
  odp.hInstance  :=hInstance;
  odp.szGroup.a  :='Plugins';
  odp.szTitle.a  :=piShortName;
  odp.pfnDlgProc :=@DlgProcOpt;
  //odp.pszTemplate := MakeIntResource(IDD_OPT);
  odp.pszTemplate := PAnsiChar(IDD_OPT);
  try
  PluginLink^.CallService(MS_OPT_ADDPAGE,wParam,dword(@odp));
  except
  on E: Exception do
    MessageBox(0, PChar(E.Message), 'Error', MB_OK or MB_ICONERROR);
  end;
end;


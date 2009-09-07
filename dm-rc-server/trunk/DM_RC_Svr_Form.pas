unit DM_RC_Svr_Form;

interface

uses
  StringsSettings,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, ComCtrls, CheckLst, ImgList;

type
  TCfgForm = class(TForm)
    PC1: TPageControl;
    TS1: TTabSheet;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    Button1: TButton;
    LB_Connected: TListBox;
    Label1: TLabel;
    Button2: TButton;
    CLB_IP: TCheckListBox;
    TS2: TTabSheet;
    EIP_URL: TLabeledEdit;
    EIP_Prefix: TLabeledEdit;
    EIP_Proxy: TLabeledEdit;
    EIP_Port: TLabeledEdit;
    EIP_Auth: TCheckBox;
    EIP_User: TLabeledEdit;
    EIP_Pass: TLabeledEdit;
    GB_Conn: TGroupBox;
    E_PortLoc: TEdit;
    CB_PortLoc: TCheckBox;
    CB_PortRem: TCheckBox;
    E_PortRem: TEdit;
    E_PortExt: TEdit;
    CB_PortExt: TCheckBox;
    Label2: TLabel;
    Button3: TButton;
    TS3: TTabSheet;
    CB_DMAPI: TCheckBox;
    IL: TImageList;
    LV_Users: TListView;
    TS4: TTabSheet;
    RG_Store: TRadioGroup;
    GB_AustoSave: TGroupBox;
    Label3: TLabel;
    Label4: TLabel;
    CBX_StoreMain: TComboBox;
    CBX_StoreUser: TComboBox;
    SB_NewUser: TSpeedButton;
    SB_DelUser: TSpeedButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure RG1Click(Sender: TObject);
    procedure EIP_AuthClick(Sender: TObject);
    procedure CB_PortExtClick(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure SB_NewUserClick(Sender: TObject);
    procedure SB_DelUserClick(Sender: TObject);
    procedure LV_UsersClick(Sender: TObject);
    procedure CB_PortRemClick(Sender: TObject);
  private
    { Private declarations }
    FSettings: TStringsSettings;
    FUsers: TStrings;
    procedure GetLocalIPs;
    procedure CheckConnection;
    procedure RefreshConnected;
    procedure BitBtnClick(BitBtn: TBitBtn);
    procedure SetSettings(NewSettings: TStringsSettings);
    procedure CheckAuth;
    procedure CheckRemote;
    procedure CheckExternal;
    procedure RefreshUsers;
    procedure CheckUsers;
  public
    { Public declarations }
    property Settings: TStringsSettings read FSettings write SetSettings;
  end;

var
  CfgForm: TCfgForm = nil;

procedure CfgFormFree;

implementation

{$R *.dfm}

uses
 OverbyteIcsWSocket,
 OverbyteIcsWSocketS,
 DM_RC_Svr_Sockets,
 DM_RC_Svr_Tokens,
 DM_RC_Svr_Defines,
 DM_RC_Svr_Store,
 DM_RC_Svr_Users,
 DM_RC_Svr_ExternalIP;

 {Common stuff}
 
procedure CfgFormFree;
begin
 if Assigned(CfgForm) then
   FreeAndNil(CfgForm);
end;

 {TCfgForm}

procedure TCfgForm.GetLocalIPs;
 var
  i, t: Integer;
begin
 //get local IP list
 CLB_IP.Clear;
 CLB_IP.Items.AddStrings(LocalIPList);
 //mark used
 for i:=0 to FSettings[sIPList]-1 do
  begin
   t:=CLB_IP.Items.IndexOf(FSettings.Group[sIPList, i]);
   if t>=0 then
     CLB_IP.Selected[t]:=true;
  end;
end;

procedure TCfgForm.Button1Click(Sender: TObject);
begin
 GetLocalIPs;
end;

procedure TCfgForm.Button2Click(Sender: TObject);
begin
 RefreshConnected;
end;

procedure TCfgForm.RefreshConnected;
begin
 LB_Connected.Clear;
 LB_Connected.Items.Add('= Local connections =');
 case SocketServerGetConnected(WSSLocal, LB_Connected.Items) of
  -1: LB_Connected.Items.Add('not started');
  0: LB_Connected.Items.Add('none');
  end;
 LB_Connected.Items.Add('= Remote connections =');
 case SocketServerGetConnected(WSSRemote, LB_Connected.Items) of
  -1: LB_Connected.Items.Add('not started');
  0: LB_Connected.Items.Add('none');
  end;
 LB_Connected.Items.Add('= External connections =');
 case SocketServerGetConnected(WSSExternal, LB_Connected.Items) of
  -1: LB_Connected.Items.Add('not started');
  0: LB_Connected.Items.Add('none');
  end;
end;

procedure TCfgForm.FormActivate(Sender: TObject);
begin
 RefreshConnected;
 if Assigned(WSSExternal) then
   Label2.Caption:=WSSExternal.Addr
 else
   Label2.Caption:='No IP yet';
end;

procedure TCfgForm.BitBtnClick(BitBtn: TBitBtn);
begin
 Self.ModalResult:=BitBtn.ModalResult;
 if not (fsModal in Self.FormState) then
   Self.Close;
end;

procedure TCfgForm.BitBtn1Click(Sender: TObject);
begin
 BitBtnClick(BitBtn1);
end;

procedure TCfgForm.BitBtn2Click(Sender: TObject);
begin
 BitBtnClick(BitBtn2);
end;

procedure TCfgForm.FormCreate(Sender: TObject);
begin
 FSettings:=TStringsSettings.Create;
 FUsers:=TStringList.Create;
end;

procedure TCfgForm.FormDestroy(Sender: TObject);
begin
 FreeAndNil(FUsers);
 FreeAndNil(FSettings);
end;

procedure TCfgForm.SetSettings(NewSettings: TStringsSettings);
 var
  i: Integer;
begin
 FSettings.Clear;
 if Assigned(NewSettings) then
  begin
   FSettings.AddStrings(NewSettings);
   //update controls with settings
   RG_Store.ItemIndex:=FSettings[sStore];
   CBX_StoreMain.ItemIndex:=FSettings[sDumpMain];
   CBX_StoreUser.ItemIndex:=FSettings[sDumpUser];
   //
   i:=FSettings[sConnection];
   CB_PortLoc.Checked:=(i and iConnLocal)>0;
   CB_PortRem.Checked:=(i and iConnRemote)>0;
   CB_PortExt.Checked:=(i and iConnExternal)>0;
   CheckConnection;
   CheckRemote;
   CheckExternal;
   E_PortLoc.Text:=IntToStr(FSettings[sPortLoc]);
   E_PortRem.Text:=IntToStr(FSettings[sPortRem]);
   E_PortExt.Text:=IntToStr(FSettings[sPortExt]);
   CB_DMAPI.Checked:=FSettings[sDMAPI];
   //
   EIP_Url.Text:=FSettings[sEIPURL];
   EIP_Prefix.Text:=FSettings[sEIPPrefix];
   EIP_Proxy.Text:=FSettings[sEIPProxy];
   EIP_Port.Text:=IntToStr(FSettings[sEIPPort]);
   EIP_Auth.Checked:=FSettings[sEIPAuth];
   EIP_User.Text:=FSettings[sEIPUser];
   EIP_Pass.Text:=FSettings[sEIPPass];
   CheckAuth;
   //
   UsersFromSettings(FSettings, FUsers);
   RefreshUsers;
  end;
end;

procedure TCfgForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
 var
  i: Integer;
begin
 if ModalResult=mrOK then
  begin
   //check settings
   i:=StrToIntDef(E_PortLoc.Text, -1);
   if (i<0) or (i>MaxWord) then
    begin
     MessageDlg('Port value must be in 0...65535 !', mtError, [mbOK], 0);
     ActiveControl:=E_PortLoc;
     CanClose:=false;
     Exit;
    end;
   i:=StrToIntDef(E_PortRem.Text, -1);
   if (i<0) or (i>MaxWord) then
    begin
     MessageDlg('Port value must be in 0...65535 !', mtError, [mbOK], 0);
     ActiveControl:=E_PortRem;
     CanClose:=false;
     Exit;
    end;
   i:=StrToIntDef(E_PortExt.Text, -1);
   if (i<0) or (i>MaxWord) then
    begin
     MessageDlg('Port value must be in 0...65535 !', mtError, [mbOK], 0);
     ActiveControl:=E_PortExt;
     CanClose:=false;
     Exit;
    end;
   if CB_PortExt.Checked then
    begin
     if EIP_Proxy.Text='' then
      begin
       MessageDlg('You must enter valid proxy IP to use external connection !', mtError, [mbOK], 0);
       ActiveControl:=EIP_Proxy;
       CanClose:=false;
       Exit;
      end;
    end;
   //modify settings from controls
   FSettings[sStore]:=RG_Store.ItemIndex;
   FSettings[sDumpMain]:=CBX_StoreMain.ItemIndex;
   FSettings[sDumpUser]:=CBX_StoreUser.ItemIndex;
   //
   i:=0;
   if CB_PortLoc.Checked then
     i:=i or iConnLocal;
   if CB_PortRem.Checked then
     i:=i or iConnRemote;
   if CB_PortExt.Checked then
     i:=i or iConnExternal;
   FSettings[sConnection]:=i;
   FSettings[sPortLoc]:=StrToIntDef(E_PortLoc.Text, Port_Default);
   FSettings[sPortRem]:=StrToIntDef(E_PortRem.Text, Port_Default);
   FSettings[sPortExt]:=StrToIntDef(E_PortExt.Text, Port_Default);
   FSettings[sIPList]:=0;
   for i:=0 to CLB_IP.Items.Count-1 do
    begin
     if CLB_IP.Checked[i] then
       FSettings.AddValueToGroup(sIPList, CLB_IP.Items[i]);
    end;
   FSettings[sDMAPI]:=CB_DMAPI.Checked;
   //
   //
   FSettings[sEIPURL]:=EIP_Url.Text;
   FSettings[sEIPPrefix]:=EIP_Prefix.Text;
   FSettings[sEIPProxy]:=EIP_Proxy.Text;
   FSettings[sEIPPort]:=StrToIntDef(EIP_Port.Text, EIPPort_Default);
   FSettings[sEIPAuth]:=EIP_Auth.Checked;
   FSettings[sEIPUser]:=EIP_User.Text;
   FSettings[sEIPPass]:=EIP_Pass.Text;
   //
   UsersToSettings(FSettings, FUsers);
  end;
end;

procedure TCfgForm.CheckConnection;
begin
 CLB_IP.Enabled:=CB_PortRem.Checked;
 Button1.Enabled:=CB_PortRem.Checked;
end;

procedure TCfgForm.RG1Click(Sender: TObject);
begin
 CheckConnection;
end;

procedure TCfgForm.CheckAuth;
begin
 EIP_User.Enabled:=EIP_Auth.Checked;
 EIP_Pass.Enabled:=EIP_Auth.Checked;
end;

procedure TCfgForm.EIP_AuthClick(Sender: TObject);
begin
 CheckAuth;
end;

procedure TCfgForm.CheckExternal;
begin
 Label2.Enabled:=CB_PortExt.Checked;
 Button3.Enabled:=CB_PortExt.Checked;
end;

procedure TCfgForm.CB_PortExtClick(Sender: TObject);
begin
 CheckExternal;
end;

procedure TCfgForm.Button3Click(Sender: TObject);
begin
 Label2.Caption:=GetExternalIP(EIP_URL.Text, EIP_Prefix.Text, EIP_Proxy.Text, StrToIntDef(EIP_Port.Text, EIPPort_Default), EIP_User.Text, EIP_Pass.Text);
end;

procedure TCfgForm.SB_NewUserClick(Sender: TObject);
 var
  nID: String;
begin
 nID:=InputBox('Add new user ID', 'Please enter new user ID && protocol'+#13+'(example: 111111111'+InternalProtoSep+'ICQ):', '');
 if nID<>'' then
  begin
   if UserIndex(nID, FUsers)<0 then
     AddUser(nID, utUser, false, FUsers);
   RefreshUsers;
  end;
end;

procedure TCfgForm.CheckUsers;
begin
 SB_NewUser.Enabled:=FUsers.Count<cUsersMax;
 SB_DelUser.Enabled:=LV_Users.ItemIndex>=0;
end;

procedure TCfgForm.RefreshUsers;
begin
 //UsersToILB(ILBUsers, FUsers);
 UsersToLV(LV_Users, FUsers);
 CheckUsers;
end;

procedure TCfgForm.SB_DelUserClick(Sender: TObject);
 var
  i: Integer;
begin
 i:=LV_Users.ItemIndex;
 if i>=0 then
  begin
   if MessageDlg('Are you sure to delete user '+LV_Users.Items[i].Caption+' ?', mtConfirmation, [mbYes, mbNo], 0)=mrYes then
    begin
     FUsers.Delete(i);
     RefreshUsers;
    end;
  end;
end;

procedure TCfgForm.LV_UsersClick(Sender: TObject);
begin
 CheckUsers;
end;

procedure TCfgForm.CheckRemote;
 var
  i: Integer;
  s: String;
begin
 GetLocalIPs;
 CLB_IP.Enabled:=CB_PortRem.Checked;
 if CB_PortRem.Checked then
  begin
   s:=Settings.Group[sIPList, 0];
   i:=CLB_IP.Items.IndexOf(s);
   if i>=0 then
     CLB_IP.Checked[i]:=true;
  end;
end;

procedure TCfgForm.CB_PortRemClick(Sender: TObject);
begin
 CheckRemote;
end;

end.

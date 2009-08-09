unit DM_RC_Svr_Form;

interface

uses
  StringsSettings,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, ComCtrls, CheckLst;

type
  TCfgForm = class(TForm)
    PC1: TPageControl;
    TS1: TTabSheet;
    RG1: TRadioGroup;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    Button1: TButton;
    LE_Port: TLabeledEdit;
    LB_Connected: TListBox;
    Label1: TLabel;
    Button2: TButton;
    CLB_IP: TCheckListBox;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure RG1Click(Sender: TObject);
  private
    { Private declarations }
    FSettings: TStringsSettings;
    procedure GetLocalIPs;
    procedure CheckConnection;
    procedure RefreshConnected;
    procedure BitBtnClick(BitBtn: TBitBtn);
    procedure SetSettings(NewSettings: TStringsSettings);
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
 DM_RC_Svr_Defines;


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
 var
  i: Integer;
begin
 LB_Connected.Clear;
 if Assigned(WSocketServer) then
  begin
   for i := 0 to WSocketServer.ClientCount - 1 do
    begin
     //LB_Connected.Items.Add((WSocketServer.Client[i] As TWSocketClient).Addr);
     LB_Connected.Items.Add((WSocketServer.Client[i] As TWSocketClient).PeerAddr);
     //LB_Connected.Items.Add((WSocketServer.Client[i] As TWSocketClient).DnsResult);
     //LB_Connected.Items.Add((WSocketServer.Client[i] As TWSocketClient).Proto);
     //LB_Connected.Items.Add((WSocketServer.Client[i] As TWSocketClient).LocalAddr);
    end;
  end;
end;

procedure TCfgForm.FormActivate(Sender: TObject);
begin
 RefreshConnected;
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
end;

procedure TCfgForm.FormDestroy(Sender: TObject);
begin
 FreeAndNil(FSettings);
end;

procedure TCfgForm.SetSettings(NewSettings: TStringsSettings);
begin
 FSettings.Clear;
 if Assigned(NewSettings) then
  begin
   FSettings.AddStrings(NewSettings);
   //update controls with settings
   RG1.ItemIndex:=FSettings[sConnection];
   CheckConnection;
   LE_Port.Text:=IntToStr(FSettings[sPort]);
   GetLocalIPs;
  end;
end;

procedure TCfgForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
 var
  i: Integer;
begin
 if ModalResult=mrOK then
  begin
   //check settings
   i:=StrToIntDef(LE_Port.Text, -1);
   if (i<0) or (i>MaxWord) then
    begin
     MessageDlg('Port value must be in 0...65535 !', mtError, [mbOK], 0);
     ActiveControl:=LE_Port;
     CanClose:=false;
     Exit;
    end;
   //modify settings from controls
   FSettings[sConnection]:=RG1.ItemIndex;
   FSettings[sPort]:=StrToIntDef(LE_Port.Text, Port_Default);
   FSettings[sIPList]:=0;
   for i:=0 to CLB_IP.Items.Count-1 do
    begin
     if CLB_IP.Checked[i] then
       FSettings.AddValueToGroup(sIPList, CLB_IP.Items[i]);
    end;
  end;
end;

procedure TCfgForm.CheckConnection;
begin
 CLB_IP.Enabled:=RG1.ItemIndex=iConnRemote;
 Button1.Enabled:=RG1.ItemIndex=iConnRemote;
end;

procedure TCfgForm.RG1Click(Sender: TObject);
begin
 CheckConnection;
end;

end.

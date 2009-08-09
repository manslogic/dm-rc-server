unit DM_RC_Svr_Form;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, ComCtrls;

type
  TCfgForm = class(TForm)
    PC1: TPageControl;
    TS1: TTabSheet;
    RG1: TRadioGroup;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    LB_IP: TListBox;
    Button1: TButton;
    LE_Port: TLabeledEdit;
    LB_Connected: TListBox;
    Label1: TLabel;
    Button2: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
  private
    { Private declarations }
    procedure RefreshConnected;
    procedure BitBtnClick(BitBtn: TBitBtn);
  public
    { Public declarations }
  end;

var
  CfgForm: TCfgForm = nil;

implementation

{$R *.dfm}

uses
 OverbyteIcsWSocket,
 OverbyteIcsWSocketS,
 DM_RC_Svr_Sockets;

procedure TCfgForm.Button1Click(Sender: TObject);
begin
 LB_IP.Clear;
 LB_IP.Items.AddStrings(LocalIPList);
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

end.

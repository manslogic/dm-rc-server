unit DM_RC_Svr_ExternalIP;

interface

const
 eieSiteNotFound = '[site not found]';
 eiePrefixNotFound = '[prefix not found]';

 EIPPort_Default = 3128;

 //settings
 ssEIP = 'ExternalIP';
 sEIPURL = 'EIP_URL';
 sEIPPrefix = 'EIP_Prefix';
 sEIPProxy = 'EIP_Proxy';
 sEIPPort = 'EIP_Port';
 sEIPAuth = 'EIP_Auth';
 sEIPUser = 'EIP_User';
 sEIPPass = 'EIP_Pass';

function GetExternalIP(FromSite: String = ''; Prefix: String = ''; ProxyServer: String =''; ProxyPort: Integer = -1; ProxyUser: String = ''; ProxyPass: String = ''; SaveBodyTo: String = ''): String;

implementation

uses
 Classes,
 SysUtils,
 OverbyteIcsWSocket,
 OverbyteIcsHttpProt;

const
 DefStrRus = 'Найденный адрес</TD></TR><TR><TD BGCOLOR="#ffffff" ALIGN=CENTER VALIGN=TOP><font size=2>';
 DefStrEng = 'Client''s address we got</TD></TR><TR><TD BGCOLOR="#ffffff" ALIGN=CENTER VALIGN=TOP><font size=2>';

function GetExternalIP(FromSite: String = ''; Prefix: String = ''; ProxyServer: String =''; ProxyPort: Integer = -1; ProxyUser: String = ''; ProxyPass: String = ''; SaveBodyTo: String = ''): String;
 var
  HTTP: THttpCli;
  Body: TStrings;
  BodyStr, Search: String;
  i, l, p: Integer;
 const
  Allowed: set of char = ['0'..'9', '.'];
 procedure RcvdStreamFree;
 begin
  if Assigned(HTTP.RcvdStream) then
   begin
    HTTP.RcvdStream.Free;
    HTTP.RcvdStream:=nil;
   end;
 end;
begin
 HTTP:=THttpCli.Create(nil);
 HTTP.Agent:='Mozilla/3.0 (compatible)';
 //setup proxy params
 if ProxyServer = '' then
  begin
   HTTP.Proxy:='';
   HTTP.ProxyPort:='';
  end
 else
  begin
   HTTP.Proxy:=ProxyServer;
   HTTP.ProxyPort:=IntToStr(ProxyPort);
   if ProxyUser = '' then
    begin
     HTTP.ProxyAuth:=httpAuthNone;
     HTTP.ProxyUsername:='';
     HTTP.ProxyPassword:='';
    end
   else
    begin
     HTTP.ProxyAuth:=httpAuthBasic;
     HTTP.ProxyUsername:=ProxyUser;
     HTTP.ProxyPassword:=ProxyPass;
    end;
  end;
 //setup source URL
 if FromSite='' then
   HTTP.URL:='http://leader.ru/secure/who.html'
 else
   HTTP.URL:=FromSite;
 //other setup
 HTTP.AcceptLanguage := 'en, ru';
 HTTP.Connection     := 'Close';
 HTTP.RequestVer     := '1.0';
 HTTP.RcvdStream     := TMemoryStream.Create;
 //get URL
 Body:=TStringList.Create;
 try
  HTTP.Get;
 except
  Body.Clear;
  RcvdStreamFree;
 end;
 if Assigned(HTTP.RcvdStream) then
  begin
   HTTP.RcvdStream.Position:=0;
   Body.LoadFromStream(HTTP.RcvdStream);
  end;
 BodyStr:=Body.Text;
 //parse Body
 if BodyStr='' then
  begin
   if Result='' then
     Result:=eieSiteNotFound;
  end
 else
  begin
   if Prefix='' then
     Search:=DefStrRus
   else
     Search:=Prefix;
   p:=Pos(Search, BodyStr);
   if (p=0) and (Search=DefStrRus) then
    begin
     Search:=DefStrEng;
     p:=Pos(Search, BodyStr);
    end;
   if p>0 then
    begin
     i:=p+Length(Search);
     l:=Length(BodyStr);
     while (i<=l) and not (BodyStr[i] in Allowed) do
       Inc(i);
     Result:='';
     while (i<=l) and (BodyStr[i] in Allowed) do
      begin
       Result:=Result+BodyStr[i];
       Inc(i);
      end;
    end
   else
     Result:=eiePrefixNotFound;
  end;
 if SaveBodyTo<>'' then
  begin
   try
    Body.SaveToFile(SaveBodyTo);
   except
   end;
  end;
 RcvdStreamFree;
 FreeAndNil(Body);
 FreeAndNil(HTTP);
end;

end.
 
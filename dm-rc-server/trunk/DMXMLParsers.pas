unit DMXMLParsers;

interface

{$DEFINE USEJEDI}

uses
 Classes,
 {$IFDEF USEJEDI}
 JclSimpleXML;
 {$ELSE}
 xmldom, XMLIntf, msxmldom, XMLDoc;
 {$ENDIF}

const
 pfeOK = 0;
 pfeFileNotFound = 1;

 sdlID = 'ID';
 sdlURL = 'URL';
 sdlFilename = 'FileName';
 sdlState = 'State';
 sdlSize = 'Size';
 sdlSaveDir = 'SaveDir';
 sdlDownloadedSize = 'DownloadedSize';
 sdlReferer = 'Referer';
 sdlLastModified = 'LastModified';
 sdlResumeMode = 'ResumeMode';
 sdlPriority = 'Priority';
 sdlDate = 'Date';
 sdlDownloadTime = 'DownloadTime';
 sdlNodeID = 'NodeID';
 sdlContentType = 'ContentType';
 sdlProxyID = 'ProxyID'; // -1 = dont'use
 sdlMirrors = 'Mirrors'; // CRLF separated
 sdlSheduled = 'Sheduled'; // 1 = sheduled
 sdlComment = 'Comment';

 sndID = 'ID';
 sndParentID = 'ParentID';
 sndNodeType = 'NodeType';
 sndName = 'Name';
 sndSaveTo = 'SaveTo';
 sndExtList = 'ExtList';
 sndImageIndex = 'ImageIndex';
 sndExpanded = 'Expanded';

 shsURL = 'ur';
 shsFilename = 'fn';
 shsDate = 'da';
 shsDownloaded = 'dd';
 shsSize = 'sz';
 shsDescription = 'de';

function ParseXML(Filename: String; Strings: TStrings): Integer;

implementation

uses
 SysUtils,
 Tokens;

function ParseXML(Filename: String; Strings: TStrings): Integer;
 var
  v: String;
 {$IFDEF USEJEDI}
  XML: TJclSimpleXML;
  Root, Node, Child: TJclSimpleXMLElem;
 {$ELSE}
  XML: TXMLDocument;
  Root, Node, Child: IXMLNode;
 {$ENDIF}
  i, t: Integer;
begin
 Result:=pfeOK;
 if not FileExists(Filename) then
  begin
   Result:=pfeFileNotFound;
   Exit;
  end;
 {$IFDEF USEJEDI}
 XML:=TJclSimpleXML.Create;
 {$ELSE}
 XML:=TXMLDocument.Create(nil);
 XMLD.DOMVendor:=GetDOMVendor('MSXML');
 {$ENDIF}
 XML.LoadFromFile(Filename);
 Strings.Clear;
 {$IFDEF USEJEDI}
 Root:=XML.Root;
 {$ELSE}
 Root:=XML.DocumentElement;
 {$ENDIF}
 {$IFDEF USEJEDI}
 if (Root.Name='NodeList') or (Root.Name='DownloadList') or (Root.Name='DownloadHistoryList') then
  begin
   for i:=0 to Root.Items.Count-1 do
    begin
     Node:=Root.Items[i];
     if (Node.Name='MyNode') or (Node.Name='DownloadFile') or (Node.Name='hitem') then
      begin
       v:='';
       for t:=0 to Node.Items.Count-1 do
        begin
         Child:=Node.Items[t];
         if Child.Name='ID' then
           v:=Child.Value+'='
         else
           v:=v+EncodeToken(Child.Name, UTF8Decode(Child.Value));
        end;
       if (Pos('=', v)>0) or (Node.Name='hitem') then
         Strings.Add(v);
      end;
    end;
  end;
 {$ELSE}
 if (Root.NodeName='NodeList') or (Root.NodeName='DownloadList') or (Root.NodeName='DownloadHistoryList') then
  begin
   for i:=0 to Root.ChildNodes.Count-1 do
    begin
     Node:=Root.ChildNodes[i];
     if (Node.NodeName='MyNode') or (Node.NodeName='DownloadFile') or (Node.NodeName='hitem') then
      begin
       v:='';
       for t:=0 to Node.ChildNodes.Count-1 do
        begin
         Child:=Node.ChildNodes[t];
         if Child.NodeName='ID' then
           v:=Child.NodeValue+'='
         else
           v:=v+EncodeToken(Child.NodeName, Child.NodeValue);
        end;
       if (Pos('=', v)>0) or (Node.NodeName='hitem') then
         Strings.Add(v);
      end;
    end;
  end;
 {$ENDIF}
 XML.Free;
end;

end.

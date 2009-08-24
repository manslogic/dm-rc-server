{
Miranda IM: the free IM client for Microsoft* Windows*

Copyright 2000-2008 Miranda ICQ/IM project, 
all portions of this codebase are copyrighted to the people 
listed in contributors.txt.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
}

{$IFNDEF M_XML}
{$DEFINE M_XML}

type
  HXML = THANDLE;

type
  XML_API_A = record
    cbSize             :integer;

    createNode         :function(const name, text:PAnsiChar; bIsDeclaration:boolean):HXML;cdecl;
    destroyNode        :procedure(node:HXML);cdecl;

    parseString        :function(const str:PAnsiChar; datalen:pint; const tag:PAnsiChar):HXML;cdecl;
    toString           :function(node:HXML;datalen:pint):PAnsiChar;cdecl;

    addChild           :function(parent:HXML; const name,text:PAnsiChar):HXML;cdecl;
    addChild2          :procedure(child,parent:HXML);cdecl;
    copyNode           :function(parent:HXML):HXML;cdecl;
    getChild           :function(parent:HXML;number:int):HXML;cdecl;
    getChildCount      :function(h:HXML):int;cdecl;
    getChildByAttrValue:function(parent:HXML; const name,attrName,attrValue:PAnsiChar):HXML;cdecl;
    getFirstChild      :function(parent:HXML):HXML;cdecl;
    getNthChild        :function(parent:HXML; const name:PAnsiChar; n:int):HXML;cdecl;
    getNextChild       :function(parent:HXML; const name:PAnsiChar; i:pint):HXML;cdecl;
    getChildByPath     :function(parent:HXML; const path:PAnsiChar;createNodeIfMissing:boolean):HXML;cdecl;
    getNextNode        :function(node:HXML):HXML;cdecl;
    getName            :function(h:HXML):PAnsiChar;cdecl;
    getParent          :function(h:HXML):HXML;cdecl;
    getText            :function(h:HXML):PAnsiChar;cdecl;
    setText            :procedure(h:HXML;value:PAnsiChar);cdecl;

    getAttr            :function(h:HXML;n:int):PAnsiChar;cdecl;
    getAttrName        :function(h:HXML;n:int):PAnsiChar;cdecl;
    getAttrValue       :function(h:HXML;const attrName:PAnsiChar):PAnsiChar;cdecl;
    getAttrCount       :function(h:HXML):int;cdecl;
    addAttr            :procedure(h:HXML;const attrName,attrValue:PAnsiChar);cdecl;
    addAttrInt         :procedure(h:HXML; const attrName:PAnsiChar;attrValue:int);cdecl;

    freeMem            :procedure(arg:pointer);cdecl;
  end;

  XML_API_W = record
    cbSize             :integer;

    createNode         :function(const name, text:PWideChar; bIsDeclaration:boolean):HXML;cdecl;
    destroyNode        :procedure(node:HXML);cdecl;

    parseString        :function(const str:PWideChar; datalen:pint; const tag:PWideChar):HXML;cdecl;
    toString           :function(node:HXML;datalen:pint):PWideChar;cdecl;

    addChild           :function(parent:HXML; const name,text:PWideChar):HXML;cdecl;
    addChild2          :procedure(child,parent:HXML);cdecl;
    copyNode           :function(parent:HXML):HXML;cdecl;
    getChild           :function(parent:HXML;number:int):HXML;cdecl;
    getChildCount      :function(h:HXML):int;cdecl;
    getChildByAttrValue:function(parent:HXML; const name,attrName,attrValue:PWideChar):HXML;cdecl;
    getFirstChild      :function(parent:HXML):HXML;cdecl;
    getNthChild        :function(parent:HXML; const name:PWideChar; n:int):HXML;cdecl;
    getNextChild       :function(parent:HXML; const name:PWideChar; i:pint):HXML;cdecl;
    getChildByPath     :function(parent:HXML; const path:PWideChar;createNodeIfMissing:boolean):HXML;cdecl;
    getNextNode        :function(node:HXML):HXML;cdecl;
    getName            :function(h:HXML):PWideChar;cdecl;
    getParent          :function(h:HXML):HXML;cdecl;
    getText            :function(h:HXML):PWideChar;cdecl;
    setText            :procedure(h:HXML;value:PWideChar);cdecl;

    getAttr            :function(h:HXML;n:int):PWideChar;cdecl;
    getAttrName        :function(h:HXML;n:int):PWideChar;cdecl;
    getAttrValue       :function(h:HXML;const attrName:PWideChar):PWideChar;cdecl;
    getAttrCount       :function(h:HXML):int;cdecl;
    addAttr            :procedure(h:HXML;const attrName,attrValue:PWideChar);cdecl;
    addAttrInt         :procedure(h:HXML; const attrName:PWideChar;attrValue:int);cdecl;

    freeMem            :procedure(arg:pointer);cdecl;
  end;

// every protocol should declare this variable to use the XML API
//const
// extern XML_API xi;

const
{
a service to obtain the XML API 

wParam = 0;
lParam = (LPARAM)(XML_API*).

returns TRUE if all is Ok, and FALSE otherwise
}
  MS_SYSTEM_GET_XI:PAnsiChar = 'Miranda/System/GetXmlApi';
(*
__forceinline int mir_getXI( XML_API* dest )
{
  dest->cbSize = sizeof(*dest);
  return CallService( MS_SYSTEM_GET_XI, 0, (LPARAM)dest );
}
*)
{$ENDIF}

unit DM_RC_Client_Utils;

interface

uses
 Windows;

function  mGetMem (var dst;size:integer):pointer;
procedure mFreeMem(var ptr);

// String processing
function WideToCombo(src:PWideChar;var dst;cp:integer=CP_ACP  ):integer;
function ChangeUnicode(str:PWideChar):PWideChar;
function UTF8Len(src:PAnsiChar):integer;
function WideToANSI(src:PWideChar;var dst:PAnsiChar;cp:dword=CP_ACP):PAnsiChar;
function ANSIToWide(src:PAnsiChar;var dst:PWideChar;cp:dword=CP_ACP):PWideChar;
function ANSIToUTF8(src:PAnsiChar;var dst:PAnsiChar;cp:dword=CP_ACP):PAnsiChar;
function UTF8toANSI(src:PAnsiChar;var dst:PAnsiChar;cp:dword=CP_ACP):PAnsiChar;
function UTF8toWide(src:PAnsiChar;var dst:PWideChar;len:cardinal=dword(-1)):PWideChar;
function WidetoUTF8(src:PWideChar;var dst:PAnsiChar):PAnsiChar;

// ----- base strings functions -----
function StrDup (var dst:PAnsiChar;src:PAnsiChar;len:cardinal=0):PAnsiChar;
function StrDupW(var dst:PWideChar;src:PWideChar;len:cardinal=0):PWideChar;
function StrDelete (aStr:PAnsiChar;pos,len:cardinal):PAnsiChar;
function StrDeleteW(aStr:PWideChar;pos,len:cardinal):PWideChar;
function StrInsert (substr,src:PAnsiChar;pos:cardinal):PAnsiChar;
function StrInsertW(substr,src:PWideChar;pos:cardinal):PWideChar;
function StrReplace (src,SubStr,NewStr:PAnsiChar):PAnsiChar;
function StrReplaceW(src,SubStr,NewStr:pWideChar):PWideChar;
function CharReplace (dst:pAnsiChar;old,new:AnsiChar):PAnsiChar;
function CharReplaceW(dst:pWideChar;old,new:WideChar):PWideChar;
function StrCmp (a,b:PAnsiChar;n:cardinal=$FFFFFFFF):integer;
function StrCmpW(a,b:PWideChar;n:cardinal=$FFFFFFFF):integer;
function StrEnd (const a:PAnsiChar):PAnsiChar;
function StrEndW(const a:PWideChar):PWideChar;
function StrScan (src:PAnsiChar;c:AnsiChar):PAnsiChar;
function StrScanW(src:PWideChar;c:WideChar):PWideChar;
function StrRScan (src:PAnsiChar;c:AnsiChar):PAnsiChar;
function StrRScanW(src:PWideChar;c:WideChar):PWideChar;
function StrLen (Str: PAnsiChar): Cardinal;
function StrLenW(Str: PWideChar): Cardinal;
function StrCat (Dest: PAnsiChar; const Source: PAnsiChar): PAnsiChar;
function StrCatW(Dest: PWideChar; const Source: PWideChar): PWideChar;
function StrCopyE (dst:PAnsiChar;src:PAnsiChar;len:cardinal=0):PAnsiChar;
function StrCopyEW(dst:PWideChar;src:PWideChar;len:cardinal=0):PWideChar;
function StrCopy (dst:PAnsiChar;src:PAnsiChar;len:cardinal=0):PAnsiChar;
function StrCopyW(dst:PWideChar;src:PWideChar;len:cardinal=0):PWideChar;
function StrPos (const aStr, aSubStr: PAnsiChar): PAnsiChar;
function StrPosW(const aStr, aSubStr: PWideChar): PWideChar;
function StrIndex (const aStr, aSubStr: PAnsiChar):integer;
function StrIndexW(const aStr, aSubStr: PWideChar):integer;

implementation

function mGetMem(var dst;size:integer):pointer;
begin
{$IFDEF USE_MMI}
  if @mmi.malloc<>nil then
    pointer(dst):=mmi.malloc(size)
  else
{$ENDIF}
    GetMem(pointer(dst),size);
  result:=pointer(dst);
end;

procedure mFreeMem(var ptr);
begin
  if pointer(ptr)<>nil then
  begin
{$IFDEF USE_MMI}
    if @mmi.free<>nil then
      mmi.free(pointer(ptr))
    else
{$ENDIF}
      FreeMem(pointer(ptr));
    Pointer(ptr):=nil;
  end;
end;

// --------- string conversion ----------

function WideToCombo(src:PWideChar;var dst;cp:integer=CP_ACP):integer;
var
  pc:PAnsiChar;
  i,j:Cardinal;
begin
  WideToAnsi(src,pc,cp);
  j:=StrLen(pc)+1;
  i:=j+(StrLenW(src)+1)*SizeOf(WideChar);
  mGetMem(PAnsiChar(dst),i);
  StrCopy(PAnsiChar(dst),pc);
  mFreeMem(pc);
  StrCopyW(pWideChar(PAnsiChar(dst)+j),src);
  result:=i;
end;

function ChangeUnicode(str:PWideChar):PWideChar;
var
  i,len:integer;
begin
  result:=str;
  if str=nil then
    exit;
  if (word(str^)=$FFFE) or (word(str^)=$FEFF) then
  begin
    len:=StrLenW(str);
    if word(str^)=$FFFE then
    begin
      i:=len-1;
      while i>0 do // str^<>#0
      begin
        pword(str)^:=swap(pword(str)^);
        inc(str);
        dec(i);
      end;
    end;
    move((result+1)^,result^,len*SizeOf(WideChar));
  end;
end;

function WideToANSI(src:PWideChar;var dst:PAnsiChar; cp:dword=CP_ACP):PAnsiChar;
var
  len,l:integer;
begin
  if (src=nil) or (src^=#0) then
  begin
    mGetMem(result,SizeOf(AnsiChar));
    result^:=#0;
  end
  else
  begin
    l:=StrLenW(src);
    len:=WideCharToMultiByte(cp,0,src,l,NIL,0,NIL,NIL)+1;
    mGetMem(result,len);
    FillChar(result^,len,0);
    WideCharToMultiByte(cp,0,src,l,result,len,NIL,NIL);
  end;
  dst:=result;
end;

function ANSIToWide(src:PAnsiChar;var dst:PWideChar; cp:dword=CP_ACP):PWideChar;
var
  len,l:integer;
begin
  if (src=nil) or (src^=#0) then
  begin
    mGetMem(result,SizeOf(WideChar));
    result^:=#0;
  end
  else
  begin
    l:=StrLen(src);
    len:=MultiByteToWideChar(cp,0,src,l,NIL,0)+1;
    mGetMem(result,len*SizeOf(WideChar));
    FillChar(result^,len*SizeOf(WideChar),0);
    MultiByteToWideChar(cp,0,src,l,result,len);
  end;
  dst:=result;
end;

function ANSIToUTF8(src:PAnsiChar;var dst:PAnsiChar;cp:dword=CP_ACP):PAnsiChar;
var
  tmp:PWideChar;
begin
  AnsiToWide(src,tmp,cp);
  result:=WideToUTF8(tmp,dst);
  mFreeMem(tmp);
end;

function UTF8Len(src:PAnsiChar):integer; // w/o zero
begin
  result:=0;
  if src<>nil then
  begin
    while src^<>#0 do
    begin
      if (ord(src^) and $80)=0 then
      else if (ord(src^) and $E0)=$E0 then
        inc(src,2)
      else
        inc(src);
      inc(result);
      inc(src);
    end;
  end;
end;

function CalcUTF8Len(src:pWideChar):integer;
begin
  result:=0;
  if src<>nil then
  begin
    while src^<>#0 do
    begin
      if src^<#$0080 then
      else if src^<#$0800 then
        inc(result)
      else
        inc(result,2);
      inc(src);
      inc(result);
    end;
  end;
end;

function UTF8toWide(src:PAnsiChar; var dst:PWideChar; len:cardinal=dword(-1)):PWideChar;
var
  w:word;
  p:PWideChar;
begin
  mGetMem(dst,(UTF8Len(src)+1)*SizeOf(WideChar));
  p:=dst;
  if src<>nil then
  begin
    while (src^<>#0) and (len>0) do
    begin
      if ord(src^)<$80 then
        w:=ord(src^)
      else if (ord(src^) and $E0)=$E0 then
      begin
        w:=(ord(src^) and $1F) shl 12;
        inc(src); dec(len);
        w:=w or (((ord(src^))and $3F) shl 6);
        inc(src); dec(len);
        w:=w or (ord(src^) and $3F);
      end
      else
      begin
        w:=(ord(src^) and $3F) shl 6;
        inc(src); dec(len);
        w:=w or (ord(src^) and $3F);
      end;
      p^:=WideChar(w);
      inc(p);
      inc(src); dec(len);
    end;
  end;
  p^:=#0;
  result:=dst;
end;

function UTF8toANSI(src:PAnsiChar;var dst:PAnsiChar;cp:dword=CP_ACP):PAnsiChar;
var
  tmp:pWideChar;
begin
  UTF8ToWide(src,tmp);
  result:=WideToAnsi(tmp,dst,cp);
  mFreeMem(tmp);
end;

function WidetoUTF8(src:PWideChar; var dst:PAnsiChar):PAnsiChar;
var
  p:PAnsiChar;
begin
  mGetMem(dst,CalcUTF8Len(src)+1);
  p:=dst;
  if src<>nil then
  begin
    while src^<>#0 do
    begin
      if src^<#$0080 then
        p^:=AnsiChar(src^)
      else if src^<#$0800 then
      begin
        p^:=AnsiChar($C0 or (ord(src^) shr 6));
        inc(p);
        p^:=AnsiChar($80 or (ord(src^) and $3F));
      end
      else
      begin
        p^:=AnsiChar($E0 or (ord(src^) shr 12));
        inc(p);
        p^:=AnsiChar($80 or ((ord(src^) shr 6) and $3F));
        inc(p);
        p^:=AnsiChar($80 or (ord(src^) and $3F));
      end;
      inc(p);
      inc(src);
    end;
  end;
  p^:=#0;
  result:=dst;
end;

// ----- base string functions -----
function StrDup(var dst:PAnsiChar;src:PAnsiChar;len:cardinal=0):PAnsiChar;
var
  l:cardinal;
  p:pAnsiChar;
begin
  if (src=nil) or (src^=#0) then
    dst:=nil
  else
  begin
    if len=0 then
      len:=high(cardinal);
    p:=src;
    l:=len;
    while (p^<>#0) and (l>0) do
    begin
      inc(p); dec(l);
    end;
    l:=p-src;

    mGetMem(dst,l+1);
    move(src^, dst^,l);
    dst[l]:=#0;
  end;
  result:=dst;
end;

function StrDupW(var dst:PWideChar;src:PWideChar;len:cardinal=0):PWideChar;
var
  l:cardinal;
  p:pWideChar;
begin
  if (src=nil) or (src^=#0) then
    dst:=nil
  else
  begin
    if len=0 then
      len:=high(cardinal);
    p:=src;
    l:=len;
    while (p^<>#0) and (l>0) do
    begin
      inc(p); dec(l);
    end;
    l:=p-src;
    mGetMem(dst,(l+1)*SizeOf(WideChar));
    move(src^, dst^,l*SizeOf(WideChar));
    dst[l]:=#0;
  end;
  result:=dst;
end;

function StrCopyE(dst:PAnsiChar;src:PAnsiChar;len:cardinal=0):PAnsiChar;
var
  l:cardinal;
  p:pAnsiChar;
begin
  if dst<>nil then
  begin
    if (src=nil) or (src^=#0) then
      dst^:=#0
    else
    begin
      if len=0 then
        len:=high(cardinal);
      p:=src;
      l:=len;
      while (p^<>#0) and (l>0) do
      begin
        inc(p); dec(l);
      end;
      l:=p-src;
      move(src^, dst^,l);
      inc(dst,l);
      dst^:=#0;
    end;
  end;
  result:=dst;
end;

function StrCopyEW(dst:PWideChar;src:PWideChar;len:cardinal=0):PWideChar;
var
  l:cardinal;
  p:pWideChar;
begin
  if dst<>nil then
  begin
    if (src=nil) or (src^=#0) then
      dst^:=#0
    else
    begin
      if len=0 then
        len:=high(cardinal);
      p:=src;
      l:=len;
      while (p^<>#0) and (l>0) do
      begin
        inc(p); dec(l);
      end;
      l:=p-src;
      move(src^, dst^,l*SizeOf(WideChar));
      inc(dst,l);
      dst^:=#0;
    end;
  end;
  result:=dst;
end;

function StrCopy(dst:PAnsiChar;src:PAnsiChar;len:cardinal=0):PAnsiChar;
var
  l:cardinal;
  p:pAnsiChar;
begin
  if dst<>nil then
  begin
    if (src=nil) or (src^=#0) then
      dst^:=#0
    else
    begin
      if len=0 then
        len:=high(cardinal);
      p:=src;
      l:=len;
      while (p^<>#0) and (l>0) do
      begin
        inc(p); dec(l);
      end;
      l:=p-src;
      move(src^, dst^,l);
      dst[l]:=#0;
    end;
  end;
  result:=dst;
end;

function StrCopyW(dst:PWideChar;src:PWideChar;len:cardinal=0):PWideChar;
var
  l:cardinal;
  p:pWideChar;
begin
  if dst<>nil then
  begin
    if (src=nil) or (src^=#0) then
      dst^:=#0
    else
    begin
      if len=0 then
        len:=high(cardinal);
      p:=src;
      l:=len;
      while (p^<>#0) and (l>0) do
      begin
        inc(p); dec(l);
      end;
      l:=p-src;
      move(src^, dst^,l*SizeOf(WideChar));
      dst[l]:=#0;
    end;
  end;
  result:=dst;
end;

function StrDelete(aStr:PAnsiChar;pos,len:cardinal):PAnsiChar;
var
  i:cardinal;
begin
  if len>0 then
  begin
    i:=StrLen(aStr);
    if pos<i then
    begin
      if (pos+len)>i then
        len:=i-pos;
      StrCopy(aStr+pos,aStr+pos+len);
    end;
  end;
  result:=aStr;
end;

function StrDeleteW(aStr:PWideChar;pos,len:cardinal):PWideChar;
var
  i:cardinal;
begin
  if len>0 then
  begin
    i:=StrLenW(aStr);
    if pos<i then
    begin
      if (pos+len)>i then
        len:=i-pos;
      StrCopyW(aStr+pos,aStr+pos+len);
    end;
  end;
  result:=aStr;
end;

function StrInsert(substr,src:PAnsiChar;pos:cardinal):PAnsiChar;
var
  i:cardinal;
  p:PAnsiChar;
begin
  i:=StrLen(substr);
  if i<>0 then
  begin
    p:=src+pos;
    move(p^,(p+i)^,StrLen(src)-pos+1);
    move(substr^,p^,i);
  end;
  result:=src;
end;

function StrInsertW(substr,src:PWideChar;pos:cardinal):PWideChar;
var
  i:cardinal;
  p:PWideChar;
begin
  i:=StrLenW(substr);
  if i<>0 then
  begin
    p:=src+pos;
    move(p^,(p+i)^,(StrLenW(src)-pos+1)*SizeOf(PWideChar));
    move(substr^,p^,i*SizeOf(WideChar));
  end;
  result:=src;
end;

function StrReplace(src,SubStr,NewStr:PAnsiChar):PAnsiChar;
var
  i,j,l:integer;
  k:integer;
  p:PAnsiChar;
begin
  result:=src;
  p:=StrPos(src,SubStr);
  if p=nil then exit;
  i:=StrLen(SubStr);
  j:=StrLen(NewStr);
  l:=i-j;
  repeat
    if j=0 then
      StrCopy(p,p+i)
    else
    begin
      k:=StrLen(p)+1;
      if l>0 then
        move((p+l)^,p^,k-l)
      else if l<>0 then
        move(p^,(p-l)^,k);
      move(NewStr^,p^,j); {new characters}
      inc(p,j);
    end;
    p:=StrPos(p,SubStr);
    if p=nil then break;
  until false;
end;

function StrReplaceW(src,SubStr,NewStr:pWideChar):PWideChar;
var
  i,j,l:integer;
  k:integer;
  p:PWideChar;
begin
  result:=src;
  p:=StrPosW(src,SubStr);
  if p=nil then exit;
  i:=StrLenW(SubStr);
  j:=StrLenW(NewStr);
  l:=i-j;
  repeat
    if j=0 then
      StrCopyW(p,p+i)
    else
    begin
      k:=(StrLenW(p)+1)*SizeOf(WideChar);
      if l>0 then
        move((p+l)^,p^,k-l*SizeOf(WideChar))
      else if l<>0 then
        move(p^,(p-l)^,k);
      move(NewStr^,p^,j*SizeOf(WideChar)); {new characters}
      inc(p,j);
    end;
    p:=StrPosW(p,SubStr);
    if p=nil then break;
  until false;
end;

function CharReplace(dst:pAnsiChar;old,new:AnsiChar):PAnsiChar;
begin
  result:=dst;
  if dst<>nil then
  begin
    while dst^<>#0 do
    begin
      if dst^=old then dst^:=new;
      inc(dst);
    end;
  end;
end;

function CharReplaceW(dst:pWideChar;old,new:WideChar):PWideChar;
begin
  result:=dst;
  if dst<>nil then
  begin
    while dst^<>#0 do
    begin
      if dst^=old then dst^:=new;
      inc(dst);
    end;
  end;
end;

function StrCmp(a,b:PAnsiChar;n:cardinal=$FFFFFFFF):integer; // CompareString
begin
  result:=0;
  if (a=nil) and (b=nil) then
    exit;
  if (a=nil) or (b=nil) then
  begin
    result:=-1;
    exit;
  end;
  while n>0 do
  begin
    result:=ord(a^)-ord(b^);
    if (result<>0) or (a^=#0) then
      break;
    inc(a);
    inc(b);
    dec(n);
  end;
end;

function StrCmpW(a,b:PWideChar;n:cardinal=$FFFFFFFF):integer;
begin
  result:=0;
  if (a=nil) and (b=nil) then
    exit;
  if (a=nil) or (b=nil) then
  begin
    result:=-1;
    exit;
  end;
  while n>0 do
  begin
    result:=ord(a^)-ord(b^);
    if (result<>0) or (a^=#0) then
      break;
    inc(a);
    inc(b);
    dec(n);
  end;
end;

function StrEnd(const a:PAnsiChar):PAnsiChar;
begin
  result:=a;
  if result<>nil then
    while result^<>#0 do inc(result);
end;

function StrEndW(const a:PWideChar):PWideChar;
begin
  result:=a;
  if result<>nil then
    while result^<>#0 do inc(result);
end;

function StrScan(src:PAnsiChar;c:AnsiChar):PAnsiChar;
begin
  if src<>nil then
  begin
    while (src^<>#0) and (src^<>c) do inc(src);
    if src^<>#0 then
    begin
      result:=src;
      exit;
    end;
  end;
  result:=nil;
end;

function StrRScan(src:PAnsiChar;c:AnsiChar):PAnsiChar;
begin
  if src<>nil then
  begin
    result:=StrEnd(src);
    while (result>=src) and (result^<>c) do dec(result);
    if result<src then
      result:=nil;
  end
  else
    result:=nil;
end;

function StrScanW(src:PWideChar;c:WideChar):PWideChar;
begin
  if src<>nil then
  begin
    while (src^<>#0) and (src^<>c) do inc(src);
    if src^<>#0 then
    begin
      result:=src;
      exit;
    end;
  end;
  result:=nil;
end;

function StrRScanW(src:PWideChar;c:WideChar):PWideChar;
begin
  if src<>nil then
  begin
    result:=StrEndW(src);
    while (result>=src) and (result^<>c) do dec(result);
    if result<src then
      result:=nil;
  end
  else
    result:=nil;
end;

function StrLen(Str: PAnsiChar): Cardinal;
var
  P : PAnsiChar;
begin
  P := Str;
  if P<>nil then
    while (P^ <> #0) do Inc(P);
  Result := (P - Str);
end;

function StrLenW(Str: PWideChar): Cardinal;
var
  P : PWideChar;
begin
  P := Str;
  if P<>nil then
    while (P^ <> #0) do Inc(P);
  Result := (P - Str);
end;

function StrCat(Dest: PAnsiChar; const Source: PAnsiChar): PAnsiChar;
begin
  if dest<>nil then
    StrCopy(StrEnd(Dest), Source);
  Result := Dest;
end;

function StrCatW(Dest: PWideChar; const Source: PWideChar): PWideChar;
begin
  if dest<>nil then
    StrCopyW(StrEndW(Dest), Source);
  Result := Dest;
end;

function StrPos(const aStr, aSubStr: PAnsiChar): PAnsiChar;
var
  Str, SubStr: PAnsiChar;
  Ch: AnsiChar;
begin
  if (aStr = nil) or (aStr^ = #0) or (aSubStr = nil) or (aSubStr^ = #0) then
  begin
    Result := nil;
    Exit;
  end;
  Result := aStr;
  Ch := aSubStr^;
  repeat
    if Result^ = Ch then
    begin
      Str := Result;
      SubStr := aSubStr;
      repeat
        Inc(Str);
        Inc(SubStr);
        if SubStr^ = #0 then exit;
        if Str^ = #0 then
        begin
          Result := nil;
          exit;
        end;
        if Str^ <> SubStr^ then break;
      until (FALSE);
    end;
    Inc(Result);
  until (Result^ = #0);
  Result := nil;
end;

function StrIndex(const aStr, aSubStr: PAnsiChar):integer;
var
  p:pAnsiChar;
begin
  p:=StrPos(aStr,aSubStr);
  if p=nil then
    result:=0
  else
    result:=p-aStr+1;
end;

function StrPosW(const aStr, aSubStr: PWideChar): PWideChar;
var
  Str, SubStr: PWideChar;
  Ch: WideChar;
begin
  if (aStr = nil) or (aStr^ = #0) or (aSubStr = nil) or (aSubStr^ = #0) then
  begin
    Result := nil;
    Exit;
  end;
  Result := aStr;
  Ch := aSubStr^;
  repeat
    if Result^ = Ch then
    begin
      Str := Result;
       SubStr := aSubStr;
      repeat
        Inc(Str);
        Inc(SubStr);
        if SubStr^ = #0 then exit;
        if Str^ = #0 then
        begin
          Result := nil;
          exit;
        end;
        if Str^ <> SubStr^ then break;
      until (FALSE);
    end;
    Inc(Result);
  until (Result^ = #0);
  Result := nil;
end;

function StrIndexW(const aStr, aSubStr: PWideChar):integer;
var
  p:pWideChar;
begin
  p:=StrPosW(aStr,aSubStr);
  if p=nil then
    result:=0
  else
    result:=(p-aStr)+1; //!!!!
end;

end.

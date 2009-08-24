(*
 Pseudo-XML tokens' encode/decode unit
 (c) 2008-2009 Alexander Kornienko AKA Korney San

 1.1 (01.10.2008)
 [-] Fixed reading token with empty value

 1.2 (10.02.2008)
 [+] Added CopyToken function

 1.3 (05.03.2009)
 [+] Added ReplaceToken procedure

 1.4 (27.03.2009)
 [+] Added TokenExist function
 [+] Added DeleteToken procedure

 1.5 (24.08.2009)
 [+] Added TagExist function
*)
unit Tokens;

interface

uses
 Classes;

function ExtractToken(Token: String; SearchString: WideString): WideString;
function EncodeToken(Token, Value: String): WideString;
function CopyToken(Token: String; SearchString: WideString): WideString;
procedure ReplaceToken(Token, Value: String; var SearchString: WideString);
function TokenExist(Token: String; SearchString: WideString): Boolean;
procedure DeleteToken(Token: String; var SearchString: WideString);
//
procedure ExtractTokenAttributes(Token: String; var SearchString: WideString; var Result: Widestring; var Attributes: TStrings);
function EncodeTokenAttributes(Token: String; Value: WideString = ''; Attributes: TStrings = nil): WideString;
//
function TagExist(Token: String; SearchString: WideString; Closing: Boolean = false): Boolean;

implementation

function ExtractToken(Token: String; SearchString: WideString): WideString;
var
 b, k, l: Integer;
begin
 b:=Pos('<'+Token+'>', SearchString);
 if b=0 then
   Result:=''
 else
  begin
   l:=Length('<'+Token+'>');
   k:=Pos('</'+Token+'>', SearchString);
   if k=0 then
     Result:=Copy(SearchString, b+l, Length(SearchString))
   else
     if k<b then
       Result:=''
     else
       Result:=Copy(SearchString, b+l, k-b-l);
  end;
end;

function EncodeToken(Token, Value: String): WideString;
begin
 if (Token='') or (Value='') then
   Result:=''
 else
   Result:='<'+Token+'>'+Value+'</'+Token+'>';
end;

function CopyToken(Token: String; SearchString: WideString): WideString;
begin
 Result:=EncodeToken(Token, ExtractToken(Token, SearchString));
end;

procedure ReplaceToken(Token, Value: String; var SearchString: WideString);
var
 b, k, l: Integer;
begin
 b:=Pos('<'+Token+'>', SearchString);
 if b>0 then
  begin
   l:=Length('<'+Token+'>');
   k:=Pos('</'+Token+'>', SearchString);
   if k>=b+l then
    begin
     Delete(SearchString, b+l, k-b-l);
     Insert(Value, SearchString, b+l);
    end;
  end;
end;

function TokenExist(Token: String; SearchString: WideString): Boolean;
var
 b, k, l: Integer;
begin
 Result:=false;
 b:=Pos('<'+Token+'>', SearchString);
 if b>0 then
  begin
   l:=Length('<'+Token+'>');
   k:=Pos('</'+Token+'>', SearchString);
   Result:=k>=b+l;
  end;
end;

procedure DeleteToken(Token: String; var SearchString: WideString);
var
 b, k, l: Integer;
begin
 b:=Pos('<'+Token+'>', SearchString);
 if b>0 then
  begin
   l:=Length('<'+Token+'>');
   k:=Pos('</'+Token+'>', SearchString);
   if k>=b+l then
    begin
     Delete(SearchString, b+l, k-b-l);
    end;
  end;
end;

procedure GetAttributes(InStr: WideString; var Attributes: TStrings);
 var
  s: WideString;
  attrname, attrvalue: WideString;
begin
 Attributes.Clear;
 s:=InStr;
 repeat
  while (Length(s)>0) and (s[1]=' ') do //удаляем начальные пробелы (по идее, всегда один)
    Delete(s, 1, 1);
  attrname:='';
  while (Length(s)>0) and (s[1]<>'=') do //всё что до = это имя атрибута
   begin
    attrname:=attrname+s[1];
    Delete(s, 1, 1);
   end;
  Delete(s, 1, 1); //удаляем само =
  attrvalue:='';
  if (Length(s)>0) and (s[1]='"') then //кавычки - в значении есть пробел(ы)
   begin
    Delete(s, 1, 1); //удаляем открывающую кавычку
    while (Length(s)>0) and (s[1]<>'"') do //всё что до кавычки это значение атрибута
     begin
      attrvalue:=attrvalue+s[1];
      Delete(s, 1, 1);
     end;
    if (Length(s)>0) and (s[1]='"') then //удаляем закрывающую кавычку
      Delete(s, 1, 1);
   end
  else //пробелов в значении нет
   begin
    while (Length(s)>0) and (s[1]<>' ') do //всё что до пробела это значение атрибута
     begin
      attrvalue:=attrvalue+s[1];
      Delete(s, 1, 1);
     end; //сам пробел удалится в следующем цикле
   end;
  if (attrname<>'') and (attrvalue<>'') then //если есть имя и значение атрибута - заносим в список
    Attributes.Add(attrname+'='+attrvalue);
 until s='';
end;

procedure ExtractTokenAttributes(Token: String; var SearchString: WideString; var Result: Widestring; var Attributes: TStrings);
 var
  tb, tk, k: Integer;
  TokenLength: Integer;
  TokenAfterIndex: Integer;
  TokenEndLength: Integer;
begin
 Result:='';
 TokenLength:=Length('<'+Token);
 tb:=Pos('<'+Token, SearchString);
 if tb>0 then
  begin
   TokenAfterIndex:=tb+TokenLength;
   tk:=Pos('>', SearchString);
   k:=Pos('</'+Token+'>', SearchString);
   TokenEndLength:=Length('</'+Token+'>');
   if k=0 then
    begin
     k:=Pos('/>', SearchString);
     TokenEndLength:=Length('/>');
    end;
   if k=0 then
    begin
     if tk>=TokenAfterIndex then
      begin
       Result:=Copy(SearchString, tk+1, Length(SearchString));
       GetAttributes(Copy(SearchString, TokenAfterIndex, TokenAfterIndex-tk), Attributes);
       Delete(SearchString, tb, Length(SearchString));
      end;
    end
   else
    begin
     if (tk>=TokenAfterIndex) then
      begin
       if tk<k then  //токен вида <token name="prop">value</token>
        begin
         Result:=Copy(SearchString, tk+1, k-tk-1);
         GetAttributes(Copy(SearchString, TokenAfterIndex, tk-TokenAfterIndex), Attributes);
         Delete(SearchString, tb, k+TokenEndLength-tb);
        end
       else //токен вида <token name="prop"/>
        begin
         Result:='';
         GetAttributes(Copy(SearchString, TokenAfterIndex, k-TokenAfterIndex), Attributes);
         Delete(SearchString, tb, k+TokenEndLength-tb);
        end;
      end;
    end;
  end;
end;

function EncodeTokenAttributes(Token: String; Value: WideString = ''; Attributes: TStrings = nil): WideString;
 var
  attrname, attrvalue: String;
  i: Integer;
begin
 Result:='';
 if (Value<>'') or Assigned(Attributes) then
  begin
   Result:='<'+Token;
   if Assigned(Attributes) then
    begin
     for i:=0 to Attributes.Count-1 do
      begin
       attrname:=Attributes.Names[i];
       attrvalue:=Attributes.ValueFromIndex[i];
       if (Length(attrvalue)>0) and (attrvalue[1]<>'"') then
         attrvalue:='"'+attrvalue+'"';
       if (attrname<>'') and (attrvalue<>'') then
         Result:=Result+' '+attrname+'='+attrvalue;
      end;
    end;
   if Value='' then
     Result:=Result+'/>'
   else
     Result:=Result+'>'+Value+'</'+Token+'>';
  end;
end;

function TagExist(Token: String; SearchString: WideString; Closing: Boolean = false): Boolean;
var
 b, k, l: Integer;
begin
 if Closing then
   b:=Pos('</'+Token+'>', SearchString)
 else
   b:=Pos('<'+Token+'>', SearchString);
 Result:=b>0;
end;

end.

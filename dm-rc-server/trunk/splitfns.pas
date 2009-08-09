unit splitfns;

interface

uses Classes, Sysutils, StrUtils;

function GetNextToken(Const S: string; Separator: TSysCharSet; var StartPos: integer): String;

function GetStringBetween(const GetFrom, aStartString, aEndString: string): string; 

{Returns the next token (substring) from string S, starting at index StartPos and ending 1 character
before the next occurrence of Separator (or at the end of S, whichever comes first).}

{StartPos returns the starting position for the next token, 1 more than the position in S of
the end of this token}

procedure Split(const S: String; Separator: TSysCharSet; MyStringList: TStringList);
{Splits a string containing designated separators into tokens and adds them to MyStringList NOTE: MyStringList must be Created before being passed to this procedure and Freed after use}

function AddToken (const aToken, S: String; Separator: Char; StringLimit: integer): String;
{Used to join 2 strings with a separator character between them and can be used in a Join function}
{The StringLimit parameter prevents the length of the Result String from exceeding a preset maximum}

 

implementation

function GetNextToken(Const S: string; Separator: TSysCharSet; var StartPos: integer): String;
var
  Index: integer;
begin
  Result := '';
  {Step over repeated separators}
  While (S[StartPos] in Separator) and (StartPos <= length(S)) do StartPos := StartPos + 1;

  if StartPos > length(S) then Exit;

  {Set Index to StartPos}
  Index := StartPos;

  {Find the next Separator}
  While not (S[Index] in Separator) and (Index <= length(S))do Index := Index + 1;

  {Copy the token to the Result}
  Result := Copy(S, StartPos, Index - StartPos);

  {SetStartPos to next Character after the Separator}
  StartPos := Index + 1;
end;
//-----------------------------------------------------------------------------
procedure Split(const S: String; Separator: TSysCharSet; MyStringList: TStringList);
var
  Start: integer;
begin
  Start := 1;
  While Start <= Length(S) do MyStringList.Add(GetNextToken(S, Separator, Start));
end;
//-----------------------------------------------------------------------------
function AddToken (const aToken, S: String; Separator: Char; StringLimit: integer): String;
begin
  if Length(aToken) + Length(S) < StringLimit then
  begin
    {Add a separator unless the Result string is empty}
    if S = '' then Result := '' else Result := S + Separator;

    {Add the token}
    Result := Result + aToken;
  end else Raise Exception.Create('Cannot add token');
  {if the StringLimit would be
  exceeded, raise an exception}
end;
//-----------------------------------------------------------------------------
function GetStringBetween(const GetFrom, aStartString, aEndString: string): string;
var
  IndStart: integer;
  IndEnd: integer;
begin
  IndStart := AnsiPos(aStartString, GetFrom) + Length(aStartString);
  IndEnd   := PosEx(aEndString, GetFrom, IndStart);
  //if IndEnd = 0 then ShowMessage(aEndString);
  Result   := Copy(GetFrom, IndStart, IndEnd - IndStart);
end;

end. 



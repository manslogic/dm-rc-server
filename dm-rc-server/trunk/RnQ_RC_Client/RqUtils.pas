unit RqUtils;

interface

uses sysutils, types, ExtCtrls, Classes, windows, Graphics, StrUtils, CallExec,
  plugin, pluginutil, Dialogs;

function RQ_IsInCL(uin: string): boolean;
function RQ_AddTabSheet(aTabCaption: string; aTabIcon: TIcon;
  aTabHandle: HWND): Integer;
function RQ_GetChatRect: TRect;
function RQ_AddUinToList(List:integer; uin: integer):integer;
procedure RQ_AddMessage(aUIN: integer; aMsg: string);
procedure RQ_AddToInput(aMsg: string);

implementation

function RQ_IsInCL(uin: string): boolean;
var
  uini, i: integer;
  list: TIntegerDynArray;
begin
  uini := StrToInt(uin);
  list := RQ_GetList(PL_ROASTER);
  result := false;

  for i := 0 to  HIGH(list) do
  begin
    if list[i] = uini then
    begin
      result := true;
      break;
    end;
  end;

  list := nil;
end;
//-----------------------------------------------------------------------------
function RQ_AddTabSheet(aTabCaption: string; aTabIcon: TIcon;
  aTabHandle: HWND): Integer;
var
  data: Pointer;
begin
  data   := callStr(char(PM_CMD)+char(PC_TAB_ADD)+_int(Integer(aTabHandle))
    + _int(Integer(aTabIcon.Handle))+_istring(aTabCaption));
  Result := _int_at(data, 4);
end;
//-----------------------------------------------------------------------------
function RQ_GetChatRect: TRect;
var
  data: Pointer;
  res:  TintegerDynArray;
begin
  data          := CallStr(char(PM_GET)+char(PG_CHAT_XYZ));
  res           := _intlist_at(data,5);
  result.Top    := res[0];
  result.Left   := res[1];
  result.Right  := res[2];
  result.Bottom := res[3];
end;
//-----------------------------------------------------------------------------
function  RQ_AddUinToList(List:integer; uin: integer):integer;
var
  uins: TIntegerDynArray;
begin
  SetLength(uins, 1);
  uins[0] := uin;

  callStr(char(PM_CMD)+char(PC_LIST_ADD)+char(List)+_intlist(uins));

  uins := nil;
end;
//-----------------------------------------------------------------------------
procedure RQ_AddMessage(aUIN: integer; aMsg: string);
begin
  callStr(char(PM_CMD)+char(PC_ADD_MSG)+_int(aUIN)+_dt(now)+_istring(aMsg));
end;
//-----------------------------------------------------------------------------
procedure RQ_AddToInput(aMsg: string);
begin
  callStr(char(PM_CMD)+char(PC_ADD_TO_INPUT)+_istring(aMsg));
end;




end.

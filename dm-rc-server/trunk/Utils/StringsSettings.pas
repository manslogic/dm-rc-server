(*
 Universal Settings System (USS) type 3
 (c) 2008-2009 Alexander Kornienko AKA Korney San

 1.0 (08.09.2008)
 [+] Initial release

 1.1 (22.09.2008)
 [!] GetAnyValue/SetAnyValue merged into array property with variant reference
     (allows to access by name or index)
     Idea is taken from USS type 2

 1.2 (01.10.2008)
 [+] Ability to load/save only one value by name
 [+] Ability to set value as non-exists which means that absense of value
     does NOT produce an error when reading file

 1.3 (27.11.2008)
 [+] Ability to set value as non-saveable (still can be read as non-exists);
     this type overload "non-exists"

 1.4 (05.03.2009)
 [*] GetAnyValue separated to GetValue with ability to return value of property
     and GetAnyValue with return of value itself
 [+] Function GetMin to read Min of Value
 [+] Function GetMax to read Max of Value
 [+] Function GetDef to read Default of Value
 [+] ReadOnly array properties of Value: Min, Max, Def

 2.0 (27.03.2009)
 [-] AddAnyValue always return -1
 [*] AddAnyValue return -2 on empty AName
 [+] GetAnyValue can return Type as TVarType
 [+] Support a group of similar values with couple of procedures
 [+] Property Group to read/write group values by their group index
 [+] Procedure SingleTokenInGroupValue for single default token in group values
 [-] GetValue vith value property now return Null if property does not exist

 2.1 (06.05.2009)
 [+] Load/Save from/to Registry
 [*] Changed TIniFile to TMemIniFile

 2.2 (20.05.2009)
 [+] GroupList procedure to dump all group in list
 [+] GroupTokenList procedure to dump token values from group values to list
 [+] GroupTokenIndex function to find group index of defined token value
 [+] Section property into GetValue property read
 [*] GetValue(xxx, GroupSection) now return Section property if GroupSection does not exists
 [-] Null result of GetValue force GroupSection property to be "0" in AddValueToGroup
 [*] GetGroup/SetGroup has string parameter AGroupName instead of variant Ref

 2.3 (26.07.2009)
 [+] Load/Save to XML through JEDI JCL library (JclSimpleXML)

 2.4 (29.07.2009)
 [*] GroupList return only values by default
 [-] SaveValuesTo* now clean all values in storage that are no longer needed   
*)

unit StringsSettings;

{.$DEFINE USE_JEDI} //remove dot to enable XML support

interface

uses
 Classes,
 Registry,
 IniFiles,
 {$IFDEF USE_JEDI}
 JclSimpleXml,
 {$ENDIF}
 Variants;

type
 TStringsSettings = class (TStringList)
   function AddAnyValue(AName: String; AType: TVarType; ADefault, AMin, AMax: Variant; ASection: String = ''; NonExist: Boolean = false; NonSave: Boolean = false): Integer;
   //
   function AddGroup(AGroupName: String; AGroupDefault, AGroupMax: Integer; AType: TVarType; ADefault, AMin, AMax: Variant; AGroupSection: String = ''; AValueSection: String = ''; ValueNonExist: Boolean = false): Integer;
   function AddValueToGroup(AGroupName: String; AValue: Variant): Integer;
   function DeleteValueFromGroup(AGroupName: String; Idx: Integer): Integer;
   procedure SingleTokenInGroupValue(AGroupName, AToken: String; Idx: Integer; TokenValue: String = '');
   //
   procedure GroupTokenList(AGroupName, AToken: String; List: TStrings);
   function GroupTokenIndex(AGroupName, AToken: String; AValue: String): Integer;
   //
   constructor Create;
   procedure Free;
   procedure CopyValues(Source: TStringsSettings);
  private
   Props: TStrings;
   //
   function AddGroupCounter(AName: String; ADefault, AMax: Integer; AValueType: TVarType; AValueDefault, AValueMin, AValueMax: Variant; ASection: String = ''; AValueSection: String = ''; AValueNonExist: Boolean = false): Integer;
   function AddGroupValues(ASection, AName: String; ACount:Integer; AType: TVarType; ADefault, AMin, AMax: Variant; NonExist: Boolean = false): Integer;
   procedure ReindexGroup(AGroupName: String);
   //
   function GetValue(Ref: Variant; Prop: String = ''): Variant;
   function GetAnyValue(Ref: Variant): Variant;
   procedure SetAnyValue(Ref: Variant; AValue: Variant);
   function GetMin(Ref: Variant): Variant;
   function GetMax(Ref: Variant): Variant;
   function GetDef(Ref: Variant): Variant;
   //
   function GetGroup(AGroupName: String; Idx: Integer): Variant;
   procedure SetGroup(AGroupName: String; Idx: Integer; AValue: Variant);
  public
   function LoadValuesFromIni(Ini: TMemIniFile; OnlyValue: String = ''): Integer; overload;
   function LoadValuesFromIni(Filename: String; OnlyValue: String = ''): Integer; overload;
   procedure SaveValuesToIni(Ini: TMemIniFile; OnlyValue: String = ''); overload;
   procedure SaveValuesToIni(Filename: String; OnlyValue: String = ''); overload;
   //
   function LoadValuesFromReg(Reg: TRegIniFile; RegPath: String = ''; OnlyValue: String = ''): Integer; overload;
   function LoadValuesFromReg(RegPath: String = ''; OnlyValue: String = ''): Integer; overload;
   procedure SaveValuesToReg(Reg: TRegIniFile; RegPath: String = ''; OnlyValue: String = ''); overload;
   procedure SaveValuesToReg(RegPath: String = ''; OnlyValue: String = ''); overload;
   {$IFDEF USE_JEDI}
   //
   function LoadValuesFromXML(XML: TJclSimpleXML; OnlyValue: String = ''): Integer; overload;
   function LoadValuesFromXML(AFilename: String; OnlyValue: String = ''): Integer; overload;
   procedure SaveValuesToXML(XML: TJclSimpleXML; OnlyValue: String = ''); overload;
   procedure SaveValuesToXML(AFilename: String; OnlyValue: String = ''); overload;
   {$ENDIF}
   //
   procedure GroupList(Ref: Variant; List: TStrings; All: Boolean = false);
   //
   property AnyValue[Ref: Variant]: Variant read GetAnyValue write SetAnyValue; default;
   //
   property Min[Ref: Variant]: Variant read GetMin;
   property Max[Ref: Variant]: Variant read GetMax;
   property Def[Ref: Variant]: Variant read GetDef;
   //
   property Group[AGroupName: String; Idx: Integer]: Variant read GetGroup write SetGroup;
 end;

const
 cDefaultSection = 'Settings';
 ctagValue = 'value';
 varDateOnly = $80;
 varTimeOnly = $81;

 AvailableTypes: set of byte = [varInteger, varCurrency, varDouble, varDate, varOleStr, varBoolean, varWord, varLongWord, varStrArg, varDateOnly, varTimeOnly];
 EmptyTypes: set of byte = [varEmpty, varNull];
 DateTimeTypes: set of Byte = [varDate, varDateOnly, varTimeOnly];
 DoubleTypes: set of byte = [varCurrency, varDouble];

 vreOK = 0;
 vreInvalidIni = 1;
 vreFileNotFound = 2;
 vreValueNotFound = 3;
 //
 vreInvalidReg = 4;
 {$IFDEF USE_JEDI}
 //
 vreInvalidXML = 5;
 {$ENDIF}

implementation

uses
 //Dialogs, //debug
 SysUtils,
 Tokens;

const
 cpropSection = 'section';
 cpropType = 'type';
 cpropDefault = 'default';
 cpropMin = 'min';
 cpropMax = 'max';
 cpropNonExist = 'nonexist';
 cpropNonSave = 'nonsave';
 //
 cpropGroup = 'group';
 cpropGroupSection = 'groupsection';
 cpropGroupType = 'grouptype';
 cpropGroupDefault = 'groupdefault';
 cpropGroupMin = 'groupmin';
 cpropGroupMax = 'groupmax';
 cpropGroupNonExist = 'groupnonexist';

 ctypeBoolean = 'BOOL';
 ctypeDate = 'DATE';
 ctypeDateTime = 'DTTM';
 ctypeDouble = 'DBLE';
 ctypeInteger = 'INTG';
 ctypeLongWord = 'LWRD';
 ctypeString = 'STRN';
 ctypeTime = 'TIME';
 ctypeWord = 'WORD';

 {Helpers}

function GetStringFromValue(AType: TVarType; Value: Variant): String;
begin
 case AType of
  varBoolean:
   begin
    Result:=BoolToStr(Value);
   end;
  varDateOnly:
   begin
    Result:=DateToStr(Value);
   end;
  varDate:
   begin
    Result:=DateTimeToStr(Value);
   end;
  varDouble:
   begin
    Result:=FloatToStr(Value);
   end;
  varInteger:
   begin
    Result:=IntToStr(Value);
   end;
  varLongWord:
   begin
    Result:=IntToStr(Value);
   end;
  varString:
   begin
    Result:=Value;
   end;
  varTimeOnly:
   begin
    Result:=TimeToStr(Value);
   end;
  varWord:
   begin
    Result:=IntToStr(Value);
   end;
  end;
end;

function ATypeAsVarType(AType: Integer): Integer;
begin
 if (AType in AvailableTypes) or (AType=varString) or (AType in EmptyTypes) then
  begin
   if AType in DateTimeTypes then
     Result:=varDate
   else
       Result:=AType;
  end
 else
   Result:=varNull;
end;

function FixedVarType(AValue: Variant): TVarType;
begin
 Result:=VarType(AValue);
 if Result in DoubleTypes then
   Result:=varDouble;
end;

function IsCorrectType(AType: TVarType; AValue: Variant): Boolean;
begin
 Result:=FixedVarType(AValue)=ATypeAsVarType(AType);
end;

function PropType2AType(PropType: String): Integer;
begin
 Result:=varEmpty;
 if PropType=ctypeBoolean then
   Result:=varBoolean;
 if PropType=ctypeDate then
   Result:=varDateOnly;
 if PropType=ctypeDateTime then
   Result:=varDate;
 if PropType=ctypeDouble then
   Result:=varDouble;
 if PropType=ctypeInteger then
   Result:=varInteger;
 if PropType=ctypeLongWord then
   Result:=varLongWord;
 if PropType=ctypeString then
   Result:=varString;
 if PropType=ctypeTime then
   Result:=varTimeOnly;
 if PropType=ctypeWord then
   Result:=varWord;
end;

 {TStringsSettings}

constructor TStringsSettings.Create;
begin
 inherited;
 Props:=TStringList.Create;
end;

procedure TStringsSettings.Free;
begin
 Props.Free;
 inherited;
end;

function TStringsSettings.AddAnyValue(AName: String; AType: TVarType; ADefault, AMin, AMax: Variant; ASection: String = ''; NonExist: Boolean = false; NonSave: Boolean = false): Integer;
 var
  s, v: String;
  defv, maxv, minv: Variant;
begin
 Result:=-1;
 defv:=VarAsType(ADefault, ATypeAsVarType(AType));
 if VarType(AMax) in EmptyTypes then
   maxv:=Unassigned
 else
   maxv:=VarAsType(AMax, ATypeAsVarType(AType));
 if VarType(AMin) in EmptyTypes then
   minv:=Unassigned
 else
   minv:=VarAsType(AMin, ATypeAsVarType(AType));
 if (AName<>'') then
  begin
   if (IndexOfName(AName)<0) then
   if ((AType in AvailableTypes) or (AType=VarString)) then
   if ((VarType(defv) in AvailableTypes) or (VarType(defv)=varString)) then
    begin
     Props.Clear;
     if ASection='' then
      s:=cpropSection+'='+cDefaultSection
     else
      s:=cpropSection+'='+ASection;
     Props.Add(s);
     case AType of
      varBoolean:
       begin
        s:=cpropType+'='+ctypeBoolean;
       end;
      varDateOnly:
       begin
        s:=cpropType+'='+ctypeDate;
       end;
      varDate:
       begin
        s:=cpropType+'='+ctypeDateTime;
       end;
      varDouble, varCurrency:
       begin
        s:=cpropType+'='+ctypeDouble;
       end;
      varInteger:
       begin
        s:=cpropType+'='+ctypeInteger;
       end;
      varLongWord:
       begin
        s:=cpropType+'='+ctypeLongWord;
       end;
      varString:
       begin
        s:=cpropType+'='+ctypeString;
       end;
      varTimeOnly:
       begin
        s:=cpropType+'='+ctypeTime;
       end;
      varWord:
       begin
        s:=cpropType+'='+ctypeWord;
       end;
      else
       s:='';
      end;
     if s<>'' then
       Props.Add(s);
     if IsCorrectType(AType, defv) then
      begin
       v:=GetStringFromValue(AType, defv);
       s:=cpropDefault+'='+v;
       Props.Add(s);
       if IsCorrectType(AType, minv) then
        begin
         s:=cpropMin+'='+GetStringFromValue(AType, minv);
         Props.Add(s);
        end;
       if IsCorrectType(AType, maxv) then
        begin
         s:=cpropMax+'='+GetStringFromValue(AType, maxv);
         Props.Add(s);
        end;
       if NonExist and not NonSave then
         Props.Add(cpropNonExist+'=1');
       if NonSave then
         Props.Add(cpropNonSave+'=1');
       Result:=Add(AName+'='+EncodeTokenAttributes(ctagValue, v, Props));
      end;
    end;
  end
 else
  begin
   //ShowMessage(VarTypeAsText(VarType(defv)));
   Result:=-2;
  end;
end;

function TStringsSettings.AddGroupCounter(AName: String; ADefault, AMax: Integer; AValueType: TVarType; AValueDefault, AValueMin, AValueMax: Variant; ASection: String = ''; AValueSection: String = ''; AValueNonExist: Boolean = false): Integer;
 var
  Default: Integer;
  s, v: String;
  defv, maxv, minv: Variant;
begin
 Result:=-1;
 if AName='' then
   Result:=-2
 else
  begin
   defv:=VarAsType(AValueDefault, ATypeAsVarType(AValueType));
   if VarType(AValueMax) in EmptyTypes then
     maxv:=Unassigned
   else
     maxv:=VarAsType(AValueMax, ATypeAsVarType(AValueType));
   if VarType(AValueMin) in EmptyTypes then
     minv:=Unassigned
   else
     minv:=VarAsType(AValueMin, ATypeAsVarType(AValueType));
   //
   if (IndexOfName(AName)<0) and (AMax>0) then
    begin
     Props.Clear;
     //define section
     if ASection='' then
      s:=cpropSection+'='+cDefaultSection
     else
      s:=cpropSection+'='+ASection;
     Props.Add(s);
     //integer
     s:=cpropType+'='+ctypeInteger;
     Props.Add(s);
     //default
     Default:=ADefault;
     if Default<0 then
       Default:=0;
     if Default>AMax then
       Default:=AMax;
     s:=cpropDefault+'='+IntToStr(Default);
     Props.Add(s);
     //min = 0
     s:=cpropMin+'=0';
     Props.Add(s);
     //
     s:=cpropMax+'='+IntToStr(AMax);
     Props.Add(s);
     //mark as group
     Props.Add(cpropGroup+'=1');
     //add group defines
     if AValueSection<>'' then
       Props.Add(cpropGroupSection+'='+AValueSection);
     case AValueType of
      varBoolean:
       begin
        s:=cpropGroupType+'='+ctypeBoolean;
       end;
      varDateOnly:
       begin
        s:=cpropGroupType+'='+ctypeDate;
       end;
      varDate:
       begin
        s:=cpropGroupType+'='+ctypeDateTime;
       end;
      varDouble, varCurrency:
       begin
        s:=cpropGroupType+'='+ctypeDouble;
       end;
      varInteger:
       begin
        s:=cpropGroupType+'='+ctypeInteger;
       end;
      varLongWord:
       begin
        s:=cpropGroupType+'='+ctypeLongWord;
       end;
      varString:
       begin
        s:=cpropGroupType+'='+ctypeString;
       end;
      varTimeOnly:
       begin
        s:=cpropGroupType+'='+ctypeTime;
       end;
      varWord:
       begin
        s:=cpropGroupType+'='+ctypeWord;
       end;
      else
       s:='';
      end;
     if s<>'' then
       Props.Add(s);
     if IsCorrectType(AValueType, defv) then
      begin
       v:=GetStringFromValue(AValueType, defv);
       s:=cpropGroupDefault+'='+v;
       Props.Add(s);
       if IsCorrectType(AValueType, minv) then
        begin
         s:=cpropGroupMin+'='+GetStringFromValue(AValueType, minv);
         Props.Add(s);
        end;
       if IsCorrectType(AValueType, maxv) then
        begin
         s:=cpropGroupMax+'='+GetStringFromValue(AValueType, maxv);
         Props.Add(s);
        end;
      end;
     if AValueNonExist then
       Props.Add(cpropGroupNonExist+'=1');
     //add all value
     Result:=Add(AName+'='+EncodeTokenAttributes(ctagValue, IntToStr(Default), Props));
    end;
  end;
end;

function TStringsSettings.AddGroup(AGroupName: String; AGroupDefault, AGroupMax: Integer; AType: TVarType; ADefault, AMin, AMax: Variant; AGroupSection: String = ''; AValueSection: String = ''; ValueNonExist: Boolean = false): Integer;
 var
  ValueSection: String;
begin
 if (AGroupName='') or (AGroupMax<1) then
   Result:=-2
 else
  begin
   Result:=AddGroupCounter(AGroupName, AGroupDefault, AGroupMax, AType, ADefault, AMin, AMax, AGroupSection, AValueSection, ValueNonExist);
   if Result>=0 then
    begin
     if AValueSection='' then
       ValueSection:=AGroupSection
     else
       ValueSection:=AValueSection;
     if AGroupDefault<=AGroupMax then
       AddGroupValues(ValueSection, AGroupName, AGroupDefault, AType, ADefault, AMin, AMax, ValueNonExist)
     else
       AddGroupValues(ValueSection, AGroupName, AGroupMax, AType, ADefault, AMin, AMax, ValueNonExist);
    end;
  end;
end;

function TStringsSettings.AddGroupValues(ASection, AName: String; ACount:Integer; AType: TVarType; ADefault, AMin, AMax: Variant; NonExist: Boolean = false): Integer;
 var
  i: Integer;
begin
 Result:=-1;
 for i:=0 to ACount-1 do
  begin
   Result:=AddAnyValue(AName+IntToStr(i), AType, ADefault, AMin, AMax, ASection, NonExist);
  end;
end;

function TStringsSettings.AddValueToGroup(AGroupName: String; AValue: Variant): Integer;
 var
  i, gc, gm: Integer;
  ValueDef: Variant;
  ValueSection: String;
begin
 Result:=-1;
 if GetValue(AGroupName, cpropGroup) then //really a group
  begin
   gc:=GetValue(AGroupName); //get amount of group members
   gm:=GetValue(AGroupName, cpropMax); //get maximum
   if gc<gm then
    begin
     Inc(gc);
     ValueDef:=GetValue(AGroupName, cpropGroupDefault);
     if VarType(ValueDef)=varNull then
       ValueDef:=Unassigned;
     ValueSection:=GetValue(AGroupName, cpropGroupSection);
     if (ValueSection='') or (ValueSection='0') then //Null protection
       ValueSection:=GetValue(AGroupName, cpropSection);
     if ValueSection='0' then //Null protection
       ValueSection:='';
     i:=AddAnyValue(AGroupName+IntToStr(gc), GetValue(AGroupName, cpropGroupType), ValueDef, GetValue(AGroupName, cpropGroupMin), GetValue(AGroupName, cpropGroupMax), ValueSection, GetValue(AGroupName, cpropGroupNonExist));
     if i>=0 then
      begin
       SetAnyValue(i, AValue);
       SetAnyValue(AGroupName, gc);
       Result:=gc;
      end;
    end;
  end;
end;

function TStringsSettings.DeleteValueFromGroup(AGroupName: String; Idx: Integer): Integer;
 var
  i, gc: Integer;
begin
 Result:=-1;
 if IndexOfName(AGroupName)<0 then
   Result:=-2
 else
  begin
   if GetValue(AGroupName, cpropGroup) then //really a group
    begin
     gc:=GetValue(AGroupName); //get amount of group members
     i:=IndexOfName(AGroupName+IntToStr(Idx));
     if i>=0 then
      begin
       Delete(i);
       Dec(gc);
       SetAnyValue(AGroupName, gc);
      end;
    end;
  end;
end;

procedure TStringsSettings.ReindexGroup(AGroupName: String);
 var
  i, t, k, gc, gm: Integer;
  vn, vnn: String;
  ValueDef: Variant;
  ValueSection: String;
begin
 gc:=GetValue(AGroupName); //get amount of group members
 gm:=GetValue(AGroupName, cpropMax); //get maximum
 i:=0;
 while i<gm do
  begin
   vn:=AGroupName+IntToStr(i);
   if i<gc then
    begin
     if IndexOfName(vn)<0 then //value not found
      begin
       t:=i+1;
       k:=-1;
       while (t<gm) and (k<0) do //search next value
        begin
         vnn:=AGroupName+IntToStr(t);
         k:=IndexOfName(vnn);
         if k<0 then
           Inc(t);
        end;
       if k>=0 then //next value found
        begin
         Strings[k]:=vn+'='+ValueFromIndex[k]; //change the name of found value to indexed
        end
       else //no more values (group is uncomplete) - add missing
        begin
         ValueDef:=GetValue(AGroupName, cpropGroupDefault);
         if VarType(ValueDef)=varNull then
           ValueDef:=Unassigned;
         ValueSection:=GetValue(AGroupName, cpropGroupSection);
         if (ValueSection='') or (ValueSection='0') then //Null protection
           ValueSection:=GetValue(AGroupName, cpropSection);
         if ValueSection='0' then //Null protection
           ValueSection:='';
         AddAnyValue(vn, GetValue(AGroupName, cpropGroupType), ValueDef, GetValue(AGroupName, cpropGroupMin), GetValue(AGroupName, cpropGroupMax), ValueSection, GetValue(AGroupName, cpropGroupNonExist));
        end;
      end;
    end
   else //values over count - cleanup
    begin
     k:=IndexOfName(vn);
     if k>=0 then
       Delete(k);
    end;
   Inc(i);
  end;
end;

function TStringsSettings.GetGroup(AGroupName: String; Idx: Integer): Variant;
 var
  AIndex: Integer;
begin
 AIndex:=IndexOfName(AGroupName);
 if (AIndex>=0) and (AIndex<Count) then
  begin
   if GetValue(AIndex, cpropGroup) then //really a group
     Result:=GetValue(Names[Aindex]+IntToStr(Idx))
   else
     Result:=Null;
  end
 else
   Result:=Unassigned;
end;

procedure TStringsSettings.SetGroup(AGroupName: String; Idx: Integer; AValue: Variant);
 var
  AIndex: Integer;
begin
 AIndex:=IndexOfName(AGroupName);
 if (AIndex>=0) and (AIndex<Count) then
  begin
   if GetValue(AIndex, cpropGroup) then //really a group
     SetAnyValue(Names[Aindex]+IntToStr(Idx), AValue);
  end;
end;

procedure TStringsSettings.SingleTokenInGroupValue(AGroupName, AToken: String; Idx: Integer; TokenValue: String = '');
 var
  i: Integer;
  s: WideString;
begin
 if (GetValue(AGroupName, cpropGroup)) and (GetValue(AGroupName, cpropGroupType)=varString) then //really a string group
  begin
   for i:=0 to GetValue(AGroupName)-1 do
    begin
     s:=Group[AGroupName, i];
     if TokenExist(AToken, s) then
      begin
       if i=Idx then
        begin
         if TokenValue<>'' then
          begin
           ReplaceToken(AToken, TokenValue, s);
           Group[AGroupName, i]:=s;
          end;
        end
       else
        begin
         DeleteToken(AToken, s);
         Group[AGroupName, i]:=s;
        end;
      end
     else
      begin
       if i=Idx then
        begin
         if TokenValue<>'' then
          begin
           s:=s+EncodeToken(AToken, TokenValue);
           Group[AGroupName, i]:=s;
          end;
        end;
      end;
    end;
  end;
end;

function TStringsSettings.GetValue(Ref: Variant; Prop: String = ''): Variant;
 var
  AIndex: Integer;
  s, r, v, d: WideString;
  f: Boolean;
begin
 s:=Ref;
 AIndex:=StrToIntDef(s, -1);
 if AIndex<0 then
   AIndex:=IndexOfName(s);
 if (AIndex>=0) and (AIndex<Count) then
  begin
   Props.Clear;
   s:=ValueFromIndex[AIndex];
   ExtractTokenAttributes(ctagValue, s, r, Props);
   if Props.IndexOfName(cpropType)<0 then
     Result:=Null
   else
    begin
     f:=true;
     v:=Props.Values[cpropType];
     d:=Props.Values[cpropDefault];
     // return of properties if needed
     if Prop=cpropType then
      begin
       r:=IntToStr(PropType2AType(Props.Values[cpropType]));
       d:='0';
       v:=ctypeWord;
      end;
     if Prop=cpropSection then
      begin
       r:=Props.Values[cpropSection];
       d:=cDefaultSection;
       v:=ctypeString;
      end;
     if Prop=cpropDefault then
      begin
       r:=Props.Values[cpropDefault];
       if r='' then
        begin
         Result:=Null;
         Exit;
        end;
      end;
     if Prop=cpropMin then
      begin
       r:=Props.Values[cpropMin];
       if r='' then
        begin
         Result:=Null;
         Exit;
        end;
      end;
     if Prop=cpropMax then
      begin
       r:=Props.Values[cpropMax];
       if r='' then
        begin
         Result:=Null;
         Exit;
        end;
      end;
     if Prop=cpropNonExist then
      begin
       r:=Props.Values[cpropNonExist];
       d:='0';
       v:=ctypeBoolean;
      end;
     if Prop=cpropNonSave then
      begin
       r:=Props.Values[cpropNonSave];
       d:='0';
       v:=ctypeBoolean;
      end;
     //also a group props
     if Prop=cpropGroup then
      begin
       r:=Props.Values[cpropGroup];
       d:='0';
       v:=ctypeBoolean;
      end;
     if Prop=cpropGroupSection then
      begin
       r:=Props.Values[cpropGroupSection];
       if r='' then
         r:=Props.Values[cpropSection];
       d:=cDefaultSection;
       v:=ctypeString;
      end;
     if Prop=cpropGroupType then
      begin
       r:=IntToStr(PropType2AType(Props.Values[cpropGroupType]));
       d:='0';
       v:=ctypeWord;
      end;
     if Prop=cpropGroupDefault then
      begin
       r:=Props.Values[cpropGroupDefault];
       if r='' then
        begin
         Result:=Null;
         Exit;
        end;
      end;
     if Prop=cpropGroupMin then
      begin
       r:=Props.Values[cpropGroupMin];
       if r='' then
        begin
         Result:=Null;
         Exit;
        end;
      end;
     if Prop=cpropGroupMax then
      begin
       r:=Props.Values[cpropGroupMax];
       if r='' then
        begin
         Result:=Null;
         Exit;
        end;
      end;
     if Prop=cpropGroupNonExist then
      begin
       r:=Props.Values[cpropGroupNonExist];
       d:='0';
       v:=ctypeBoolean;
      end;
     //
     if v=ctypeBoolean then
      begin
       Result:=StrToBoolDef(r, StrToBoolDef(d, false));
       f:=false;
      end;
     if v=ctypeDate then
      begin
       Result:=StrToDateDef(r, StrToDateDef(d, 0));
       f:=false;
      end;
     if v=ctypeDateTime then
      begin
       Result:=StrToDateTimeDef(r, StrToDateTimeDef(d, 0));
       f:=false;
      end;
     if v=ctypeDouble then
      begin
       Result:=StrToFloatDef(r, StrToFloatDef(d, 0));
       f:=false;
      end;
     if v=ctypeInteger then
      begin
       Result:=StrToIntDef(r, StrToIntDef(d, 0));
       f:=false;
      end;
     if v=ctypeLongWord then
      begin
       Result:=StrToIntDef(r, StrToIntDef(d, 0));
       f:=false;
      end;
     if v=ctypeString then
      begin
       if r='' then
         Result:=d
       else
         Result:=r;
       f:=false;
      end;
     if v=ctypeTime then
      begin
       Result:=StrToTimeDef(r, StrToTimeDef(d, 0));
       f:=false;
      end;
     if v=ctypeWord then
      begin
       Result:=StrToIntDef(r, StrToIntDef(d, 0));
       f:=false;
      end;
     if f then
       Result:=Null;
    end;
  end
 else
   Result:=Unassigned;
end;

function TStringsSettings.GetAnyValue(Ref: Variant): Variant;
 {
 var
  AIndex: Integer;
  s, r, v, d: WideString;
  f: Boolean;
 }
begin
 {
 s:=Ref;
 AIndex:=StrToIntDef(s, -1);
 if AIndex<0 then
   AIndex:=IndexOfName(s);
 if (AIndex>=0) and (AIndex<Count) then
  begin
   Props.Clear;
   s:=ValueFromIndex[AIndex];
   ExtractTokenAttributes(ctagValue, s, r, Props);
   if Props.IndexOfName(cpropType)<0 then
     Result:=Null
   else
    begin
     f:=true;
     v:=Props.Values[cpropType];
     d:=Props.Values[cpropDefault];
     if v=ctypeBoolean then
      begin
       Result:=StrToBoolDef(r, StrToBoolDef(d, false));
       f:=false;
      end;
     if v=ctypeDate then
      begin
       Result:=StrToDateDef(r, StrToDateDef(d, 0));
       f:=false;
      end;
     if v=ctypeDateTime then
      begin
       Result:=StrToDateTimeDef(r, StrToDateTimeDef(d, 0));
       f:=false;
      end;
     if v=ctypeDouble then
      begin
       Result:=StrToFloatDef(r, StrToFloatDef(d, 0));
       f:=false;
      end;
     if v=ctypeInteger then
      begin
       Result:=StrToIntDef(r, StrToIntDef(d, 0));
       f:=false;
      end;
     if v=ctypeLongWord then
      begin
       Result:=StrToIntDef(r, StrToIntDef(d, 0));
       f:=false;
      end;
     if v=ctypeString then
      begin
       if r='' then
         Result:=d
       else
         Result:=r;
       f:=false;
      end;
     if v=ctypeTime then
      begin
       Result:=StrToTimeDef(r, StrToTimeDef(d, 0));
       f:=false;
      end;
     if v=ctypeWord then
      begin
       Result:=StrToIntDef(r, StrToIntDef(d, 0));
       f:=false;
      end;
     if f then
       Result:=Null;
    end;
  end
 else
   Result:=Unassigned;
 }
 Result:=GetValue(Ref);
end;

procedure TStringsSettings.SetAnyValue(Ref: Variant; AValue: Variant);
 var
  AIndex: Integer;
  s, r: WideString;
  i, AType: Integer;
  v, tv: Variant;
begin
 s:=Ref;
 AIndex:=StrToIntDef(s, -1);
 if AIndex<0 then
   AIndex:=IndexOfName(s);
 if (AIndex>=0) and (AIndex<Count) then
  begin
   s:=ValueFromIndex[AIndex];
   Props.Clear;
   ExtractTokenAttributes(ctagValue, s, r, Props);
   i:=Props.IndexOfName(cpropType);
   if (i>=0) then
    begin
     AType:=PropType2AType(Props.ValueFromIndex[i]);
     tv:=VarAsType(AValue, ATypeAsVarType(AType));
     if IsCorrectType(AType, tv) then
      begin
       i:=Props.IndexOfName(cpropMin);
       if i>=0 then
        begin
         v:=Props.ValueFromIndex[i];
         VarCast(v, v, ATypeAsVarType(AType));
         if AValue<v then
           tv:=v;
        end;
       i:=Props.IndexOfName(cpropMax);
       if i>=0 then
        begin
         v:=Props.ValueFromIndex[i];
         VarCast(v, v, ATypeAsVarType(AType));
         if AValue>v then
           tv:=v;
        end;
       s:=EncodeTokenAttributes(ctagValue, GetStringFromValue(AType, tv), Props);
       ValueFromIndex[AIndex]:=s;
       //we have a group counter here ?
       if Props.Values[cpropGroup]='1' then
         ReindexGroup(Names[AIndex]);
      end;
    end;
  end;
end;

function TStringsSettings.LoadValuesFromIni(Ini: TMemIniFile; OnlyValue: String = ''): Integer;
 var
  i: Integer;
 procedure LoadValue(Index: Integer);
  var
   t: Integer;
   s, r: WideString;
   Name, Section, d: String;
  begin
   s:=ValueFromIndex[Index];
   Props.Clear;
   ExtractTokenAttributes(ctagValue, s, r, Props);
   t:=Props.IndexOfName(cpropSection);
   if t<0 then
     Section:=cDefaultSection
   else
     Section:=Props.ValueFromIndex[t];
   if Section='' then
     Section:=cDefaultSection;
   Name:=Names[Index];
   d:=Ini.ReadString(Section, Name, '');
   if d='' then
    begin
     if (Props.IndexOfName(cpropNonExist)<0) and (Props.IndexOfName(cpropNonSave)<0) then
       Result:=vreValueNotFound;
    end
   else
     SetAnyValue(Index, d);
  end;
begin
 Result:=vreOK;
 if Assigned(Ini) then
  begin
   if OnlyValue='' then
    begin
     i:=0;
     while i<Count do
      begin
       LoadValue(i);
       Inc(i);
      end;
    end
   else
    begin
     i:=IndexOfName(OnlyValue);
     if i>=0 then
       LoadValue(i);
    end;
  end
 else
   Result:=vreInvalidIni;
end;

function TStringsSettings.LoadValuesFromIni(Filename: String; OnlyValue: String = ''): Integer;
 var
  Ini: TMemIniFile;
begin
 if FileExists(Filename) then
  begin
   Ini:=TMemIniFile.Create(Filename);
   Result:=LoadValuesFromIni(Ini, OnlyValue);
   Ini.Free;
  end
 else
   Result:=vreFileNotFound;
end;

procedure TStringsSettings.SaveValuesToIni(Ini: TMemIniFile; OnlyValue: String = '');
 var
  i: Integer;
 procedure SaveValue(Index: Integer);
  var
   t, k, j: Integer;
   s, r: WideString;
   Name, Section, ValSection: String;
  begin
   s:=ValueFromIndex[Index];
   Props.Clear;
   ExtractTokenAttributes(ctagValue, s, r, Props);
   if r='' then
    begin
     r:=Props.Values[cpropDefault];
    end;
   t:=Props.IndexOfName(cpropSection);
   if t<0 then
     Section:=cDefaultSection
   else
     Section:=Props.ValueFromIndex[t];
   if Section='' then
     Section:=cDefaultSection;
   Name:=Names[Index];
   t:=Props.IndexOfName(cpropNonSave);
   if t<0 then
     Ini.WriteString(Section, Name, r);
   //clear group values in ini
   if StrToBoolDef(Props.Values[cpropGroup], false) then
    begin
     //ShowMessage('Cleanup...'+#13+r); //debug;
     k:=StrToIntDef(r, 0);
     ValSection:=Props.Values[cpropGroupSection];
     if ValSection='' then
       ValSection:=Section;
     //ShowMessage(Name+#13+ValSection+#13+Props.Values[cpropMax]); //debug;
     for j:=k to StrToIntDef(Props.Values[cpropMax], 0)-1 do
      begin
       if Ini.ValueExists(ValSection, Name+IntToStr(j)) then
         Ini.DeleteKey(ValSection, Name+IntToStr(j));
      end;
    end;
  end;
begin
 if Assigned(Ini) then
  begin
   if OnlyValue='' then
    begin
     for i:=0 to Count-1 do
       SaveValue(i);
    end
   else
    begin
     i:=IndexOfName(OnlyValue);
     if i>=0 then
       SaveValue(i);
    end;
   Ini.UpdateFile;
  end;
end;

procedure TStringsSettings.SaveValuesToIni(Filename: String; OnlyValue: String = '');
 var
  Ini: TMemIniFile;
begin
 Ini:=TMemIniFile.Create(Filename);
 SaveValuesToIni(Ini, OnlyValue);
 Ini.Free;
end;

procedure TStringsSettings.CopyValues(Source: TStringsSettings);
 var
  i: Integer;
begin
 for i:=0 to Count-1 do
  begin
   if Source.IndexOfName(Names[i])>=0 then
     SetAnyValue(i, Source.GetAnyValue(Names[i]));
  end;
end;

function TStringsSettings.GetMin(Ref: Variant): Variant;
begin
 Result:=GetValue(Ref, cpropMin);
end;

function TStringsSettings.GetMax(Ref: Variant): Variant;
begin
 Result:=GetValue(Ref, cpropMax);
end;

function TStringsSettings.GetDef(Ref: Variant): Variant;
begin
 Result:=GetValue(Ref, cpropDefault);
end;

function TStringsSettings.LoadValuesFromReg(Reg: TRegIniFile; RegPath: String = ''; OnlyValue: String = ''): Integer;
 var
  i: Integer;
 procedure LoadValue(Index: Integer);
  var
   t: Integer;
   s, r: WideString;
   Name, Section, d: String;
  begin
   s:=ValueFromIndex[Index];
   Props.Clear;
   ExtractTokenAttributes(ctagValue, s, r, Props);
   t:=Props.IndexOfName(cpropSection);
   if t<0 then
     Section:=cDefaultSection
   else
     Section:=Props.ValueFromIndex[t];
   if Section='' then
     Section:=cDefaultSection;
   Name:=Names[Index];
   d:=Reg.ReadString(Section, Name, '');
   if d='' then
    begin
     if (Props.IndexOfName(cpropNonExist)<0) and (Props.IndexOfName(cpropNonSave)<0) then
       Result:=vreValueNotFound;
    end
   else
     SetAnyValue(Index, d);
  end;
begin
 Result:=vreOK;
 if Assigned(Reg) then
  begin
   Reg.OpenKeyReadOnly(RegPath);
   if OnlyValue='' then
    begin
     i:=0;
     while i<Count do
      begin
       LoadValue(i);
       Inc(i);
      end;
    end
   else
    begin
     i:=IndexOfName(OnlyValue);
     if i>=0 then
       LoadValue(i);
    end;
   Reg.CloseKey;
  end
 else
   Result:=vreInvalidReg;
end;

function TStringsSettings.LoadValuesFromReg(RegPath: String = ''; OnlyValue: String = ''): Integer;
 var
  Reg: TRegIniFile;
begin
 Reg:=TRegIniFile.Create;
 Result:=LoadValuesFromReg(Reg, RegPath, OnlyValue);
 Reg.Free;
end;

procedure TStringsSettings.SaveValuesToReg(Reg: TRegIniFile; RegPath: String = ''; OnlyValue: String = '');
 var
  i: Integer;
 procedure SaveValue(Index: Integer);
  var
   t, k, j: Integer;
   s, r: WideString;
   Name, Section, ValSection: String;
  begin
   s:=ValueFromIndex[Index];
   Props.Clear;
   ExtractTokenAttributes(ctagValue, s, r, Props);
   if r='' then
    begin
     r:=Props.Values[cpropDefault];
    end;
   t:=Props.IndexOfName(cpropSection);
   if t<0 then
     Section:=cDefaultSection
   else
     Section:=Props.ValueFromIndex[t];
   if Section='' then
     Section:=cDefaultSection;
   Name:=Names[Index];
   t:=Props.IndexOfName(cpropNonSave);
   if t<0 then
     Reg.WriteString(Section, Name, r);
   //clear group values in registry
   if StrToBoolDef(Props.Values[cpropGroup], false) then
    begin
     k:=StrToIntDef(r, 0);
     ValSection:=Props.Values[cpropGroupSection];
     if ValSection='' then
       ValSection:=Section;
     Reg.OpenKey(RegPath+ValSection, false);
     for j:=k to StrToIntDef(Props.Values[cpropMax], 0)-1 do
      begin
       if Reg.ValueExists(Name+IntToStr(j)) then
         Reg.DeleteKey(ValSection, Name+IntToStr(j));
      end;
    end;
  end;
begin
 if Assigned(Reg) then
  begin
   Reg.OpenKey(RegPath, true);
   if OnlyValue='' then
    begin
     for i:=0 to Count-1 do
       SaveValue(i);
    end
   else
    begin
     i:=IndexOfName(OnlyValue);
     if i>=0 then
       SaveValue(i);
    end;
   Reg.CloseKey;
  end;
end;

procedure TStringsSettings.SaveValuesToReg(RegPath: String = ''; OnlyValue: String = '');
 var
  Reg: TRegIniFile;
begin
 Reg:=TRegIniFile.Create;
 SaveValuesToReg(Reg, RegPath, OnlyValue);
 Reg.Free;
end;

procedure TStringsSettings.GroupList(Ref: Variant; List: TStrings; All: Boolean = false);
 var
  AIndex, i: Integer;
  Name, s: String;
begin
 if Assigned(List) then
  begin
   List.Clear;
   s:=Ref;
   AIndex:=StrToIntDef(s, -1);
   if AIndex<0 then
     AIndex:=IndexOfName(s);
   if (AIndex>=0) and (AIndex<Count) then
    begin
     if GetValue(AIndex, cpropGroup) then //really a group
      begin
       Name:=Names[AIndex];
       for i:=0 to GetValue(AIndex)-1 do
        begin
         if All then
          List.Add(Strings[IndexOfName(Name+IntToStr(i))])
         else
          List.Add(GetGroup(Name, i));
        end;
      end;
    end;
  end;
end;

procedure TStringsSettings.GroupTokenList(AGroupName, AToken: String; List: TStrings);
 var
  i: Integer;
  s: WideString;
  TokenValue: String;
begin
 if Assigned(List) then
  begin
   List.Clear;
   if (GetValue(AGroupName, cpropGroup)) and (GetValue(AGroupName, cpropGroupType)=varString) //really a string group
      and (AToken<>'') then
    begin
     for i:=0 to GetValue(AGroupName)-1 do
      begin
       s:=Group[AGroupName, i];
       TokenValue:=ExtractToken(AToken, s);
       if TokenValue<>'' then
         List.Add(TokenValue);
      end;
    end;
  end;
end;

function TStringsSettings.GroupTokenIndex(AGroupName, AToken: String; AValue: String): Integer;
 var
  i: Integer;
  s: WideString;
begin
 Result:=-1;
 if (GetValue(AGroupName, cpropGroup)) and (GetValue(AGroupName, cpropGroupType)=varString) //really a string group
    and (AToken<>'') and (AValue<>'') then
  begin
   for i:=0 to GetValue(AGroupName)-1 do
    begin
     s:=Group[AGroupName, i];
     if ExtractToken(AToken, s)=AValue then
      begin
       Result:=i;
       Break;
      end;
    end;
  end;
end;

//2.3

{$IFDEF USE_JEDI}
function TStringsSettings.LoadValuesFromXML(XML: TJclSimpleXML; OnlyValue: String = ''): Integer;
 var
  i: Integer;
 procedure LoadValue(Index: Integer);
  var
   t, k: Integer;
   s, r: WideString;
   Name, Section, d: String;
   elsec: TJclSimpleXMLElem;
  begin
   s:=ValueFromIndex[Index];
   Props.Clear;
   ExtractTokenAttributes(ctagValue, s, r, Props);
   t:=Props.IndexOfName(cpropSection);
   if t<0 then
     Section:=cDefaultSection
   else
     Section:=Props.ValueFromIndex[t];
   if Section='' then
     Section:=cDefaultSection;
   Name:=Names[Index];
   //find a section
   k:=XML.Root.Items.IndexOf(Section);
   if k<0 then
    begin
     //section not exist = value not found
     if (Props.IndexOfName(cpropNonExist)<0) and (Props.IndexOfName(cpropNonSave)<0) then
       Result:=vreValueNotFound;
    end
   else
    begin
     elsec:=XML.Root.Items[k];
     //find a value
     k:=elsec.Items.IndexOf(Name);
     if k<0 then
      begin
       //value not found
       if (Props.IndexOfName(cpropNonExist)<0) and (Props.IndexOfName(cpropNonSave)<0) then
         Result:=vreValueNotFound;
      end
     else
      begin
       //read and set value
       d:=elsec.Items[k].Value;
       if d='' then
        begin
         if (Props.IndexOfName(cpropNonExist)<0) and (Props.IndexOfName(cpropNonSave)<0) then
           Result:=vreValueNotFound;
        end
       else
         SetAnyValue(Index, d);
      end;
    end;
  end;
begin
 Result:=vreOK;
 if Assigned(XML) then
  begin
   if OnlyValue='' then
    begin
     i:=0;
     while i<Count do
      begin
       LoadValue(i);
       Inc(i);
      end;
    end
   else
    begin
     i:=IndexOfName(OnlyValue);
     if i>=0 then
       LoadValue(i);
    end;
  end
 else
   Result:=vreInvalidXML;
end;

function TStringsSettings.LoadValuesFromXML(AFilename: String; OnlyValue: String = ''): Integer;
 var
  XML: TJclSimpleXML;
begin
 if FileExists(AFilename) then
  begin
   XML:=TJclSimpleXML.Create;
   XML.FileName:=AFilename;
   Result:=LoadValuesFromXML(XML, OnlyValue);
   XML.Free;
  end
 else
   Result:=vreFileNotFound;
end;

procedure TStringsSettings.SaveValuesToXML(XML: TJclSimpleXML; OnlyValue: String = '');
 var
  i: Integer;
 procedure SaveValue(Index: Integer);
  var
   t, k, j, x: Integer;
   s, r: WideString;
   Name, Section, ValSection: String;
   el, elsec: TJclSimpleXMLElem;
   //elprop: TJclSimpleXMLProp; //for future needs
  begin
   s:=ValueFromIndex[Index];
   Props.Clear;
   ExtractTokenAttributes(ctagValue, s, r, Props);
   if r='' then
    begin
     r:=Props.Values[cpropDefault];
    end;
   t:=Props.IndexOfName(cpropSection);
   if t<0 then
     Section:=cDefaultSection
   else
     Section:=Props.ValueFromIndex[t];
   if Section='' then
     Section:=cDefaultSection;
   Name:=Names[Index];
   t:=Props.IndexOfName(cpropNonSave);
   if t<0 then
    begin
     //find a section
     k:=XML.Root.Items.IndexOf(Section);
     if k<0 then //no section - create new
       elsec:=XML.Root.Items.Add(Section)
     else
       elsec:=XML.Root.Items[k];
     //find a value
     k:=elsec.Items.IndexOf(Name);
     if k<0 then //no element - create new
       {el:=}elsec.Items.Add(Name, r)
     else //set new value
      begin
       el:=elsec.Items[k];
       el.Value:=r;
      end;
     { for future needs
     //set all properties
     for x:=0 to Props.Count-1 do
      begin
       elprop:=el.Properties.ItemNamed[Props.Names[x]];
       if Assigned(elprop) then //if property exists...
         elprop.Value:=Props.ValueFromIndex[x] //...set it
       else //..create it
         el.Properties.Add(Props.Names[x], Props.ValueFromIndex[x]);
      end;
     }
     //clear group values in XML
     if StrToBoolDef(Props.Values[cpropGroup], false) then
      begin
       ValSection:=Props.Values[cpropGroupSection];
       if ValSection='' then
         ValSection:=Section;
       //find a section
       k:=XML.Root.Items.IndexOf(ValSection);
       if k>=0 then //if no section, we don't need to clear :)
        begin
         elsec:=XML.Root.Items[k];
         k:=StrToIntDef(r, 0);
         //find elements and delete
         for j:=k+1 to StrToIntDef(Props.Values[cpropMax], 0)-1 do
          begin
           x:=elsec.Items.IndexOf(Name+IntToStr(j));
           if x>=0 then
             elsec.Items.Delete(x);
          end;
        end;
      end;
    end;
  end;
begin
 if Assigned(XML) then
  begin
   if OnlyValue='' then
    begin
     for i:=0 to Count-1 do
       SaveValue(i);
    end
   else
    begin
     i:=IndexOfName(OnlyValue);
     if i>=0 then
       SaveValue(i);
    end;
   XML.SaveToFile(XML.FileName);
  end;
end;

procedure TStringsSettings.SaveValuesToXML(AFilename: String; OnlyValue: String = '');
 var
  XML: TJclSimpleXML;
begin
 XML:=TJclSimpleXML.Create;
 try
  XML.FileName:=AFilename;
 except
  //stub for 'File not exist' error on new file 
 end;
 XML.Prolog.Encoding:='windows-1251';
 XML.Root.Name:='SettingsData';
 SaveValuesToXML(XML, OnlyValue);
 XML.Free;
end;
{$ENDIF}

end.

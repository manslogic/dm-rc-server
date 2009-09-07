unit xIniFile;

interface

uses
 Classes,
 IniFiles,
 Registry;

type
 TxIniFile = class
  private
   FWayToData: String;
   FMode: Integer;
   FIni: TMemIniFile;
   FReg: TRegIniFile;
  public
   constructor Create(AWayToData: String; AMode: Integer = 0);
   destructor Destroy; override;
   procedure SwitchMode(AWayToData: String; NewMode: Integer; EraseOld: Boolean = false);
   procedure CopyTo(NewIniOrKey: String; Dest: Integer);
   //
   function ReadString(const Section, Ident, Default: string): string;
   procedure WriteString(const Section, Ident, Value: String);
   procedure ReadSection(const Section: string; Strings: TStrings);
   procedure ReadSections(Strings: TStrings);
   procedure ReadSectionValues(const Section: string; Strings: TStrings);
   function SectionExists(const Section: string): Boolean;
   procedure EraseSection(const Section: string);
   function ValueExists(const Section, Ident: string): Boolean;
   procedure DeleteKey(const Section, Ident: String);
   procedure UpdateFile;
   //
   property Mode: Integer read FMode;
   property WayToData: String read FWayToData;
   property Ini: TMemIniFile read FIni;
   property Reg: TRegIniFile read FReg;
 end;

const
 xitIni = 0;
 xitReg = 1;

procedure CopyDataFromReg(Reg: TRegIniFile; Ini: TMemIniFile); overload;
procedure CopyDataFromReg(Reg: TRegIniFile; NewReg: TRegIniFile); overload;
procedure CopyDataFromIni(Ini: TMemIniFile; NewIni: TMemIniFile); overload;
procedure CopyDataFromIni(Ini: TMemIniFile; Reg: TRegIniFile); overload;

implementation

uses
 SysUtils;

procedure CopyDataFromReg(Reg: TRegIniFile; Ini: TMemIniFile); overload;
 var
  Sections, Data: TStrings;
  i, t: Integer;
begin
 if Assigned(Reg) and Assigned(Ini) then
  begin
   Sections:=TStringList.Create;
   Data:=TStringList.Create;
   Reg.ReadSections(Sections);
   for i:=0 to Sections.Count-1 do
    begin
     Reg.ReadSectionValues(Sections[i], Data);
     for t:=0 to Data.Count-1 do
      Ini.WriteString(Sections[i], Data.Names[t], Data.ValueFromIndex[t]);
     end;
   Data.Free;
   Sections.Free;
  end;
end;

procedure CopyDataFromReg(Reg: TRegIniFile; NewReg: TRegIniFile); overload;
 var
  Sections, Data: TStrings;
  i, t: Integer;
begin
 if Assigned(Reg) and Assigned(NewReg) then
  begin
   Sections:=TStringList.Create;
   Data:=TStringList.Create;
   Reg.ReadSections(Sections);
   for i:=0 to Sections.Count-1 do
    begin
     Reg.ReadSectionValues(Sections[i], Data);
     for t:=0 to Data.Count-1 do
      NewReg.WriteString(Sections[i], Data.Names[t], Data.ValueFromIndex[t]);
     end;
   Data.Free;
   Sections.Free;
  end;
end;

procedure CopyDataFromIni(Ini: TMemIniFile; NewIni: TMemIniFile); overload;
 var
  Sections, Data: TStrings;
  i, t: Integer;
begin
 if Assigned(Ini) and Assigned(NewIni) then
  begin
   Sections:=TStringList.Create;
   Data:=TStringList.Create;
   Ini.ReadSections(Sections);
   for i:=0 to Sections.Count-1 do
    begin
     Ini.ReadSectionValues(Sections[i], Data);
     for t:=0 to Data.Count-1 do
      NewIni.WriteString(Sections[i], Data.Names[t], Data.ValueFromIndex[t]);
     end;
   Data.Free;
   Sections.Free;
  end;
end;

procedure CopyDataFromIni(Ini: TMemIniFile; Reg: TRegIniFile); overload;
 var
  Sections, Data: TStrings;
  i, t: Integer;
begin
 if Assigned(Reg) and Assigned(Ini) then
  begin
   Sections:=TStringList.Create;
   Data:=TStringList.Create;
   Ini.ReadSections(Sections);
   for i:=0 to Sections.Count-1 do
    begin
     Ini.ReadSectionValues(Sections[i], Data);
     for t:=0 to Data.Count-1 do
      Reg.WriteString(Sections[i], Data.Names[t], Data.ValueFromIndex[t]);
     end;
   Data.Free;
   Sections.Free;
  end;
end;

 {TxIniFile}

constructor TxIniFile.Create(AWayToData: String; AMode: Integer = 0);
begin
 inherited Create;
 FWayToData:=AWayToData;
 FMode:=AMode;
 case FMode of
  xitReg:
   begin
    FIni:=nil;
    FReg:=TRegIniFile.Create;
   end;
  else
   begin
    FReg:=nil;
    FIni:=TMemIniFile.Create(FWayToData);
   end;
  end;
end;

destructor TxIniFile.Destroy;
begin
 case FMode of
  xitReg:
   begin
    FReg.CloseKey;
    FReg.Free;
   end;
  else
   begin
    FIni.UpdateFile;
    FIni.Free;
   end;
  end;
 inherited Destroy;
end;

procedure TxIniFile.SwitchMode(AWayToData: String; NewMode: Integer; EraseOld: Boolean = false);
 var
  f: file;
  AReg: TRegistry;
begin
 if NewMode<>FMode then
  begin
   case NewMode of
    xitReg:
     begin
      FReg:=TRegIniFile.Create;
      FReg.OpenKey(AWayToData, true);
      CopyDataFromIni(FIni, FReg);
      FReg.CloseKey;
      if EraseOld then
       begin
        AssignFile(f, FIni.FileName);
        try
          Erase(f);
        except
        end;
       end;
      FIni.Free;
     end;
    else
     begin
      FIni:=TMemIniFile.Create(AWayToData);
      FReg.OpenKeyReadOnly(FWayToData);
      CopyDataFromReg(FReg, FIni);
      FReg.CloseKey;
      if EraseOld then
       begin
        AReg:=TRegistry.Create;
        AReg.DeleteKey(FWayToData);
        AReg.Free;
       end;
      FReg.Free;
     end;
    end;
   FWayToData:=AWayToData;
   FMode:=NewMode;
  end;
end;

procedure TxIniFile.CopyTo(NewIniOrKey: String; Dest: Integer);
 var
  NewIni: TMemIniFile;
  NewReg: TRegIniFile;
begin
 if NewIniOrKey<>FWayToData then
  begin
   case Dest of
    xitReg:
     begin
      NewReg:=TRegIniFile.Create;
      NewReg.OpenKey(NewIniOrKey, true);
      case FMode of
       xitReg:
        begin
         FReg.OpenKeyReadOnly(FWayToData);
         CopyDataFromReg(FReg, NewReg);
         FReg.CloseKey;
        end;
       else
         CopyDataFromIni(FIni, NewReg);
       end;
      NewReg.CloseKey;
      NewReg.Free;
     end;
    else
      NewIni:=TMemIniFile.Create(NewIniOrKey);
      case FMode of
       xitReg:
        begin
         FReg.OpenKeyReadOnly(FWayToData);
         CopyDataFromReg(FReg, NewIni);
         FReg.CloseKey;
        end;
       else
         CopyDataFromIni(FIni, NewIni);
       end;
      NewIni.UpdateFile;
      NewIni.Free;
    end;
  end;
end;

function TxIniFile.ReadString(const Section, Ident, Default: string): string;
begin
 case FMode of
  xitReg:
    Result:=FReg.ReadString(Section, Ident, Default);
  else
    Result:=FIni.ReadString(Section, Ident, Default);
  end;
end;

procedure TxIniFile.WriteString(const Section, Ident, Value: String);
begin
 case FMode of
  xitReg:
    FReg.WriteString(Section, Ident, Value);
  else
    FIni.WriteString(Section, Ident, Value);
  end;
end;

procedure TxIniFile.ReadSection(const Section: string; Strings: TStrings);
begin
 case FMode of
  xitReg:
    FReg.ReadSection(Section, Strings);
  else
    FIni.ReadSection(Section, Strings);
  end;
end;

procedure TxIniFile.ReadSections(Strings: TStrings);
begin
 case FMode of
  xitReg:
    FReg.ReadSections(Strings);
  else
    FIni.ReadSections(Strings);
  end;
end;

procedure TxIniFile.ReadSectionValues(const Section: string; Strings: TStrings);
begin
 case FMode of
  xitReg:
    FReg.ReadSectionValues(Section, Strings);
  else
    FIni.ReadSectionValues(Section, Strings);
  end;
end;

function TxIniFile.SectionExists(const Section: string): Boolean;
begin
 case FMode of
  xitReg:
    Result:=FReg.KeyExists(FWayToData+'\'+Section);
  else
    Result:=FIni.SectionExists(Section);
  end;
end;

procedure TxIniFile.EraseSection(const Section: string);
begin
 case FMode of
  xitReg:
    FReg.EraseSection(Section);
  else
    FIni.EraseSection(Section);
  end;
end;

function TxIniFile.ValueExists(const Section, Ident: string): Boolean;
begin
 case FMode of
  xitReg:
   begin
    FReg.OpenKeyReadOnly(FWayToData+'\'+Section);
    Result:=FReg.ValueExists(Ident);
    FReg.CloseKey;
   end;
  else
    Result:=FIni.ValueExists(Section, Ident);
  end;
end;

procedure TxIniFile.DeleteKey(const Section, Ident: String);
begin
 case FMode of
  xitReg:
    FReg.DeleteKey(Section, Ident);
  else
    FIni.DeleteKey(Section, Ident);
  end;
end;

procedure TxIniFile.UpdateFile;
begin
 if FMode=xitIni then
   FIni.UpdateFile;
end;

end.

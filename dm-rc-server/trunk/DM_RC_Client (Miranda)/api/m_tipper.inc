{
 Tipper API
 note: Tipper is internally unicode and requires unicows.dll to function
 correctly on 95/98/ME so you'll find a lot of wchar_t stuff in here

 translation function type
 use hContact, module and setting to read your db value(s) and put the resulting
 string into buff return buff if the translation was successful, or return 0 for failure
}
{$IFNDEF M_TIPPER}
{$DEFINE M_TIPPER}
type
  TranslateFunc = function (hContact:THANDLE;module:PAnsiChar;setting_or_prefix:PAnsiChar;
       buff:pWideChar;bufflen:int):pWideChar; cdecl;

type
  PDBVTranslation = ^TDBVTranslation;
  TDBVTranslation = record
    tfunc:TranslateFunc; // address of your translation function (see typedef above)
    name :pWideChar; // make sure this is unique, and DO NOT translate it
    id   :dword;     // will be overwritten by Tipper - do not use
  end;

{
 add a translation to tipper
 wParam not used
 lParam = pointer to PDBVTranslation
}
const
  MS_TIPPER_ADDTRANSLATION:PAnsiChar = 'Tipper/AddTranslation';

{
 unicode extension to the basic functionality
 wParam - optional (wchar_t *)text for text-only tips
 lParam - (CLCINFOTIP *)infoTip
}
  MS_TIPPER_SHOWTIPW:PAnsiChar = 'mToolTip/ShowTipW';

{$ENDIF}

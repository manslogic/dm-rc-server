unit DMPluginIntf;

//описание см. в readme.txt

interface

type
  { IDMInterface }
  IDMInterface = interface(IUnknown)
  ['{B412B405-0578-4B99-BB06-368CDA0B2F8C}']
    function DoAction(action: WideString; parameters: WideString): WideString; stdcall;//выполнить какие-либо действия в ДМ
  end;

  { IDMPlugIn }
  IDMPlugIn = interface(IUnknown)
  ['{959CD0D3-83FD-40F7-A75A-E5C6500B58DF}']
    function getID: WideString; stdcall;
    //-----info
    function GetName: WideString; stdcall;//получаем инфу о плагине
    function GetVersion: WideString; stdcall;//получаем инфу о плагине
    function GetDescription(language: WideString): WideString; stdcall;//получаем инфу о плагине
    function GetEmail: WideString; stdcall;//получаем инфу о плагине
    function GetHomepage: WideString; stdcall;//получаем инфу о плагине
    function GetCopyright: WideString; stdcall;//получаем инфу о плагине
    function GetMinAppVersion: WideString; stdcall;//получаем минимальную версию ДМ-а с которой может работать плагин

    //------
    procedure PluginInit(_IDmInterface: IDmInterface); stdcall;//инициализация плагина и передача интерфейса для доступа к ДМ
    procedure PluginConfigure(params: WideString); stdcall;//вызов окна конфигурации плагина
    procedure BeforeUnload; stdcall;

    function EventRaised(eventType: WideString; eventData: WideString): WideString; stdcall;//вызывается из ДМ-ма при возникновении какого либо события
    { идентификатор плагина }
    property ID: WideString read getID;
  end;

implementation

end.

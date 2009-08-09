В данной папке находится пример/шаблон тестового плагина для Download Master-a
и файл с объявлением интерфейса который используется для взаимодействия плагина
с программой.

DMPluginIntf.pas - файл объявления интерфейсов;
dmtest_plugin.dpr - файл проекта плагина (на Delphi);
dmtest_pluginImpl.pas - реализация тестового плагина.

	ОПИСАНИЕ ИНТЕРФЕЙСА МЕНЕДЖЕРА ЗАКАЧЕК Download Master (DMPluginIntf.pas)

	В интерфейсе предусмотрены 2 основные функции для реализации 
взаимодействия с программой EventRaised и DoAction, и одна функция для отображения окна 
настроек вашего плагина PluginConfigure, которую вам тоже необходимо 
реализовать самостоятельно. Реализация остальных функций одинакова для всех 
плагинов и может быть взята из примера.

======function DoAction(action: WideString; parameters: WideString): WideString; stdcall;
//выполнить какие-либо действия в ДМ

 	action = 'AddingURL' - добавление УРЛ-а на закачку.
	parameters = '<url>http://www.westbyte.com/plugin</url> <sectionslimit>2</sectionslimit>';
		допустимые имена параметров:
		'url', 'referer', 'description', 'savepath', 'filename', 'user', 'password', 'sectionslimit', 'priority', 'cookies', 'post', 'hidden', 'start', 'mirror1', 'mirror2', 'mirror3', 'mirror4', 'mirror5'
   
	Например: DoAction('AddingURL', '<url>http://www.westbyte.com/plugin</url> <hidden>1</hidden>')
		- добавляем закачку http://www.westbyte.com/plugin без открытия окна добавления закачки (hidden=1)

     Возможные значения параметров (в формате: (action: WideString; parameters: WideString)):
        ('AddingURL', '<url>http://www.westbyte.com/plugin</url> <hidden>1</hidden>') - добавление на закачку указанного УРЛ-а без открытия окна добавления закачки;
        ('GetDownloadInfoByID', IntToStr(ID)) - возвращаем информацию (в XML формате) о закачке с указанным ID;
        ('GetMaxSectionsByID', IntToStr(ID)) - возвращаем максимальное к-во секций которое может быть открыто закачкой с указанным ID;
        ('GetDownloadIDsList', '') - получаем список ID (разделенных пробелами) всех закачек из списка. В качестве параметра может быть указано состояние закачки для возврата списка закачек которые находятся в этом состоянии ('GetDownloadIDsList', IntToStr(State));
	                Например: ('GetDownloadIDsList', '3') - возвращаем список ID для качающихся в данный момент закачек (dsDownloading = 3).  
			Возможные значения параметра состояния - (dsPause = 0, dsPausing = 1, dsDownloaded = 2, dsDownloading = 3, dsError = 4, dsErroring = 5, dsQueue = 6);

	('GetTempDir', '') - получить путь к папке где храняться временные файлы
	('GetPluginDir', '') - получить путь к папке где находяться плагины
	('GetListDir', '') - получить путь к папке где храняться файлы списков
	('GetProgramDir', '') - получить путь к папке где находиться программа
	('GetLanguage', '') - получить текущий используемый язык
	('GetProgramName', '') - получить название менеджера закачки
	('GetCategoriesList', '') - получить в формате stringlist-a список категорий
	('GetSpeedsList', '') - получить в формате stringlist-a список скоростей
	('GetConnectionsList', '') - получить в формате stringlist-a список соединений RAS
	('GetLogDir', '') - получить путь к папке где храняться файлы логов

        ('StartSheduled', '') - стартовать все запланированные закачки;
        ('StopSheduled', '') - остановить все запланированные закачки;
        ('StartAll', '') - стартовать все незавершенные закачки;
        ('StopAll', '') - остановить все закачки;
        ('StartNode', IntToStr(NodeID)) - стартовать все незавершенные из определенной категории (подкатегории включаются только если в опциях программы указана настройка "Отображать закачки из подкатегорий");
        ('StopNode', IntToStr(NodeID)) - остановить все в указанной категории (подкатегории включаются только если в опциях программы указана настройка "Отображать закачки из подкатегорий");
        ('StartDownloads', IntToStr(ID)) - стартовать/(поставить в очередь) закачку(и) с указанным(и) ID (если закачек несколько, то ID указываются через пробел, например: ('StartDownloads', '21 456 20'));
        ('StopDownloads', IntToStr(ID)) - остановить закачку(и) с указанным(и) ID (если закачек несколько, то ID указываются через пробел, например: ('StopDownloads', '13 2527'));
        ('ChangeSpeed', IntToStr(SpeedMode)) - изменить скорость;
        ('RunApp', '<app>'+RunStr+'</app>'+'<param>'+RunParamStr+'</param>') - запустить приложение с указанными параметрами;
        ('ConnectRAS', '<connection>'+ConnectionName+'</connection><attempts>'+IntToStr(_Task.ConnectionAttempts)+'</attempts><period>'+IntToStr(_Task.ConnectionPeriod)+'</period>') - установить соединение с указанными параметрами;
        ('DisconnectRAS', ConnectionName) - разорвать указанное соединение, если соединение не указано, то разрываются все активные в данный момент;
        ('ShutDown', '') - выключить ПК;
        ('HibernateMode', '') - перейти в спящий режим;
        ('StandByMode', '') - перейти в ждущий режим;
        ('Exit', '') - вийти из программы
        ('ChangeMaxDownloads', IntToStr(MaxDownloads)) - изменить максимальное к-во одновременных закачек;
        ('AddStringToLog', '<id>'+IntToStr(ID)+'</id>'+'<type>'+IntToStr(Type)+'</type>'+'<logstring>Log String</logstring>') - добавить в лог закачки с указанным ID строку Log String, типа Type (0 - Out, 1 - In, 2 - Info (по-умолчанию), 3 - Error);

Пишите мне на: slava@westbyte.com для добавления необходимых вам действий.

========function EventRaised(eventType: WideString; eventData: WideString): WideString; stdcall;
//вызывается из ДМ-ма при возникновении какого либо события

Cобытия в формате (eventType: WideString; eventData: WideString):
	

1. ('plugin_start', '') - включаем плагин;
2. ('plugin_stop', '') - выключаем плагин;
3. ('dm_timer_60', '') - возникает каждые 60 секунд 
3.2. ('dm_timer_10', '') - возникает каждые 10 секунд 
3.3. ('dm_timer_5', '') - возникает каждые 5 секунд 
	(для отработки чего-либо каждую минуту);
4. ('dm_download_state', IntToStr(ID)+' '+IntToStr(integer(State))) - 
	возникает при изменении состояния закачки с указанным ID.
	State = (dsPause, dsPausing, dsDownloaded, dsDownloading, dsError, dsErroring, dsQueue);
5. ('dm_download_added', IntToStr(ID)) - возникает когда добавлена новая закачка с указанным ID;
6. ('dm_downloadall', '') - возникает когда все закачки завершены;
7. ('dm_start', '') - возникает когда dm стартовал;
8. ('dm_connect', '') - возникает когда dm установил какое-либо соединение;
9. ('dm_changelanguage', language) - сообщение о изменении языка в ДМ-е
Пишите мне на: slava@westbyte.com для добавления необходимых вам событий.

=============procedure PluginConfigure(params: WideString); stdcall;
вызов из ДМ-ма окна конфигурации плагина

1. ('<language>VALUE</language>') - где VALUE название текущего языка 
	установленного в программе.
	Например: ('<language>ukrainian</language>')

	Вам необходимо реализовать окно настроек как минимум для 2-х языков 
	русского и английского и выдавать соотв. окно для заданного языка.
	Пример кода:
	  if (language = 'russian') or (language = 'ukrainian') or (language = 'belarusian') then
	    //выводим на русском
	  else
	    //выводим на английском

=================================================================================
						(с)2006 Вячеслав Витер
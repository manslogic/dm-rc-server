unit DM_RC_Svr_Web;

interface

uses
 SysUtils;

const
 webHome = '<CENTER><a href="/">Download Master Remote Control Server</a></CENTER>';
 webHeadNoTimer = '<HTML><HEAD><TITLE>DM RC Server</TITLE></HEAD><BODY>'+webHome;
 scriptTimer = '<script language="JavaScript"><!--//'#13'startday = new Date();'#13'clockStart = startday.getTime();'#13'timerEnabled = true;'#13'function initStopwatch() {'#13+
               'var myTime = new Date();'#13'var timeNow = myTime.getTime();'#13'var timeDiff = timeNow - clockStart;'#13'this.diffSecs = 30-timeDiff/1000;'#13+
               'if (this.diffSecs<=0)'#13'location.reload();'#13'return(this.diffSecs); }'#13'function getSecs() {'#13'var mySecs = initStopwatch();'#13'var mySecs1 = ""+mySecs;'#13+
               'mySecs1= mySecs1.substring(0,mySecs1.indexOf(".")) + " sec.";'#13'document.forms[0].timespent.value = mySecs1'#13'if (timerEnabled)'#13'window.setTimeout(''getSecs()'',1000); }'#13+
               '// -->'#13'</script>';
 webTimer = '<form><div style="position:fixed;top:0px;left:0px">Refresh in <input type="text" size="20" name="timespent" onfocus="this.blur()" style="font-family: sans-serif; text-align: left; background-color: rgb(0,0,0); color: rgb(255,255,0); border: thin">'+'<input id="b1" value="Start Timer" onclick="timerEnabled = true;window.setTimeout(''getSecs()'',1000);" type="button"/><input id="b2" value="Stop Timer" onclick="timerEnabled = false;" type="button"/></div></form>';
 webHeadTimer = '<HTML><HEAD><TITLE>DM RC Server</TITLE></HEAD>'+scriptTimer+'<BODY onload="window.setTimeout(''getSecs()'',1)">'+webTimer+webHome;
 webCommands = '<p><CENTER><a href="/addurl">Добавить закачку</a><br><a href="/list">Вывести список</a></CENTER>';
 webEnd = '</BODY></HTML>';
 webBanner = webHeadNoTimer+webCommands+webEnd;
 webLogin = webHeadNoTimer+'<font face="courier"><CENTER><FORM ACTION="/login" METHOD="GET">login<P><INPUT width=100px name="login"><P>password<P><INPUT width=100px name="password"><P><INPUT TYPE="submit" VALUE="Login"><P></FORM></CENTER></font>'+webEnd;
 webAddUrl = webHeadNoTimer+'<font face="courier"><CENTER><FORM ACTION="/addurl" METHOD="GET">URL<P><INPUT width=200px name="url"><P>Параметры<P><INPUT width=300px name="params"><P><INPUT TYPE="submit" VALUE="Добавить"><P></FORM></CENTER></font>'+webEnd;
 webUrlAdded = webHeadNoTimer+'<p><CENTER>Ссылка добавлена.</CENTER>'+webEnd;
 webList = webHeadNoTimer+'<font face="courier"><CENTER><FORM ACTION="/list" METHOD="GET">'+'<P>Состояние<SELECT width=100% NAME="state"><OPTION value="0"> 0 - Pause '#13'<OPTION value="2"> 2 - Downloaded '#13'<OPTION value="3"> 3 - Downloading '#13'<OPTION SELECTED value="9"> 9 - All '#13'</SELECT>'+'<P><INPUT TYPE="submit" VALUE="Вывести"><P></FORM></CENTER></font>'+webEnd;
 webListData = webHeadTimer+'<p>%s<p>'+webHome+webEnd;

implementation

end.
 
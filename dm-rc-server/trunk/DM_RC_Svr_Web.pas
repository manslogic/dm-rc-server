unit DM_RC_Svr_Web;

interface

const
 webHome = '<CENTER><a href="/">Download Master Remote Control Server</a></CENTER>';
 webHead = '<HTML><HEAD><TITLE>DM RC Server</TITLE></HEAD><BODY>'+webHome;
 webCommands = '<p><CENTER><a href="/addurl">Добавить закачку</a><br><a href="/list">Вывести список</a></CENTER>';
 webEnd = '</BODY></HTML>';
 webBanner = webHead+webCommands+webEnd;
 webLogin = webHead+'<font face="courier"><CENTER><FORM ACTION="/login" METHOD="GET">login<P><INPUT width=100px name="login"><P>password<P><INPUT width=100px name="password"><P><INPUT TYPE="submit" VALUE="Login"><P></FORM></CENTER></font></BODY></HTML>';
 webAddUrl = webHead+'<font face="courier"><CENTER><FORM ACTION="/addurl" METHOD="GET">URL<P><INPUT width=200px name="url"><P>Параметры<P><INPUT width=300px name="params"><P><INPUT TYPE="submit" VALUE="Добавить"><P></FORM></CENTER></font></BODY></HTML>';
 webUrlAdded = webhead+'<p><CENTER>Ссылка добавлена.</CENTER></BODY></HTML>';
 webList = webHead+'<p>%s<p>'+webHome+webEnd;

implementation

end.
 
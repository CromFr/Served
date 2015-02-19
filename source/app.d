import vibe.d;
import std.file;
import std.stdio;
import std.conv;
import std.regex;
import config;
import auth;


int main(string[] args) {

	Server srv;
	if(args.length==2 && args[1].isFile){
		writeln("Using config: ", args[1]);

		srv = new Server(args[1]);
	}
	else if(args.length==1 || (args.length==2 && args[1].isDir)){

		srv = new Server(DirEntry(args.length==2? args[1] : "."));
	}
	else{
		writeln("Usage:\n\tserved dir\n\t\tStart serving a specific directory using default configuration\n\tserved cfg\n\t\tStart serving files using cfg as configuration");
	}


	srv.Start();
	
	return 0;
}



class Server{
	import tpl;
	import ftproot;

	this(in string configPath){
		m_conf = Config(readText(configPath));
		Setup();
	}

	this(in DirEntry dir){
		import std.string;
		string[dchar] trans = ['\\':"\\\\", '"':"\\\""];
		m_conf = Config(q"[
		{
			"/": {
				"root": "]"~dir.name.translate(trans)~q"["
			}
		}
		]");
		Setup();
	}

	void Start(){
		listenHTTP(m_settings, &HandleRequest);
		auto cfg = m_conf.GetConfig(".");

		auto user = cfg.default_user.to!string;
		if(user!="") Auth.setUser(cfg.default_user.to!string);
		
		runEventLoop();
	}



private:
	Config m_conf;
	HTTPServerSettings m_settings;
	URLRouter m_router;
	FtpRoot m_ftpPub;
	FtpRoot m_ftpRoots[];

	TemplateDB m_tpldb;



	void Setup(){
		auto srvconf = m_conf.GetConfig(".");

		m_settings = new HTTPServerSettings;
		m_settings.port = srvconf.port.to!ushort;
		m_settings.maxRequestSize = ulong.max;
		m_settings.sessionStore = new MemorySessionStore;

		m_router = new URLRouter;

		m_tpldb = new TemplateDB(srvconf.resource.to!string, srvconf.autoreload.to!bool);

		auto pubconf = parseJsonString(srvconf.toString);
		pubconf.root = pubconf.resource.to!string;
		m_ftpPub = new FtpRoot(pubconf);
		m_ftpPub.setRoute(m_router, "/_served_pub", 0b100);

		foreach_reverse(path ; m_conf.roots){
			auto pathconf = m_conf.GetConfig(path);
			//writeln(pathconf.toPrettyString);

			auto ftproot = new FtpRoot(pathconf);
			ftproot.setRoute(m_router, path, 0b110);
			m_ftpRoots ~= ftproot;
		}
	}


	void HandleRequest(HTTPServerRequest req, HTTPServerResponse res){
		import auth : AuthException;
		import ftproot : SecuredPathException;


		try{

			if(req.method == HTTPMethod.POST && req.contentType=="multipart/form-data"){
				switch(req.form["posttype"]){

					case "login":
						if("login" in req.form && "password" in req.form){

							if(!req.session){
								string login = req.form["login"];
								string password = req.form["password"];

								Auth.checkCredentials(login, password);
								//Let server exception handler handle login failures

								writeln("User logged in as ", req.form["login"]);
								req.session = res.startSession();
								req.session.set("login", login);

								res.redirect(".");
							}
							else{
								res.statusCode = 401;
								res.writeBody("<h1>You are already logged in</h1>", "text/html; charset=UTF-8");
							}
						}
						else{
							res.statusCode = 400;
							res.writeBody("<h1>400: Bad Request</h1>", "text/html; charset=UTF-8");
						}
						return;

					case "logout":
						if(!req.session){
							res.terminateSession();
							res.redirect(".");
						}
						else{
							res.statusCode = 401;
							res.writeBody("<h1>You are not logged in</h1>", "text/html; charset=UTF-8");
						}
						return;


					default: break;
				}

			}
			
			//Default case
			m_router.handleRequest(req, res);

		}
		catch(SecuredPathException e){
			res.statusCode = 403;
			res.writeBody("<h1>Forbidden</h1><p>"~e.msg~"</p>", "text/html; charset=UTF-8");
		}
		catch(AuthException e){
			res.statusCode = 401;
			res.writeBody("<h1>Bad authentification</h1><p>"~e.msg~"</p>", "text/html; charset=UTF-8");
		}
		catch(Throwable t){
			import std.array : replace;
			res.statusCode = 500;
			debug res.writeBody("<h1>Thrown</h1><p>"~t.msg~"</p><hr/><ul><li>"~t.info.toString.replace("\n", "</li><li>")~"</li></ul></p>", "text/html; charset=UTF-8");
			else res.writeBody("<h1>Thrown</h1><p>"~t.msg~"</p>", "text/html; charset=UTF-8");
		}

	}

}







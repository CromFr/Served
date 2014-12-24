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
		m_conf = Config(q"[
		{
			"/": {
				"root": "]"~dir.name~q"["
			}
		}
		]");
		Setup();
	}

	void Start(){
		listenHTTP(m_settings, m_router);
		auto cfg = m_conf.GetConfig(".");
		Auth.setUser(cfg.default_user.to!string);
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

		m_router = new URLRouter;

		m_tpldb = new TemplateDB(srvconf.resource.to!string);

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

}







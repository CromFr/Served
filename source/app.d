import vibe.d;
import std.file;
import std.expe.path;
import std.stdio;
import std.conv;
import std.regex;
import std.algorithm;

import tpl;
import config;


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
		runEventLoop();
	}



private:
	Config m_conf;
	HTTPServerSettings m_settings;
	URLRouter m_router;
	FtpRoot m_ftpPub;
	FtpRoot m_ftpRoots[];



	void Setup(){
		auto srvconf = m_conf.GetConfig(".");
		writeln(m_conf.json);

		m_settings = new HTTPServerSettings;
		m_settings.port = srvconf.port.to!ushort;
		m_settings.maxRequestSize = ulong.max;

		m_router = new URLRouter;

		m_ftpPub = new FtpRoot(srvconf.resource.to!string, srvconf.resource.to!string, r"^\..*?$");
		m_ftpPub.setRoute(m_router, "/_served_pub", 0b100);

		foreach(key, path ; m_conf.roots){
			auto pathconf = m_conf.GetConfig(path);
			writeln(pathconf.toPrettyString);

			auto ftproot = new FtpRoot(pathconf.root.to!string, srvconf.resource.to!string, pathconf.blacklist.to!string);
			ftproot.setRoute(m_router, key, 0b110);
			m_ftpRoots ~= ftproot;
		}
	}

}





class FtpRoot{
	this(in string path, in string tplDir, in string blacklist=""){
		auto normpath = normalizedPath(path);
		assert(normpath.exists, "'"~normpath~"' does not exists");
		assert(normpath.isDir, "'"~normpath~"' must be a folder");
		m_de = normpath;

		m_tplPage = new Template(buildPath(tplDir, "page.tpl"));
		m_tplFile = new Template(buildPath(tplDir, "file.tpl"));

		m_blacklist = regex(blacklist);
	}

	void setRoute(URLRouter router, string prefix, int accessrights=0b100){
		m_prefix = prefix;

		if(accessrights & 0b100){//read
			router.get(m_prefix~"*", &Serve);
		}
		if(accessrights & 0b010){//write
			router.post(m_prefix~"*", &Serve);
		}
	}

	void Serve(HTTPServerRequest req, HTTPServerResponse res){

		try{
			auto reqpath = normalizedPath(req.path).chompPrefix(normalizedPath(m_prefix));

			auto reqFullPath = buildSecuredPath(m_de, "./"~reqpath);

			if(!reqFullPath.exists){
				res.statusCode = 404;
				res.writeBody("<h1>404: Not found</h1><p>"~reqFullPath~" does not exist</p>", "text/html; charset=UTF-8");
				return;
			}
			

			switch(req.method){
				case HTTPMethod.GET:{
					writeln("GET:  ",reqFullPath);

					if(reqFullPath.isDir){
						ServeDir(req, res, DirEntry(reqFullPath));
					}
					else{
						ServeFile(req, res, DirEntry(reqFullPath));
					}

				}break;

				case HTTPMethod.POST:{
					writeln("POST ",req.form["posttype"],": ",reqFullPath);
					if(req.contentType=="multipart/form-data"){

						switch(req.form["posttype"]){
							case "uploadfile":{
								auto files = req.files;
								foreach(f ; files){

									auto tmppath = f.tempPath.toNativeString;
									auto targetpath = buildSecuredPath(reqFullPath, f.filename.toString);

									tmppath.copy(targetpath);
									logInfo("Uploaded file: "~targetpath);
								}
								ServeDir(req, res, DirEntry(reqFullPath));
							}break;

							case "newfolder":{
								string path = buildSecuredPath(reqFullPath, req.form["name"]);
								mkdir(path);
								logInfo("Created folder: "~path);

								ServeDir(req, res, DirEntry(reqFullPath));
							}break;

							case "rename":{
								string curname = buildSecuredPath(reqFullPath, req.form["file"]);
								string newname = buildSecuredPath(reqFullPath, req.form["name"]);
								rename(curname, newname);
								logInfo("Renamed: "~curname~" into "~newname);

								ServeDir(req, res, DirEntry(reqFullPath));
							}break;

							case "remove":{
								string path = buildSecuredPath(reqFullPath, req.form["file"]);
								remove(path);
								logInfo("Removed: "~path);

								ServeDir(req, res, DirEntry(reqFullPath));
							}break;

							case "move":{
								string file = buildSecuredPath(reqFullPath, req.form["file"]);
								string dest = buildSecuredPath(reqFullPath, req.form["destination"], req.form["file"]);
								file.rename(dest);
								logInfo("Moved: "~file~" to "~dest);

								ServeDir(req, res, DirEntry(reqFullPath));
							}break;

							default:
								res.statusCode = 405;
						}



					}

				}break;

				default:
					writeln("Unhandled method: ",req.method);
			}
		}
		catch(SecuredPathException e){
			res.writeBody("<h1>403: Forbidden</h1><p>"~e.msg~"</p>", "text/html; charset=UTF-8");
		}
	}

	


private:
	DirEntry m_de;
	Regex!char m_blacklist;
	string m_prefix;
	Template m_tplPage;
	Template m_tplFile;

	class SecuredPathException : Exception{
		this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null){
			super(msg, file, line, next);
		}
	}
	string buildSecuredPath(VT...)(VT path){
		auto normpath = normalizedPath(path);
		auto relPath = normpath.relativePath(m_de);
		auto relPathSplit = relPath.pathSplitter;

		//Forbid escaping from ftp root
		if(relPathSplit.front==".."){
			throw new SecuredPathException("You cannot go under the file-server root directory");
		}

		//Apply the regex blacklist
		if(relPath != "."){
			foreach(dir ; relPathSplit){
				if(dir.matchFirst(m_blacklist)){
					throw new SecuredPathException("The file/folder '"~dir.to!string~"' is blacklisted");
				}
			}
		}

		return normpath;
	}

	


	void ServeDir(ref HTTPServerRequest req, ref HTTPServerResponse res, DirEntry path){


		string NavbarPath(){
			string ret;
			string link;
			foreach(folder ; req.path.normalizedPath.pathSplitter){
				link = normalizedPath(link, folder);

				ret~="<li><a href=\""~link~"\">"~folder~"</a></li>";
			}
			return ret;
		}

		string HeaderIndex(){

			auto indexmd = path.buildPath("index.md");
			if(indexmd.exists){
				auto res = requestHTTP("https://api.github.com/markdown",
					(scope req) {
						import std.file;
						req.method = HTTPMethod.POST;
						req.writeJsonBody([
							"text": readText(indexmd),
							"mode":"markdown"
						]);
					}
				);
				return "<div class=\"container\">"~res.bodyReader.readAllUTF8()~"</div>";
			}
			return "";

		}

		string FileList(){
			string ret;

			//Sort DirEntries (directories first, alphabetical order after)
			bool SortDirs(ref DirEntry a, ref DirEntry b){
				if(a.isDir==b.isDir)return a.name<b.name;
				return a.isDir>b.isDir;
			}

			DirEntry[] files;
			files ~= DirEntry("..");
			foreach(f ; dirEntries(path, SpanMode.shallow))
				files ~= f;

			bool bPrevSep = false;
			bool bDirSep = false;
			int i = 0;
			foreach(de ; files.sort!SortDirs){
				int id = i++;

				if(de.name!=".." && de.baseName.matchFirst(m_blacklist)){
					continue;
				}

				if(bPrevSep==false && de.name!=".."){
					ret~="<tr><td class=\"bg-primary\" colspan=\"10\"></td></tr>\n";
					bPrevSep = true;
				}
				if(bDirSep==false && !de.isDir){
					ret~="<tr><td class=\"bg-primary\" colspan=\"10\"></td></tr>\n";
					bDirSep = true;
				}



				string sIcon;
				if(de.isDir)		sIcon="glyphicon glyphicon-folder-open";
				else if(de.isFile)	sIcon="glyphicon glyphicon-file";
				else				sIcon="glyphicon glyphicon-question-sign";

				string sIconLink;
				if(de.isSymlink)	sIconLink="glyphicon glyphicon-link";

				auto size = de.size;
				auto logsize = std.math.log10(de.size);

				string sizePretty;
				if(logsize<3.5)			sizePretty=(size).to!string~" <span class=\"unit-simple\">_B</span>";
				else if(logsize<6.5)	sizePretty=(size/1_000).to!string~" <span class=\"unit-kilo\">KB</span>";
				else if(logsize<9.5)	sizePretty=(size/1_000_000).to!string~" <span class=\"unit-mega\">MB</span>";
				else					sizePretty=(size/1_000_000_000).to!string~" <span class=\"unit-giga\">GB</span>";

				string[string] map = [
					"ID": id.to!string,
					"NAME": de.baseName,
					"LINK": normalizedPath(req.path, de.baseName),
					"ICON": sIcon,
					"ICON_LINK": sIconLink,
					"SIZE_PRETTY": sizePretty,
					"SIZE_PERCENT": ((logsize-2>0?logsize-2:0)/0.08).to!string,
					"IS_FOLDER": de.isDir ? "true" : "false",
				];

				void MergeMaps(T)(ref T mapA, in T mapB){
					foreach(k, v ; mapB){
						mapA[k] = v;
					}
				}

				version(Posix){
					//Rights
					string GetRightString(int right){
						string ret;
						if(right&0b100)	ret~="r"; else ret~="-";
						if(right&0b010)	ret~=" w "; else ret~=" - ";
						if(right&0b001)	ret~="x"; else ret~="-";
						return ret;
					}
					import core.sys.posix.unistd;
					import core.sys.posix.pwd;
					import core.sys.posix.grp;
					auto stat = de.statBuf;
					int rightType;
					if(getuid() == stat.st_uid)		rightType=2;
					else if(getgid() == stat.st_gid)rightType=1;
					else							rightType=0;

					MergeMaps(map, [
						"RIGHTS": GetRightString((stat.st_mode>>(3*rightType)) & 0b111),
						"USER": getpwuid(stat.st_uid).pw_name.to!string,
						"GROUP": getgrgid(stat.st_gid).gr_name.to!string,
						"RIGHT_USER_STYLE": rightType==2 ? "active" : "disabled",
						"RIGHT_USER": GetRightString((stat.st_mode>>6) & 0b111),
						"RIGHT_GROUP_STYLE": rightType==1 ? "active" : "disabled",
						"RIGHT_GROUP": GetRightString((stat.st_mode>>3) & 0b111),
						"RIGHT_OTHER_STYLE": rightType==0 ? "active" : "disabled",
						"RIGHT_OTHER": GetRightString((stat.st_mode>>0) & 0b111),
					]);
				}

				ret~= m_tplFile.Generate(map);
			}

			return ret;
		}

		auto page = res.bodyWriter;
		auto map = [
			"PAGE_TITLE" : path.baseName,
			"NAVBAR_PATH" : NavbarPath(),
			"HEADER_INDEX" : HeaderIndex(),
			"FILE_LIST" : FileList()
		];

		page.write(m_tplPage.Generate(map));
	}

	void ServeFile(ref HTTPServerRequest req, ref HTTPServerResponse res, DirEntry path){
		auto callback = serveStaticFile(path);
		callback(req, res);
	}


}

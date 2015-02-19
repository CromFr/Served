module ftproot;

import vibe.d;
import std.file;
import std.expe.path;
import std.regex;
import std.stdio : writeln;

import auth;
import tpl;



class SecuredPathException : Exception{
	this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null){
		super(msg, file, line, next);
	}
}

class FtpRoot{
	this(in Json conf){
		auto normpath = normalizedPath(conf.root.to!string);
		assert(normpath.exists, "'"~normpath~"' does not exists");
		assert(normpath.isDir, "'"~normpath~"' must be a folder");
		m_de = normpath;

		m_blacklist = regex(conf.blacklist.to!string);
		m_defaultUser = conf.default_user.to!string;
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

		auto fun = delegate(){
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

								res.redirect(reqpath);
							}break;

							case "newfolder":{
								string path = buildSecuredPath(reqFullPath, req.form["name"]);
								mkdir(path);
								logInfo("Created folder: "~path);

								res.redirect(reqpath);
							}break;

							case "rename":{
								string curname = buildSecuredPath(reqFullPath, req.form["file"]);
								string newname = buildSecuredPath(reqFullPath, req.form["name"]);
								rename(curname, newname);
								logInfo("Renamed: "~curname~" into "~newname);

								res.redirect(reqpath);
							}break;

							case "remove":{
								string path = buildSecuredPath(reqFullPath, req.form["file"]);
								remove(path);
								logInfo("Removed: "~path);

								res.redirect(DirEntry(reqFullPath));
							}break;

							case "move":{
								string file = buildSecuredPath(reqFullPath, req.form["file"]);
								string dest = buildSecuredPath(reqFullPath, req.form["destination"], req.form["file"]);
								file.rename(dest);
								logInfo("Moved: "~file~" to "~dest);

								res.redirect(reqpath);
							}break;

							default:
								res.statusCode = 405;
						}



					}

				}break;

				default:
					writeln("Unhandled method: ",req.method);
			}
		};

		if(req.session)            Auth.executeAs(req.session.get!string("login"), fun);
		else if(m_defaultUser!="") Auth.executeAs(m_defaultUser, fun);
		else                       fun();
	}

	


private:
	DirEntry m_de;
	Regex!char m_blacklist;
	string m_prefix;
	string m_defaultUser;

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
					if(geteuid() == stat.st_uid)     rightType=2;
					else if(getegid() == stat.st_gid)rightType=1;
					else                             rightType=0;

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

				ret~= TemplateDB["file.tpl"].Generate(map);
			}

			return ret;
		}

		auto page = res.bodyWriter;
		auto map = [
			"PAGE_TITLE" : path.baseName,
			"NAVBAR_PATH" : NavbarPath(),
			"HEADER_INDEX" : HeaderIndex(),
			"FILE_LIST" : FileList(),
			"USER" : req.session? req.session.get!string("login") : "Default user"
		];

		page.write(TemplateDB["page.tpl"].Generate(map));
	}

	void ServeFile(ref HTTPServerRequest req, ref HTTPServerResponse res, DirEntry path){
		auto callback = serveStaticFile(path);
		callback(req, res);
	}


}
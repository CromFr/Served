import vibe.d;
import std.file;
import std.path;
import std.stdio;
import std.conv;
import std.regex;
import std.algorithm;

import tpl;


int main(string[] args) {
	auto tplPage = new Template("Public/page.tpl");

	auto settings = new HTTPServerSettings;
	settings.port = 8080;

	auto f = new FtpRoot(args[1], tplPage, r"^\..*?$");
	auto ftpPub = new FtpRoot("./Public", tplPage, r"^\..*?$");


	auto router = new URLRouter;
	ftpPub.setRoute(router, "/_served_pub", 0b100);
	f.setRoute(router, "/", 0b110);

	listenHTTP(settings, router);

	runEventLoop();
	return 0;
}





class FtpRoot{
	this(in string path, ref Template tplPage, in string blacklist=""){
		m_de = DirEntry(path);
		if(!m_de.isDir)
			throw new Exception("Folder constructor must take an existing folder as argument");

		m_tplPage = tplPage;

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
		auto reqpath = buildNormalizedPath(req.path).chompPrefix(buildNormalizedPath(m_prefix));
		auto reqFullPath = buildNormalizedPath(m_de, "./"~reqpath);

		if(!reqFullPath.exists){
			res.statusCode = 404;
			res.writeBody("<h1>404 : Not found</h1><p>"~reqFullPath~" does not exist</p>", "text/html; charset=UTF-8");
			return;
		}

		//Forbid escaping from ftp root
		auto relPath = relativePath(reqFullPath, m_de).pathSplitter;
		if(relPath.front==".."){
			res.writeBody("<h1>Access Denied : Never go up the root</h1>", "text/html; charset=UTF-8");
			return;
		}

		//Apply the regex blacklist
		foreach(dir ; pathSplitter(reqpath)){
			if(dir.matchFirst(m_blacklist)){
				res.writeBody("<h1>Access Denied by FTP Rule</h1>", "text/html; charset=UTF-8");
				return;
			}
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
				writeln("POST: ",reqFullPath);
				if(req.contentType=="multipart/form-data"){
					auto files = req.files;
					foreach(f ; files){

						auto tmppath = f.tempPath.toNativeString;
						auto targetpath = buildNormalizedPath(reqFullPath, f.filename.toString);

						logInfo("Uploaded file: ",targetpath);
						tmppath.copy(targetpath);
					}
					ServeDir(req, res, DirEntry(reqFullPath));


				}

			}break;

			default:
				writeln("Unhandled method: ",req.method);
		}


	}

	


private:
	DirEntry m_de;
	Regex!char m_blacklist;
	string m_prefix;
	Template m_tplPage;


	void ServeDir(ref HTTPServerRequest req, ref HTTPServerResponse res, DirEntry path){


		string NavbarPath(){
			string ret;
			string link;
			foreach(folder ; req.path.buildNormalizedPath.pathSplitter){
				link = buildNormalizedPath(link, folder);

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
			foreach(f ; dirEntries(path, SpanMode.shallow))
				files ~= f;

			foreach(de ; files.sort!SortDirs){

				if(de.baseName.matchFirst(m_blacklist)){
					continue;
				}

				ret~="<tr>";

				ret~="<td class=\"text-nowrap\">";
				if(de.isDir)		ret~="<div class=\"glyphicon glyphicon-folder-open\"></div>";
				else if(de.isFile)	ret~="<div class=\"glyphicon glyphicon-file\"></div>";
				else				ret~="<div class=\"glyphicon glyphicon-question-sign\"></div>";

				if(de.isSymlink)	ret~=" <div class=\"glyphicon glyphicon-link\"></div>";
				ret~="</td>";

				//Name
				ret~="<td class=\"text-forcewrap\"><a href=\""~buildNormalizedPath(req.path, de.baseName)~"\">"~de.baseName~"</a></td>";

				//Size
				auto size = de.size;
				auto logsize = std.math.log10(de.size);


				ret~=q"[
					<td class="text-right text-nowrap">
						<samp>]";

							if(logsize<3.5)			ret~=(size).to!string~" <span class=\"unit-simple\">_B</span>";
							else if(logsize<6.5)	ret~=(size/1_000).to!string~" <span class=\"unit-kilo\">KB</span>";
							else if(logsize<9.5)	ret~=(size/1_000_000).to!string~" <span class=\"unit-mega\">MB</span>";
							else					ret~=(size/1_000_000_000).to!string~" <span class=\"unit-giga\">GB</span>";

							ret~=q"[
						</samp>
					</td>
					<td style="min-width: 50px; width:100%;">
						<div class="progress" style="margin: 0;">
							<div class="progress-bar progress-bar-info progress-bar-striped" role="progressbar" style="width: ]"~((logsize-2>0?logsize-2:0)/0.08).to!string~q"[%">
							</div>
						</div>
					</td>]";

				ret~="</tr>\n";
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

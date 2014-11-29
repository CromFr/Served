import vibe.d;
import std.file;
import std.path;
import std.stdio;
import std.conv;
import std.regex;
import std.algorithm;


int main(string[] args) {

	auto settings = new HTTPServerSettings;
	settings.port = 8080;

	auto f = new FtpRoot(args[1], r"^\..*?$");
	auto ftpPub = new FtpRoot("./Public", r"^\..*?$");


	auto router = new URLRouter;
	ftpPub.setRoute(router, "/_served_pub", 0b100);
	f.setRoute(router, "/", 0b110);

	listenHTTP(settings, router);

	runEventLoop();
	return 0;
}





class FtpRoot{
	this(in string path, in string blacklist=""){
		m_de = DirEntry(path);
		if(!m_de.isDir)
			throw new Exception("Folder constructor must take an existing folder as argument");

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


	void ServeDir(ref HTTPServerRequest req, ref HTTPServerResponse res, DirEntry path){

		DirEntry[] files;
		foreach(f ; dirEntries(path, SpanMode.shallow))
			files ~= f;

		auto page = res.bodyWriter;
		page.write(q"[
			<!DOCTYPE html>
			<html>
				<head>
					<meta http-equiv="Content-Type" content="text/html;charset=utf-8"/>
				    <meta name="viewport" content="width=device-width, initial-scale=1">

					<title>]"~path.baseName~q"[</title>
					<link rel="stylesheet" href="/_served_pub/bootstrap/css/bootstrap.min.css" type="text/css"/>
					<link rel="stylesheet" href="/_served_pub/style.css" type="text/css"/>
				</head>
				<body>
					<nav class="navbar navbar-inverse navbar-fixed-top" role="navigation">
						<div class="container">
							<div class="navbar-header">
								<a class="navbar-brand" href='https://github.com/CromFr/Served'>Served</a>
							</div>
							<div id="navbar" class="navbar-collapse collapse">
								<ul class="nav navbar-nav">]"~{

									string ret;
									string link;
									foreach(folder ; req.path.buildNormalizedPath.pathSplitter){
										link = buildNormalizedPath(link, folder);

										ret~="<li><a href=\""~link~"\">"~folder~"</a></li>";
									}
									return ret;

								}()~q"[
								</ul>
							</div>
						</div>
					</nav>]"~{

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
							return "<div class=\"jumbotron\"><div class=\"container\">"~res.bodyReader.readAllUTF8()~"</div></div>";
						}
						return "";

					}()~q"[
					<div class="container">
						<div class="table-responsive">
	            			<table class="table table-striped">
								<thead>
									<tr><th></th><th>Name</th><th colspan="2">Size</th></tr>
								</thead>
								<tbody>
								<!-- FILE LIST -->]"
								~'\n');

								//Sort DirEntries (directories first, alphabetical order after)
								bool SortDirs(ref DirEntry a, ref DirEntry b){
									if(a.isDir==b.isDir)return a.name<b.name;
									return a.isDir>b.isDir;
								}
								foreach(de ; files.sort!SortDirs){

									if(de.baseName.matchFirst(m_blacklist)){
										continue;
									}

									page.write("<tr>");

									page.write("<td>");
									if(de.isSymlink)	page.write("-&gt;");

									if(de.isDir)		page.write("<div class=\"glyphicon glyphicon-folder-open\"></div>");
									else if(de.isFile)	page.write("<div class=\"glyphicon glyphicon-file\"></div>");
									else				page.write("<div class=\"glyphicon glyphicon-question-sign\"></div>");
									page.write("</td>");

									//Name
									page.write("<td><a href=\""~buildNormalizedPath(req.path, de.baseName)~"\">"~de.baseName~"</a></td>");

									//Size
									auto size = de.size;
									auto logsize = std.math.log10(de.size);

									if(logsize<3.5)			page.write("<td>"~(size).to!string~" <span class=\"unit-simple\">B</span></td>");
									else if(logsize<6.5)	page.write("<td>"~(size/1_000).to!string~" <span class=\"unit-kilo\">KB</span></td>");
									else if(logsize<9.5)	page.write("<td>"~(size/1_000_000).to!string~" <span class=\"unit-mega\">MB</span></td>");
									else					page.write("<td>"~(size/1_000_000_000).to!string~" <span class=\"unit-giga\">GB</span></td>");


									page.write("<td><progress value=\""~(logsize-2>0?logsize-2:0.1).to!string~"\" min=\"0\" max=\"8\"></progress></td>");

									page.write("</tr>\n");
								}

								page.write(q"[
								<!-- ######### -->
								</tbody>
							</table>

							<form enctype="multipart/form-data" method="POST">
								<input type="hidden" name="FileUpload" value="1" />
								<input type="hidden" name="MAX_FILE_SIZE" value="100000" />
								Choose a file to upload: <input name="uploadedfile" type="file" /><br />
								<input type="submit" value="Upload File" />
							</form>
							<div id="dropzone" class="fade well"></div>
							<script src="/_served_pub/dropupload.js" type="text/javascript"></script>
						</div>
					</div>
					<script src="/_served_pub/jquery/jquery.min.js"></script>
					<script src="/_served_pub/bootstrap/js/bootstrap.min.js"></script>
				</body>
			</html>
		]");
	}

	void ServeFile(ref HTTPServerRequest req, ref HTTPServerResponse res, DirEntry path){
		auto callback = serveStaticFile(path);
		callback(req, res);
	}


}

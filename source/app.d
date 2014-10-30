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
	settings.bindAddresses = ["::1", "127.0.0.1"];

	auto f = new FtpRoot("/home/crom", r"^\..*?$");
	listenHTTP(settings, &f.Serve);

	//listenHTTP(settings, serveStaticFile("dub.json"));


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

	void Serve(HTTPServerRequest req, HTTPServerResponse res){
		auto reqFullPath = DirEntry(buildNormalizedPath(m_de, "."~req.path));


		//Forbid escaping from ftp root
		auto relPath = relativePath(reqFullPath, m_de).pathSplitter;
		writeln("full=",reqFullPath,"\t\tm_de=",m_de);
		writeln(relPath,"\t\tfront=",relPath.front);
		if(relPath.front==".."){
			res.writeBody("<h1>Access Denied : Never go up the root</h1>", "text/html; charset=UTF-8");
			return;
		}


		foreach(dir ; pathSplitter(req.path)){
			if(dir.matchFirst(m_blacklist)){
				res.writeBody("<h1>Access Denied by FTP Rule</h1>", "text/html; charset=UTF-8");
				return;
			}
		}

		switch(req.method){
			case HTTPMethod.GET:{
				writeln(reqFullPath);
				if(reqFullPath.isDir){
					ServeDir(req, res, reqFullPath);
				}
				else{
					ServeFile(req, res, reqFullPath);
				}

			}break;

			case HTTPMethod.POST:{
				if(req.contentType=="multipart/form-data"){
					auto files = req.files;
					foreach(f ; files){

						auto tmppath = f.tempPath.toNativeString;
						auto targetpath = buildNormalizedPath(reqFullPath, f.filename.toString);

						logInfo("Uploaded file ",targetpath);
						tmppath.copy(targetpath);
					}
					ServeDir(req, res, reqFullPath);


				}

			}break;

			default:
				writeln("Unhandled method: ",req.method);
		}


	}

	


private:
	DirEntry m_de;
	Regex!char m_blacklist;


	void ServeDir(ref HTTPServerRequest req, ref HTTPServerResponse res, DirEntry path){

		DirEntry[] files;
		foreach(f ; dirEntries(path, SpanMode.shallow))
			files ~= f;

		auto page = res.bodyWriter;
		page.write(q{
			<!DOCTYPE html>
			<html>
				<head>
					<meta http-equiv="Content-Type" content="text/html;charset=utf-8">
					<title>}~path.baseName~q{</title>
				</head>
				<body>
					<table>
						<tr><th>Type</th><th>Name</th><th>Size</th></tr>
		});

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
			if(de.isSymlink)	page.write("->");

			if(de.isDir)		page.write("D");
			else if(de.isFile)	page.write("F");
			else				page.write("?");
			page.write("</td>");

			//Name
			page.write("<td><a href=\""~buildNormalizedPath(req.path, de.baseName)~"\">"~de.baseName~"</a></td>");

			//Size
			page.write("<td>");
			float fSize = de.size/1_000_000.0;
			if(fSize<0.01)	page.write("<0.01 MB");
			else 			page.write(format("%.2f MB",fSize));
			page.write("</td>");

			page.write("</tr>");
		}
		page.write("</table>");

		page.write(q{
			<form enctype="multipart/form-data" method="POST">
				<input type="hidden" name="FileUpload" value="1" />
				<input type="hidden" name="MAX_FILE_SIZE" value="100000" />
				Choose a file to upload: <input name="uploadedfile" type="file" /><br />
				<input type="submit" value="Upload File" />
			</form>

			</body>
			</html>
		});
	}

	void ServeFile(ref HTTPServerRequest req, ref HTTPServerResponse res, DirEntry path){
		auto ans = serveStaticFile(path);
		ans(req, res);
	}


}

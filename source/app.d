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

	auto f = new FtpRoot(args[1], r"^\..*?$");
	listenHTTP(settings, &f.Serve);


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

		//Apply the regex blacklist
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
		page.write(q"[
			<!DOCTYPE html>
			<html>
				<head>
					<meta http-equiv="Content-Type" content="text/html;charset=utf-8"/>
					<title>]"~path.baseName~q"[</title>
					<style>
					#dropzone {
						background: palegreen;
						width: 150px;
						height: 50px;
						line-height: 50px;
						text-align: center;
						font-weight: bold;
					}
					#dropzone.in {
						width: 600px;
						height: 200px;
						line-height: 200px;
						font-size: larger;
					}
					#dropzone.hover {
						background: lawngreen;
					}
					#dropzone.fade {
						-webkit-transition: all 0.3s ease-out;
						-moz-transition: all 0.3s ease-out;
						-ms-transition: all 0.3s ease-out;
						-o-transition: all 0.3s ease-out;
						transition: all 0.3s ease-out;
						opacity: 1;
					}
					</style>
				</head>
				<body>
					<div id="dropzone" class="fade well"></div>
					<script>
						var drop = document.getElementById('dropzone');

						drop.addEventListener('dragover', function(e){
						  e.preventDefault();
						  drop.className = drop.className+" hover";
						}, false);
						drop.addEventListener('dragenter', function(e){
						  e.preventDefault();
						  drop.className = drop.className.replace(/\bhover\b/,'');
						}, false);

						drop.addEventListener('drop', function(e){
						  e.preventDefault();
						  drop.className = drop.className.replace(/\bhover\b/,'');
						  
						  var dt = e.dataTransfer;
						  var files = dt.files;
						  for(var i=0; i<files.length; i++){
						    var file = files[i];
						    console.log(file);
						    
						    var xhr = new XMLHttpRequest();
						    xhr.open('POST', window.location.pathname);
						    xhr.onload = function() {
						      //result.innerHTML += this.responseText;
						      //handleComplete(file.size);
						    };
						    xhr.onerror = function() {
						      //result.textContent = this.responseText;
						      //handleComplete(file.size);
						    };
						    xhr.upload.onprogress = function(event){
						        //var progress = totalProgress + event.loaded;
						        //console.log(progress / totalSize);
						    }
						    xhr.upload.onloadstart = function(event) {
						    }

						    // création de l'objet FormData
						    var formData = new FormData();
						    formData.append('uploadedfile', file);
						    xhr.send(formData);
						  }
						  
						}, false);
					</script>
					<table>
						<tr><th>Type</th><th>Name</th><th>Size</th></tr>
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

			if(de.isDir)		page.write("D");
			else if(de.isFile)	page.write("F");
			else				page.write("?");
			page.write("</td>");

			//Name
			page.write("<td><a href=\""~buildNormalizedPath(req.path, de.baseName)~"\">"~de.baseName~"</a></td>");

			//Size
			page.write("<td>");
			float fSize = de.size/1_000_000.0;
			if(fSize<0.01)	page.write("&lt;0.01 MB");
			else 			page.write(format("%.2f MB",fSize));
			page.write("</td>");

			page.write("</tr>\n");
		}

		page.write(q"[
						<!-- ######### -->
					</table>
					<form enctype="multipart/form-data" method="POST">
						<input type="hidden" name="FileUpload" value="1" />
						<input type="hidden" name="MAX_FILE_SIZE" value="100000" />
						Choose a file to upload: <input name="uploadedfile" type="file" /><br />
						<input type="submit" value="Upload File" />
					</form>

				</body>
			</html>
		]");
	}

	void ServeFile(ref HTTPServerRequest req, ref HTTPServerResponse res, DirEntry path){
		auto callback = serveStaticFile(path);
		callback(req, res);
	}


}

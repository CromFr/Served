module config;

import std.stdio;
import std.expe.path;
import vibe.data.json;

struct Config{

	this(in string json){
		//Setup default config
		defaultConfig = parseJsonString(q"[{
			"listen": "localhost",
			"port": "8080",
			"default_user": "",
			"users_read": ["all"],
			"users_write": [""],
			"root": ".",
			"blacklist": "^\\..*?$",
			"resource": "Public"
		}]");

		
		//Parse config file
		import std.file;
		m_container = parseJsonString(json);
		assert(m_container.type == Json.Type.object, "Config should be packed in a json object");


		void RegisterRoots(Json obj, in string prefix=""){
			foreach(string key, value ; obj){
				if(value.type==Json.Type.object){
					if(prefix!=""){
						string newPrefix = key.isAbsolute? "."~key : key;
						m_rootsPath ~= normalizedPath(prefix, newPrefix);
					}
					else{
						m_rootsPath ~= normalizedPath(key);
					}
					RegisterRoots(value, m_rootsPath[$-1]);
				}
			}
		}

		RegisterRoots(m_container);
		writeln("m_rootsPath=", m_rootsPath);
	}




	Json GetConfig(in string path){

		Json GetConfigRecurse(in string path, ref Json root, ref Json ret){
			import std.algorithm;

			if(root.type != Json.Type.undefined){
				Json jsonobj[string];

				//Update ret config and register objects for next loop
				foreach(string key, value ; root){
					if(value.type!=Json.Type.object){
						if(key=="root"){
							//Special rule for root option: relative path will be relative to the parent root
							ret[key] = normalizedPath(ret[key].to!string, value.to!string);
						}
						else
							ret[key] = value;
					}
					else{
						jsonobj[key] = value;
					}
				}

				foreach(key, value ; jsonobj){
					//Make path "absolute"
					string keypath = (key.isAbsolute? key : dirSeparator~key).normalizedPath;
					string targetpath = (path.isAbsolute? path : dirSeparator~path).normalizedPath;

					if(targetpath.startsWith(keypath)){
						return GetConfigRecurse(targetpath.relativePath(keypath), value, ret);
					}
				}
			}


			//TODO: handle path that are longer than roots
			//Check ../path behavior
			return ret;
		}

		Json j = defaultConfig;
		return GetConfigRecurse(path, m_container, j);
	}

	@property string[] roots(){return m_rootsPath;}
	@property string json(){return m_container.toPrettyString;}

private:
	Json defaultConfig;
	Json m_container;
	string m_rootsPath[];

}
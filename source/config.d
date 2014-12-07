module config;

import std.stdio;
import std.path;
import vibe.data.json;

class Config{
	this(in string jsonpath){
		//Setup default config
		defaultConfig = parseJsonString(q"[{
			"listen": "localhost",
			"port": "80",
			"default_user": "",
			"users_read": ["all"],
			"users_write": [""],
			"root": "."
		}]");

		//Parse config file
		import std.file;
		m_container = parseJsonString(readText(jsonpath));
		assert(m_container.type == Json.Type.object, "Config should be packed in a json object");
	}




	Json GetConfig(in string path){

		Json GetConfigRecurse(in string path, ref Json root, ref Json ret){
			import std.algorithm;

			Json jsonobj[string];

			//Update ret config and register objects for next loop
			foreach(string key, value ; root){
				if(value.type!=Json.Type.object){
					if(key=="root"){
						//Special rule for root option: relative path will be relative to the parent root
						ret[key] = buildNormalizedPath(ret[key].to!string, value.to!string);
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
				string keypath = (key.isAbsolute? key : dirSeparator~key).buildNormalizedPath;
				string targetpath = (path.isAbsolute? path : dirSeparator~path).buildNormalizedPath;

				if(targetpath.startsWith(keypath)){
					return GetConfigRecurse(targetpath.relativePath(keypath), value, ret);
				}
			}

			//TODO: handle path that are longer than roots
			//Check ../path behavior
			return ret;
		}

		Json j = defaultConfig;
		return GetConfigRecurse(path, m_container, j);
	}


private:
	Json defaultConfig;
	Json m_container;

}
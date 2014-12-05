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


	Json m_container;
	Json[string] m_roots;

	Json defaultConfig;


	Json GetPathConfig(in string path){

		Json GetPathConfigRecurse(in string path, ref Json root, Json ret){
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
					return GetPathConfigRecurse(targetpath.relativePath(keypath), value, ret);
				}
			}
			return ret;
		}

		return GetPathConfigRecurse(path, m_container, defaultConfig);
	}


	//class Node {
	//	this(ref Node parent, in string path){

	//		m_path = path;

	//		if(parent !is null){
	//			m_parent = &parent;
	//			parent.children ~= this;
	//		}

	//		assert
	//	}

	//	@property ref Node parent(){ return *m_parent; }
	//	@property ref Node[] children(){ return m_children; }

	//	@property T get(T)(in string key){
	//		m_container.
	//		return get!T(key);
	//	}

	//private:
	//	Json m_container;
	//	string m_path;

	//	Node* m_parent;
	//	Node m_children[];
	//}




private:

}
module tpl;

import std.regex;
import std.stdio;
import std.file;
import std.path : baseName;
import std.datetime : SysTime;

class Template{
	
	this(string path, bool reloadIfModified){
		m_path = path;
		m_reload = reloadIfModified;
		Load();
	}

	auto ref Generate(in string[string] symbolmap){

		if(m_reload && m_lastReload<timeLastModified(m_path))
			Load();

		string MapSym(Captures!(string) m)
		{
			if(m[1] in symbolmap)
				return symbolmap[m[1]];

			return m[0];
		}

		return replaceAll!MapSym(content, rgxEntry);
	}


private:
	void Load(){
		content = readText(m_path);
		m_lastReload = timeLastModified(m_path);

		//TODO: Fetch all fields now and register indexes

		writeln("Loaded ",m_path.baseName);
	}


	immutable string m_path;
	bool m_reload;
	SysTime m_lastReload;
	string content;
	enum rgxEntry = ctRegex!r"\{\{(.*?)\}\}";

}



class TemplateDB{
	import std.algorithm : map;
	import std.path : baseName;

	this(in string directory, bool reloadIfModified){

		foreach(f ; dirEntries(directory, "*.tpl", SpanMode.shallow)){
			if(f.isFile)
				m_tpl[f.baseName] = new Template(f, reloadIfModified);
		}
		m_inst = this;
	}

	static auto ref opIndex(in string name){
		assert(m_inst !is null);
		with(m_inst){
			if(name in m_tpl)
				return m_tpl[name];
			else{
				throw new Exception("Template file '"~name~"' not found !");
			}
		}
	}

private:
	static __gshared TemplateDB m_inst;
	Template[string] m_tpl;
}
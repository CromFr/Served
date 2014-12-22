module tpl;

import std.regex;
import std.stdio;
import std.file;

class Template{
	
	this(string path){
		content = readText(path);

		//TODO: Fetch all fields now and register indexes
	}

	auto ref Generate(in string[string] symbolmap){

		string MapSym(Captures!(string) m)
		{
			if(m[1] in symbolmap)
				return symbolmap[m[1]];

			return m[0];
		}

		return replaceAll!MapSym(content, rgxEntry);
	}


private:
	immutable string content;
	enum rgxEntry = ctRegex!r"\{\{(.*?)\}\}";

}



class TemplateDB{
	import std.algorithm : map;
	import std.path : baseName;

	this(in string directory){

		foreach(f ; dirEntries(directory, "*.tpl", SpanMode.shallow)){
			if(f.isFile)
				m_tpl[f.baseName] = new Template(f);
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
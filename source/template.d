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

			return "<!--UNKNOWN:"~m[1]~"-->";
		}

		return replaceAll!MapSym(content, rgxEntry);
	}


private:
	immutable string content;
	enum rgxEntry = ctRegex!r"\{\{(.*?)\}\}";

}
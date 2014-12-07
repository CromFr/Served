module std.expe.path;
public import std.path;

import std.traits;

immutable(C)[] normalizedPath(C)(const(C[])[] paths...)
    @trusted pure nothrow
    if (isSomeChar!C)
{
	auto ret = buildNormalizedPath(paths);
	return ret==""? "." : ret;
}
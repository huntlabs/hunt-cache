module hunt.cache.store;

import kiss.util.serialize;
import hunt.cache.nullable;
//only add header from Serialize for check meta info.
//	meta
//	object

import std.stdio;

byte[] SerializeToByte(T)( T t)
{
	import std.stdio;
	string meta = immutable(T).stringof;

	return serialize(meta[10 .. $-1]) ~ serialize(t);
}

 Nullable!T DeserializeToObject(T)(const byte[] data )
{
	long parser_index;
	if(data.length == 0)
		return Nullable!T.init;

	string meta = unserialize!string(data , parser_index);
	if(immutable(T).stringof[10 .. $-1] != meta)
		return Nullable!T.init;
	Nullable!T nullt;

	nullt.bind(unserialize!T(data[cast(size_t)parser_index .. $]));

	return nullt;
}
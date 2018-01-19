module zhang2018.cache.store;

import kiss.serialize;
import zhang2018.cache.nullable;

//only add header from Serialize for check meta info.
//	meta
//	object

byte[] SerializeToByte(T: const T)(T t)
{
	string meta = T.stringof;
	return serialize(meta) ~ serialize(t);
}

 Nullable!T DeserializeToObject(T : const T)(const byte[] data )
{
	long parser_index;
	if(data.length == 0)
		return Nullable!T.init;

	string meta = unserialize!string(data , parser_index);
	if(T.stringof != meta)
		return Nullable!T.init;
	Nullable!T nullt;

	nullt.bind(unserialize!T(data[parser_index .. $]));

	return nullt;
}
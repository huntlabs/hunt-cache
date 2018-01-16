module zhang2018.cache.store;

import zhang2018.common.Serialize;
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

	string meta = deserialize!string(data , parser_index);
	if(T.stringof != meta)
		return Nullable!T.init;
	Nullable!T nullt;

	nullt.bind(deserialize!T(data[parser_index .. $]));

	return nullt;
}
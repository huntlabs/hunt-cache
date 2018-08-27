module hunt.cache.redis;

import hunt.cache.cache;
import hunt.cache.nullable;
import hunt.cache.store;

import std.conv;
import std.string;

version(SUPPORT_REDIS):

import redis;

class RedisCache
{
	Nullable!V get(V)(string key)
	{
		synchronized(this)
		{
			string data = _redis.send!string("get" , key);
			return DeserializeToObject!V(cast(byte[])data);
		}
	}

	Nullable!V[string] getall(V)(string[] keys)
	{
		synchronized(this){
			Nullable!V[string] mapv;
			if( keys.length == 0)
				return mapv;

			Response r = _redis.send("mget" , keys);

			foreach(i , v ; r.values)
			{
				mapv[keys[i]] = DeserializeToObject!V(cast(byte[])v);
			}

			return mapv;
		}
	}

	bool containsKey(string key)
	{
		synchronized(this)
		{
			return _redis.send!bool("exists" , key);
		}
	}
	
	void put(V)(string key ,  V v , uint expired)
	{
		synchronized(this)
		{
			if( expired == 0)
				_redis.send("set" , key , cast(string)SerializeToByte(v));
			else
				_redis.send("setex" , key , expired , cast(string)SerializeToByte(v));
		}
	}

	bool putifAbsent(V)(string key ,  V v)
	{
		synchronized(this)
		{
				return _redis.send!bool("setnx" , key , cast(string)SerializeToByte(v)) == 1;		
		}

	}

	void putAll(V)( V[string] maps , uint expired)
	{
		synchronized(this){
			if(maps.length == 0)
			return;

			if(expired == 0)
			{
				string cmds = "mset ";
				foreach(k , v ; maps)
				{
					cmds ~= k ~ " " ~ cast(string)SerializeToByte(v) ~ " ";
				}
				_redis.send(cmds);
			}
			else
			{
				string[] cmds;
				foreach( k ,v ; maps){
					cmds ~= "setex " ~ k ~ " " ~ to!string(expired) ~ " " ~ cast(string)SerializeToByte(v);
				}

				_redis.pipeline(cmds);
			}
		}
	}
	
	bool remove(string key)
	{
		synchronized(this)
		{
			return _redis.send!bool("del" , key);
		}
	}

	void removeAll(string[] keys)
	{
		synchronized(this)
		{
			if( keys.length == 0)
			return ;

			string[] cmds;
			foreach(k ; keys){
				cmds ~= "del " ~ k;
			}
			_redis.pipeline(cmds);
		}
	}

	void clear()
	{
		synchronized(this)
		{
			_redis.send("flushdb");
		}
	}

	this(string args)
	{
		if(args == null)
			args = "127.0.0.1:6379";

		auto hp = args.split(":");
		_redis = new Redis(hp[0] , to!ushort(hp[1]));
	}

protected:
	Redis _redis;
}

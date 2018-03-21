module zhang2018.cache.forward;

import zhang2018.cache.memory;
import zhang2018.cache.memcached;
import zhang2018.cache.redis;
import zhang2018.cache.rocksdb;
import zhang2018.cache.cache;
import zhang2018.cache.nullable;
import std.conv;
import std.stdio;
import std.traits;


class Forward
{
	this(Object obj)
	{
		string className = to!string(typeid(obj));
		if(className == to!string(typeid(UCache!MemoryCache)))
		{
			_memory = cast(UCache!MemoryCache)obj;
			return;
		}
		version(SUPPORT_REDIS)
		{
		 	if(className == to!string(typeid(UCache!RedisCache)))
			{
				_redis = cast(UCache!RedisCache)obj;
				return;
			}
		}

		version(SUPPORT_MEMCACHED)
		{ 
			if(className == to!string(typeid(UCache!MemcachedCache)))
			{	_memcahed = cast(UCache!MemcachedCache)(obj);
				return;
			}
		}

		version(SUPPORT_ROCKSDB){
			if(className == to!string(typeid(UCache!RocksdbCache)))
			{	
				_rocksdb = cast(UCache!RocksdbCache)(obj);
				return;
			}
		}

		assert(0);
	}

	//get
	mixin(genfunc("Nullable!V get(V)(string key )" , "get!V(key);"));
	//getall
	mixin(genfunc("Nullable!V[string] getall(V)(string[] keys)" , "getall!V(keys);"));
	//containsKey
	mixin(genfunc("bool	containsKey(string key)" , "containsKey(key);"));
	//put
	mixin(genfunc("void put(V)(string key , const V v , uint expired = 0)" , "put!V(key , v , expired);"));
	//putifabsent
	mixin(genfunc("bool	putifAbsent(V)(string key , const V v)" , "putifAbsent!V(key , v);"));
	//putAll
	mixin(genfunc("void	putAll(V)(const V[string] maps , uint expired = 0)" , "putAll!V(maps , expired);"));
	//remove
	mixin(genfunc("bool	remove(string key)" , "remove(key);"));
	//removeAll
	mixin(genfunc("void	removeAll(string[] keys)" , "removeAll(keys);"));
	//clear
	mixin(genfunc("void clear()" , "clear();"));
private:

	static string genfunc(string callorigin , string callfunc)
	{
		string f = callorigin ~ " { if(_memory !is null) return  _memory." ~ callfunc ;
        
		version(SUPPORT_REDIS)
		{
			f ~= " if(_redis !is null) return  _redis." ~ callfunc;
		}

		version(SUPPORT_MEMCACHED)
		{
			f ~= "if( _memcahed !is null) return _memcahed." ~ callfunc;
		}

		version(SUPPORT_ROCKSDB)
		{ 
			f ~= "if(_rocksdb !is null) return _rocksdb." ~ callfunc ;
		}
        
		f ~= "assert(0);}";
		return f;	
	}

	  
	UCache!MemoryCache			_memory = null;
	version(SUPPORT_REDIS)
	UCache!RedisCache 			_redis = null;
	version(SUPPORT_MEMCACHED)
	UCache!MemcachedCache		_memcahed = null;
	version(SUPPORT_ROCKSDB)
	UCache!RocksdbCache			_rocksdb = null;
};




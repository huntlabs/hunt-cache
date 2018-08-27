module hunt.cache.ucache;

import hunt.cache.memory;
import hunt.cache.memcached;
import hunt.cache.redis;
import hunt.cache.rocksdb;
import hunt.cache.cache;
import hunt.cache.nullable;

import std.conv;
import std.stdio;
import std.traits;

class UCache
{
	//get
	mixin(genfunc("V get(V)(string key )" , "get!V(key);"));
	//get_ex
	mixin(genfunc("Nullable!V get_ex(V)(string key )" , "get_ex!V(key);"));
	//getall
	mixin(genfunc("Nullable!V[string] getall(V)(string[] keys)" , "getall!V(keys);"));
	mixin(genfunc("string get(string key )" , "get!string(key);"));
	//get_ex
	mixin(genfunc("Nullable!string get_ex(string key )" , "get_ex!string(key);"));
	//getall
	mixin(genfunc("Nullable!string[string] getall(string[] keys)" , "getall!string(keys);"));

	//containsKey
	mixin(genfunc("bool	containsKey(string key)" , "containsKey(key);"));
	//put
	mixin(genfunc("void put(V)(string key ,  V v , uint expired = 0)" , "put!V(key , v , expired);"));
	//putifabsent
	mixin(genfunc("bool	putifAbsent(V)(string key ,  V v)" , "putifAbsent!V(key , v);"));
	//putAll
	mixin(genfunc("void	putAll(V)( V[string] maps , uint expired = 0)" , "putAll!V(maps , expired);"));
	//remove
	mixin(genfunc("bool	remove(string key)" , "remove(key);"));
	//removeAll
	mixin(genfunc("void	removeAll(string[] keys)" , "removeAll(keys);"));
	//clear
	mixin(genfunc("void clear()" , "clear();"));


	static UCache CreateUCache(string driverName = "memory"  , 
		string args = ""  , bool enableL2  = false )
	{
		switch(driverName)
		{
			case "memory":
				return new UCache(new Cache!MemoryCache(args , enableL2));
				version(SUPPORT_REDIS)
				{
					case "redis":
					return new UCache(new Cache!RedisCache(args , enableL2));
				}
				version(SUPPORT_MEMCACHED)
				{
					case "memcached":
					return new UCache(new Cache!MemcachedCache(args , enableL2));
				}
				version(SUPPORT_ROCKSDB)
				{
					case "rocksdb":
					return new UCache(new Cache!RocksdbCache(args , enableL2));
				}
			default:
				return new UCache(new Cache!MemoryCache(args , enableL2));
		}
		
		
	}

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

	this(Object obj)
	{
		string className = to!string(typeid(obj));
		if(className == to!string(typeid(Cache!MemoryCache)))
		{
			_memory = cast(Cache!MemoryCache)obj;
			return;
		}
		version(SUPPORT_REDIS)
		{
			if(className == to!string(typeid(Cache!RedisCache)))
			{
				_redis = cast(Cache!RedisCache)obj;
				return;
			}
		}
		
		version(SUPPORT_MEMCACHED)
		{ 
			if(className == to!string(typeid(Cache!MemcachedCache)))
			{	_memcahed = cast(Cache!MemcachedCache)(obj);
				return;
			}
		}
		
		version(SUPPORT_ROCKSDB){
			if(className == to!string(typeid(Cache!RocksdbCache)))
			{	
				_rocksdb = cast(Cache!RocksdbCache)(obj);
				return;
			}
		}
		
		assert(0);
	}

	Cache!MemoryCache			_memory = null;
	version(SUPPORT_REDIS)
	Cache!RedisCache 			_redis = null;
	version(SUPPORT_MEMCACHED)
	Cache!MemcachedCache		_memcahed = null;
	version(SUPPORT_ROCKSDB)
	Cache!RocksdbCache			_rocksdb = null;
};

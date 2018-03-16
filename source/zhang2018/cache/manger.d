module zhang2018.cache.manger;

import zhang2018.cache.cache;
import std.json;

class CacheManger
{

	UCache!T createCache(T:const T , ARG ...)(string cacheName , ARG args)
	{
		if(getCache!T(cacheName)){
			return null;
		}

		auto cache = new UCache!T(args);
		_mapCaches[cacheName] = cache;

		auto caches =  getCacheClassMaps!T();
		if(caches == null)
		{
			_mapClassCaches[T.stringof] =  [cacheName:true] ;
		}
		else
		{
			(*caches)[cacheName] = true;
		}

		return cache;
	}

	UCache!T getCache(T: const T)(string cacheName)
	{
		Object *cache = (cacheName) in _mapCaches;

		if(cache == null)
			return null;
			
		return cast(UCache!T)*cache ;
	}

	string[] getAllCacheNames()
	{
		return _mapCaches.keys;
	}

	string[] getCacheNames(T:const T)()
	{
		auto caches =  getCacheClassMaps!T();
		if(caches == null)
			return null;
		return (*caches).keys;

	}

	void destroyCache(string cacheName)
	{
		_mapCaches.remove(cacheName);

		foreach(k , v ; _mapClassCaches)
		{
			foreach(k1 , v1 ; v)
			{
				if(k1 == cacheName)
				{
					_mapClassCaches[k].remove(cacheName);
					break;
				}
			}
		}

	}

private:

	bool[string]*	getCacheClassMaps(T)()
	{
		auto cCache = T.stringof in _mapClassCaches;
		if( cCache == null)
			return null;
		return cCache;
	}


private:
	Object[string]			_mapCaches;
	bool[string][string]	_mapClassCaches;
}


unittest{

	import core.thread;
	import std.algorithm;

	version(SUPPORT_MEMCACHED){
		version(SUPPORT_REDIS){
			version(SUPPORT_ROCKSDB){
	

	import zhang2018.cache.memcached;
	import zhang2018.cache.rocksdb;
	import zhang2018.cache.memory;
	import zhang2018.cache.redis;
	import std.stdio;


	CacheManger manger = new CacheManger();

	//test manger.

	string[] allkeys = ["redis" , "memcached" , "memory" , "rocksdb1"  , "rocksdb2"];
	allkeys.sort();
	string[] rdallkeys = ["rocksdb1" , "rocksdb2"];
	rdallkeys.sort();

	auto redis = manger.createCache!RedisCache("redis" ,"127.0.0.1" , 6379);
	auto memcahed = manger.createCache!MemcachedCache("memcached" , "127.0.0.1",11211);
	auto momery = manger.createCache!MemoryCache("memory");
	auto rocksdb1 = manger.createCache!RocksdbCache("rocksdb1" , "/tmp/test1");
	auto rocksdb2 = manger.createCache!RocksdbCache("rocksdb2" , "/tmp/test2");


	assert(manger.getCacheNames!MemoryCache()[0] == "memory");
	assert(manger.getCacheNames!MemcachedCache()[0] == "memcached");
	assert(manger.getCacheNames!RedisCache()[0] == "redis");

	assert(!manger.getCache!RedisCache("memory"));
	assert(!manger.getCache!MemoryCache("redis"));
	assert(manger.getCache!RocksdbCache("rocksdb2"));

	auto getallkeys = manger.getAllCacheNames();
	getallkeys.sort();
	assert(getallkeys.length == allkeys.length);

	foreach(i , n ; getallkeys)
	{
		assert(getallkeys[i] == allkeys[i]);
	}

	auto getrdallkeys = manger.getCacheNames!RocksdbCache();
	getrdallkeys.sort();
	assert(getrdallkeys.length == rdallkeys.length);
	foreach(i , n ; getrdallkeys)
	{
		assert(getrdallkeys[i] == rdallkeys[i]);
	}
	manger.destroyCache("rocksdb2");
	assert(!manger.getCache!RocksdbCache("rocksdb2"));

	// test all cache's api.
	void test(U)(UCache!U cache)
	{		
		cache.put("key1" ,"value1" , 1);
		string[string] map = ["key2":"value2" , "key3":"value3"];
		cache.putAll(map);
		
		assert(cache.get!string("key1").origin == "value1");
		assert(cache.containsKey("key2"));
		assert(!cache.putifAbsent("key1" , "value11"));
		auto kvs = cache.getall!string(["key2" , "key3"]);
		foreach(k,v ; kvs)
		{
			assert(map[k] == v.origin);
		}
		
		assert(cache.remove("key2"));
		assert(!cache.containsKey("key2"));
		Thread.sleep(dur!"seconds"(2));
		assert(!cache.containsKey("key1"));
		assert(cache.putifAbsent("key1" , "value11"));
		cache.clear();
		assert(!cache.containsKey("key3"));
	}


	test(manger.getCache!RedisCache("redis"));
	test(manger.getCache!MemcachedCache("memcached"));
	test(manger.getCache!MemoryCache("memory"));
	test(manger.getCache!RocksdbCache("rocksdb1"));

			}
		}
	}
}
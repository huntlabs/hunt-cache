module hunt.cache.manger;
import hunt.cache.ucache;

class CacheManger
{
	UCache createCache( string cacheName ,  string driverName = "memory"  ,string args = "" , bool enableL2Cache = false)
	{
		synchronized(this)
		{
			if(getCache(cacheName)){
				return null;
			}

			auto ucache  = UCache.CreateUCache(driverName , args , enableL2Cache);
			_mapCaches[cacheName] = ucache;
			return ucache;
		}
	}

	string[] getAllCacheNames()
	{
		synchronized(this){
			return _mapCaches.keys;
		}
	}

	UCache getCache(string cacheName)
	{
		synchronized(this){
			UCache *ucache = cacheName in _mapCaches;
			if(ucache == null)
				return null;
			else
				return *ucache;
		}
	}

	void destroyCache(string cacheName)
	{
		synchronized(this){
			_mapCaches.remove(cacheName);
		}
	}

private:
	UCache[string]			_mapCaches;
}


unittest{

	import core.thread;
	import std.algorithm;
	import std.stdio;


	CacheManger manger = new CacheManger();

	//test manger.
	string[] allkeys = ["memory" , "memory_l2"];

	auto memory = manger.createCache(allkeys[0]);
	auto memory_l2 = manger.createCache(allkeys[1] , "memory" , "" , true);

	version(SUPPORT_REDIS)
	{
		allkeys ~= ["redis" ,"redis_l2"];

		auto redis = manger.createCache(allkeys[$ - 2] , "redis" , "127.0.0.1:6379");
		auto redis_l2 = manger.createCache(allkeys[$ - 1] , "redis" , "127.0.0.1:6379" , true);
	}

	version(SUPPORT_MEMCACHED)
	{
		allkeys ~= ["memcached" , "memcached_l2"];
		auto memcached = manger.createCache(allkeys[$ - 2] , "memcached" , "--SERVER=127.0.0.1:11211" );
		auto memcached_l2 = manger.createCache(allkeys[$ -1] , "memcached" , "--SERVER=127.0.0.1:11211" , true);
	}

	version(SUPPORT_ROCKSDB)
	{
		allkeys ~= ["rocksdb" , "rocksdb_l2"];
		auto rocksdb = manger.createCache(allkeys[$ - 2] , "rocksdb" , "/tmp/test1");
		auto rocksdb_l2 = manger.createCache(allkeys[$ -1] , "rocksdb" , "/tmp/test2" , true);
	}


	auto names = manger.getAllCacheNames();
	names.sort;
	allkeys.sort;
	assert(allkeys.length == names.length);

	void  test(UCache cache)
	{
		cache.put("key1" ,"value1" , 1);
		string[string] map = ["key2":"value2" , "key3":"value3"];
		cache.putAll(map);

		string value = cache.get("key1");
		assert(value == "value1");
		assert(cache.containsKey("key2"));
		assert(!cache.putifAbsent("key1" , "value11"));
		auto kvs = cache.getall(["key2" , "key3"]);
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

	foreach(k ; allkeys)
	{
		import std.stdio;
		writeln("test " ,k);

		test(manger.getCache(k));
	}

	foreach(k ; allkeys)
		manger.destroyCache(k);

	assert(manger.getAllCacheNames().length == 0);

}
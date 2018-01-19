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

	string[] getCacheNames()
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

	import zhang2018.cache.memory;
	import zhang2018.cache.redis;
	import zhang2018.cache.memcached;
	import std.stdio;

	CacheManger manager = new CacheManger();

	manager.createCache!MemoryCache("memory");
	manager.createCache!RedisCache("redis" , "127.0.0.1" , 6379);
	manager.createCache!MemcachedCache("memcached" , "127.0.0.1" , 11211);

	writeln(manager._mapCaches , manager._mapClassCaches);

	auto cache = manager.getCache!MemoryCache("memory");

	cache.put("test" , "test");

	writeln(cache.get!string("test"));

	manager.destroyCache("memory");

	writeln(manager._mapCaches , manager._mapClassCaches);

}
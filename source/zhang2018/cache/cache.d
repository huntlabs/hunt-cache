module zhang2018.cache.cache;

import zhang2018.cache.nullable;


final class Cache(T)
{
	Nullable!V				get(V)(string key)
	{
		return _t.get!V(key);
	}
	Nullable!V[string] 		getall(V)(string[] keys)
	{
		return _t.getall!V(keys);
	}
	bool					containsKey(string key)
	{
		return _t.containsKey(key);
	}

	void 					put(V)(string key , const V v)
	{
		return _t.put!V(key , v);
	}
	bool					putifAbsent(V)(string key , const V v)
	{
		return _t.putifAbsent!V(key , v);
	}
	void					putAll(V)(const V[string] maps)
	{
		return _t.putAll!V(maps);
	}

	bool					remove(string key)
	{
		return _t.remove(key);
	}
	void					removeAll(string[] keys)
	{
		return _t.removeAll(keys);
	}

	void 					clear()
	{
		return _t.clear();
	}

	this(ARGS ...)(ARGS args)
	{
		_t = new T(args);
	}

private:

	T _t;
}

unittest{
	import zhang2018.cache.memory;
	import zhang2018.cache.redis;
	import zhang2018.cache.memcached;
	import std.stdio;

	auto cache = new Cache!MemoryCache();

	struct A{
		int age;
		string name;

	};

	A a;
	a.name = "zhyc";
	a.age = 0;
	cache.put!A("test" , a);

	writeln(cache.get!A("test"));


	auto cache2 = new Cache!(RedisCache)("127.0.0.1" , 6379);
	cache2.put!A("redis" , a);
	writeln(cache2.get!A("redis"));

	auto cache3 = new Cache!(MemcachedCache)("127.0.0.1" , 11211);
	cache3.put!A("redis" , a);
	writeln(cache3.get!A("redis"));

}
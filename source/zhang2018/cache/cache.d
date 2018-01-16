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

	void 					put(V)(string key , const V v , uint expired = 0)
	{
		return _t.put!V(key , v , expired);
	}
	bool					putifAbsent(V)(string key , const V v)
	{
		return _t.putifAbsent!V(key , v);
	}
	void					putAll(V)(const V[string] maps , uint expired = 0)
	{
		return _t.putAll!V(maps , expired);
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



	struct A{
		int age;
		string name;
	}

	A a;
	a.age = 11;
	a.name = "zhyc";

	auto cache = new Cache!MemoryCache();
	cache.put("memory" , a);
	writeln(cache.get!A("memory"));

	auto cache2 = new Cache!(RedisCache)("127.0.0.1" , 6379);
	cache2.put("redis" , a);
	writeln(cache2.get!A("redis"));

	auto cache3 = new Cache!(MemcachedCache)("127.0.0.1" , 11211);
	cache3.put("memcached" , a);
	writeln(cache3.get!A("memcached"));

	A b;
	b.age = 10;
	b.name = "expired";
	cache.put("expired" , b , 1);
	cache2.put("expired" , b , 1);
	cache3.put("expired" , b , 1);

	writeln(cache.get!A("expired"));
	writeln(cache2.get!A("expired"));
	writeln(cache3.get!A("expired"));


	import core.thread;
	Thread.sleep(dur!"msecs"(500));

	writeln(cache.get!A("expired"));
	writeln(cache2.get!A("expired"));
	writeln(cache3.get!A("expired"));

	Thread.sleep(dur!"msecs"(1000));
	
	writeln(cache.get!A("expired"));
	writeln(cache2.get!A("expired"));
	writeln(cache3.get!A("expired"));



}
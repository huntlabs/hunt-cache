module hunt.cache.cache;

import hunt.cache.nullable;
import hunt.cache.l2cache;

final class Cache(T)
{

	Nullable!V get_ex(V)(string key)
	{
		if(_t !is null)
			return _t.get!V(key);
		else
			return _t2.get!V(key);
	}

	V get(V)(string key)
	{
		return cast(V)get_ex!V(key);
	}

	Nullable!V[string] getall(V)(string[] keys)
	{
		if(_t !is null)
			return _t.getall!V(keys);
		else
			return _t2.getall!V(keys);
	}

	bool containsKey(string key)
	{
		if(_t !is null)
			return _t.containsKey(key);
		else
			return _t2.containsKey(key);
	}

	void put(V)(string key ,  V v , uint expired = 0)
	{
		if(_t !is null)
			return _t.put!V(key , v , expired);
		else
			return _t2.put!V(key , v , expired);
	}

	bool putifAbsent(V)(string key ,  V v)
	{
		if( _t !is null)
			return _t.putifAbsent!V(key , v);
		else
			return _t2.putifAbsent!V(key , v);
	}

	void putAll(V)( V[string] maps , uint expired = 0)
	{
		if(_t !is null)
			return _t.putAll!V(maps , expired);
		else
			return _t2.putAll!V(maps , expired);
	}

	bool remove(string key)
	{
		if(_t !is null)
			return _t.remove(key);
		else
			return _t2.remove(key);
	}

	void removeAll(string[] keys)
	{
		if(_t !is null)
			return _t.removeAll(keys);
		else
			return _t2.removeAll(keys);
	}

	void clear()
	{
		if(_t !is null)
			return _t.clear();
		else
			return _t2.clear();
	}

	this(string args , bool enableL2Cache )
	{
		if(enableL2Cache)
			_t2 = new L2Cache!T(args);
		else
			_t = new T(args);
	}

private:

	T 			_t;
	L2Cache!T   _t2;
}

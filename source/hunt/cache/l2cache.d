module hunt.cache.l2cache;

import hunt.cache.memory;
import hunt.cache.nullable;

final class L2Cache(T)
{
	Nullable!V get(V)(string key)
	{
		synchronized(this){
			auto v1 = _memory.get!V(key);
			if(!v1.isnull)
				return v1;

			auto v2 = _cache.get!V(key);
			if(v2.isnull)
				return v2;

			_memory.put!V(key , v2.origin);

			return v2;
		}
	}

	Nullable!V[string] getall(V)(string[] keys)
	{
		synchronized(this){
			Nullable!V[string] mapv;
			foreach(k ; keys)
			{
				mapv[k] = get!V(k);
			}

			return mapv;
		}
	}

	bool containsKey(string key)
	{
		synchronized(this){
			return _cache.containsKey(key);
		}
	}
	
	void put(V)(string key ,  V v , uint expired = 0)
	{
		synchronized(this){
			_cache.put!V(key , v  , expired);
			_memory.put!V(key , v , expired);
		}
	}

	bool putifAbsent(V)(string key ,  V v)
	{
		synchronized(this){
			if( _cache.putifAbsent!V(key , v))
			{
				_memory.put!V(key ,v);
				return true;
			}
		}

		return false;
	}

	void putAll(V)( V[string] maps , uint expired = 0)
	{
		synchronized(this){
			_cache.putAll!V(maps , expired);
			_memory.putAll!V(maps , expired);
		}
	}
	
	bool remove(string key)
	{
		synchronized(this){
			auto ret = _cache.remove(key);
			_memory.remove(key);
			return ret;
		}
	}

	void removeAll(string[] keys)
	{
		synchronized(this){
			 _cache.removeAll(keys);
			_memory.removeAll(keys);
		}
	}
	
	void clear()
	{
		synchronized(this){
		 	_cache.clear();
			_memory.clear();
		}
	}

	this(ARG ...)(ARG arg)
	{
		_memory = new MemoryCache();
		_cache = new T(arg);
	}

private:
	MemoryCache _memory;
	T			_cache;
}

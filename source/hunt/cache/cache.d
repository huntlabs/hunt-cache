module hunt.cache.Cache;

import hunt.cache.adapter.MemoryAdapter;
import hunt.cache.adapter.Adapter;
import hunt.cache.Nullable;

final class Cache
{
    this(Adapter cacheAdapter, MemoryAdapter memoryAdapter = null)
    {
        _memoryAdapter = memoryAdapter;
        _cacheAdapter = cacheAdapter;
    }

    Nullable!V get(V) (string key)
    {
        synchronized(this)
		{
			if (_memoryAdapter !is null)
			{
				auto v1 = _memoryAdapter.get!V(key);
				if(!v1.isnull)
					return v1;
			}

            auto v2 = _cacheAdapter.get!V(key);
            if(v2.isnull)
                return v2;

			if (_memoryAdapter !is null)
			{
            	_memoryAdapter.set!V(key, v2.origin);
			}

            return v2;
        }
    }

    Nullable!V[string] getAll(V) (string[] keys)
    {
        synchronized(this)
        {
            Nullable!V[string] mapv;
            foreach(k ; keys)
            {
                mapv[k] = get!V(k);
            }

            return mapv;
        }
    }

    bool has(string key)
    {
        synchronized(this){
            return _cacheAdapter.has(key);
        }
    }

    void set(V) (string key,  V v, uint expired = 0)
    {
        synchronized(this)
        {
            _cacheAdapter.set!V(key, v , expired);
			if (_memoryAdapter !is null)
			{
            	_memoryAdapter.set!V(key, v, expired);
			}
        }
    }

    bool setIfAbsent(V) (string key,  V v)
    {
        synchronized(this)
        {
            if(_cacheAdapter.setIfAbsent!V(key, v))
            {
				if (_memoryAdapter !is null)
				{
					_memoryAdapter.set!V(key, v);
				}

                return true;
            }
        }

        return false;
    }

    void set(V) ( V[string] maps, uint expired = 0)
    {
        synchronized(this)
		{
            _cacheAdapter.set!V(maps, expired);
			if (_memoryAdapter !is null)
			{
           	 	_memoryAdapter.set!V(maps, expired);
			}
        }
    }

    bool remove(string key)
    {
        synchronized(this)
		{
            auto ret = _cacheAdapter.remove(key);
			if (_memoryAdapter !is null)
			{
            	_memoryAdapter.remove(key);
			}
            return ret;
        }
    }

    void remove(string[] keys)
    {
        synchronized(this){
             _cacheAdapter.remove(keys);
			if (_memoryAdapter !is null)
			{
            	_memoryAdapter.remove(keys);
			}
        }
    }

    void clear()
    {
        synchronized(this)
		{
             _cacheAdapter.clear();

			if (_memoryAdapter !is null)
			{
            	_memoryAdapter.clear();
			}
        }
    }

    private
    {
        MemoryAdapter _memoryAdapter;
        Adapter _cacheAdapter;
    }
}

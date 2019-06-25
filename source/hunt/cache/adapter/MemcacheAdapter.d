module hunt.cache.adapter.MemcacheAdapter;

import hunt.cache.adapter.Adapter;
import hunt.cache.Store;

import hunt.cache.Nullable;

version(WITH_HUNT_MEMCACHE):

import memcache.memcache;
import hunt.cache.CacheOption;

class MemcacheAdapter : Adapter
{
    Nullable!V get(V) (string key)
    {
		synchronized(this)
		{
			return get_inter!V(key);
		}
    }

    Nullable!V[string] getAll(V) (string[] keys)
    {
		//Memcache's bug not implement mget.
		//so it's not atomic operation, and transfer .keys.length. times througth network
		synchronized(this)
		{
			Nullable!V[string] mapv;
			if(keys.length == 0)
				return mapv;

			foreach(k ; keys){
				mapv[k] = get_inter!V(k);
			}

			return mapv;
		}
    }
	
    bool hasKey(string key)
    {
		//Memcache's bug not implement exist, use get inside of.
		synchronized(this)
		{
			return _cache.get!string(key).length > 0;
		}
    }

    void set(V) (string key,  V v, uint expired)
    {
		synchronized(this)
		{
			put_inter!V(key, v, expired);
		}
    }

    bool setIfAbsent(V) (string key, const V v)
    {
		synchronized(this){

			if(hasKey(key))
				return false;

			put_inter!V(key, v, 0);
			return true;
			//return _cache.replace(key, cast(string)SerializeToByte!V(v));
		}
    }

    // because memcached api no mset api, so is cost much time to put many.
    void set(V) (V[string] maps, uint expired)
    {
		synchronized(this)
		{
			foreach(k, v ; maps)
			{
				put_inter!V(k, v, expired);
			}
		}
    }

    bool remove(string key)
	{
		synchronized(this)
		{
			return remove_inter(key);
        }
    }

    // because memcached api no mdel api, so is cost much time to remove many.
    void remove(string[] keys)
    {
		synchronized(this)
		{
			foreach(k  ; keys){
				remove_inter(k);
			}
		}
    }

    void clear()
    {
		synchronized(this){
			_cache.flush();
		}
    }

    this(CacheOption.MemcacheConf config)
    {
		import std.conv : to;

        string args = "--SERVER=" ~ config.host ~ ":" ~ config.port.to!string;
        _cache = new Memcache(args);
    }

protected:
    Memcache _cache;

    Nullable!V get_inter(V) (string key)
    {
        string data = _cache.get(key);
        return DeserializeToObject!V(cast(byte[])data);
    }

    void put_inter(V) (string key,  V v, uint expired)
    {
         _cache.set(key, cast(string)SerializeToByte(v), cast(int)expired);
    }

    bool remove_inter(string key)
    {
        return _cache.del(key);
    }
}

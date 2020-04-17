module hunt.cache.adapter.RedisClusterAdapter;

import hunt.cache.adapter.Adapter;
import hunt.cache.CacheOptions;
import hunt.cache.Nullable;
import hunt.cache.Store;

import hunt.Exceptions;
import hunt.logging;
import hunt.redis;

import std.array;
import std.conv;
import std.string;

class RedisClusterAdapter : Adapter
{
    this(RedisPoolConfig config)
    {
        try
        {            
            _redis = new RedisCluster(new HostAndPort(config.host, config.port));
            // _redis.connect();

            // if (!config.password.empty())
            //     _redis.auth(config.password);
            // _redis.select(config.database);
        }
        catch (Exception e)
        {
            logError(e);
        }
    }

    Nullable!V get(V) (string key)
    {
        synchronized(this)
        {   
            try {
                string data = _redis.get(key);
                return DeserializeToObject!V(cast(byte[])data);
            } catch(Exception ex) {
                warning(ex.msg);
                version(HUNT_DEBUG) warning(ex);
            }
            return Nullable!V();
        }
    }

    Nullable!V[string] getAll(V) (string[] keys)
    {
        synchronized(this)
        {
            Nullable!V[string] mapv;
            if( keys.length == 0)
                return mapv;

            List!(string) r = _redis.mget(keys);

            foreach(i, v ; r)
            {
                mapv[keys[i]] = DeserializeToObject!V(cast(byte[])v);
            }

            return mapv;
        }
    }

    bool hasKey(string key)
    {
        synchronized(this)
        {
            return _redis.exists(key);
        }
    }

    void set(V) (string key,  V v, uint expired)
    {
        synchronized(this)
        {
            if( expired == 0)
                _redis.set(key, cast(string)SerializeToByte(v));
            else {
                implementationMissing(false);
            }
                // _redis.setex(key, expired, cast(string)SerializeToByte(v));
        }
    }

    bool setIfAbsent(V) (string key,  V v)
    {
        synchronized(this)
        {
            return _redis.setnx(key, cast(string)SerializeToByte(v)) == 1;        
        }
    }

    void set(V) (V[string] maps, uint expired)
    {
        synchronized(this)
        {
            if(maps.length == 0)
                return;

            if(expired == 0)
            {
                _redis.mset(maps);
            }
            else
            {
                foreach( k, v ; maps)
                {
                    _redis.set(k, expired, cast(string)SerializeToByte(v));
                }
            }
        }
    }

    bool remove(string key)
    {
        synchronized(this)
        {
            return _redis.del(key) > 0;
        }
    }

    void remove(string[] keys)
    {
        synchronized(this)
        {
            if( keys.length == 0)
                return ;

            foreach(key ; keys){
                _redis.del(key);
            }
        }
    }

    void clear()
    {
        synchronized(this)
        {
            // _redis.flushAll();
        }
    }

protected:
    RedisCluster _redis;
}

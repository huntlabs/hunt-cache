module hunt.cache.adapter.RedisAdapter;

import hunt.cache.adapter.Adapter;
import hunt.cache.CacheOption;
import hunt.cache.Nullable;
import hunt.cache.Store;

import hunt.logging;
import hunt.redis;

import std.array;
import std.conv;
import std.string;

class RedisAdapter : Adapter
{
    this(CacheOption.RedisConf config)
    {
        try
        {
            RedisPoolConfig poolConfig = new RedisPoolConfig();
            poolConfig.host = config.host;
            poolConfig.port = config.port;
            poolConfig.soTimeout = config.timeout;
            poolConfig.database = config.database;
            poolConfig.password = config.password;

            defalutPoolConfig = poolConfig;
        }
        catch (Exception e)
        {
            logError(e);
        }
    }

    Nullable!V get(V) (string key)
    {
        Redis _redis = redis();
        scope(exit) _redis.close();
        // synchronized(this)
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
        Redis _redis = redis();
        scope(exit) _redis.close();
        // synchronized(this)
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
        Redis _redis = redis();
        scope(exit) _redis.close();
        // synchronized(this)
        {
            return _redis.exists(key);
        }
    }

    void set(V) (string key,  V v, uint expired)
    {
        Redis _redis = redis();
        scope(exit) _redis.close();

        // synchronized(this)
        {
            if( expired == 0)
                _redis.set(key, cast(string)SerializeToByte(v));
            else
                _redis.setex(key, expired, cast(string)SerializeToByte(v));
        }
    }

    bool setIfAbsent(V) (string key,  V v)
    {
        Redis _redis = redis();
        scope(exit) _redis.close();
        // synchronized(this)
        {
            return _redis.setnx(key, cast(string)SerializeToByte(v)) == 1;        
        }
    }

    void set(V) (V[string] maps, uint expired)
    {
        if(maps.length == 0)
            return;
        Redis _redis = redis();
        scope(exit) _redis.close();

        // synchronized(this)
        {

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
        Redis _redis = redis();
        scope(exit) _redis.close();

        // synchronized(this)
        {
            return _redis.del(key) > 0;
        }
    }

    void remove(string[] keys)
    {
        if( keys.length == 0)
            return ;

        Redis _redis = redis();
        scope(exit) _redis.close();

        foreach(key ; keys){
            _redis.del(key);
        }
   
    }

    void clear()
    {
        Redis _redis = redis();
        scope(exit) _redis.close();
        _redis.flushAll();

        // synchronized(this)
        // {
        //     _redis.flushAll();
        // }
    }

protected:
    // Redis _redis;
    Redis redis() {
        return defaultRedisPool().getResource();
    }
}

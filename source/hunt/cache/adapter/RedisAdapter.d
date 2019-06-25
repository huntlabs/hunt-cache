module hunt.cache.adapter.RedisAdapter;

import hunt.cache.adapter.Adapter;
import hunt.cache.Store;
import hunt.cache.CacheOption;

import hunt.logging;

import std.conv;
import std.string;
import hunt.cache.Nullable;

version(WITH_HUNT_REDIS):

import redis;

class RedisAdapter : Adapter
{
    this(CacheOption.RedisConf config)
    {
        try
        {
            _redis = new Redis(config.host, config.port, config.password);
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
            string data = _redis.send!string("get", key);
            return DeserializeToObject!V(cast(byte[])data);
        }
    }

    Nullable!V[string] getAll(V) (string[] keys)
    {
        synchronized(this)
        {
            Nullable!V[string] mapv;
            if( keys.length == 0)
                return mapv;

            Response r = _redis.send("mget", keys);

            foreach(i, v ; r.values)
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
            return _redis.send!bool("exists", key);
        }
    }

    void set(V) (string key,  V v, uint expired)
    {
        synchronized(this)
        {
            if( expired == 0)
                _redis.send("set", key, cast(string)SerializeToByte(v));
            else
                _redis.send("setex", key, expired, cast(string)SerializeToByte(v));
        }
    }

    bool setIfAbsent(V) (string key,  V v)
    {
        synchronized(this)
        {
                return _redis.send!bool("setnx", key, cast(string)SerializeToByte(v)) == 1;        
        }
    }

    void set(V) (V[string] maps, uint expired)
    {
        synchronized(this){
            if(maps.length == 0)
            return;

            if(expired == 0)
            {
                string cmds = "mset ";
                foreach(k, v ; maps)
                {
                    cmds ~= k ~ " " ~ cast(string)SerializeToByte(v) ~ " ";
                }
                _redis.send(cmds);
            }
            else
            {
                string[] cmds;
                foreach( k,v ; maps){
                    cmds ~= "setex " ~ k ~ " " ~ to!string(expired) ~ " " ~ cast(string)SerializeToByte(v);
                }

                _redis.pipeline(cmds);
            }
        }
    }

    bool remove(string key)
    {
        synchronized(this)
        {
            return _redis.send!bool("del", key);
        }
    }

    void remove(string[] keys)
    {
        synchronized(this)
        {
            if( keys.length == 0)
            return ;

            string[] cmds;
            foreach(k ; keys){
                cmds ~= "del " ~ k;
            }
            _redis.pipeline(cmds);
        }
    }

    void clear()
    {
        synchronized(this)
        {
            _redis.send("flushdb");
        }
    }

protected:
    Redis _redis;
}

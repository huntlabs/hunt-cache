module hunt.cache.memory;

import hunt.cache.cache;
import hunt.cache.store;
import hunt.cache.nullable;

import core.stdc.stdlib;
import core.stdc.string;
import core.stdc.time;

import std.variant;
import std.conv;

public:

class MemoryCache
{
    Nullable!V get(V)(string key)
    {
        synchronized(this)
        {
            return get_inter!V(key);
        }
    }

    Nullable!V[string] getall(V)(string[] keys)
    {
        Nullable!V[string] mapv;

        synchronized(this)
        {
            foreach(k; keys)
            {
                mapv[k] = get_inter!V(k);
            }
        }

        return mapv;
    }

    bool containsKey(string key)
    {
        synchronized(this)
        {
            return (key in cacheData) ? true : false;
        }
    }

    void put(V)(string key, V v, uint expired = 0)
    {
        synchronized(this)
        {
            put_inter(key, v, expired);
        }
    }

    bool putifAbsent(V)(string key, V v)
    {
        synchronized(this)
        {
            bool ret = (key in cacheData) ? true : false;

            if (!ret)
            {
                put_inter!V(key, v, 0);

                return true;
            }

            return false;
        }
    }

    void putAll(V)(V[string] maps, uint expired = 0)
    {
        synchronized(this)
        {
            foreach(k, v; maps)
            {
                put_inter(k, v, expired);
            }
        }
    }

    bool remove(string key)
    {
        synchronized(this)
        {
            if (key in cacheTime)
            {
                cacheTime.remove(key);
            }

            bool ret = (key in cacheData) ? true : false;

            if (ret)
            {
                cacheData.remove(key);
            }

            return ret;
        }
    }

    void removeAll(string[] keys)
    {
        synchronized(this)
        {
            foreach(k; keys)
            {
                if (k in cacheTime)
                {
                    cacheTime.remove(k);
                }

                if (k in cacheData)
                {
                    cacheData.remove(k);
                }
            }
        }
    }

    void clear()
    {
        synchronized(this)
        {
            cacheData.clear();
            cacheTime.clear();
        }
    }

    this(string args = "")
    {
    }

    ~this()
    {
        clear();
    }

protected:

    Variant[string] cacheData;
    uint[string] cacheTime;

    Nullable!V get_inter(V)(string key)
    {
        Nullable!V v;

        if (key !in cacheTime)    //not set ttl
        {
            if (key in cacheData)
            {
                v.bind(cacheData[key].get!V);
            }

            return v;
        }
        else
        {
            uint tick = cacheTime[key];
            uint now = cast(uint)time(null);

            if (tick < now) // remove
            {
                cacheTime.remove(key);
                cacheData.remove(key);

                return v;
            }
            else
            {
                v.bind(cacheData[key].get!V);

                return v;
            }
        }
    }

    void put_inter(V)(string key, V v, uint expired)
    {
        if (expired == 0)
        {
            if (key in cacheTime)
            {
                cacheTime.remove(key);
            }
        }
        else
        {
            cacheTime[key] = expired + cast(uint)time(null);
        }

        cacheData[key] = v;
    }
}

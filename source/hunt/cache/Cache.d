module hunt.cache.Cache;

import hunt.cache.adapter;

import hunt.cache.Nullable;

import std.conv : to;

final class Cache
{
    this(Object adapterObject, MemoryAdapter memoryAdapter = null)
    {
        string className = to!string(typeid(adapterObject));

        if (memoryAdapter !is null && to!string(typeid(memoryAdapter)) != className)
        {
            _memoryAdapter = memoryAdapter;
            _l2enabled = true;
        }
        
        if(className == to!string(typeid(MemoryAdapter)))
        {
            _memoryAdapter = cast(MemoryAdapter)adapterObject;
            _type = ADAPTER_TYPE.MEMORY_ADAPTER;
            return;
        }

        version(WITH_HUNT_REDIS)
        {
            if(className == to!string(typeid(RedisAdapter)))
            {
                _redisAdapter = cast(RedisAdapter)adapterObject;
                _type = ADAPTER_TYPE.REDIS_ADAPTER;
                return;
            }
        }
        
        version(WITH_HUNT_MEMCACHE)
        { 
            if(className == to!string(typeid(MemcacheAdapter)))
            {
                _memcacheAdapter = cast(MemcacheAdapter)(adapterObject);
                _type = ADAPTER_TYPE.MEMCACHE_ADAPTER;
                return;
            }
        }
        
        version(WITH_HUNT_ROCKSDB)
        {
            if(className == to!string(typeid(RocksdbAdapter)))
            {    
                _rocksdbAdapter = cast(RocksdbAdapter)(adapterObject);
                _type = ADAPTER_TYPE.ROCKSDB_ADAPTER;
                return;
            }
        }
    }

    Nullable!V get(V = string) (string key)
    {
        switch(_type)
        {
            case ADAPTER_TYPE.MEMORY_ADAPTER:
                return get!(MemoryAdapter, V)(key);
            
            version(WITH_HUNT_MEMCACHE) {
            case ADAPTER_TYPE.REDIS_ADAPTER:
                return get!(RedisAdapter, V)(key);
            }

            version(WITH_HUNT_MEMCACHE)
            {
            case ADAPTER_TYPE.MEMCACHE_ADAPTER:
                return get!(MemcacheAdapter, V)(key);
            }

            version(WITH_HUNT_ROCKSDB)
            {
            case ADAPTER_TYPE.ROCKSDB_ADAPTER:
                return get!(RocksdbAdapter, V)(key);
            }
            
            default:
                return get!(MemoryAdapter, V)(key);
        }
    }

    Nullable!V get(A, V) (string key)
    {
        synchronized(this)
        {
            if (_l2enabled)
            {
                auto v1 = _memoryAdapter.get!V(key);
                if(!v1.isNull)
                    return v1;
            }

            auto v2 = cacheAdapter!A().get!V(key);
            if(v2.isNull)
                return v2;

            if (_l2enabled)
            {
                _memoryAdapter.set!V(key, v2.origin);
            }

            return v2;
        }
    }


    Nullable!V[string] get(V = string) (string[] keys)
    {
        switch(_type)
        {
            case ADAPTER_TYPE.MEMORY_ADAPTER:
                return get!(MemoryAdapter, V)(keys);
            case ADAPTER_TYPE.REDIS_ADAPTER:
                return get!(RedisAdapter, V)(keys);
            version(WITH_HUNT_MEMCACHE)
            {
            case ADAPTER_TYPE.MEMCACHE_ADAPTER:
                return get!(MemcacheAdapter, V)(keys);
            }
            version(WITH_HUNT_ROCKSDB)
            {
            case ADAPTER_TYPE.ROCKSDB_ADAPTER:
                return get!(RocksdbAdapter, V)(keys);
            }
            default:
                return get!(MemoryAdapter, V)(keys);
        }
    }

    Nullable!V[string] get(A, V) (string[] keys)
    {
        synchronized(this)
        {
            Nullable!V[string] mapv;
            foreach(k ; keys)
            {
                mapv[k] = get!(A, V)(k);
            }

            return mapv;
        }
    }

    bool hasKey(string key)
    {
        switch(_type)
        {
            case ADAPTER_TYPE.MEMORY_ADAPTER:
                return hasKey!MemoryAdapter(key);
version(WITH_HUNT_REDIS) {                
            case ADAPTER_TYPE.REDIS_ADAPTER:
                return hasKey!RedisAdapter(key);
}                
            version(WITH_HUNT_MEMCACHE)
            {
            case ADAPTER_TYPE.MEMCACHE_ADAPTER:
                return hasKey!MemcacheAdapter(key);
            }
            version(WITH_HUNT_MEMCACHE)
            {
            case ADAPTER_TYPE.ROCKSDB_ADAPTER:
                return hasKey!RocksdbAdapter(key);
            }
            default:
                return hasKey!MemoryAdapter(key);
        }
    }

    bool hasKey(A)(string key)
    {
        synchronized(this)
        {
            return cacheAdapter!A().hasKey(key);
        }
    }

    void set(V) (string key, V v, uint expired = 0)
    {
        switch(_type)
        {
            case ADAPTER_TYPE.MEMORY_ADAPTER:
                return set!(MemoryAdapter, V)(key, v, expired);
            
            version(WITH_HUNT_MEMCACHE) {
            case ADAPTER_TYPE.REDIS_ADAPTER:
                return set!(RedisAdapter, V)(key, v, expired);
            }

            version(WITH_HUNT_MEMCACHE)
            {
            case ADAPTER_TYPE.MEMCACHE_ADAPTER:
                return set!(MemcacheAdapter, V)(key, v, expired);
            }

            version(WITH_HUNT_ROCKSDB)
            {
            case ADAPTER_TYPE.ROCKSDB_ADAPTER:
                return set!(RocksdbAdapter, V)(key, v, expired);
            }

            default:
                return set!(MemoryAdapter, V)(key, v, expired);
        }
    }

    void set(A, V) (string key, V v, uint expired = 0)
    {
        synchronized(this)
        {
            cacheAdapter!A().set!V(key, v, expired);

            if (_l2enabled)
            {
                _memoryAdapter.set!V(key, v, expired);
            }
        }
    }

    bool setIfAbsent(V) (string key,  V v)
    {
        synchronized(this)
        {
            if(cacheAdapter!A().setIfAbsent!V(key, v))
            {
                if (_l2enabled)
                {
                    _memoryAdapter.set!V(key, v);
                }

                return true;
            }
        }

        return false;
    }

    void set(V) (V[string] maps, uint expired = 0)
    {
        switch(_type)
        {
            case ADAPTER_TYPE.MEMORY_ADAPTER:
                return set!(MemoryAdapter, V)(maps, expired);
            case ADAPTER_TYPE.REDIS_ADAPTER:
                return set!(RedisAdapter, V)(maps, expired);
            case ADAPTER_TYPE.MEMCACHE_ADAPTER:
                return set!(MemcacheAdapter, V)(maps, expired);
            case ADAPTER_TYPE.ROCKSDB_ADAPTER:
                return set!(RocksdbAdapter, V)(maps, expired);
            default:
                return set!(MemoryAdapter, V)(maps, expired);
        }
    }

    void set(A, V) (V[string] maps, uint expired = 0)
    {
        synchronized(this)
        {
            cacheAdapter!A().set!V(maps, expired);
            if (_l2enabled)
            {
                    _memoryAdapter.set!V(maps, expired);
            }
        }
    }

    bool remove(string key)
    {
        switch(_type)
        {
            case ADAPTER_TYPE.MEMORY_ADAPTER:
                return remove!MemoryAdapter(key);

            version(WITH_HUNT_REDIS) {                                
            case ADAPTER_TYPE.REDIS_ADAPTER:
                return remove!RedisAdapter(key);
            }

            version(WITH_HUNT_MEMCACHE)
            {
            case ADAPTER_TYPE.MEMCACHE_ADAPTER:
                return remove!MemcacheAdapter(key);
            }
            version(WITH_HUNT_MEMCACHE)
            {
            case ADAPTER_TYPE.ROCKSDB_ADAPTER:
                return remove!RocksdbAdapter(key);
            }
            default:
                return remove!MemoryAdapter(key);
        }
    }

    bool remove(A)(string key)
    {
        synchronized(this)
        {
            auto ret = cacheAdapter!A().remove(key);
            if (_l2enabled)
            {
                _memoryAdapter.remove(key);
            }
            return ret;
        }
    }

    void remove(string[] keys)
    {
        switch(_type)
        {
            case ADAPTER_TYPE.MEMORY_ADAPTER:
                remove!MemoryAdapter(keys);
                break;

            version(WITH_HUNT_REDIS) {                                
            case ADAPTER_TYPE.REDIS_ADAPTER:
                remove!RedisAdapter(keys);
                break;
            }  

            version(WITH_HUNT_MEMCACHE)
            {
            case ADAPTER_TYPE.MEMCACHE_ADAPTER:
                remove!MemcacheAdapter(keys);
                break;
            }

            version(WITH_HUNT_ROCKSDB)
            {
            case ADAPTER_TYPE.ROCKSDB_ADAPTER:
                remove!RocksdbAdapter(keys);
                break;
            }

            default:
                remove!MemoryAdapter(keys);
        }
    }

    void remove(A)(string[] keys)
    {
        synchronized(this)
        {
             cacheAdapter!A().remove(keys);
            if (_l2enabled)
            {
                _memoryAdapter.remove(keys);
            }
        }
    }

    void clear()
    {
        switch(_type)
        {
            case ADAPTER_TYPE.MEMORY_ADAPTER:
                clear!MemoryAdapter();
                break;
            
            version(WITH_HUNT_REDIS) {
            case ADAPTER_TYPE.REDIS_ADAPTER:
                clear!RedisAdapter();
                break;
            }

            version(WITH_HUNT_MEMCACHE)
            {
            case ADAPTER_TYPE.MEMCACHE_ADAPTER:
                clear!MemcacheAdapter();
                break;
            }

            version(WITH_HUNT_ROCKSDB)
            {
            case ADAPTER_TYPE.ROCKSDB_ADAPTER:
                clear!RocksdbAdapter();
                break;
            }
            
            default:
                clear!MemoryAdapter();
        }
    }

    void clear(A)()
    {
        synchronized(this)
        {
             cacheAdapter!A().clear();

            if (_l2enabled)
            {
                _memoryAdapter.clear();
            }
        }
    }

    A cacheAdapter(A)()
    {
        switch(_type)
        {
            case ADAPTER_TYPE.MEMORY_ADAPTER:
                return cast(A)_memoryAdapter;
version(WITH_HUNT_REDIS) {                
            case ADAPTER_TYPE.REDIS_ADAPTER:
                return cast(A)_redisAdapter;
}                
            version(WITH_HUNT_MEMCACHE)
            {
            case ADAPTER_TYPE.MEMCACHE_ADAPTER:
                return cast(A)_memcacheAdapter;
            }
            version(WITH_HUNT_ROCKSDB)
            {
            case ADAPTER_TYPE.ROCKSDB_ADAPTER:
                return cast(A)_rocksdbAdapter;
            }
            default:
                return cast(A)_memoryAdapter;
        }
    }

    private
    {
        bool _l2enabled = false;

        MemoryAdapter _memoryAdapter;
        version(WITH_HUNT_REDIS) RedisAdapter _redisAdapter;
        version(WITH_HUNT_MEMCACHE) MemcacheAdapter _memcacheAdapter;
        version(WITH_HUNT_ROCKSDB) RocksdbAdapter _rocksdbAdapter;

        ADAPTER_TYPE _type;

        enum ADAPTER_TYPE
        {
            MEMORY_ADAPTER,
            REDIS_ADAPTER,
            MEMCACHE_ADAPTER,
            ROCKSDB_ADAPTER
        }
    }
}

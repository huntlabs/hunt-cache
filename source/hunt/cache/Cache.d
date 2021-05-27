module hunt.cache.Cache;

import hunt.cache.adapter;
import hunt.cache.CacheOptions;
import hunt.cache.Defined;
import hunt.cache.Nullable;
import hunt.logging.ConsoleLogger;

import std.algorithm;
import std.array;
import std.conv : to;
import std.range;

final class Cache
{
    this(MemoryAdapter memoryAdapter) {
        this(memoryAdapter, new CacheOptions());
    }

    this(Object adapterObject, CacheOptions option, MemoryAdapter memoryAdapter = null)
    {
        version(HUNT_DEBUG) infof("Creating cache: [%s]", option);
        _option = option;
        auto className = typeid(adapterObject);

        if (memoryAdapter !is null && typeid(memoryAdapter) != className)
        {
            _memoryAdapter = memoryAdapter;
            _l2enabled = true;
        }
        
        if(className == typeid(MemoryAdapter))
        {
            _memoryAdapter = cast(MemoryAdapter)adapterObject;
            _type = CACHE_ADAPTER.MEMORY;
            return;
        }

        if(className == typeid(RedisAdapter))
        {
            _redisAdapter = cast(RedisAdapter)adapterObject;
            _type = CACHE_ADAPTER.REDIS;
            return;
        }
        
        if(className == typeid(RedisClusterAdapter))
        {
            _redisClusterAdapter = cast(RedisClusterAdapter)adapterObject;
            _type = CACHE_ADAPTER.REDIS_CLUSTER;
            return;
        }

        version(WITH_HUNT_MEMCACHE)
        { 
            if(className == typeid(MemcacheAdapter))
            {
                _memcacheAdapter = cast(MemcacheAdapter)(adapterObject);
                _type = CACHE_ADAPTER.MEMCACHE_ADAPTER;
                return;
            }
        }
        
        version(WITH_HUNT_ROCKSDB)
        {
            if(className == typeid(RocksdbAdapter))
            {    
                _rocksdbAdapter = cast(RocksdbAdapter)(adapterObject);
                _type = CACHE_ADAPTER.ROCKSDB;
                return;
            }
        }
    }

    

    Nullable!V get(V = string) (string key)
    {
        switch(_type)
        {
            case CACHE_ADAPTER.MEMORY:
                return get!(MemoryAdapter, V)(key);
            
            case CACHE_ADAPTER.REDIS:
                return get!(RedisAdapter, V)(key);
            
            case CACHE_ADAPTER.REDIS_CLUSTER:
                return get!(RedisClusterAdapter, V)(key);

            version(WITH_HUNT_MEMCACHE)
            {
            case CACHE_ADAPTER.MEMCACHE_ADAPTER:
                return get!(MemcacheAdapter, V)(key);
            }

            version(WITH_HUNT_ROCKSDB)
            {
            case CACHE_ADAPTER.ROCKSDB:
                return get!(RocksdbAdapter, V)(key);
            }
            
            default:
                return get!(MemoryAdapter, V)(key);
        }
    }

    private Nullable!V get(A, V) (string key)
    {
        if(!_option.prefix.empty())
            key = _option.prefix ~ key;

        version(HUNT_CACHE_DEBUG) trace("key: ", key);

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
            case CACHE_ADAPTER.MEMORY:
                return get!(MemoryAdapter, V)(keys);

            case CACHE_ADAPTER.REDIS:
                return get!(RedisAdapter, V)(keys);

            case CACHE_ADAPTER.REDIS_CLUSTER:
                return get!(RedisClusterAdapter, V)(keys);

            version(WITH_HUNT_MEMCACHE)
            {
            case CACHE_ADAPTER.MEMCACHE_ADAPTER:
                return get!(MemcacheAdapter, V)(keys);
            }

            version(WITH_HUNT_ROCKSDB)
            {
            case CACHE_ADAPTER.ROCKSDB:
                return get!(RocksdbAdapter, V)(keys);
            }
            
            default:
                return get!(MemoryAdapter, V)(keys);
        }
    }

    private Nullable!V[string] get(A, V) (string[] keys)
    {
        if(!_option.prefix.empty()) {
            keys = keys.map!(k => _option.prefix ~ k)();
        }

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
            case CACHE_ADAPTER.MEMORY:
                return hasKey!MemoryAdapter(key);

            case CACHE_ADAPTER.REDIS:
                return hasKey!RedisAdapter(key);

            case CACHE_ADAPTER.REDIS_CLUSTER:
                return hasKey!RedisClusterAdapter(key);

            version(WITH_HUNT_MEMCACHE)
            {
            case CACHE_ADAPTER.MEMCACHE_ADAPTER:
                return hasKey!MemcacheAdapter(key);
            }
            version(WITH_HUNT_MEMCACHE)
            {
            case CACHE_ADAPTER.ROCKSDB:
                return hasKey!RocksdbAdapter(key);
            }
            default:
                return hasKey!MemoryAdapter(key);
        }
    }

    bool hasKey(A)(string key)
    {
        if(!_option.prefix.empty())
            key = _option.prefix ~ key;

        synchronized(this)
        {
            return cacheAdapter!A().hasKey(key);
        }
    }


    void set(V) (string key, V v, uint expired = 0)
    {
        switch(_type)
        {
            case CACHE_ADAPTER.MEMORY:
                return set!(MemoryAdapter, V)(key, v, expired);
            
            case CACHE_ADAPTER.REDIS:
                return set!(RedisAdapter, V)(key, v, expired);
            
            case CACHE_ADAPTER.REDIS_CLUSTER:
                return set!(RedisClusterAdapter, V)(key, v, expired);

            version(WITH_HUNT_MEMCACHE)
            {
            case CACHE_ADAPTER.MEMCACHE_ADAPTER:
                return set!(MemcacheAdapter, V)(key, v, expired);
            }

            version(WITH_HUNT_ROCKSDB)
            {
            case CACHE_ADAPTER.ROCKSDB:
                return set!(RocksdbAdapter, V)(key, v, expired);
            }

            default:
                return set!(MemoryAdapter, V)(key, v, expired);
        }
    }

    private void set(A, V) (string key, V v, uint expired = 0)
    {
        if(!_option.prefix.empty())
            key = _option.prefix ~ key;

        version(HUNT_CACHE_DEBUG) trace("key: ", key);

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
        if(!_option.prefix.empty())
            key = _option.prefix ~ key;

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
            case CACHE_ADAPTER.MEMORY:
                return set!(MemoryAdapter, V)(maps, expired);

            case CACHE_ADAPTER.REDIS:
                return set!(RedisAdapter, V)(maps, expired);

            case CACHE_ADAPTER.REDIS_CLUSTER:
                return set!(RedisClusterAdapter, V)(maps, expired);

            case CACHE_ADAPTER.MEMCACHE_ADAPTER:
                return set!(MemcacheAdapter, V)(maps, expired);
            case CACHE_ADAPTER.ROCKSDB:
                return set!(RocksdbAdapter, V)(maps, expired);
            default:
                return set!(MemoryAdapter, V)(maps, expired);
        }
    }

    private void set(A, V) (V[string] maps, uint expired = 0)
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
            case CACHE_ADAPTER.MEMORY:
                return remove!MemoryAdapter(key);

            case CACHE_ADAPTER.REDIS:
                return remove!RedisAdapter(key);

            case CACHE_ADAPTER.REDIS_CLUSTER:
                return remove!RedisClusterAdapter(key);

            version(WITH_HUNT_MEMCACHE)
            {
            case CACHE_ADAPTER.MEMCACHE_ADAPTER:
                return remove!MemcacheAdapter(key);
            }
            version(WITH_HUNT_MEMCACHE)
            {
            case CACHE_ADAPTER.ROCKSDB:
                return remove!RocksdbAdapter(key);
            }
            default:
                return remove!MemoryAdapter(key);
        }
    }

    private bool remove(A)(string key)
    {
        if(!_option.prefix.empty())
            key = _option.prefix ~ key;

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
            case CACHE_ADAPTER.MEMORY:
                remove!MemoryAdapter(keys);
                break;

            case CACHE_ADAPTER.REDIS:
                remove!RedisAdapter(keys);
                break;

            case CACHE_ADAPTER.REDIS_CLUSTER:
                remove!RedisClusterAdapter(keys);
                break;

            version(WITH_HUNT_MEMCACHE)
            {
            case CACHE_ADAPTER.MEMCACHE_ADAPTER:
                remove!MemcacheAdapter(keys);
                break;
            }

            version(WITH_HUNT_ROCKSDB)
            {
            case CACHE_ADAPTER.ROCKSDB:
                remove!RocksdbAdapter(keys);
                break;
            }

            default:
                remove!MemoryAdapter(keys);
        }
    }

    private void remove(A)(string[] keys)
    {
        if(!_option.prefix.empty()) {
            keys = keys.map!(k => _option.prefix ~ k)().array();
        }

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
            case CACHE_ADAPTER.MEMORY:
                clear!MemoryAdapter();
                break;
            
            case CACHE_ADAPTER.REDIS:
                clear!RedisAdapter();
                break;

            case CACHE_ADAPTER.REDIS_CLUSTER:
                clear!RedisClusterAdapter();
                break;

            version(WITH_HUNT_MEMCACHE)
            {
            case CACHE_ADAPTER.MEMCACHE_ADAPTER:
                clear!MemcacheAdapter();
                break;
            }

            version(WITH_HUNT_ROCKSDB)
            {
            case CACHE_ADAPTER.ROCKSDB:
                clear!RocksdbAdapter();
                break;
            }
            
            default:
                clear!MemoryAdapter();
        }
    }

    private void clear(A)()
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

    private A cacheAdapter(A)()
    {
        switch(_type)
        {
            case CACHE_ADAPTER.MEMORY:
                return cast(A)_memoryAdapter;

            case CACHE_ADAPTER.REDIS:
                return cast(A)_redisAdapter;

            version(WITH_HUNT_MEMCACHE)
            {
            case CACHE_ADAPTER.MEMCACHE_ADAPTER:
                return cast(A)_memcacheAdapter;
            }
            version(WITH_HUNT_ROCKSDB)
            {
            case CACHE_ADAPTER.ROCKSDB:
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
        RedisAdapter _redisAdapter;
        RedisClusterAdapter _redisClusterAdapter;
        version(WITH_HUNT_MEMCACHE) MemcacheAdapter _memcacheAdapter;
        version(WITH_HUNT_ROCKSDB) RocksdbAdapter _rocksdbAdapter;

        CacheOptions _option;

        CACHE_ADAPTER _type;
    }
}

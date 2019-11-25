module hunt.cache.CacheFactory;

import hunt.cache.Cache;
import hunt.cache.CacheOption;
import hunt.cache.Defined;
import hunt.cache.adapter;


deprecated("Using CacheFactory instead.")
alias CacheFectory = CacheFactory;

class CacheFactory
{
    static Cache create()
    {
        return new Cache(new MemoryAdapter);
    }

    static Cache create(ref CacheOption option)
    {
        MemoryAdapter memoryAdapter;
        if (option.useSecondLevelCache || option.adapter == AdapterType.MEMORY)
        {
            memoryAdapter = new MemoryAdapter;
        }

        switch(option.adapter)
        {
            case AdapterType.MEMORY:
                return new Cache(memoryAdapter, option);

            case AdapterType.REDIS:
                if(option.redis.cluster.enabled) {
                    return new Cache(new RedisClusterAdapter(option.redis), option, memoryAdapter);
                } else {
                    return new Cache(new RedisAdapter(option.redis), option, memoryAdapter);
                }

            version(WITH_HUNT_MEMCACHE)
            {
                case AdapterType.MEMCACHE:
                return new Cache(new MemcacheAdapter(option.memcache), option, memoryAdapter);
            }
            version(WITH_HUNT_ROCKSDB)
            {
                case AdapterType.ROCKSDB:
                return new Cache(new RocksdbAdapter(option.rocksdb), option, memoryAdapter);
            }
            default:
                return new Cache(memoryAdapter, option);
        }
    }
}

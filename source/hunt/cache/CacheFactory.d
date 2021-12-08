module hunt.cache.CacheFactory;

import hunt.cache.Cache;
import hunt.cache.CacheOptions;
import hunt.cache.Defined;
import hunt.cache.adapter;

/**
 * 
 */
class CacheFactory
{
    static Cache create()
    {
        return new Cache(new MemoryAdapter);
    }

    static Cache create(CacheOptions option)
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
                return new Cache(new RedisAdapter(option.redis), option, memoryAdapter);

            case AdapterType.REDIS_CLUSTER:
                return new Cache(new RedisClusterAdapter(option.redis, option.redisCluster), option, memoryAdapter);

            // version(WITH_HUNT_MEMCACHE)
            // {
            //     case AdapterType.MEMCACHE:
            //     return new Cache(new MemcacheAdapter(option.memcache), option, memoryAdapter);
            // }
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

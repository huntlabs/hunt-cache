module hunt.cache.CacheFectory;

import hunt.cache.Cache;
import hunt.cache.CacheOption;
import hunt.cache.Defined;
import hunt.cache.adapter;

class CacheFectory
{
    static Cache create()
    {
        return new Cache(new MemoryAdapter);
    }

    static Cache create(CacheOption option)
    {
        MemoryAdapter memoryAdapter;
        if (option.l2 || option.adapter == AdapterType.MEMORY)
        {
            memoryAdapter = new MemoryAdapter;
        }

        switch(option.adapter)
        {
            case AdapterType.MEMORY:
                return new Cache(memoryAdapter);

            case AdapterType.REDIS:
            return new Cache(new RedisAdapter(option.redis), memoryAdapter);

            version(WITH_HUNT_MEMCACHE)
            {
                case AdapterType.MEMCACHE:
                return new Cache(new MemcacheAdapter(option.memcache), memoryAdapter);
            }
            version(WITH_HUNT_ROCKSDB)
            {
                case AdapterType.ROCKSDB:
                return new Cache(new RocksdbAdapter(option.rocksdb), memoryAdapter);
            }
            default:
                return new Cache(memoryAdapter);
        }
    }
}

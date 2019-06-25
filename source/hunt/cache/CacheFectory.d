module hunt.cache.CacheFectory;

import hunt.cache.Cache;
import hunt.cache.CacheOption;
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
		if (option.l2 || option.adapter == "memory")
		{
			memoryAdapter = new MemoryAdapter;
		}

        switch(option.adapter)
        {
            case "memory":
                return new Cache(memoryAdapter);
            version(WITH_HUNT_REDIS)
            {
                case "redis":
                return new Cache(new RedisAdapter(option.redis), memoryAdapter);
            }
            version(WITH_HUNT_MEMCACHE)
            {
                case "memcache":
                return new Cache(new MemcacheAdapter(option.memcache), memoryAdapter);
            }
            version(WITH_HUNT_ROCKSDB)
            {
                case "rocksdb":
                return new Cache(new RocksdbAdapter(option.rocksdb), memoryAdapter);
            }
            default:
                return new Cache(memoryAdapter);
        }
    }
}

module hunt.cache.Defined;

/**
 For Cache Object
*/
enum CACHE_ADAPTER
{
    MEMORY,
    REDIS,
    REDIS_CLUSTER,
    MEMCACHE,
    ROCKSDB
}


/**
 For CacheOption
*/
enum AdapterType {
    MEMORY = "memory",
    REDIS = "redis",
    REDIS_CLUSTER = "redis-cluster",
    MEMCACHE = "memcache",
    ROCKSDB = "rocksdb"
}

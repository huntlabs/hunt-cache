module hunt.cache.Defined;

/**
 For Cache Object
*/
enum CACHE_ADAPTER
{
    MEMORY,
    REDIS,
    MEMCACHE,
    ROCKSDB
}


/**
 For CacheOption
*/
enum AdapterType {
    MEMORY = "memory",
    REDIS = "redis",
    MEMCACHE = "memcache",
    ROCKSDB = "rocksdb"
}

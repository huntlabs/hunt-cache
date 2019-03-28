module hunt.cache.CacheOption;

struct CacheOption
{
    string driver = "memory";

    bool l2 = false;

    RedisConf redis;
    MemcacheConf memcache;
    RocksdbConf rocksdb;

    struct MemoryConf
    {
        long size = 65535;
    }
    
    struct RedisConf
    {
        string host = "127.0.0.1";
        string password;
        ushort database = 0;
        ushort port = 6379;
        uint timeout = 0;
    }

    struct MemcacheConf
    {
        string host = "127.0.0.1";
        ushort port = 11211;
        uint timeout = 0;
    }

    struct RocksdbConf
    {
        string path = "storages/cache.db";
    }
}

module hunt.cache.CacheOption;

struct CacheOption
{
    string adapter = "memory";

    bool l2 = false;
    
    uint maxEntriesLocalHeap = 10000;
    bool eternal = false;
    uint timeToIdleSeconds = 3600;
    uint timeToLiveSeconds = 10;
    bool overflowToDisk = true;
    bool diskPersistent = true;
    uint diskExpiryThreadIntervalSeconds = 120;
    uint maxEntriesLocalDisk = 10000;

    RedisConf redis;
    MemcacheConf memcache;
    RocksdbConf rocksdb;

    struct MemoryConf
    {
        long size = 65535;
        bool persisted = false; // dependency RocksDB conf
    }

    struct RedisConf
    {
        string host = "127.0.0.1";
        ushort port = 6379;
        string password;
        ushort database = 0;
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
        string file = "storages/cache.db";
    }
}

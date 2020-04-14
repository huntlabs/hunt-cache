module hunt.cache.CacheOption;

import hunt.cache.Defined;
import hunt.redis.RedisPoolConfig;

import std.format;
import std.range;


struct CacheOption
{
    string adapter = "memory";
    string prefix = "";

    bool useSecondLevelCache = false;
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
    
    struct RedisPoolConf {
        bool enabled = false;

        bool blockOnExhausted = true;
        uint idleTimeout = 30000; // millisecond
        uint maxPoolSize = 20;
        uint minPoolSize = 5;
        uint maxLifetime = 2000000;
        uint connectionTimeout = 15000;
        int waitTimeout = 15000; // -1: forever
        uint maxConnection = 20;
        uint minConnection = 5;        
    }

    struct RedisConf
    {
        string host = "127.0.0.1";
        string password = "";
        ushort database = 0;
        ushort port = 6379;
        uint timeout = 5000;
        
        RedisPoolConf pool;
        ClusterOption cluster;
        
        string toString() {
            if(password.empty()) {
                return format("redis://%s:%s/%d?timeout=%d&cluster=%s", host, port, database, timeout, cluster);
            } else {
                return format("redis://%s@%s:%s/%d?timeout=%d&useCluster=%s", password, host, port, database, timeout, cluster);
            }
        }
    }

    struct MemcacheConf
    {
        string host = "127.0.0.1";
        ushort port = 11211;
        uint timeout = 0;

        string toString() {
            return format("memecache://%s:%d/?timeout=%d", host, port, timeout);
        }
    }

    struct RocksdbConf
    {
        string file = "storages/cache.db";
    }

    string toString() {
        if(adapter == "redis") {
            return format("adapter: %s, prefix: %s, Redis: {%s}", adapter, prefix, redis.toString());
        } else if(adapter == "memcache") {
            return format("adapter: %s, prefix: %s, Memcache: {%s}", adapter, prefix, memcache.toString());
        } else {
            return format("adapter: %s, prefix: %s", adapter, prefix);
        }
    }
}

module hunt.cache.CacheOptions;

import hunt.cache.Defined;
import hunt.redis.RedisPoolOptions;

import std.format;
import std.range;

enum string ADAPTER_MEMORY = "memory";
enum string ADAPTER_MEMCACHE = "memcache";
enum string ADAPTER_REDIS = "redis";
enum string ADAPTER_ROCKSDB = "rocksdb";

/**
 * 
 */
class CacheOptions {

    string adapter = ADAPTER_MEMORY;
    string prefix = "";

    bool isRedisClusterEnabled = false;
    
    bool useSecondLevelCache = false;
    uint maxEntriesLocalHeap = 10000;
    bool eternal = false;
    uint timeToIdleSeconds = 3600;
    uint timeToLiveSeconds = 10;
    bool overflowToDisk = true;
    bool diskPersistent = true;
    uint diskExpiryThreadIntervalSeconds = 120;
    uint maxEntriesLocalDisk = 10000;

    this() {
        redis = new RedisPoolOptions();
    }

    RedisClusterConfig redisCluster;
    RedisPoolOptions redis;
    MemcacheConf memcache;
    RocksdbConf rocksdb;

    struct MemoryConf {
        long size = 65535;
        bool persisted = false; // dependency RocksDB conf
    }

    struct MemcacheConf {
        string host = "127.0.0.1";
        ushort port = 11211;
        uint timeout = 0;

        string toString() {
            return format("memecache://%s:%d/?timeout=%d", host, port, timeout);
        }
    }

    struct RocksdbConf {
        string file = "storages/cache.db";
    }

    override string toString() {
        if (adapter == ADAPTER_MEMORY) {
            return format("adapter: %s, prefix: %s, Redis: {%s}", adapter,
                    prefix, redis.toString());
        } else if (adapter == ADAPTER_MEMCACHE) {
            return format("adapter: %s, prefix: %s, Memcache: {%s}", adapter,
                    prefix, memcache.toString());
        } else {
            return format("adapter: %s, prefix: %s", adapter, prefix);
        }
    }
}

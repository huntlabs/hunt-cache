module hunt.cache.adapter.RocksdbAdapter;

// dfmt off
version (WITH_HUNT_ROCKSDB)  : 
// dfmt on

import hunt.cache.adapter.Adapter;
import hunt.cache.Store;
import hunt.cache.CacheOption;

import core.time;
import core.stdc.time;
import core.stdc.string;
import core.thread;

import std.file;
import std.string;
import hunt.cache.Nullable;

import rocksdb;

class RocksdbAdapter : Adapter
{
    this(CacheOption.rocksdb config)
	{
        create(config.file);
    }

    ~this()
	{
        _rocksdb.close();
    }

    Nullable!V get(V) (string key)
    {
        synchronized (this) {
            auto data = _rocksdb.get(cast(ubyte[]) key);

            return get_inter!V(data);

        }
    }

    Nullable!V[string] getAll(V) (string[] key)
	{
        synchronized (this) {
            Nullable!V[string] mapv;
            ubyte[][] datas = _rocksdb.multiGet(cast(ubyte[][]) key);
            foreach (i, d; datas) {
                mapv[key[i]] = get_inter!V(d);
            }
            return mapv;
        }
    }

    bool hasKey(string key)
	{
        synchronized (this)
		{
            auto data = _rocksdb.get(cast(ubyte[]) key);
            if (data == null)
                return false;
            if (check_is_expired(data)) {
                _rocksdb.remove(cast(ubyte[]) key);
                return false;
            }
            return true;
        }
    }

    void set(V) (string key, V v, uint expired = 0)
	{
        synchronized (this) {
            _rocksdb.put(cast(ubyte[]) key,
                    generator_expired(expired) ~ cast(ubyte[]) SerializeToByte!V(v));
        }
    }

    // rocksdb no putifaabsent, so this function not atomic.
    bool setIfAbsent(V) (string key, V v)
	{
        synchronized (this) {
            auto data = _rocksdb.get(cast(ubyte[]) key);
            if (data == null || check_is_expired(data)) {
                put(key, v);
                return true;
            }
            return false;
        }
    }

    void set(V) (V[string] maps, uint expired)
	{
        synchronized (this) {
            string[] datas;
            if (maps.length == 0)
                return;
            auto expired_data = generator_expired(expired);
            _rocksdb.withBatch((batch) {
                foreach (k, v; maps)
                    batch.put(cast(ubyte[]) k, expired_data ~ cast(ubyte[]) SerializeToByte(v));
            });
        }
    }

    bool remove(string key)
	{
        synchronized (this) {
            // rocksdb's remove api not return the value.
            auto data = _rocksdb.get(cast(ubyte[]) key);
            if (data == null) {
                return false;
            }

            if (check_is_expired(data)) {
                _rocksdb.remove(cast(ubyte[]) key);
                return false;
            }

            _rocksdb.remove(cast(ubyte[]) key);
            return true;
        }
    }

    void remove(string[] keys)
    {
        synchronized (this) {
            foreach (k; keys) {
                _rocksdb.remove(cast(ubyte[]) k);
            }
        }
    }

    void clear()
    {
        _rocksdb.close();
        std.file.rmdirRecurse(_dir);
        create(_dir);
    }

protected:

    void create(string dir) {
        auto opts = new DBOptions;
        opts.createIfMissing = true;
        opts.errorIfExists = false;

        _rocksdb = new Database(opts, dir);
        _dir = dir;
    }

    Nullable!V get_inter(V) (ubyte[] data) {
        if (data == null)
            return Nullable!V.init;

        if (check_is_expired(data)) {
            _rocksdb.remove(cast(ubyte[]) data);
            return Nullable!V.init;
        }

        return DeserializeToObject!V(cast(byte[]) data[8 .. $]);
    }

    ubyte[] generator_expired(uint expired) {
        byte[8] byExpired;
        if (expired == 0) {
            return cast(ubyte[]) byExpired.idup;
        } else {
            ulong stamp = time(null) + expired;
            memcpy(byExpired.ptr, cast(void*)&stamp, byExpired.sizeof);
        }
        return cast(ubyte[]) byExpired.idup;
    }

    ulong get_expired(ubyte[] data) {
        ulong stamp;
        memcpy(&stamp, data.ptr, 8);
        return stamp;
    }

    bool check_is_expired(ubyte[] data) {
        ulong stamp = time(null);
        ulong expired = get_expired(data);
        if (expired > 0 && expired < stamp) {
            return true;
        }
        return false;
    }

    Database _rocksdb;
    string _dir;
}

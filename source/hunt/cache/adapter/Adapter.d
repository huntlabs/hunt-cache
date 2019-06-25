module hunt.cache.adapter.Adapter;

import hunt.cache.Nullable;

interface Adapter
{
    Nullable!V get(V) (string key);

    Nullable!V[string] get(V) (string[] keys);

    void set(V) (string key, V value, uint expired);

    void set(V) (V[string] maps, uint expired);

    bool setIfAbsent(V) (string key, V value);

    bool hasKey(string key);

    bool remove(string key);

    void remove(string[] keys);

    void clear();
}

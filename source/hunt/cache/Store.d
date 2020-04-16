module hunt.cache.Store;

import hunt.cache.Nullable;
import hunt.logging.ConsoleLogger;

// import hunt.util.Serialize;
import hunt.serialization.BinarySerialization;

byte[] SerializeToByte(T)(T t) {
    auto data = cast(byte[]) serialize(t);
    version (HUNT_CACHE_DEBUG)
        tracef("%s", data);
    return data;
}

Nullable!T DeserializeToObject(T)(const byte[] data) {
    T obj = unserialize!(T)(cast(ubyte[]) data);

    version (HUNT_CACHE_DEBUG) {
        warningf("%s", data);
        tracef("obj: %s, %s", T.stringof, obj);
    }

    Nullable!T nullt;
    nullt.bind(obj);

    return nullt;
}

module hunt.cache.Store;

import hunt.cache.Nullable;
import hunt.logging.ConsoleLogger;

// import hunt.util.Serialize;
import hunt.serialization.BinarySerialization;
import hunt.serialization.Common;

byte[] SerializeToByte(T)(T t) {
    auto data = cast(byte[]) serialize!(SerializationOptions.OnlyPublicWithNull)(t);
    version (HUNT_CACHE_DEBUG)
        tracef("%s", data);
    return data;
}

Nullable!T DeserializeToObject(T)(const byte[] data) {
    T obj = unserialize!(T, SerializationOptions.OnlyPublicWithNull)(cast(ubyte[]) data);

    version (HUNT_CACHE_DEBUG) {
        tracef("%(%02X %)", data);
        tracef("obj T: %s", T.stringof);
    }

    Nullable!T nullt;
    nullt.bind(obj);

    return nullt;
}

module example;

import hunt.cache;
import hunt.logging;
import hunt.net.NetUtil;

struct User {
    string name;
    int age;
}

void main() {
    CacheOptions option = new CacheOptions();
    option.adapter = AdapterType.MEMORY;
    option.redis.host = "10.1.222.120";
    option.redis.password = "foobared";

    auto cache = CacheFactory.create(option);

    // define key
    string key = "userinfo";

    User user;
    user.name = "putao";
    user.age = 23;

    try {
        // set value
        cache.set(key, user, 10);

        // get value
        User userinfo = cache.get!User(key);

        logDebug(userinfo);
    } catch (Exception ex) {
        warning(ex);
    }
}

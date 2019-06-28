module example;

import hunt.cache;
import hunt.logging;

struct User
{
    string name;
    int age;
}

void main()
{
    auto cache = CacheFectory.create();

    // define key
    string key = "userinfo";

    User user;
    user.name = "zoujiaqing";
    user.age = 99;

    // set value
    cache.set(key, user);

    // get value
    User userinfo = cache.get!User(key);

    logDebug(userinfo);
}

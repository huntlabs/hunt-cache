[![Build Status](https://travis-ci.org/huntlabs/hunt-cache.svg?branch=master)](https://travis-ci.org/huntlabs/hunt-cache)
## Hunt Cache
Universal cache library for D programming language.

## Support backend
 * memory
 * redis

## Tips
Default support memory and redis drivers.

## Sample code for Memory adapter
```D
import hunt.cache;

import std.stdio;

void main()
{
    auto cache = CacheFactory.create();

    // define key
    string key = "my_cache_key";
    // set cache
    cache.set(key, "My cache value.");

    // get cache
    string value = cache.get(key);

    writeln(value);
}
```

## Sample code for struct & class
```D
import hunt.cache;

import std.stdio;

struct User
{
    string name;
    int age;
}

void main()
{
    auto cache = CacheFactory.create();

    // define key
    string key = "user_info";

    User user;
    user.name = "zoujiaqing";
    user.age = 99;

    // set cache
    cache.set(key, user);

    // get cache
    User userinfo = cache.get!User(key);

    writeln(userinfo.name);
}

```

## How to use Redis adapter?
```D
import hunt.cache;

import std.stdio;

void main()
{
    CacheOption option;
    option.adapter = "redis";
    option.redis.host = "127.0.0.1";
    option.redis.port = 6379;

    auto cache = CacheFactory.create(option);

    // code for set / get ..
}

```

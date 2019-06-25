module example;

import hunt.logging;
import hunt.cache;

struct User
{
	string name;
	int age;
}

import std.conv;

void example(Cache cache)
{
	// define key
	string key = "userinfo";

	User user;
	user.name = "zoujiaqing";
	user.age = 99;

	// set value
	cache.set(key, user);

	// get value
	auto userinfo = cache.get!User(key);

	logDebug(userinfo.name);
}

void main()
{
    auto cache = CacheFectory.create();

    example(cache);
}

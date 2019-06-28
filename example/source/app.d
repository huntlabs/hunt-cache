module example;

import hunt.logging;
import hunt.cache;

import std.stdio;

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
	User userinfo = cache.get!User(key);

	logDebug(userinfo);
}

void main()
{
	CacheOption option;
	option.adapter = "redis";

    auto cache = CacheFectory.create(option);

    example(cache);
}

[![Build Status](https://travis-ci.org/huntlabs/hunt-cache.svg?branch=master)](https://travis-ci.org/huntlabs/hunt-cache)
# UCache
D language universal cache library.

# Support drivers
 * memory
 * redis
 * libmemcached
 * rocksdb

 # Versions
 * WITH_HUNT_REDIS
 * WITH_HUNT_MEMCACHE
 * WITH_HUNT_ROCKSDB

# tips
default support memory、redis.

# example
````d
struct Student
{
	ulong 		ID;
	string 		name;
	string		address;
}

class Grade
{
	int 		gradeLevel;
	string  	gradeName;
	Student[]	arrStu;
}

auto cache = UCache.CreateUCache();

//string
cache.put("test" , "test");
string val = cache.get("test");

//student.
Student stu1;
stu1.ID = 1;
stu1.name = "tom";
stu1.address = "Tianlin Road 1016";
cache.put("tom" , stu1);
auto stu = cache.get!Student("tom");

//Grade
Grade grade = new Grade();
grade.gradeLevel = 12;
grade.gradeName = "13";
grade.arrStu ~= stu1;
cache.put("13" , grade);
auto grade1 = cache.get!Grade("13");
````	

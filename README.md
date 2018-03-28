[![Build Status](https://travis-ci.org/huntlabs/cache.svg?branch=master)](https://travis-ci.org/huntlabs/cache)
# UCache
D language universal cache library.

# Support drivers
 * memory
 * memcache
 * redis
 * rocksdb

# tips
default support memory、memcache、redis.

# example
	
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
	cache.put!string("test" , "test");
	string val = cache.get!string("test");

	//student.
	Student stu1;
	stu1.ID = 1;
	stu1.name = "tom";
	stu1.address = "Tianlin Road 1016";
	cache.put!Student("tom" , stu1);
	auto stu = cache.get!Student("tom");

	//Grade
	Grade grade = new Grade();
	grade.gradeLevel = 12;
	grade.gradeName = "13";
	grade.arrStu ~= stu1;
	cache.put!Grade("13" , grade);
	auto grade1 = cache.get!Grade("13");
	
	

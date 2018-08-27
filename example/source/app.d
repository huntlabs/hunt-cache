module example;
import hunt.cache;


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


import std.conv;

void example(UCache cache)
{
	import std.stdio;
	//string

	cache.put!string("test" , "teststring");
	string val = cache.get!string("test");


	cache.put!string("test1" ,"");
	auto val2 = cache.get_ex!string("test1");
	assert(!val2.isnull);


	//student.
	Student stu1;
	stu1.ID = 1;
	stu1.name = "tom";
	stu1.address = "Tianlin Road 1016";
	cache.put!Student("tom" , stu1);

	Student stu = cache.get!Student("tom");

	Nullable!Student nstu = cache.get_ex!Student("tom");
	assert(!nstu.isnull);

	Student stu2 = nstu.origin;
	Student stu3 = cast(Student)nstu;
	assert(stu2 == stu);
	assert(stu2 == stu);
	assert(stu3 == stu);

	auto nstu2 = cache.get!Student("jacker");
	assert(nstu2 == Student.init);

	Nullable!Student nstu3 = cache.get_ex!Student("test");
	assert(nstu3.isnull);

	//Grade
	Grade grade = new Grade();
	grade.gradeLevel = 12;
	grade.gradeName = "13";
	grade.arrStu ~= stu1;

	cache.put!Grade("13" , grade);


	auto gra = cache.get!Grade("tom");
	assert(gra is null);

	auto gra1 = cache.get!Grade("13");
	assert(gra1 !is null);
	writeln(gra1.gradeLevel , " " , gra1.gradeName , " " , gra1.arrStu);

}


void example2()
{
	CacheManger manger = new CacheManger();

	manger.createCache("default");

	manger.createCache("myredis" , "redis" , "127.0.0.1:6379");
	manger.createCache("myreids_l2" , "redis" , "127.0.0.1:6379" ,true);

	manger.createCache("mymemcached" , "memcached" , "--server=127.0.0.1:11211");

	example(manger.getCache("default"));

	example(manger.getCache("myredis"));

	example(manger.getCache("myreids_l2"));

	example(manger.getCache("mymemcached"));

}

/*
void example3(UCache cache)
{
	const int i = 12;
	cache.put!int("count" , i);
	cache.put("count_const" , i);
	assert(cast(int)cache.get!int("count_const") == i);
}*/



int main()
{
	auto cache = UCache.CreateUCache();

	example(cache);

	example2();


	return 0;

}
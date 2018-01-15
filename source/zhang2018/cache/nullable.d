module zhang2018.cache.nullable;

struct Nullable(T)
{
	auto opDispatch(string s, ARGS ...)(ARGS i) if(hasMember!(T,s))
	{
		mixin( "return _t."~s~"(i);");
	}
	
	bool isnull() 
	{
		return _isnull;
	}

	@property T origin(){
		return _t;
	}
	
	void bind(T t)
	{
		_isnull = false;
		_t = t;
	}
	
	
private:
	
	bool 	_isnull = true;
	T 		_t;
}

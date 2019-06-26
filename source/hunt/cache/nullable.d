module hunt.cache.Nullable;

struct Nullable(T)
{
    auto opDispatch(string s, ARGS ...) (ARGS i) if(hasMember!(T,s))
    {
        mixin( "return _t."~s~"(i);");
    }

    bool isNull() 
    {
        return _isNull;
    }

    @property T origin()
	{
        return _t;
    }

    void bind(T t)
    {
        _isNull = false;
        _t = t;
    }

    T opCast(T) ()
    {
        return _t;
    }

    T _t;
	alias _t this;

    private bool _isNull = true;
}

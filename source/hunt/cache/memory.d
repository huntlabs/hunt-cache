module hunt.cache.memory;

import hunt.cache.cache;
import hunt.cache.store;
import hunt.cache.nullable;

import kiss.container.radix;

import core.stdc.stdlib;
import core.stdc.string;
import core.stdc.time;

import std.stdio;

public:
class MemoryCache 
{

//interface

	Nullable!V get(V)(string key)
	{
		synchronized(this)
		{
			return get_inter!V(key);
		}
	}

	Nullable!V[string] getall(V)(string[] keys)
	{
		Nullable!V[string] mapv;
		synchronized(this)
		{
			foreach(k ; keys)
			mapv[k] = get_inter!V(k);
		}

		return mapv;
	}

	bool containsKey(string key)
	{
		synchronized(this){
			return find_inter(key , true);
		}
	}
	
	void put(V)(string key ,  V v , uint expired = 0)
	{
		synchronized(this)
		{
			put_inter(key , v , expired);
		}
	}

	bool putifAbsent(V)(string key ,  V v)
	{
		synchronized(this)
		{
			if(!find_inter(key , false))
			{	
				put_inter(key , v , 0);
				return true;
			}
			return false;	
		}		
	}

	void putAll(V)( V[string] maps , uint expired = 0)
	{
		synchronized(this){
			foreach(k , v ; maps)
			{
				put_inter(k , v , expired);
			}
		}
	}
	
	bool remove(string key)
	{
		synchronized(this)
		{
			return remove_inter(key);
		}
	}

	void removeAll(string[] keys)
	{
		synchronized(this)
		{
			foreach( k ; keys)
			{
				remove_inter(k);
			}
		}
	}

	void clear()
	{
		synchronized(this){
			rax_data.Clear();
			rax_time.Clear();
		}
	}

	this(string args = "")
	{
		rax_data = rax.New();
		rax_time = rax.New();
	}

	~this()
	{
		rax.Free(rax_data);
		rax.Free(rax_time);
	}

protected:

	rax *rax_data;
	rax *rax_time;

	bool find_inter(string key , bool free)
	{
		Nullable!uint tick = get_inter!uint(rax_time , key);
		if(tick.isnull)
		{
			void *data;
			return rax_data.find(cast(ubyte[])key ,data);
		}
		else{
			uint now = cast(uint)time(null);
			if( tick.origin < now )
			{
				if(free)
				{
					remove_inter(key);
				}
				return false;
			}
			else{
				return true;
			}
		}
	}

	Nullable!V get_inter(V)(string key)
	{
		Nullable!uint tick =  get_inter!uint(rax_time , key);

		if(tick.isnull)	//not set ttl
		{
			return get_inter!V(rax_data , key);
		}
		else{
			uint now = cast(uint)time(null);
			if( tick.origin < now) // remove
			{
				remove_inter(key);
				return Nullable!V.init;
			}
			else
			{
				return get_inter!V(rax_data , key);
			}
		}
	}

	Nullable!V get_inter(V)(rax *r ,string key)
	{
		void *data;
		if (!r.find(cast(ubyte[])key , data))
			return Nullable!V.init;

		uint len;
		memcpy(&len , data , 4);
		byte[] byDatas = new byte[len];
		memcpy(byDatas.ptr , data + 4, len);
		return DeserializeToObject!V(byDatas);
	}

	void put_inter(V)(string key , V v , uint expired)
	{
		if(expired == 0)
			put_inter(rax_data , key , v);
		else{
			put_inter!uint(rax_time , key , expired + cast(uint)time(null));
			put_inter(rax_data , key , v);
		}
	}

	void put_inter(V)(rax *r , string key ,  V v)
	{
		byte[] data = SerializeToByte(v);

		void *value = malloc(data.length + 4);
		uint len = cast(uint) data.length;
		memcpy(value , &len , 4);
		memcpy(value + 4 , data.ptr , data.length);
		r.Insert(cast(ubyte[])key , value);
	}

	bool remove_inter(string key)
	{
		if(rax_data.Remove(cast(ubyte[])key))
		{
			rax_time.Remove(cast(ubyte[])key);
			return true;
		}

		return false;
	}

	bool remove_inter(rax *r , string key)
	{	
		return r.Remove(cast(ubyte[])key);	
	}
}

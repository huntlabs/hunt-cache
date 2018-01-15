module zhang2018.cache.memory;

import zhang2018.cache.cache;
import zhang2018.cache.store;
import zhang2018.radix;
import core.stdc.stdlib;
import core.stdc.string;
import zhang2018.cache.nullable;



import std.stdio;



class MemoryCache 
{

//interface

	Nullable!V		get(V)(string key)
	{

		synchronized(this){
			return get_inter!V(key);
		}
	}

	Nullable!V[string] 		getall(V)(string[] keys)
	{
		Nullable!V[string] mapv;
		synchronized(this){
			mapv[k] = get_inter!V(k);
		}

		return mapv;
	}

	bool			containsKey(string key)
	{
		synchronized(this){
			void *data;
			if(!r.find(cast(ubyte[])key ,data))
				return false;

			return true;
		}
	}
	
	void 			put(V)(string key , const V v)
	{
		synchronized(this){
			put_inter(key , v);
		}
	}

	bool			putifAbsent(V)(string key , const V v)
	{
		synchronized(this){
			void *data;
			if(!r.find(cast(ubyte[])key ,data))
			{	
				r.put_inter(key , v);
				return true;
			}
			return false;	
		}		
	}

	void			putAll(V)(const V[string] maps)
	{
		synchronized(this){
			foreach(k , v ; maps)
			{
				r.put_inter(k , v);
			}
		}
	}
	
	bool			remove(string key)
	{
		synchronized(this){
			return remove_inter(key);
		}
	
	}

	void			removeAll(string[] keys)
	{
		synchronized(this){
			foreach( k ; keys)
			{
				remove_inter(k);
			}
		}
	}

	void 			clear()
	{
		synchronized(this){
			r.Clear();
		}
	}


	this()
	{
		r = rax.New();
	}

	~this()
	{
		rax.Free(r);
	}

protected:

	rax				*r;

	Nullable!V		get_inter(V)(string key)
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


	void 			put_inter(V)(string key , const V v)
	{
		byte[] data = SerializeToByte!V(v);

		void *value = malloc(data.length + 4);
		uint len = cast(uint) data.length;
		memcpy(value , &len , 4);
		memcpy(value + 4 , data.ptr , data.length);
		r.Insert(cast(ubyte[])key , value);
	}

	bool			remove_inter(string key)
	{	
		return r.Remove(cast(ubyte[])key);	
	} 


}


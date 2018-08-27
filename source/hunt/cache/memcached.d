module hunt.cache.memcached;

import hunt.cache.cache;
import hunt.cache.store;
import hunt.cache.nullable;

version(SUPPORT_MEMCACHED):

import memcache.memcache;

class MemcachedCache
{

	Nullable!V get(V)(string key)
	{
			synchronized(this){
				return get_inter!V(key);
			}
	}

	Nullable!V[string] 		getall(V)(string[] keys)
	{
			//Memcache's bug not implement mget.
			//so it's not atomic operation, and transfer .keys.length. times througth network
			synchronized(this){
				Nullable!V[string] mapv;
				if(keys.length == 0)
					return mapv;

				foreach(k ; keys){
					mapv[k] = get_inter!V(k);
				}

				return mapv;
			}

	}
	bool					containsKey(string key)
	{
			//Memcache's bug not implement exist , use get inside of.
			synchronized(this){
				return _cache.get!string(key).length > 0;
			}
	}


	void 					put(V)(string key ,  V v , uint expired)
	{
			synchronized(this){
				put_inter!V(key , v , expired);
			}
	}
	
	 
	bool					putifAbsent(V)(string key , const V v)
	{
			synchronized(this){

				if(containsKey(key))
					return false;

				put_inter!V(key , v , 0);
				return true;
				//return _cache.replace(key , cast(string)SerializeToByte!V(v));
			}
	}
	
	// because memcached api no mset api , so is cost much time to put many.
	void					putAll(V)( V[string] maps , uint expired)
	{
			synchronized(this){

				foreach(k , v ; maps)
				{
					put_inter!V(k , v , expired);
				}
			}

	}
	
	bool					remove(string key){
			synchronized(this){
				return remove_inter(key);
			}
	}

	// because memcached api no mdel api , so is cost much time to remove many.
	void					removeAll(string[] keys)
	{
			synchronized(this){
				foreach(k  ; keys){
					remove_inter(k);
				}
			}

	}
	void 					clear(){
			synchronized(this){
				_cache.flush();
			}
	}
	

	
	this(string args )
	{
		if(args == null)
			args = "--SERVER=127.0.0.1:11211";
		_cache = new Memcache(args);
	}
	

protected:
	Memcache _cache;


	Nullable!V				get_inter(V)(string key)
	{
		string data = _cache.get(key);
		return DeserializeToObject!V(cast(byte[])data);
	}

	void 					put_inter(V)(string key ,  V v , uint expired)
	{
		 _cache.set(key , cast(string)SerializeToByte(v) , cast(int)expired);
	}

	bool					remove_inter(string key)
	{
		return _cache.del(key);
	}
	
	
}

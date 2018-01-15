module zhang2018.cache.redis;
import zhang2018.cache.cache;

import zhang2018.cache.nullable;
import zhang2018.cache.store;

version(SUPPORT_REDIS){

	import tinyredis;


class RedisCache
{
		Nullable!V				get(V)(string key)
		{
			synchronized(this){
				string data = _redis.send!string("get" , key);
				return DeserializeToObject!V(cast(byte[])data);
			}
		}

		Nullable!V[string] 		getall(V)(string[] keys)
		{
			synchronized(this){
				Nullable!V[string] mapv;
				if( keys.length == 0)
					return mapv;

				Response r = _redis.send("mget" , keys);

				foreach(i , v ; r.values)
				{
					mapv[keys[i]] = DeserializeToObject!V(cast(byte[])v);
				}

				return mapv;
			}
		}

		bool					containsKey(string key)
		{
			synchronized(this){
				return _redis.send!bool("exists" , key);
			}
		}
		
		void 					put(V)(string key , const V v)
		{
			synchronized(this){
				_redis.send("set" , key , cast(string)SerializeToByte!V(v));
			}
		}

		bool					putifAbsent(V)(string key , const V v)
		{
			synchronized(this){
				return _redis.send!bool("setnx" , key , cast(string)SerializeToByte!V(v)) == 1;
			}
		}

		void					putAll(V)(const V[string] maps)
		{
			synchronized(this){
				if(maps.length == 0)
				return;

				string[] cmds;
				foreach( k ,v ; maps){
					cmds ~= "set " ~ k ~ " " ~ cast(string)SerializeToByte!V(v);
				}
				_redis.pipeline(cmds);
			}
		}
		
		bool					remove(string key)
		{
			synchronized(this){
				return _redis.send!bool("del" , key);
			}
		}

		void					removeAll(string[] keys)
		{
			synchronized(this){
				if( keys.length == 0)
				return ;

				string[] cmds;
				foreach(k ; keys){
					cmds ~= "del " ~ k;
				}
				_redis.pipeline(cmds);
			}
		}

		void 					clear()
		{
			synchronized(this){
				_redis.send("flush");
			}
		}


		this(string host , int port){
			_redis = new Redis(host , cast(ushort)port);
		}

		this(){
			_redis = new Redis("127.0.0.1" , 6379);
		}


	protected:
		Redis					_redis;



}







}


# UCache
D language universal cache library.

# Support drivers
 * memory
 * memcache
 * redis
 * rocksdb
 
# tips
default support memory、memcache、redis.

you can remove "SUPPORT_MEMCACHE" from versions and remove memcache option from Dependencies to disable support memcache. the same as redis.

you can add "SUPPORT_ROCKSDB" into versions and add rocksdb lib into Dependencies,
config "lflags" and libs. 
example:
	"lflags": ["-L./lib"]  				// where is the rocksdb library, you may down code source , and compile.
	"libs": ["rocksdb","zstd"]  		//
	"rocksdb":{"version" :"~>0.0.7"}	// d bind lib.
		

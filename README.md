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

you can remove "SUPPORT_MEMCACHE" from versions and remove memcached option from dependencies to disable support memcache. the same as redis.

you can add "SUPPORT_ROCKSDB" into versions and add rocksdb lib into dependencies.<br/>
example see dub_old.json.

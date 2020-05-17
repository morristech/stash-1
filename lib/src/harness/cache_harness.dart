import 'package:quiver/time.dart';
import 'package:stash/src/api/cache.dart';
import 'package:stash/src/api/cache/default_cache.dart';
import 'package:stash/src/api/cache_store.dart';
import 'package:stash/src/api/eviction/eviction_policy.dart';
import 'package:stash/src/api/eviction/fifo_policy.dart';
import 'package:stash/src/api/eviction/filo_policy.dart';
import 'package:stash/src/api/eviction/lfu_policy.dart';
import 'package:stash/src/api/eviction/lru_policy.dart';
import 'package:stash/src/api/eviction/mfu_policy.dart';
import 'package:stash/src/api/eviction/mru_policy.dart';
import 'package:stash/src/api/expiry/accessed_policy.dart';
import 'package:stash/src/api/expiry/created_policy.dart';
import 'package:stash/src/api/expiry/eternal_policy.dart';
import 'package:stash/src/api/expiry/expiry_policy.dart';
import 'package:stash/src/api/expiry/modified_policy.dart';
import 'package:stash/src/api/expiry/touched_policy.dart';
import 'package:stash/src/api/sampler/sampler.dart';
import 'package:test/test.dart';

import 'value_generator.dart';

/// Creates a new [DefaultCache] bound to an implementation of the [CacheStore] interface
///
/// * [store]: The store implementation
/// * [name]: The name of the cache
/// * [expiryPolicy]: The expiry policy to use
/// * [sampler]: The sampler to use upon eviction of a cache element
/// * [evictionPolicy]: The eviction policy to use
/// * [maxEntries]: The max number of entries this cache can hold if provided.
/// * [cacheLoader]: The [CacheLoader], that should be used to fetch a new value upon expiration
/// * [clock]: The source of time to be used
DefaultCache newDefaultCache<T extends CacheStore>(T store,
    {String name,
    ExpiryPolicy expiryPolicy,
    KeySampler sampler,
    EvictionPolicy evictionPolicy,
    int maxEntries,
    CacheLoader cacheLoader,
    Clock clock}) {
  return Cache.newCache(store,
      name: name,
      expiryPolicy: expiryPolicy,
      sampler: sampler,
      evictionPolicy: evictionPolicy,
      maxEntries: maxEntries,
      cacheLoader: cacheLoader,
      clock: clock);
}

/// Calls [Cache.put] on a [Cache] backed by the provided [CacheStore] builder
///
/// * [newStore]: A delegate for the construction of a [CacheStore]
/// * [newCache]: A delegate for the construction of a [Cache]
/// * [generator]: A value generator
///
/// Returns the created store
Future<T> _cachePut<T extends CacheStore>(StoreBuilder<T> newStore,
    CacheBuilder newCache, ValueGenerator generator) async {
  var store = await newStore();
  var cache = newCache(store);

  var key = 'key_1';
  var value = generator.nextValue(1);
  await cache.put(key, value);

  return store;
}

/// Calls [Cache.put] on a [Cache] backed by the provided [CacheStore] builder
/// and removes the value through [Cache.remove]
///
/// * [newStore]: A delegate for the construction of a [CacheStore]
/// * [newCache]: A delegate for the construction of a [Cache]
/// * [generator]: A value generator
///
/// Returns the created store
Future<T> _cachePutRemove<T extends CacheStore>(StoreBuilder<T> newStore,
    CacheBuilder newCache, ValueGenerator generator) async {
  var store = await newStore();
  var cache = newCache(store);

  await cache.put('key_1', generator.nextValue(1));
  var size = await cache.size;
  expect(size, 1);

  await cache.remove('key_1');
  size = await cache.size;
  expect(size, 0);

  return store;
}

/// Calls [Cache.size] on a [Cache] backed by the provided [CacheStore] builder
///
/// * [newStore]: A delegate for the construction of a [CacheStore]
/// * [newCache]: A delegate for the construction of a [Cache]
/// * [generator]: A value generator
///
/// Returns the created store
Future<T> _cacheSize<T extends CacheStore>(StoreBuilder<T> newStore,
    CacheBuilder newCache, ValueGenerator generator) async {
  var store = await newStore();
  var cache = newCache(store);

  await cache.put('key_1', generator.nextValue(1));
  var size = await cache.size;
  expect(size, 1);

  await cache.put('key_2', generator.nextValue(2));
  size = await cache.size;
  expect(size, 2);

  await cache.put('key_3', generator.nextValue(3));
  size = await cache.size;
  expect(size, 3);

  await cache.remove('key_1');
  size = await cache.size;
  expect(size, 2);

  await cache.remove('key_2');
  size = await cache.size;
  expect(size, 1);

  await cache.remove('key_3');
  size = await cache.size;
  expect(size, 0);

  return store;
}

/// Calls [Cache.containsKey] on a [Cache] backed by the provided [CacheStore] builder
///
/// * [newStore]: A delegate for the construction of a [CacheStore]
/// * [newCache]: A delegate for the construction of a [Cache]
/// * [generator]: A value generator
///
/// Returns the created store
Future<T> _cacheContainsKey<T extends CacheStore>(StoreBuilder<T> newStore,
    CacheBuilder newCache, ValueGenerator generator) async {
  var store = await newStore();
  var cache = newCache(store);

  var key = 'key_1';
  var value = generator.nextValue(1);
  await cache.put(key, value);
  var hasKey = await cache.containsKey(key);

  expect(hasKey, isTrue);

  return store;
}

/// Calls [Cache.keys] on a [Cache] backed by the provided [CacheStore] builder
///
/// * [newStore]: A delegate for the construction of a [CacheStore]
/// * [newCache]: A delegate for the construction of a [Cache]
/// * [generator]: A value generator
///
/// Returns the created store
Future<T> _cacheKeys<T extends CacheStore>(StoreBuilder<T> newStore,
    CacheBuilder newCache, ValueGenerator generator) async {
  var store = await newStore();
  var cache = newCache(store);

  var key1 = 'key_1';
  await cache.put(key1, generator.nextValue(1));

  var key2 = 'key_2';
  await cache.put(key2, generator.nextValue(2));

  var key3 = 'key_3';
  await cache.put(key3, generator.nextValue(3));

  var keys = await cache.keys;

  expect(keys, containsAll([key1, key2, key3]));

  return store;
}

/// Calls [Cache.put] followed by a [Cache.get] on a [Cache] backed by
/// the provided [CacheStore] builder
///
/// * [newStore]: A delegate for the construction of a [CacheStore]
/// * [newCache]: A delegate for the construction of a [Cache]
/// * [generator]: A value generator
///
/// Returns the created store
Future<T> _cachePutGet<T extends CacheStore>(StoreBuilder<T> newStore,
    CacheBuilder newCache, ValueGenerator generator) async {
  var store = await newStore();
  var cache = newCache(store);

  var key = 'key_1';
  var value1 = generator.nextValue(1);
  await cache.put(key, value1);
  var value2 = await cache.get(key);

  expect(value2, value1);

  return store;
}

/// Calls [Cache.put] followed by a operator call on
/// a [Cache] backed by the provided [CacheStore] builder
///
/// * [newStore]: A delegate for the construction of a [CacheStore]
/// * [newCache]: A delegate for the construction of a [Cache]
/// * [generator]: A value generator
///
/// Returns the created store
Future<T> _cachePutGetOperator<T extends CacheStore>(StoreBuilder<T> newStore,
    CacheBuilder newCache, ValueGenerator generator) async {
  var store = await newStore();
  var cache = newCache(store);

  var key = 'key_1';
  var value1 = generator.nextValue(1);
  await cache.put(key, value1);
  var value2 = await cache[key];

  expect(value2, value1);

  return store;
}

/// Calls [Cache.put] followed by a second [Cache.put] on a [Cache] backed by
/// the provided [CacheStore] builder
///
/// * [newStore]: A delegate for the construction of a [CacheStore]
/// * [newCache]: A delegate for the construction of a [Cache]
/// * [generator]: A value generator
///
/// Returns the created store
Future<T> _cachePutPut<T extends CacheStore>(StoreBuilder<T> newStore,
    CacheBuilder newCache, ValueGenerator generator) async {
  var store = await newStore();
  var cache = newCache(store);

  var key = 'key_1';
  var value1 = generator.nextValue(1);
  await cache.put(key, value1);
  var size = await cache.size;
  expect(size, 1);
  var value2 = await cache.get(key);
  expect(value2, value1);

  value1 = generator.nextValue(1);
  await cache.put(key, value1);
  size = await cache.size;
  expect(size, 1);
  value2 = await cache.get(key);
  expect(value2, value1);

  return store;
}

/// Calls [Cache.putIfAbsent] on a [Cache] backed by the provided [CacheStore] builder
///
/// * [newStore]: A delegate for the construction of a [CacheStore]
/// * [newCache]: A delegate for the construction of a [Cache]
/// * [generator]: A value generator
///
/// Returns the created store
Future<T> _cachePutIfAbsent<T extends CacheStore>(StoreBuilder<T> newStore,
    CacheBuilder newCache, ValueGenerator generator) async {
  var store = await newStore();
  var cache = newCache(store);

  var key = 'key_1';
  var value1 = generator.nextValue(1);
  var added = await cache.putIfAbsent(key, value1);
  expect(added, isTrue);
  var size = await cache.size;
  expect(size, 1);
  var value2 = await cache.get(key);
  expect(value2, value1);

  added = await cache.putIfAbsent(key, generator.nextValue(2));
  expect(added, isFalse);
  size = await cache.size;
  expect(size, 1);
  value2 = await cache.get(key);
  expect(value2, value1);

  return store;
}

/// Calls [Cache.getAndPut] on a [Cache] backed by the provided [CacheStore] builder
///
/// * [newStore]: A delegate for the construction of a [CacheStore]
/// * [newCache]: A delegate for the construction of a [Cache]
/// * [generator]: A value generator
///
/// Returns the created store
Future<T> _cacheGetAndPut<T extends CacheStore>(StoreBuilder<T> newStore,
    CacheBuilder newCache, ValueGenerator generator) async {
  var store = await newStore();
  var cache = newCache(store);

  var key = 'key_1';
  var value1 = generator.nextValue(1);
  await cache.put(key, value1);
  var value2 = await cache.get(key);
  expect(value2, value1);

  var value3 = generator.nextValue(3);
  var value4 = await cache.getAndPut(key, value3);
  expect(value4, value1);

  var value5 = await cache.get(key);
  expect(value5, value3);

  return store;
}

/// Calls [Cache.getAndRemove] on a [Cache] backed by the provided [CacheStore] builder
///
/// * [newStore]: A delegate for the construction of a [CacheStore]
/// * [newCache]: A delegate for the construction of a [Cache]
/// * [generator]: A value generator
///
/// Returns the created store
Future<T> _cacheGetAndRemove<T extends CacheStore>(StoreBuilder<T> newStore,
    CacheBuilder newCache, ValueGenerator generator) async {
  var store = await newStore();
  var cache = newCache(store);

  var key = 'key_1';
  var value1 = generator.nextValue(1);
  await cache.put(key, value1);
  var value2 = await cache.get(key);
  expect(value2, value1);

  var value3 = await cache.getAndRemove(key);
  expect(value3, value1);

  var size = await cache.size;
  expect(size, 0);

  return store;
}

/// Calls [Cache.clear] on a [Cache] backed by the provided [CacheStore] builder
///
/// * [newStore]: A delegate for the construction of a [CacheStore]
/// * [newCache]: A delegate for the construction of a [Cache]
/// * [generator]: A value generator
///
/// Returns the created store
Future<T> _cacheClear<T extends CacheStore>(StoreBuilder<T> newStore,
    CacheBuilder newCache, ValueGenerator generator) async {
  var store = await newStore();
  var cache = newCache(store);

  await cache.put('key_1', generator.nextValue(1));
  await cache.put('key_2', generator.nextValue(2));
  await cache.put('key_3', generator.nextValue(3));
  var size = await cache.size;
  expect(size, 3);

  await cache.clear();
  size = await cache.size;
  expect(size, 0);

  return store;
}

/// Builds a [Cache] backed by the provided [CacheStore] builder
/// configured with a [CreatedExpiryPolicy]
///
/// * [newStore]: A delegate for the construction of a [CacheStore]
/// * [newCache]: A delegate for the construction of a [Cache]
/// * [generator]: A value generator
///
/// Returns the created store
Future<T> _cacheCreatedExpiry<T extends CacheStore>(StoreBuilder<T> newStore,
    CacheBuilder newCache, ValueGenerator generator) async {
  var store = await newStore();
  var cache = newCache(store,
      expiryPolicy: const CreatedExpiryPolicy(Duration(microseconds: 0)));

  await cache.put('key_1', generator.nextValue(1));
  var present = await cache.containsKey('key_1');
  expect(present, isFalse);

  return store;
}

/// Builds a [Cache] backed by the provided [CacheStore] builder
/// configured with a [AccessedExpiryPolicy]
///
/// * [newStore]: A delegate for the construction of a [CacheStore]
/// * [newCache]: A delegate for the construction of a [Cache]
/// * [generator]: A value generator
///
/// Returns the created store
Future<T> _cacheAccessedExpiry<T extends CacheStore>(StoreBuilder<T> newStore,
    CacheBuilder newCache, ValueGenerator generator) async {
  var now = Clock().fromNow(microseconds: 1);
  var store = await newStore();

  var cache = newCache(store,
      expiryPolicy: const AccessedExpiryPolicy(Duration(microseconds: 0)));

  await cache.put('key_1', generator.nextValue(1));
  var present = await cache.containsKey('key_1');
  expect(present, isFalse);

  var cache2 = newCache(store,
      expiryPolicy: const AccessedExpiryPolicy(Duration(minutes: 1)),
      clock: Clock(() => now));

  await cache2.put('key_1', generator.nextValue(1));
  present = await cache2.containsKey('key_1');
  expect(present, isTrue);

  now = Clock().fromNow(hours: 1);

  present = await cache2.containsKey('key_1');
  expect(present, isFalse);

  return store;
}

/// Builds a [Cache] backed by the provided [CacheStore] builder
/// configured with a [ModifiedExpiryPolicy]
///
/// * [newStore]: A delegate for the construction of a [CacheStore]
/// * [newCache]: A delegate for the construction of a [Cache]
/// * [generator]: A value generator
///
/// Returns the created store
Future<T> _cacheModifiedExpiry<T extends CacheStore>(StoreBuilder<T> newStore,
    CacheBuilder newCache, ValueGenerator generator) async {
  var now = Clock().fromNow(microseconds: 1);
  var store = await newStore();

  var cache1 = newCache(store,
      expiryPolicy: const ModifiedExpiryPolicy(Duration(microseconds: 0)));

  await cache1.put('key_1', generator.nextValue(1));
  var present = await cache1.containsKey('key_1');
  expect(present, isFalse);

  var cache2 = newCache(store,
      expiryPolicy: const ModifiedExpiryPolicy(Duration(minutes: 1)),
      clock: Clock(() => now));

  await cache2.put('key_1', generator.nextValue(1));
  present = await cache2.containsKey('key_1');
  expect(present, isTrue);

  now = Clock().fromNow(minutes: 2);

  present = await cache2.containsKey('key_1');
  expect(present, isFalse);

  var cache3 = newCache(store,
      expiryPolicy: const ModifiedExpiryPolicy(Duration(minutes: 1)),
      clock: Clock(() => now));

  await cache3.put('key_1', generator.nextValue(1));
  present = await cache3.containsKey('key_1');
  expect(present, isTrue);

  await cache3.put('key_1', generator.nextValue(2));
  now = Clock().fromNow(minutes: 2);

  present = await cache3.containsKey('key_1');
  expect(present, isTrue);

  now = Clock().fromNow(minutes: 3);
  present = await cache3.containsKey('key_1');
  expect(present, isFalse);

  return store;
}

/// Builds a [Cache] backed by the provided [CacheStore] builder
/// configured with a [TouchedExpiryPolicy]
///
/// * [newStore]: A delegate for the construction of a [CacheStore]
/// * [newCache]: A delegate for the construction of a [Cache]
/// * [generator]: A value generator
///
/// Returns the created store
Future<T> _cacheTouchedExpiry<T extends CacheStore>(StoreBuilder<T> newStore,
    CacheBuilder newCache, ValueGenerator generator) async {
  var now = Clock().fromNow(microseconds: 1);
  var store = await newStore();

  // The expiry policy works on creation of the cache
  var cache = newCache(store,
      expiryPolicy: const TouchedExpiryPolicy(Duration(microseconds: 0)));

  await cache.put('key_1', generator.nextValue(1));
  var present = await cache.containsKey('key_1');
  expect(present, isFalse);

  // The cache expires
  var cache2 = newCache(store,
      expiryPolicy: const TouchedExpiryPolicy(Duration(minutes: 1)),
      clock: Clock(() => now));

  await cache2.put('key_1', generator.nextValue(1));
  present = await cache2.containsKey('key_1');
  expect(present, isTrue);

  now = Clock().fromNow(minutes: 2);
  present = await cache2.containsKey('key_1');
  expect(present, isFalse);

  // Check if the updated of the cache increases the expiry time
  var cache3 = newCache(store,
      expiryPolicy: const TouchedExpiryPolicy(Duration(minutes: 1)),
      clock: Clock(() => now));

  // First add a cache entry during the 1 minute time, it should be there
  await cache3.put('key_1', generator.nextValue(1));
  present = await cache3.containsKey('key_1');
  expect(present, isTrue);

  // Then add another and move the clock to the next slot. It should be there as
  // well because the put added 1 minute
  await cache3.put('key_1', generator.nextValue(2));
  now = Clock().fromNow(minutes: 2);
  present = await cache3.containsKey('key_1');
  expect(present, isTrue);

  // Move the time again but this time without generating any change. The cache
  // should expire
  now = Clock().fromNow(minutes: 3);
  present = await cache3.containsKey('key_1');
  expect(present, isFalse);

  return store;
}

/// Builds a [Cache] backed by the provided [CacheStore] builder
/// configured with a [EternalExpiryPolicy]
///
/// * [newStore]: A delegate for the construction of a [CacheStore]
/// * [newCache]: A delegate for the construction of a [Cache]
/// * [generator]: A value generator
///
/// Returns the created store
Future<T> _cacheEternalExpiry<T extends CacheStore>(StoreBuilder<T> newStore,
    CacheBuilder newCache, ValueGenerator generator) async {
  var now = Clock().fromNow(microseconds: 1);
  var store = await newStore();
  var cache = newCache(store,
      expiryPolicy: const EternalExpiryPolicy(), clock: Clock(() => now));

  await cache.put('key_1', generator.nextValue(1));
  var present = await cache.containsKey('key_1');
  expect(present, isTrue);

  now = Clock().fromNow(days: 99999);

  present = await cache.containsKey('key_1');
  expect(present, isTrue);

  return store;
}

/// Builds a [Cache] backed by the provided [CacheStore] builder
/// configured with a [CacheLoader]
///
/// * [newStore]: A delegate for the construction of a [CacheStore]
/// * [newCache]: A delegate for the construction of a [Cache]
/// * [generator]: A value generator
///
/// Returns the created store
Future<T> _cacheLoader<T extends CacheStore>(StoreBuilder<T> newStore,
    CacheBuilder newCache, ValueGenerator generator) async {
  var store = await newStore();

  var value2 = generator.nextValue(2);
  var cache = newCache(store,
      expiryPolicy: const AccessedExpiryPolicy(Duration(microseconds: 0)),
      cacheLoader: (key) => Future.value(value2));

  await cache.put('key_1', generator.nextValue(1));
  var value = await cache.get('key_1');
  expect(value, equals(value2));

  return store;
}

/// Builds a [Cache] backed by the provided [CacheStore] builder
/// configured with a [FifoEvictionPolicy]
///
/// * [newStore]: A delegate for the construction of a [CacheStore]
/// * [newCache]: A delegate for the construction of a [Cache]
/// * [generator]: A value generator
///
/// Returns the created store
Future<T> _cacheFifoEviction<T extends CacheStore>(StoreBuilder<T> newStore,
    CacheBuilder newCache, ValueGenerator generator) async {
  var store = await newStore();
  var cache = newCache(store,
      maxEntries: 2, evictionPolicy: const FifoEvictionPolicy());

  await cache.put('key_1', generator.nextValue(1));
  await cache.put('key_2', generator.nextValue(2));
  var size = await cache.size;
  expect(size, 2);

  await cache.put('key_3', generator.nextValue(3));
  size = await cache.size;
  expect(size, 2);

  var present = await cache.containsKey('key_1');
  expect(present, isFalse);

  return store;
}

/// Builds a [Cache] backed by the provided [CacheStore] builder
/// configured with a [FiloEvictionPolicy]
///
/// * [newStore]: A delegate for the construction of a [CacheStore]
/// * [newCache]: A delegate for the construction of a [Cache]
/// * [generator]: A value generator
///
/// Returns the created store
Future<T> _cacheFiloEviction<T extends CacheStore>(StoreBuilder<T> newStore,
    CacheBuilder newCache, ValueGenerator generator) async {
  var store = await newStore();
  var cache = newCache(store,
      maxEntries: 2, evictionPolicy: const FiloEvictionPolicy());

  await cache.put('key_1', generator.nextValue(1));
  await cache.put('key_2', generator.nextValue(2));
  var size = await cache.size;
  expect(size, 2);

  await cache.put('key_3', generator.nextValue(3));
  size = await cache.size;
  expect(size, 2);

  var present = await cache.containsKey('key_3');
  expect(present, isTrue);

  return store;
}

/// Builds a [Cache] backed by the provided [CacheStore] builder
/// configured with a [LruEvictionPolicy]
///
/// * [newStore]: A delegate for the construction of a [CacheStore]
/// * [newCache]: A delegate for the construction of a [Cache]
/// * [generator]: A value generator
///
/// Returns the created store
Future<T> _cacheLruEviction<T extends CacheStore>(StoreBuilder<T> newStore,
    CacheBuilder newCache, ValueGenerator generator) async {
  var store = await newStore();
  var cache =
      newCache(store, maxEntries: 3, evictionPolicy: const LruEvictionPolicy());

  await cache.put('key_1', generator.nextValue(1));
  await cache.put('key_2', generator.nextValue(2));
  await cache.put('key_3', generator.nextValue(3));
  var size = await cache.size;
  expect(size, 3);

  await cache.get('key_1');
  await cache.get('key_3');

  await cache.put('key_4', generator.nextValue(4));
  size = await cache.size;
  expect(size, 3);

  var present = await cache.containsKey('key_2');
  expect(present, isFalse);

  return store;
}

/// Builds a [Cache] backed by the provided [CacheStore] builder
/// configured with a [MruEvictionPolicy]
///
/// * [newStore]: A delegate for the construction of a [CacheStore]
/// * [newCache]: A delegate for the construction of a [Cache]
/// * [generator]: A value generator
///
/// Returns the created store
Future<T> _cacheMruEviction<T extends CacheStore>(StoreBuilder<T> newStore,
    CacheBuilder newCache, ValueGenerator generator) async {
  var store = await newStore();
  var cache =
      newCache(store, maxEntries: 3, evictionPolicy: const MruEvictionPolicy());

  await cache.put('key_1', generator.nextValue(1));
  await cache.put('key_2', generator.nextValue(2));
  await cache.put('key_3', generator.nextValue(3));
  var size = await cache.size;
  expect(size, 3);

  await cache.get('key_1');
  await cache.get('key_3');

  await cache.put('key_4', generator.nextValue(4));
  size = await cache.size;
  expect(size, 3);

  var present = await cache.containsKey('key_3');
  expect(present, isFalse);

  return store;
}

/// Builds a [Cache] backed by the provided [CacheStore] builder
/// configured with a [LfuEvictionPolicy]
///
/// * [newStore]: A delegate for the construction of a [CacheStore]
/// * [newCache]: A delegate for the construction of a [Cache]
/// * [generator]: A value generator
///
/// Returns the created store
Future<T> _cacheLfuEviction<T extends CacheStore>(StoreBuilder<T> newStore,
    CacheBuilder newCache, ValueGenerator generator) async {
  var store = await newStore();
  var cache =
      newCache(store, maxEntries: 3, evictionPolicy: const LfuEvictionPolicy());

  await cache.put('key_1', generator.nextValue(1));
  await cache.put('key_2', generator.nextValue(2));
  await cache.put('key_3', generator.nextValue(3));
  var size = await cache.size;
  expect(size, 3);

  await cache.get('key_1');
  await cache.get('key_1');
  await cache.get('key_1');
  await cache.get('key_2');
  await cache.get('key_3');
  await cache.get('key_3');

  await cache.put('key_4', generator.nextValue(4));
  size = await cache.size;
  expect(size, 3);

  var present = await cache.containsKey('key_2');
  expect(present, isFalse);

  return store;
}

/// Builds a [Cache] backed by the provided [CacheStore] builder
/// configured with a [MfuEvictionPolicy]
///
/// * [newStore]: A delegate for the construction of a [CacheStore]
/// * [newCache]: A delegate for the construction of a [Cache]
/// * [generator]: A value generator
///
/// Returns the created store
Future<T> _cacheMfuEviction<T extends CacheStore>(StoreBuilder<T> newStore,
    CacheBuilder newCache, ValueGenerator generator) async {
  var store = await newStore();
  var cache =
      newCache(store, maxEntries: 3, evictionPolicy: const MfuEvictionPolicy());

  await cache.put('key_1', generator.nextValue(1));
  await cache.put('key_2', generator.nextValue(2));
  await cache.put('key_3', generator.nextValue(3));
  var size = await cache.size;
  expect(size, 3);

  await cache.get('key_1');
  await cache.get('key_1');
  await cache.get('key_1');
  await cache.get('key_2');
  await cache.get('key_3');
  await cache.get('key_3');

  await cache.put('key_4', generator.nextValue(4));
  size = await cache.size;
  expect(size, 3);

  var present = await cache.containsKey('key_1');
  expect(present, isFalse);

  return store;
}

/// returns the list of tests to execute
List<Future<T> Function(StoreBuilder<T>, CacheBuilder, ValueGenerator)>
    _getCacheTests<T extends CacheStore>() {
  return [
    _cachePut,
    _cachePutRemove,
    _cacheSize,
    _cacheContainsKey,
    _cacheKeys,
    _cachePutGet,
    _cachePutGetOperator,
    _cachePutPut,
    _cachePutIfAbsent,
    _cacheGetAndPut,
    _cacheGetAndRemove,
    _cacheClear,
    _cacheCreatedExpiry,
    _cacheAccessedExpiry,
    _cacheModifiedExpiry,
    _cacheTouchedExpiry,
    _cacheEternalExpiry,
    _cacheLoader,
    _cacheFifoEviction,
    _cacheFiloEviction,
    _cacheLruEviction,
    _cacheMruEviction,
    _cacheLfuEviction,
    _cacheMfuEviction
  ];
}

/// Entry point for the cache testing harness. It delegates most of the
/// construction to user provided functions that are responsible for the [CacheStore] creation,
/// the [Cache] creation and by the generation of testing values
/// (with a provided [ValueGenerator] instance).
///
/// * [newStore]: A delegate for the construction of a [CacheStore]
/// * [newCache]: A delegate for the construction of a [Cache]
/// * [generator]: A value generator
/// * [tearDown]: A optional function to release any resources held by the [CacheStore]
void testCacheWith<T extends CacheStore>(
    StoreBuilder<T> newStore, CacheBuilder newCache, ValueGenerator generator,
    [Future<void> Function(T store) tearDown]) async {
  tearDown = tearDown ?? ((T store) => Future.value());

  for (var test in _getCacheTests<T>()) {
    await test(newStore, newCache, generator).then(tearDown);
  }
}
// ignore_for_file: cascade_invocations
import 'dart:convert';

import 'package:test/test.dart';
import 'package:velox_cache/velox_cache.dart';
import 'package:velox_storage/velox_storage.dart';

void main() {
  group('LruCache', () {
    test('puts and gets values', () {
      final cache = LruCache<String>(maxSize: 3);
      cache.put('a', 'alpha');
      expect(cache.get('a'), 'alpha');
    });

    test('returns null for missing key', () {
      final cache = LruCache<String>(maxSize: 3);
      expect(cache.get('missing'), isNull);
    });

    test('evicts least recently used when full', () {
      final cache = LruCache<String>(maxSize: 3);
      cache
        ..put('a', 'alpha')
        ..put('b', 'beta')
        ..put('c', 'gamma');

      // Access 'a' to make it recently used
      cache.get('a');

      // Add 'd', should evict 'b' (least recently used)
      cache.put('d', 'delta');

      expect(cache.get('b'), isNull);
      expect(cache.get('a'), 'alpha');
      expect(cache.get('d'), 'delta');
    });

    test('updates existing key without eviction', () {
      final cache = LruCache<String>(maxSize: 2);
      cache
        ..put('a', 'alpha')
        ..put('b', 'beta')
        ..put('a', 'updated');

      expect(cache.get('a'), 'updated');
      expect(cache.size, 2);
    });

    test('remove removes entry', () {
      final cache = LruCache<String>(maxSize: 3);
      cache.put('a', 'alpha');
      expect(cache.remove('a'), 'alpha');
      expect(cache.get('a'), isNull);
    });

    test('containsKey works correctly', () {
      final cache = LruCache<String>(maxSize: 3);
      cache.put('a', 'alpha');
      expect(cache.containsKey('a'), isTrue);
      expect(cache.containsKey('b'), isFalse);
    });

    test('clear empties cache', () {
      final cache = LruCache<String>(maxSize: 3);
      cache
        ..put('a', 'alpha')
        ..put('b', 'beta')
        ..clear();
      expect(cache.isEmpty, isTrue);
      expect(cache.size, 0);
    });

    test('getOrPut computes value if absent', () {
      final cache = LruCache<String>(maxSize: 3);
      final value = cache.getOrPut('a', () => 'computed');
      expect(value, 'computed');
      expect(cache.get('a'), 'computed');
    });

    test('getOrPut returns existing value', () {
      final cache = LruCache<String>(maxSize: 3);
      cache.put('a', 'existing');
      final value = cache.getOrPut('a', () => 'computed');
      expect(value, 'existing');
    });

    test('isFull returns correct state', () {
      final cache = LruCache<String>(maxSize: 2);
      expect(cache.isFull, isFalse);
      cache
        ..put('a', 'alpha')
        ..put('b', 'beta');
      expect(cache.isFull, isTrue);
    });
  });

  group('TtlCache', () {
    test('puts and gets values', () {
      final cache = TtlCache<String>(defaultTtl: const Duration(hours: 1));
      cache.put('a', 'alpha');
      expect(cache.get('a'), 'alpha');
    });

    test('returns null for expired entries', () {
      final cache = TtlCache<String>(defaultTtl: Duration.zero);
      cache.put('a', 'alpha');

      // Entry should be immediately expired
      expect(cache.get('a'), isNull);
    });

    test('containsKey returns false for expired', () {
      final cache = TtlCache<String>(defaultTtl: Duration.zero);
      cache.put('a', 'alpha');
      expect(cache.containsKey('a'), isFalse);
    });

    test('custom ttl per entry', () {
      final cache = TtlCache<String>(defaultTtl: const Duration(hours: 1));
      cache.put('a', 'alpha', ttl: Duration.zero);
      expect(cache.get('a'), isNull);
    });

    test('removeExpired cleans up', () {
      final cache = TtlCache<String>(defaultTtl: Duration.zero);
      cache.put('a', 'alpha');
      cache.removeExpired();
      expect(cache.isEmpty, isTrue);
    });

    test('getOrPut computes value for expired', () {
      final cache = TtlCache<String>(defaultTtl: Duration.zero);
      cache.put('a', 'old');
      final value = cache.getOrPut('a', () => 'new');
      expect(value, 'new');
    });
  });

  group('VeloxCache', () {
    test('puts and gets values', () {
      final cache = VeloxCache<String>(
        maxSize: 3,
        defaultTtl: const Duration(hours: 1),
      );
      cache.put('a', 'alpha');
      expect(cache.get('a'), 'alpha');
      cache.dispose();
    });

    test('evicts LRU when full', () {
      final cache = VeloxCache<String>(
        maxSize: 2,
        defaultTtl: const Duration(hours: 1),
      );
      cache
        ..put('a', 'alpha')
        ..put('b', 'beta');

      cache.get('a'); // Touch 'a'
      cache.put('c', 'gamma'); // Should evict 'b'

      expect(cache.get('b'), isNull);
      expect(cache.get('a'), 'alpha');
      cache.dispose();
    });

    test('expires entries after TTL', () {
      final cache = VeloxCache<String>(
        maxSize: 10,
        defaultTtl: Duration.zero,
      );
      cache.put('a', 'alpha');
      expect(cache.get('a'), isNull);
      cache.dispose();
    });

    test('emits events on onChange', () async {
      final cache = VeloxCache<String>(
        maxSize: 10,
        defaultTtl: const Duration(hours: 1),
      );

      final events = <CacheEvent<String>>[];
      final sub = cache.onChange.listen(events.add);

      cache.put('a', 'alpha');
      cache.remove('a');
      cache.clear();

      await Future<void>.delayed(Duration.zero);
      // put emits: put event
      // remove emits: removed event
      // clear emits: cleared event
      expect(events.where((e) => e.type == CacheEventType.put), hasLength(1));
      expect(
        events.where((e) => e.type == CacheEventType.removed),
        hasLength(1),
      );
      expect(
        events.where((e) => e.type == CacheEventType.cleared),
        hasLength(1),
      );

      await sub.cancel();
      cache.dispose();
    });

    test('getOrPut works correctly', () {
      final cache = VeloxCache<String>(
        maxSize: 10,
        defaultTtl: const Duration(hours: 1),
      );

      final value = cache.getOrPut('a', () => 'computed');
      expect(value, 'computed');
      expect(cache.get('a'), 'computed');
      cache.dispose();
    });

    test('getOrPutAsync works correctly', () async {
      final cache = VeloxCache<String>(
        maxSize: 10,
        defaultTtl: const Duration(hours: 1),
      );

      final value = await cache.getOrPutAsync('a', () async => 'async_value');
      expect(value, 'async_value');
      expect(cache.get('a'), 'async_value');
      cache.dispose();
    });

    test('containsKey returns false for expired', () {
      final cache = VeloxCache<String>(
        maxSize: 10,
        defaultTtl: Duration.zero,
      );
      cache.put('a', 'alpha');
      expect(cache.containsKey('a'), isFalse);
      cache.dispose();
    });
  });

  group('CacheEntry', () {
    test('isExpired returns true for past expiry', () {
      final entry = CacheEntry(
        key: 'a',
        value: 'alpha',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(entry.isExpired, isTrue);
      expect(entry.isValid, isFalse);
    });

    test('isExpired returns false for future expiry', () {
      final entry = CacheEntry(
        key: 'a',
        value: 'alpha',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(entry.isExpired, isFalse);
      expect(entry.isValid, isTrue);
    });

    test('isExpired returns false when expiresAt is null', () {
      final entry = CacheEntry(
        key: 'a',
        value: 'alpha',
        createdAt: DateTime.now(),
      );
      expect(entry.isExpired, isFalse);
    });

    test('touch updates lastAccessedAt and increments accessCount', () {
      final entry = CacheEntry(
        key: 'a',
        value: 'alpha',
        createdAt: DateTime(2020),
      );
      expect(entry.accessCount, 0);
      final before = entry.lastAccessedAt;
      entry.touch();
      expect(entry.lastAccessedAt.isAfter(before), isTrue);
      expect(entry.accessCount, 1);
      entry.touch();
      expect(entry.accessCount, 2);
    });

    test('tags are stored and queryable', () {
      final entry = CacheEntry(
        key: 'a',
        value: 'alpha',
        createdAt: DateTime.now(),
        tags: {'user', 'profile'},
      );
      expect(entry.hasTag('user'), isTrue);
      expect(entry.hasTag('unknown'), isFalse);
      expect(entry.hasAnyTag({'user', 'admin'}), isTrue);
      expect(entry.hasAnyTag({'admin', 'system'}), isFalse);
      expect(entry.tags, containsAll(['user', 'profile']));
    });

    test('tags default to empty set', () {
      final entry = CacheEntry(
        key: 'a',
        value: 'alpha',
        createdAt: DateTime.now(),
      );
      expect(entry.tags, isEmpty);
      expect(entry.hasTag('any'), isFalse);
    });
  });

  group('VeloxCacheStats', () {
    test('starts at zero', () {
      final stats = VeloxCacheStats();
      expect(stats.hits, 0);
      expect(stats.misses, 0);
      expect(stats.evictions, 0);
      expect(stats.expirations, 0);
      expect(stats.writes, 0);
      expect(stats.totalLookups, 0);
      expect(stats.hitRate, 0.0);
      expect(stats.missRate, 0.0);
    });

    test('records hits and misses', () {
      final stats = VeloxCacheStats();
      stats
        ..recordHit()
        ..recordHit()
        ..recordMiss();
      expect(stats.hits, 2);
      expect(stats.misses, 1);
      expect(stats.totalLookups, 3);
    });

    test('computes hit rate correctly', () {
      final stats = VeloxCacheStats();
      stats
        ..recordHit()
        ..recordHit()
        ..recordHit()
        ..recordMiss();
      expect(stats.hitRate, closeTo(0.75, 0.001));
      expect(stats.missRate, closeTo(0.25, 0.001));
    });

    test('records evictions and expirations', () {
      final stats = VeloxCacheStats();
      stats
        ..recordEviction()
        ..recordEviction()
        ..recordExpiration();
      expect(stats.evictions, 2);
      expect(stats.expirations, 1);
    });

    test('records writes', () {
      final stats = VeloxCacheStats();
      stats
        ..recordWrite()
        ..recordWrite();
      expect(stats.writes, 2);
    });

    test('reset clears all counters', () {
      final stats = VeloxCacheStats();
      stats
        ..recordHit()
        ..recordMiss()
        ..recordEviction()
        ..recordExpiration()
        ..recordWrite()
        ..reset();
      expect(stats.hits, 0);
      expect(stats.misses, 0);
      expect(stats.evictions, 0);
      expect(stats.expirations, 0);
      expect(stats.writes, 0);
    });

    test('toString provides useful output', () {
      final stats = VeloxCacheStats();
      stats.recordHit();
      final str = stats.toString();
      expect(str, contains('hits: 1'));
    });
  });

  group('LfuCache', () {
    test('puts and gets values', () {
      final cache = LfuCache<String>(maxSize: 3);
      cache.put('a', 'alpha');
      expect(cache.get('a'), 'alpha');
    });

    test('returns null for missing key', () {
      final cache = LfuCache<String>(maxSize: 3);
      expect(cache.get('missing'), isNull);
    });

    test('evicts least frequently used when full', () {
      final cache = LfuCache<String>(maxSize: 3);
      cache
        ..put('a', 'alpha')
        ..put('b', 'beta')
        ..put('c', 'gamma');

      // Access 'a' twice, 'c' once, 'b' zero times
      cache.get('a');
      cache.get('a');
      cache.get('c');

      // Add 'd', should evict 'b' (least frequently used: 0 accesses)
      cache.put('d', 'delta');

      expect(cache.get('b'), isNull);
      expect(cache.get('a'), 'alpha');
      expect(cache.get('c'), 'gamma');
      expect(cache.get('d'), 'delta');
    });

    test('uses LRU as tiebreaker for same frequency', () {
      final cache = LfuCache<String>(maxSize: 2);
      cache.put('a', 'alpha');
      // Wait a bit to ensure different timestamps
      cache.put('b', 'beta');

      // Both have 0 access count, 'a' was created first (oldest)
      cache.put('c', 'gamma');
      expect(cache.get('a'), isNull); // Evicted (older with same frequency)
      expect(cache.get('b'), 'beta');
    });

    test('accessCount returns correct count', () {
      final cache = LfuCache<String>(maxSize: 3);
      cache.put('a', 'alpha');
      expect(cache.accessCount('a'), 0);
      cache.get('a');
      expect(cache.accessCount('a'), 1);
      cache.get('a');
      expect(cache.accessCount('a'), 2);
    });

    test('accessCount returns null for missing key', () {
      final cache = LfuCache<String>(maxSize: 3);
      expect(cache.accessCount('missing'), isNull);
    });

    test('clear empties cache', () {
      final cache = LfuCache<String>(maxSize: 3);
      cache
        ..put('a', 'alpha')
        ..put('b', 'beta')
        ..clear();
      expect(cache.isEmpty, isTrue);
    });

    test('containsKey works correctly', () {
      final cache = LfuCache<String>(maxSize: 3);
      cache.put('a', 'alpha');
      expect(cache.containsKey('a'), isTrue);
      expect(cache.containsKey('b'), isFalse);
    });

    test('getOrPut computes value if absent', () {
      final cache = LfuCache<String>(maxSize: 3);
      final value = cache.getOrPut('a', () => 'computed');
      expect(value, 'computed');
      expect(cache.get('a'), 'computed');
    });

    test('updates existing key without eviction', () {
      final cache = LfuCache<String>(maxSize: 2);
      cache
        ..put('a', 'alpha')
        ..put('b', 'beta')
        ..put('a', 'updated');
      expect(cache.get('a'), 'updated');
      expect(cache.size, 2);
    });
  });

  group('VeloxCache - Tags', () {
    test('put with tags stores tags', () {
      final cache = VeloxCache<String>(
        maxSize: 10,
        defaultTtl: const Duration(hours: 1),
      );
      cache.put('user:1', 'John', tags: {'user', 'active'});
      final entry = cache.entry('user:1');
      expect(entry, isNotNull);
      expect(entry!.tags, containsAll(['user', 'active']));
      cache.dispose();
    });

    test('invalidateByTag removes tagged entries', () {
      final cache = VeloxCache<String>(
        maxSize: 10,
        defaultTtl: const Duration(hours: 1),
      );
      cache
        ..put('user:1', 'John', tags: {'user'})
        ..put('user:2', 'Jane', tags: {'user'})
        ..put('config:1', 'dark', tags: {'config'});

      final removed = cache.invalidateByTag('user');
      expect(removed, 2);
      expect(cache.get('user:1'), isNull);
      expect(cache.get('user:2'), isNull);
      expect(cache.get('config:1'), 'dark');
      cache.dispose();
    });

    test('invalidateByTags removes entries with any matching tag', () {
      final cache = VeloxCache<String>(
        maxSize: 10,
        defaultTtl: const Duration(hours: 1),
      );
      cache
        ..put('a', '1', tags: {'user'})
        ..put('b', '2', tags: {'config'})
        ..put('c', '3', tags: {'system'});

      final removed = cache.invalidateByTags({'user', 'config'});
      expect(removed, 2);
      expect(cache.size, 1);
      expect(cache.get('c'), '3');
      cache.dispose();
    });

    test('keysByTag returns matching keys', () {
      final cache = VeloxCache<String>(
        maxSize: 10,
        defaultTtl: const Duration(hours: 1),
      );
      cache
        ..put('user:1', 'John', tags: {'user'})
        ..put('user:2', 'Jane', tags: {'user'})
        ..put('config:1', 'dark', tags: {'config'});

      final userKeys = cache.keysByTag('user');
      expect(userKeys, containsAll(['user:1', 'user:2']));
      expect(userKeys, hasLength(2));
      cache.dispose();
    });
  });

  group('VeloxCache - Statistics', () {
    test('tracks hits and misses', () {
      final cache = VeloxCache<String>(
        maxSize: 10,
        defaultTtl: const Duration(hours: 1),
      );
      cache.put('a', 'alpha');
      cache.get('a'); // hit
      cache.get('b'); // miss

      expect(cache.stats.hits, 1);
      expect(cache.stats.misses, 1);
      cache.dispose();
    });

    test('tracks evictions', () {
      final cache = VeloxCache<String>(
        maxSize: 2,
        defaultTtl: const Duration(hours: 1),
      );
      cache
        ..put('a', 'alpha')
        ..put('b', 'beta')
        ..put('c', 'gamma'); // evicts 'a'

      expect(cache.stats.evictions, 1);
      cache.dispose();
    });

    test('tracks writes', () {
      final cache = VeloxCache<String>(
        maxSize: 10,
        defaultTtl: const Duration(hours: 1),
      );
      cache
        ..put('a', 'alpha')
        ..put('b', 'beta');
      expect(cache.stats.writes, 2);
      cache.dispose();
    });

    test('hitRate is computed correctly', () {
      final cache = VeloxCache<String>(
        maxSize: 10,
        defaultTtl: const Duration(hours: 1),
      );
      cache.put('a', 'alpha');
      cache.get('a'); // hit
      cache.get('a'); // hit
      cache.get('b'); // miss

      expect(cache.stats.hitRate, closeTo(0.666, 0.01));
      cache.dispose();
    });

    test('stats reset works', () {
      final cache = VeloxCache<String>(
        maxSize: 10,
        defaultTtl: const Duration(hours: 1),
      );
      cache.put('a', 'alpha');
      cache.get('a');
      cache.stats.reset();
      expect(cache.stats.hits, 0);
      expect(cache.stats.misses, 0);
      expect(cache.stats.writes, 0);
      cache.dispose();
    });
  });

  group('VeloxCache - Bulk Operations', () {
    test('putAll adds multiple entries', () {
      final cache = VeloxCache<String>(
        maxSize: 10,
        defaultTtl: const Duration(hours: 1),
      );
      cache.putAll({'a': 'alpha', 'b': 'beta', 'c': 'gamma'});
      expect(cache.size, 3);
      expect(cache.get('a'), 'alpha');
      expect(cache.get('b'), 'beta');
      expect(cache.get('c'), 'gamma');
      cache.dispose();
    });

    test('putAll with tags applies tags to all entries', () {
      final cache = VeloxCache<String>(
        maxSize: 10,
        defaultTtl: const Duration(hours: 1),
      );
      cache.putAll({'a': 'alpha', 'b': 'beta'}, tags: {'batch'});
      expect(cache.entry('a')!.tags, contains('batch'));
      expect(cache.entry('b')!.tags, contains('batch'));
      cache.dispose();
    });

    test('getAll returns found entries', () {
      final cache = VeloxCache<String>(
        maxSize: 10,
        defaultTtl: const Duration(hours: 1),
      );
      cache.putAll({'a': 'alpha', 'b': 'beta', 'c': 'gamma'});
      final results = cache.getAll(['a', 'c', 'missing']);
      expect(results, {'a': 'alpha', 'c': 'gamma'});
      cache.dispose();
    });

    test('removeAll removes specified entries', () {
      final cache = VeloxCache<String>(
        maxSize: 10,
        defaultTtl: const Duration(hours: 1),
      );
      cache.putAll({'a': 'alpha', 'b': 'beta', 'c': 'gamma'});
      final removed = cache.removeAll(['a', 'c']);
      expect(removed, {'a': 'alpha', 'c': 'gamma'});
      expect(cache.size, 1);
      expect(cache.get('b'), 'beta');
      cache.dispose();
    });
  });

  group('VeloxCache - Cache Loader', () {
    test('getOrLoad loads on cache miss', () async {
      final cache = VeloxCache<String>(
        maxSize: 10,
        defaultTtl: const Duration(hours: 1),
      );

      var loaderCalled = false;
      final value = await cache.getOrLoad('user:1', () async {
        loaderCalled = true;
        return 'John';
      });

      expect(value, 'John');
      expect(loaderCalled, isTrue);
      expect(cache.get('user:1'), 'John');
      cache.dispose();
    });

    test('getOrLoad returns cached value on hit', () async {
      final cache = VeloxCache<String>(
        maxSize: 10,
        defaultTtl: const Duration(hours: 1),
      );
      cache.put('user:1', 'John');

      var loaderCalled = false;
      final value = await cache.getOrLoad('user:1', () async {
        loaderCalled = true;
        return 'Jane';
      });

      expect(value, 'John');
      expect(loaderCalled, isFalse);
      cache.dispose();
    });

    test('getOrLoad stores tags from loader', () async {
      final cache = VeloxCache<String>(
        maxSize: 10,
        defaultTtl: const Duration(hours: 1),
      );

      await cache.getOrLoad(
        'user:1',
        () async => 'John',
        tags: {'user'},
      );

      expect(cache.entry('user:1')!.tags, contains('user'));
      cache.dispose();
    });
  });

  group('VeloxCache - Cache Events', () {
    test('emits hit events', () async {
      final cache = VeloxCache<String>(
        maxSize: 10,
        defaultTtl: const Duration(hours: 1),
      );

      final events = <CacheEvent<String>>[];
      final sub = cache.onChange.listen(events.add);

      cache.put('a', 'alpha');
      cache.get('a');

      await Future<void>.delayed(Duration.zero);
      expect(
        events.any((e) => e.type == CacheEventType.hit && e.key == 'a'),
        isTrue,
      );

      await sub.cancel();
      cache.dispose();
    });

    test('emits miss events', () async {
      final cache = VeloxCache<String>(
        maxSize: 10,
        defaultTtl: const Duration(hours: 1),
      );

      final events = <CacheEvent<String>>[];
      final sub = cache.onChange.listen(events.add);

      cache.get('missing');

      await Future<void>.delayed(Duration.zero);
      expect(
        events.any(
          (e) => e.type == CacheEventType.miss && e.key == 'missing',
        ),
        isTrue,
      );

      await sub.cancel();
      cache.dispose();
    });

    test('emits eviction events', () async {
      final cache = VeloxCache<String>(
        maxSize: 2,
        defaultTtl: const Duration(hours: 1),
      );

      final events = <CacheEvent<String>>[];
      final sub = cache.onChange.listen(events.add);

      cache
        ..put('a', 'alpha')
        ..put('b', 'beta')
        ..put('c', 'gamma'); // Evicts 'a'

      await Future<void>.delayed(Duration.zero);
      expect(
        events.any((e) => e.type == CacheEventType.evicted),
        isTrue,
      );

      await sub.cancel();
      cache.dispose();
    });

    test('emits expiration events', () async {
      final cache = VeloxCache<String>(
        maxSize: 10,
        defaultTtl: Duration.zero,
      );

      final events = <CacheEvent<String>>[];
      final sub = cache.onChange.listen(events.add);

      cache.put('a', 'alpha');
      cache.get('a'); // Should be expired

      await Future<void>.delayed(Duration.zero);
      expect(
        events.any((e) => e.type == CacheEventType.expired),
        isTrue,
      );

      await sub.cancel();
      cache.dispose();
    });
  });

  group('VeloxCache - Stale While Revalidate', () {
    test('returns null for non-existent key', () {
      final cache = VeloxCache<String>(
        maxSize: 10,
        defaultTtl: const Duration(hours: 1),
      );

      final value = cache.getStale(
        'missing',
        refresh: () async => 'fresh',
      );
      expect(value, isNull);
      cache.dispose();
    });

    test('returns fresh value when not expired', () {
      final cache = VeloxCache<String>(
        maxSize: 10,
        defaultTtl: const Duration(hours: 1),
      );
      cache.put('a', 'alpha');

      final value = cache.getStale('a', refresh: () async => 'fresh');
      expect(value, 'alpha');
      cache.dispose();
    });

    test('returns stale value within tolerance and triggers refresh',
        () async {
      final cache = VeloxCache<String>(
        maxSize: 10,
        defaultTtl: Duration.zero, // Expires immediately
      );
      cache.put('a', 'stale_value');

      // The entry is expired but within stale tolerance (1 minute)
      final value = cache.getStale(
        'a',
        refresh: () async => 'fresh_value',
        staleTolerance: const Duration(minutes: 5),
        ttl: const Duration(hours: 1), // Refresh with long TTL
      );

      expect(value, 'stale_value');

      // Wait for background refresh
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cache.get('a'), 'fresh_value');
      cache.dispose();
    });

    test('emits stale event when serving stale data', () async {
      final cache = VeloxCache<String>(
        maxSize: 10,
        defaultTtl: Duration.zero,
      );
      cache.put('a', 'stale_value');

      final events = <CacheEvent<String>>[];
      final sub = cache.onChange.listen(events.add);

      cache.getStale(
        'a',
        refresh: () async => 'fresh',
        staleTolerance: const Duration(minutes: 5),
      );

      await Future<void>.delayed(Duration.zero);
      expect(
        events.any((e) => e.type == CacheEventType.stale && e.key == 'a'),
        isTrue,
      );

      await sub.cancel();
      // Wait for background refresh to complete before dispose
      await Future<void>.delayed(const Duration(milliseconds: 50));
      cache.dispose();
    });
  });

  group('VeloxCache - Entry Metadata', () {
    test('entry returns metadata for valid key', () {
      final cache = VeloxCache<String>(
        maxSize: 10,
        defaultTtl: const Duration(hours: 1),
      );
      cache.put('a', 'alpha', tags: {'test'});
      cache.get('a'); // Touch to increment access count

      final entry = cache.entry('a');
      expect(entry, isNotNull);
      expect(entry!.key, 'a');
      expect(entry.value, 'alpha');
      expect(entry.accessCount, 1);
      expect(entry.tags, contains('test'));
      expect(entry.createdAt, isNotNull);
      expect(entry.lastAccessedAt, isNotNull);
      cache.dispose();
    });

    test('entry returns null for missing key', () {
      final cache = VeloxCache<String>(
        maxSize: 10,
        defaultTtl: const Duration(hours: 1),
      );
      expect(cache.entry('missing'), isNull);
      cache.dispose();
    });

    test('entry returns null for expired key', () {
      final cache = VeloxCache<String>(
        maxSize: 10,
        defaultTtl: Duration.zero,
      );
      cache.put('a', 'alpha');
      expect(cache.entry('a'), isNull);
      cache.dispose();
    });
  });

  group('WriteThroughCache', () {
    late VeloxStorage storage;

    setUp(() {
      storage = VeloxStorage(adapter: MemoryStorageAdapter());
    });

    tearDown(() async {
      await storage.dispose();
    });

    test('put stores in both memory and storage', () async {
      final cache = WriteThroughCache<String>(
        storage: storage,
        maxSize: 10,
        defaultTtl: const Duration(hours: 1),
        serialize: (v) => v,
        deserialize: (s) => s,
      );

      await cache.put('a', 'alpha');
      expect(await cache.get('a'), 'alpha');

      // Verify it's in storage
      final stored = await storage.getString('wtc:a');
      expect(stored, isNotNull);
      expect(stored, contains('alpha'));
    });

    test('get falls through to storage on memory miss', () async {
      final cache = WriteThroughCache<String>(
        storage: storage,
        maxSize: 10,
        defaultTtl: const Duration(hours: 1),
        serialize: (v) => v,
        deserialize: (s) => s,
      );

      // Put via storage directly (simulating a previous session)
      final expiresAt =
          DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch;
      await storage.setString(
        'wtc:a',
        jsonEncode({'value': 'alpha', 'expiresAt': expiresAt}),
      );

      expect(await cache.get('a'), 'alpha');
    });

    test('remove clears both memory and storage', () async {
      final cache = WriteThroughCache<String>(
        storage: storage,
        maxSize: 10,
        defaultTtl: const Duration(hours: 1),
        serialize: (v) => v,
        deserialize: (s) => s,
      );

      await cache.put('a', 'alpha');
      await cache.remove('a');

      expect(await cache.get('a'), isNull);
      expect(await storage.getString('wtc:a'), isNull);
    });

    test('clear removes all entries with prefix', () async {
      final cache = WriteThroughCache<String>(
        storage: storage,
        maxSize: 10,
        defaultTtl: const Duration(hours: 1),
        serialize: (v) => v,
        deserialize: (s) => s,
      );

      await cache.put('a', 'alpha');
      await cache.put('b', 'beta');
      await storage.setString('other', 'unrelated');

      await cache.clear();

      expect(cache.size, 0);
      expect(await storage.getString('wtc:a'), isNull);
      expect(await storage.getString('wtc:b'), isNull);
      expect(await storage.getString('other'), 'unrelated');
    });

    test('custom storage prefix works', () async {
      final cache = WriteThroughCache<String>(
        storage: storage,
        maxSize: 10,
        defaultTtl: const Duration(hours: 1),
        serialize: (v) => v,
        deserialize: (s) => s,
        storagePrefix: 'custom:',
      );

      await cache.put('a', 'alpha');
      expect(await storage.getString('custom:a'), isNotNull);
    });

    test('expired storage entries return null', () async {
      final cache = WriteThroughCache<String>(
        storage: storage,
        maxSize: 10,
        defaultTtl: const Duration(hours: 1),
        serialize: (v) => v,
        deserialize: (s) => s,
      );

      // Put an expired entry directly in storage
      final expiredAt =
          DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch;
      await storage.setString(
        'wtc:a',
        jsonEncode({'value': 'alpha', 'expiresAt': expiredAt}),
      );

      expect(await cache.get('a'), isNull);
    });
  });

  group('VeloxMultiLevelCache', () {
    late VeloxStorage l2Storage;

    setUp(() {
      l2Storage = VeloxStorage(adapter: MemoryStorageAdapter());
    });

    tearDown(() async {
      await l2Storage.dispose();
    });

    test('put stores in L1 and L2', () async {
      final cache = VeloxMultiLevelCache<String>(
        l1MaxSize: 10,
        l1Ttl: const Duration(minutes: 5),
        l2Storage: l2Storage,
        l2Ttl: const Duration(hours: 1),
        serialize: (v) => v,
        deserialize: (s) => s,
      );

      await cache.put('a', 'alpha');
      expect(cache.l1Size, 1);
      expect(await l2Storage.getString('mlc:a'), isNotNull);
    });

    test('get hits L1 first', () async {
      final cache = VeloxMultiLevelCache<String>(
        l1MaxSize: 10,
        l1Ttl: const Duration(minutes: 5),
        l2Storage: l2Storage,
        l2Ttl: const Duration(hours: 1),
        serialize: (v) => v,
        deserialize: (s) => s,
      );

      await cache.put('a', 'alpha');
      final value = await cache.get('a');
      expect(value, 'alpha');
      expect(cache.l1Stats.hits, 1);
    });

    test('cascades to L2 on L1 miss and promotes back to L1', () async {
      final cache = VeloxMultiLevelCache<String>(
        l1MaxSize: 10,
        l1Ttl: const Duration(minutes: 5),
        l2Storage: l2Storage,
        l2Ttl: const Duration(hours: 1),
        serialize: (v) => v,
        deserialize: (s) => s,
      );

      await cache.put('a', 'alpha');
      cache.clearL1(); // Clear L1 to force L2 fallback

      expect(cache.l1Size, 0);

      final value = await cache.get('a');
      expect(value, 'alpha');
      expect(cache.l1Stats.misses, 1); // L1 miss
      expect(cache.l2Stats.hits, 1); // L2 hit
      expect(cache.l1Size, 1); // Promoted back to L1
    });

    test('returns null when key not in L1 or L2', () async {
      final cache = VeloxMultiLevelCache<String>(
        l1MaxSize: 10,
        l1Ttl: const Duration(minutes: 5),
        l2Storage: l2Storage,
        l2Ttl: const Duration(hours: 1),
        serialize: (v) => v,
        deserialize: (s) => s,
      );

      expect(await cache.get('missing'), isNull);
      expect(cache.l1Stats.misses, 1);
      expect(cache.l2Stats.misses, 1);
    });

    test('remove clears from L1 and L2', () async {
      final cache = VeloxMultiLevelCache<String>(
        l1MaxSize: 10,
        l1Ttl: const Duration(minutes: 5),
        l2Storage: l2Storage,
        l2Ttl: const Duration(hours: 1),
        serialize: (v) => v,
        deserialize: (s) => s,
      );

      await cache.put('a', 'alpha');
      await cache.remove('a');

      expect(cache.l1Size, 0);
      expect(await cache.get('a'), isNull);
    });

    test('containsKey checks both levels', () async {
      final cache = VeloxMultiLevelCache<String>(
        l1MaxSize: 10,
        l1Ttl: const Duration(minutes: 5),
        l2Storage: l2Storage,
        l2Ttl: const Duration(hours: 1),
        serialize: (v) => v,
        deserialize: (s) => s,
      );

      await cache.put('a', 'alpha');
      expect(await cache.containsKey('a'), isTrue);

      cache.clearL1();
      // Still in L2
      expect(await cache.containsKey('a'), isTrue);
      expect(await cache.containsKey('missing'), isFalse);
    });

    test('clear removes from both levels', () async {
      final cache = VeloxMultiLevelCache<String>(
        l1MaxSize: 10,
        l1Ttl: const Duration(minutes: 5),
        l2Storage: l2Storage,
        l2Ttl: const Duration(hours: 1),
        serialize: (v) => v,
        deserialize: (s) => s,
      );

      await cache.put('a', 'alpha');
      await cache.put('b', 'beta');
      await cache.clear();

      expect(cache.l1Size, 0);
      expect(await cache.get('a'), isNull);
      expect(await cache.get('b'), isNull);
    });

    test('L1 evicts LRU when full', () async {
      final cache = VeloxMultiLevelCache<String>(
        l1MaxSize: 2,
        l1Ttl: const Duration(minutes: 5),
        l2Storage: l2Storage,
        l2Ttl: const Duration(hours: 1),
        serialize: (v) => v,
        deserialize: (s) => s,
      );

      await cache.put('a', 'alpha');
      await cache.put('b', 'beta');
      await cache.get('a'); // Touch 'a'
      await cache.put('c', 'gamma'); // Evicts 'b' from L1

      expect(cache.l1Size, 2);
      expect(cache.l1Stats.evictions, 1);
    });

    test('tracks L1 and L2 stats independently', () async {
      final cache = VeloxMultiLevelCache<String>(
        l1MaxSize: 10,
        l1Ttl: const Duration(minutes: 5),
        l2Storage: l2Storage,
        l2Ttl: const Duration(hours: 1),
        serialize: (v) => v,
        deserialize: (s) => s,
      );

      await cache.put('a', 'alpha');
      expect(cache.l1Stats.writes, 1);
      expect(cache.l2Stats.writes, 1);

      await cache.get('a'); // L1 hit
      expect(cache.l1Stats.hits, 1);
      expect(cache.l2Stats.hits, 0); // L2 not consulted
    });
  });

  group('CacheEvent types', () {
    test('CacheEvent.hit has correct type', () {
      const event = CacheEvent.hit('key', 'value');
      expect(event.type, CacheEventType.hit);
      expect(event.key, 'key');
      expect(event.value, 'value');
    });

    test('CacheEvent.miss has correct type', () {
      const event = CacheEvent<String>.miss('key');
      expect(event.type, CacheEventType.miss);
      expect(event.key, 'key');
      expect(event.value, isNull);
    });

    test('CacheEvent.stale has correct type', () {
      const event = CacheEvent.stale('key', 'old_value');
      expect(event.type, CacheEventType.stale);
      expect(event.key, 'key');
      expect(event.value, 'old_value');
    });

    test('CacheEvent.cleared has null key and value', () {
      const event = CacheEvent<String>.cleared();
      expect(event.type, CacheEventType.cleared);
      expect(event.key, isNull);
      expect(event.value, isNull);
    });

    test('CacheEvent toString works', () {
      const event = CacheEvent.put('key', 'value');
      expect(event.toString(), contains('put'));
      expect(event.toString(), contains('key'));
    });
  });
}

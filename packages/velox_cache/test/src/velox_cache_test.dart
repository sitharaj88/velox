// ignore_for_file: cascade_invocations
import 'package:test/test.dart';
import 'package:velox_cache/velox_cache.dart';

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
      expect(events, hasLength(3));
      expect(events[0].type, CacheEventType.put);
      expect(events[1].type, CacheEventType.removed);
      expect(events[2].type, CacheEventType.cleared);

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

    test('touch updates lastAccessedAt', () {
      final entry = CacheEntry(
        key: 'a',
        value: 'alpha',
        createdAt: DateTime(2020),
      );
      final before = entry.lastAccessedAt;
      entry.touch();
      expect(entry.lastAccessedAt.isAfter(before), isTrue);
    });
  });
}

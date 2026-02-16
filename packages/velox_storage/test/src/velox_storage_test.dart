import 'dart:async';

import 'package:test/test.dart';
import 'package:velox_core/velox_core.dart';
import 'package:velox_storage/velox_storage.dart';

/// A test observer that records all operations.
class TestObserver extends StorageObserver {
  final List<String> events = [];

  @override
  void onRead(String key, {String? value}) {
    events.add('read:$key:$value');
  }

  @override
  void onWrite(String key, String value) {
    events.add('write:$key:$value');
  }

  @override
  void onRemove(String key) {
    events.add('remove:$key');
  }

  @override
  void onClear() {
    events.add('clear');
  }

  @override
  void onBatchStart() {
    events.add('batch_start');
  }

  @override
  void onBatchComplete({
    required int operationCount,
    required bool success,
  }) {
    events.add('batch_complete:$operationCount:$success');
  }
}

/// A storage adapter that throws on a specific key, for testing rollback.
class FailingStorageAdapter implements StorageAdapter {
  FailingStorageAdapter({required this.failOnKey});

  final String failOnKey;
  final Map<String, String> _store = {};

  @override
  Future<String?> read(String key) async => _store[key];

  @override
  Future<void> write(String key, String value) async {
    if (key == failOnKey) {
      throw Exception('Simulated write failure on $key');
    }
    _store[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _store.remove(key);
  }

  @override
  Future<List<String>> keys() async => _store.keys.toList();

  @override
  Future<void> clear() async => _store.clear();

  @override
  Future<bool> containsKey(String key) async => _store.containsKey(key);

  @override
  Future<void> dispose() async => _store.clear();
}

/// A simple test migration.
class TestMigrationV1 extends StorageMigration {
  @override
  int get version => 1;

  @override
  String get description => 'Add greeting key';

  @override
  Future<void> up(StorageAdapter adapter) async {
    await adapter.write('greeting', 'hello');
  }

  @override
  Future<void> down(StorageAdapter adapter) async {
    await adapter.remove('greeting');
  }
}

class TestMigrationV2 extends StorageMigration {
  @override
  int get version => 2;

  @override
  String get description => 'Rename greeting to welcome';

  @override
  Future<void> up(StorageAdapter adapter) async {
    final value = await adapter.read('greeting');
    if (value != null) {
      await adapter.write('welcome', value);
      await adapter.remove('greeting');
    }
  }

  @override
  Future<void> down(StorageAdapter adapter) async {
    final value = await adapter.read('welcome');
    if (value != null) {
      await adapter.write('greeting', value);
      await adapter.remove('welcome');
    }
  }
}

void main() {
  late MemoryStorageAdapter adapter;
  late VeloxStorage storage;

  setUp(() {
    adapter = MemoryStorageAdapter();
    storage = VeloxStorage(adapter: adapter);
  });

  tearDown(() async {
    await storage.dispose();
  });

  group('VeloxStorage', () {
    group('String', () {
      test('setString and getString', () async {
        await storage.setString('name', 'John');
        expect(await storage.getString('name'), 'John');
      });

      test('getString returns null for missing key', () async {
        expect(await storage.getString('missing'), isNull);
      });
    });

    group('Int', () {
      test('setInt and getInt', () async {
        await storage.setInt('age', 25);
        expect(await storage.getInt('age'), 25);
      });

      test('getInt returns null for missing key', () async {
        expect(await storage.getInt('missing'), isNull);
      });

      test('getInt returns null for non-integer value', () async {
        await storage.setString('bad', 'not_a_number');
        expect(await storage.getInt('bad'), isNull);
      });
    });

    group('Double', () {
      test('setDouble and getDouble', () async {
        await storage.setDouble('price', 9.99);
        expect(await storage.getDouble('price'), 9.99);
      });
    });

    group('Bool', () {
      test('setBool and getBool', () async {
        await storage.setBool('active', value: true);
        expect(await storage.getBool('active'), isTrue);

        await storage.setBool('active', value: false);
        expect(await storage.getBool('active'), isFalse);
      });

      test('getBool returns null for missing key', () async {
        expect(await storage.getBool('missing'), isNull);
      });
    });

    group('JSON', () {
      test('setJson and getJson', () async {
        await storage.setJson('user', {'name': 'John', 'age': 25});
        final json = await storage.getJson('user');

        expect(json, isNotNull);
        expect(json!['name'], 'John');
        expect(json['age'], 25);
      });

      test('getJson returns null for invalid JSON', () async {
        await storage.setString('bad', 'not json');
        expect(await storage.getJson('bad'), isNull);
      });
    });

    group('StringList', () {
      test('setStringList and getStringList', () async {
        await storage.setStringList('tags', ['a', 'b', 'c']);
        expect(await storage.getStringList('tags'), ['a', 'b', 'c']);
      });
    });

    group('General', () {
      test('remove deletes a key', () async {
        await storage.setString('key', 'value');
        await storage.remove('key');
        expect(await storage.getString('key'), isNull);
      });

      test('containsKey', () async {
        expect(await storage.containsKey('key'), isFalse);
        await storage.setString('key', 'value');
        expect(await storage.containsKey('key'), isTrue);
      });

      test('keys returns all keys', () async {
        await storage.setString('a', '1');
        await storage.setString('b', '2');
        final allKeys = await storage.keys();
        expect(allKeys, containsAll(['a', 'b']));
      });

      test('clear removes all values', () async {
        await storage.setString('a', '1');
        await storage.setString('b', '2');
        await storage.clear();
        expect(await storage.keys(), isEmpty);
      });

      test('getOrFail returns Success for existing key', () async {
        await storage.setString('key', 'value');
        final result = await storage.getOrFail('key');
        expect(result.isSuccess, isTrue);
        expect(result.valueOrNull, 'value');
      });

      test('getOrFail returns Failure for missing key', () async {
        final result = await storage.getOrFail('missing');
        expect(result.isFailure, isTrue);
      });
    });

    group('onChange', () {
      test('emits on write', () async {
        final entries = <StorageEntry>[];
        final sub = storage.onChange.listen(entries.add);

        await storage.setString('name', 'John');

        await Future<void>.delayed(Duration.zero);
        expect(entries, hasLength(1));
        expect(entries.first.key, 'name');
        expect(entries.first.value, 'John');

        await sub.cancel();
      });

      test('emits on remove', () async {
        await storage.setString('name', 'John');

        final entries = <StorageEntry>[];
        final sub = storage.onChange.listen(entries.add);

        await storage.remove('name');

        await Future<void>.delayed(Duration.zero);
        expect(entries, hasLength(1));
        expect(entries.first.isRemoval, isTrue);

        await sub.cancel();
      });
    });
  });

  group('MemoryStorageAdapter', () {
    test('read/write/remove', () async {
      await adapter.write('key', 'value');
      expect(await adapter.read('key'), 'value');

      await adapter.remove('key');
      expect(await adapter.read('key'), isNull);
    });

    test('clear empties storage', () async {
      await adapter.write('a', '1');
      await adapter.write('b', '2');
      await adapter.clear();
      expect(await adapter.keys(), isEmpty);
    });
  });

  // =====================================================================
  // NEW FEATURE TESTS
  // =====================================================================

  group('Batch Operations', () {
    test('batch writes multiple keys atomically', () async {
      await storage.batch([
        const BatchOperation.write(key: 'a', value: '1'),
        const BatchOperation.write(key: 'b', value: '2'),
        const BatchOperation.write(key: 'c', value: '3'),
      ]);

      expect(await storage.getString('a'), '1');
      expect(await storage.getString('b'), '2');
      expect(await storage.getString('c'), '3');
    });

    test('batch supports mixed write and remove', () async {
      await storage.setString('old', 'value');

      await storage.batch([
        const BatchOperation.write(key: 'new', value: 'fresh'),
        const BatchOperation.remove(key: 'old'),
      ]);

      expect(await storage.getString('new'), 'fresh');
      expect(await storage.getString('old'), isNull);
    });

    test('batch rolls back on failure', () async {
      final failAdapter = FailingStorageAdapter(failOnKey: 'fail_key');
      final failStorage = VeloxStorage(adapter: failAdapter);

      // Pre-populate with a value
      await failAdapter.write('existing', 'original');

      await expectLater(
        failStorage.batch([
          const BatchOperation.write(key: 'existing', value: 'changed'),
          const BatchOperation.write(key: 'fail_key', value: 'boom'),
        ]),
        throwsA(isA<VeloxStorageException>()),
      );

      // existing should be rolled back to original
      expect(await failAdapter.read('existing'), 'original');

      await failStorage.dispose();
    });

    test('batch emits change events for each operation', () async {
      final entries = <StorageEntry>[];
      final sub = storage.onChange.listen(entries.add);

      await storage.batch([
        const BatchOperation.write(key: 'x', value: '1'),
        const BatchOperation.write(key: 'y', value: '2'),
      ]);

      await Future<void>.delayed(Duration.zero);
      expect(entries, hasLength(2));
      expect(entries[0].key, 'x');
      expect(entries[1].key, 'y');

      await sub.cancel();
    });
  });

  group('TypedStorageAdapter', () {
    late TypedStorageAdapter<Map<String, dynamic>> typedAdapter;

    setUp(() {
      typedAdapter = TypedStorageAdapter<Map<String, dynamic>>(
        adapter: adapter,
        toJson: (value) => value,
        fromJson: (json) => json,
      );
    });

    test('writeTyped and readTyped', () async {
      await typedAdapter.writeTyped('user', {'name': 'John', 'age': 30});
      final result = await typedAdapter.readTyped('user');

      expect(result, isNotNull);
      expect(result!['name'], 'John');
      expect(result['age'], 30);
    });

    test('readTyped returns null for missing key', () async {
      expect(await typedAdapter.readTyped('missing'), isNull);
    });

    test('readTyped returns null for invalid data', () async {
      await adapter.write('bad', 'not json');
      expect(await typedAdapter.readTyped('bad'), isNull);
    });

    test('readTypedOrFail returns Success', () async {
      await typedAdapter.writeTyped('key', {'data': 'test'});
      final result = await typedAdapter.readTypedOrFail('key');
      expect(result.isSuccess, isTrue);
    });

    test('readTypedOrFail returns Failure for missing key', () async {
      final result = await typedAdapter.readTypedOrFail('missing');
      expect(result.isFailure, isTrue);
    });

    test('writeAll and readAll', () async {
      await typedAdapter.writeAll({
        'a': {'id': 1},
        'b': {'id': 2},
      });

      final results = await typedAdapter.readAll(['a', 'b', 'c']);
      expect(results, hasLength(2));
      expect(results['a']!['id'], 1);
      expect(results['b']!['id'], 2);
    });

    test('remove and containsKey', () async {
      await typedAdapter.writeTyped('key', {'data': 'test'});
      expect(await typedAdapter.containsKey('key'), isTrue);

      await typedAdapter.remove('key');
      expect(await typedAdapter.containsKey('key'), isFalse);
    });
  });

  group('StorageMigration', () {
    test('runs migrations in order', () async {
      final runner = StorageMigrationRunner(
        adapter: adapter,
        migrations: [TestMigrationV1(), TestMigrationV2()],
      );

      final count = await runner.migrate();
      expect(count, 2);
      expect(await runner.currentVersion(), 2);

      // V1 wrote 'greeting', V2 renamed to 'welcome'
      expect(await adapter.read('greeting'), isNull);
      expect(await adapter.read('welcome'), 'hello');
    });

    test('skips already applied migrations', () async {
      final runner = StorageMigrationRunner(
        adapter: adapter,
        migrations: [TestMigrationV1(), TestMigrationV2()],
      );

      // Run all
      await runner.migrate();

      // Run again, should be a no-op
      final count = await runner.migrate();
      expect(count, 0);
    });

    test('migrate to specific version', () async {
      final runner = StorageMigrationRunner(
        adapter: adapter,
        migrations: [TestMigrationV1(), TestMigrationV2()],
      );

      final count = await runner.migrate(targetVersion: 1);
      expect(count, 1);
      expect(await runner.currentVersion(), 1);
      expect(await adapter.read('greeting'), 'hello');
    });

    test('rollback migrations (down)', () async {
      final runner = StorageMigrationRunner(
        adapter: adapter,
        migrations: [TestMigrationV1(), TestMigrationV2()],
      );

      // Migrate up to V2
      await runner.migrate();
      expect(await adapter.read('welcome'), 'hello');

      // Rollback to V1
      final count = await runner.migrate(targetVersion: 1);
      expect(count, 1);
      expect(await runner.currentVersion(), 1);
      expect(await adapter.read('greeting'), 'hello');
      expect(await adapter.read('welcome'), isNull);
    });

    test('pendingMigrations returns unapplied migrations', () async {
      final runner = StorageMigrationRunner(
        adapter: adapter,
        migrations: [TestMigrationV1(), TestMigrationV2()],
      );

      var pending = await runner.pendingMigrations();
      expect(pending, hasLength(2));

      await runner.migrate(targetVersion: 1);
      pending = await runner.pendingMigrations();
      expect(pending, hasLength(1));
      expect(pending.first.version, 2);
    });
  });

  group('NamespacedStorageAdapter', () {
    late NamespacedStorageAdapter nsAdapter;

    setUp(() {
      nsAdapter = NamespacedStorageAdapter(
        adapter: adapter,
        namespace: 'user',
      );
    });

    test('prefixes keys on write and read', () async {
      await nsAdapter.write('name', 'John');

      // Underlying adapter has prefixed key
      expect(await adapter.read('user.name'), 'John');

      // Namespaced adapter reads correctly
      expect(await nsAdapter.read('name'), 'John');
    });

    test('remove removes prefixed key', () async {
      await nsAdapter.write('name', 'John');
      await nsAdapter.remove('name');
      expect(await nsAdapter.read('name'), isNull);
      expect(await adapter.read('user.name'), isNull);
    });

    test('keys returns only namespace keys without prefix', () async {
      await adapter.write('user.name', 'John');
      await adapter.write('user.age', '30');
      await adapter.write('system.version', '1');

      final keys = await nsAdapter.keys();
      expect(keys, containsAll(['name', 'age']));
      expect(keys, isNot(contains('system.version')));
    });

    test('clear removes only namespace keys', () async {
      await adapter.write('user.name', 'John');
      await adapter.write('system.version', '1');

      await nsAdapter.clear();

      expect(await adapter.read('user.name'), isNull);
      expect(await adapter.read('system.version'), '1');
    });

    test('containsKey checks prefixed key', () async {
      await nsAdapter.write('name', 'John');
      expect(await nsAdapter.containsKey('name'), isTrue);
      expect(await nsAdapter.containsKey('missing'), isFalse);
    });

    test('custom separator', () async {
      final customNs = NamespacedStorageAdapter(
        adapter: adapter,
        namespace: 'app',
        separator: '::',
      );

      await customNs.write('key', 'value');
      expect(await adapter.read('app::key'), 'value');
    });
  });

  group('TtlStorageAdapter', () {
    late TtlStorageAdapter ttlAdapter;

    setUp(() {
      ttlAdapter = TtlStorageAdapter(adapter: adapter);
    });

    test('write and read non-expiring entry', () async {
      await ttlAdapter.write('key', 'value');
      expect(await ttlAdapter.read('key'), 'value');
    });

    test('writeWithTtl stores value that can be read before expiry', () async {
      await ttlAdapter.writeWithTtl(
        'session',
        'token123',
        ttl: const Duration(hours: 1),
      );

      expect(await ttlAdapter.read('session'), 'token123');
    });

    test('expired entries return null', () async {
      // Write with a TTL that already expired (negative duration trick)
      await ttlAdapter.writeWithTtl(
        'expired',
        'old_value',
        ttl: const Duration(milliseconds: -1),
      );

      expect(await ttlAdapter.read('expired'), isNull);
    });

    test('expired entries are removed from storage on read', () async {
      await ttlAdapter.writeWithTtl(
        'temp',
        'data',
        ttl: const Duration(milliseconds: -1),
      );

      await ttlAdapter.read('temp');
      expect(await adapter.containsKey('temp'), isFalse);
    });

    test('containsKey returns false for expired entries', () async {
      await ttlAdapter.writeWithTtl(
        'expired',
        'data',
        ttl: const Duration(milliseconds: -1),
      );

      expect(await ttlAdapter.containsKey('expired'), isFalse);
    });

    test('keys excludes expired entries', () async {
      await ttlAdapter.writeWithTtl(
        'valid',
        'data',
        ttl: const Duration(hours: 1),
      );
      await ttlAdapter.writeWithTtl(
        'expired',
        'old',
        ttl: const Duration(milliseconds: -1),
      );

      final keys = await ttlAdapter.keys();
      expect(keys, contains('valid'));
      expect(keys, isNot(contains('expired')));
    });

    test('cleanupExpired removes expired entries', () async {
      await ttlAdapter.writeWithTtl(
        'keep',
        'value',
        ttl: const Duration(hours: 1),
      );
      await ttlAdapter.writeWithTtl(
        'expired1',
        'old',
        ttl: const Duration(milliseconds: -1),
      );
      await ttlAdapter.writeWithTtl(
        'expired2',
        'old',
        ttl: const Duration(milliseconds: -1),
      );

      final removed = await ttlAdapter.cleanupExpired();
      expect(removed, 2);
      expect(await adapter.containsKey('keep'), isTrue);
    });

    test('defaultTtl is applied to all writes', () async {
      final ttlWithDefault = TtlStorageAdapter(
        adapter: MemoryStorageAdapter(),
        defaultTtl: const Duration(milliseconds: -1),
      );

      await ttlWithDefault.write('key', 'value');
      // With negative default TTL, value is already expired
      expect(await ttlWithDefault.read('key'), isNull);

      await ttlWithDefault.dispose();
    });
  });

  group('EncryptedStorageAdapter', () {
    late EncryptedStorageAdapter encAdapter;

    setUp(() {
      encAdapter = EncryptedStorageAdapter(
        adapter: adapter,
        encryptionKey: 'test-secret-key',
      );
    });

    test('write encrypts and read decrypts', () async {
      await encAdapter.write('token', 'my-secret-token');

      // Underlying value is encrypted (not the original)
      final raw = await adapter.read('token');
      expect(raw, isNot('my-secret-token'));

      // Encrypted adapter returns original value
      expect(await encAdapter.read('token'), 'my-secret-token');
    });

    test('read returns null for missing key', () async {
      expect(await encAdapter.read('missing'), isNull);
    });

    test('encrypt and decrypt are symmetric', () async {
      const original = r'Hello, World! Special chars: @#$%^&*()';
      final encrypted = encAdapter.encrypt(original);
      final decrypted = encAdapter.decrypt(encrypted);
      expect(decrypted, original);
    });

    test('different keys produce different ciphertext', () async {
      final adapter2 = EncryptedStorageAdapter(
        adapter: MemoryStorageAdapter(),
        encryptionKey: 'different-key',
      );

      const plaintext = 'same-value';
      final cipher1 = encAdapter.encrypt(plaintext);
      final cipher2 = adapter2.encrypt(plaintext);

      expect(cipher1, isNot(cipher2));

      await adapter2.dispose();
    });

    test('keys, containsKey, remove, clear work through encryption', () async {
      await encAdapter.write('a', '1');
      await encAdapter.write('b', '2');

      expect(await encAdapter.containsKey('a'), isTrue);
      expect(await encAdapter.keys(), containsAll(['a', 'b']));

      await encAdapter.remove('a');
      expect(await encAdapter.containsKey('a'), isFalse);

      await encAdapter.clear();
      expect(await encAdapter.keys(), isEmpty);
    });
  });

  group('LazyStorageAdapter', () {
    test('defers initialization until first access', () async {
      var initialized = false;

      final lazy = LazyStorageAdapter(
        factory: () async {
          initialized = true;
          return MemoryStorageAdapter();
        },
      );

      expect(initialized, isFalse);
      expect(lazy.isInitialized, isFalse);

      await lazy.write('key', 'value');

      expect(initialized, isTrue);
      expect(lazy.isInitialized, isTrue);
      expect(await lazy.read('key'), 'value');

      await lazy.dispose();
    });

    test('initializes only once on concurrent access', () async {
      var initCount = 0;

      final lazy = LazyStorageAdapter(
        factory: () async {
          initCount++;
          return MemoryStorageAdapter();
        },
      );

      // Multiple concurrent operations
      await Future.wait([
        lazy.write('a', '1'),
        lazy.write('b', '2'),
        lazy.read('a'),
      ]);

      expect(initCount, 1);

      await lazy.dispose();
    });

    test('all StorageAdapter methods work', () async {
      final lazy = LazyStorageAdapter(
        factory: () async => MemoryStorageAdapter(),
      );

      await lazy.write('a', '1');
      await lazy.write('b', '2');

      expect(await lazy.read('a'), '1');
      expect(await lazy.containsKey('a'), isTrue);
      expect(await lazy.keys(), containsAll(['a', 'b']));

      await lazy.remove('a');
      expect(await lazy.containsKey('a'), isFalse);

      await lazy.clear();
      expect(await lazy.keys(), isEmpty);

      await lazy.dispose();
    });

    test('dispose clears initialization state', () async {
      var initCount = 0;

      final lazy = LazyStorageAdapter(
        factory: () async {
          initCount++;
          return MemoryStorageAdapter();
        },
      );

      await lazy.write('key', 'value');
      expect(initCount, 1);

      await lazy.dispose();
      expect(lazy.isInitialized, isFalse);

      // Re-access triggers re-initialization
      await lazy.write('key2', 'value2');
      expect(initCount, 2);

      await lazy.dispose();
    });
  });

  group('StorageObserver', () {
    late TestObserver observer;

    setUp(() {
      observer = TestObserver();
      storage.addObserver(observer);
    });

    test('observes read operations', () async {
      await storage.setString('key', 'value');
      observer.events.clear();

      await storage.getString('key');
      expect(observer.events, contains('read:key:value'));
    });

    test('observes write operations', () async {
      await storage.setString('key', 'value');
      expect(observer.events, contains('write:key:value'));
    });

    test('observes remove operations', () async {
      await storage.setString('key', 'value');
      await storage.remove('key');
      expect(observer.events, contains('remove:key'));
    });

    test('observes clear operations', () async {
      await storage.clear();
      expect(observer.events, contains('clear'));
    });

    test('observes batch operations', () async {
      await storage.batch([
        const BatchOperation.write(key: 'a', value: '1'),
      ]);

      expect(observer.events, contains('batch_start'));
      expect(observer.events, contains('batch_complete:1:true'));
    });

    test('removeObserver stops notifications', () async {
      storage.removeObserver(observer);
      await storage.setString('key', 'value');
      expect(observer.events, isEmpty);
    });

    test('NoOpStorageObserver does nothing', () {
      // Just verify it can be instantiated and called without error
      NoOpStorageObserver()
        ..onRead('key')
        ..onWrite('key', 'value')
        ..onRemove('key')
        ..onClear()
        ..onBatchStart()
        ..onBatchComplete(operationCount: 1, success: true);
    });
  });

  group('Import/Export', () {
    test('exportAll returns all entries', () async {
      await storage.setString('a', '1');
      await storage.setString('b', '2');

      final exported = await storage.exportAll();
      expect(exported, {'a': '1', 'b': '2'});
    });

    test('importAll loads entries', () async {
      await storage.importAll({'x': '10', 'y': '20'});

      expect(await storage.getString('x'), '10');
      expect(await storage.getString('y'), '20');
    });

    test('export then import round-trips correctly', () async {
      await storage.setString('name', 'John');
      await storage.setInt('age', 30);

      final exported = await storage.exportAll();

      // Clear and re-import
      await storage.clear();
      expect(await storage.keys(), isEmpty);

      await storage.importAll(exported);
      expect(await storage.getString('name'), 'John');
      expect(await storage.getInt('age'), 30);
    });

    test('importAll emits change events', () async {
      final entries = <StorageEntry>[];
      final sub = storage.onChange.listen(entries.add);

      await storage.importAll({'a': '1', 'b': '2'});

      await Future<void>.delayed(Duration.zero);
      expect(entries, hasLength(2));

      await sub.cancel();
    });
  });

  group('StorageStatistics', () {
    test('tracks read hits and misses', () async {
      await storage.setString('key', 'value');

      await storage.getString('key'); // hit
      await storage.getString('missing'); // miss

      expect(storage.statistics.readCount, 2);
      expect(storage.statistics.hitCount, 1);
      expect(storage.statistics.missCount, 1);
      expect(storage.statistics.hitRate, 0.5);
      expect(storage.statistics.missRate, 0.5);
    });

    test('tracks write count', () async {
      await storage.setString('a', '1');
      await storage.setString('b', '2');

      expect(storage.statistics.writeCount, 2);
    });

    test('tracks remove count', () async {
      await storage.setString('key', 'value');
      await storage.remove('key');

      expect(storage.statistics.removeCount, 1);
    });

    test('tracks clear count', () async {
      await storage.clear();
      expect(storage.statistics.clearCount, 1);
    });

    test('totalOperations sums all operations', () async {
      await storage.setString('a', '1'); // write
      await storage.getString('a'); // read
      await storage.remove('a'); // remove
      await storage.clear(); // clear

      expect(storage.statistics.totalOperations, 4);
    });

    test('hitRate returns 0 when no reads', () {
      expect(storage.statistics.hitRate, 0);
      expect(storage.statistics.missRate, 0);
    });

    test('reset clears all counters', () async {
      await storage.setString('a', '1');
      await storage.getString('a');

      storage.statistics.reset();

      expect(storage.statistics.readCount, 0);
      expect(storage.statistics.writeCount, 0);
      expect(storage.statistics.totalOperations, 0);
    });

    test('toString provides readable summary', () {
      final stats = StorageStatistics();
      expect(stats.toString(), contains('reads:'));
      expect(stats.toString(), contains('writes:'));
    });
  });

  group('TtlEntry', () {
    test('non-expiring entry is never expired', () {
      const entry = TtlEntry(value: 'test');
      expect(entry.isExpired, isFalse);
    });

    test('future expiry is not expired', () {
      final entry = TtlEntry(
        value: 'test',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(entry.isExpired, isFalse);
    });

    test('past expiry is expired', () {
      final entry = TtlEntry(
        value: 'test',
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(entry.isExpired, isTrue);
    });

    test('toJson and fromJson round-trip', () {
      final now = DateTime.now();
      final entry = TtlEntry(value: 'hello', expiresAt: now);
      final json = entry.toJson();
      final restored = TtlEntry.fromJson(json);

      expect(restored.value, 'hello');
      expect(
        restored.expiresAt!.millisecondsSinceEpoch,
        now.millisecondsSinceEpoch,
      );
    });

    test('toJson without expiry', () {
      const entry = TtlEntry(value: 'hello');
      final json = entry.toJson();
      final restored = TtlEntry.fromJson(json);

      expect(restored.value, 'hello');
      expect(restored.expiresAt, isNull);
    });

    test('toString provides readable output', () {
      const entry = TtlEntry(value: 'test');
      expect(entry.toString(), contains('test'));
    });
  });

  group('BatchOperation', () {
    test('write factory creates BatchWrite', () {
      const op = BatchOperation.write(key: 'k', value: 'v');
      expect(op, isA<BatchWrite>());
      expect((op as BatchWrite).key, 'k');
      expect(op.value, 'v');
    });

    test('remove factory creates BatchRemove', () {
      const op = BatchOperation.remove(key: 'k');
      expect(op, isA<BatchRemove>());
      expect((op as BatchRemove).key, 'k');
    });

    test('toString provides readable output', () {
      const write = BatchOperation.write(key: 'k', value: 'v');
      const remove = BatchOperation.remove(key: 'k');
      expect(write.toString(), contains('k'));
      expect(remove.toString(), contains('k'));
    });
  });

  group('StorageEntry', () {
    test('isRemoval is true when value is null', () {
      const entry = StorageEntry(key: 'key');
      expect(entry.isRemoval, isTrue);
    });

    test('isRemoval is false when value is present', () {
      const entry = StorageEntry(key: 'key', value: 'value');
      expect(entry.isRemoval, isFalse);
    });

    test('toString provides readable output', () {
      const entry = StorageEntry(key: 'key', value: 'value');
      expect(entry.toString(), contains('key'));
    });
  });
}

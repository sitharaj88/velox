import 'dart:async';

import 'package:test/test.dart';
import 'package:velox_storage/velox_storage.dart';

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
}

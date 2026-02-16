import 'package:test/test.dart';
import 'package:velox_core/velox_core.dart';

void main() {
  group('VeloxIterableExtension', () {
    test('firstWhereOrNull finds element', () {
      expect([1, 2, 3].firstWhereOrNull((e) => e == 2), 2);
    });

    test('firstWhereOrNull returns null when not found', () {
      expect([1, 2, 3].firstWhereOrNull((e) => e == 4), isNull);
    });

    test('lastWhereOrNull finds last matching element', () {
      expect([1, 2, 3, 2, 1].lastWhereOrNull((e) => e == 2), 2);
    });

    test('lastWhereOrNull returns null when not found', () {
      expect([1, 2, 3].lastWhereOrNull((e) => e == 4), isNull);
    });

    group('groupBy', () {
      test('groups elements correctly', () {
        final result = ['apple', 'avocado', 'banana', 'blueberry'].groupBy(
          (s) => s[0],
        );

        expect(result['a'], ['apple', 'avocado']);
        expect(result['b'], ['banana', 'blueberry']);
      });
    });

    group('distinctBy', () {
      test('removes duplicates by key', () {
        final result = [
          (id: 1, name: 'Alice'),
          (id: 2, name: 'Bob'),
          (id: 1, name: 'Alice2'),
        ].distinctBy((e) => e.id).toList();

        expect(result, hasLength(2));
        expect(result[0].name, 'Alice');
        expect(result[1].name, 'Bob');
      });
    });

    group('chunked', () {
      test('splits into correct chunks', () {
        expect([1, 2, 3, 4, 5].chunked(2).toList(), [
          [1, 2],
          [3, 4],
          [5],
        ]);
      });

      test('throws on non-positive size', () {
        expect(() => [1, 2].chunked(0), throwsArgumentError);
      });
    });

    group('sortedBy', () {
      test('sorts by key ascending', () {
        final result = ['banana', 'apple', 'cherry'].sortedBy(
          (s) => s,
        );
        expect(result, ['apple', 'banana', 'cherry']);
      });
    });

    group('sortedByDescending', () {
      test('sorts by key descending', () {
        final result = [1, 3, 2].sortedByDescending((n) => n);
        expect(result, [3, 2, 1]);
      });
    });

    test('separated adds separator between elements', () {
      expect([1, 2, 3].separated(0).toList(), [1, 0, 2, 0, 3]);
    });

    test('sumBy sums mapped values', () {
      expect(
        ['a', 'bb', 'ccc'].sumBy((s) => s.length),
        6,
      );
    });

    test('none returns true when no elements match', () {
      expect([1, 2, 3].none((e) => e > 5), isTrue);
      expect([1, 2, 3].none((e) => e > 2), isFalse);
    });
  });

  group('VeloxNullableIterableExtension', () {
    test('whereNotNull filters nulls', () {
      expect([1, null, 2, null, 3].whereNotNull().toList(), [1, 2, 3]);
    });
  });

  group('VeloxIterableNullExtension', () {
    test('isNullOrEmpty', () {
      expect((null as List<int>?).isNullOrEmpty, isTrue);
      expect(<int>[].isNullOrEmpty, isTrue);
      expect([1].isNullOrEmpty, isFalse);
    });

    test('orEmpty', () {
      expect((null as List<int>?).orEmpty.toList(), <int>[]);
      expect([1, 2].orEmpty.toList(), [1, 2]);
    });
  });
}

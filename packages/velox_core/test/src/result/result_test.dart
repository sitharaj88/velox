import 'package:test/test.dart';
import 'package:velox_core/velox_core.dart';

void main() {
  group('Result', () {
    group('Success', () {
      test('creates a success result', () {
        const result = Success<int, String>(42);

        expect(result.isSuccess, isTrue);
        expect(result.isFailure, isFalse);
        expect(result.valueOrNull, 42);
        expect(result.errorOrNull, isNull);
        expect(result.valueOrThrow, 42);
      });

      test('factory constructor creates success', () {
        const result = Result<int, String>.success(42);

        expect(result.isSuccess, isTrue);
        expect(result.valueOrNull, 42);
      });

      test('equality works correctly', () {
        const a = Success<int, String>(42);
        const b = Success<int, String>(42);
        const c = Success<int, String>(99);

        expect(a, equals(b));
        expect(a, isNot(equals(c)));
      });

      test('toString returns readable format', () {
        const result = Success<int, String>(42);
        expect(result.toString(), 'Success(42)');
      });
    });

    group('Failure', () {
      test('creates a failure result', () {
        const result = Failure<int, String>('error');

        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
        expect(result.valueOrNull, isNull);
        expect(result.errorOrNull, 'error');
      });

      test('valueOrThrow throws error', () {
        const result = Failure<int, String>('oops');

        expect(() => result.valueOrThrow, throwsA('oops'));
      });

      test('factory constructor creates failure', () {
        const result = Result<int, String>.failure('error');

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, 'error');
      });

      test('equality works correctly', () {
        const a = Failure<int, String>('error');
        const b = Failure<int, String>('error');
        const c = Failure<int, String>('other');

        expect(a, equals(b));
        expect(a, isNot(equals(c)));
      });

      test('toString returns readable format', () {
        const result = Failure<int, String>('error');
        expect(result.toString(), 'Failure(error)');
      });
    });

    group('when', () {
      test('calls success handler for Success', () {
        const result = Result<int, String>.success(42);

        final value = result.when(
          success: (v) => 'got $v',
          failure: (e) => 'error: $e',
        );

        expect(value, 'got 42');
      });

      test('calls failure handler for Failure', () {
        const result = Result<int, String>.failure('oops');

        final value = result.when(
          success: (v) => 'got $v',
          failure: (e) => 'error: $e',
        );

        expect(value, 'error: oops');
      });
    });

    group('maybeWhen', () {
      test('calls success handler when available', () {
        const result = Result<int, String>.success(42);

        final value = result.maybeWhen(
          success: (v) => 'got $v',
          orElse: () => 'default',
        );

        expect(value, 'got 42');
      });

      test('calls orElse when handler not provided', () {
        const result = Result<int, String>.success(42);

        final value = result.maybeWhen(orElse: () => 'default');

        expect(value, 'default');
      });
    });

    group('map', () {
      test('transforms success value', () {
        const result = Result<int, String>.success(42);

        final mapped = result.map((v) => v * 2);

        expect(mapped.valueOrNull, 84);
      });

      test('passes through failure', () {
        const result = Result<int, String>.failure('error');

        final mapped = result.map((v) => v * 2);

        expect(mapped.isFailure, isTrue);
        expect(mapped.errorOrNull, 'error');
      });
    });

    group('mapError', () {
      test('transforms error value', () {
        const result = Result<int, String>.failure('error');

        final mapped = result.mapError((e) => 'mapped: $e');

        expect(mapped.errorOrNull, 'mapped: error');
      });

      test('passes through success', () {
        const result = Result<int, String>.success(42);

        final mapped = result.mapError((e) => 'mapped: $e');

        expect(mapped.valueOrNull, 42);
      });
    });

    group('flatMap', () {
      test('chains successful computations', () {
        const result = Result<int, String>.success(42);

        final chained = result.flatMap(
          (v) => Result<String, String>.success('value: $v'),
        );

        expect(chained.valueOrNull, 'value: 42');
      });

      test('short-circuits on failure', () {
        const result = Result<int, String>.failure('error');

        final chained = result.flatMap(
          (v) => Result<String, String>.success('value: $v'),
        );

        expect(chained.isFailure, isTrue);
        expect(chained.errorOrNull, 'error');
      });
    });

    group('getOrElse / getOrDefault', () {
      test('getOrElse returns value for success', () {
        const result = Result<int, String>.success(42);
        expect(result.getOrElse(() => 0), 42);
      });

      test('getOrElse returns default for failure', () {
        const result = Result<int, String>.failure('error');
        expect(result.getOrElse(() => 0), 0);
      });

      test('getOrDefault returns value for success', () {
        const result = Result<int, String>.success(42);
        expect(result.getOrDefault(0), 42);
      });

      test('getOrDefault returns default for failure', () {
        const result = Result<int, String>.failure('error');
        expect(result.getOrDefault(0), 0);
      });
    });
  });

  group('FutureResultExtension', () {
    test('converts successful future to Success', () async {
      final result = await Future.value(42).toResult();

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, 42);
    });

    test('converts failed future to Failure', () async {
      final result =
          await Future<int>.error(Exception('oops')).toResult();

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<Exception>());
    });
  });
}

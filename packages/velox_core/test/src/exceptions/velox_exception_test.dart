import 'package:test/test.dart';
import 'package:velox_core/velox_core.dart';

void main() {
  group('VeloxException', () {
    test('creates with message only', () {
      const exception = VeloxException(message: 'Something went wrong');

      expect(exception.message, 'Something went wrong');
      expect(exception.code, isNull);
      expect(exception.stackTrace, isNull);
      expect(exception.cause, isNull);
      expect(exception.toString(), 'VeloxException: Something went wrong');
    });

    test('creates with all fields', () {
      final cause = Exception('original');
      final exception = VeloxException(
        message: 'Something went wrong',
        code: 'ERR_001',
        cause: cause,
      );

      expect(exception.message, 'Something went wrong');
      expect(exception.code, 'ERR_001');
      expect(exception.cause, cause);
      expect(
        exception.toString(),
        'VeloxException[ERR_001]: Something went wrong '
        '(caused by: Exception: original)',
      );
    });

    test('implements Exception', () {
      const exception = VeloxException(message: 'test');
      expect(exception, isA<Exception>());
    });
  });

  group('VeloxNetworkException', () {
    test('creates with status code and url', () {
      const exception = VeloxNetworkException(
        message: 'Not found',
        code: 'NOT_FOUND',
        statusCode: 404,
        url: 'https://api.example.com/users/1',
      );

      expect(exception.statusCode, 404);
      expect(exception.url, 'https://api.example.com/users/1');
      expect(
        exception.toString(),
        'VeloxNetworkException[NOT_FOUND](404): Not found '
        '[url: https://api.example.com/users/1]',
      );
    });
  });

  group('VeloxStorageException', () {
    test('creates with key', () {
      const exception = VeloxStorageException(
        message: 'Key not found',
        key: 'user_token',
      );

      expect(exception.key, 'user_token');
      expect(
        exception.toString(),
        'VeloxStorageException: Key not found [key: user_token]',
      );
    });
  });

  group('VeloxValidationException', () {
    test('creates with field and violations', () {
      const exception = VeloxValidationException(
        message: 'Invalid email',
        field: 'email',
        violations: ['Must contain @', 'Must have domain'],
      );

      expect(exception.field, 'email');
      expect(exception.violations, hasLength(2));
      expect(
        exception.toString(),
        'VeloxValidationException[email]: Invalid email '
        '(violations: Must contain @, Must have domain)',
      );
    });
  });

  group('VeloxPlatformException', () {
    test('creates with platform', () {
      const exception = VeloxPlatformException(
        message: 'Not supported',
        platform: 'web',
      );

      expect(exception.platform, 'web');
      expect(
        exception.toString(),
        'VeloxPlatformException[web]: Not supported',
      );
    });
  });

  group('VeloxTimeoutException', () {
    test('creates with duration', () {
      const exception = VeloxTimeoutException(
        message: 'Request timed out',
        duration: Duration(seconds: 30),
      );

      expect(exception.duration, const Duration(seconds: 30));
      expect(
        exception.toString(),
        'VeloxTimeoutException: Request timed out (after 30000ms)',
      );
    });
  });
}

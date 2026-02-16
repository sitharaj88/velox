import 'dart:convert';

import 'package:test/test.dart';
import 'package:velox_logger/velox_logger.dart';

void main() {
  LogRecord makeRecord({
    LogLevel level = LogLevel.info,
    String message = 'test message',
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) => LogRecord(
    level: level,
    message: message,
    timestamp: DateTime(2026, 1, 15, 10, 30),
    tag: tag,
    error: error,
    stackTrace: stackTrace,
  );

  group('SimpleLogFormatter', () {
    late SimpleLogFormatter formatter;

    setUp(() {
      formatter = SimpleLogFormatter();
    });

    test('formats basic message with level', () {
      final result = formatter.format(makeRecord());

      expect(result, equals('[INFO] test message'));
    });

    test('includes tag when present', () {
      final result = formatter.format(makeRecord(tag: 'AuthService'));

      expect(result, equals('[INFO] AuthService: test message'));
    });

    test('includes error when present', () {
      final result = formatter.format(
        makeRecord(error: Exception('oops')),
      );

      expect(result, contains('| Error: Exception: oops'));
    });

    test('includes stack trace when present', () {
      final trace = StackTrace.current;
      final result = formatter.format(makeRecord(stackTrace: trace));

      expect(result, contains(trace.toString()));
    });

    test('formats all levels correctly', () {
      for (final level in LogLevel.values) {
        final result = formatter.format(makeRecord(level: level));
        expect(result, startsWith('[${level.label}]'));
      }
    });

    test('includes error and stack trace together', () {
      final trace = StackTrace.current;
      final result = formatter.format(
        makeRecord(
          error: Exception('fail'),
          stackTrace: trace,
        ),
      );

      expect(result, contains('| Error: Exception: fail'));
      expect(result, contains(trace.toString()));
    });
  });

  group('PrettyLogFormatter', () {
    late PrettyLogFormatter formatter;

    setUp(() {
      formatter = PrettyLogFormatter();
    });

    test('includes box characters', () {
      final result = formatter.format(makeRecord());

      expect(result, contains('\u250C')); // top left
      expect(result, contains('\u2514')); // bottom left
      expect(result, contains('\u251C')); // middle left
      expect(result, contains('\u2502')); // vertical
    });

    test('includes timestamp in header', () {
      final result = formatter.format(makeRecord());

      expect(result, contains('2026-01-15T10:30:00.000'));
    });

    test('includes level label in header', () {
      final result = formatter.format(makeRecord(level: LogLevel.error));

      expect(result, contains('ERROR'));
    });

    test('includes tag in header when present', () {
      final result = formatter.format(makeRecord(tag: 'MyTag'));

      expect(result, contains('MyTag'));
    });

    test('includes message in body', () {
      final result = formatter.format(makeRecord(message: 'Hello world'));

      expect(result, contains('\u2502 Hello world'));
    });

    test('includes error section when present', () {
      final result = formatter.format(
        makeRecord(error: Exception('fail')),
      );

      expect(result, contains('Error: Exception: fail'));
    });

    test('includes stack trace section when present', () {
      final trace = StackTrace.current;
      final result = formatter.format(makeRecord(stackTrace: trace));

      // Stack trace lines should be present
      expect(result, contains(trace.toString().split('\n').first));
    });

    test('supports custom line width', () {
      final narrow = PrettyLogFormatter(lineWidth: 40);
      final wide = PrettyLogFormatter(lineWidth: 120);

      final narrowResult = narrow.format(makeRecord());
      final wideResult = wide.format(makeRecord());

      // The wider formatter should produce longer border lines
      expect(wideResult.length, greaterThan(narrowResult.length));
    });

    test('handles multi-line messages', () {
      final result = formatter.format(
        makeRecord(message: 'line1\nline2\nline3'),
      );

      expect(result, contains('\u2502 line1'));
      expect(result, contains('\u2502 line2'));
      expect(result, contains('\u2502 line3'));
    });
  });

  group('JsonLogFormatter', () {
    late JsonLogFormatter formatter;

    setUp(() {
      formatter = JsonLogFormatter();
    });

    test('outputs valid JSON', () {
      final result = formatter.format(makeRecord());
      final parsed = jsonDecode(result) as Map<String, dynamic>;

      expect(parsed, isA<Map<String, dynamic>>());
    });

    test('includes timestamp', () {
      final result = formatter.format(makeRecord());
      final parsed = jsonDecode(result) as Map<String, dynamic>;

      expect(parsed['timestamp'], equals('2026-01-15T10:30:00.000'));
    });

    test('includes level', () {
      final result = formatter.format(makeRecord(level: LogLevel.warning));
      final parsed = jsonDecode(result) as Map<String, dynamic>;

      expect(parsed['level'], equals('WARN'));
    });

    test('includes message', () {
      final result = formatter.format(makeRecord(message: 'hello'));
      final parsed = jsonDecode(result) as Map<String, dynamic>;

      expect(parsed['message'], equals('hello'));
    });

    test('includes tag when present', () {
      final result = formatter.format(makeRecord(tag: 'DB'));
      final parsed = jsonDecode(result) as Map<String, dynamic>;

      expect(parsed['tag'], equals('DB'));
    });

    test('omits tag when null', () {
      final result = formatter.format(makeRecord());
      final parsed = jsonDecode(result) as Map<String, dynamic>;

      expect(parsed.containsKey('tag'), isFalse);
    });

    test('includes error when present', () {
      final result = formatter.format(
        makeRecord(error: Exception('boom')),
      );
      final parsed = jsonDecode(result) as Map<String, dynamic>;

      expect(parsed['error'], contains('boom'));
    });

    test('omits error when null', () {
      final result = formatter.format(makeRecord());
      final parsed = jsonDecode(result) as Map<String, dynamic>;

      expect(parsed.containsKey('error'), isFalse);
    });

    test('includes stackTrace when present', () {
      final trace = StackTrace.current;
      final result = formatter.format(makeRecord(stackTrace: trace));
      final parsed = jsonDecode(result) as Map<String, dynamic>;

      expect(parsed.containsKey('stackTrace'), isTrue);
    });

    test('pretty print produces indented output', () {
      final pretty = JsonLogFormatter(prettyPrint: true);
      final result = pretty.format(makeRecord());

      expect(result, contains('\n'));
      expect(result, contains('  '));
    });
  });
}

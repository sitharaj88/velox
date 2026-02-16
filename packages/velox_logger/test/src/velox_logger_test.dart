// ignore_for_file: cascade_invocations
import 'package:test/test.dart';
import 'package:velox_logger/velox_logger.dart';

void main() {
  group('VeloxLogger', () {
    late MemoryLogOutput output;
    late VeloxLogger logger;

    setUp(() {
      output = MemoryLogOutput();
      logger = VeloxLogger(output: output, minLevel: LogLevel.trace);
    });

    test('logs at all levels', () {
      logger
        ..trace('trace message')
        ..debug('debug message')
        ..info('info message')
        ..warning('warning message')
        ..error('error message')
        ..fatal('fatal message');

      expect(output.records, hasLength(6));
      expect(output.records[0].level, LogLevel.trace);
      expect(output.records[1].level, LogLevel.debug);
      expect(output.records[2].level, LogLevel.info);
      expect(output.records[3].level, LogLevel.warning);
      expect(output.records[4].level, LogLevel.error);
      expect(output.records[5].level, LogLevel.fatal);
    });

    test('filters by minimum level', () {
      final filteredLogger = VeloxLogger(
        output: output,
        minLevel: LogLevel.warning,
      );

      filteredLogger
        ..trace('hidden')
        ..debug('hidden')
        ..info('hidden')
        ..warning('shown')
        ..error('shown');

      expect(output.records, hasLength(2));
      expect(output.records[0].message, 'shown');
      expect(output.records[0].level, LogLevel.warning);
    });

    test('includes tag in log records', () {
      final taggedLogger = VeloxLogger(
        output: output,
        tag: 'AuthService',
      );

      taggedLogger.info('User logged in');

      expect(output.records.first.tag, 'AuthService');
    });

    test('includes error and stack trace', () {
      final error = Exception('test error');
      final stackTrace = StackTrace.current;

      logger.error(
        'Something failed',
        error: error,
        stackTrace: stackTrace,
      );

      final record = output.records.first;
      expect(record.error, error);
      expect(record.stackTrace, stackTrace);
    });

    test('child logger inherits configuration', () {
      final parent = VeloxLogger(
        output: output,
        tag: 'App',
        minLevel: LogLevel.warning,
      );

      final child = parent.child('Auth');
      child
        ..info('hidden')
        ..warning('shown');

      expect(output.records, hasLength(1));
      expect(output.records.first.tag, 'App.Auth');
    });

    test('child logger without parent tag', () {
      final parent = VeloxLogger(output: output);
      final child = parent.child('Auth');
      child.info('test');

      expect(output.records.first.tag, 'Auth');
    });

    test('log method accepts level parameter', () {
      logger.log(LogLevel.info, 'generic log');

      expect(output.records.first.level, LogLevel.info);
      expect(output.records.first.message, 'generic log');
    });

    test('records include timestamp', () {
      final before = DateTime.now();
      logger.info('test');
      final after = DateTime.now();

      final timestamp = output.records.first.timestamp;
      expect(
        timestamp.isAfter(before) || timestamp.isAtSameMomentAs(before),
        isTrue,
      );
      expect(
        timestamp.isBefore(after) || timestamp.isAtSameMomentAs(after),
        isTrue,
      );
    });
  });

  group('LogLevel', () {
    test('comparison operators work correctly', () {
      expect(LogLevel.error >= LogLevel.warning, isTrue);
      expect(LogLevel.debug < LogLevel.info, isTrue);
      expect(LogLevel.fatal > LogLevel.error, isTrue);
      expect(LogLevel.trace <= LogLevel.debug, isTrue);
    });

    test('compareTo works for sorting', () {
      final levels = [LogLevel.error, LogLevel.debug, LogLevel.info];
      levels.sort();
      expect(levels, [LogLevel.debug, LogLevel.info, LogLevel.error]);
    });
  });

  group('LogRecord', () {
    test('toString formats correctly', () {
      final record = LogRecord(
        level: LogLevel.info,
        message: 'test message',
        timestamp: DateTime(2026, 1, 15, 10, 30),
        tag: 'TestTag',
      );

      final str = record.toString();
      expect(str, contains('[INFO]'));
      expect(str, contains('test message'));
      expect(str, contains('[TestTag]'));
    });

    test('toString includes error when present', () {
      final record = LogRecord(
        level: LogLevel.error,
        message: 'failed',
        timestamp: DateTime.now(),
        error: Exception('oops'),
      );

      expect(record.toString(), contains('Error: Exception: oops'));
    });
  });

  group('MemoryLogOutput', () {
    test('clear removes all records', () {
      final output = MemoryLogOutput()
        ..write(
          LogRecord(
            level: LogLevel.info,
            message: 'test',
            timestamp: DateTime.now(),
          ),
        );

      expect(output.records, hasLength(1));
      output.clear();
      expect(output.records, isEmpty);
    });
  });

  group('MultiLogOutput', () {
    test('writes to all outputs', () {
      final output1 = MemoryLogOutput();
      final output2 = MemoryLogOutput();
      final multi = MultiLogOutput([output1, output2]);

      multi.write(
        LogRecord(
          level: LogLevel.info,
          message: 'test',
          timestamp: DateTime.now(),
        ),
      );

      expect(output1.records, hasLength(1));
      expect(output2.records, hasLength(1));
    });
  });
}

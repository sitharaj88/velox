// ignore_for_file: cascade_invocations, avoid_redundant_argument_values
import 'dart:async';

import 'package:test/test.dart';
import 'package:velox_logger/velox_logger.dart';

void main() {
  LogRecord makeRecord({
    LogLevel level = LogLevel.info,
    String message = 'test',
    String? tag,
  }) => LogRecord(
    level: level,
    message: message,
    timestamp: DateTime.now(),
    tag: tag,
  );

  group('VeloxLogHistory', () {
    late VeloxLogHistory history;

    setUp(() {
      history = VeloxLogHistory();
    });

    tearDown(() async {
      await history.dispose();
    });

    test('stores records', () {
      history.add(makeRecord(message: 'a'));
      history.add(makeRecord(message: 'b'));

      expect(history.records, hasLength(2));
      expect(history.records[0].message, equals('a'));
      expect(history.records[1].message, equals('b'));
    });

    test('enforces max size (circular buffer)', () {
      final small = VeloxLogHistory(maxSize: 3);
      addTearDown(small.dispose);

      small.add(makeRecord(message: '1'));
      small.add(makeRecord(message: '2'));
      small.add(makeRecord(message: '3'));
      small.add(makeRecord(message: '4'));

      expect(small.records, hasLength(3));
      expect(small.records[0].message, equals('2'));
      expect(small.records[1].message, equals('3'));
      expect(small.records[2].message, equals('4'));
    });

    test('clear removes all records', () {
      history.add(makeRecord());
      history.add(makeRecord());

      expect(history.records, hasLength(2));

      history.clear();

      expect(history.records, isEmpty);
    });

    test('where filters by minimum level', () {
      history.add(makeRecord(level: LogLevel.debug, message: 'debug'));
      history.add(makeRecord(level: LogLevel.info, message: 'info'));
      history.add(makeRecord(level: LogLevel.error, message: 'error'));

      final errors = history.where(minLevel: LogLevel.error);

      expect(errors, hasLength(1));
      expect(errors.first.message, equals('error'));
    });

    test('where filters by tag', () {
      history.add(makeRecord(tag: 'Auth', message: 'auth msg'));
      history.add(makeRecord(tag: 'DB', message: 'db msg'));
      history.add(makeRecord(tag: 'Auth', message: 'auth msg 2'));

      final authRecords = history.where(tag: 'Auth');

      expect(authRecords, hasLength(2));
    });

    test('where combines level and tag filters', () {
      history.add(
        makeRecord(
          level: LogLevel.debug,
          tag: 'Auth',
          message: 'debug auth',
        ),
      );
      history.add(
        makeRecord(
          level: LogLevel.error,
          tag: 'Auth',
          message: 'error auth',
        ),
      );
      history.add(
        makeRecord(
          level: LogLevel.error,
          tag: 'DB',
          message: 'error db',
        ),
      );

      final results = history.where(minLevel: LogLevel.error, tag: 'Auth');

      expect(results, hasLength(1));
      expect(results.first.message, equals('error auth'));
    });

    test('where with no filters returns all', () {
      history.add(makeRecord(message: 'a'));
      history.add(makeRecord(message: 'b'));

      final results = history.where();

      expect(results, hasLength(2));
    });

    test('onRecord emits new records', () async {
      final completer = Completer<LogRecord>();
      final subscription = history.onRecord.listen(completer.complete);

      final record = makeRecord(message: 'streamed');
      history.add(record);

      final received = await completer.future.timeout(
        const Duration(seconds: 1),
      );
      expect(received.message, equals('streamed'));

      await subscription.cancel();
    });

    test('onRecord is a broadcast stream', () {
      // Should not throw when listening multiple times
      final sub1 = history.onRecord.listen((_) {});
      final sub2 = history.onRecord.listen((_) {});

      addTearDown(() async {
        await sub1.cancel();
        await sub2.cancel();
      });

      expect(sub1, isNotNull);
      expect(sub2, isNotNull);
    });

    test('records list is unmodifiable', () {
      history.add(makeRecord());

      expect(
        () => history.records.add(makeRecord()),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('default maxSize is 1000', () {
      expect(history.maxSize, equals(1000));
    });
  });
}

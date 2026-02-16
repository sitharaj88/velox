// ignore_for_file: cascade_invocations
import 'package:test/test.dart';
import 'package:velox_logger/velox_logger.dart';

void main() {
  group('VeloxLogger enhanced features', () {
    test('integrates formatter and sinks', () {
      final messages = <String>[];
      final output = MemoryLogOutput();
      final logger = VeloxLogger(
        tag: 'Test',
        minLevel: LogLevel.trace,
        output: output,
        formatter: SimpleLogFormatter(),
        sinks: [CallbackSink(messages.add)],
      );

      logger.info('hello');

      // Sink should receive formatted message
      expect(messages, hasLength(1));
      expect(messages.first, equals('[INFO] Test: hello'));

      // Legacy output should also receive the record
      expect(output.records, hasLength(1));
    });

    test('filter blocks records from sinks and output', () {
      final messages = <String>[];
      final output = MemoryLogOutput();
      final logger = VeloxLogger(
        tag: 'Test',
        minLevel: LogLevel.trace,
        output: output,
        formatter: SimpleLogFormatter(),
        sinks: [CallbackSink(messages.add)],
        filter: LevelFilter(LogLevel.warning),
      );

      logger.info('should be filtered');
      logger.warning('should pass');

      expect(messages, hasLength(1));
      expect(messages.first, contains('should pass'));
      expect(output.records, hasLength(1));
    });

    test('history receives records that pass filters', () {
      final history = VeloxLogHistory();
      final output = MemoryLogOutput();
      final logger = VeloxLogger(
        minLevel: LogLevel.trace,
        output: output,
        filter: LevelFilter(LogLevel.warning),
        history: history,
      );

      logger.info('filtered out');
      logger.error('passes through');

      expect(history.records, hasLength(1));
      expect(history.records.first.message, equals('passes through'));

      addTearDown(history.dispose);
    });

    test('child logger inherits formatter and sinks', () {
      final messages = <String>[];
      final output = MemoryLogOutput();
      final parent = VeloxLogger(
        tag: 'App',
        minLevel: LogLevel.trace,
        output: output,
        formatter: SimpleLogFormatter(),
        sinks: [CallbackSink(messages.add)],
      );

      final child = parent.child('Auth');
      child.info('logged in');

      expect(messages, hasLength(1));
      expect(messages.first, equals('[INFO] App.Auth: logged in'));
    });

    test('child logger inherits filter', () {
      final output = MemoryLogOutput();
      final parent = VeloxLogger(
        tag: 'App',
        minLevel: LogLevel.trace,
        output: output,
        filter: LevelFilter(LogLevel.error),
      );

      final child = parent.child('Auth');
      child.info('filtered');
      child.error('passes');

      expect(output.records, hasLength(1));
      expect(output.records.first.message, equals('passes'));
    });

    test('child logger inherits history', () {
      final history = VeloxLogHistory();
      final output = MemoryLogOutput();
      final parent = VeloxLogger(
        tag: 'App',
        minLevel: LogLevel.trace,
        output: output,
        history: history,
      );

      final child = parent.child('DB');
      child.info('query executed');

      expect(history.records, hasLength(1));
      expect(history.records.first.tag, equals('App.DB'));

      addTearDown(history.dispose);
    });
  });

  group('VeloxLogger.root', () {
    tearDown(VeloxLogger.resetRoot);

    test('returns a singleton instance', () {
      final root1 = VeloxLogger.root;
      final root2 = VeloxLogger.root;

      expect(identical(root1, root2), isTrue);
    });

    test('has Root tag', () {
      expect(VeloxLogger.root.tag, equals('Root'));
    });

    test('resetRoot clears the singleton', () {
      final root1 = VeloxLogger.root;
      VeloxLogger.resetRoot();
      final root2 = VeloxLogger.root;

      expect(identical(root1, root2), isFalse);
    });

    test('root can create child loggers', () {
      VeloxLogger.resetRoot();
      final child = VeloxLogger.root.child('Service');
      expect(child.tag, equals('Root.Service'));
    });
  });

  group('VeloxLogger backward compatibility', () {
    test('works without new parameters', () {
      final output = MemoryLogOutput();
      final logger = VeloxLogger(
        tag: 'Test',
        output: output,
        minLevel: LogLevel.trace,
      );

      logger.info('test message');

      expect(output.records, hasLength(1));
      expect(output.records.first.message, equals('test message'));
    });

    test('minLevel filtering still works', () {
      final output = MemoryLogOutput();
      final logger = VeloxLogger(
        output: output,
        minLevel: LogLevel.warning,
      );

      logger.debug('hidden');
      logger.warning('visible');

      expect(output.records, hasLength(1));
      expect(output.records.first.message, equals('visible'));
    });

    test('dispose disposes output and sinks', () async {
      var sinkDisposed = false;
      final output = MemoryLogOutput();
      final sink = _TrackingDisposeSink(
        onDispose: () => sinkDisposed = true,
      );

      final logger = VeloxLogger(
        output: output,
        formatter: SimpleLogFormatter(),
        sinks: [sink],
      );

      logger.dispose();

      expect(sinkDisposed, isTrue);
    });

    test('works with sinks but no formatter (legacy only)', () {
      final messages = <String>[];
      final output = MemoryLogOutput();
      final logger = VeloxLogger(
        output: output,
        minLevel: LogLevel.trace,
        sinks: [CallbackSink(messages.add)],
        // No formatter, so sinks pipeline is skipped
      );

      logger.info('test');

      // Legacy output should still work
      expect(output.records, hasLength(1));
      // Sinks should not receive anything (no formatter)
      expect(messages, isEmpty);
    });
  });
}

class _TrackingDisposeSink extends VeloxLogSink {
  _TrackingDisposeSink({required this.onDispose});

  final void Function() onDispose;

  @override
  void write(String formattedMessage) {}

  @override
  Future<void> dispose() async {
    onDispose();
  }
}

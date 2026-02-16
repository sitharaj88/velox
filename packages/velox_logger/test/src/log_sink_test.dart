// ignore_for_file: cascade_invocations
import 'package:test/test.dart';
import 'package:velox_logger/velox_logger.dart';

void main() {
  group('CallbackSink', () {
    test('invokes callback with formatted message', () {
      final messages = <String>[];
      final sink = CallbackSink(messages.add);

      sink.write('[INFO] test message');

      expect(messages, hasLength(1));
      expect(messages.first, equals('[INFO] test message'));
    });

    test('invokes callback for each write', () {
      final messages = <String>[];
      final sink = CallbackSink(messages.add);

      sink.write('message 1');
      sink.write('message 2');
      sink.write('message 3');

      expect(messages, hasLength(3));
    });
  });

  group('CompositeSink', () {
    test('writes to all child sinks', () {
      final messages1 = <String>[];
      final messages2 = <String>[];
      final composite = CompositeSink([
        CallbackSink(messages1.add),
        CallbackSink(messages2.add),
      ]);

      composite.write('[INFO] test');

      expect(messages1, hasLength(1));
      expect(messages2, hasLength(1));
      expect(messages1.first, equals('[INFO] test'));
      expect(messages2.first, equals('[INFO] test'));
    });

    test('disposes all child sinks', () async {
      var disposed1 = false;
      var disposed2 = false;

      final sink1 = _DisposableSink(onDispose: () => disposed1 = true);
      final sink2 = _DisposableSink(onDispose: () => disposed2 = true);
      final composite = CompositeSink([sink1, sink2]);

      await composite.dispose();

      expect(disposed1, isTrue);
      expect(disposed2, isTrue);
    });

    test('works with empty sinks list', () {
      final composite = CompositeSink([]);

      // Should not throw
      composite.write('[INFO] test');
    });
  });

  group('BufferedSink', () {
    test('buffers messages until flush', () {
      final messages = <String>[];
      final delegate = CallbackSink(messages.add);
      final buffered = BufferedSink(delegate: delegate, bufferSize: 10);

      buffered.write('message 1');
      buffered.write('message 2');

      // Not flushed yet
      expect(messages, isEmpty);
      expect(buffered.pendingCount, equals(2));

      buffered.flush();

      expect(messages, hasLength(2));
      expect(buffered.pendingCount, equals(0));
    });

    test('auto-flushes when buffer is full', () {
      final messages = <String>[];
      final delegate = CallbackSink(messages.add);
      final buffered = BufferedSink(delegate: delegate, bufferSize: 3);

      buffered.write('msg 1');
      buffered.write('msg 2');

      expect(messages, isEmpty);

      buffered.write('msg 3'); // triggers auto-flush

      expect(messages, hasLength(3));
      expect(buffered.pendingCount, equals(0));
    });

    test('flush is idempotent when empty', () {
      final messages = <String>[];
      final delegate = CallbackSink(messages.add);
      final buffered = BufferedSink(delegate: delegate);

      // Should not throw
      buffered.flush();

      expect(messages, isEmpty);
    });

    test('dispose flushes remaining messages', () async {
      final messages = <String>[];
      final delegate = CallbackSink(messages.add);
      final buffered = BufferedSink(delegate: delegate, bufferSize: 50);

      buffered.write('msg 1');
      buffered.write('msg 2');

      expect(messages, isEmpty);

      await buffered.dispose();

      expect(messages, hasLength(2));
    });

    test('reports pending count correctly', () {
      final delegate = CallbackSink((_) {});
      final buffered = BufferedSink(delegate: delegate);

      expect(buffered.pendingCount, equals(0));

      buffered.write('a');
      expect(buffered.pendingCount, equals(1));

      buffered.write('b');
      expect(buffered.pendingCount, equals(2));

      buffered.flush();
      expect(buffered.pendingCount, equals(0));
    });
  });
}

/// A test sink that tracks disposal.
class _DisposableSink extends VeloxLogSink {
  _DisposableSink({required this.onDispose});

  final void Function() onDispose;

  @override
  void write(String formattedMessage) {}

  @override
  Future<void> dispose() async {
    onDispose();
  }
}

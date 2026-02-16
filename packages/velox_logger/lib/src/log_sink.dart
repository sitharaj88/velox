import 'dart:async';
import 'dart:io';

/// Abstraction for log output destinations.
///
/// A sink receives pre-formatted log messages and writes them
/// to a destination (console, file, network, etc.).
///
/// ```dart
/// final sink = ConsoleSink();
/// sink.write('[INFO] Hello world');
/// await sink.dispose();
/// ```
abstract class VeloxLogSink {
  /// Writes a pre-formatted log message to the output destination.
  void write(String formattedMessage);

  /// Releases any resources held by this sink.
  ///
  /// After calling [dispose], the sink should not be used again.
  Future<void> dispose() async {}
}

/// A sink that writes formatted log messages to [stdout].
///
/// This is the default sink used when no other sinks are configured.
///
/// ```dart
/// final sink = ConsoleSink();
/// sink.write('[INFO] AuthService: User logged in');
/// ```
class ConsoleSink extends VeloxLogSink {
  /// Creates a [ConsoleSink].
  ConsoleSink();

  @override
  void write(String formattedMessage) {
    stdout.writeln(formattedMessage);
  }
}

/// A sink that delegates to a user-provided callback function.
///
/// Useful for integrating with custom logging systems or testing.
///
/// ```dart
/// final messages = <String>[];
/// final sink = CallbackSink((msg) => messages.add(msg));
/// sink.write('[INFO] test');
/// ```
class CallbackSink extends VeloxLogSink {
  /// Creates a [CallbackSink] with the given [onMessage] callback.
  CallbackSink(this.onMessage);

  /// The callback invoked for each formatted log message.
  final void Function(String message) onMessage;

  @override
  void write(String formattedMessage) {
    onMessage(formattedMessage);
  }
}

/// A sink that fans out formatted messages to multiple child sinks.
///
/// ```dart
/// final composite = CompositeSink([
///   ConsoleSink(),
///   CallbackSink((msg) => remoteLog(msg)),
/// ]);
/// composite.write('[INFO] test'); // written to both sinks
/// ```
class CompositeSink extends VeloxLogSink {
  /// Creates a [CompositeSink] that writes to all [sinks].
  CompositeSink(this.sinks);

  /// The list of child sinks to write to.
  final List<VeloxLogSink> sinks;

  @override
  void write(String formattedMessage) {
    for (final sink in sinks) {
      sink.write(formattedMessage);
    }
  }

  @override
  Future<void> dispose() async {
    for (final sink in sinks) {
      await sink.dispose();
    }
  }
}

/// A sink that buffers messages in memory and flushes them to a
/// delegate sink either when the buffer is full or on demand.
///
/// ```dart
/// final buffered = BufferedSink(
///   delegate: ConsoleSink(),
///   bufferSize: 50,
/// );
/// buffered.write('[INFO] test'); // buffered, not yet flushed
/// buffered.flush(); // now flushed to ConsoleSink
/// ```
class BufferedSink extends VeloxLogSink {
  /// Creates a [BufferedSink].
  ///
  /// - [delegate] is the sink to flush buffered messages to.
  /// - [bufferSize] is the max number of messages to buffer before
  ///   auto-flushing. Defaults to 100.
  BufferedSink({
    required this.delegate,
    this.bufferSize = 100,
  });

  /// The underlying sink that receives flushed messages.
  final VeloxLogSink delegate;

  /// The maximum number of messages to buffer before auto-flushing.
  final int bufferSize;

  final List<String> _buffer = [];

  /// Returns the current number of buffered messages.
  int get pendingCount => _buffer.length;

  @override
  void write(String formattedMessage) {
    _buffer.add(formattedMessage);
    if (_buffer.length >= bufferSize) {
      flush();
    }
  }

  /// Flushes all buffered messages to the [delegate] sink.
  void flush() {
    for (final message in _buffer) {
      delegate.write(message);
    }
    _buffer.clear();
  }

  @override
  Future<void> dispose() async {
    flush();
    await delegate.dispose();
  }
}

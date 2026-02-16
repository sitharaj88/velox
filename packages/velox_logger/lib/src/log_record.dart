import 'package:velox_logger/src/log_level.dart';

/// An immutable record of a single log event.
class LogRecord {
  /// Creates a [LogRecord].
  LogRecord({
    required this.level,
    required this.message,
    required this.timestamp,
    this.tag,
    this.error,
    this.stackTrace,
  });

  /// The severity level of this log record.
  final LogLevel level;

  /// The log message.
  final String message;

  /// When this log event occurred.
  final DateTime timestamp;

  /// Optional tag for filtering and categorization.
  final String? tag;

  /// Optional error associated with this log record.
  final Object? error;

  /// Optional stack trace associated with this log record.
  final StackTrace? stackTrace;

  @override
  String toString() {
    final buffer = StringBuffer()
      ..write('[${level.label}]')
      ..write(' ${timestamp.toIso8601String()}');
    if (tag != null) {
      buffer.write(' [$tag]');
    }
    buffer.write(' $message');
    if (error != null) {
      buffer.write('\n  Error: $error');
    }
    if (stackTrace != null) {
      buffer.write('\n  $stackTrace');
    }
    return buffer.toString();
  }
}

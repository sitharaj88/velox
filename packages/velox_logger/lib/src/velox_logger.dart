import 'package:velox_logger/src/log_level.dart';
import 'package:velox_logger/src/log_output.dart';
import 'package:velox_logger/src/log_record.dart';

/// A structured logger with configurable output and filtering.
///
/// ```dart
/// final logger = VeloxLogger(tag: 'AuthService');
/// logger.info('User logged in');
/// logger.error('Login failed', error: exception, stackTrace: trace);
/// ```
class VeloxLogger {
  /// Creates a [VeloxLogger].
  ///
  /// - [tag] is an optional label for filtering.
  /// - [minLevel] sets the minimum severity to output.
  /// - [output] is the log destination (defaults to console).
  VeloxLogger({
    this.tag,
    this.minLevel = LogLevel.debug,
    LogOutput? output,
  }) : output = output ?? ConsoleLogOutput();

  /// Optional tag for categorizing log messages.
  final String? tag;

  /// Minimum log level to output.
  final LogLevel minLevel;

  /// The output destination for log records.
  final LogOutput output;

  /// Logs a message at the [LogLevel.trace] level.
  void trace(String message, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.trace, message, error: error, stackTrace: stackTrace);

  /// Logs a message at the [LogLevel.debug] level.
  void debug(String message, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.debug, message, error: error, stackTrace: stackTrace);

  /// Logs a message at the [LogLevel.info] level.
  void info(String message, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.info, message, error: error, stackTrace: stackTrace);

  /// Logs a message at the [LogLevel.warning] level.
  void warning(String message, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.warning, message, error: error, stackTrace: stackTrace);

  /// Logs a message at the [LogLevel.error] level.
  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.error, message, error: error, stackTrace: stackTrace);

  /// Logs a message at the [LogLevel.fatal] level.
  void fatal(String message, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.fatal, message, error: error, stackTrace: stackTrace);

  /// Logs a message at the given [level].
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) => _log(level, message, error: error, stackTrace: stackTrace);

  /// Creates a child logger with a new [tag], inheriting configuration.
  VeloxLogger child(String childTag) => VeloxLogger(
    tag: tag != null ? '$tag.$childTag' : childTag,
    minLevel: minLevel,
    output: output,
  );

  /// Disposes of the output resources.
  void dispose() => output.dispose();

  void _log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level < minLevel) return;

    final record = LogRecord(
      level: level,
      message: message,
      timestamp: DateTime.now(),
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );

    output.write(record);
  }
}

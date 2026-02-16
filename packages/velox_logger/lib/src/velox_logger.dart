import 'package:velox_logger/src/log_filter.dart';
import 'package:velox_logger/src/log_formatter.dart';
import 'package:velox_logger/src/log_history.dart';
import 'package:velox_logger/src/log_level.dart';
import 'package:velox_logger/src/log_output.dart';
import 'package:velox_logger/src/log_record.dart';
import 'package:velox_logger/src/log_sink.dart';

/// A structured logger with configurable output, formatting, filtering,
/// and history.
///
/// Supports the legacy [LogOutput]-based API as well as the newer
/// [VeloxLogFormatter] + [VeloxLogSink] pipeline.
///
/// ```dart
/// final logger = VeloxLogger(tag: 'AuthService');
/// logger.info('User logged in');
/// logger.error('Login failed', error: exception, stackTrace: trace);
/// ```
///
/// Enhanced usage with formatter, sinks, filter, and history:
///
/// ```dart
/// final history = VeloxLogHistory();
/// final logger = VeloxLogger(
///   tag: 'App',
///   formatter: JsonLogFormatter(),
///   sinks: [ConsoleSink()],
///   filter: LevelFilter(LogLevel.info),
///   history: history,
/// );
/// ```
class VeloxLogger {
  /// Creates a [VeloxLogger].
  ///
  /// - [tag] is an optional label for filtering.
  /// - [minLevel] sets the minimum severity to output (used by the legacy
  ///   [LogOutput]-based pipeline).
  /// - [output] is the legacy log destination (defaults to [ConsoleLogOutput]).
  /// - [formatter] is the formatter for the new sink-based pipeline.
  /// - [sinks] are the output destinations for formatted messages.
  /// - [filter] is an optional filter applied before any output.
  /// - [history] is an optional in-memory log history buffer.
  VeloxLogger({
    this.tag,
    this.minLevel = LogLevel.debug,
    LogOutput? output,
    this.formatter,
    this.sinks = const [],
    this.filter,
    this.history,
  }) : output = output ?? ConsoleLogOutput();

  /// A private constructor used internally for child loggers to inherit
  /// all configuration without defaulting [output].
  VeloxLogger._internal({
    required this.tag,
    required this.minLevel,
    required this.output,
    required this.formatter,
    required this.sinks,
    required this.filter,
    required this.history,
  });

  static VeloxLogger? _root;

  /// Returns a singleton root logger.
  ///
  /// The root logger uses default settings (debug level, console output).
  /// Use this as a global logger when you don't need separate instances.
  // ignore: prefer_constructors_over_static_methods
  static VeloxLogger get root => _root ??= VeloxLogger(tag: 'Root');

  /// Resets the root singleton. Primarily useful for testing.
  static void resetRoot() {
    _root = null;
  }

  /// Optional tag for categorizing log messages.
  final String? tag;

  /// Minimum log level to output.
  final LogLevel minLevel;

  /// The output destination for log records (legacy API).
  final LogOutput output;

  /// Optional formatter for the sink-based pipeline.
  ///
  /// When set along with [sinks], log records are formatted by this
  /// formatter and then written to each sink.
  final VeloxLogFormatter? formatter;

  /// Output sinks that receive formatted log messages.
  ///
  /// Requires [formatter] to be set. If [sinks] is empty, the legacy
  /// [output] pipeline is used instead.
  final List<VeloxLogSink> sinks;

  /// Optional filter applied to log records before any output.
  ///
  /// If the filter returns `false` for a record, it is silently dropped.
  final VeloxLogFilter? filter;

  /// Optional in-memory history buffer for log records.
  ///
  /// When set, every record that passes filtering is added to the history.
  final VeloxLogHistory? history;

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

  /// Creates a child logger with a new [childTag], inheriting all
  /// configuration from this logger.
  ///
  /// The child tag is appended to the parent tag with a dot separator.
  /// For example, if the parent tag is `'App'` and the child tag is
  /// `'Auth'`, the resulting tag is `'App.Auth'`.
  VeloxLogger child(String childTag) => VeloxLogger._internal(
    tag: tag != null ? '$tag.$childTag' : childTag,
    minLevel: minLevel,
    output: output,
    formatter: formatter,
    sinks: sinks,
    filter: filter,
    history: history,
  );

  /// Disposes of the output and all sink resources.
  void dispose() {
    output.dispose();
    for (final sink in sinks) {
      sink.dispose();
    }
  }

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

    // Apply filter if present.
    if (filter != null && !filter!.shouldLog(record)) {
      return;
    }

    // Add to history if present.
    history?.add(record);

    // If formatter + sinks are configured, use the new pipeline.
    if (formatter != null && sinks.isNotEmpty) {
      final formatted = formatter!.format(record);
      for (final sink in sinks) {
        sink.write(formatted);
      }
    }

    // Always write to the legacy output for backward compatibility.
    output.write(record);
  }
}

import 'dart:developer' as developer;

import 'package:velox_logger/src/log_level.dart';
import 'package:velox_logger/src/log_record.dart';

/// Interface for log output destinations.
abstract class LogOutput {
  /// Writes a [record] to the output.
  void write(LogRecord record);

  /// Disposes of any resources held by this output.
  void dispose() {}
}

/// Outputs logs to the developer console using [developer.log].
class ConsoleLogOutput extends LogOutput {
  /// Creates a [ConsoleLogOutput].
  ///
  /// If [useColors] is true, ANSI colors are applied to the output.
  ConsoleLogOutput({this.useColors = true});

  /// Whether to use ANSI colors in output.
  final bool useColors;

  @override
  void write(LogRecord record) {
    final formattedMessage = _format(record);
    developer.log(
      formattedMessage,
      name: record.tag ?? 'Velox',
      level: _mapLevel(record.level),
      error: record.error,
      stackTrace: record.stackTrace,
      time: record.timestamp,
    );
  }

  String _format(LogRecord record) {
    final buffer = StringBuffer();
    final prefix = useColors ? _colorForLevel(record.level) : '';
    final suffix = useColors ? _resetColor : '';

    buffer
      ..write('$prefix${record.level.label}$suffix')
      ..write(' ${record.message}');

    if (record.error != null) {
      buffer.write('\n  Error: ${record.error}');
    }

    return buffer.toString();
  }

  static String _colorForLevel(LogLevel level) => switch (level) {
    LogLevel.trace => '\x1B[37m',
    LogLevel.debug => '\x1B[36m',
    LogLevel.info => '\x1B[32m',
    LogLevel.warning => '\x1B[33m',
    LogLevel.error => '\x1B[31m',
    LogLevel.fatal => '\x1B[35m',
  };

  static const _resetColor = '\x1B[0m';

  static int _mapLevel(LogLevel level) => switch (level) {
    LogLevel.trace => 300,
    LogLevel.debug => 500,
    LogLevel.info => 800,
    LogLevel.warning => 900,
    LogLevel.error => 1000,
    LogLevel.fatal => 1200,
  };
}

/// Collects log records in memory. Useful for testing.
class MemoryLogOutput extends LogOutput {
  /// All log records written to this output.
  final List<LogRecord> records = [];

  @override
  void write(LogRecord record) {
    records.add(record);
  }

  /// Clears all recorded logs.
  void clear() => records.clear();
}

/// Forwards logs to multiple outputs.
class MultiLogOutput extends LogOutput {
  /// Creates a [MultiLogOutput] that writes to all [outputs].
  MultiLogOutput(this.outputs);

  /// The list of outputs to write to.
  final List<LogOutput> outputs;

  @override
  void write(LogRecord record) {
    for (final output in outputs) {
      output.write(record);
    }
  }

  @override
  void dispose() {
    for (final output in outputs) {
      output.dispose();
    }
  }
}

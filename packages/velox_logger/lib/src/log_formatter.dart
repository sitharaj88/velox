import 'dart:convert';

import 'package:velox_logger/src/log_record.dart';

/// Abstraction for formatting log records into strings.
///
/// Implementations control how log messages appear in output.
///
/// ```dart
/// final formatter = SimpleLogFormatter();
/// final formatted = formatter.format(record);
/// ```
abstract class VeloxLogFormatter {
  /// Formats a [LogRecord] into a string representation.
  String format(LogRecord record);
}

/// A simple formatter that outputs `[LEVEL] tag: message`.
///
/// ```dart
/// final formatter = SimpleLogFormatter();
/// // Output: [INFO] AuthService: User logged in
/// ```
class SimpleLogFormatter extends VeloxLogFormatter {
  /// Creates a [SimpleLogFormatter].
  SimpleLogFormatter();

  @override
  String format(LogRecord record) {
    final buffer = StringBuffer()..write('[${record.level.label}]');

    if (record.tag != null) {
      buffer.write(' ${record.tag}:');
    }

    buffer.write(' ${record.message}');

    if (record.error != null) {
      buffer.write(' | Error: ${record.error}');
    }

    if (record.stackTrace != null) {
      buffer.write('\n${record.stackTrace}');
    }

    return buffer.toString();
  }
}

/// A pretty formatter that outputs a box-style log with timestamp, tag,
/// message, and optional stack trace, indented for readability.
///
/// ```dart
/// final formatter = PrettyLogFormatter();
/// // Output:
/// // ┌───────────────────────────────────────────
/// // │ 2026-01-15T10:30:00.000 │ INFO │ AuthService
/// // ├───────────────────────────────────────────
/// // │ User logged in
/// // └───────────────────────────────────────────
/// ```
class PrettyLogFormatter extends VeloxLogFormatter {
  /// Creates a [PrettyLogFormatter].
  ///
  /// - [lineWidth] controls the width of the box border lines.
  PrettyLogFormatter({this.lineWidth = 80});

  /// The width of horizontal border lines.
  final int lineWidth;

  static const _topLeft = '\u250C';
  static const _bottomLeft = '\u2514';
  static const _middleLeft = '\u251C';
  static const _vertical = '\u2502';
  static const _horizontal = '\u2500';

  @override
  String format(LogRecord record) {
    final border = _horizontal * lineWidth;
    final buffer = StringBuffer()
      // Top border
      ..writeln('$_topLeft$border')
      // Header line: timestamp | level | tag
      ..write('$_vertical ${record.timestamp.toIso8601String()}'
          ' $_vertical ${record.level.label}');

    if (record.tag != null) {
      buffer.write(' $_vertical ${record.tag}');
    }

    buffer
      ..writeln()
      // Separator
      ..writeln('$_middleLeft$border');

    // Message
    for (final line in record.message.split('\n')) {
      buffer.writeln('$_vertical $line');
    }

    // Error
    if (record.error != null) {
      buffer
        ..writeln('$_middleLeft$border')
        ..writeln('$_vertical Error: ${record.error}');
    }

    // Stack trace
    if (record.stackTrace != null) {
      buffer.writeln('$_middleLeft$border');
      for (final line in record.stackTrace.toString().split('\n')) {
        if (line.trim().isNotEmpty) {
          buffer.writeln('$_vertical $line');
        }
      }
    }

    // Bottom border
    buffer.write('$_bottomLeft$border');

    return buffer.toString();
  }
}

/// A JSON formatter that outputs structured JSON for log aggregation systems.
///
/// ```dart
/// final formatter = JsonLogFormatter();
/// // Output: {"timestamp":"2026-01-15T10:30:00.000","level":"INFO",...}
/// ```
class JsonLogFormatter extends VeloxLogFormatter {
  /// Creates a [JsonLogFormatter].
  ///
  /// If [prettyPrint] is true, the JSON output is indented for readability.
  JsonLogFormatter({this.prettyPrint = false});

  /// Whether to indent JSON output.
  final bool prettyPrint;

  @override
  String format(LogRecord record) {
    final map = <String, Object?>{
      'timestamp': record.timestamp.toIso8601String(),
      'level': record.level.label,
      if (record.tag != null) 'tag': record.tag,
      'message': record.message,
      if (record.error != null) 'error': record.error.toString(),
      if (record.stackTrace != null)
        'stackTrace': record.stackTrace.toString(),
    };

    if (prettyPrint) {
      return const JsonEncoder.withIndent('  ').convert(map);
    }
    return jsonEncode(map);
  }
}

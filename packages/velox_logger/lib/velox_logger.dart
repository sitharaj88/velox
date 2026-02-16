/// A structured logging system for Flutter applications.
///
/// Provides:
/// - Multiple log levels (trace, debug, info, warning, error, fatal)
/// - Tagged output for filtering
/// - Pluggable log outputs (console, custom)
/// - Pluggable formatters (simple, pretty, JSON)
/// - Pluggable sinks (console, callback, composite, buffered)
/// - Configurable filters (level, tag, composite)
/// - In-memory log history with circular buffer and live stream
/// - Pretty console formatting with colors
/// - Log filtering by level and tag
library;

export 'src/log_filter.dart';
export 'src/log_formatter.dart';
export 'src/log_history.dart';
export 'src/log_level.dart';
export 'src/log_output.dart';
export 'src/log_record.dart';
export 'src/log_sink.dart';
export 'src/velox_logger.dart';

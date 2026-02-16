/// A structured logging system for Flutter applications.
///
/// Provides:
/// - Multiple log levels (trace, debug, info, warning, error, fatal)
/// - Tagged output for filtering
/// - Pluggable log outputs (console, custom)
/// - Pretty console formatting with colors
/// - Log filtering by level and tag
library;

export 'src/log_level.dart';
export 'src/log_output.dart';
export 'src/log_record.dart';
export 'src/velox_logger.dart';

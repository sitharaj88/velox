/// Log severity levels, ordered from least to most severe.
enum LogLevel implements Comparable<LogLevel> {
  /// Very detailed diagnostic information.
  trace(0, 'TRACE'),

  /// Diagnostic information useful during development.
  debug(1, 'DEBUG'),

  /// General informational messages.
  info(2, 'INFO'),

  /// Potentially harmful situations.
  warning(3, 'WARN'),

  /// Error events that might still allow the application to continue.
  error(4, 'ERROR'),

  /// Very severe error events that will likely lead the application to abort.
  fatal(5, 'FATAL');

  const LogLevel(this.value, this.label);

  /// Numeric value for comparison.
  final int value;

  /// Short label for display.
  final String label;

  @override
  int compareTo(LogLevel other) => value.compareTo(other.value);

  /// Returns `true` if this level is at least as severe as [other].
  bool operator >=(LogLevel other) => value >= other.value;

  /// Returns `true` if this level is more severe than [other].
  bool operator >(LogLevel other) => value > other.value;

  /// Returns `true` if this level is less severe than [other].
  bool operator <(LogLevel other) => value < other.value;

  /// Returns `true` if this level is at most as severe as [other].
  bool operator <=(LogLevel other) => value <= other.value;
}

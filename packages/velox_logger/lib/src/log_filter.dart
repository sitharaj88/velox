import 'package:velox_logger/src/log_level.dart';
import 'package:velox_logger/src/log_record.dart';

/// Abstraction for filtering log records before they reach outputs.
///
/// Return `true` from [shouldLog] to allow the record through,
/// or `false` to suppress it.
///
/// ```dart
/// final filter = LevelFilter(LogLevel.warning);
/// filter.shouldLog(record); // true if record.level >= warning
/// ```
abstract class VeloxLogFilter {
  /// Returns `true` if the given [record] should be logged.
  bool shouldLog(LogRecord record);
}

/// A filter that passes records at or above a minimum [LogLevel].
///
/// ```dart
/// final filter = LevelFilter(LogLevel.warning);
/// // Only warning, error, and fatal records pass through.
/// ```
class LevelFilter extends VeloxLogFilter {
  /// Creates a [LevelFilter] with the given [minLevel].
  LevelFilter(this.minLevel);

  /// The minimum severity level required for a record to pass.
  final LogLevel minLevel;

  @override
  bool shouldLog(LogRecord record) => record.level >= minLevel;
}

/// A filter that allows or blocks records based on their tag.
///
/// Use [allowedTags] to whitelist specific tags (only matching tags pass).
/// Use [blockedTags] to blacklist specific tags (matching tags are blocked).
///
/// If both are provided, [allowedTags] takes precedence: a record must
/// have a tag in [allowedTags] AND not in [blockedTags].
///
/// Records with no tag are allowed unless [requireTag] is true.
///
/// ```dart
/// final filter = TagFilter(allowedTags: {'AuthService', 'Database'});
/// ```
class TagFilter extends VeloxLogFilter {
  /// Creates a [TagFilter].
  ///
  /// - [allowedTags] if non-null, only records with these tags pass.
  /// - [blockedTags] if non-null, records with these tags are blocked.
  /// - [requireTag] if true, records without a tag are blocked.
  TagFilter({
    this.allowedTags,
    this.blockedTags,
    this.requireTag = false,
  });

  /// If non-null, only records with a tag in this set are allowed.
  final Set<String>? allowedTags;

  /// If non-null, records with a tag in this set are blocked.
  final Set<String>? blockedTags;

  /// If true, records without a tag are blocked.
  final bool requireTag;

  @override
  bool shouldLog(LogRecord record) {
    final tag = record.tag;

    if (tag == null) {
      return !requireTag;
    }

    if (blockedTags != null && blockedTags!.contains(tag)) {
      return false;
    }

    if (allowedTags != null) {
      return allowedTags!.contains(tag);
    }

    return true;
  }
}

/// A filter that combines multiple filters with AND logic.
///
/// A record passes only if ALL child filters allow it.
///
/// ```dart
/// final filter = CompositeFilter([
///   LevelFilter(LogLevel.info),
///   TagFilter(blockedTags: {'Verbose'}),
/// ]);
/// ```
class CompositeFilter extends VeloxLogFilter {
  /// Creates a [CompositeFilter] that requires all [filters] to pass.
  CompositeFilter(this.filters);

  /// The list of filters that must all return `true`.
  final List<VeloxLogFilter> filters;

  @override
  bool shouldLog(LogRecord record) {
    for (final filter in filters) {
      if (!filter.shouldLog(record)) {
        return false;
      }
    }
    return true;
  }
}

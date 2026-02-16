import 'dart:async';

import 'package:velox_logger/src/log_level.dart';
import 'package:velox_logger/src/log_record.dart';

/// A circular buffer that stores recent log records in memory.
///
/// Provides query capabilities and a live stream of new records.
/// When the buffer reaches [maxSize], the oldest records are discarded.
///
/// ```dart
/// final history = VeloxLogHistory(maxSize: 500);
/// // ... logs are added via VeloxLogger ...
/// final errors = history.where(minLevel: LogLevel.error);
/// ```
class VeloxLogHistory {
  /// Creates a [VeloxLogHistory] with the given [maxSize].
  ///
  /// The default [maxSize] is 1000 records.
  VeloxLogHistory({this.maxSize = 1000});

  /// The maximum number of records to retain in the buffer.
  final int maxSize;

  final List<LogRecord> _records = [];
  final StreamController<LogRecord> _controller =
      StreamController<LogRecord>.broadcast();

  /// Returns all records currently in the buffer.
  ///
  /// The returned list is a copy and is safe to modify.
  List<LogRecord> get records => List<LogRecord>.unmodifiable(_records);

  /// Returns a live stream of new log records as they are added.
  ///
  /// This is a broadcast stream; multiple listeners are supported.
  Stream<LogRecord> get onRecord => _controller.stream;

  /// Adds a [record] to the history buffer.
  ///
  /// If the buffer is full, the oldest record is removed first.
  void add(LogRecord record) {
    if (_records.length >= maxSize) {
      _records.removeAt(0);
    }
    _records.add(record);
    _controller.add(record);
  }

  /// Returns records matching the given criteria.
  ///
  /// - [minLevel] filters to records at or above this severity.
  /// - [tag] filters to records with this exact tag.
  List<LogRecord> where({LogLevel? minLevel, String? tag}) =>
      _records.where((record) {
      if (minLevel != null && record.level < minLevel) {
        return false;
      }
      if (tag != null && record.tag != tag) {
        return false;
      }
      return true;
    }).toList();

  /// Removes all records from the buffer.
  void clear() {
    _records.clear();
  }

  /// Disposes of the history, closing the stream controller.
  ///
  /// After calling [dispose], no more records can be added.
  Future<void> dispose() async {
    await _controller.close();
  }
}

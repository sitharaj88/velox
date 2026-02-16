/// Tracks read/write counts, hit/miss rates, and storage size estimates.
///
/// ```dart
/// final stats = storage.statistics;
/// print('Reads: ${stats.readCount}');
/// print('Hit rate: ${stats.hitRate}');
/// ```
class StorageStatistics {
  int _readCount = 0;
  int _writeCount = 0;
  int _removeCount = 0;
  int _hitCount = 0;
  int _missCount = 0;
  int _clearCount = 0;

  /// Total number of read operations.
  int get readCount => _readCount;

  /// Total number of write operations.
  int get writeCount => _writeCount;

  /// Total number of remove operations.
  int get removeCount => _removeCount;

  /// Number of reads that found a value (hits).
  int get hitCount => _hitCount;

  /// Number of reads that did not find a value (misses).
  int get missCount => _missCount;

  /// Number of clear operations.
  int get clearCount => _clearCount;

  /// The cache hit rate as a value between 0.0 and 1.0.
  ///
  /// Returns 0.0 if no reads have been performed.
  double get hitRate {
    if (_readCount == 0) return 0;
    return _hitCount / _readCount;
  }

  /// The cache miss rate as a value between 0.0 and 1.0.
  ///
  /// Returns 0.0 if no reads have been performed.
  double get missRate {
    if (_readCount == 0) return 0;
    return _missCount / _readCount;
  }

  /// Total number of all operations.
  int get totalOperations => _readCount + _writeCount + _removeCount + _clearCount;

  /// Records a read operation.
  ///
  /// [hit] indicates whether the read found a value.
  void recordRead({required bool hit}) {
    _readCount++;
    if (hit) {
      _hitCount++;
    } else {
      _missCount++;
    }
  }

  /// Records a write operation.
  void recordWrite() {
    _writeCount++;
  }

  /// Records a remove operation.
  void recordRemove() {
    _removeCount++;
  }

  /// Records a clear operation.
  void recordClear() {
    _clearCount++;
  }

  /// Resets all counters to zero.
  void reset() {
    _readCount = 0;
    _writeCount = 0;
    _removeCount = 0;
    _hitCount = 0;
    _missCount = 0;
    _clearCount = 0;
  }

  @override
  String toString() =>
      'StorageStatistics(reads: $_readCount, writes: $_writeCount, '
      'removes: $_removeCount, clears: $_clearCount, '
      'hits: $_hitCount, misses: $_missCount, hitRate: ${hitRate.toStringAsFixed(2)})';
}

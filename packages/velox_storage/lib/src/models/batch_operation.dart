/// Represents a single operation within a batch.
///
/// A batch operation can be either a [write] or a [remove].
sealed class BatchOperation {
  const BatchOperation();

  /// Creates a write operation.
  const factory BatchOperation.write({
    required String key,
    required String value,
  }) = BatchWrite;

  /// Creates a remove operation.
  const factory BatchOperation.remove({required String key}) = BatchRemove;
}

/// A write operation within a batch.
class BatchWrite extends BatchOperation {
  /// Creates a [BatchWrite] operation.
  const BatchWrite({required this.key, required this.value});

  /// The key to write.
  final String key;

  /// The value to write.
  final String value;

  @override
  String toString() => 'BatchWrite($key: $value)';
}

/// A remove operation within a batch.
class BatchRemove extends BatchOperation {
  /// Creates a [BatchRemove] operation.
  const BatchRemove({required this.key});

  /// The key to remove.
  final String key;

  @override
  String toString() => 'BatchRemove($key)';
}

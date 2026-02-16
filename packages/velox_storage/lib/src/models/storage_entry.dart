/// Represents a storage change event.
class StorageEntry {
  /// Creates a [StorageEntry].
  const StorageEntry({
    required this.key,
    this.value,
  });

  /// The storage key.
  final String key;

  /// The value (null if removed).
  final String? value;

  /// Returns `true` if this entry represents a deletion.
  bool get isRemoval => value == null;

  @override
  String toString() => 'StorageEntry($key: $value)';
}

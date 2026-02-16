/// A cached value with metadata.
class CacheEntry<T> {
  /// Creates a [CacheEntry].
  CacheEntry({
    required this.key,
    required this.value,
    required this.createdAt,
    this.expiresAt,
  }) : _lastAccessedAt = createdAt;

  /// The cache key.
  final String key;

  /// The cached value.
  final T value;

  /// When this entry was created.
  final DateTime createdAt;

  /// When this entry expires (null = never).
  final DateTime? expiresAt;

  DateTime _lastAccessedAt;

  /// When this entry was last accessed.
  DateTime get lastAccessedAt => _lastAccessedAt;

  /// Returns `true` if this entry has expired.
  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// Returns `true` if this entry is still valid.
  bool get isValid => !isExpired;

  /// Marks this entry as accessed.
  void touch() {
    _lastAccessedAt = DateTime.now();
  }

  @override
  String toString() => 'CacheEntry($key: $value, expired: $isExpired)';
}

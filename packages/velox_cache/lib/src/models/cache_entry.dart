/// A cached value with metadata.
///
/// Tracks creation time, last access time, access count, and optional tags
/// for group-based invalidation.
class CacheEntry<T> {
  /// Creates a [CacheEntry].
  CacheEntry({
    required this.key,
    required this.value,
    required this.createdAt,
    this.expiresAt,
    Set<String>? tags,
  })  : _lastAccessedAt = createdAt,
        _accessCount = 0,
        _tags = tags ?? {};

  /// The cache key.
  final String key;

  /// The cached value.
  final T value;

  /// When this entry was created.
  final DateTime createdAt;

  /// When this entry expires (null = never).
  final DateTime? expiresAt;

  DateTime _lastAccessedAt;
  int _accessCount;
  final Set<String> _tags;

  /// When this entry was last accessed.
  DateTime get lastAccessedAt => _lastAccessedAt;

  /// Number of times this entry has been accessed.
  int get accessCount => _accessCount;

  /// Tags associated with this entry for group-based invalidation.
  Set<String> get tags => Set.unmodifiable(_tags);

  /// Returns `true` if this entry has expired.
  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// Returns `true` if this entry is still valid.
  bool get isValid => !isExpired;

  /// Returns `true` if this entry is tagged with [tag].
  bool hasTag(String tag) => _tags.contains(tag);

  /// Returns `true` if this entry has any of the given [queryTags].
  bool hasAnyTag(Set<String> queryTags) =>
      _tags.any(queryTags.contains);

  /// Marks this entry as accessed, updating last access time and count.
  void touch() {
    _lastAccessedAt = DateTime.now();
    _accessCount++;
  }

  @override
  String toString() =>
      'CacheEntry($key: $value, expired: $isExpired, '
      'accessCount: $_accessCount, tags: $_tags)';
}

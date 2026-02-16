/// An intelligent caching layer for Flutter applications.
///
/// Provides:
/// - LRU (Least Recently Used) cache with configurable max size
/// - TTL (Time To Live) based expiration
/// - Reactive cache change streams
/// - Typed cache access
library;

export 'src/models/cache_entry.dart';
export 'src/strategies/lru_cache.dart';
export 'src/strategies/ttl_cache.dart';
export 'src/velox_cache.dart';

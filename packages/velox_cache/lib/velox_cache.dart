/// An intelligent caching layer for Dart applications.
///
/// Provides:
/// - LRU (Least Recently Used) cache with configurable max size
/// - LFU (Least Frequently Used) cache as an alternative strategy
/// - TTL (Time To Live) based expiration
/// - Write-through cache backed by persistent storage
/// - Multi-level cache (L1 memory + L2 storage) with cascading reads
/// - Cache statistics (hits, misses, evictions, hit rate)
/// - Tag-based grouping and invalidation
/// - Bulk operations (putAll, getAll, removeAll)
/// - Cache loader pattern (getOrLoad)
/// - Stale-while-revalidate pattern
/// - Reactive cache change streams with rich event types
/// - Cache entry metadata (creation time, access count, tags)
library;

export 'src/models/cache_entry.dart';
export 'src/models/cache_stats.dart';
export 'src/strategies/lfu_cache.dart';
export 'src/strategies/lru_cache.dart';
export 'src/strategies/multi_level_cache.dart';
export 'src/strategies/ttl_cache.dart';
export 'src/strategies/write_through_cache.dart';
export 'src/velox_cache.dart';

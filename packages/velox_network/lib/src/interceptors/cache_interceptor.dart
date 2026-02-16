import 'package:velox_network/src/interceptors/velox_interceptor.dart';
import 'package:velox_network/src/models/velox_request.dart';
import 'package:velox_network/src/models/velox_response.dart';

/// A function that generates a cache key from a request.
typedef CacheKeyStrategy = String Function(VeloxRequest request);

/// An entry in the response cache with metadata.
class CacheEntry {
  /// Creates a [CacheEntry].
  CacheEntry({
    required this.response,
    required this.cachedAt,
    required this.ttl,
  });

  /// The cached response.
  final VeloxResponse<dynamic> response;

  /// When the entry was cached.
  final DateTime cachedAt;

  /// How long the entry is valid.
  final Duration ttl;

  /// Whether this entry has expired.
  bool get isExpired => DateTime.now().difference(cachedAt) >= ttl;
}

/// An interceptor that caches GET responses with configurable TTL
/// and cache key strategy.
///
/// Only caches successful GET responses (2xx status codes). The cache
/// can be cleared manually or entries expire automatically based on TTL.
///
/// ```dart
/// final cacheInterceptor = VeloxCacheInterceptor(
///   ttl: Duration(minutes: 5),
///   maxEntries: 100,
/// );
///
/// final client = VeloxHttpClient(
///   config: VeloxNetworkConfig(
///     baseUrl: 'https://api.example.com',
///     interceptors: [cacheInterceptor],
///   ),
/// );
/// ```
class VeloxCacheInterceptor extends VeloxInterceptor {
  /// Creates a [VeloxCacheInterceptor].
  ///
  /// [ttl] is the time-to-live for cache entries.
  /// [maxEntries] limits the cache size (oldest entries are evicted first).
  /// [cacheKeyStrategy] customizes how cache keys are generated.
  VeloxCacheInterceptor({
    required this.ttl,
    this.maxEntries = 100,
    CacheKeyStrategy? cacheKeyStrategy,
  }) : cacheKeyStrategy = cacheKeyStrategy ?? _defaultCacheKey;

  /// Time-to-live for cache entries.
  final Duration ttl;

  /// Maximum number of entries in the cache.
  final int maxEntries;

  /// Strategy for generating cache keys from requests.
  final CacheKeyStrategy cacheKeyStrategy;

  final Map<String, CacheEntry> _cache = {};

  /// The current number of entries in the cache.
  int get size => _cache.length;

  /// Extra key used to signal a cache hit in the response.
  static const String cacheHitKey = 'x-velox-cache-hit';

  static String _defaultCacheKey(VeloxRequest request) {
    final queryString = request.queryParameters.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    return '${request.method.name}:${request.path}'
        '${queryString.isNotEmpty ? '?$queryString' : ''}';
  }

  @override
  Future<VeloxRequest> onRequest(VeloxRequest request) async {
    // Only cache GET requests
    if (request.method != HttpMethod.get) return request;

    // Check for forced skip
    if (request.extra['skipCache'] == true) return request;

    final key = cacheKeyStrategy(request);
    final entry = _cache[key];

    if (entry != null && !entry.isExpired) {
      // Return a request with a cache-hit marker so we can intercept
      // in onResponse. Store the cached response in extra.
      return request.copyWith(
        extra: {
          ...request.extra,
          '_cachedResponse': entry.response,
          '_cacheHit': true,
        },
      );
    }

    // Remove expired entry if present
    if (entry != null && entry.isExpired) {
      _cache.remove(key);
    }

    return request;
  }

  @override
  Future<VeloxResponse<dynamic>> onResponse(
    VeloxResponse<dynamic> response,
  ) async {
    // If we have a cached response, return it
    final cachedResponse =
        response.request.extra['_cachedResponse'] as VeloxResponse<dynamic>?;
    if (cachedResponse != null) {
      return cachedResponse;
    }

    // Only cache successful GET responses
    if (response.request.method == HttpMethod.get &&
        response.statusCode >= 200 &&
        response.statusCode < 300) {
      final key = cacheKeyStrategy(response.request);
      _cacheResponse(key, response);
    }

    return response;
  }

  void _cacheResponse(String key, VeloxResponse<dynamic> response) {
    // Evict oldest entries if at capacity
    while (_cache.length >= maxEntries) {
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
    }

    _cache[key] = CacheEntry(
      response: response,
      cachedAt: DateTime.now(),
      ttl: ttl,
    );
  }

  /// Retrieves a cached response by [key], or `null` if not found or expired.
  VeloxResponse<dynamic>? getCachedResponse(String key) {
    final entry = _cache[key];
    if (entry == null || entry.isExpired) {
      if (entry != null) _cache.remove(key);
      return null;
    }
    return entry.response;
  }

  /// Clears all cached entries.
  void clearCache() => _cache.clear();

  /// Removes a single cached entry by [key].
  void evict(String key) => _cache.remove(key);

  /// Removes all expired entries from the cache.
  void evictExpired() {
    _cache.removeWhere((_, entry) => entry.isExpired);
  }
}

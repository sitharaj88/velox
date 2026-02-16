// ignore_for_file: avoid_print
import 'package:velox_cache/velox_cache.dart';

void main() {
  // LRU Cache
  final lruCache = LruCache<String>(maxSize: 3);
  lruCache
    ..put('a', 'alpha')
    ..put('b', 'beta')
    ..put('c', 'gamma');
  print('LRU: ${lruCache.get('a')}'); // alpha

  // TTL Cache
  final ttlCache = TtlCache<String>(defaultTtl: const Duration(minutes: 5));
  ttlCache.put('token', 'abc123');
  print('TTL: ${ttlCache.get('token')}'); // abc123

  // Combined Cache with events
  final cache = VeloxCache<String>(
    maxSize: 100,
    defaultTtl: const Duration(minutes: 5),
  );

  cache.onChange.listen((event) {
    print('Cache event: ${event.type} ${event.key}');
  });

  cache.put('user:1', 'John');
  final value = cache.getOrPut('user:2', () => 'Jane');
  print('Computed: $value');

  cache.dispose();
}

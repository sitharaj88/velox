# velox_cache

[![pub.dev](https://img.shields.io/pub/v/velox_cache.svg)](https://pub.dev/packages/velox_cache)
[![style: velox lint](https://img.shields.io/badge/style-velox__lint-blue.svg)](https://pub.dev/packages/velox_lint)

An intelligent caching layer for Flutter with LRU eviction, TTL expiration, and reactive cache streams.

## Features

- LRU (Least Recently Used) eviction
- TTL (Time To Live) expiration
- Combined LRU + TTL cache (VeloxCache)
- Reactive change streams
- getOrPut / getOrPutAsync for compute-if-absent
- Zero external dependencies

## Usage

```dart
import 'package:velox_cache/velox_cache.dart';

final cache = VeloxCache<String>(
  maxSize: 100,
  defaultTtl: Duration(minutes: 5),
);

cache.put('user:1', 'John');
final user = cache.get('user:1'); // 'John'

// Compute if absent
final data = await cache.getOrPutAsync(
  'expensive',
  () async => fetchFromNetwork(),
);

// Listen for changes
cache.onChange.listen((event) {
  print('${event.type}: ${event.key}');
});
```

## Part of the Velox Collection

This package is part of the [Velox](https://github.com/velox-flutter/velox) Flutter plugin collection.

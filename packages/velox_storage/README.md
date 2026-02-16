# velox_storage

[![pub.dev](https://img.shields.io/pub/v/velox_storage.svg)](https://pub.dev/packages/velox_storage)
[![style: velox lint](https://img.shields.io/badge/style-velox__lint-blue.svg)](https://pub.dev/packages/velox_lint)

A local persistence layer for Flutter with type-safe key-value storage and pluggable adapters.

## Features

- Type-safe access: getString, getInt, getDouble, getBool, getJson
- Pluggable storage adapters (memory, custom)
- Reactive change notifications via streams
- Result-based error handling with getOrFail
- Batch operations

## Usage

```dart
import 'package:velox_storage/velox_storage.dart';

final storage = VeloxStorage(adapter: MemoryStorageAdapter());

await storage.setString('name', 'John');
await storage.setInt('age', 25);
await storage.setJson('user', {'role': 'admin'});

final name = await storage.getString('name'); // 'John'

// Reactive
storage.onChange.listen((entry) {
  print('${entry.key} changed');
});
```

## Part of the Velox Collection

This package is part of the [Velox](https://github.com/velox-flutter/velox) Flutter plugin collection.

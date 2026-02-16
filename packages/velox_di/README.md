# velox_di

[![pub.dev](https://img.shields.io/pub/v/velox_di.svg)](https://pub.dev/packages/velox_di)
[![coverage](https://codecov.io/gh/velox-flutter/velox/branch/main/graph/badge.svg?flag=velox_di)](https://codecov.io/gh/velox-flutter/velox)
[![style: velox lint](https://img.shields.io/badge/style-velox__lint-blue.svg)](https://pub.dev/packages/velox_lint)
[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](https://opensource.org/licenses/MIT)

Compile-time safe dependency injection container for the Velox Flutter plugin collection. Supports singletons, factories, lazy registration, scoped containers, and modular grouping with **zero configuration**.

## Features

- **Singleton** -- register a pre-created instance
- **Lazy singleton** -- create on first access, then cache
- **Factory** -- new instance on every resolution
- **Scoped containers** -- child containers that fall back to a parent
- **Modules** -- group related registrations together
- **Disposable** -- automatic cleanup of resources

## Getting Started

```yaml
dependencies:
  velox_di: ^0.1.0
```

## Usage

### Basic Registration and Resolution

```dart
import 'package:velox_di/velox_di.dart';

final container = VeloxContainer();

// Singleton -- same instance every time
container.registerSingleton<Logger>(ConsoleLogger());

// Lazy singleton -- created on first access
container.registerLazy<Database>(() => SqliteDatabase());

// Factory -- new instance every time
container.registerFactory<HttpClient>(() => HttpClient());

// Resolve
final logger = container.get<Logger>();
final db = container.get<Database>();
```

### Safe Resolution

```dart
// Returns null instead of throwing
final logger = container.getOrNull<Logger>();

// Check before resolving
if (container.has<Logger>()) {
  container.get<Logger>().log('ready');
}
```

### Modules

```dart
class AuthModule extends VeloxModule {
  @override
  void register(VeloxContainer container) {
    container.registerLazy<AuthService>(() => AuthServiceImpl());
    container.registerFactory<LoginUseCase>(
      () => LoginUseCase(container.get<AuthService>()),
    );
  }
}

final container = VeloxContainer();
AuthModule().register(container);
```

### Scoped Containers

```dart
final root = VeloxContainer()
  ..registerSingleton<Logger>(ConsoleLogger())
  ..registerSingleton<Theme>(LightTheme());

final scope = root.createScope()
  ..registerSingleton<Theme>(DarkTheme());

scope.get<Logger>(); // ConsoleLogger (from parent)
scope.get<Theme>();  // DarkTheme      (overridden)
```

### Cleanup

```dart
// Dispose all Disposable singletons and clear registrations
container.dispose();

// Or just clear registrations without disposing
container.reset();
```

## Part of the Velox Collection

This package is part of the [Velox](https://github.com/velox-flutter/velox) Flutter plugin collection.

# velox_logger

[![pub.dev](https://img.shields.io/pub/v/velox_logger.svg)](https://pub.dev/packages/velox_logger)
[![style: velox lint](https://img.shields.io/badge/style-velox__lint-blue.svg)](https://pub.dev/packages/velox_lint)

A structured logging system for Flutter with log levels, tagged output, and pluggable destinations.

## Features

- Six log levels: trace, debug, info, warning, error, fatal
- Tagged output for filtering by component
- Pluggable output system (console, memory, multi)
- Pretty console formatting with ANSI colors
- Child loggers with inherited configuration
- Zero Flutter dependencies (pure Dart)

## Usage

```dart
import 'package:velox_logger/velox_logger.dart';

final logger = VeloxLogger(tag: 'AuthService');

logger.info('User logged in');
logger.error('Login failed', error: exception, stackTrace: trace);

// Child logger
final childLogger = logger.child('OAuth');
childLogger.debug('Token refreshed'); // tag: AuthService.OAuth
```

## Part of the Velox Collection

This package is part of the [Velox](https://github.com/velox-flutter/velox) Flutter plugin collection.

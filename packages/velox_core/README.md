# velox_core

[![pub.dev](https://img.shields.io/pub/v/velox_core.svg)](https://pub.dev/packages/velox_core)
[![coverage](https://codecov.io/gh/velox-flutter/velox/branch/main/graph/badge.svg?flag=velox_core)](https://codecov.io/gh/velox-flutter/velox)
[![style: velox lint](https://img.shields.io/badge/style-velox__lint-blue.svg)](https://pub.dev/packages/velox_lint)
[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](https://opensource.org/licenses/MIT)

Foundation package for the Velox Flutter plugin collection. Provides Result types, exception hierarchy, and common extensions with **zero third-party dependencies**.

## Features

- **Result type** - Type-safe error handling without exceptions
- **Exception hierarchy** - Structured exceptions for all Velox packages
- **String extensions** - Case conversion, validation, truncation
- **Iterable extensions** - groupBy, chunked, distinctBy, sortedBy
- **DateTime extensions** - isToday, dateOnly, daysInMonth, age
- **Num extensions** - Duration literals, range checks, ordinals

## Getting Started

```yaml
dependencies:
  velox_core: ^0.1.0
```

## Usage

### Result Type

```dart
import 'package:velox_core/velox_core.dart';

Result<User, VeloxException> fetchUser(int id) {
  try {
    final user = api.getUser(id);
    return Success(user);
  } catch (e) {
    return Failure(VeloxException(message: e.toString()));
  }
}

// Pattern matching
final result = fetchUser(1);
result.when(
  success: (user) => print(user.name),
  failure: (error) => print(error.message),
);

// Chaining
final name = fetchUser(1)
    .map((user) => user.name)
    .getOrDefault('Unknown');
```

### Extensions

```dart
// String
'hello world'.capitalized;    // 'Hello world'
'helloWorld'.toSnakeCase;     // 'hello_world'
'test@email.com'.isEmail;    // true

// Iterable
[1, 2, 3, 4, 5].chunked(2); // [[1, 2], [3, 4], [5]]
users.groupBy((u) => u.role); // {admin: [...], user: [...]}
users.sortedBy((u) => u.name);

// Num
30.seconds;                   // Duration(seconds: 30)
5.isBetween(1, 10);          // true
3.ordinal;                    // '3rd'
```

## Part of the Velox Collection

This package is part of the [Velox](https://github.com/velox-flutter/velox) Flutter plugin collection.

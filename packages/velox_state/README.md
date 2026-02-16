# velox_state

[![pub.dev](https://img.shields.io/pub/v/velox_state.svg)](https://pub.dev/packages/velox_state)
[![coverage](https://codecov.io/gh/velox-flutter/velox/branch/main/graph/badge.svg?flag=velox_state)](https://codecov.io/gh/velox-flutter/velox)
[![style: velox lint](https://img.shields.io/badge/style-velox__lint-blue.svg)](https://pub.dev/packages/velox_lint)
[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](https://opensource.org/licenses/MIT)

A lightweight reactive state management solution for the Velox Flutter plugin collection. Provides notifiers, command pattern with undo/redo, and derived state selectors with **zero Flutter dependency**.

## Features

- **VeloxNotifier** - Reactive state holder with listener callbacks and streams
- **VeloxCommand** - Command pattern for encapsulating state transitions
- **VeloxCommandExecutor** - Undo/redo support via command history
- **VeloxSelector** - Derived state that only notifies when the selected value changes

## Getting Started

```yaml
dependencies:
  velox_state: ^0.1.0
```

## Usage

### VeloxNotifier

```dart
import 'package:velox_state/velox_state.dart';

final counter = VeloxNotifier<int>(0);

// Listen to changes
counter.addListener((state) => print('Counter: $state'));

// Update state
counter.setState(1);
counter.update((current) => current + 1);

// Stream-based listening
counter.stream.listen((state) => print('Stream: $state'));

// Cleanup
counter.dispose();
```

### VeloxCommand with Undo/Redo

```dart
class IncrementCommand extends VeloxCommand<int> {
  const IncrementCommand(this.amount);
  final int amount;

  @override
  int execute(int state) => state + amount;

  @override
  int undo(int state) => state - amount;
}

final notifier = VeloxNotifier<int>(0);
final executor = VeloxCommandExecutor<int>(notifier);

executor.execute(const IncrementCommand(5)); // state -> 5
executor.execute(const IncrementCommand(3)); // state -> 8
executor.undo();                              // state -> 5
executor.redo();                              // state -> 8
```

### VeloxSelector

```dart
final userNotifier = VeloxNotifier<User>(user);
final nameSelector = VeloxSelector<User, String>(
  source: userNotifier,
  selector: (user) => user.name,
);

// Only notified when the name actually changes
nameSelector.addListener((name) => print('Name: $name'));

// Changing age does not trigger the name selector
userNotifier.setState(user.copyWith(age: 31));
```

## Part of the Velox Collection

This package is part of the [Velox](https://github.com/velox-flutter/velox) Flutter plugin collection.

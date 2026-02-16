# velox_event_bus

[![pub.dev](https://img.shields.io/pub/v/velox_event_bus.svg)](https://pub.dev/packages/velox_event_bus)
[![coverage](https://codecov.io/gh/velox-flutter/velox/branch/main/graph/badge.svg?flag=velox_event_bus)](https://codecov.io/gh/velox-flutter/velox)
[![style: velox lint](https://img.shields.io/badge/style-velox__lint-blue.svg)](https://pub.dev/packages/velox_lint)
[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](https://opensource.org/licenses/MIT)

Typed event bus for the Velox Flutter plugin collection. Provides a lightweight, broadcast-based pub/sub system with type-safe subscriptions and **zero third-party dependencies** (beyond `velox_core` and `meta`).

## Features

- **Typed events** - Define events as classes extending `VeloxEvent`
- **Type-safe subscriptions** - Subscribe to specific event types with `on<T>()`
- **Broadcast-based** - Multiple listeners per event type
- **Subtype filtering** - Listening to a base type receives all subtypes
- **Subscription management** - Pause, resume, and cancel with `VeloxEventSubscription`
- **Batch dispatch** - Fire multiple events at once with `fireAll`

## Getting Started

```yaml
dependencies:
  velox_event_bus: ^0.1.0
```

## Usage

### Define Events

```dart
import 'package:velox_event_bus/velox_event_bus.dart';

class UserLoggedIn extends VeloxEvent {
  UserLoggedIn(this.userId);
  final String userId;
}

class OrderPlaced extends VeloxEvent {
  OrderPlaced(this.orderId, this.total);
  final String orderId;
  final double total;
}
```

### Subscribe and Fire

```dart
final bus = VeloxEventBus();

// Subscribe to a specific event type.
bus.on<UserLoggedIn>().listen((event) {
  print('User ${event.userId} logged in at ${event.timestamp}');
});

// Subscribe to all events.
bus.on<VeloxEvent>().listen((event) {
  print('Event: $event');
});

// Fire a single event.
bus.fire(UserLoggedIn('user-42'));

// Fire multiple events.
bus.fireAll([
  OrderPlaced('ord-1', 29.99),
  OrderPlaced('ord-2', 49.99),
]);
```

### Manage Subscriptions

```dart
final sub = bus.on<UserLoggedIn>().listen(handleLogin);
final handle = VeloxEventSubscription(sub);

// Pause / resume.
handle.pause();
handle.resume();

// Cancel when done.
await handle.cancel();
print(handle.isCancelled); // true
```

### Cleanup

```dart
await bus.dispose();
```

## Part of the Velox Collection

This package is part of the [Velox](https://github.com/velox-flutter/velox) Flutter plugin collection.

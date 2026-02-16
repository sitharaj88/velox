/// Typed event bus for the Velox Flutter plugin collection.
///
/// Provides:
/// - [VeloxEvent] base class for defining typed events
/// - [VeloxEventBus] for broadcasting and subscribing to events
/// - [VeloxEventSubscription] for managing listener lifecycle
/// - [EventHandler] for priority-based, filtered event handling
/// - [EventInterceptor] for middleware-style event transformation
/// - [ScopedEventBus] for hierarchical event scoping
library;

export 'src/event_handler.dart';
export 'src/event_interceptor.dart';
export 'src/event_subscription.dart';
export 'src/scoped_event_bus.dart';
export 'src/velox_event.dart';
export 'src/velox_event_bus.dart';

// ignore_for_file: avoid_print

import 'dart:async';

import 'package:velox_event_bus/velox_event_bus.dart';

// -- Define your events --

/// Fired when a user successfully logs in.
class UserLoggedIn extends VeloxEvent {
  /// Creates a [UserLoggedIn] event.
  UserLoggedIn(this.userId, this.email);

  /// The unique identifier of the user.
  final String userId;

  /// The email address used to log in.
  final String email;

  @override
  String toString() => 'UserLoggedIn(userId: $userId, email: $email)';
}

/// Fired when a user logs out.
class UserLoggedOut extends VeloxEvent {
  /// Creates a [UserLoggedOut] event.
  UserLoggedOut(this.userId);

  /// The unique identifier of the user.
  final String userId;

  @override
  String toString() => 'UserLoggedOut(userId: $userId)';
}

/// Fired when a new order is placed.
class OrderPlaced extends VeloxEvent {
  /// Creates an [OrderPlaced] event.
  OrderPlaced(this.orderId, this.total);

  /// The unique identifier of the order.
  final String orderId;

  /// The total amount of the order.
  final double total;

  @override
  String toString() => 'OrderPlaced(orderId: $orderId, total: $total)';
}

Future<void> main() async {
  // Create an event bus instance.
  final bus = VeloxEventBus();

  // Subscribe to login events.
  final loginSub = bus.on<UserLoggedIn>().listen((event) {
    print('[AUTH] ${event.email} logged in at ${event.timestamp}');
  });
  final loginHandle = VeloxEventSubscription(loginSub);

  // Subscribe to all events for logging.
  bus.on<VeloxEvent>().listen((event) {
    print('[LOG]  $event');
  });

  // Subscribe to order events.
  bus.on<OrderPlaced>().listen((event) {
    print('[SHOP] Order ${event.orderId}: \$${event.total}');
  });

  // Fire some events.
  print('--- Firing events ---');
  bus.fire(UserLoggedIn('u-42', 'alice@example.com'));
  bus.fire(OrderPlaced('ord-1', 29.99));

  // Fire multiple events at once.
  bus.fireAll([
    OrderPlaced('ord-2', 49.99),
    UserLoggedOut('u-42'),
  ]);

  // Let the event loop process all events.
  await Future<void>.delayed(Duration.zero);

  // Cancel the login subscription.
  print('\n--- Cancelling login subscription ---');
  await loginHandle.cancel();
  print('Login subscription cancelled: ${loginHandle.isCancelled}');

  // This login event will not be received by the login listener.
  bus.fire(UserLoggedIn('u-99', 'bob@example.com'));
  await Future<void>.delayed(Duration.zero);

  // Clean up.
  await bus.dispose();
  print('\n--- Event bus disposed ---');
}

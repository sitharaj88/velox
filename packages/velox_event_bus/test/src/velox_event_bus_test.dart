// ignore_for_file: cancel_subscriptions

import 'dart:async';

import 'package:test/test.dart';
import 'package:velox_event_bus/velox_event_bus.dart';

// ---- Test events ----

class _UserLoggedIn extends VeloxEvent {
  _UserLoggedIn(this.userId);
  final String userId;
}

class _UserLoggedOut extends VeloxEvent {
  _UserLoggedOut(this.userId);
  final String userId;
}

class _OrderPlaced extends VeloxEvent {
  _OrderPlaced(this.orderId, this.amount);
  final String orderId;
  final double amount;
}

class _BaseEvent extends VeloxEvent {}

class _ChildEvent extends _BaseEvent {}

void main() {
  group('VeloxEvent', () {
    test('has a timestamp set on creation', () {
      final before = DateTime.now();
      final event = _UserLoggedIn('u1');
      final after = DateTime.now();

      expect(
        event.timestamp.isAfter(
          before.subtract(const Duration(milliseconds: 1)),
        ),
        isTrue,
      );
      expect(
        event.timestamp.isBefore(
          after.add(const Duration(milliseconds: 1)),
        ),
        isTrue,
      );
    });

    test('toString includes runtime type and timestamp', () {
      final event = _UserLoggedIn('u1');
      final result = event.toString();

      expect(result, contains('_UserLoggedIn'));
      expect(result, contains('timestamp:'));
    });
  });

  group('VeloxEventBus', () {
    late VeloxEventBus bus;

    setUp(() {
      bus = VeloxEventBus();
    });

    tearDown(() async {
      if (!bus.isDisposed) {
        await bus.dispose();
      }
    });

    test('fires and receives a single event', () async {
      final completer = Completer<_UserLoggedIn>();
      bus.on<_UserLoggedIn>().listen(completer.complete);

      bus.fire(_UserLoggedIn('user-1'));

      final event = await completer.future;
      expect(event.userId, 'user-1');
    });

    test('filters events by type', () async {
      final loggedInEvents = <_UserLoggedIn>[];
      final loggedOutEvents = <_UserLoggedOut>[];

      bus
        ..on<_UserLoggedIn>().listen(loggedInEvents.add)
        ..on<_UserLoggedOut>().listen(loggedOutEvents.add)
        ..fire(_UserLoggedIn('u1'))
        ..fire(_UserLoggedOut('u2'))
        ..fire(_UserLoggedIn('u3'));

      // Allow the microtask queue to flush.
      await Future<void>.delayed(Duration.zero);

      expect(loggedInEvents, hasLength(2));
      expect(loggedInEvents[0].userId, 'u1');
      expect(loggedInEvents[1].userId, 'u3');
      expect(loggedOutEvents, hasLength(1));
      expect(loggedOutEvents[0].userId, 'u2');
    });

    test('delivers events to multiple listeners of the same type', () async {
      final first = <_UserLoggedIn>[];
      final second = <_UserLoggedIn>[];

      bus
        ..on<_UserLoggedIn>().listen(first.add)
        ..on<_UserLoggedIn>().listen(second.add)
        ..fire(_UserLoggedIn('u1'));

      await Future<void>.delayed(Duration.zero);

      expect(first, hasLength(1));
      expect(second, hasLength(1));
    });

    test('fireAll dispatches multiple events in order', () async {
      final events = <VeloxEvent>[];
      bus.on<VeloxEvent>().listen(events.add);

      bus.fireAll([
        _UserLoggedIn('u1'),
        _OrderPlaced('o1', 29.99),
        _UserLoggedOut('u1'),
      ]);

      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(3));
      expect(events[0], isA<_UserLoggedIn>());
      expect(events[1], isA<_OrderPlaced>());
      expect(events[2], isA<_UserLoggedOut>());
    });

    test('fireAll with empty list does nothing', () async {
      final events = <VeloxEvent>[];
      bus.on<VeloxEvent>().listen(events.add);

      bus.fireAll([]);

      await Future<void>.delayed(Duration.zero);

      expect(events, isEmpty);
    });

    test('hasListeners returns false when no listeners', () {
      expect(bus.hasListeners, isFalse);
    });

    test('hasListeners returns true when listeners exist', () {
      bus.on<_UserLoggedIn>().listen((_) {});

      expect(bus.hasListeners, isTrue);
    });

    test('hasListeners returns false after all subscriptions cancelled',
        () async {
      final sub = bus.on<_UserLoggedIn>().listen((_) {});

      expect(bus.hasListeners, isTrue);

      await sub.cancel();

      expect(bus.hasListeners, isFalse);
    });

    test('isDisposed returns false initially', () {
      expect(bus.isDisposed, isFalse);
    });

    test('isDisposed returns true after dispose', () async {
      await bus.dispose();

      expect(bus.isDisposed, isTrue);
    });

    test('fire throws StateError after dispose', () async {
      await bus.dispose();

      expect(
        () => bus.fire(_UserLoggedIn('u1')),
        throwsStateError,
      );
    });

    test('fireAll throws StateError after dispose', () async {
      await bus.dispose();

      expect(
        () => bus.fireAll([_UserLoggedIn('u1')]),
        throwsStateError,
      );
    });

    test('on throws StateError after dispose', () async {
      await bus.dispose();

      expect(
        () => bus.on<_UserLoggedIn>(),
        throwsStateError,
      );
    });

    test('dispose is idempotent', () async {
      await bus.dispose();
      await bus.dispose();

      expect(bus.isDisposed, isTrue);
    });

    test('receives subtype events when listening to supertype', () async {
      final events = <_BaseEvent>[];
      bus.on<_BaseEvent>().listen(events.add);

      bus
        ..fire(_ChildEvent())
        ..fire(_BaseEvent());

      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(2));
      expect(events[0], isA<_ChildEvent>());
      expect(events[1], isA<_BaseEvent>());
    });

    test('does not receive supertype events when listening to subtype',
        () async {
      final events = <_ChildEvent>[];
      bus.on<_ChildEvent>().listen(events.add);

      bus
        ..fire(_BaseEvent())
        ..fire(_ChildEvent());

      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events[0], isA<_ChildEvent>());
    });

    test('on<VeloxEvent> receives all events', () async {
      final events = <VeloxEvent>[];
      bus.on<VeloxEvent>().listen(events.add);

      bus
        ..fire(_UserLoggedIn('u1'))
        ..fire(_OrderPlaced('o1', 9.99))
        ..fire(_UserLoggedOut('u1'));

      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(3));
    });
  });

  group('VeloxEventSubscription', () {
    late VeloxEventBus bus;

    setUp(() {
      bus = VeloxEventBus();
    });

    tearDown(() async {
      if (!bus.isDisposed) {
        await bus.dispose();
      }
    });

    test('wraps a stream subscription for cancellation', () async {
      final events = <_UserLoggedIn>[];
      final subscription = VeloxEventSubscription(
        bus.on<_UserLoggedIn>().listen(events.add),
      );

      bus.fire(_UserLoggedIn('u1'));
      await Future<void>.delayed(Duration.zero);
      expect(events, hasLength(1));

      await subscription.cancel();
      expect(subscription.isCancelled, isTrue);

      bus.fire(_UserLoggedIn('u2'));
      await Future<void>.delayed(Duration.zero);
      expect(events, hasLength(1));
    });

    test('cancel is idempotent', () async {
      final subscription = VeloxEventSubscription(
        bus.on<_UserLoggedIn>().listen((_) {}),
      );

      await subscription.cancel();
      await subscription.cancel();

      expect(subscription.isCancelled, isTrue);
    });

    test('pause and resume work correctly', () async {
      final events = <_UserLoggedIn>[];
      final subscription = VeloxEventSubscription(
        bus.on<_UserLoggedIn>().listen(events.add),
      );

      expect(subscription.isPaused, isFalse);

      subscription.pause();
      expect(subscription.isPaused, isTrue);

      bus.fire(_UserLoggedIn('u1'));
      await Future<void>.delayed(Duration.zero);

      subscription.resume();
      expect(subscription.isPaused, isFalse);

      // Buffered event should be delivered after resume.
      await Future<void>.delayed(Duration.zero);
      expect(events, hasLength(1));
    });

    test('isCancelled is false initially', () {
      final subscription = VeloxEventSubscription(
        bus.on<_UserLoggedIn>().listen((_) {}),
      );

      expect(subscription.isCancelled, isFalse);
    });
  });
}

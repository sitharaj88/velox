// ignore_for_file: cancel_subscriptions, cascade_invocations
// ignore_for_file: prefer_int_literals, prefer_const_constructors

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

class _ChatMessage extends VeloxEvent {
  _ChatMessage(this.text);
  final String text;
}

void main() {
  // ===========================================================================
  // Priority-based event handling
  // ===========================================================================
  group('Priority-based event handling', () {
    late VeloxEventBus bus;

    setUp(() {
      bus = VeloxEventBus();
    });

    tearDown(() async {
      if (!bus.isDisposed) {
        await bus.dispose();
      }
    });

    test('handlers execute in priority order (highest first)', () {
      final order = <int>[];

      bus
        ..listen<_UserLoggedIn>((_) => order.add(1), priority: 1)
        ..listen<_UserLoggedIn>((_) => order.add(10), priority: 10)
        ..listen<_UserLoggedIn>((_) => order.add(5), priority: 5)
        ..fire(_UserLoggedIn('u1'));

      expect(order, [10, 5, 1]);
    });

    test('equal priority handlers execute in registration order', () {
      final order = <String>[];

      bus
        ..listen<_UserLoggedIn>((_) => order.add('first'))
        ..listen<_UserLoggedIn>((_) => order.add('second'))
        ..listen<_UserLoggedIn>((_) => order.add('third'))
        ..fire(_UserLoggedIn('u1'));

      expect(order, ['first', 'second', 'third']);
    });

    test('negative priorities are supported', () {
      final order = <int>[];

      bus
        ..listen<_UserLoggedIn>((_) => order.add(-5), priority: -5)
        ..listen<_UserLoggedIn>((_) => order.add(0))
        ..listen<_UserLoggedIn>((_) => order.add(5), priority: 5)
        ..fire(_UserLoggedIn('u1'));

      expect(order, [5, 0, -5]);
    });
  });

  // ===========================================================================
  // Async event handling
  // ===========================================================================
  group('Async event handling', () {
    late VeloxEventBus bus;

    setUp(() {
      bus = VeloxEventBus();
    });

    tearDown(() async {
      if (!bus.isDisposed) {
        await bus.dispose();
      }
    });

    test('emitAsync awaits all handlers', () async {
      final results = <String>[];

      bus.listen<_UserLoggedIn>((event) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        results.add('handler1');
      });

      bus.listen<_UserLoggedIn>((event) async {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        results.add('handler2');
      });

      await bus.emitAsync(_UserLoggedIn('u1'));

      // Both handlers should have completed.
      expect(results, contains('handler1'));
      expect(results, contains('handler2'));
    });

    test('emitAsync handles errors without stopping other handlers', () async {
      final results = <String>[];
      final errors = <Object>[];

      bus.onError = (error, _) => errors.add(error);
      bus
        ..listen<_UserLoggedIn>((event) {
          throw Exception('handler1 failed');
        })
        ..listen<_UserLoggedIn>((event) {
          results.add('handler2');
        });

      await bus.emitAsync(_UserLoggedIn('u1'));

      expect(results, ['handler2']);
      expect(errors, hasLength(1));
      expect(errors.first.toString(), contains('handler1 failed'));
    });

    test('emitAsync with no handlers completes immediately', () async {
      // Should not throw or hang.
      await bus.emitAsync(_UserLoggedIn('u1'));
    });

    test('emitAsync throws StateError after dispose', () async {
      await bus.dispose();

      expect(
        () => bus.emitAsync(_UserLoggedIn('u1')),
        throwsStateError,
      );
    });
  });

  // ===========================================================================
  // One-shot listeners
  // ===========================================================================
  group('One-shot listeners (listenOnce)', () {
    late VeloxEventBus bus;

    setUp(() {
      bus = VeloxEventBus();
    });

    tearDown(() async {
      if (!bus.isDisposed) {
        await bus.dispose();
      }
    });

    test('listenOnce fires handler exactly once', () {
      final events = <_UserLoggedIn>[];

      bus
        ..listenOnce<_UserLoggedIn>(events.add)
        ..fire(_UserLoggedIn('u1'))
        ..fire(_UserLoggedIn('u2'))
        ..fire(_UserLoggedIn('u3'));

      expect(events, hasLength(1));
      expect(events.first.userId, 'u1');
    });

    test('listenOnce can be cancelled before firing', () async {
      final events = <_UserLoggedIn>[];

      final sub = bus.listenOnce<_UserLoggedIn>(events.add);
      await sub.cancel();

      bus.fire(_UserLoggedIn('u1'));

      expect(events, isEmpty);
    });

    test('listenOnce respects priority', () {
      final order = <int>[];

      bus
        ..listenOnce<_UserLoggedIn>((_) => order.add(1), priority: 1)
        ..listenOnce<_UserLoggedIn>((_) => order.add(10), priority: 10)
        ..fire(_UserLoggedIn('u1'));

      expect(order, [10, 1]);
    });

    test('listenOnce respects filter', () {
      final events = <_UserLoggedIn>[];

      bus
        ..listenOnce<_UserLoggedIn>(
          events.add,
          filter: (e) => e.userId == 'u2',
        )
        ..fire(_UserLoggedIn('u1')) // filtered out, handler NOT consumed
        ..fire(_UserLoggedIn('u2')) // passes filter, handler fires
        ..fire(_UserLoggedIn('u2')); // already consumed

      expect(events, hasLength(1));
      expect(events.first.userId, 'u2');
    });
  });

  // ===========================================================================
  // Event history
  // ===========================================================================
  group('Event history', () {
    late VeloxEventBus bus;

    setUp(() {
      bus = VeloxEventBus(historySize: 5);
    });

    tearDown(() async {
      if (!bus.isDisposed) {
        await bus.dispose();
      }
    });

    test('retains events in history buffer', () {
      bus
        ..fire(_UserLoggedIn('u1'))
        ..fire(_UserLoggedIn('u2'));

      final history = bus.getHistory<_UserLoggedIn>();
      expect(history, hasLength(2));
      expect(history[0].userId, 'u1');
      expect(history[1].userId, 'u2');
    });

    test('history buffer respects size limit', () {
      for (var i = 0; i < 10; i++) {
        bus.fire(_UserLoggedIn('u$i'));
      }

      final history = bus.getHistory<_UserLoggedIn>();
      expect(history, hasLength(5));
      // Only the last 5 should remain.
      expect(history[0].userId, 'u5');
      expect(history[4].userId, 'u9');
    });

    test('listenWithHistory replays past events to new subscriber', () {
      final events = <_UserLoggedIn>[];

      bus
        ..fire(_UserLoggedIn('u1'))
        ..fire(_UserLoggedIn('u2'))
        ..fire(_UserLoggedIn('u3'))
        ..listenWithHistory<_UserLoggedIn>(events.add);

      // Should have received all 3 history events.
      expect(events, hasLength(3));
      expect(events[0].userId, 'u1');
      expect(events[1].userId, 'u2');
      expect(events[2].userId, 'u3');
    });

    test('listenWithHistory limits replay count', () {
      final events = <_UserLoggedIn>[];

      bus
        ..fire(_UserLoggedIn('u1'))
        ..fire(_UserLoggedIn('u2'))
        ..fire(_UserLoggedIn('u3'))
        ..listenWithHistory<_UserLoggedIn>(events.add, count: 2);

      // Should have received only the last 2 history events.
      expect(events, hasLength(2));
      expect(events[0].userId, 'u2');
      expect(events[1].userId, 'u3');
    });

    test('listenWithHistory also receives future events', () {
      final events = <_UserLoggedIn>[];

      bus
        ..fire(_UserLoggedIn('u1'))
        ..listenWithHistory<_UserLoggedIn>(events.add)
        ..fire(_UserLoggedIn('u2'));

      // 1 from history + 1 from new fire.
      expect(events, hasLength(2));
      expect(events[0].userId, 'u1');
      expect(events[1].userId, 'u2');
    });

    test('history is per event type', () {
      bus
        ..fire(_UserLoggedIn('u1'))
        ..fire(_OrderPlaced('o1', 9.99));

      expect(bus.getHistory<_UserLoggedIn>(), hasLength(1));
      expect(bus.getHistory<_OrderPlaced>(), hasLength(1));
    });

    test('clearHistory removes history for a type', () {
      bus.fire(_UserLoggedIn('u1'));
      expect(bus.getHistory<_UserLoggedIn>(), hasLength(1));

      bus.clearHistory<_UserLoggedIn>();
      expect(bus.getHistory<_UserLoggedIn>(), isEmpty);
    });

    test('clearAllHistory removes all history', () {
      bus
        ..fire(_UserLoggedIn('u1'))
        ..fire(_OrderPlaced('o1', 9.99))
        ..clearAllHistory();

      expect(bus.getHistory<_UserLoggedIn>(), isEmpty);
      expect(bus.getHistory<_OrderPlaced>(), isEmpty);
    });

    test('no history when historySize is 0', () {
      final noHistoryBus = VeloxEventBus();
      addTearDown(noHistoryBus.dispose);

      noHistoryBus.fire(_UserLoggedIn('u1'));
      expect(noHistoryBus.getHistory<_UserLoggedIn>(), isEmpty);
    });
  });

  // ===========================================================================
  // Event filtering
  // ===========================================================================
  group('Event filtering', () {
    late VeloxEventBus bus;

    setUp(() {
      bus = VeloxEventBus();
    });

    tearDown(() async {
      if (!bus.isDisposed) {
        await bus.dispose();
      }
    });

    test('filter restricts which events reach the handler', () {
      final events = <_OrderPlaced>[];

      bus
        ..listen<_OrderPlaced>(
          events.add,
          filter: (e) => e.amount > 50,
        )
        ..fire(_OrderPlaced('o1', 25.0))
        ..fire(_OrderPlaced('o2', 75.0))
        ..fire(_OrderPlaced('o3', 100.0));

      expect(events, hasLength(2));
      expect(events[0].orderId, 'o2');
      expect(events[1].orderId, 'o3');
    });

    test('filter works with listenWithHistory', () {
      final events = <_OrderPlaced>[];
      bus = VeloxEventBus(historySize: 5);

      bus
        ..fire(_OrderPlaced('o1', 25.0))
        ..fire(_OrderPlaced('o2', 75.0))
        ..listenWithHistory<_OrderPlaced>(
          events.add,
          filter: (e) => e.amount > 50,
        );

      // Only the >50 event from history should be replayed.
      expect(events, hasLength(1));
      expect(events[0].orderId, 'o2');
    });
  });

  // ===========================================================================
  // Sticky events
  // ===========================================================================
  group('Sticky events', () {
    late VeloxEventBus bus;

    setUp(() {
      bus = VeloxEventBus();
    });

    tearDown(() async {
      if (!bus.isDisposed) {
        await bus.dispose();
      }
    });

    test('sticky event is retained and delivered to new subscribers', () {
      final events = <_UserLoggedIn>[];

      bus
        ..fire(_UserLoggedIn('u1'))
        ..listenSticky<_UserLoggedIn>(events.add);

      expect(events, hasLength(1));
      expect(events[0].userId, 'u1');
    });

    test('sticky event is the latest fired event per type', () {
      bus
        ..fire(_UserLoggedIn('u1'))
        ..fire(_UserLoggedIn('u2'));

      final sticky = bus.getStickyEvent<_UserLoggedIn>();
      expect(sticky, isNotNull);
      expect(sticky!.userId, 'u2');
    });

    test('sticky events are per type', () {
      bus
        ..fire(_UserLoggedIn('u1'))
        ..fire(_OrderPlaced('o1', 9.99));

      expect(bus.getStickyEvent<_UserLoggedIn>(), isNotNull);
      expect(bus.getStickyEvent<_OrderPlaced>(), isNotNull);
      expect(bus.getStickyEvent<_UserLoggedOut>(), isNull);
    });

    test('clearStickyEvent removes and returns the event', () {
      bus.fire(_UserLoggedIn('u1'));

      final cleared = bus.clearStickyEvent<_UserLoggedIn>();
      expect(cleared, isNotNull);
      expect(cleared!.userId, 'u1');
      expect(bus.getStickyEvent<_UserLoggedIn>(), isNull);
    });

    test('clearAllStickyEvents removes all sticky events', () {
      bus
        ..fire(_UserLoggedIn('u1'))
        ..fire(_OrderPlaced('o1', 9.99))
        ..clearAllStickyEvents();

      expect(bus.getStickyEvent<_UserLoggedIn>(), isNull);
      expect(bus.getStickyEvent<_OrderPlaced>(), isNull);
    });

    test('listenSticky with filter skips non-matching sticky event', () {
      final events = <_OrderPlaced>[];

      bus
        ..fire(_OrderPlaced('o1', 25.0))
        ..listenSticky<_OrderPlaced>(
          events.add,
          filter: (e) => e.amount > 50,
        );

      // Sticky event has amount 25, which doesn't pass filter.
      expect(events, isEmpty);
    });

    test('listenSticky with no sticky event just subscribes', () {
      final events = <_UserLoggedIn>[];

      bus
        ..listenSticky<_UserLoggedIn>(events.add)
        ..fire(_UserLoggedIn('u1'));

      // No sticky event initially, but gets the fired event.
      expect(events, hasLength(1));
      expect(events[0].userId, 'u1');
    });
  });

  // ===========================================================================
  // Event interceptors
  // ===========================================================================
  group('Event interceptors', () {
    late VeloxEventBus bus;

    setUp(() {
      bus = VeloxEventBus();
    });

    tearDown(() async {
      if (!bus.isDisposed) {
        await bus.dispose();
      }
    });

    test('interceptor can block events by returning null', () async {
      final events = <_UserLoggedIn>[];

      bus
        ..addInterceptor(EventInterceptor<_UserLoggedIn>((_) => null))
        ..on<_UserLoggedIn>().listen(events.add)
        ..fire(_UserLoggedIn('u1'));

      await Future<void>.delayed(Duration.zero);

      expect(events, isEmpty);
    });

    test('interceptor can pass events through', () async {
      final events = <_UserLoggedIn>[];

      bus
        ..addInterceptor(EventInterceptor<_UserLoggedIn>((e) => e))
        ..on<_UserLoggedIn>().listen(events.add)
        ..fire(_UserLoggedIn('u1'));

      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
    });

    test('interceptor can transform events', () async {
      final events = <_UserLoggedIn>[];

      bus
        ..addInterceptor(
          EventInterceptor<_UserLoggedIn>(
            (e) => _UserLoggedIn('transformed_${e.userId}'),
          ),
        )
        ..on<_UserLoggedIn>().listen(events.add)
        ..fire(_UserLoggedIn('u1'));

      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events[0].userId, 'transformed_u1');
    });

    test('interceptors are chained in order', () async {
      final events = <_UserLoggedIn>[];

      bus
        ..addInterceptor(
          EventInterceptor<_UserLoggedIn>(
            (e) => _UserLoggedIn('${e.userId}_a'),
          ),
        )
        ..addInterceptor(
          EventInterceptor<_UserLoggedIn>(
            (e) => _UserLoggedIn('${e.userId}_b'),
          ),
        )
        ..on<_UserLoggedIn>().listen(events.add)
        ..fire(_UserLoggedIn('u1'));

      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events[0].userId, 'u1_a_b');
    });

    test('removeInterceptor stops the interceptor from running', () async {
      final events = <_UserLoggedIn>[];

      final interceptor =
          EventInterceptor<_UserLoggedIn>((_) => null);

      bus
        ..addInterceptor(interceptor)
        ..on<_UserLoggedIn>().listen(events.add);

      bus.fire(_UserLoggedIn('u1'));
      await Future<void>.delayed(Duration.zero);
      expect(events, isEmpty);

      bus.removeInterceptor(interceptor);

      bus.fire(_UserLoggedIn('u2'));
      await Future<void>.delayed(Duration.zero);
      expect(events, hasLength(1));
    });

    test('blocked event is not recorded in history or sticky', () {
      bus = VeloxEventBus(historySize: 5);

      bus
        ..addInterceptor(EventInterceptor<_UserLoggedIn>((_) => null))
        ..fire(_UserLoggedIn('u1'));

      expect(bus.getHistory<_UserLoggedIn>(), isEmpty);
      expect(bus.getStickyEvent<_UserLoggedIn>(), isNull);
    });
  });

  // ===========================================================================
  // Stream-based API
  // ===========================================================================
  group('Stream-based API', () {
    late VeloxEventBus bus;

    setUp(() {
      bus = VeloxEventBus();
    });

    tearDown(() async {
      if (!bus.isDisposed) {
        await bus.dispose();
      }
    });

    test('on<T>() returns a typed stream', () async {
      final events = <_UserLoggedIn>[];
      bus.on<_UserLoggedIn>().listen(events.add);

      bus.fire(_UserLoggedIn('u1'));
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events[0].userId, 'u1');
    });

    test('stream can be used with take for one-shot via stream', () async {
      final event =
          bus.on<_UserLoggedIn>().first;

      bus.fire(_UserLoggedIn('u1'));

      final result = await event;
      expect(result.userId, 'u1');
    });

    test('stream supports where for filtering', () async {
      final events = <_OrderPlaced>[];

      bus
          .on<_OrderPlaced>()
          .where((e) => e.amount > 50)
          .listen(events.add);

      bus
        ..fire(_OrderPlaced('o1', 25.0))
        ..fire(_OrderPlaced('o2', 75.0));

      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events[0].orderId, 'o2');
    });

    test('stream supports map transformation', () async {
      final amounts = <double>[];

      bus
          .on<_OrderPlaced>()
          .map((e) => e.amount)
          .listen(amounts.add);

      bus
        ..fire(_OrderPlaced('o1', 9.99))
        ..fire(_OrderPlaced('o2', 19.99));

      await Future<void>.delayed(Duration.zero);

      expect(amounts, [9.99, 19.99]);
    });
  });

  // ===========================================================================
  // Comprehensive error handling
  // ===========================================================================
  group('Comprehensive error handling', () {
    late VeloxEventBus bus;

    setUp(() {
      bus = VeloxEventBus();
    });

    tearDown(() async {
      if (!bus.isDisposed) {
        await bus.dispose();
      }
    });

    test('error in one handler does not prevent others from executing', () {
      final results = <String>[];
      final errors = <Object>[];

      bus.onError = (error, _) => errors.add(error);
      bus
        ..listen<_UserLoggedIn>((e) {
          throw Exception('handler1 error');
        })
        ..listen<_UserLoggedIn>((e) {
          results.add('handler2 ok');
        })
        ..fire(_UserLoggedIn('u1'));

      expect(results, ['handler2 ok']);
      expect(errors, hasLength(1));
    });

    test('errors are reported to onError callback', () {
      final errors = <Object>[];
      final stackTraces = <StackTrace>[];

      bus.onError = (error, stack) {
        errors.add(error);
        stackTraces.add(stack);
      };
      bus
        ..listen<_UserLoggedIn>((e) {
          throw FormatException('bad format');
        })
        ..fire(_UserLoggedIn('u1'));

      expect(errors, hasLength(1));
      expect(errors.first, isA<FormatException>());
      expect(stackTraces, hasLength(1));
    });

    test('errors are silently swallowed when no onError handler set', () {
      final results = <String>[];

      bus
        ..listen<_UserLoggedIn>((e) {
          throw Exception('handler1 error');
        })
        ..listen<_UserLoggedIn>((e) {
          results.add('handler2 ok');
        })
        ..fire(_UserLoggedIn('u1'));

      // handler2 should still run even without an error callback.
      expect(results, ['handler2 ok']);
    });

    test('multiple errors are all reported', () {
      final errors = <Object>[];

      bus.onError = (error, _) => errors.add(error);
      bus
        ..listen<_UserLoggedIn>((e) {
          throw Exception('error1');
        })
        ..listen<_UserLoggedIn>((e) {
          throw Exception('error2');
        })
        ..fire(_UserLoggedIn('u1'));

      expect(errors, hasLength(2));
    });
  });

  // ===========================================================================
  // Scoped event bus
  // ===========================================================================
  group('ScopedEventBus', () {
    late VeloxEventBus parent;
    late ScopedEventBus child;

    setUp(() {
      parent = VeloxEventBus();
      child = ScopedEventBus(parent);
    });

    tearDown(() async {
      if (!child.isDisposed) {
        await child.dispose();
      }
      if (!parent.isDisposed) {
        await parent.dispose();
      }
    });

    test('child receives parent events via stream', () async {
      final childEvents = <_UserLoggedIn>[];
      child.on<_UserLoggedIn>().listen(childEvents.add);

      parent.fire(_UserLoggedIn('u1'));
      await Future<void>.delayed(Duration.zero);

      expect(childEvents, hasLength(1));
      expect(childEvents[0].userId, 'u1');
    });

    test('child receives parent events via handler', () async {
      final childEvents = <_UserLoggedIn>[];
      child.listen<_UserLoggedIn>(childEvents.add);

      parent.fire(_UserLoggedIn('u1'));

      // Parent events arrive via stream (async), so wait for microtask.
      await Future<void>.delayed(Duration.zero);
      expect(childEvents, hasLength(1));
    });

    test('parent does not receive child events', () async {
      final parentEvents = <_UserLoggedIn>[];
      parent.on<_UserLoggedIn>().listen(parentEvents.add);

      child.fire(_UserLoggedIn('u1'));
      await Future<void>.delayed(Duration.zero);

      expect(parentEvents, isEmpty);
    });

    test('child events are local to the child', () async {
      final childEvents = <_ChatMessage>[];
      child.on<_ChatMessage>().listen(childEvents.add);

      child.fire(_ChatMessage('hello'));
      await Future<void>.delayed(Duration.zero);

      expect(childEvents, hasLength(1));
      expect(childEvents[0].text, 'hello');
    });

    test('disposing child does not affect parent', () async {
      await child.dispose();

      // Parent should still work fine.
      final events = <_UserLoggedIn>[];
      parent.on<_UserLoggedIn>().listen(events.add);

      parent.fire(_UserLoggedIn('u1'));
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(parent.isDisposed, isFalse);
    });

    test('sibling children are isolated from each other', () async {
      final sibling = ScopedEventBus(parent);
      addTearDown(sibling.dispose);

      final childEvents = <_ChatMessage>[];
      final siblingEvents = <_ChatMessage>[];

      child.on<_ChatMessage>().listen(childEvents.add);
      sibling.on<_ChatMessage>().listen(siblingEvents.add);

      child.fire(_ChatMessage('from child'));
      await Future<void>.delayed(Duration.zero);

      expect(childEvents, hasLength(1));
      expect(siblingEvents, isEmpty);
    });
  });

  // ===========================================================================
  // Handler subscription cancellation
  // ===========================================================================
  group('Handler subscription management', () {
    late VeloxEventBus bus;

    setUp(() {
      bus = VeloxEventBus();
    });

    tearDown(() async {
      if (!bus.isDisposed) {
        await bus.dispose();
      }
    });

    test('listen returns cancellable subscription', () async {
      final events = <_UserLoggedIn>[];

      final sub = bus.listen<_UserLoggedIn>(events.add);

      bus.fire(_UserLoggedIn('u1'));
      expect(events, hasLength(1));

      await sub.cancel();

      bus.fire(_UserLoggedIn('u2'));
      expect(events, hasLength(1));
    });

    test('listen throws after dispose', () async {
      await bus.dispose();

      expect(
        () => bus.listen<_UserLoggedIn>((_) {}),
        throwsStateError,
      );
    });

    test('listenOnce throws after dispose', () async {
      await bus.dispose();

      expect(
        () => bus.listenOnce<_UserLoggedIn>((_) {}),
        throwsStateError,
      );
    });
  });

  // ===========================================================================
  // Integration tests
  // ===========================================================================
  group('Integration', () {
    test('all features work together', () async {
      final bus = VeloxEventBus(historySize: 10);
      addTearDown(bus.dispose);
      final allEvents = <String>[];
      final errors = <Object>[];

      bus.onError = (error, _) => errors.add(error);

      // Add interceptor that transforms user IDs to uppercase.
      bus.addInterceptor(
        EventInterceptor<_UserLoggedIn>(
          (e) => _UserLoggedIn(e.userId.toUpperCase()),
        ),
      );

      // High-priority handler that throws.
      bus.listen<_UserLoggedIn>(
        (e) => throw Exception('audit failed'),
        priority: 100,
      );

      // Normal handler.
      bus.listen<_UserLoggedIn>(
        (e) => allEvents.add('logged-in: ${e.userId}'),
      );

      // Fire events.
      bus.fire(_UserLoggedIn('alice'));
      bus.fire(_UserLoggedIn('bob'));

      // Verify transformation happened.
      expect(allEvents, ['logged-in: ALICE', 'logged-in: BOB']);

      // Verify error was caught.
      expect(errors, hasLength(2));

      // Verify history recorded transformed events.
      final history = bus.getHistory<_UserLoggedIn>();
      expect(history, hasLength(2));
      expect(history[0].userId, 'ALICE');

      // Verify sticky is the latest.
      final sticky = bus.getStickyEvent<_UserLoggedIn>();
      expect(sticky!.userId, 'BOB');

      // New subscriber gets history.
      final replayedEvents = <String>[];
      bus.listenWithHistory<_UserLoggedIn>(
        (e) => replayedEvents.add(e.userId),
        count: 1,
      );
      expect(replayedEvents, ['BOB']);
    });

    test('scoped bus with interceptors and sticky', () async {
      final parent = VeloxEventBus();
      final child = ScopedEventBus(parent);
      addTearDown(() async {
        await child.dispose();
        await parent.dispose();
      });

      // Parent fires with sticky.
      parent.fire(_UserLoggedIn('u1'));

      // Child uses sticky from parent? No - sticky is per bus instance.
      // But the child's injectEvent records it locally.
      await Future<void>.delayed(Duration.zero);

      final childSticky = child.getStickyEvent<_UserLoggedIn>();
      expect(childSticky, isNotNull);
      expect(childSticky!.userId, 'u1');
    });
  });
}

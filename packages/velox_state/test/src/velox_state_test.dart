import 'package:flutter_test/flutter_test.dart';
import 'package:velox_state/velox_state.dart';

// ---------------------------------------------------------------------------
// Test helper commands
// ---------------------------------------------------------------------------

/// A command that adds [amount] to an integer state.
class AddCommand extends VeloxCommand<int> {
  const AddCommand(this.amount);
  final int amount;

  @override
  int execute(int state) => state + amount;

  @override
  int undo(int state) => state - amount;
}

/// A command that multiplies an integer state by [factor].
class MultiplyCommand extends VeloxCommand<int> {
  const MultiplyCommand(this.factor);
  final int factor;

  @override
  int execute(int state) => state * factor;

  @override
  int undo(int state) => state ~/ factor;
}

// ---------------------------------------------------------------------------
// Test helper middleware
// ---------------------------------------------------------------------------

/// Middleware that clamps an integer value between [min] and [max].
class ClampMiddleware extends VeloxMiddleware<int> {
  const ClampMiddleware(this.min, this.max);
  final int min;
  final int max;

  @override
  int? handle(int currentState, int newState, int Function(int) next) =>
      next(newState.clamp(min, max));
}

/// Middleware that rejects negative values.
class RejectNegativeMiddleware extends VeloxMiddleware<int> {
  const RejectNegativeMiddleware();

  @override
  int? handle(int currentState, int newState, int Function(int) next) {
    if (newState < 0) return null;
    return next(newState);
  }
}

/// Middleware that logs transitions.
class LoggingMiddleware<T> extends VeloxMiddleware<T> {
  final List<String> log = [];

  @override
  T? handle(T currentState, T newState, T Function(T) next) {
    log.add('$currentState -> $newState');
    return next(newState);
  }
}

// ---------------------------------------------------------------------------
// Test helper observer
// ---------------------------------------------------------------------------

class TestObserver extends VeloxStateObserver {
  final List<String> changes = [];

  @override
  void onStateChanged<T>(String name, T previousState, T newState) {
    changes.add('$name: $previousState -> $newState');
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // =========================================================================
  // VeloxNotifier (existing tests preserved)
  // =========================================================================
  group('VeloxNotifier', () {
    late VeloxNotifier<int> notifier;

    setUp(() {
      notifier = VeloxNotifier<int>(0);
    });

    tearDown(() {
      if (!notifier.isDisposed) {
        notifier.dispose();
      }
    });

    test('has initial state', () {
      expect(notifier.state, 0);
    });

    test('setState updates the state', () {
      notifier.setState(42);

      expect(notifier.state, 42);
    });

    test('update applies a function to the current state', () {
      notifier
        ..setState(10)
        ..update((s) => s + 5);

      expect(notifier.state, 15);
    });

    test('addListener is called on state change', () {
      final values = <int>[];
      notifier
        ..addListener(values.add)
        ..setState(1)
        ..setState(2)
        ..setState(3);

      expect(values, [1, 2, 3]);
    });

    test('removeListener stops notifications', () {
      final values = <int>[];
      void listener(int value) => values.add(value);

      notifier
        ..addListener(listener)
        ..setState(1)
        ..removeListener(listener)
        ..setState(2);

      expect(values, [1]);
    });

    test('addListener returns a removal callback', () {
      final values = <int>[];
      final remove = notifier.addListener(values.add);

      notifier.setState(1);
      remove();
      notifier.setState(2);

      expect(values, [1]);
    });

    test('multiple listeners are all notified', () {
      final valuesA = <int>[];
      final valuesB = <int>[];
      notifier
        ..addListener(valuesA.add)
        ..addListener(valuesB.add)
        ..setState(7);

      expect(valuesA, [7]);
      expect(valuesB, [7]);
    });

    test('stream emits state changes', () async {
      final future = notifier.stream.take(3).toList();

      notifier
        ..setState(1)
        ..setState(2)
        ..setState(3);

      final values = await future;
      expect(values, [1, 2, 3]);
    });

    test('stream is a broadcast stream', () {
      final streamA = notifier.stream;
      final streamB = notifier.stream;

      expect(identical(streamA, streamB), isTrue);
      expect(streamA.isBroadcast, isTrue);
    });

    test('dispose clears listeners and closes stream', () async {
      final values = <int>[];
      notifier.addListener(values.add);

      final streamDone = notifier.stream.toList();

      notifier
        ..setState(1)
        ..dispose();

      expect(notifier.isDisposed, isTrue);
      expect(await streamDone, [1]);
    });

    test('throws StateError when used after dispose', () {
      notifier.dispose();

      expect(() => notifier.setState(1), throwsStateError);
      expect(() => notifier.update((s) => s + 1), throwsStateError);
      expect(() => notifier.addListener((_) {}), throwsStateError);
      expect(() => notifier.stream, throwsStateError);
      expect(() => notifier.dispose(), throwsStateError);
    });

    test('listener added during notification is not called', () {
      final values = <int>[];
      notifier
        ..addListener((_) {
          notifier.addListener(values.add);
        })
        ..setState(1);

      // The inner listener was added during notification, so it should
      // not have been called for the value 1.
      expect(values, isEmpty);
    });
  });

  // =========================================================================
  // VeloxCommand (existing tests + new enhancements)
  // =========================================================================
  group('VeloxCommand', () {
    late VeloxNotifier<int> notifier;
    late VeloxCommandExecutor<int> executor;

    setUp(() {
      notifier = VeloxNotifier<int>(0);
      executor = VeloxCommandExecutor<int>(notifier);
    });

    tearDown(() {
      if (!notifier.isDisposed) {
        notifier.dispose();
      }
    });

    test('execute applies command to state', () {
      executor.execute(const AddCommand(5));

      expect(notifier.state, 5);
    });

    test('execute multiple commands accumulates state', () {
      executor
        ..execute(const AddCommand(5))
        ..execute(const AddCommand(3));

      expect(notifier.state, 8);
    });

    test('undo reverses the last command', () {
      executor
        ..execute(const AddCommand(5))
        ..execute(const AddCommand(3))
        ..undo();

      expect(notifier.state, 5);
    });

    test('redo re-applies an undone command', () {
      executor
        ..execute(const AddCommand(5))
        ..undo()
        ..redo();

      expect(notifier.state, 5);
    });

    test('undo then redo preserves state', () {
      executor
        ..execute(const AddCommand(10))
        ..execute(const AddCommand(20))
        ..undo()
        ..undo()
        ..redo()
        ..redo();

      expect(notifier.state, 30);
    });

    test('execute clears redo stack', () {
      executor
        ..execute(const AddCommand(5))
        ..undo()
        ..execute(const AddCommand(10));

      expect(executor.canRedo, isFalse);
      expect(notifier.state, 10);
    });

    test('canUndo and canRedo report correct state', () {
      expect(executor.canUndo, isFalse);
      expect(executor.canRedo, isFalse);

      executor.execute(const AddCommand(1));
      expect(executor.canUndo, isTrue);
      expect(executor.canRedo, isFalse);

      executor.undo();
      expect(executor.canUndo, isFalse);
      expect(executor.canRedo, isTrue);
    });

    test('undoCount and redoCount track history sizes', () {
      executor
        ..execute(const AddCommand(1))
        ..execute(const AddCommand(2))
        ..execute(const AddCommand(3));

      expect(executor.undoCount, 3);
      expect(executor.redoCount, 0);

      executor.undo();

      expect(executor.undoCount, 2);
      expect(executor.redoCount, 1);
    });

    test('undo throws when nothing to undo', () {
      expect(executor.undo, throwsStateError);
    });

    test('redo throws when nothing to redo', () {
      expect(executor.redo, throwsStateError);
    });

    test('clearHistory empties both stacks', () {
      executor
        ..execute(const AddCommand(5))
        ..execute(const AddCommand(3))
        ..undo()
        ..clearHistory();

      expect(executor.canUndo, isFalse);
      expect(executor.canRedo, isFalse);
      expect(notifier.state, 5);
    });

    test('works with different command types', () {
      executor
        ..execute(const AddCommand(5))
        ..execute(const MultiplyCommand(3));

      expect(notifier.state, 15);

      executor.undo();
      expect(notifier.state, 5);

      executor.undo();
      expect(notifier.state, 0);
    });

    // New: batch commands
    test('executeBatch applies multiple commands as one undo step', () {
      executor.executeBatch([
        const AddCommand(5),
        const MultiplyCommand(3),
      ]);

      expect(notifier.state, 15);
      expect(executor.undoCount, 1);

      executor.undo();
      expect(notifier.state, 0);
    });

    test('VeloxBatchCommand undo reverses in correct order', () {
      executor.executeBatch([
        const AddCommand(10),
        const MultiplyCommand(2),
        const AddCommand(5),
      ]);

      // (0 + 10) * 2 + 5 = 25
      expect(notifier.state, 25);

      executor.undo();
      expect(notifier.state, 0);
    });

    // New: configurable history size
    test('maxHistorySize trims old commands', () {
      final limited = VeloxCommandExecutor<int>(notifier, maxHistorySize: 3)
        ..execute(const AddCommand(1))
        ..execute(const AddCommand(2))
        ..execute(const AddCommand(3))
        ..execute(const AddCommand(4))
        ..execute(const AddCommand(5));

      expect(notifier.state, 15);
      expect(limited.undoCount, 3);

      // Can only undo 3 times (AddCommand(3), AddCommand(4), AddCommand(5))
      limited
        ..undo()
        ..undo()
        ..undo();
      // 15 - 5 - 4 - 3 = 3
      expect(notifier.state, 3);
      expect(limited.canUndo, isFalse);
    });

    // New: undoAll / redoAll
    test('undoAll undoes all commands', () {
      executor
        ..execute(const AddCommand(1))
        ..execute(const AddCommand(2))
        ..execute(const AddCommand(3))
        ..undoAll();

      expect(notifier.state, 0);
      expect(executor.canUndo, isFalse);
      expect(executor.redoCount, 3);
    });

    test('redoAll redoes all commands', () {
      executor
        ..execute(const AddCommand(1))
        ..execute(const AddCommand(2))
        ..execute(const AddCommand(3))
        ..undoAll()
        ..redoAll();

      expect(notifier.state, 6);
      expect(executor.canRedo, isFalse);
    });

    // New: checkpoints
    test('saveCheckpoint and restoreCheckpoint', () {
      executor
        ..execute(const AddCommand(10))
        ..saveCheckpoint('before-multiply')
        ..execute(const MultiplyCommand(5));

      expect(notifier.state, 50);

      executor.restoreCheckpoint('before-multiply');
      expect(notifier.state, 10);
    });

    test('restoreCheckpoint throws for unknown name', () {
      expect(
        () => executor.restoreCheckpoint('nonexistent'),
        throwsStateError,
      );
    });

    test('hasCheckpoint and removeCheckpoint', () {
      executor
        ..execute(const AddCommand(1))
        ..saveCheckpoint('cp1');

      expect(executor.hasCheckpoint('cp1'), isTrue);
      expect(executor.hasCheckpoint('cp2'), isFalse);

      expect(executor.removeCheckpoint('cp1'), isTrue);
      expect(executor.removeCheckpoint('cp1'), isFalse);
    });

    test('checkpointNames returns all saved names', () {
      executor
        ..execute(const AddCommand(1))
        ..saveCheckpoint('a')
        ..execute(const AddCommand(2))
        ..saveCheckpoint('b');

      expect(executor.checkpointNames, containsAll(['a', 'b']));
    });
  });

  // =========================================================================
  // VeloxSelector (existing tests)
  // =========================================================================
  group('VeloxSelector', () {
    late VeloxNotifier<Map<String, int>> notifier;

    setUp(() {
      notifier = VeloxNotifier<Map<String, int>>({'a': 1, 'b': 2});
    });

    tearDown(() {
      if (!notifier.isDisposed) {
        notifier.dispose();
      }
    });

    test('has initial derived value', () {
      final selector = VeloxSelector<Map<String, int>, int>(
        source: notifier,
        selector: (state) => state['a']!,
      );

      expect(selector.value, 1);
      selector.dispose();
    });

    test('updates when selected value changes', () {
      final selector = VeloxSelector<Map<String, int>, int>(
        source: notifier,
        selector: (state) => state['a']!,
      );
      final values = <int>[];
      selector.addListener(values.add);

      notifier.setState({'a': 10, 'b': 2});

      expect(selector.value, 10);
      expect(values, [10]);
      selector.dispose();
    });

    test('does not notify when selected value is unchanged', () {
      final selector = VeloxSelector<Map<String, int>, int>(
        source: notifier,
        selector: (state) => state['a']!,
      );
      final values = <int>[];
      selector.addListener(values.add);

      // Change b but not a.
      notifier.setState({'a': 1, 'b': 99});

      expect(values, isEmpty);
      selector.dispose();
    });

    test('stream emits only when value changes', () async {
      final selector = VeloxSelector<Map<String, int>, int>(
        source: notifier,
        selector: (state) => state['a']!,
      );

      final future = selector.stream.take(2).toList();

      notifier
        ..setState({'a': 1, 'b': 99}) // a unchanged, no emit
        ..setState({'a': 5, 'b': 99}) // a changed, emit 5
        ..setState({'a': 5, 'b': 42}) // a unchanged, no emit
        ..setState({'a': 7, 'b': 42}); // a changed, emit 7

      final values = await future;
      expect(values, [5, 7]);
      selector.dispose();
    });

    test('supports custom equality', () {
      // Treat values as equal if their difference is less than 3.
      final selector = VeloxSelector<Map<String, int>, int>(
        source: notifier,
        selector: (state) => state['a']!,
        equals: (prev, next) => (prev - next).abs() < 3,
      );
      final values = <int>[];
      selector.addListener(values.add);

      notifier
        ..setState({'a': 2, 'b': 2}) // diff 1, considered equal
        ..setState({'a': 10, 'b': 2}); // diff 8, considered different

      expect(values, [10]);
      selector.dispose();
    });

    test('removeListener stops notifications', () {
      final selector = VeloxSelector<Map<String, int>, int>(
        source: notifier,
        selector: (state) => state['a']!,
      );
      final values = <int>[];
      void listener(int v) => values.add(v);

      selector
        ..addListener(listener)
        ..removeListener(listener);

      notifier.setState({'a': 99, 'b': 2});

      expect(values, isEmpty);
      selector.dispose();
    });

    test('dispose stops listening to source', () {
      final selector = VeloxSelector<Map<String, int>, int>(
        source: notifier,
        selector: (state) => state['a']!,
      );
      final values = <int>[];
      selector
        ..addListener(values.add)
        ..dispose();

      notifier.setState({'a': 99, 'b': 2});

      expect(values, isEmpty);
      expect(selector.isDisposed, isTrue);
    });

    test('throws StateError when used after dispose', () {
      final selector = VeloxSelector<Map<String, int>, int>(
        source: notifier,
        selector: (state) => state['a']!,
      )..dispose();

      expect(() => selector.addListener((_) {}), throwsStateError);
      expect(() => selector.stream, throwsStateError);
      expect(selector.dispose, throwsStateError);
    });
  });

  // =========================================================================
  // AsyncValue
  // =========================================================================
  group('AsyncValue', () {
    test('AsyncLoading equality', () {
      expect(const AsyncLoading<int>(), equals(const AsyncLoading<int>()));
      expect(const AsyncLoading<int>().toString(), 'AsyncLoading<int>()');
    });

    test('AsyncData equality', () {
      expect(const AsyncData<int>(42), equals(const AsyncData<int>(42)));
      expect(const AsyncData<int>(42), isNot(equals(const AsyncData<int>(7))));
      expect(const AsyncData<int>(42).toString(), 'AsyncData<int>(42)');
    });

    test('AsyncError equality', () {
      expect(
        const AsyncError<int>('oops'),
        equals(const AsyncError<int>('oops')),
      );
      expect(
        const AsyncError<int>('oops'),
        isNot(equals(const AsyncError<int>('nope'))),
      );
      expect(const AsyncError<int>('oops').toString(), 'AsyncError<int>(oops)');
    });

    test('when folds all cases correctly', () {
      final loading = const AsyncLoading<int>().when(
        loading: () => 'loading',
        onData: (d) => 'data: $d',
        onError: (e, _) => 'error: $e',
      );
      expect(loading, 'loading');

      final data = const AsyncData<int>(42).when(
        loading: () => 'loading',
        onData: (d) => 'data: $d',
        onError: (e, _) => 'error: $e',
      );
      expect(data, 'data: 42');

      final error = const AsyncError<int>('fail').when(
        loading: () => 'loading',
        onData: (d) => 'data: $d',
        onError: (e, _) => 'error: $e',
      );
      expect(error, 'error: fail');
    });

    test('whenOrNull returns null for unhandled cases', () {
      final result = const AsyncLoading<int>().whenOrNull<String>(
        onData: (d) => 'data: $d',
      );
      expect(result, isNull);
    });

    test('whenOrNull calls matching callback', () {
      final result = const AsyncData<int>(10).whenOrNull<String>(
        onData: (d) => 'data: $d',
      );
      expect(result, 'data: 10');
    });

    test('map transforms data while preserving loading', () {
      final mapped = const AsyncLoading<int>().map((d) => d.toString());
      expect(mapped, isA<AsyncLoading<String>>());
    });

    test('map transforms data value', () {
      final mapped = const AsyncData<int>(5).map((d) => d * 2);
      expect(mapped, equals(const AsyncData<int>(10)));
    });

    test('map preserves error', () {
      final mapped = const AsyncError<int>('fail').map((d) => d.toString());
      expect(mapped, isA<AsyncError<String>>());
      expect((mapped as AsyncError<String>).error, 'fail');
    });
  });

  // =========================================================================
  // VeloxAsyncNotifier
  // =========================================================================
  group('VeloxAsyncNotifier', () {
    test('starts in loading state', () {
      final notifier = VeloxAsyncNotifier<int>();
      expect(notifier.isLoading, isTrue);
      expect(notifier.hasData, isFalse);
      expect(notifier.hasError, isFalse);
      expect(notifier.data, isNull);
      expect(notifier.error, isNull);
      notifier.dispose();
    });

    test('withData starts with data', () {
      final notifier = VeloxAsyncNotifier<int>.withData(42);
      expect(notifier.hasData, isTrue);
      expect(notifier.data, 42);
      notifier.dispose();
    });

    test('setData transitions to data state', () {
      final notifier = VeloxAsyncNotifier<int>()..setData(10);
      expect(notifier.hasData, isTrue);
      expect(notifier.data, 10);
      notifier.dispose();
    });

    test('setError transitions to error state', () {
      final notifier = VeloxAsyncNotifier<int>()..setError('boom');
      expect(notifier.hasError, isTrue);
      expect(notifier.error, 'boom');
      notifier.dispose();
    });

    test('setLoading transitions to loading state', () {
      final notifier = VeloxAsyncNotifier<int>.withData(5)..setLoading();
      expect(notifier.isLoading, isTrue);
      notifier.dispose();
    });

    test('guard transitions through loading -> data', () async {
      final notifier = VeloxAsyncNotifier<int>();
      final states = <AsyncValue<int>>[];
      notifier.addListener(states.add);

      final result = await notifier.guard(() async => 42);

      expect(result, 42);
      expect(notifier.data, 42);
      expect(states.length, 2); // loading, then data
      expect(states[0], isA<AsyncLoading<int>>());
      expect(states[1], isA<AsyncData<int>>());
      notifier.dispose();
    });

    test('guard transitions through loading -> error on failure', () async {
      final notifier = VeloxAsyncNotifier<int>();
      final states = <AsyncValue<int>>[];
      notifier.addListener(states.add);

      final result = await notifier.guard(() async => throw Exception('fail'));

      expect(result, isNull);
      expect(notifier.hasError, isTrue);
      expect(states.length, 2);
      expect(states[0], isA<AsyncLoading<int>>());
      expect(states[1], isA<AsyncError<int>>());
      notifier.dispose();
    });
  });

  // =========================================================================
  // VeloxComputed
  // =========================================================================
  group('VeloxComputed', () {
    test('computes initial value', () {
      final a = VeloxNotifier<int>(2);
      final b = VeloxNotifier<int>(3);
      final sum = VeloxComputed<int>(
        dependencies: [a, b],
        compute: () => a.state + b.state,
      );

      expect(sum.value, 5);

      sum.dispose();
      a.dispose();
      b.dispose();
    });

    test('recomputes when dependency changes', () {
      final a = VeloxNotifier<int>(2);
      final b = VeloxNotifier<int>(3);
      final sum = VeloxComputed<int>(
        dependencies: [a, b],
        compute: () => a.state + b.state,
      );
      final values = <int>[];
      sum.addListener(values.add);

      a.setState(10);
      expect(sum.value, 13);
      expect(values, [13]);

      b.setState(7);
      expect(sum.value, 17);
      expect(values, [13, 17]);

      sum.dispose();
      a.dispose();
      b.dispose();
    });

    test('does not notify when computed value is unchanged', () {
      final a = VeloxNotifier<int>(2);
      final b = VeloxNotifier<int>(3);
      // Even parity: returns 0 if sum is even, 1 if odd
      final parity = VeloxComputed<int>(
        dependencies: [a, b],
        compute: () => (a.state + b.state) % 2,
      );
      final values = <int>[];
      parity.addListener(values.add);

      // sum was 5 (odd=1), change a to 4 => sum=7 (still odd=1)
      a.setState(4);
      expect(values, isEmpty);

      // Now change a to 5 => sum=8 (even=0)
      a.setState(5);
      expect(values, [0]);

      parity.dispose();
      a.dispose();
      b.dispose();
    });

    test('stream emits computed values', () async {
      final a = VeloxNotifier<int>(1);
      final computed = VeloxComputed<int>(
        dependencies: [a],
        compute: () => a.state * 10,
      );

      final future = computed.stream.take(2).toList();

      a
        ..setState(2)
        ..setState(3);

      final values = await future;
      expect(values, [20, 30]);

      computed.dispose();
      a.dispose();
    });

    test('supports custom equality', () {
      final a = VeloxNotifier<int>(10);
      final computed = VeloxComputed<int>(
        dependencies: [a],
        compute: () => a.state,
        equals: (prev, next) => (prev - next).abs() < 5,
      );
      final values = <int>[];
      computed.addListener(values.add);

      a.setState(12); // diff 2, treated as equal
      expect(values, isEmpty);

      a.setState(20); // diff 8, treated as different
      expect(values, [20]);

      computed.dispose();
      a.dispose();
    });

    test('dispose stops listening to dependencies', () {
      final a = VeloxNotifier<int>(1);
      final computed = VeloxComputed<int>(
        dependencies: [a],
        compute: () => a.state,
      );
      final values = <int>[];
      computed
        ..addListener(values.add)
        ..dispose();

      a.setState(99);
      expect(values, isEmpty);
      a.dispose();
    });

    test('throws StateError when used after dispose', () {
      final a = VeloxNotifier<int>(0);
      final computed = VeloxComputed<int>(
        dependencies: [a],
        compute: () => a.state,
      )..dispose();

      expect(() => computed.addListener((_) {}), throwsStateError);
      expect(() => computed.stream, throwsStateError);
      expect(computed.dispose, throwsStateError);

      a.dispose();
    });
  });

  // =========================================================================
  // VeloxMiddleware
  // =========================================================================
  group('VeloxMiddleware', () {
    test('middleware can modify state', () {
      final notifier = VeloxMiddlewareNotifier<int>(
        0,
        middleware: [const ClampMiddleware(0, 10)],
      )..setState(50);

      expect(notifier.state, 10);

      notifier.setState(-5);
      expect(notifier.state, 0);

      notifier.dispose();
    });

    test('middleware can reject state change', () {
      final notifier = VeloxMiddlewareNotifier<int>(
        5,
        middleware: [const RejectNegativeMiddleware()],
      )..setState(-1);

      expect(notifier.state, 5); // unchanged

      notifier.setState(10);
      expect(notifier.state, 10);

      notifier.dispose();
    });

    test('middleware chain executes in order', () {
      final logger = LoggingMiddleware<int>();
      final notifier = VeloxMiddlewareNotifier<int>(
        0,
        middleware: [logger, const ClampMiddleware(0, 100)],
      )..setState(50);

      expect(logger.log, ['0 -> 50']);
      expect(notifier.state, 50);

      notifier.dispose();
    });

    test('addMiddleware appends to chain', () {
      final notifier = VeloxMiddlewareNotifier<int>(0)
        ..addMiddleware(const ClampMiddleware(0, 10))
        ..setState(20);

      expect(notifier.state, 10);

      notifier.dispose();
    });

    test('removeMiddleware removes from chain', () {
      const clamp = ClampMiddleware(0, 10);
      final notifier = VeloxMiddlewareNotifier<int>(0, middleware: [clamp])
        ..removeMiddleware(clamp)
        ..setState(20);

      expect(notifier.state, 20);

      notifier.dispose();
    });

    test('update goes through middleware', () {
      final notifier = VeloxMiddlewareNotifier<int>(
        5,
        middleware: [const ClampMiddleware(0, 10)],
      )..update((s) => s + 100);

      expect(notifier.state, 10);

      notifier.dispose();
    });

    test('middleware getter returns unmodifiable list', () {
      final notifier = VeloxMiddlewareNotifier<int>(
        0,
        middleware: [const ClampMiddleware(0, 10)],
      );

      expect(notifier.middleware.length, 1);
      expect(
        () => notifier.middleware.add(const RejectNegativeMiddleware()),
        throwsA(isA<UnsupportedError>()),
      );

      notifier.dispose();
    });
  });

  // =========================================================================
  // VeloxPersistedNotifier
  // =========================================================================
  group('VeloxPersistedNotifier', () {
    test('persists state on setState', () async {
      final strategy = InMemoryPersistenceStrategy<int>();
      final notifier = VeloxPersistedNotifier<int>(0, strategy: strategy)
        ..setState(42);

      expect(await strategy.load(), 42);
      notifier.dispose();
    });

    test('persists state on update', () async {
      final strategy = InMemoryPersistenceStrategy<int>();
      final notifier = VeloxPersistedNotifier<int>(10, strategy: strategy)
        ..update((s) => s * 2);

      expect(await strategy.load(), 20);
      notifier.dispose();
    });

    test('hydrate restores persisted state', () async {
      final strategy = InMemoryPersistenceStrategy<int>();
      await strategy.save(99);

      final notifier = VeloxPersistedNotifier<int>(0, strategy: strategy);
      await notifier.hydrate();

      expect(notifier.state, 99);
      expect(notifier.isHydrated, isTrue);
      notifier.dispose();
    });

    test('hydrate keeps initial state when nothing persisted', () async {
      final strategy = InMemoryPersistenceStrategy<int>();
      final notifier = VeloxPersistedNotifier<int>(7, strategy: strategy);

      await notifier.hydrate();

      expect(notifier.state, 7);
      expect(notifier.isHydrated, isTrue);
      notifier.dispose();
    });

    test('clearPersisted removes stored data', () async {
      final strategy = InMemoryPersistenceStrategy<int>();
      final notifier = VeloxPersistedNotifier<int>(0, strategy: strategy)
        ..setState(42);
      await notifier.clearPersisted();

      expect(await strategy.load(), isNull);
      expect(notifier.state, 42); // in-memory state unchanged
      notifier.dispose();
    });

    test('InMemoryPersistenceStrategy tracks stored state', () async {
      final strategy = InMemoryPersistenceStrategy<String>();

      expect(strategy.hasStored, isFalse);
      expect(strategy.stored, isNull);

      await strategy.save('hello');
      expect(strategy.hasStored, isTrue);
      expect(strategy.stored, 'hello');

      await strategy.clear();
      expect(strategy.hasStored, isFalse);
    });
  });

  // =========================================================================
  // VeloxStateObserver
  // =========================================================================
  group('VeloxStateObserver', () {
    setUp(VeloxStateObserver.clearObservers);

    tearDown(VeloxStateObserver.clearObservers);

    test('addObserver registers and notifyAll calls observers', () {
      final observer = TestObserver();
      VeloxStateObserver.addObserver(observer);

      VeloxStateObserver.notifyAll<int>('counter', 0, 1);

      expect(observer.changes, ['counter: 0 -> 1']);
    });

    test('removeObserver stops notifications', () {
      final observer = TestObserver();
      VeloxStateObserver.addObserver(observer);
      VeloxStateObserver.removeObserver(observer);

      VeloxStateObserver.notifyAll<int>('counter', 0, 1);

      expect(observer.changes, isEmpty);
    });

    test('clearObservers removes all observers', () {
      final a = TestObserver();
      final b = TestObserver();
      VeloxStateObserver.addObserver(a);
      VeloxStateObserver.addObserver(b);

      VeloxStateObserver.clearObservers();
      VeloxStateObserver.notifyAll<int>('x', 0, 1);

      expect(a.changes, isEmpty);
      expect(b.changes, isEmpty);
    });

    test('observers getter returns current list', () {
      final observer = TestObserver();
      VeloxStateObserver.addObserver(observer);

      expect(VeloxStateObserver.observers.length, 1);
      expect(VeloxStateObserver.observers.first, observer);
    });

    test('multiple observers receive same notification', () {
      final a = TestObserver();
      final b = TestObserver();
      VeloxStateObserver.addObserver(a);
      VeloxStateObserver.addObserver(b);

      VeloxStateObserver.notifyAll<String>('name', 'old', 'new');

      expect(a.changes, ['name: old -> new']);
      expect(b.changes, ['name: old -> new']);
    });
  });

  // =========================================================================
  // VeloxDebouncedNotifier
  // =========================================================================
  group('VeloxDebouncedNotifier', () {
    test('state is updated immediately', () {
      final notifier = VeloxDebouncedNotifier<int>(
        0,
        duration: const Duration(milliseconds: 100),
      )..setState(42);

      expect(notifier.state, 42); // immediate read

      notifier.dispose();
    });

    test('listeners are notified after debounce period', () async {
      final values = <int>[];
      final notifier = VeloxDebouncedNotifier<int>(
        0,
        duration: const Duration(milliseconds: 50),
      )
        ..addListener(values.add)
        ..setState(1)
        ..setState(2)
        ..setState(3);

      // Immediately: no notifications yet
      expect(values, isEmpty);

      // Wait for the debounce
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Only the final value should have been emitted
      expect(values, [3]);
      notifier.dispose();
    });

    test('flush forces immediate notification', () {
      final values = <int>[];
      final notifier = VeloxDebouncedNotifier<int>(
        0,
        duration: const Duration(seconds: 10),
      )
        ..addListener(values.add)
        ..setState(5)
        ..flush();

      expect(values, [5]);
      notifier.dispose();
    });

    test('update works with debouncing', () async {
      final values = <int>[];
      final notifier = VeloxDebouncedNotifier<int>(
        0,
        duration: const Duration(milliseconds: 50),
      )
        ..addListener(values.add)
        ..update((s) => s + 1)
        ..update((s) => s + 1)
        ..update((s) => s + 1);

      expect(notifier.state, 3);
      expect(values, isEmpty);

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(values, [3]);

      notifier.dispose();
    });

    test('stream emits debounced values', () async {
      final notifier = VeloxDebouncedNotifier<int>(
        0,
        duration: const Duration(milliseconds: 50),
      );

      final future = notifier.stream.first;

      notifier
        ..setState(1)
        ..setState(2)
        ..setState(3);

      final value = await future;
      expect(value, 3);
      notifier.dispose();
    });

    test('dispose cancels pending timer', () async {
      final values = <int>[];
      VeloxDebouncedNotifier<int>(
        0,
        duration: const Duration(milliseconds: 50),
      )
        ..addListener(values.add)
        ..setState(42)
        ..dispose();

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(values, isEmpty);
    });

    test('throws StateError when used after dispose', () {
      final notifier = VeloxDebouncedNotifier<int>(
        0,
        duration: const Duration(milliseconds: 50),
      )..dispose();

      expect(() => notifier.setState(1), throwsStateError);
      expect(() => notifier.update((s) => s + 1), throwsStateError);
      expect(() => notifier.addListener((_) {}), throwsStateError);
      expect(notifier.flush, throwsStateError);
      expect(() => notifier.stream, throwsStateError);
      expect(notifier.dispose, throwsStateError);
    });

    test('removeListener stops debounced notifications', () async {
      final values = <int>[];
      void listener(int v) => values.add(v);
      final notifier = VeloxDebouncedNotifier<int>(
        0,
        duration: const Duration(milliseconds: 50),
      )
        ..addListener(listener)
        ..setState(10)
        ..removeListener(listener);

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(values, isEmpty);

      notifier.dispose();
    });
  });

  // =========================================================================
  // VeloxNotifierFamily
  // =========================================================================
  group('VeloxNotifierFamily', () {
    test('creates notifier for new key', () {
      final family = VeloxNotifierFamily<String, int>(create: (_) => 0);

      final notifier = family('home');

      expect(notifier.state, 0);
      expect(family.length, 1);

      family.disposeAll();
    });

    test('returns same notifier for same key', () {
      final family = VeloxNotifierFamily<String, int>(create: (_) => 0);

      final a = family('key');
      final b = family('key');

      expect(identical(a, b), isTrue);

      family.disposeAll();
    });

    test('creates separate notifiers for different keys', () {
      final family = VeloxNotifierFamily<String, int>(create: (_) => 0);

      final a = family('a');
      final b = family('b');

      expect(identical(a, b), isFalse);
      expect(family.length, 2);

      family.disposeAll();
    });

    test('create receives the key', () {
      final family = VeloxNotifierFamily<int, int>(create: (key) => key * 10);

      expect(family(3).state, 30);
      expect(family(5).state, 50);

      family.disposeAll();
    });

    test('get returns null for non-existent key', () {
      final family = VeloxNotifierFamily<String, int>(create: (_) => 0);

      expect(family.get('x'), isNull);

      family.disposeAll();
    });

    test('get returns existing notifier', () {
      final family = VeloxNotifierFamily<String, int>(create: (_) => 0);
      final notifier = family('x');

      expect(identical(family.get('x'), notifier), isTrue);

      family.disposeAll();
    });

    test('containsKey checks existence', () {
      final family = VeloxNotifierFamily<String, int>(create: (_) => 0);

      expect(family.containsKey('a'), isFalse);
      family('a');
      expect(family.containsKey('a'), isTrue);

      family.disposeAll();
    });

    test('keys and values return cached entries', () {
      final family = VeloxNotifierFamily<String, int>(create: (_) => 0);
      family('a');
      family('b');

      expect(family.keys, containsAll(['a', 'b']));
      expect(family.values.length, 2);

      family.disposeAll();
    });

    test('remove disposes and removes notifier', () {
      final family = VeloxNotifierFamily<String, int>(create: (_) => 0);
      final notifier = family('x');

      expect(family.remove('x'), isTrue);
      expect(notifier.isDisposed, isTrue);
      expect(family.containsKey('x'), isFalse);

      expect(family.remove('x'), isFalse);
    });

    test('disposeAll disposes all and clears', () {
      final family = VeloxNotifierFamily<String, int>(create: (_) => 0);
      final a = family('a');
      final b = family('b');

      family.disposeAll();

      expect(a.isDisposed, isTrue);
      expect(b.isDisposed, isTrue);
      expect(family.length, 0);
    });
  });
}

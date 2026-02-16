import 'package:test/test.dart';
import 'package:velox_state/velox_state.dart';

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

void main() {
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
  });

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
}

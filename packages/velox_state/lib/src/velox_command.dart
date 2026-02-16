import 'package:velox_state/src/velox_notifier.dart';

/// A reversible operation that transforms state.
///
/// [VeloxCommand] encapsulates a state transition along with its inverse,
/// enabling undo/redo functionality when used with [VeloxCommandExecutor].
///
/// ```dart
/// class IncrementCommand extends VeloxCommand<int> {
///   const IncrementCommand(this.amount);
///   final int amount;
///
///   @override
///   int execute(int state) => state + amount;
///
///   @override
///   int undo(int state) => state - amount;
/// }
/// ```
abstract class VeloxCommand<T> {
  /// Creates a [VeloxCommand].
  const VeloxCommand();

  /// Applies this command to the given [state] and returns the new state.
  T execute(T state);

  /// Reverses this command on the given [state] and returns the prior state.
  T undo(T state);
}

/// Executes [VeloxCommand] instances against a [VeloxNotifier] and maintains
/// an undo/redo history.
///
/// ```dart
/// final notifier = VeloxNotifier<int>(0);
/// final executor = VeloxCommandExecutor<int>(notifier);
///
/// executor.execute(IncrementCommand(5)); // state -> 5
/// executor.execute(IncrementCommand(3)); // state -> 8
/// executor.undo();                       // state -> 5
/// executor.redo();                       // state -> 8
/// ```
class VeloxCommandExecutor<T> {
  /// Creates a [VeloxCommandExecutor] that operates on the given [notifier].
  VeloxCommandExecutor(this.notifier);

  /// The notifier whose state this executor manages.
  final VeloxNotifier<T> notifier;

  final List<VeloxCommand<T>> _undoStack = [];
  final List<VeloxCommand<T>> _redoStack = [];

  /// Whether there are commands that can be undone.
  bool get canUndo => _undoStack.isNotEmpty;

  /// Whether there are commands that can be redone.
  bool get canRedo => _redoStack.isNotEmpty;

  /// The number of commands in the undo history.
  int get undoCount => _undoStack.length;

  /// The number of commands in the redo history.
  int get redoCount => _redoStack.length;

  /// Executes the given [command] and pushes it onto the undo stack.
  ///
  /// Executing a new command clears the redo stack because the prior
  /// future history is no longer valid.
  void execute(VeloxCommand<T> command) {
    final newState = command.execute(notifier.state);
    notifier.setState(newState);
    _undoStack.add(command);
    _redoStack.clear();
  }

  /// Undoes the most recent command.
  ///
  /// Throws a [StateError] if there are no commands to undo.
  void undo() {
    if (!canUndo) {
      throw StateError('Nothing to undo.');
    }
    final command = _undoStack.removeLast();
    final newState = command.undo(notifier.state);
    notifier.setState(newState);
    _redoStack.add(command);
  }

  /// Redoes the most recently undone command.
  ///
  /// Throws a [StateError] if there are no commands to redo.
  void redo() {
    if (!canRedo) {
      throw StateError('Nothing to redo.');
    }
    final command = _redoStack.removeLast();
    final newState = command.execute(notifier.state);
    notifier.setState(newState);
    _undoStack.add(command);
  }

  /// Clears both the undo and redo history without changing the state.
  void clearHistory() {
    _undoStack.clear();
    _redoStack.clear();
  }
}

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

/// A command that groups multiple commands into a single undoable unit.
///
/// When executed, all inner commands are applied in order. When undone, they
/// are reversed in the opposite order. This allows multiple operations to be
/// treated as a single atomic undo/redo step.
///
/// ```dart
/// final batch = VeloxBatchCommand<int>([
///   AddCommand(5),
///   MultiplyCommand(2),
/// ]);
/// executor.execute(batch); // state: (0 + 5) * 2 = 10
/// executor.undo();         // state: 0
/// ```
class VeloxBatchCommand<T> extends VeloxCommand<T> {
  /// Creates a [VeloxBatchCommand] that wraps the given [commands].
  VeloxBatchCommand(this.commands);

  /// The list of commands executed as a batch.
  final List<VeloxCommand<T>> commands;

  @override
  T execute(T state) {
    var current = state;
    for (final command in commands) {
      current = command.execute(current);
    }
    return current;
  }

  @override
  T undo(T state) {
    var current = state;
    for (final command in commands.reversed) {
      current = command.undo(current);
    }
    return current;
  }
}

/// A named snapshot of state that can be restored later.
///
/// Checkpoints are stored inside a [VeloxCommandExecutor] and allow users to
/// revert to a specific named point in history.
class VeloxCheckpoint<T> {
  /// Creates a [VeloxCheckpoint] with the given [name], [state], and the
  /// number of commands in the undo stack at that point ([undoIndex]).
  const VeloxCheckpoint({
    required this.name,
    required this.state,
    required this.undoIndex,
  });

  /// The human-readable name of this checkpoint.
  final String name;

  /// The state at the time the checkpoint was created.
  final T state;

  /// The undo stack index at the time the checkpoint was created.
  final int undoIndex;
}

/// Executes [VeloxCommand] instances against a [VeloxNotifier] and maintains
/// an undo/redo history.
///
/// Supports configurable history size, batch commands, and named checkpoints.
///
/// ```dart
/// final notifier = VeloxNotifier<int>(0);
/// final executor = VeloxCommandExecutor<int>(notifier, maxHistorySize: 50);
///
/// executor.execute(IncrementCommand(5)); // state -> 5
/// executor.execute(IncrementCommand(3)); // state -> 8
/// executor.saveCheckpoint('before-multiply');
/// executor.undo();                       // state -> 5
/// executor.redo();                       // state -> 8
/// ```
class VeloxCommandExecutor<T> {
  /// Creates a [VeloxCommandExecutor] that operates on the given [notifier].
  ///
  /// [maxHistorySize] limits the number of commands kept in the undo stack.
  /// When the limit is reached, the oldest commands are discarded. A value of
  /// `null` means unlimited history (the default).
  VeloxCommandExecutor(this.notifier, {this.maxHistorySize});

  /// The notifier whose state this executor manages.
  final VeloxNotifier<T> notifier;

  /// The maximum number of commands to keep in the undo history, or `null`
  /// for unlimited.
  final int? maxHistorySize;

  final List<VeloxCommand<T>> _undoStack = [];
  final List<VeloxCommand<T>> _redoStack = [];
  final Map<String, VeloxCheckpoint<T>> _checkpoints = {};

  /// Whether there are commands that can be undone.
  bool get canUndo => _undoStack.isNotEmpty;

  /// Whether there are commands that can be redone.
  bool get canRedo => _redoStack.isNotEmpty;

  /// The number of commands in the undo history.
  int get undoCount => _undoStack.length;

  /// The number of commands in the redo history.
  int get redoCount => _redoStack.length;

  /// Returns the names of all saved checkpoints.
  List<String> get checkpointNames =>
      _checkpoints.keys.toList(growable: false);

  /// Executes the given [command] and pushes it onto the undo stack.
  ///
  /// Executing a new command clears the redo stack because the prior
  /// future history is no longer valid.
  void execute(VeloxCommand<T> command) {
    final newState = command.execute(notifier.state);
    notifier.setState(newState);
    _undoStack.add(command);
    _redoStack.clear();
    _trimHistory();
  }

  /// Executes a list of [commands] as a single [VeloxBatchCommand].
  ///
  /// All commands are applied in order and treated as one undo/redo step.
  void executeBatch(List<VeloxCommand<T>> commands) {
    execute(VeloxBatchCommand<T>(commands));
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

  /// Undoes all commands, returning to the initial state.
  void undoAll() {
    while (canUndo) {
      undo();
    }
  }

  /// Redoes all commands that were undone.
  void redoAll() {
    while (canRedo) {
      redo();
    }
  }

  /// Saves a named checkpoint at the current state.
  ///
  /// If a checkpoint with the same [name] already exists, it is overwritten.
  void saveCheckpoint(String name) {
    _checkpoints[name] = VeloxCheckpoint<T>(
      name: name,
      state: notifier.state,
      undoIndex: _undoStack.length,
    );
  }

  /// Restores the state to the checkpoint with the given [name].
  ///
  /// This sets the notifier state directly and clears the undo/redo history
  /// because the history is no longer consistent after a jump.
  ///
  /// Throws a [StateError] if no checkpoint with [name] exists.
  void restoreCheckpoint(String name) {
    final checkpoint = _checkpoints[name];
    if (checkpoint == null) {
      throw StateError('No checkpoint named "$name".');
    }
    notifier.setState(checkpoint.state);
    _undoStack.clear();
    _redoStack.clear();
    // Remove all checkpoints including and after the restored one
    _checkpoints.remove(name);
  }

  /// Removes the checkpoint with the given [name].
  ///
  /// Returns `true` if a checkpoint was removed, `false` if it did not exist.
  bool removeCheckpoint(String name) => _checkpoints.remove(name) != null;

  /// Whether a checkpoint with the given [name] exists.
  bool hasCheckpoint(String name) => _checkpoints.containsKey(name);

  /// Clears both the undo and redo history without changing the state.
  void clearHistory() {
    _undoStack.clear();
    _redoStack.clear();
    _checkpoints.clear();
  }

  void _trimHistory() {
    final max = maxHistorySize;
    if (max != null) {
      while (_undoStack.length > max) {
        _undoStack.removeAt(0);
      }
    }
  }
}

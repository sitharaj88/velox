// ignore_for_file: avoid_print, unused_local_variable
import 'package:velox_state/velox_state.dart';

/// A command that adds [amount] to the counter state.
class IncrementCommand extends VeloxCommand<int> {
  const IncrementCommand(this.amount);
  final int amount;

  @override
  int execute(int state) => state + amount;

  @override
  int undo(int state) => state - amount;
}

void main() {
  // --- VeloxNotifier ---
  print('=== VeloxNotifier ===');

  final counter = VeloxNotifier<int>(0);
  counter.addListener((state) => print('  Listener: $state'));

  counter.setState(1);
  counter.update((s) => s + 10);
  print('  Current state: ${counter.state}');

  // --- Stream ---
  print('\n=== Stream ===');
  counter.stream.listen((state) => print('  Stream: $state'));
  counter.setState(42);

  // --- VeloxCommand with undo/redo ---
  print('\n=== Commands ===');

  final notifier = VeloxNotifier<int>(0);
  final executor = VeloxCommandExecutor<int>(notifier);

  executor.execute(const IncrementCommand(5));
  print('  After +5: ${notifier.state}');

  executor.execute(const IncrementCommand(3));
  print('  After +3: ${notifier.state}');

  executor.undo();
  print('  After undo: ${notifier.state}');

  executor.redo();
  print('  After redo: ${notifier.state}');

  // --- VeloxSelector ---
  print('\n=== Selector ===');

  final userNotifier = VeloxNotifier<Map<String, Object>>({
    'name': 'Alice',
    'age': 30,
  });

  final nameSelector = VeloxSelector<Map<String, Object>, String>(
    source: userNotifier,
    selector: (state) => state['name']! as String,
  );

  nameSelector.addListener((name) => print('  Name changed: $name'));

  // Only age changes, selector does NOT notify.
  userNotifier.setState({'name': 'Alice', 'age': 31});
  print('  Name after age change: ${nameSelector.value}');

  // Name changes, selector notifies.
  userNotifier.setState({'name': 'Bob', 'age': 31});
  print('  Name after name change: ${nameSelector.value}');

  // Cleanup
  nameSelector.dispose();
  userNotifier.dispose();
  notifier.dispose();
  counter.dispose();
}

/// A lightweight reactive state management solution for Flutter.
///
/// Provides:
/// - [VeloxNotifier] for reactive state holding with listeners and streams
/// - [VeloxCommand] and [VeloxCommandExecutor] for the command pattern
///   with undo/redo support
/// - [VeloxSelector] for derived state that only updates when the selected
///   value changes
library;

export 'src/velox_command.dart';
export 'src/velox_notifier.dart';
export 'src/velox_selector.dart';

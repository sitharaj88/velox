/// A lightweight reactive state management solution for Flutter.
///
/// Provides:
/// - [VeloxNotifier] for reactive state holding with listeners and streams
/// - [VeloxCommand] and [VeloxCommandExecutor] for the command pattern
///   with undo/redo, batch commands, and named checkpoints
/// - [VeloxSelector] for derived state that only updates when the selected
///   value changes
/// - [VeloxComputed] for values derived from multiple notifiers
/// - [AsyncValue] and [VeloxAsyncNotifier] for async state management
/// - [VeloxMiddlewareNotifier] for intercepting state changes
/// - [VeloxPersistedNotifier] for state persistence
/// - [VeloxDebouncedNotifier] for debouncing rapid state changes
/// - [VeloxNotifierFamily] for keyed notifier creation and caching
/// - [VeloxStateObserver] for global state observation
library;

export 'src/async_value.dart';
export 'src/velox_async_notifier.dart';
export 'src/velox_command.dart';
export 'src/velox_computed.dart';
export 'src/velox_debounced_notifier.dart';
export 'src/velox_middleware.dart';
export 'src/velox_notifier.dart';
export 'src/velox_notifier_family.dart';
export 'src/velox_persisted_notifier.dart';
export 'src/velox_selector.dart';
export 'src/velox_state_observer.dart';

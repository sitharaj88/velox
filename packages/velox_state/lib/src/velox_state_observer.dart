/// A global observer that is notified of all state changes across notifiers.
///
/// Register observers with [VeloxStateObserver.addObserver] and they will
/// receive callbacks for every state change on any
/// [ObservableVeloxNotifier] instance.
///
/// This is useful for analytics, logging, debugging, and time-travel
/// debugging.
///
/// ```dart
/// class LoggingObserver extends VeloxStateObserver {
///   @override
///   void onStateChanged<T>(String name, T previousState, T newState) {
///     print('[$name] $previousState -> $newState');
///   }
/// }
///
/// VeloxStateObserver.addObserver(LoggingObserver());
/// ```
abstract class VeloxStateObserver {
  /// Creates a [VeloxStateObserver].
  const VeloxStateObserver();

  static final List<VeloxStateObserver> _observers = [];

  /// Registers a global [observer].
  static void addObserver(VeloxStateObserver observer) {
    _observers.add(observer);
  }

  /// Removes a previously registered [observer].
  static void removeObserver(VeloxStateObserver observer) {
    _observers.remove(observer);
  }

  /// Removes all registered observers.
  static void clearObservers() {
    _observers.clear();
  }

  /// Returns the current list of registered observers (read-only copy).
  static List<VeloxStateObserver> get observers =>
      List.unmodifiable(_observers);

  /// Notifies all registered observers of a state change.
  ///
  /// This is called internally by observable notifiers.
  static void notifyAll<T>(String name, T previousState, T newState) {
    for (final observer in List.of(_observers)) {
      observer.onStateChanged(name, previousState, newState);
    }
  }

  /// Called when any observable notifier's state changes.
  ///
  /// - [name] identifies the notifier that changed.
  /// - [previousState] is the state before the change.
  /// - [newState] is the state after the change.
  void onStateChanged<T>(String name, T previousState, T newState);
}

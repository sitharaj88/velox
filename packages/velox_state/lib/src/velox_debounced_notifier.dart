import 'dart:async';

import 'package:velox_state/src/velox_notifier.dart';

/// A [VeloxNotifier] that debounces notifications to listeners.
///
/// When multiple state changes occur in rapid succession, listeners are only
/// notified after a period of inactivity specified by [duration]. The state
/// value is always up-to-date when read via [state] - only notifications
/// are debounced.
///
/// ```dart
/// final search = VeloxDebouncedNotifier<String>(
///   '',
///   duration: Duration(milliseconds: 300),
/// );
///
/// search.addListener((query) {
///   // Only called 300ms after the last keystroke.
///   performSearch(query);
/// });
///
/// search.setState('h');
/// search.setState('he');
/// search.setState('hello');
/// // Listener fires once with 'hello' after 300ms of inactivity.
/// ```
class VeloxDebouncedNotifier<T> {
  /// Creates a [VeloxDebouncedNotifier] with the given [initialState] and
  /// debounce [duration].
  VeloxDebouncedNotifier(
    T initialState, {
    required this.duration,
  }) : _state = initialState;

  /// The debounce duration. Notifications are delayed by this amount after
  /// the last state change.
  final Duration duration;

  T _state;
  final List<void Function(T)> _listeners = [];
  StreamController<T>? _streamController;
  Stream<T>? _stream;
  bool _disposed = false;
  Timer? _debounceTimer;

  /// The current state value (always up-to-date, even before debounce fires).
  T get state => _state;

  /// Whether this notifier has been disposed.
  bool get isDisposed => _disposed;

  /// A broadcast [Stream] that emits debounced state changes.
  Stream<T> get stream {
    _assertNotDisposed();
    if (_streamController == null) {
      _streamController = StreamController<T>.broadcast();
      _stream = _streamController!.stream;
    }
    return _stream!;
  }

  /// Replaces the current state and schedules a debounced notification.
  void setState(T newState) {
    _assertNotDisposed();
    _state = newState;
    _scheduleNotification();
  }

  /// Updates the state using a function and schedules a debounced
  /// notification.
  void update(T Function(T current) updater) {
    _assertNotDisposed();
    _state = updater(_state);
    _scheduleNotification();
  }

  /// Registers a [listener] that is called when the debounced state changes.
  ///
  /// Returns a callback that removes the listener when called.
  VoidCallback addListener(void Function(T state) listener) {
    _assertNotDisposed();
    _listeners.add(listener);
    return () => removeListener(listener);
  }

  /// Removes a previously registered [listener].
  void removeListener(void Function(T state) listener) {
    _listeners.remove(listener);
  }

  /// Forces an immediate notification to all listeners, cancelling any
  /// pending debounced notification.
  void flush() {
    _assertNotDisposed();
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _notifyListeners();
  }

  /// Releases all resources held by this notifier.
  void dispose() {
    _assertNotDisposed();
    _disposed = true;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _listeners.clear();
    _streamController?.close();
    _streamController = null;
    _stream = null;
  }

  void _scheduleNotification() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(duration, () {
      if (!_disposed) {
        _notifyListeners();
      }
    });
  }

  void _notifyListeners() {
    for (final listener in List.of(_listeners)) {
      listener(_state);
    }
    _streamController?.add(_state);
  }

  void _assertNotDisposed() {
    if (_disposed) {
      throw StateError(
        'Cannot use a VeloxDebouncedNotifier after it has been disposed.',
      );
    }
  }
}

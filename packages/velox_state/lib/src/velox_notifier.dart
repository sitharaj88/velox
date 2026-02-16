import 'dart:async';

/// A reactive state holder that notifies listeners when the state changes.
///
/// [VeloxNotifier] holds a single value of type [T] and provides multiple
/// ways to observe state changes: callbacks, streams, and functional updates.
///
/// ```dart
/// final counter = VeloxNotifier<int>(0);
///
/// counter.addListener(print); // prints new state on each change
/// counter.setState(1);       // notifies listeners with 1
/// counter.update((s) => s + 1); // notifies listeners with 2
///
/// counter.dispose(); // cleans up resources
/// ```
class VeloxNotifier<T> {
  /// Creates a [VeloxNotifier] with the given [initialState].
  VeloxNotifier(T initialState) : _state = initialState;

  T _state;
  final List<void Function(T)> _listeners = [];
  StreamController<T>? _streamController;
  Stream<T>? _stream;
  bool _disposed = false;

  /// The current state value.
  T get state => _state;

  /// Whether this notifier has been disposed.
  bool get isDisposed => _disposed;

  /// A broadcast [Stream] that emits state changes.
  ///
  /// The stream does not emit the current state on subscription; it only
  /// emits future state changes. Use [state] to read the current value.
  Stream<T> get stream {
    _assertNotDisposed();
    if (_streamController == null) {
      _streamController = StreamController<T>.broadcast();
      _stream = _streamController!.stream;
    }
    return _stream!;
  }

  /// Replaces the current state with [newState] and notifies listeners.
  ///
  /// If [newState] is equal to the current state, listeners are still
  /// notified. Use [update] with an equality check if you want to skip
  /// duplicate values.
  void setState(T newState) {
    _assertNotDisposed();
    _state = newState;
    _notifyListeners();
  }

  /// Updates the state using a function that receives the current state.
  ///
  /// This is useful for deriving the next state from the current one:
  ///
  /// ```dart
  /// counter.update((current) => current + 1);
  /// ```
  void update(T Function(T current) updater) {
    _assertNotDisposed();
    _state = updater(_state);
    _notifyListeners();
  }

  /// Registers a [listener] that is called whenever the state changes.
  ///
  /// Returns a callback that removes the listener when called, which is
  /// convenient for inline cleanup:
  ///
  /// ```dart
  /// final remove = notifier.addListener((state) => print(state));
  /// // later...
  /// remove();
  /// ```
  VoidCallback addListener(void Function(T state) listener) {
    _assertNotDisposed();
    _listeners.add(listener);
    return () => removeListener(listener);
  }

  /// Removes a previously registered [listener].
  ///
  /// If the [listener] was not registered, this is a no-op.
  void removeListener(void Function(T state) listener) {
    _listeners.remove(listener);
  }

  /// Releases all resources held by this notifier.
  ///
  /// After calling [dispose], the notifier must not be used. Any calls to
  /// [setState], [update], [addListener], or [stream] will throw a
  /// [StateError].
  void dispose() {
    _assertNotDisposed();
    _disposed = true;
    _listeners.clear();
    _streamController?.close();
    _streamController = null;
    _stream = null;
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
        'Cannot use a VeloxNotifier after it has been disposed.',
      );
    }
  }
}

/// A callback with no arguments and no return value.
///
/// This is used as the return type of [VeloxNotifier.addListener] so that
/// callers can remove listeners without keeping a reference to the original
/// function.
typedef VoidCallback = void Function();

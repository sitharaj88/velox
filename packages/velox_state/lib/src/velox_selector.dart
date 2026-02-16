import 'dart:async';

import 'package:velox_state/src/velox_notifier.dart';

/// Selects and caches a derived value from a [VeloxNotifier].
///
/// [VeloxSelector] observes a source [VeloxNotifier] and applies a
/// [selector] function to derive a value of type [R]. It only notifies
/// its own listeners when the derived value actually changes, avoiding
/// unnecessary rebuilds downstream.
///
/// ```dart
/// final userNotifier = VeloxNotifier<User>(user);
/// final nameSelector = VeloxSelector<User, String>(
///   source: userNotifier,
///   selector: (user) => user.name,
/// );
///
/// nameSelector.addListener((name) => print('Name changed: $name'));
/// ```
class VeloxSelector<T, R> {
  /// Creates a [VeloxSelector] that derives a value from the given [source].
  ///
  /// - [source] is the upstream [VeloxNotifier] to observe.
  /// - [selector] extracts the derived value from the source state.
  /// - [equals] is an optional equality function used to determine whether
  ///   the derived value has changed. Defaults to `==`.
  VeloxSelector({
    required this.source,
    required R Function(T state) selector,
    bool Function(R previous, R next)? equals,
  })  : _selector = selector,
        _equals = equals ?? _defaultEquals,
        _value = selector(source.state) {
    _removeSourceListener = source.addListener(_onSourceChanged);
  }

  /// The upstream notifier being observed.
  final VeloxNotifier<T> source;

  final R Function(T state) _selector;
  final bool Function(R previous, R next) _equals;
  final List<void Function(R)> _listeners = [];
  StreamController<R>? _streamController;
  Stream<R>? _stream;
  VoidCallback? _removeSourceListener;
  R _value;
  bool _disposed = false;

  /// The current derived value.
  R get value => _value;

  /// Whether this selector has been disposed.
  bool get isDisposed => _disposed;

  /// A broadcast [Stream] that emits the derived value when it changes.
  Stream<R> get stream {
    _assertNotDisposed();
    if (_streamController == null) {
      _streamController = StreamController<R>.broadcast();
      _stream = _streamController!.stream;
    }
    return _stream!;
  }

  /// Registers a [listener] that is called when the derived value changes.
  ///
  /// Returns a callback that removes the listener when called.
  VoidCallback addListener(void Function(R value) listener) {
    _assertNotDisposed();
    _listeners.add(listener);
    return () => removeListener(listener);
  }

  /// Removes a previously registered [listener].
  void removeListener(void Function(R value) listener) {
    _listeners.remove(listener);
  }

  /// Releases all resources held by this selector.
  ///
  /// After calling [dispose], the selector must not be used.
  void dispose() {
    _assertNotDisposed();
    _disposed = true;
    _removeSourceListener?.call();
    _removeSourceListener = null;
    _listeners.clear();
    _streamController?.close();
    _streamController = null;
    _stream = null;
  }

  void _onSourceChanged(T sourceState) {
    final newValue = _selector(sourceState);
    if (!_equals(_value, newValue)) {
      _value = newValue;
      _notifyListeners();
    }
  }

  void _notifyListeners() {
    for (final listener in List.of(_listeners)) {
      listener(_value);
    }
    _streamController?.add(_value);
  }

  void _assertNotDisposed() {
    if (_disposed) {
      throw StateError(
        'Cannot use a VeloxSelector after it has been disposed.',
      );
    }
  }
}

bool _defaultEquals<R>(R a, R b) => a == b;

import 'dart:async';

import 'package:velox_state/src/velox_notifier.dart';

/// A read-only value that is automatically derived from one or more
/// [VeloxNotifier] sources.
///
/// Whenever any dependency changes, the [compute] function is re-evaluated and
/// listeners are notified only when the computed result differs from the
/// previous one.
///
/// ```dart
/// final firstName = VeloxNotifier<String>('John');
/// final lastName  = VeloxNotifier<String>('Doe');
///
/// final fullName = VeloxComputed<String>(
///   dependencies: [firstName, lastName],
///   compute: () => '${firstName.state} ${lastName.state}',
/// );
///
/// fullName.addListener((name) => print(name)); // prints when either changes
/// ```
class VeloxComputed<T> {
  /// Creates a [VeloxComputed] that derives its value from the given
  /// [dependencies] using the [compute] function.
  ///
  /// An optional [equals] function can be supplied to customise the equality
  /// check used to determine whether listeners should be notified.
  VeloxComputed({
    required List<VeloxNotifier<dynamic>> dependencies,
    required T Function() compute,
    bool Function(T previous, T next)? equals,
  })  : _dependencies = dependencies,
        _compute = compute,
        _equals = equals ?? _defaultEquals,
        _value = compute() {
    for (final dep in _dependencies) {
      _removers.add(dep.addListener((_) => _recompute()));
    }
  }

  final List<VeloxNotifier<dynamic>> _dependencies;
  final T Function() _compute;
  final bool Function(T previous, T next) _equals;
  final List<VoidCallback> _removers = [];
  final List<void Function(T)> _listeners = [];
  StreamController<T>? _streamController;
  Stream<T>? _stream;
  T _value;
  bool _disposed = false;

  /// The current computed value.
  T get value => _value;

  /// Whether this computed has been disposed.
  bool get isDisposed => _disposed;

  /// A broadcast [Stream] that emits values whenever the computed result
  /// changes.
  Stream<T> get stream {
    _assertNotDisposed();
    if (_streamController == null) {
      _streamController = StreamController<T>.broadcast();
      _stream = _streamController!.stream;
    }
    return _stream!;
  }

  /// Registers a [listener] that is called when the computed value changes.
  ///
  /// Returns a callback that removes the listener when called.
  VoidCallback addListener(void Function(T value) listener) {
    _assertNotDisposed();
    _listeners.add(listener);
    return () => removeListener(listener);
  }

  /// Removes a previously registered [listener].
  void removeListener(void Function(T value) listener) {
    _listeners.remove(listener);
  }

  /// Releases all resources held by this computed value.
  void dispose() {
    _assertNotDisposed();
    _disposed = true;
    for (final remove in _removers) {
      remove();
    }
    _removers.clear();
    _listeners.clear();
    _streamController?.close();
    _streamController = null;
    _stream = null;
  }

  void _recompute() {
    final newValue = _compute();
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
        'Cannot use a VeloxComputed after it has been disposed.',
      );
    }
  }
}

bool _defaultEquals<T>(T a, T b) => a == b;

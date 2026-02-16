import 'package:velox_state/src/velox_notifier.dart';

/// Creates and caches [VeloxNotifier] instances by key.
///
/// [VeloxNotifierFamily] is similar to Riverpod's family pattern: it lazily
/// creates a notifier for each unique key and caches it for subsequent lookups.
///
/// ```dart
/// final counterFamily = VeloxNotifierFamily<String, int>(
///   create: (key) => 0,
/// );
///
/// final homeCounter = counterFamily('home');   // creates notifier with 0
/// final workCounter = counterFamily('work');   // creates another notifier
/// final sameHome    = counterFamily('home');   // returns cached instance
///
/// assert(identical(homeCounter, sameHome));
/// ```
class VeloxNotifierFamily<K, T> {
  /// Creates a [VeloxNotifierFamily] with the given [create] factory.
  ///
  /// The [create] function is called once per unique key to produce the
  /// initial state of the notifier.
  VeloxNotifierFamily({required T Function(K key) create}) : _create = create;

  final T Function(K key) _create;
  final Map<K, VeloxNotifier<T>> _cache = {};

  /// Returns the [VeloxNotifier] for the given [key], creating one if it does
  /// not already exist.
  VeloxNotifier<T> call(K key) =>
      _cache.putIfAbsent(key, () => VeloxNotifier<T>(_create(key)));

  /// Returns the [VeloxNotifier] for the given [key], or `null` if it has not
  /// been created yet.
  VeloxNotifier<T>? get(K key) => _cache[key];

  /// Whether a notifier for the given [key] has been created.
  bool containsKey(K key) => _cache.containsKey(key);

  /// Returns all currently cached keys.
  Iterable<K> get keys => _cache.keys;

  /// Returns all currently cached notifiers.
  Iterable<VeloxNotifier<T>> get values => _cache.values;

  /// The number of cached notifiers.
  int get length => _cache.length;

  /// Removes and disposes the notifier for the given [key].
  ///
  /// Returns `true` if a notifier was removed, `false` if the key was not
  /// found.
  bool remove(K key) {
    final notifier = _cache.remove(key);
    if (notifier != null) {
      notifier.dispose();
      return true;
    }
    return false;
  }

  /// Disposes all cached notifiers and clears the cache.
  void disposeAll() {
    for (final notifier in _cache.values) {
      if (!notifier.isDisposed) {
        notifier.dispose();
      }
    }
    _cache.clear();
  }
}

import 'package:velox_state/src/velox_notifier.dart';

/// A strategy for persisting and restoring state.
///
/// Implement this to provide custom serialization/deserialization for
/// [VeloxPersistedNotifier].
///
/// ```dart
/// class JsonStorage<T> implements VeloxPersistenceStrategy<T> {
///   final String key;
///   final Map<String, dynamic> Function(T) toJson;
///   final T Function(Map<String, dynamic>) fromJson;
///   final SharedPreferences prefs;
///
///   JsonStorage({
///     required this.key,
///     required this.toJson,
///     required this.fromJson,
///     required this.prefs,
///   });
///
///   @override
///   Future<T?> load() async {
///     final raw = prefs.getString(key);
///     if (raw == null) return null;
///     return fromJson(jsonDecode(raw));
///   }
///
///   @override
///   Future<void> save(T state) async {
///     await prefs.setString(key, jsonEncode(toJson(state)));
///   }
///
///   @override
///   Future<void> clear() async {
///     await prefs.remove(key);
///   }
/// }
/// ```
abstract class VeloxPersistenceStrategy<T> {
  /// Creates a [VeloxPersistenceStrategy].
  const VeloxPersistenceStrategy();

  /// Loads the persisted state, or returns `null` if nothing was persisted.
  Future<T?> load();

  /// Persists the given [state].
  Future<void> save(T state);

  /// Clears the persisted state.
  Future<void> clear();
}

/// A simple in-memory implementation of [VeloxPersistenceStrategy] useful for
/// testing.
class InMemoryPersistenceStrategy<T> implements VeloxPersistenceStrategy<T> {
  T? _stored;

  /// Whether any value has been stored.
  bool get hasStored => _stored != null;

  /// The currently stored value, or `null`.
  T? get stored => _stored;

  @override
  Future<T?> load() async => _stored;

  @override
  Future<void> save(T state) async {
    _stored = state;
  }

  @override
  Future<void> clear() async {
    _stored = null;
  }
}

/// A [VeloxNotifier] that automatically persists state changes using a
/// [VeloxPersistenceStrategy].
///
/// Call [hydrate] after construction to restore any previously persisted state.
///
/// ```dart
/// final notifier = VeloxPersistedNotifier<int>(
///   0,
///   strategy: myStrategy,
/// );
/// await notifier.hydrate(); // restores persisted state if available
///
/// notifier.setState(42); // automatically persisted
/// ```
class VeloxPersistedNotifier<T> extends VeloxNotifier<T> {
  /// Creates a [VeloxPersistedNotifier] with the given [initialState] and
  /// persistence [strategy].
  VeloxPersistedNotifier(
    super.initialState, {
    required VeloxPersistenceStrategy<T> strategy,
  }) : _strategy = strategy;

  final VeloxPersistenceStrategy<T> _strategy;

  /// Whether [hydrate] has been called and completed successfully.
  bool _hydrated = false;

  /// Whether the state has been hydrated from persistence.
  bool get isHydrated => _hydrated;

  /// Restores previously persisted state.
  ///
  /// If the strategy returns a non-null value, it replaces the current state
  /// and notifies listeners.
  Future<void> hydrate() async {
    final persisted = await _strategy.load();
    if (persisted != null) {
      super.setState(persisted);
    }
    _hydrated = true;
  }

  @override
  void setState(T newState) {
    super.setState(newState);
    _strategy.save(newState);
  }

  @override
  void update(T Function(T current) updater) {
    super.update(updater);
    _strategy.save(state);
  }

  /// Clears the persisted state without affecting the in-memory state.
  Future<void> clearPersisted() async {
    await _strategy.clear();
  }
}

import 'package:velox_di/src/velox_container.dart';

/// A child container that delegates unresolved lookups to a [parent].
///
/// [VeloxScope] lets you override specific registrations for a limited
/// lifetime (e.g. per-request, per-screen) while still falling back to the
/// parent container for everything else.
///
/// Child scopes can be nested, forming a hierarchy. When the scope is
/// disposed, only its own registrations are cleaned up -- the parent is
/// left intact.
///
/// ```dart
/// final root = VeloxContainer()
///   ..registerSingleton<Logger>(ConsoleLogger())
///   ..registerSingleton<Theme>(LightTheme());
///
/// final scope = root.createScope()
///   ..registerSingleton<Theme>(DarkTheme());
///
/// scope.get<Logger>(); // ConsoleLogger (from parent)
/// scope.get<Theme>();  // DarkTheme      (overridden in scope)
/// ```
class VeloxScope extends VeloxContainer {
  /// Creates a [VeloxScope] with the given [parent] container.
  VeloxScope({required this.parent});

  /// The parent container to fall back to when a type is not registered in
  /// this scope.
  final VeloxContainer parent;

  /// Child scopes created from this scope, tracked for disposal chain.
  final List<VeloxScope> _children = <VeloxScope>[];

  /// Resolves [T] from this scope first, falling back to [parent] if not
  /// found locally.
  ///
  /// If [name] is provided, resolves the named registration.
  @override
  T get<T extends Object>({String? name}) {
    if (has<T>(name: name)) {
      return super.get<T>(name: name);
    }
    return parent.get<T>(name: name);
  }

  /// Resolves [T] from this scope first, falling back to [parent] if not
  /// found locally. Returns `null` if neither has a registration.
  ///
  /// If [name] is provided, resolves the named registration.
  @override
  T? getOrNull<T extends Object>({String? name}) {
    if (has<T>(name: name)) {
      return super.getOrNull<T>(name: name);
    }
    return parent.getOrNull<T>(name: name);
  }

  /// Resolves an instance of [T] using a parameterised factory, falling
  /// back to the [parent] if not found locally.
  @override
  T getWithParam<T extends Object, P extends Object>(
    P param, {
    String? name,
  }) {
    if (has<T>(name: name)) {
      return super.getWithParam<T, P>(param, name: name);
    }
    return parent.getWithParam<T, P>(param, name: name);
  }

  /// Resolves an async instance of [T], falling back to the [parent] if
  /// not found locally.
  @override
  Future<T> getAsync<T extends Object>({String? name}) {
    if (has<T>(name: name)) {
      return super.getAsync<T>(name: name);
    }
    return parent.getAsync<T>(name: name);
  }

  /// Returns `true` if [T] is registered in this scope **or** in the
  /// [parent].
  ///
  /// If [name] is provided, checks for the named registration.
  bool hasInHierarchy<T extends Object>({String? name}) =>
      has<T>(name: name) || parent.has<T>(name: name);

  /// Creates a child [VeloxScope] nested under this scope.
  ///
  /// The child scope falls back to this scope (and transitively to this
  /// scope's parent) for unresolved types.
  @override
  VeloxScope createScope() {
    final child = VeloxScope(parent: this);
    _children.add(child);
    return child;
  }

  /// Disposes all child scopes first, then disposes this scope's own
  /// registrations.
  ///
  /// The [parent] container is **not** disposed.
  @override
  void dispose() {
    // Dispose children first (deepest first via recursion).
    for (final child in _children) {
      child.dispose();
    }
    _children.clear();
    super.dispose();
  }
}

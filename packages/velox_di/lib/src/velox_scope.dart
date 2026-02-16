import 'package:velox_di/src/velox_container.dart';

/// A child container that delegates unresolved lookups to a [parent].
///
/// [VeloxScope] lets you override specific registrations for a limited
/// lifetime (e.g. per-request, per-screen) while still falling back to the
/// parent container for everything else.
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

  /// Resolves [T] from this scope first, falling back to [parent] if not
  /// found locally.
  @override
  T get<T extends Object>() {
    if (has<T>()) {
      return super.get<T>();
    }
    return parent.get<T>();
  }

  /// Resolves [T] from this scope first, falling back to [parent] if not
  /// found locally. Returns `null` if neither has a registration.
  @override
  T? getOrNull<T extends Object>() {
    if (has<T>()) {
      return super.getOrNull<T>();
    }
    return parent.getOrNull<T>();
  }

  /// Returns `true` if [T] is registered in this scope **or** in the
  /// [parent].
  bool hasInHierarchy<T extends Object>() => has<T>() || parent.has<T>();

  /// Disposes only the registrations in this scope.
  ///
  /// The [parent] container is **not** disposed.
  @override
  void dispose() {
    super.dispose();
  }
}

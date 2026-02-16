import 'package:meta/meta.dart';
import 'package:velox_core/velox_core.dart';

import 'package:velox_di/src/velox_scope.dart';

/// The type of registration stored in the container.
enum _RegistrationType {
  /// A pre-created singleton instance.
  singleton,

  /// A factory that creates the instance on first access, then caches it.
  lazy,

  /// A factory that creates a new instance on every access.
  factory,
}

/// Internal wrapper that holds registration metadata and the resolved value.
class _Registration<T> {
  _Registration({
    required this.type,
    this.instance,
    this.factory,
  });

  /// The type of this registration.
  final _RegistrationType type;

  /// The resolved instance (for singletons and lazy singletons after first
  /// access).
  T? instance;

  /// The factory function (for lazy singletons and factories).
  final T Function()? factory;
}

/// A compile-time safe dependency injection container.
///
/// [VeloxContainer] provides a lightweight service locator that supports
/// three registration strategies:
///
/// - **Singleton** -- a pre-created instance returned on every [get] call.
/// - **Lazy singleton** -- created on first [get] call, then cached.
/// - **Factory** -- a new instance created on every [get] call.
///
/// ```dart
/// final container = VeloxContainer();
///
/// container.registerSingleton<Logger>(ConsoleLogger());
/// container.registerLazy<Database>(() => SqliteDatabase());
/// container.registerFactory<HttpClient>(() => HttpClient());
///
/// final logger = container.get<Logger>();
/// ```
class VeloxContainer {
  /// Creates a new [VeloxContainer].
  VeloxContainer();

  final Map<Type, _Registration<Object>> _registrations =
      <Type, _Registration<Object>>{};

  /// Registers a pre-created singleton [instance].
  ///
  /// The same [instance] is returned on every call to [get<T>].
  ///
  /// Throws a [VeloxException] if a registration for [T] already exists.
  ///
  /// ```dart
  /// container.registerSingleton<Logger>(ConsoleLogger());
  /// ```
  void registerSingleton<T extends Object>(T instance) {
    _ensureNotRegistered<T>();
    _registrations[T] = _Registration<T>(
      type: _RegistrationType.singleton,
      instance: instance,
    );
  }

  /// Registers a lazy singleton using the given [factory].
  ///
  /// The [factory] is called once on the first [get<T>] call. The resulting
  /// instance is cached and returned on subsequent calls.
  ///
  /// Throws a [VeloxException] if a registration for [T] already exists.
  ///
  /// ```dart
  /// container.registerLazy<Database>(() => SqliteDatabase());
  /// ```
  void registerLazy<T extends Object>(T Function() factory) {
    _ensureNotRegistered<T>();
    _registrations[T] = _Registration<T>(
      type: _RegistrationType.lazy,
      factory: factory,
    );
  }

  /// Registers a factory that creates a new instance on every [get<T>] call.
  ///
  /// Throws a [VeloxException] if a registration for [T] already exists.
  ///
  /// ```dart
  /// container.registerFactory<HttpClient>(() => HttpClient());
  /// ```
  void registerFactory<T extends Object>(T Function() factory) {
    _ensureNotRegistered<T>();
    _registrations[T] = _Registration<T>(
      type: _RegistrationType.factory,
      factory: factory,
    );
  }

  /// Resolves and returns an instance of [T].
  ///
  /// - For **singletons**, returns the registered instance.
  /// - For **lazy singletons**, creates the instance on first call, then
  ///   returns the cached value.
  /// - For **factories**, creates a new instance on every call.
  ///
  /// Throws a [VeloxException] if [T] has not been registered.
  ///
  /// ```dart
  /// final logger = container.get<Logger>();
  /// ```
  T get<T extends Object>() {
    final registration = _registrations[T];
    if (registration == null) {
      throw VeloxException(
        message: 'No registration found for type $T',
        code: 'DI_NOT_FOUND',
      );
    }
    return _resolve<T>(registration);
  }

  /// Resolves an instance of [T], or returns `null` if not registered.
  ///
  /// This is a safe alternative to [get] that avoids exceptions.
  ///
  /// ```dart
  /// final logger = container.getOrNull<Logger>();
  /// if (logger != null) {
  ///   logger.log('Hello');
  /// }
  /// ```
  T? getOrNull<T extends Object>() {
    final registration = _registrations[T];
    if (registration == null) {
      return null;
    }
    return _resolve<T>(registration);
  }

  /// Returns `true` if a registration for [T] exists in this container.
  ///
  /// ```dart
  /// if (container.has<Logger>()) {
  ///   container.get<Logger>().log('ready');
  /// }
  /// ```
  bool has<T extends Object>() => _registrations.containsKey(T);

  /// Removes the registration for [T].
  ///
  /// Does nothing if [T] is not registered.
  ///
  /// ```dart
  /// container.unregister<Logger>();
  /// ```
  void unregister<T extends Object>() {
    _registrations.remove(T);
  }

  /// Removes all registrations from this container.
  ///
  /// ```dart
  /// container.reset();
  /// ```
  void reset() {
    _registrations.clear();
  }

  /// Disposes all resolved singleton and lazy singleton instances that
  /// implement [Disposable] or have a `dispose()` method.
  ///
  /// Factory registrations are skipped because the container does not hold
  /// references to their instances.
  ///
  /// After calling this method all registrations are removed.
  void dispose() {
    for (final registration in _registrations.values) {
      if (registration.type == _RegistrationType.factory) {
        continue;
      }
      final instance = registration.instance;
      if (instance is Disposable) {
        instance.dispose();
      }
    }
    _registrations.clear();
  }

  /// Creates a child [VeloxScope] that falls back to this container for
  /// unresolved dependencies.
  ///
  /// ```dart
  /// final scope = container.createScope();
  /// scope.registerSingleton<Theme>(DarkTheme());
  /// // Falls back to parent for Logger, Database, etc.
  /// ```
  VeloxScope createScope() => VeloxScope(parent: this);

  /// Returns all registered types. Intended for testing and debugging.
  @visibleForTesting
  Iterable<Type> get registeredTypes => _registrations.keys;

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  T _resolve<T extends Object>(_Registration<Object> registration) {
    switch (registration.type) {
      case _RegistrationType.singleton:
        return registration.instance! as T;
      case _RegistrationType.lazy:
        if (registration.instance != null) {
          return registration.instance! as T;
        }
        final instance = registration.factory!() as T;
        registration.instance = instance;
        return instance;
      case _RegistrationType.factory:
        return registration.factory!() as T;
    }
  }

  void _ensureNotRegistered<T extends Object>() {
    if (_registrations.containsKey(T)) {
      throw VeloxException(
        message: 'Type $T is already registered',
        code: 'DI_ALREADY_REGISTERED',
      );
    }
  }
}

/// An interface for objects that can release resources.
///
/// Singleton instances that implement this interface will have their
/// [dispose] method called when [VeloxContainer.dispose] is invoked.
abstract class Disposable {
  /// Releases resources held by this object.
  void dispose();
}

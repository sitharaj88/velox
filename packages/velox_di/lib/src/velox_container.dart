import 'dart:async';

import 'package:meta/meta.dart';
import 'package:velox_core/velox_core.dart';

import 'package:velox_di/src/container_event.dart';
import 'package:velox_di/src/velox_scope.dart';

/// The type of registration stored in the container.
enum RegistrationType {
  /// A pre-created singleton instance.
  singleton,

  /// A factory that creates the instance on first access, then caches it.
  lazy,

  /// A factory that creates a new instance on every access.
  factory,

  /// A factory that creates a new instance on every access, accepting a
  /// parameter.
  factoryParam,

  /// An async factory that creates the instance on first access.
  asyncFactory,
}

/// A key that uniquely identifies a registration by its type and optional name.
@immutable
class _RegistrationKey {
  const _RegistrationKey(this.type, this.name);

  final Type type;
  final String? name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _RegistrationKey && type == other.type && name == other.name;

  @override
  int get hashCode => Object.hash(type, name);

  @override
  String toString() {
    if (name != null) return '$type($name)';
    return '$type';
  }
}

/// Internal wrapper that holds registration metadata and the resolved value.
class Registration<T> {
  /// Creates a [Registration].
  Registration({
    required this.type,
    this.disposable = false,
    this.instance,
    this.factory,
    this.factoryParam,
    this.asyncFactory,
  });

  /// The type of this registration.
  final RegistrationType type;

  /// Whether the container should auto-dispose this instance on teardown.
  final bool disposable;

  /// The resolved instance (for singletons and lazy singletons after first
  /// access).
  T? instance;

  /// The factory function (for lazy singletons and factories).
  final T Function()? factory;

  /// A factory that takes a parameter.
  final T Function(Object)? factoryParam;

  /// An async factory for services that require async initialization.
  final Future<T> Function()? asyncFactory;
}

/// A compile-time safe dependency injection container.
///
/// [VeloxContainer] provides a lightweight service locator that supports
/// multiple registration strategies:
///
/// - **Singleton** -- a pre-created instance returned on every [get] call.
/// - **Lazy singleton** -- created on first [get] call, then cached.
/// - **Eager singleton** -- created immediately at registration time via a
///   factory.
/// - **Factory** -- a new instance created on every [get] call.
/// - **Factory with parameter** -- a new instance created with a parameter on
///   every [getWithParam] call.
/// - **Async factory** -- a lazy singleton that requires async initialization,
///   resolved via [getAsync].
/// - **Named registrations** -- multiple implementations of the same type
///   registered with different names.
///
/// The container also provides:
/// - **Circular dependency detection** during resolution
/// - **Auto-dispose** of disposable instances on teardown
/// - **Container events** for debugging and logging
/// - **Service overrides** for testing
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

  final Map<_RegistrationKey, Registration<Object>> _registrations =
      <_RegistrationKey, Registration<Object>>{};

  final StreamController<ContainerEvent> _eventController =
      StreamController<ContainerEvent>.broadcast();

  /// The set of types currently being resolved, used to detect circular
  /// dependencies.
  final Set<_RegistrationKey> _resolving = <_RegistrationKey>{};

  /// A stream of [ContainerEvent]s emitted during registration, resolution,
  /// and disposal.
  ///
  /// Subscribe to this stream to observe the container lifecycle for
  /// debugging, logging, or metrics.
  ///
  /// ```dart
  /// container.events.listen((event) {
  ///   switch (event) {
  ///     case RegistrationEvent():
  ///       print('Registered: ${event.type}');
  ///     case ResolutionEvent():
  ///       print('Resolved: ${event.type}');
  ///     case DisposalEvent():
  ///       print('Disposed: ${event.type}');
  ///   }
  /// });
  /// ```
  Stream<ContainerEvent> get events => _eventController.stream;

  // ---------------------------------------------------------------------------
  // Registration methods
  // ---------------------------------------------------------------------------

  /// Registers a pre-created singleton [instance].
  ///
  /// The same [instance] is returned on every call to [get<T>].
  ///
  /// If [name] is provided, the registration is stored under that name,
  /// allowing multiple implementations of the same type.
  ///
  /// If [disposable] is `true`, the container will call `dispose()` on the
  /// instance if it implements [Disposable] when the container is disposed.
  ///
  /// Throws a [VeloxException] if a registration for [T] (with the same
  /// [name]) already exists.
  ///
  /// ```dart
  /// container.registerSingleton<Logger>(ConsoleLogger());
  /// container.registerSingleton<Logger>(FileLogger(), name: 'file');
  /// ```
  void registerSingleton<T extends Object>(
    T instance, {
    String? name,
    bool disposable = false,
  }) {
    final key = _RegistrationKey(T, name);
    _ensureNotRegistered(key);
    _registrations[key] = Registration<T>(
      type: RegistrationType.singleton,
      instance: instance,
      disposable: disposable,
    );
    _emitEvent(RegistrationEvent(type: T, name: name));
  }

  /// Registers a lazy singleton using the given [factory].
  ///
  /// The [factory] is called once on the first [get<T>] call. The resulting
  /// instance is cached and returned on subsequent calls.
  ///
  /// If [name] is provided, the registration is stored under that name.
  ///
  /// If [disposable] is `true`, the container will call `dispose()` on the
  /// resolved instance when the container is disposed.
  ///
  /// Throws a [VeloxException] if a registration for [T] (with the same
  /// [name]) already exists.
  ///
  /// ```dart
  /// container.registerLazy<Database>(() => SqliteDatabase());
  /// ```
  void registerLazy<T extends Object>(
    T Function() factory, {
    String? name,
    bool disposable = false,
  }) {
    final key = _RegistrationKey(T, name);
    _ensureNotRegistered(key);
    _registrations[key] = Registration<T>(
      type: RegistrationType.lazy,
      factory: factory,
      disposable: disposable,
    );
    _emitEvent(RegistrationEvent(type: T, name: name));
  }

  /// Registers an eager singleton using the given [factory].
  ///
  /// Unlike [registerLazy], the [factory] is called **immediately** and
  /// the resulting instance is cached for all subsequent [get<T>] calls.
  ///
  /// This is useful for services that must be initialized at startup time.
  ///
  /// If [name] is provided, the registration is stored under that name.
  ///
  /// If [disposable] is `true`, the container will call `dispose()` on the
  /// instance when the container is disposed.
  ///
  /// Throws a [VeloxException] if a registration for [T] (with the same
  /// [name]) already exists.
  ///
  /// ```dart
  /// container.registerEager<Analytics>(() => Analytics.init());
  /// ```
  void registerEager<T extends Object>(
    T Function() factory, {
    String? name,
    bool disposable = false,
  }) {
    final key = _RegistrationKey(T, name);
    _ensureNotRegistered(key);
    final instance = factory();
    _registrations[key] = Registration<T>(
      type: RegistrationType.singleton,
      instance: instance,
      disposable: disposable,
    );
    _emitEvent(RegistrationEvent(type: T, name: name));
  }

  /// Registers a factory that creates a new instance on every [get<T>] call.
  ///
  /// If [name] is provided, the registration is stored under that name.
  ///
  /// Throws a [VeloxException] if a registration for [T] (with the same
  /// [name]) already exists.
  ///
  /// ```dart
  /// container.registerFactory<HttpClient>(() => HttpClient());
  /// ```
  void registerFactory<T extends Object>(
    T Function() factory, {
    String? name,
  }) {
    final key = _RegistrationKey(T, name);
    _ensureNotRegistered(key);
    _registrations[key] = Registration<T>(
      type: RegistrationType.factory,
      factory: factory,
    );
    _emitEvent(RegistrationEvent(type: T, name: name));
  }

  /// Registers a factory that takes a parameter of type [P] and creates a
  /// new instance of [T] on every [getWithParam] call.
  ///
  /// If [name] is provided, the registration is stored under that name.
  ///
  /// Throws a [VeloxException] if a registration for [T] (with the same
  /// [name]) already exists.
  ///
  /// ```dart
  /// container.registerFactoryParam<UserRepo, String>(
  ///   (token) => UserRepo(token: token),
  /// );
  /// final repo = container.getWithParam<UserRepo, String>('abc123');
  /// ```
  void registerFactoryParam<T extends Object, P extends Object>(
    T Function(P param) factory, {
    String? name,
  }) {
    final key = _RegistrationKey(T, name);
    _ensureNotRegistered(key);
    _registrations[key] = Registration<T>(
      type: RegistrationType.factoryParam,
      factoryParam: (p) => factory(p as P),
    );
    _emitEvent(RegistrationEvent(type: T, name: name));
  }

  /// Registers an async factory for services that need asynchronous
  /// initialization.
  ///
  /// The [factory] is called once on the first [getAsync<T>] call. The
  /// resulting instance is cached and returned on subsequent calls.
  ///
  /// If [name] is provided, the registration is stored under that name.
  ///
  /// If [disposable] is `true`, the container will call `dispose()` on the
  /// resolved instance when the container is disposed.
  ///
  /// Throws a [VeloxException] if a registration for [T] (with the same
  /// [name]) already exists.
  ///
  /// ```dart
  /// container.registerAsync<Database>(
  ///   () async {
  ///     final db = Database();
  ///     await db.initialize();
  ///     return db;
  ///   },
  /// );
  /// final db = await container.getAsync<Database>();
  /// ```
  void registerAsync<T extends Object>(
    Future<T> Function() factory, {
    String? name,
    bool disposable = false,
  }) {
    final key = _RegistrationKey(T, name);
    _ensureNotRegistered(key);
    _registrations[key] = Registration<T>(
      type: RegistrationType.asyncFactory,
      asyncFactory: factory,
      disposable: disposable,
    );
    _emitEvent(RegistrationEvent(type: T, name: name));
  }

  // ---------------------------------------------------------------------------
  // Override methods
  // ---------------------------------------------------------------------------

  /// Overrides an existing registration for [T] with a new [instance].
  ///
  /// This is intended primarily for testing, allowing you to swap
  /// implementations at runtime. If no prior registration exists, the
  /// [instance] is simply registered.
  ///
  /// ```dart
  /// container.registerSingleton<Logger>(ConsoleLogger());
  /// container.override<Logger>(MockLogger()); // replaces for testing
  /// ```
  void override<T extends Object>(
    T instance, {
    String? name,
    bool disposable = false,
  }) {
    final key = _RegistrationKey(T, name);
    _registrations[key] = Registration<T>(
      type: RegistrationType.singleton,
      instance: instance,
      disposable: disposable,
    );
    _emitEvent(OverrideEvent(type: T, name: name));
  }

  /// Overrides an existing factory registration for [T] with a new [factory].
  ///
  /// Useful for testing when you need to swap factory behaviour.
  void overrideFactory<T extends Object>(
    T Function() factory, {
    String? name,
  }) {
    final key = _RegistrationKey(T, name);
    _registrations[key] = Registration<T>(
      type: RegistrationType.factory,
      factory: factory,
    );
    _emitEvent(OverrideEvent(type: T, name: name));
  }

  /// Overrides an existing lazy registration for [T] with a new [factory].
  ///
  /// Useful for testing when you need to swap lazy singleton behaviour.
  void overrideLazy<T extends Object>(
    T Function() factory, {
    String? name,
    bool disposable = false,
  }) {
    final key = _RegistrationKey(T, name);
    _registrations[key] = Registration<T>(
      type: RegistrationType.lazy,
      factory: factory,
      disposable: disposable,
    );
    _emitEvent(OverrideEvent(type: T, name: name));
  }

  // ---------------------------------------------------------------------------
  // Resolution methods
  // ---------------------------------------------------------------------------

  /// Resolves and returns an instance of [T].
  ///
  /// - For **singletons**, returns the registered instance.
  /// - For **lazy singletons**, creates the instance on first call, then
  ///   returns the cached value.
  /// - For **factories**, creates a new instance on every call.
  ///
  /// If [name] is provided, resolves the named registration.
  ///
  /// Throws a [VeloxException] if [T] has not been registered.
  /// Throws a [VeloxException] with code `DI_CIRCULAR_DEPENDENCY` if a
  /// circular dependency is detected during resolution.
  ///
  /// ```dart
  /// final logger = container.get<Logger>();
  /// final fileLogger = container.get<Logger>(name: 'file');
  /// ```
  T get<T extends Object>({String? name}) {
    final key = _RegistrationKey(T, name);
    final registration = _registrations[key];
    if (registration == null) {
      throw VeloxException(
        message: 'No registration found for type $T'
            '${name != null ? ' with name "$name"' : ''}',
        code: 'DI_NOT_FOUND',
      );
    }
    return _resolve<T>(key, registration);
  }

  /// Resolves an instance of [T], or returns `null` if not registered.
  ///
  /// This is a safe alternative to [get] that avoids exceptions.
  ///
  /// If [name] is provided, resolves the named registration.
  ///
  /// ```dart
  /// final logger = container.getOrNull<Logger>();
  /// if (logger != null) {
  ///   logger.log('Hello');
  /// }
  /// ```
  T? getOrNull<T extends Object>({String? name}) {
    final key = _RegistrationKey(T, name);
    final registration = _registrations[key];
    if (registration == null) {
      return null;
    }
    return _resolve<T>(key, registration);
  }

  /// Resolves an instance of [T] using a parameterised factory.
  ///
  /// Throws a [VeloxException] if [T] has not been registered or was not
  /// registered with [registerFactoryParam].
  ///
  /// ```dart
  /// final repo = container.getWithParam<UserRepo, String>('token123');
  /// ```
  T getWithParam<T extends Object, P extends Object>(
    P param, {
    String? name,
  }) {
    final key = _RegistrationKey(T, name);
    final registration = _registrations[key];
    if (registration == null) {
      throw VeloxException(
        message: 'No registration found for type $T'
            '${name != null ? ' with name "$name"' : ''}',
        code: 'DI_NOT_FOUND',
      );
    }
    if (registration.type != RegistrationType.factoryParam) {
      throw VeloxException(
        message: 'Type $T was not registered with registerFactoryParam',
        code: 'DI_NOT_FACTORY_PARAM',
      );
    }
    _emitEvent(ResolutionEvent(type: T, name: name));
    return registration.factoryParam!(param) as T;
  }

  /// Resolves an instance of [T] that was registered with [registerAsync].
  ///
  /// On first call, the async factory is invoked and the result is cached.
  /// Subsequent calls return the cached instance.
  ///
  /// Throws a [VeloxException] if [T] has not been registered or was not
  /// registered with [registerAsync].
  ///
  /// ```dart
  /// final db = await container.getAsync<Database>();
  /// ```
  Future<T> getAsync<T extends Object>({String? name}) async {
    final key = _RegistrationKey(T, name);
    final registration = _registrations[key];
    if (registration == null) {
      throw VeloxException(
        message: 'No registration found for type $T'
            '${name != null ? ' with name "$name"' : ''}',
        code: 'DI_NOT_FOUND',
      );
    }
    if (registration.type != RegistrationType.asyncFactory) {
      throw VeloxException(
        message: 'Type $T was not registered with registerAsync',
        code: 'DI_NOT_ASYNC',
      );
    }
    if (registration.instance != null) {
      _emitEvent(ResolutionEvent(type: T, name: name));
      return registration.instance! as T;
    }
    final instance = await registration.asyncFactory!() as T;
    registration.instance = instance;
    _emitEvent(ResolutionEvent(type: T, name: name));
    return instance;
  }

  /// Returns `true` if a registration for [T] exists in this container.
  ///
  /// If [name] is provided, checks for the named registration.
  ///
  /// ```dart
  /// if (container.has<Logger>()) {
  ///   container.get<Logger>().log('ready');
  /// }
  /// ```
  bool has<T extends Object>({String? name}) =>
      _registrations.containsKey(_RegistrationKey(T, name));

  // ---------------------------------------------------------------------------
  // Unregister / Reset / Dispose
  // ---------------------------------------------------------------------------

  /// Removes the registration for [T].
  ///
  /// If [name] is provided, removes only the named registration.
  ///
  /// Does nothing if [T] is not registered.
  ///
  /// ```dart
  /// container.unregister<Logger>();
  /// ```
  void unregister<T extends Object>({String? name}) {
    final key = _RegistrationKey(T, name);
    if (_registrations.containsKey(key)) {
      _registrations.remove(key);
      _emitEvent(UnregistrationEvent(type: T, name: name));
    }
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
  /// implement [Disposable], plus any registration marked with
  /// `disposable: true`.
  ///
  /// Factory registrations are skipped because the container does not hold
  /// references to their instances.
  ///
  /// After calling this method all registrations are removed and the event
  /// stream is closed.
  void dispose() {
    for (final entry in _registrations.entries) {
      final registration = entry.value;
      if (registration.type == RegistrationType.factory ||
          registration.type == RegistrationType.factoryParam) {
        continue;
      }
      final instance = registration.instance;
      if (instance == null) continue;
      if (instance is Disposable || registration.disposable) {
        if (instance is Disposable) {
          instance.dispose();
        }
        _emitEvent(DisposalEvent(type: entry.key.type, name: entry.key.name));
      }
    }
    _registrations.clear();
    _eventController.close();
  }

  // ---------------------------------------------------------------------------
  // Scoped containers
  // ---------------------------------------------------------------------------

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
  Iterable<Type> get registeredTypes =>
      _registrations.keys.map((k) => k.type);

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  T _resolve<T extends Object>(
    _RegistrationKey key,
    Registration<Object> registration,
  ) {
    switch (registration.type) {
      case RegistrationType.singleton:
        _emitEvent(ResolutionEvent(type: T, name: key.name));
        return registration.instance! as T;
      case RegistrationType.lazy:
        if (registration.instance != null) {
          _emitEvent(ResolutionEvent(type: T, name: key.name));
          return registration.instance! as T;
        }
        // Circular dependency detection
        if (!_resolving.add(key)) {
          throw VeloxException(
            message: 'Circular dependency detected while resolving $key. '
                'Resolution chain: ${_resolving.join(' -> ')} -> $key',
            code: 'DI_CIRCULAR_DEPENDENCY',
          );
        }
        try {
          final instance = registration.factory!() as T;
          registration.instance = instance;
          _emitEvent(ResolutionEvent(type: T, name: key.name));
          return instance;
        } finally {
          _resolving.remove(key);
        }
      case RegistrationType.factory:
        // Circular dependency detection
        if (!_resolving.add(key)) {
          throw VeloxException(
            message: 'Circular dependency detected while resolving $key. '
                'Resolution chain: ${_resolving.join(' -> ')} -> $key',
            code: 'DI_CIRCULAR_DEPENDENCY',
          );
        }
        try {
          final instance = registration.factory!() as T;
          _emitEvent(ResolutionEvent(type: T, name: key.name));
          return instance;
        } finally {
          _resolving.remove(key);
        }
      case RegistrationType.factoryParam:
        throw VeloxException(
          message: 'Type $T was registered with registerFactoryParam. '
              'Use getWithParam<$T, P>(param) instead of get<$T>()',
          code: 'DI_REQUIRES_PARAM',
        );
      case RegistrationType.asyncFactory:
        if (registration.instance != null) {
          _emitEvent(ResolutionEvent(type: T, name: key.name));
          return registration.instance! as T;
        }
        throw VeloxException(
          message: 'Type $T was registered with registerAsync. '
              'Use getAsync<$T>() instead of get<$T>(), '
              'or await getAsync<$T>() first before using get<$T>()',
          code: 'DI_REQUIRES_ASYNC',
        );
    }
  }

  void _ensureNotRegistered(_RegistrationKey key) {
    if (_registrations.containsKey(key)) {
      throw VeloxException(
        message: 'Type ${key.type} is already registered'
            '${key.name != null ? ' with name "${key.name}"' : ''}',
        code: 'DI_ALREADY_REGISTERED',
      );
    }
  }

  void _emitEvent(ContainerEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
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

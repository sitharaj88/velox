import 'dart:async';

import 'package:test/test.dart';
import 'package:velox_core/velox_core.dart';
import 'package:velox_di/velox_di.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

abstract class Logger {
  void log(String message);
}

class ConsoleLogger implements Logger {
  @override
  void log(String message) {}
}

class FileLogger implements Logger {
  @override
  void log(String message) {}
}

abstract class Database {
  String get name;
}

class SqliteDatabase implements Database {
  @override
  String get name => 'sqlite';
}

class PostgresDatabase implements Database {
  @override
  String get name => 'postgres';
}

class DisposableService implements Disposable {
  bool isDisposed = false;

  @override
  void dispose() {
    isDisposed = true;
  }
}

class CountingDisposable implements Disposable {
  int disposeCount = 0;

  @override
  void dispose() {
    disposeCount++;
  }
}

class UserRepo {
  UserRepo({required this.token});
  final String token;
}

class AsyncDatabase implements Disposable {
  AsyncDatabase._();
  bool initialized = false;
  bool isDisposed = false;

  static Future<AsyncDatabase> create() async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return AsyncDatabase._()..initialized = true;
  }

  @override
  void dispose() {
    isDisposed = true;
  }
}

class ServiceA {
  ServiceA(this.b);
  final ServiceB b;
}

class ServiceB {
  ServiceB(this.a);
  final ServiceA a;
}

class AuthModule extends VeloxModule {
  @override
  void register(VeloxContainer container) {
    container
      ..registerSingleton<Logger>(ConsoleLogger())
      ..registerLazy<Database>(SqliteDatabase.new);
  }
}

class TrackingModule extends VeloxModule {
  bool onInstallCalled = false;
  bool onUninstallCalled = false;

  @override
  void register(VeloxContainer container) {
    container.registerSingleton<Logger>(ConsoleLogger());
  }

  @override
  void onInstall(VeloxContainer container) {
    onInstallCalled = true;
  }

  @override
  void onUninstall(VeloxContainer container) {
    container.unregister<Logger>();
    onUninstallCalled = true;
  }
}

class EagerTracker {
  EagerTracker() {
    instanceCount++;
  }
  static int instanceCount = 0;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('VeloxContainer', () {
    late VeloxContainer container;

    setUp(() {
      container = VeloxContainer();
      EagerTracker.instanceCount = 0;
    });

    tearDown(() {
      container.dispose();
    });

    // -- Singleton -----------------------------------------------------------

    group('registerSingleton', () {
      test('registers and resolves a singleton', () {
        final logger = ConsoleLogger();
        container.registerSingleton<Logger>(logger);

        expect(container.get<Logger>(), same(logger));
      });

      test('returns the same instance on every get call', () {
        container.registerSingleton<Logger>(ConsoleLogger());

        final first = container.get<Logger>();
        final second = container.get<Logger>();

        expect(first, same(second));
      });

      test('throws when registering the same type twice', () {
        container.registerSingleton<Logger>(ConsoleLogger());

        expect(
          () => container.registerSingleton<Logger>(FileLogger()),
          throwsA(
            isA<VeloxException>().having(
              (e) => e.code,
              'code',
              'DI_ALREADY_REGISTERED',
            ),
          ),
        );
      });
    });

    // -- Lazy singleton ------------------------------------------------------

    group('registerLazy', () {
      test('does not call factory until first get', () {
        var called = false;
        container.registerLazy<Logger>(() {
          called = true;
          return ConsoleLogger();
        });

        expect(called, isFalse);
        container.get<Logger>();
        expect(called, isTrue);
      });

      test('caches the instance after first get', () {
        var callCount = 0;
        container.registerLazy<Logger>(() {
          callCount++;
          return ConsoleLogger();
        });

        final first = container.get<Logger>();
        final second = container.get<Logger>();

        expect(callCount, 1);
        expect(first, same(second));
      });

      test('throws when registering the same type twice', () {
        container.registerLazy<Logger>(ConsoleLogger.new);

        expect(
          () => container.registerLazy<Logger>(ConsoleLogger.new),
          throwsA(isA<VeloxException>()),
        );
      });
    });

    // -- Eager singleton -----------------------------------------------------

    group('registerEager', () {
      test('calls factory immediately at registration time', () {
        container.registerEager<EagerTracker>(EagerTracker.new);

        expect(EagerTracker.instanceCount, 1);
      });

      test('returns the eagerly-created instance on get', () {
        container.registerEager<EagerTracker>(EagerTracker.new);
        final instance = container.get<EagerTracker>();

        expect(instance, isA<EagerTracker>());
        // No additional instance should be created.
        expect(EagerTracker.instanceCount, 1);
      });

      test('returns the same instance on every get call', () {
        container.registerEager<EagerTracker>(EagerTracker.new);

        final first = container.get<EagerTracker>();
        final second = container.get<EagerTracker>();

        expect(first, same(second));
      });

      test('throws when registering the same type twice', () {
        container.registerEager<EagerTracker>(EagerTracker.new);

        expect(
          () => container.registerEager<EagerTracker>(EagerTracker.new),
          throwsA(isA<VeloxException>()),
        );
      });
    });

    // -- Factory -------------------------------------------------------------

    group('registerFactory', () {
      test('creates a new instance on every get call', () {
        container.registerFactory<Database>(SqliteDatabase.new);

        final first = container.get<Database>();
        final second = container.get<Database>();

        expect(first, isNot(same(second)));
      });

      test('throws when registering the same type twice', () {
        container.registerFactory<Database>(SqliteDatabase.new);

        expect(
          () => container.registerFactory<Database>(SqliteDatabase.new),
          throwsA(isA<VeloxException>()),
        );
      });
    });

    // -- Factory with parameter ----------------------------------------------

    group('registerFactoryParam', () {
      test('creates instance with the given parameter', () {
        container.registerFactoryParam<UserRepo, String>(
          (token) => UserRepo(token: token),
        );

        final repo = container.getWithParam<UserRepo, String>('abc123');
        expect(repo.token, 'abc123');
      });

      test('creates a new instance on every call', () {
        container.registerFactoryParam<UserRepo, String>(
          (token) => UserRepo(token: token),
        );

        final first = container.getWithParam<UserRepo, String>('a');
        final second = container.getWithParam<UserRepo, String>('b');

        expect(first, isNot(same(second)));
        expect(first.token, 'a');
        expect(second.token, 'b');
      });

      test('throws DI_NOT_FOUND for unregistered type', () {
        expect(
          () => container.getWithParam<UserRepo, String>('x'),
          throwsA(
            isA<VeloxException>().having(
              (e) => e.code,
              'code',
              'DI_NOT_FOUND',
            ),
          ),
        );
      });

      test('throws DI_NOT_FACTORY_PARAM if not registered with param', () {
        container.registerSingleton<UserRepo>(UserRepo(token: 'fixed'));

        expect(
          () => container.getWithParam<UserRepo, String>('x'),
          throwsA(
            isA<VeloxException>().having(
              (e) => e.code,
              'code',
              'DI_NOT_FACTORY_PARAM',
            ),
          ),
        );
      });

      test('throws DI_REQUIRES_PARAM when using get() instead of '
          'getWithParam()', () {
        container.registerFactoryParam<UserRepo, String>(
          (token) => UserRepo(token: token),
        );

        expect(
          () => container.get<UserRepo>(),
          throwsA(
            isA<VeloxException>().having(
              (e) => e.code,
              'code',
              'DI_REQUIRES_PARAM',
            ),
          ),
        );
      });
    });

    // -- Async factory -------------------------------------------------------

    group('registerAsync', () {
      test('resolves async factory on first getAsync call', () async {
        container.registerAsync<AsyncDatabase>(AsyncDatabase.create);

        final db = await container.getAsync<AsyncDatabase>();
        expect(db.initialized, isTrue);
      });

      test('caches the instance after first getAsync call', () async {
        container.registerAsync<AsyncDatabase>(AsyncDatabase.create);

        final first = await container.getAsync<AsyncDatabase>();
        final second = await container.getAsync<AsyncDatabase>();

        expect(first, same(second));
      });

      test('allows sync get() after getAsync() has resolved', () async {
        container.registerAsync<AsyncDatabase>(AsyncDatabase.create);

        await container.getAsync<AsyncDatabase>();
        final db = container.get<AsyncDatabase>();

        expect(db.initialized, isTrue);
      });

      test('throws DI_REQUIRES_ASYNC when calling get() before getAsync()',
          () {
        container.registerAsync<AsyncDatabase>(AsyncDatabase.create);

        expect(
          () => container.get<AsyncDatabase>(),
          throwsA(
            isA<VeloxException>().having(
              (e) => e.code,
              'code',
              'DI_REQUIRES_ASYNC',
            ),
          ),
        );
      });

      test('throws DI_NOT_ASYNC when calling getAsync on non-async '
          'registration', () {
        container.registerSingleton<Logger>(ConsoleLogger());

        expect(
          () => container.getAsync<Logger>(),
          throwsA(
            isA<VeloxException>().having(
              (e) => e.code,
              'code',
              'DI_NOT_ASYNC',
            ),
          ),
        );
      });

      test('throws DI_NOT_FOUND when type is not registered', () {
        expect(
          () => container.getAsync<AsyncDatabase>(),
          throwsA(
            isA<VeloxException>().having(
              (e) => e.code,
              'code',
              'DI_NOT_FOUND',
            ),
          ),
        );
      });
    });

    // -- Named registrations -------------------------------------------------

    group('named registrations', () {
      test('registers multiple implementations of the same type', () {
        container
          ..registerSingleton<Logger>(ConsoleLogger())
          ..registerSingleton<Logger>(FileLogger(), name: 'file');

        expect(container.get<Logger>(), isA<ConsoleLogger>());
        expect(container.get<Logger>(name: 'file'), isA<FileLogger>());
      });

      test('named and unnamed are independent', () {
        container.registerSingleton<Logger>(ConsoleLogger());

        expect(container.has<Logger>(), isTrue);
        expect(container.has<Logger>(name: 'file'), isFalse);
      });

      test('unregister named does not affect unnamed', () {
        container
          ..registerSingleton<Logger>(ConsoleLogger())
          ..registerSingleton<Logger>(FileLogger(), name: 'file')
          ..unregister<Logger>(name: 'file');

        expect(container.has<Logger>(), isTrue);
        expect(container.has<Logger>(name: 'file'), isFalse);
      });

      test('named lazy registration works correctly', () {
        container
          ..registerLazy<Database>(
            SqliteDatabase.new,
            name: 'sqlite',
          )
          ..registerLazy<Database>(
            PostgresDatabase.new,
            name: 'postgres',
          );

        expect(container.get<Database>(name: 'sqlite').name, 'sqlite');
        expect(container.get<Database>(name: 'postgres').name, 'postgres');
      });

      test('named factory registration works correctly', () {
        container
          ..registerFactory<Database>(SqliteDatabase.new, name: 'sqlite')
          ..registerFactory<Database>(PostgresDatabase.new, name: 'postgres');

        final sqlite1 = container.get<Database>(name: 'sqlite');
        final sqlite2 = container.get<Database>(name: 'sqlite');

        expect(sqlite1.name, 'sqlite');
        expect(sqlite1, isNot(same(sqlite2)));
      });

      test('named factoryParam registration works correctly', () {
        container.registerFactoryParam<UserRepo, String>(
          (token) => UserRepo(token: token),
          name: 'api',
        );

        final repo = container.getWithParam<UserRepo, String>(
          'token',
          name: 'api',
        );
        expect(repo.token, 'token');
      });

      test('named getOrNull returns null for missing name', () {
        container.registerSingleton<Logger>(ConsoleLogger());

        expect(container.getOrNull<Logger>(name: 'missing'), isNull);
      });
    });

    // -- get / getOrNull / has -----------------------------------------------

    group('get', () {
      test('throws VeloxException for unregistered type', () {
        expect(
          container.get<Logger>,
          throwsA(
            isA<VeloxException>().having(
              (e) => e.code,
              'code',
              'DI_NOT_FOUND',
            ),
          ),
        );
      });
    });

    group('getOrNull', () {
      test('returns null for unregistered type', () {
        expect(container.getOrNull<Logger>(), isNull);
      });

      test('returns instance for registered type', () {
        container.registerSingleton<Logger>(ConsoleLogger());

        expect(container.getOrNull<Logger>(), isA<ConsoleLogger>());
      });
    });

    group('has', () {
      test('returns false when type is not registered', () {
        expect(container.has<Logger>(), isFalse);
      });

      test('returns true when type is registered', () {
        container.registerSingleton<Logger>(ConsoleLogger());

        expect(container.has<Logger>(), isTrue);
      });
    });

    // -- unregister / reset / dispose ----------------------------------------

    group('unregister', () {
      test('removes a registration', () {
        container.registerSingleton<Logger>(ConsoleLogger());
        expect(container.has<Logger>(), isTrue);

        container.unregister<Logger>();
        expect(container.has<Logger>(), isFalse);
      });

      test('does nothing for an unregistered type', () {
        // Should not throw.
        container.unregister<Logger>();
      });
    });

    group('reset', () {
      test('removes all registrations', () {
        container
          ..registerSingleton<Logger>(ConsoleLogger())
          ..registerLazy<Database>(SqliteDatabase.new)
          ..reset();

        expect(container.has<Logger>(), isFalse);
        expect(container.has<Database>(), isFalse);
      });
    });

    group('dispose', () {
      test('calls dispose on Disposable singletons', () {
        final service = DisposableService();
        // Use a fresh container to control its lifecycle.
        (VeloxContainer()..registerSingleton<DisposableService>(service))
            .dispose();

        expect(service.isDisposed, isTrue);
      });

      test('calls dispose on resolved lazy singletons', () {
        final service = DisposableService();

        // Force resolution so the instance is cached, then dispose.
        (VeloxContainer()..registerLazy<DisposableService>(() => service))
          ..get<DisposableService>()
          ..dispose();

        expect(service.isDisposed, isTrue);
      });

      test('clears all registrations after dispose', () {
        final c = VeloxContainer()
          ..registerSingleton<Logger>(ConsoleLogger())
          ..dispose();

        expect(c.has<Logger>(), isFalse);
      });

      test('skips factory registrations', () {
        // Factories do not hold instances, so dispose should not fail.
        (VeloxContainer()..registerFactory<Database>(SqliteDatabase.new))
            .dispose();
      });

      test('auto-disposes instances marked with disposable flag', () {
        final service = DisposableService();
        (VeloxContainer()
              ..registerSingleton<DisposableService>(
                service,
                disposable: true,
              ))
            .dispose();

        expect(service.isDisposed, isTrue);
      });

      test('disposes async instances that were resolved', () async {
        final c = VeloxContainer()
          ..registerAsync<AsyncDatabase>(
            AsyncDatabase.create,
            disposable: true,
          );
        final db = await c.getAsync<AsyncDatabase>();
        c.dispose();

        expect(db.isDisposed, isTrue);
      });
    });

    // -- Circular dependency detection ---------------------------------------

    group('circular dependency detection', () {
      test('detects circular dependency in lazy registrations', () {
        container
          ..registerLazy<ServiceA>(() => ServiceA(container.get<ServiceB>()))
          ..registerLazy<ServiceB>(() => ServiceB(container.get<ServiceA>()));

        expect(
          () => container.get<ServiceA>(),
          throwsA(
            isA<VeloxException>().having(
              (e) => e.code,
              'code',
              'DI_CIRCULAR_DEPENDENCY',
            ),
          ),
        );
      });

      test('detects circular dependency in factory registrations', () {
        container
          ..registerFactory<ServiceA>(
            () => ServiceA(container.get<ServiceB>()),
          )
          ..registerFactory<ServiceB>(
            () => ServiceB(container.get<ServiceA>()),
          );

        expect(
          () => container.get<ServiceA>(),
          throwsA(
            isA<VeloxException>().having(
              (e) => e.code,
              'code',
              'DI_CIRCULAR_DEPENDENCY',
            ),
          ),
        );
      });

      test('error message includes resolution chain', () {
        container
          ..registerLazy<ServiceA>(() => ServiceA(container.get<ServiceB>()))
          ..registerLazy<ServiceB>(() => ServiceB(container.get<ServiceA>()));

        expect(
          () => container.get<ServiceA>(),
          throwsA(
            isA<VeloxException>().having(
              (e) => e.message,
              'message',
              contains('Circular dependency detected'),
            ),
          ),
        );
      });
    });

    // -- Service overrides ---------------------------------------------------

    group('override', () {
      test('overrides an existing singleton registration', () {
        container
          ..registerSingleton<Logger>(ConsoleLogger())
          ..override<Logger>(FileLogger());

        expect(container.get<Logger>(), isA<FileLogger>());
      });

      test('works even if no prior registration exists', () {
        container.override<Logger>(ConsoleLogger());

        expect(container.get<Logger>(), isA<ConsoleLogger>());
      });

      test('overrides a named registration', () {
        container
          ..registerSingleton<Logger>(ConsoleLogger(), name: 'log')
          ..override<Logger>(FileLogger(), name: 'log');

        expect(container.get<Logger>(name: 'log'), isA<FileLogger>());
      });
    });

    group('overrideFactory', () {
      test('replaces factory with a new one', () {
        container
          ..registerFactory<Database>(SqliteDatabase.new)
          ..overrideFactory<Database>(PostgresDatabase.new);

        expect(container.get<Database>().name, 'postgres');
      });
    });

    group('overrideLazy', () {
      test('replaces lazy registration with a new factory', () {
        container
          ..registerLazy<Database>(SqliteDatabase.new)
          ..overrideLazy<Database>(PostgresDatabase.new);

        expect(container.get<Database>().name, 'postgres');
      });
    });

    // -- Container events ----------------------------------------------------

    group('events', () {
      test('emits RegistrationEvent on registerSingleton', () async {
        final events = <ContainerEvent>[];
        container.events.listen(events.add);

        container.registerSingleton<Logger>(ConsoleLogger());

        // Allow microtask to flush.
        await Future<void>.delayed(Duration.zero);

        expect(events, hasLength(1));
        expect(events.first, isA<RegistrationEvent>());
        expect(events.first.type, Logger);
      });

      test('emits ResolutionEvent on get', () async {
        final events = <ContainerEvent>[];
        container
          ..registerSingleton<Logger>(ConsoleLogger())
          ..events.listen(events.add)
          ..get<Logger>();

        await Future<void>.delayed(Duration.zero);

        expect(
          events.whereType<ResolutionEvent>(),
          hasLength(1),
        );
      });

      test('emits DisposalEvent on dispose', () async {
        final events = <ContainerEvent>[];
        final service = DisposableService();
        (VeloxContainer()
              ..registerSingleton<DisposableService>(service)
              ..events.listen(events.add))
            .dispose();

        await Future<void>.delayed(Duration.zero);

        expect(
          events.whereType<DisposalEvent>(),
          hasLength(1),
        );
      });

      test('emits UnregistrationEvent on unregister', () async {
        final events = <ContainerEvent>[];
        container
          ..registerSingleton<Logger>(ConsoleLogger())
          ..events.listen(events.add)
          ..unregister<Logger>();

        await Future<void>.delayed(Duration.zero);

        expect(
          events.whereType<UnregistrationEvent>(),
          hasLength(1),
        );
      });

      test('emits OverrideEvent on override', () async {
        final events = <ContainerEvent>[];
        container
          ..registerSingleton<Logger>(ConsoleLogger())
          ..events.listen(events.add)
          ..override<Logger>(FileLogger());

        await Future<void>.delayed(Duration.zero);

        expect(
          events.whereType<OverrideEvent>(),
          hasLength(1),
        );
      });

      test('events include name for named registrations', () async {
        final events = <ContainerEvent>[];
        container.events.listen(events.add);

        container.registerSingleton<Logger>(
          FileLogger(),
          name: 'file',
        );

        await Future<void>.delayed(Duration.zero);

        expect(events.first.name, 'file');
      });
    });

    // -- createScope ---------------------------------------------------------

    group('createScope', () {
      test('returns a VeloxScope instance', () {
        final scope = container.createScope();

        expect(scope, isA<VeloxScope>());
      });
    });

    // -- registeredTypes (visibleForTesting) ----------------------------------

    group('registeredTypes', () {
      test('lists all registered types', () {
        container
          ..registerSingleton<Logger>(ConsoleLogger())
          ..registerLazy<Database>(SqliteDatabase.new);

        expect(
          container.registeredTypes,
          containsAll(<Type>[Logger, Database]),
        );
      });
    });
  });

  // ---------------------------------------------------------------------------
  // VeloxModule
  // ---------------------------------------------------------------------------

  group('VeloxModule', () {
    test('registers dependencies via register()', () {
      final container = VeloxContainer();
      AuthModule().register(container);

      expect(container.has<Logger>(), isTrue);
      expect(container.has<Database>(), isTrue);
      container.dispose();
    });

    test('install() calls register and marks as installed', () {
      final container = VeloxContainer();
      final module = TrackingModule()..install(container);

      expect(module.isInstalled, isTrue);
      expect(module.onInstallCalled, isTrue);
      expect(container.has<Logger>(), isTrue);
      container.dispose();
    });

    test('install() is idempotent -- second call is a no-op', () {
      final container = VeloxContainer();
      // Second install should not throw (even though Logger is already
      // registered).
      final module = AuthModule()
        ..install(container)
        ..install(container);

      expect(module.isInstalled, isTrue);
      container.dispose();
    });

    test('uninstall() calls onUninstall and marks as not installed', () {
      final container = VeloxContainer();
      final module = TrackingModule()
        ..install(container)
        ..uninstall(container);

      expect(module.isInstalled, isFalse);
      expect(module.onUninstallCalled, isTrue);
      expect(container.has<Logger>(), isFalse);
      container.dispose();
    });

    test('uninstall() is a no-op if not installed', () {
      final container = VeloxContainer();
      // Should not throw.
      final module = TrackingModule()..uninstall(container);

      expect(module.onUninstallCalled, isFalse);
      container.dispose();
    });

    test('module can be reinstalled after uninstall', () {
      final container = VeloxContainer();
      final module = TrackingModule()
        ..install(container)
        ..uninstall(container);
      expect(container.has<Logger>(), isFalse);

      // Reset tracking flags.
      module
        ..onInstallCalled = false
        ..install(container);
      expect(module.isInstalled, isTrue);
      expect(module.onInstallCalled, isTrue);
      expect(container.has<Logger>(), isTrue);
      container.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // VeloxScope
  // ---------------------------------------------------------------------------

  group('VeloxScope', () {
    late VeloxContainer parent;
    late VeloxScope scope;

    setUp(() {
      parent = VeloxContainer();
      scope = parent.createScope();
    });

    tearDown(() {
      scope.dispose();
      parent.dispose();
    });

    test('resolves from parent when not registered locally', () {
      final logger = ConsoleLogger();
      parent.registerSingleton<Logger>(logger);

      expect(scope.get<Logger>(), same(logger));
    });

    test('overrides parent registration with local one', () {
      parent.registerSingleton<Logger>(ConsoleLogger());
      final fileLogger = FileLogger();
      scope.registerSingleton<Logger>(fileLogger);

      expect(scope.get<Logger>(), same(fileLogger));
    });

    test('getOrNull returns null when neither scope nor parent has type', () {
      expect(scope.getOrNull<Logger>(), isNull);
    });

    test('getOrNull resolves from parent', () {
      parent.registerSingleton<Logger>(ConsoleLogger());

      expect(scope.getOrNull<Logger>(), isA<ConsoleLogger>());
    });

    test('hasInHierarchy returns true for parent registrations', () {
      parent.registerSingleton<Logger>(ConsoleLogger());

      expect(scope.has<Logger>(), isFalse);
      expect(scope.hasInHierarchy<Logger>(), isTrue);
    });

    test('hasInHierarchy returns true for local registrations', () {
      scope.registerSingleton<Logger>(ConsoleLogger());

      expect(scope.hasInHierarchy<Logger>(), isTrue);
    });

    test('hasInHierarchy returns false when nothing is registered', () {
      expect(scope.hasInHierarchy<Logger>(), isFalse);
    });

    test('dispose only affects the scope, not the parent', () {
      final parentService = DisposableService();

      parent.registerSingleton<DisposableService>(parentService);
      (parent.createScope()..registerSingleton<Logger>(ConsoleLogger()))
          .dispose();

      expect(parentService.isDisposed, isFalse);
      expect(parent.has<DisposableService>(), isTrue);
    });

    test('throws when parent also does not have the type', () {
      expect(
        scope.get<Database>,
        throwsA(isA<VeloxException>()),
      );
    });

    test('named registrations fall back to parent', () {
      parent.registerSingleton<Logger>(ConsoleLogger(), name: 'console');

      expect(scope.get<Logger>(name: 'console'), isA<ConsoleLogger>());
    });

    test('scope can override named registrations from parent', () {
      parent.registerSingleton<Logger>(ConsoleLogger(), name: 'log');
      scope.registerSingleton<Logger>(FileLogger(), name: 'log');

      expect(scope.get<Logger>(name: 'log'), isA<FileLogger>());
    });

    test('hasInHierarchy works with named registrations', () {
      parent.registerSingleton<Logger>(ConsoleLogger(), name: 'named');

      expect(scope.hasInHierarchy<Logger>(name: 'named'), isTrue);
      expect(scope.hasInHierarchy<Logger>(name: 'other'), isFalse);
    });

    test('getWithParam falls back to parent', () {
      parent.registerFactoryParam<UserRepo, String>(
        (token) => UserRepo(token: token),
      );

      final repo = scope.getWithParam<UserRepo, String>('abc');
      expect(repo.token, 'abc');
    });

    test('getAsync falls back to parent', () async {
      parent.registerAsync<AsyncDatabase>(AsyncDatabase.create);

      final db = await scope.getAsync<AsyncDatabase>();
      expect(db.initialized, isTrue);
    });

    // -- Disposal chain ------------------------------------------------------

    group('disposal chain', () {
      test('disposes child scopes when parent scope is disposed', () {
        final parentScope = parent.createScope();
        final childScope = parentScope.createScope();

        final parentDisposable = DisposableService();
        final childDisposable = DisposableService();

        parentScope.registerSingleton<DisposableService>(parentDisposable);
        childScope.registerSingleton<DisposableService>(childDisposable);

        parentScope.dispose();

        expect(childDisposable.isDisposed, isTrue);
        expect(parentDisposable.isDisposed, isTrue);
      });

      test('deeply nested scopes are disposed correctly', () {
        final level1 = parent.createScope();
        final level2 = level1.createScope();
        final level3 = level2.createScope();

        final d1 = CountingDisposable();
        final d2 = CountingDisposable();
        final d3 = CountingDisposable();

        level1.registerSingleton<CountingDisposable>(d1);
        level2.registerSingleton<CountingDisposable>(d2);
        level3.registerSingleton<CountingDisposable>(d3);

        level1.dispose();

        expect(d3.disposeCount, 1);
        expect(d2.disposeCount, 1);
        expect(d1.disposeCount, 1);
      });

      test('disposing a child does not affect its parent', () {
        final parentScope = parent.createScope();
        final childScope = parentScope.createScope();

        final parentDisposable = DisposableService();
        parentScope.registerSingleton<DisposableService>(parentDisposable);

        childScope.dispose();

        expect(parentDisposable.isDisposed, isFalse);
        expect(parentScope.has<DisposableService>(), isTrue);
      });
    });
  });

  // ---------------------------------------------------------------------------
  // ContainerEvent toString
  // ---------------------------------------------------------------------------

  group('ContainerEvent toString', () {
    test('RegistrationEvent toString', () {
      const event = RegistrationEvent(type: Logger);
      expect(event.toString(), 'RegistrationEvent: Logger');
    });

    test('RegistrationEvent toString with name', () {
      const event = RegistrationEvent(type: Logger, name: 'file');
      expect(event.toString(), 'RegistrationEvent: Logger (name: file)');
    });

    test('ResolutionEvent toString', () {
      const event = ResolutionEvent(type: Logger);
      expect(event.toString(), 'ResolutionEvent: Logger');
    });

    test('DisposalEvent toString', () {
      const event = DisposalEvent(type: Logger);
      expect(event.toString(), 'DisposalEvent: Logger');
    });

    test('UnregistrationEvent toString', () {
      const event = UnregistrationEvent(type: Logger);
      expect(event.toString(), 'UnregistrationEvent: Logger');
    });

    test('OverrideEvent toString', () {
      const event = OverrideEvent(type: Logger);
      expect(event.toString(), 'OverrideEvent: Logger');
    });
  });
}

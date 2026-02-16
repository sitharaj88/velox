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

class DisposableService implements Disposable {
  bool isDisposed = false;

  @override
  void dispose() {
    isDisposed = true;
  }
}

class AuthModule extends VeloxModule {
  @override
  void register(VeloxContainer container) {
    container
      ..registerSingleton<Logger>(ConsoleLogger())
      ..registerLazy<Database>(SqliteDatabase.new);
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('VeloxContainer', () {
    late VeloxContainer container;

    setUp(() {
      container = VeloxContainer();
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
        container
          ..registerSingleton<DisposableService>(service)
          ..dispose();

        expect(service.isDisposed, isTrue);
      });

      test('calls dispose on resolved lazy singletons', () {
        final service = DisposableService();

        // Force resolution so the instance is cached, then dispose.
        container
          ..registerLazy<DisposableService>(() => service)
          ..get<DisposableService>()
          ..dispose();

        expect(service.isDisposed, isTrue);
      });

      test('clears all registrations after dispose', () {
        container
          ..registerSingleton<Logger>(ConsoleLogger())
          ..dispose();

        expect(container.has<Logger>(), isFalse);
      });

      test('skips factory registrations', () {
        // Factories do not hold instances, so dispose should not fail.
        container
          ..registerFactory<Database>(SqliteDatabase.new)
          ..dispose();
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
    test('registers dependencies via module', () {
      final container = VeloxContainer();
      AuthModule().register(container);

      expect(container.has<Logger>(), isTrue);
      expect(container.has<Database>(), isTrue);
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
      scope
        ..registerSingleton<Logger>(ConsoleLogger())
        ..dispose();

      expect(parentService.isDisposed, isFalse);
      expect(parent.has<DisposableService>(), isTrue);
    });

    test('throws when parent also does not have the type', () {
      expect(
        scope.get<Database>,
        throwsA(isA<VeloxException>()),
      );
    });
  });
}

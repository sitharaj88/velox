// ignore_for_file: avoid_print, unused_local_variable
import 'package:velox_di/velox_di.dart';

// ---------------------------------------------------------------------------
// Domain contracts
// ---------------------------------------------------------------------------

abstract class Logger {
  void log(String message);
}

abstract class Database {
  String query(String sql);
}

abstract class AuthService {
  bool isAuthenticated();
}

// ---------------------------------------------------------------------------
// Implementations
// ---------------------------------------------------------------------------

class ConsoleLogger implements Logger {
  @override
  void log(String message) => print('[LOG] $message');
}

class SqliteDatabase implements Logger, Database, Disposable {
  SqliteDatabase() {
    print('SqliteDatabase created');
  }

  @override
  void log(String message) => print('[DB] $message');

  @override
  String query(String sql) => 'result of: $sql';

  @override
  void dispose() {
    print('SqliteDatabase disposed');
  }
}

class TokenAuthService implements AuthService {
  TokenAuthService(this._logger);

  final Logger _logger;

  @override
  bool isAuthenticated() {
    _logger.log('Checking authentication...');
    return true;
  }
}

// ---------------------------------------------------------------------------
// Module
// ---------------------------------------------------------------------------

class AppModule extends VeloxModule {
  @override
  void register(VeloxContainer container) {
    container
      ..registerSingleton<Logger>(ConsoleLogger())
      ..registerLazy<Database>(SqliteDatabase.new)
      ..registerFactory<AuthService>(
        () => TokenAuthService(container.get<Logger>()),
      );
  }
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

void main() {
  // 1. Create the root container and register via a module.
  final container = VeloxContainer();
  AppModule().register(container);

  // 2. Resolve services.
  final logger = container.get<Logger>();
  logger.log('Application started');

  // Lazy singleton -- created on first access.
  final db = container.get<Database>();
  print(db.query('SELECT * FROM users'));

  // Factory -- new instance every time.
  final auth1 = container.get<AuthService>();
  final auth2 = container.get<AuthService>();
  print('Same AuthService? ${identical(auth1, auth2)}'); // false

  // 3. Check registration.
  print('Has Logger? ${container.has<Logger>()}');
  print('Has String? ${container.has<String>()}');

  // 4. Safe lookup.
  final maybeLogger = container.getOrNull<Logger>();
  print('Logger found: ${maybeLogger != null}');

  // 5. Scoped container.
  final scope = container.createScope();
  scope.registerSingleton<Logger>(SqliteDatabase());
  print('Scope Logger type: ${scope.get<Logger>().runtimeType}');
  print('Parent Logger type: ${container.get<Logger>().runtimeType}');

  // Falls back to parent for Database.
  print('Scope Database: ${scope.get<Database>().runtimeType}');

  // 6. Dispose -- cleans up Disposable singletons.
  scope.dispose();
  container.dispose();
  print('All resources released.');
}

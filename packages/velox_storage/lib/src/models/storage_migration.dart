import 'package:velox_storage/src/adapters/storage_adapter.dart';

/// Defines a versioned schema migration for storage.
///
/// Migrations run in order from the current version to the target version.
/// Each migration has an [up] method for forward migration and a [down]
/// method for rollback.
///
/// ```dart
/// class AddUserPrefixMigration extends StorageMigration {
///   @override
///   int get version => 2;
///
///   @override
///   String get description => 'Add user_ prefix to user keys';
///
///   @override
///   Future<void> up(StorageAdapter adapter) async {
///     final name = await adapter.read('name');
///     if (name != null) {
///       await adapter.write('user_name', name);
///       await adapter.remove('name');
///     }
///   }
///
///   @override
///   Future<void> down(StorageAdapter adapter) async {
///     final name = await adapter.read('user_name');
///     if (name != null) {
///       await adapter.write('name', name);
///       await adapter.remove('user_name');
///     }
///   }
/// }
/// ```
abstract class StorageMigration {
  /// The version number for this migration.
  ///
  /// Migrations are applied in ascending order of version.
  int get version;

  /// Human-readable description of what this migration does.
  String get description;

  /// Applies the migration forward.
  Future<void> up(StorageAdapter adapter);

  /// Rolls back the migration.
  Future<void> down(StorageAdapter adapter);
}

/// Manages running storage migrations.
///
/// Tracks the current schema version in storage and applies pending
/// migrations in order.
class StorageMigrationRunner {
  /// Creates a [StorageMigrationRunner].
  ///
  /// [adapter] is the storage adapter to migrate.
  /// [migrations] is the list of available migrations.
  StorageMigrationRunner({
    required this.adapter,
    required List<StorageMigration> migrations,
  }) : _migrations = List.of(migrations)
          ..sort((a, b) => a.version.compareTo(b.version));

  /// The storage adapter to operate on.
  final StorageAdapter adapter;

  /// Sorted list of migrations.
  final List<StorageMigration> _migrations;

  /// The storage key used to track the current schema version.
  static const String versionKey = '__velox_storage_version__';

  /// Returns the current schema version from storage.
  ///
  /// Returns 0 if no version has been set.
  Future<int> currentVersion() async {
    final value = await adapter.read(versionKey);
    return value != null ? (int.tryParse(value) ?? 0) : 0;
  }

  /// Returns the list of pending migrations that haven't been applied yet.
  Future<List<StorageMigration>> pendingMigrations() async {
    final current = await currentVersion();
    return _migrations.where((m) => m.version > current).toList();
  }

  /// Runs all pending migrations up to [targetVersion].
  ///
  /// If [targetVersion] is null, runs all pending migrations.
  /// Returns the number of migrations applied.
  Future<int> migrate({int? targetVersion}) async {
    final current = await currentVersion();
    final target = targetVersion ?? _latestVersion;

    if (target == current) return 0;

    if (target > current) {
      return _migrateUp(current, target);
    } else {
      return _migrateDown(current, target);
    }
  }

  int get _latestVersion {
    if (_migrations.isEmpty) return 0;
    return _migrations.last.version;
  }

  Future<int> _migrateUp(int fromVersion, int toVersion) async {
    final toApply = _migrations
        .where((m) => m.version > fromVersion && m.version <= toVersion)
        .toList();

    for (final migration in toApply) {
      await migration.up(adapter);
      await adapter.write(versionKey, migration.version.toString());
    }

    return toApply.length;
  }

  Future<int> _migrateDown(int fromVersion, int toVersion) async {
    final toRollback = _migrations
        .where((m) => m.version <= fromVersion && m.version > toVersion)
        .toList()
        .reversed
        .toList();

    for (final migration in toRollback) {
      await migration.down(adapter);
    }

    await adapter.write(versionKey, toVersion.toString());

    return toRollback.length;
  }
}

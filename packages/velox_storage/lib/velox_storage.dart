/// A local persistence layer for Flutter applications.
///
/// Provides:
/// - Type-safe key-value storage
/// - Pluggable storage adapters (memory, encrypted, namespaced, TTL, lazy)
/// - Reactive storage with change streams
/// - Batch operations with rollback
/// - Typed storage for custom objects
/// - Storage migrations with versioned schema changes
/// - Import/export for backup and restore
/// - Storage observers for monitoring
/// - Storage statistics for hit/miss rates
library;

export 'src/adapters/encrypted_storage_adapter.dart';
export 'src/adapters/lazy_storage_adapter.dart';
export 'src/adapters/memory_storage_adapter.dart';
export 'src/adapters/namespaced_storage_adapter.dart';
export 'src/adapters/storage_adapter.dart';
export 'src/adapters/ttl_storage_adapter.dart';
export 'src/adapters/typed_storage_adapter.dart';
export 'src/models/batch_operation.dart';
export 'src/models/storage_entry.dart';
export 'src/models/storage_migration.dart';
export 'src/models/storage_statistics.dart';
export 'src/models/ttl_entry.dart';
export 'src/observers/storage_observer.dart';
export 'src/velox_storage.dart';

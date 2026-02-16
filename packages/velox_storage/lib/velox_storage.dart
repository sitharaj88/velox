/// A local persistence layer for Flutter applications.
///
/// Provides:
/// - Type-safe key-value storage
/// - Pluggable storage adapters (memory, file-based)
/// - Reactive storage with change streams
/// - Batch operations
library;

export 'src/adapters/memory_storage_adapter.dart';
export 'src/adapters/storage_adapter.dart';
export 'src/models/storage_entry.dart';
export 'src/velox_storage.dart';

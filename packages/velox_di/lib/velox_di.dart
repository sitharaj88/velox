/// Compile-time safe dependency injection container for the Velox Flutter
/// plugin collection.
///
/// Provides:
/// - [VeloxContainer] for singleton, lazy, and factory registrations
/// - [VeloxModule] for grouping related registrations
/// - [VeloxScope] for child containers with parent fallback
/// - [Disposable] interface for automatic resource cleanup
library;

export 'src/velox_container.dart';
export 'src/velox_module.dart';
export 'src/velox_scope.dart';

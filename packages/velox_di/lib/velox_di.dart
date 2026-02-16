/// Compile-time safe dependency injection container for the Velox Flutter
/// plugin collection.
///
/// Provides:
/// - [VeloxContainer] for singleton, lazy, eager, factory, async, and named
///   registrations
/// - [VeloxModule] for grouping related registrations with install/uninstall
/// - [VeloxScope] for child containers with parent fallback
/// - [Disposable] interface for automatic resource cleanup
/// - [ContainerEvent] sealed hierarchy for observing container lifecycle
/// - Circular dependency detection
/// - Service overrides for testing
library;

export 'src/container_event.dart';
export 'src/velox_container.dart';
export 'src/velox_module.dart';
export 'src/velox_scope.dart';

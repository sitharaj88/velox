/// Cross-platform permission handling for Flutter.
///
/// Provides:
/// - [VeloxPermissionType] and [VeloxPermissionStatus] enums
/// - [VeloxPermissionResult] immutable result data
/// - [VeloxPermissionHandler] abstract interface
/// - [VeloxPermissionManager] with caching and reactive streams
library;

export 'src/permission_exception.dart';
export 'src/permission_handler.dart';
export 'src/permission_manager.dart';
export 'src/permission_result.dart';
export 'src/permission_status.dart';
export 'src/permission_type.dart';
export 'src/velox_permissions_platform.dart';

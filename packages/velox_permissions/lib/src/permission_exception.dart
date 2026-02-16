import 'package:velox_core/velox_core.dart';

import 'package:velox_permissions/src/permission_type.dart';

/// Exception thrown when a permission-related operation fails.
///
/// Extends [VeloxException] with an optional [permission] field
/// indicating which permission caused the error.
///
/// ```dart
/// throw VeloxPermissionException(
///   message: 'Camera permission is required',
///   permission: VeloxPermissionType.camera,
///   code: 'PERMISSION_REQUIRED',
/// );
/// ```
class VeloxPermissionException extends VeloxException {
  /// Creates a [VeloxPermissionException].
  const VeloxPermissionException({
    required super.message,
    super.code,
    super.stackTrace,
    super.cause,
    this.permission,
  });

  /// The permission type that caused the exception, if applicable.
  final VeloxPermissionType? permission;

  @override
  String toString() {
    final buffer = StringBuffer('VeloxPermissionException');
    if (code != null) {
      buffer.write('[$code]');
    }
    buffer.write(': $message');
    if (permission != null) {
      buffer.write(' [permission: ${permission!.name}]');
    }
    if (cause != null) {
      buffer.write(' (caused by: $cause)');
    }
    return buffer.toString();
  }
}

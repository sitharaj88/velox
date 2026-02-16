import 'package:meta/meta.dart';

import 'package:velox_permissions/src/permission_status.dart';
import 'package:velox_permissions/src/permission_type.dart';

/// An immutable result of a permission check or request.
///
/// Contains the [permission] type that was checked, its current [status],
/// and the [timestamp] of when the result was obtained.
///
/// ```dart
/// final result = VeloxPermissionResult(
///   permission: VeloxPermissionType.camera,
///   status: VeloxPermissionStatus.granted,
///   timestamp: DateTime.now(),
/// );
/// ```
@immutable
class VeloxPermissionResult {
  /// Creates a [VeloxPermissionResult].
  const VeloxPermissionResult({
    required this.permission,
    required this.status,
    required this.timestamp,
  });

  /// The type of permission that was checked or requested.
  final VeloxPermissionType permission;

  /// The current status of the permission.
  final VeloxPermissionStatus status;

  /// The time at which this result was obtained.
  final DateTime timestamp;

  /// Creates a copy of this result with the given fields replaced.
  ///
  /// ```dart
  /// final updated = result.copyWith(
  ///   status: VeloxPermissionStatus.denied,
  /// );
  /// ```
  VeloxPermissionResult copyWith({
    VeloxPermissionType? permission,
    VeloxPermissionStatus? status,
    DateTime? timestamp,
  }) =>
      VeloxPermissionResult(
        permission: permission ?? this.permission,
        status: status ?? this.status,
        timestamp: timestamp ?? this.timestamp,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VeloxPermissionResult &&
          runtimeType == other.runtimeType &&
          permission == other.permission &&
          status == other.status &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(permission, status, timestamp);

  @override
  String toString() =>
      'VeloxPermissionResult(permission: $permission, status: $status, '
      'timestamp: $timestamp)';
}

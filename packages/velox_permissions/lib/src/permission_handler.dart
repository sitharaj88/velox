import 'package:velox_permissions/src/permission_result.dart';
import 'package:velox_permissions/src/permission_status.dart';
import 'package:velox_permissions/src/permission_type.dart';

/// Abstract interface for platform-specific permission handling.
///
/// Implementations of this class provide the actual platform communication
/// for checking and requesting permissions. Each platform (Android, iOS, web)
/// should provide its own implementation.
///
/// ```dart
/// class AndroidPermissionHandler implements VeloxPermissionHandler {
///   @override
///   Future<VeloxPermissionStatus> check(VeloxPermissionType permission) async {
///     // Platform-specific implementation
///   }
///   // ... other methods
/// }
/// ```
abstract class VeloxPermissionHandler {
  /// Checks the current status of the given [permission].
  ///
  /// Returns the current [VeloxPermissionStatus] without prompting the user.
  Future<VeloxPermissionStatus> check(VeloxPermissionType permission);

  /// Requests the given [permission] from the user.
  ///
  /// Returns a [VeloxPermissionResult] containing the permission type,
  /// the resulting status, and a timestamp.
  Future<VeloxPermissionResult> request(VeloxPermissionType permission);

  /// Requests multiple [permissions] from the user at once.
  ///
  /// Returns a list of [VeloxPermissionResult] for each requested permission.
  Future<List<VeloxPermissionResult>> requestMultiple(
    List<VeloxPermissionType> permissions,
  );

  /// Whether the app should show a rationale for requesting the [permission].
  ///
  /// On Android, this returns `true` if the user has previously denied the
  /// permission but has not selected "Don't ask again". On other platforms,
  /// this may always return `false`.
  Future<bool> shouldShowRationale(VeloxPermissionType permission);

  /// Opens the app's system settings page.
  ///
  /// This is useful when a permission has been permanently denied and the
  /// user needs to manually grant it from the system settings.
  Future<void> openSettings();
}

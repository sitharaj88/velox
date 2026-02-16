import 'dart:async';

import 'package:velox_permissions/src/permission_handler.dart';
import 'package:velox_permissions/src/permission_result.dart';
import 'package:velox_permissions/src/permission_status.dart';
import 'package:velox_permissions/src/permission_type.dart';

/// A high-level permission manager with caching and reactive streams.
///
/// Wraps a [VeloxPermissionHandler] and provides:
/// - In-memory caching of permission results
/// - A broadcast [Stream] of permission changes
/// - Methods to check, request, and manage permissions
///
/// ```dart
/// final manager = VeloxPermissionManager(handler: myHandler);
///
/// // Listen for permission changes
/// manager.onPermissionChanged.listen((result) {
///   print('${result.permission}: ${result.status}');
/// });
///
/// // Request a permission
/// final result = await manager.request(VeloxPermissionType.camera);
///
/// // Clean up when done
/// manager.dispose();
/// ```
class VeloxPermissionManager {
  /// Creates a [VeloxPermissionManager] with the given [handler].
  VeloxPermissionManager({required VeloxPermissionHandler handler})
      : _handler = handler;

  final VeloxPermissionHandler _handler;
  final Map<VeloxPermissionType, VeloxPermissionResult> _cache = {};
  final StreamController<VeloxPermissionResult> _controller =
      StreamController<VeloxPermissionResult>.broadcast();

  /// A broadcast stream that emits a [VeloxPermissionResult] whenever
  /// a permission status changes.
  ///
  /// Subscribe to this stream to reactively update UI or logic when
  /// permissions are granted, denied, or otherwise changed.
  Stream<VeloxPermissionResult> get onPermissionChanged => _controller.stream;

  /// Checks the current status of the given [permission].
  ///
  /// If [forceRefresh] is `false` (the default) and a cached result exists,
  /// the cached result's status is returned. If [forceRefresh] is `true`,
  /// the handler is queried directly and the cache is updated.
  ///
  /// ```dart
  /// final status = await manager.check(VeloxPermissionType.camera);
  /// final fresh = await manager.check(
  ///   VeloxPermissionType.camera,
  ///   forceRefresh: true,
  /// );
  /// ```
  Future<VeloxPermissionStatus> check(
    VeloxPermissionType permission, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cache.containsKey(permission)) {
      return _cache[permission]!.status;
    }

    final status = await _handler.check(permission);
    final result = VeloxPermissionResult(
      permission: permission,
      status: status,
      timestamp: DateTime.now(),
    );
    _cache[permission] = result;
    return status;
  }

  /// Requests the given [permission] from the user.
  ///
  /// Delegates to the underlying handler, updates the cache, and emits
  /// the result on [onPermissionChanged].
  Future<VeloxPermissionResult> request(VeloxPermissionType permission) async {
    final result = await _handler.request(permission);
    _cache[permission] = result;
    _controller.add(result);
    return result;
  }

  /// Requests multiple [permissions] from the user at once.
  ///
  /// Delegates to the underlying handler, updates the cache for each
  /// permission, and emits each result on [onPermissionChanged].
  Future<List<VeloxPermissionResult>> requestMultiple(
    List<VeloxPermissionType> permissions,
  ) async {
    final results = await _handler.requestMultiple(permissions);
    for (final result in results) {
      _cache[result.permission] = result;
      _controller.add(result);
    }
    return results;
  }

  /// Whether the app should show a rationale for requesting the [permission].
  ///
  /// Delegates directly to the underlying handler.
  Future<bool> shouldShowRationale(VeloxPermissionType permission) =>
      _handler.shouldShowRationale(permission);

  /// Opens the app's system settings page.
  ///
  /// Delegates directly to the underlying handler.
  Future<void> openSettings() => _handler.openSettings();

  /// Clears all cached permission results.
  ///
  /// Subsequent calls to [check] will query the handler directly.
  void clearCache() {
    _cache.clear();
  }

  /// Disposes of this manager and releases resources.
  ///
  /// Closes the [onPermissionChanged] stream. This manager should not
  /// be used after calling dispose.
  void dispose() {
    _cache.clear();
    _controller.close();
  }
}

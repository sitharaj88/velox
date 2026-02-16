import 'package:flutter/services.dart';

import 'package:velox_permissions/src/permission_handler.dart';
import 'package:velox_permissions/src/permission_result.dart';
import 'package:velox_permissions/src/permission_status.dart';
import 'package:velox_permissions/src/permission_type.dart';

/// A [VeloxPermissionHandler] implementation that uses [MethodChannel]
/// to communicate with native Android and iOS code.
///
/// This class bridges the Dart permission API with platform-specific
/// implementations via the `com.velox.permissions/method` channel.
///
/// ```dart
/// final handler = VeloxPermissionsPlatform();
/// final status = await handler.check(VeloxPermissionType.camera);
/// ```
class VeloxPermissionsPlatform implements VeloxPermissionHandler {
  /// Creates a [VeloxPermissionsPlatform] instance.
  ///
  /// An optional [channel] can be provided for testing purposes.
  VeloxPermissionsPlatform({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('com.velox.permissions/method');

  final MethodChannel _channel;

  /// Maps a [VeloxPermissionType] to its string representation for the
  /// method channel.
  static String _permissionTypeToString(VeloxPermissionType type) =>
      switch (type) {
        VeloxPermissionType.camera => 'camera',
        VeloxPermissionType.microphone => 'microphone',
        VeloxPermissionType.location => 'location',
        VeloxPermissionType.locationAlways => 'locationAlways',
        VeloxPermissionType.storage => 'storage',
        VeloxPermissionType.photos => 'photos',
        VeloxPermissionType.contacts => 'contacts',
        VeloxPermissionType.calendar => 'calendar',
        VeloxPermissionType.notifications => 'notifications',
        VeloxPermissionType.phone => 'phone',
        VeloxPermissionType.sms => 'sms',
        VeloxPermissionType.bluetooth => 'bluetooth',
        VeloxPermissionType.sensors => 'sensors',
      };

  /// Maps a status string from the native platform to a
  /// [VeloxPermissionStatus].
  static VeloxPermissionStatus _statusFromString(String status) =>
      switch (status) {
        'granted' => VeloxPermissionStatus.granted,
        'denied' => VeloxPermissionStatus.denied,
        'permanentlyDenied' => VeloxPermissionStatus.permanentlyDenied,
        'restricted' => VeloxPermissionStatus.restricted,
        'limited' => VeloxPermissionStatus.limited,
        _ => VeloxPermissionStatus.unknown,
      };

  @override
  Future<VeloxPermissionStatus> check(VeloxPermissionType permission) async {
    final result = await _channel.invokeMethod<String>(
      'check',
      {'permission': _permissionTypeToString(permission)},
    );
    return _statusFromString(result ?? 'unknown');
  }

  @override
  Future<VeloxPermissionResult> request(VeloxPermissionType permission) async {
    final result = await _channel.invokeMethod<String>(
      'request',
      {'permission': _permissionTypeToString(permission)},
    );
    return VeloxPermissionResult(
      permission: permission,
      status: _statusFromString(result ?? 'unknown'),
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<List<VeloxPermissionResult>> requestMultiple(
    List<VeloxPermissionType> permissions,
  ) async {
    final permissionStrings =
        permissions.map(_permissionTypeToString).toList();
    final result = await _channel.invokeMapMethod<String, String>(
      'requestMultiple',
      {'permissions': permissionStrings},
    );

    return [
      for (final permission in permissions)
        VeloxPermissionResult(
          permission: permission,
          status: _statusFromString(
            result?[_permissionTypeToString(permission)] ?? 'unknown',
          ),
          timestamp: DateTime.now(),
        ),
    ];
  }

  @override
  Future<bool> shouldShowRationale(VeloxPermissionType permission) async {
    final result = await _channel.invokeMethod<bool>(
      'shouldShowRationale',
      {'permission': _permissionTypeToString(permission)},
    );
    return result ?? false;
  }

  @override
  Future<void> openSettings() async {
    await _channel.invokeMethod<void>('openSettings');
  }
}

import 'dart:io' show Platform;

import 'package:flutter/services.dart';

import 'package:velox_device/src/battery_info.dart';
import 'package:velox_device/src/device_exception.dart';
import 'package:velox_device/src/device_info.dart';
import 'package:velox_device/src/device_info_provider.dart';
import 'package:velox_device/src/device_platform.dart';
import 'package:velox_device/src/device_type.dart';
import 'package:velox_device/src/screen_info.dart';

/// A [VeloxDeviceInfoProvider] implementation that communicates with native
/// platform code through a [MethodChannel].
///
/// This bridge delegates device information queries to the native Android
/// (Kotlin) and iOS (Swift) implementations via the
/// `'com.velox.device/method'` channel.
class VeloxDeviceMethodChannel extends VeloxDeviceInfoProvider {
  /// Creates a [VeloxDeviceMethodChannel].
  ///
  /// An optional [channel] can be provided for testing purposes.
  VeloxDeviceMethodChannel({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('com.velox.device/method');

  final MethodChannel _channel;

  @override
  VeloxDevicePlatform get currentPlatform {
    if (Platform.isAndroid) return VeloxDevicePlatform.android;
    if (Platform.isIOS) return VeloxDevicePlatform.ios;
    if (Platform.isMacOS) return VeloxDevicePlatform.macos;
    if (Platform.isWindows) return VeloxDevicePlatform.windows;
    if (Platform.isLinux) return VeloxDevicePlatform.linux;
    if (Platform.isFuchsia) return VeloxDevicePlatform.fuchsia;
    return VeloxDevicePlatform.unknown;
  }

  @override
  Future<VeloxDeviceInfo> getDeviceInfo() async {
    try {
      final result =
          await _channel.invokeMapMethod<String, dynamic>('getDeviceInfo');
      if (result == null) {
        throw const VeloxDeviceException(
          message: 'Native getDeviceInfo returned null',
          code: 'NULL_RESULT',
        );
      }

      final deviceTypeString = result['deviceType'] as String? ?? 'unknown';
      final deviceType = _parseDeviceType(deviceTypeString);

      return VeloxDeviceInfo(
        platform: currentPlatform,
        deviceType: deviceType,
        model: result['model'] as String? ?? 'Unknown',
        manufacturer: result['manufacturer'] as String? ?? 'Unknown',
        osVersion: result['osVersion'] as String? ?? 'Unknown',
        appVersion: result['appVersion'] as String? ?? 'Unknown',
      );
    } on PlatformException catch (e) {
      throw VeloxDeviceException(
        message: 'Failed to get device info: ${e.message}',
        code: e.code,
        cause: e,
        platform: currentPlatform.name,
      );
    }
  }

  @override
  Future<VeloxScreenInfo> getScreenInfo() async {
    try {
      final result =
          await _channel.invokeMapMethod<String, dynamic>('getScreenInfo');
      if (result == null) {
        throw const VeloxDeviceException(
          message: 'Native getScreenInfo returned null',
          code: 'NULL_RESULT',
        );
      }

      return VeloxScreenInfo(
        width: (result['width'] as num).toDouble(),
        height: (result['height'] as num).toDouble(),
        pixelRatio: (result['pixelRatio'] as num).toDouble(),
      );
    } on PlatformException catch (e) {
      throw VeloxDeviceException(
        message: 'Failed to get screen info: ${e.message}',
        code: e.code,
        cause: e,
        platform: currentPlatform.name,
      );
    }
  }

  @override
  Future<VeloxBatteryInfo> getBatteryInfo() async {
    try {
      final result =
          await _channel.invokeMapMethod<String, dynamic>('getBatteryInfo');
      if (result == null) {
        throw const VeloxDeviceException(
          message: 'Native getBatteryInfo returned null',
          code: 'NULL_RESULT',
        );
      }

      final stateString = result['state'] as String? ?? 'unknown';
      final state = _parseBatteryState(stateString);

      return VeloxBatteryInfo(
        level: (result['level'] as num).toDouble(),
        state: state,
        isLowPower: result['isLowPower'] as bool? ?? false,
      );
    } on PlatformException catch (e) {
      throw VeloxDeviceException(
        message: 'Failed to get battery info: ${e.message}',
        code: e.code,
        cause: e,
        platform: currentPlatform.name,
      );
    }
  }

  VeloxDeviceType _parseDeviceType(String value) => switch (value) {
        'phone' => VeloxDeviceType.phone,
        'tablet' => VeloxDeviceType.tablet,
        'desktop' => VeloxDeviceType.desktop,
        'tv' => VeloxDeviceType.tv,
        'watch' => VeloxDeviceType.watch,
        _ => VeloxDeviceType.unknown,
      };

  VeloxBatteryState _parseBatteryState(String value) => switch (value) {
        'charging' => VeloxBatteryState.charging,
        'discharging' => VeloxBatteryState.discharging,
        'full' => VeloxBatteryState.full,
        'notCharging' => VeloxBatteryState.notCharging,
        _ => VeloxBatteryState.unknown,
      };
}

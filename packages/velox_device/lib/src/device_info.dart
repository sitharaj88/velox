import 'package:meta/meta.dart';

import 'package:velox_device/src/battery_info.dart';
import 'package:velox_device/src/device_platform.dart';
import 'package:velox_device/src/device_type.dart';
import 'package:velox_device/src/screen_info.dart';

/// Immutable aggregate data class containing all device information.
///
/// Combines platform, device type, hardware details, OS and app versions,
/// and optional screen and battery information into a single object.
///
/// ```dart
/// final info = VeloxDeviceInfo(
///   platform: VeloxDevicePlatform.android,
///   deviceType: VeloxDeviceType.phone,
///   model: 'Pixel 7',
///   manufacturer: 'Google',
///   osVersion: '14.0',
///   appVersion: '1.2.3',
/// );
/// print(info.model); // 'Pixel 7'
/// ```
@immutable
class VeloxDeviceInfo {
  /// Creates a [VeloxDeviceInfo] with the given device data.
  ///
  /// - [platform] is the operating system platform.
  /// - [deviceType] is the form factor of the device.
  /// - [model] is the device model name.
  /// - [manufacturer] is the device manufacturer.
  /// - [osVersion] is the operating system version string.
  /// - [appVersion] is the application version string.
  /// - [screenInfo] is optional screen dimension data.
  /// - [batteryInfo] is optional battery state data.
  const VeloxDeviceInfo({
    required this.platform,
    required this.deviceType,
    required this.model,
    required this.manufacturer,
    required this.osVersion,
    required this.appVersion,
    this.screenInfo,
    this.batteryInfo,
  });

  /// The operating system platform.
  final VeloxDevicePlatform platform;

  /// The form factor of the device.
  final VeloxDeviceType deviceType;

  /// The device model name (e.g., 'Pixel 7', 'iPhone 15').
  final String model;

  /// The device manufacturer (e.g., 'Google', 'Apple').
  final String manufacturer;

  /// The operating system version string (e.g., '14.0', '17.1').
  final String osVersion;

  /// The application version string (e.g., '1.2.3').
  final String appVersion;

  /// Optional screen dimension and density information.
  final VeloxScreenInfo? screenInfo;

  /// Optional battery level and state information.
  final VeloxBatteryInfo? batteryInfo;

  /// Creates a copy of this [VeloxDeviceInfo] with the given fields replaced.
  VeloxDeviceInfo copyWith({
    VeloxDevicePlatform? platform,
    VeloxDeviceType? deviceType,
    String? model,
    String? manufacturer,
    String? osVersion,
    String? appVersion,
    VeloxScreenInfo? screenInfo,
    VeloxBatteryInfo? batteryInfo,
  }) =>
      VeloxDeviceInfo(
        platform: platform ?? this.platform,
        deviceType: deviceType ?? this.deviceType,
        model: model ?? this.model,
        manufacturer: manufacturer ?? this.manufacturer,
        osVersion: osVersion ?? this.osVersion,
        appVersion: appVersion ?? this.appVersion,
        screenInfo: screenInfo ?? this.screenInfo,
        batteryInfo: batteryInfo ?? this.batteryInfo,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VeloxDeviceInfo &&
          runtimeType == other.runtimeType &&
          platform == other.platform &&
          deviceType == other.deviceType &&
          model == other.model &&
          manufacturer == other.manufacturer &&
          osVersion == other.osVersion &&
          appVersion == other.appVersion &&
          screenInfo == other.screenInfo &&
          batteryInfo == other.batteryInfo;

  @override
  int get hashCode => Object.hash(
        platform,
        deviceType,
        model,
        manufacturer,
        osVersion,
        appVersion,
        screenInfo,
        batteryInfo,
      );

  @override
  String toString() =>
      'VeloxDeviceInfo(platform: $platform, deviceType: $deviceType, '
      'model: $model, manufacturer: $manufacturer, osVersion: $osVersion, '
      'appVersion: $appVersion, screenInfo: $screenInfo, '
      'batteryInfo: $batteryInfo)';
}

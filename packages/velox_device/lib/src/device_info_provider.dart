import 'package:velox_device/src/battery_info.dart';
import 'package:velox_device/src/device_info.dart';
import 'package:velox_device/src/device_platform.dart';
import 'package:velox_device/src/screen_info.dart';

/// Abstract interface for retrieving device information.
///
/// Platform-specific implementations should extend this class to provide
/// actual device data. This abstraction allows for easy testing and
/// platform-agnostic code.
///
/// ```dart
/// class MyDeviceInfoProvider extends VeloxDeviceInfoProvider {
///   @override
///   Future<VeloxDeviceInfo> getDeviceInfo() async {
///     // Platform-specific implementation
///   }
///
///   @override
///   Future<VeloxScreenInfo> getScreenInfo() async {
///     // Platform-specific implementation
///   }
///
///   @override
///   Future<VeloxBatteryInfo> getBatteryInfo() async {
///     // Platform-specific implementation
///   }
///
///   @override
///   VeloxDevicePlatform get currentPlatform => VeloxDevicePlatform.android;
/// }
/// ```
abstract class VeloxDeviceInfoProvider {
  /// Creates a [VeloxDeviceInfoProvider].
  const VeloxDeviceInfoProvider();

  /// Retrieves comprehensive device information.
  ///
  /// Returns a [VeloxDeviceInfo] containing platform, device type,
  /// model, manufacturer, OS version, app version, and optionally
  /// screen and battery information.
  Future<VeloxDeviceInfo> getDeviceInfo();

  /// Retrieves screen dimension and density information.
  ///
  /// Returns a [VeloxScreenInfo] with physical width, height,
  /// and pixel ratio.
  Future<VeloxScreenInfo> getScreenInfo();

  /// Retrieves battery level and state information.
  ///
  /// Returns a [VeloxBatteryInfo] with current level, charging state,
  /// and low power mode status.
  Future<VeloxBatteryInfo> getBatteryInfo();

  /// The platform the application is currently running on.
  VeloxDevicePlatform get currentPlatform;
}

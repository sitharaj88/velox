/// Enum representing the form factor of the device.
///
/// Provides convenient getters for device categories:
/// - [isHandheld] for phone and watch devices
/// - [hasLargeScreen] for tablet, desktop, and TV devices
///
/// ```dart
/// final type = VeloxDeviceType.phone;
/// print(type.isHandheld); // true
/// print(type.hasLargeScreen); // false
/// ```
enum VeloxDeviceType {
  /// A phone device.
  phone,

  /// A tablet device.
  tablet,

  /// A desktop computer.
  desktop,

  /// A television device.
  tv,

  /// A watch or wearable device.
  watch,

  /// Unknown or unsupported device type.
  unknown;

  /// Whether this device is handheld (phone or watch).
  bool get isHandheld => this == phone || this == watch;

  /// Whether this device has a large screen (tablet, desktop, or TV).
  bool get hasLargeScreen => this == tablet || this == desktop || this == tv;
}

/// Platform detection utilities that work across all platforms.
///
/// Unlike `dart:io`'s `Platform`, this works on web as well.
///
/// ```dart
/// if (VeloxPlatform.isAndroid) {
///   // Android-specific code
/// }
/// ```
abstract final class VeloxPlatform {
  /// Returns `true` if running on the web.
  static bool get isWeb => identical(0, 0.0);

  /// Returns `true` if running on Android.
  static bool get isAndroid => _platform == 'android';

  /// Returns `true` if running on iOS.
  static bool get isIOS => _platform == 'ios';

  /// Returns `true` if running on macOS.
  static bool get isMacOS => _platform == 'macos';

  /// Returns `true` if running on Windows.
  static bool get isWindows => _platform == 'windows';

  /// Returns `true` if running on Linux.
  static bool get isLinux => _platform == 'linux';

  /// Returns `true` if running on Fuchsia.
  static bool get isFuchsia => _platform == 'fuchsia';

  /// Returns `true` if running on a mobile platform (Android or iOS).
  static bool get isMobile => isAndroid || isIOS;

  /// Returns `true` if running on a desktop platform.
  static bool get isDesktop => isMacOS || isWindows || isLinux;

  /// Returns the current platform name.
  static String get platformName {
    if (isWeb) return 'web';
    return _platform;
  }

  static String get _platform =>
      const String.fromEnvironment('dart.vm.product').isNotEmpty
          ? 'unknown'
          : 'unknown';
}

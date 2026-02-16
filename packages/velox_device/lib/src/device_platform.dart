/// Enum representing the platform the application is running on.
///
/// Provides convenient getters for platform categories:
/// - [isMobile] for Android and iOS
/// - [isDesktop] for macOS, Windows, and Linux
/// - [isWeb] for web browsers
///
/// ```dart
/// final platform = VeloxDevicePlatform.android;
/// print(platform.isMobile); // true
/// print(platform.displayName); // 'Android'
/// ```
enum VeloxDevicePlatform {
  /// Google Android platform.
  android,

  /// Apple iOS platform.
  ios,

  /// Web browser platform.
  web,

  /// Apple macOS platform.
  macos,

  /// Microsoft Windows platform.
  windows,

  /// Linux platform.
  linux,

  /// Google Fuchsia platform.
  fuchsia,

  /// Unknown or unsupported platform.
  unknown;

  /// Whether this platform is a mobile platform (Android or iOS).
  bool get isMobile => this == android || this == ios;

  /// Whether this platform is a desktop platform (macOS, Windows, or Linux).
  bool get isDesktop => this == macos || this == windows || this == linux;

  /// Whether this platform is a web browser.
  bool get isWeb => this == web;

  /// A human-readable display name for this platform.
  String get displayName => switch (this) {
        android => 'Android',
        ios => 'iOS',
        web => 'Web',
        macos => 'macOS',
        windows => 'Windows',
        linux => 'Linux',
        fuchsia => 'Fuchsia',
        unknown => 'Unknown',
      };
}

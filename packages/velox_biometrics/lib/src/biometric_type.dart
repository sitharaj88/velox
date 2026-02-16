/// Enum representing the types of biometric authentication available.
///
/// Each type corresponds to a specific biometric hardware capability
/// on the device.
enum VeloxBiometricType {
  /// Fingerprint-based authentication.
  fingerprint,

  /// Face recognition-based authentication.
  face,

  /// Iris scan-based authentication.
  iris,

  /// An unknown or unsupported biometric type.
  unknown;

  /// A human-readable display name for this biometric type.
  ///
  /// Returns a formatted string suitable for display in UI elements:
  /// - [fingerprint] returns `'Fingerprint'`
  /// - [face] returns `'Face Recognition'`
  /// - [iris] returns `'Iris Scan'`
  /// - [unknown] returns `'Unknown'`
  String get displayName => switch (this) {
    VeloxBiometricType.fingerprint => 'Fingerprint',
    VeloxBiometricType.face => 'Face Recognition',
    VeloxBiometricType.iris => 'Iris Scan',
    VeloxBiometricType.unknown => 'Unknown',
  };

  /// Whether this biometric type is considered a strong authenticator.
  ///
  /// Strong biometrics provide a higher level of security and are
  /// generally preferred for sensitive operations.
  ///
  /// - [fingerprint], [face], and [iris] are considered strong.
  /// - [unknown] is not considered strong.
  bool get isStrong => switch (this) {
    VeloxBiometricType.fingerprint => true,
    VeloxBiometricType.face => true,
    VeloxBiometricType.iris => true,
    VeloxBiometricType.unknown => false,
  };
}

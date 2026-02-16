/// Enum representing the availability status of biometric authentication.
///
/// Used to determine whether the device can perform biometric
/// authentication and why it might be unavailable.
enum VeloxBiometricStatus {
  /// Biometric authentication is available and ready to use.
  available,

  /// Biometric hardware is present but currently unavailable.
  ///
  /// This may be due to temporary system conditions.
  unavailable,

  /// Biometric hardware is present but no biometrics are enrolled.
  ///
  /// The user needs to register at least one biometric in device settings.
  notEnrolled,

  /// Biometric authentication is locked out due to too many failed attempts.
  ///
  /// The user may need to wait or use an alternative authentication method.
  lockedOut,

  /// The device does not support biometric authentication.
  ///
  /// No biometric hardware is available on this device.
  notSupported;

  /// Whether authentication can be performed in this status.
  ///
  /// Returns `true` only when the status is [available].
  bool get canAuthenticate => this == VeloxBiometricStatus.available;

  /// Whether biometric hardware is present on the device.
  ///
  /// Returns `true` for all statuses except [notSupported], since the
  /// hardware exists even if authentication is currently unavailable,
  /// not enrolled, or locked out.
  bool get isHardwarePresent => this != VeloxBiometricStatus.notSupported;
}

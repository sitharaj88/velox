import 'package:velox_biometrics/src/auth_result.dart';
import 'package:velox_biometrics/src/biometric_config.dart';
import 'package:velox_biometrics/src/biometric_status.dart';
import 'package:velox_biometrics/src/biometric_type.dart';

/// Abstract interface for biometric authentication.
///
/// Platform implementations should extend this class to provide
/// biometric authentication capabilities for their specific platform
/// (e.g., Android, iOS).
///
/// ```dart
/// class AndroidBiometricAuthenticator extends VeloxBiometricAuthenticator {
///   @override
///   Future<VeloxBiometricStatus> checkAvailability() async {
///     // Check Android BiometricManager
///     return VeloxBiometricStatus.available;
///   }
///
///   // ... other implementations
/// }
/// ```
abstract class VeloxBiometricAuthenticator {
  /// Checks the availability of biometric authentication on the device.
  ///
  /// Returns a [VeloxBiometricStatus] indicating whether biometric
  /// authentication is available and ready, or why it is not.
  Future<VeloxBiometricStatus> checkAvailability();

  /// Returns a list of biometric types available on the device.
  ///
  /// The returned list may be empty if no biometric hardware is
  /// available or no biometrics are enrolled.
  Future<List<VeloxBiometricType>> getAvailableBiometrics();

  /// Performs a biometric authentication attempt.
  ///
  /// The [config] parameter controls the behavior and presentation
  /// of the authentication dialog.
  ///
  /// Returns a [VeloxBiometricAuthResult] with the outcome of
  /// the authentication attempt.
  Future<VeloxBiometricAuthResult> authenticate(VeloxBiometricConfig config);

  /// Whether the device supports biometric authentication.
  ///
  /// Returns `true` if biometric hardware is present, regardless
  /// of whether biometrics are enrolled.
  Future<bool> get isDeviceSupported;

  /// Whether at least one biometric is enrolled on the device.
  ///
  /// Returns `true` if the user has registered at least one
  /// biometric credential (e.g., a fingerprint or face).
  Future<bool> get isEnrolled;
}

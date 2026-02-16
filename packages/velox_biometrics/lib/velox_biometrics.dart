/// Biometric authentication abstractions for Flutter.
///
/// Provides:
/// - [VeloxBiometricType] and [VeloxBiometricStatus] enums
/// - [VeloxBiometricConfig] for authentication configuration
/// - [VeloxBiometricAuthResult] for authentication results
/// - [VeloxBiometricAuthenticator] abstract interface
/// - [VeloxBiometricManager] with Result-based API
library;

export 'src/auth_result.dart';
export 'src/biometric_authenticator.dart';
export 'src/biometric_config.dart';
export 'src/biometric_exception.dart';
export 'src/biometric_manager.dart';
export 'src/biometric_status.dart';
export 'src/biometric_type.dart';
export 'src/velox_biometrics_platform.dart';

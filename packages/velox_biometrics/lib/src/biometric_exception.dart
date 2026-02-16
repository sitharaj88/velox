import 'package:velox_biometrics/src/biometric_type.dart';
import 'package:velox_core/velox_core.dart';

/// Exception thrown when a biometric operation fails.
///
/// Extends [VeloxPlatformException] with an optional [biometricType]
/// to indicate which biometric was involved in the failure.
///
/// ```dart
/// throw VeloxBiometricException(
///   message: 'Fingerprint sensor unavailable',
///   code: 'SENSOR_UNAVAILABLE',
///   biometricType: VeloxBiometricType.fingerprint,
///   platform: 'android',
/// );
/// ```
class VeloxBiometricException extends VeloxPlatformException {
  /// Creates a [VeloxBiometricException].
  const VeloxBiometricException({
    required super.message,
    super.code,
    super.stackTrace,
    super.cause,
    super.platform,
    this.biometricType,
  });

  /// The type of biometric involved in the failure, if known.
  final VeloxBiometricType? biometricType;

  @override
  String toString() {
    final buffer = StringBuffer('VeloxBiometricException');
    if (code != null) {
      buffer.write('[$code]');
    }
    if (platform != null) {
      buffer.write('($platform)');
    }
    buffer.write(': $message');
    if (biometricType != null) {
      buffer.write(' [biometricType: ${biometricType!.name}]');
    }
    if (cause != null) {
      buffer.write(' (caused by: $cause)');
    }
    return buffer.toString();
  }
}

import 'package:meta/meta.dart';

import 'package:velox_biometrics/src/biometric_type.dart';

/// Enum representing the outcome status of an authentication attempt.
enum VeloxAuthResultStatus {
  /// Authentication was successful.
  success,

  /// Authentication failed (e.g., biometric did not match).
  failed,

  /// Authentication was cancelled by the user.
  cancelled,

  /// Authentication is locked out due to too many failed attempts.
  lockedOut,

  /// An error occurred during authentication.
  error,
}

/// An immutable result of a biometric authentication attempt.
///
/// Contains the [status] of the attempt, the optional [biometricType]
/// that was used, any [errorMessage] if applicable, and the [timestamp]
/// of when the attempt occurred.
///
/// ```dart
/// final result = VeloxBiometricAuthResult(
///   status: VeloxAuthResultStatus.success,
///   biometricType: VeloxBiometricType.fingerprint,
///   timestamp: DateTime.now(),
/// );
///
/// if (result.isSuccess) {
///   print('Authenticated with ${result.biometricType?.displayName}');
/// }
/// ```
@immutable
class VeloxBiometricAuthResult {
  /// Creates a [VeloxBiometricAuthResult].
  ///
  /// The [status] and [timestamp] are required. The [biometricType]
  /// and [errorMessage] are optional.
  const VeloxBiometricAuthResult({
    required this.status,
    required this.timestamp,
    this.biometricType,
    this.errorMessage,
  });

  /// The outcome status of the authentication attempt.
  final VeloxAuthResultStatus status;

  /// The type of biometric that was used, if known.
  final VeloxBiometricType? biometricType;

  /// An error message providing additional details, if applicable.
  final String? errorMessage;

  /// The timestamp of when the authentication attempt occurred.
  final DateTime timestamp;

  /// Whether the authentication was successful.
  bool get isSuccess => status == VeloxAuthResultStatus.success;

  /// Whether the authentication was cancelled by the user.
  bool get isCancelled => status == VeloxAuthResultStatus.cancelled;

  /// Creates a copy of this result with the given fields replaced.
  VeloxBiometricAuthResult copyWith({
    VeloxAuthResultStatus? status,
    VeloxBiometricType? biometricType,
    String? errorMessage,
    DateTime? timestamp,
  }) =>
      VeloxBiometricAuthResult(
        status: status ?? this.status,
        biometricType: biometricType ?? this.biometricType,
        errorMessage: errorMessage ?? this.errorMessage,
        timestamp: timestamp ?? this.timestamp,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VeloxBiometricAuthResult &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          biometricType == other.biometricType &&
          errorMessage == other.errorMessage &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(
    status,
    biometricType,
    errorMessage,
    timestamp,
  );

  @override
  String toString() =>
      'VeloxBiometricAuthResult('
      'status: $status, '
      'biometricType: $biometricType, '
      'errorMessage: $errorMessage, '
      'timestamp: $timestamp)';
}

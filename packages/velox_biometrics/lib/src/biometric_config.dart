import 'package:meta/meta.dart';

import 'package:velox_biometrics/src/biometric_type.dart';

/// Configuration for a biometric authentication request.
///
/// Controls the behavior and presentation of the authentication dialog,
/// including the prompt message, fallback options, and timeout.
///
/// ```dart
/// const config = VeloxBiometricConfig(
///   localizedReason: 'Please authenticate to access your account',
///   biometricOnly: true,
///   authTimeout: Duration(seconds: 30),
/// );
/// ```
@immutable
class VeloxBiometricConfig {
  /// Creates a [VeloxBiometricConfig].
  ///
  /// The [localizedReason] is the message displayed to the user
  /// explaining why authentication is needed.
  const VeloxBiometricConfig({
    required this.localizedReason,
    this.useErrorDialogs = true,
    this.stickyAuth = false,
    this.biometricOnly = false,
    this.authTimeout,
    this.allowedTypes = const [
      VeloxBiometricType.fingerprint,
      VeloxBiometricType.face,
      VeloxBiometricType.iris,
      VeloxBiometricType.unknown,
    ],
  });

  /// The message displayed to the user explaining why authentication
  /// is needed.
  ///
  /// This should be a localized string that clearly describes the
  /// purpose of the authentication request.
  final String localizedReason;

  /// Whether to use platform-specific error dialogs.
  ///
  /// When `true` (the default), the system will display error dialogs
  /// for common issues like unenrolled biometrics.
  final bool useErrorDialogs;

  /// Whether authentication should persist across app pause/resume.
  ///
  /// When `false` (the default), the authentication session is
  /// invalidated when the app is paused (e.g., user switches apps).
  /// When `true`, the authentication persists.
  final bool stickyAuth;

  /// Whether to restrict authentication to biometrics only.
  ///
  /// When `false` (the default), the system may allow fallback to
  /// PIN, pattern, or password. When `true`, only biometric
  /// authentication is allowed.
  final bool biometricOnly;

  /// An optional timeout for the authentication attempt.
  ///
  /// If provided, the authentication will be cancelled after
  /// this duration elapses. If `null`, no timeout is applied.
  final Duration? authTimeout;

  /// The biometric types that are allowed for authentication.
  ///
  /// Defaults to all types. Only biometrics matching one of
  /// these types will be accepted.
  final List<VeloxBiometricType> allowedTypes;

  /// Creates a copy of this config with the given fields replaced.
  VeloxBiometricConfig copyWith({
    String? localizedReason,
    bool? useErrorDialogs,
    bool? stickyAuth,
    bool? biometricOnly,
    Duration? authTimeout,
    List<VeloxBiometricType>? allowedTypes,
  }) =>
      VeloxBiometricConfig(
        localizedReason: localizedReason ?? this.localizedReason,
        useErrorDialogs: useErrorDialogs ?? this.useErrorDialogs,
        stickyAuth: stickyAuth ?? this.stickyAuth,
        biometricOnly: biometricOnly ?? this.biometricOnly,
        authTimeout: authTimeout ?? this.authTimeout,
        allowedTypes: allowedTypes ?? this.allowedTypes,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VeloxBiometricConfig &&
          runtimeType == other.runtimeType &&
          localizedReason == other.localizedReason &&
          useErrorDialogs == other.useErrorDialogs &&
          stickyAuth == other.stickyAuth &&
          biometricOnly == other.biometricOnly &&
          authTimeout == other.authTimeout &&
          _listEquals(allowedTypes, other.allowedTypes);

  @override
  int get hashCode => Object.hash(
    localizedReason,
    useErrorDialogs,
    stickyAuth,
    biometricOnly,
    authTimeout,
    Object.hashAll(allowedTypes),
  );

  @override
  String toString() =>
      'VeloxBiometricConfig('
      'localizedReason: $localizedReason, '
      'useErrorDialogs: $useErrorDialogs, '
      'stickyAuth: $stickyAuth, '
      'biometricOnly: $biometricOnly, '
      'authTimeout: $authTimeout, '
      'allowedTypes: $allowedTypes)';

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

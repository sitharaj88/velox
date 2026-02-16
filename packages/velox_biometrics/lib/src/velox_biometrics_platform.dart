import 'package:flutter/services.dart';

import 'package:velox_biometrics/src/auth_result.dart';
import 'package:velox_biometrics/src/biometric_authenticator.dart';
import 'package:velox_biometrics/src/biometric_config.dart';
import 'package:velox_biometrics/src/biometric_status.dart';
import 'package:velox_biometrics/src/biometric_type.dart';

/// Platform implementation of [VeloxBiometricAuthenticator] using
/// [MethodChannel] to communicate with native Android and iOS code.
///
/// This class bridges the Dart interface to native biometric APIs:
/// - Android: `androidx.biometric.BiometricPrompt`
/// - iOS: `LocalAuthentication` (`LAContext`)
///
/// ```dart
/// final authenticator = VeloxBiometricsPlatform();
/// final status = await authenticator.checkAvailability();
/// ```
class VeloxBiometricsPlatform extends VeloxBiometricAuthenticator {
  /// Creates a [VeloxBiometricsPlatform] with an optional [MethodChannel].
  ///
  /// If no channel is provided, the default channel
  /// `'com.velox.biometrics/method'` is used.
  VeloxBiometricsPlatform({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('com.velox.biometrics/method');

  final MethodChannel _channel;

  @override
  Future<VeloxBiometricStatus> checkAvailability() async {
    final result = await _channel.invokeMethod<String>('checkAvailability');
    return _parseStatus(result ?? 'notSupported');
  }

  @override
  Future<List<VeloxBiometricType>> getAvailableBiometrics() async {
    final result =
        await _channel.invokeListMethod<String>('getAvailableBiometrics');
    if (result == null) return <VeloxBiometricType>[];
    return result.map(_parseBiometricType).toList();
  }

  @override
  Future<VeloxBiometricAuthResult> authenticate(
    VeloxBiometricConfig config,
  ) async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'authenticate',
      <String, dynamic>{
        'localizedReason': config.localizedReason,
        'useErrorDialogs': config.useErrorDialogs,
        'stickyAuth': config.stickyAuth,
        'biometricOnly': config.biometricOnly,
      },
    );

    if (result == null) {
      return VeloxBiometricAuthResult(
        status: VeloxAuthResultStatus.error,
        errorMessage: 'No result from platform',
        timestamp: DateTime.now(),
      );
    }

    return _parseAuthResult(result);
  }

  @override
  Future<bool> get isDeviceSupported async {
    final result = await _channel.invokeMethod<bool>('isDeviceSupported');
    return result ?? false;
  }

  @override
  Future<bool> get isEnrolled async {
    final result = await _channel.invokeMethod<bool>('isEnrolled');
    return result ?? false;
  }

  VeloxBiometricStatus _parseStatus(String status) => switch (status) {
    'available' => VeloxBiometricStatus.available,
    'unavailable' => VeloxBiometricStatus.unavailable,
    'notEnrolled' => VeloxBiometricStatus.notEnrolled,
    'lockedOut' => VeloxBiometricStatus.lockedOut,
    'notSupported' => VeloxBiometricStatus.notSupported,
    _ => VeloxBiometricStatus.notSupported,
  };

  VeloxBiometricType _parseBiometricType(String type) => switch (type) {
    'fingerprint' => VeloxBiometricType.fingerprint,
    'face' => VeloxBiometricType.face,
    'iris' => VeloxBiometricType.iris,
    _ => VeloxBiometricType.unknown,
  };

  VeloxAuthResultStatus _parseAuthResultStatus(String status) =>
      switch (status) {
        'success' => VeloxAuthResultStatus.success,
        'failed' => VeloxAuthResultStatus.failed,
        'cancelled' => VeloxAuthResultStatus.cancelled,
        'lockedOut' => VeloxAuthResultStatus.lockedOut,
        'error' => VeloxAuthResultStatus.error,
        _ => VeloxAuthResultStatus.error,
      };

  VeloxBiometricAuthResult _parseAuthResult(Map<String, dynamic> map) {
    final statusStr = map['status'] as String? ?? 'error';
    final biometricTypeStr = map['biometricType'] as String?;
    final errorMessage = map['errorMessage'] as String?;

    return VeloxBiometricAuthResult(
      status: _parseAuthResultStatus(statusStr),
      biometricType:
          biometricTypeStr != null ? _parseBiometricType(biometricTypeStr) : null,
      errorMessage: errorMessage,
      timestamp: DateTime.now(),
    );
  }
}

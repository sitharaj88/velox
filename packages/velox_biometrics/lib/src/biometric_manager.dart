import 'dart:async';

import 'package:velox_biometrics/src/auth_result.dart';
import 'package:velox_biometrics/src/biometric_authenticator.dart';
import 'package:velox_biometrics/src/biometric_config.dart';
import 'package:velox_biometrics/src/biometric_exception.dart';
import 'package:velox_biometrics/src/biometric_type.dart';
import 'package:velox_core/velox_core.dart';

/// A high-level manager for biometric authentication.
///
/// Wraps a [VeloxBiometricAuthenticator] delegate and provides a
/// [Result]-based API for safe error handling. Also tracks the last
/// authentication result and exposes a stream of all auth attempts.
///
/// ```dart
/// final authenticator = MyPlatformAuthenticator();
/// final manager = VeloxBiometricManager(authenticator);
///
/// final result = await manager.authenticateWithResult(
///   const VeloxBiometricConfig(localizedReason: 'Verify identity'),
/// );
///
/// result.when(
///   success: (authResult) => print('Auth: ${authResult.status}'),
///   failure: (error) => print('Error: ${error.message}'),
/// );
///
/// manager.dispose();
/// ```
class VeloxBiometricManager {
  /// Creates a [VeloxBiometricManager] with the given [delegate].
  ///
  /// The [delegate] provides the platform-specific biometric
  /// authentication implementation.
  VeloxBiometricManager(this._delegate);

  final VeloxBiometricAuthenticator _delegate;

  final StreamController<VeloxBiometricAuthResult> _authResultController =
      StreamController<VeloxBiometricAuthResult>.broadcast();

  VeloxBiometricAuthResult? _lastResult;

  /// The most recent authentication result, or `null` if no
  /// authentication has been attempted.
  VeloxBiometricAuthResult? get lastResult => _lastResult;

  /// A broadcast stream of authentication results.
  ///
  /// Emits a [VeloxBiometricAuthResult] each time an authentication
  /// attempt completes (whether successful or not).
  Stream<VeloxBiometricAuthResult> get onAuthResult =>
      _authResultController.stream;

  /// Performs biometric authentication and returns a [Result].
  ///
  /// Wraps the [VeloxBiometricAuthenticator.authenticate] call in a
  /// try/catch, returning a [Success] with the [VeloxBiometricAuthResult]
  /// on success, or a [Failure] with a [VeloxBiometricException] if
  /// an exception occurs.
  ///
  /// The result is also tracked in [lastResult] and emitted on
  /// [onAuthResult].
  Future<Result<VeloxBiometricAuthResult, VeloxBiometricException>>
      authenticateWithResult(VeloxBiometricConfig config) async {
    try {
      final result = await _delegate.authenticate(config);
      _lastResult = result;
      if (!_authResultController.isClosed) {
        _authResultController.add(result);
      }
      return Success(result);
    } on VeloxBiometricException catch (e) {
      return Failure(e);
    } on Exception catch (e) {
      return Failure(
        VeloxBiometricException(
          message: e.toString(),
          cause: e,
        ),
      );
    }
  }

  /// Retrieves available biometrics and returns a [Result].
  ///
  /// Wraps the [VeloxBiometricAuthenticator.getAvailableBiometrics] call
  /// in a try/catch, returning a [Success] with the list of
  /// [VeloxBiometricType] values on success, or a [Failure] with a
  /// [VeloxBiometricException] if an exception occurs.
  Future<Result<List<VeloxBiometricType>, VeloxBiometricException>>
      getAvailableBiometricsResult() async {
    try {
      final biometrics = await _delegate.getAvailableBiometrics();
      return Success(biometrics);
    } on VeloxBiometricException catch (e) {
      return Failure(e);
    } on Exception catch (e) {
      return Failure(
        VeloxBiometricException(
          message: e.toString(),
          cause: e,
        ),
      );
    }
  }

  /// Releases resources held by this manager.
  ///
  /// Closes the [onAuthResult] stream. After calling dispose,
  /// the manager should not be used.
  void dispose() {
    _authResultController.close();
  }
}

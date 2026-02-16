import 'package:flutter_test/flutter_test.dart';
import 'package:velox_biometrics/velox_biometrics.dart';
import 'package:velox_core/velox_core.dart';

/// A fake authenticator for testing [VeloxBiometricManager].
class FakeBiometricAuthenticator extends VeloxBiometricAuthenticator {
  VeloxBiometricStatus availabilityResult = VeloxBiometricStatus.available;
  List<VeloxBiometricType> availableBiometrics = [
    VeloxBiometricType.fingerprint,
  ];
  VeloxBiometricAuthResult? authenticateResult;
  bool deviceSupported = true;
  bool enrolled = true;
  Exception? authenticateException;
  Exception? getAvailableBiometricsException;

  @override
  Future<VeloxBiometricStatus> checkAvailability() async =>
      availabilityResult;

  @override
  Future<List<VeloxBiometricType>> getAvailableBiometrics() async {
    if (getAvailableBiometricsException != null) {
      throw getAvailableBiometricsException!;
    }
    return availableBiometrics;
  }

  @override
  Future<VeloxBiometricAuthResult> authenticate(
    VeloxBiometricConfig config,
  ) async {
    if (authenticateException != null) {
      throw authenticateException!;
    }
    return authenticateResult ??
        VeloxBiometricAuthResult(
          status: VeloxAuthResultStatus.success,
          biometricType: VeloxBiometricType.fingerprint,
          timestamp: DateTime(2024),
        );
  }

  @override
  Future<bool> get isDeviceSupported async => deviceSupported;

  @override
  Future<bool> get isEnrolled async => enrolled;
}

void main() {
  group('VeloxBiometricType', () {
    test('has all expected values', () {
      expect(VeloxBiometricType.values, hasLength(4));
      expect(
        VeloxBiometricType.values,
        containsAll([
          VeloxBiometricType.fingerprint,
          VeloxBiometricType.face,
          VeloxBiometricType.iris,
          VeloxBiometricType.unknown,
        ]),
      );
    });

    test('displayName returns correct values', () {
      expect(VeloxBiometricType.fingerprint.displayName, 'Fingerprint');
      expect(VeloxBiometricType.face.displayName, 'Face Recognition');
      expect(VeloxBiometricType.iris.displayName, 'Iris Scan');
      expect(VeloxBiometricType.unknown.displayName, 'Unknown');
    });

    test('isStrong returns true for fingerprint, face, and iris', () {
      expect(VeloxBiometricType.fingerprint.isStrong, isTrue);
      expect(VeloxBiometricType.face.isStrong, isTrue);
      expect(VeloxBiometricType.iris.isStrong, isTrue);
    });

    test('isStrong returns false for unknown', () {
      expect(VeloxBiometricType.unknown.isStrong, isFalse);
    });
  });

  group('VeloxBiometricStatus', () {
    test('has all expected values', () {
      expect(VeloxBiometricStatus.values, hasLength(5));
      expect(
        VeloxBiometricStatus.values,
        containsAll([
          VeloxBiometricStatus.available,
          VeloxBiometricStatus.unavailable,
          VeloxBiometricStatus.notEnrolled,
          VeloxBiometricStatus.lockedOut,
          VeloxBiometricStatus.notSupported,
        ]),
      );
    });

    test('canAuthenticate is true only for available', () {
      expect(VeloxBiometricStatus.available.canAuthenticate, isTrue);
      expect(VeloxBiometricStatus.unavailable.canAuthenticate, isFalse);
      expect(VeloxBiometricStatus.notEnrolled.canAuthenticate, isFalse);
      expect(VeloxBiometricStatus.lockedOut.canAuthenticate, isFalse);
      expect(VeloxBiometricStatus.notSupported.canAuthenticate, isFalse);
    });

    test('isHardwarePresent is true for all except notSupported', () {
      expect(VeloxBiometricStatus.available.isHardwarePresent, isTrue);
      expect(VeloxBiometricStatus.unavailable.isHardwarePresent, isTrue);
      expect(VeloxBiometricStatus.notEnrolled.isHardwarePresent, isTrue);
      expect(VeloxBiometricStatus.lockedOut.isHardwarePresent, isTrue);
      expect(VeloxBiometricStatus.notSupported.isHardwarePresent, isFalse);
    });
  });

  group('VeloxAuthResultStatus', () {
    test('has all expected values', () {
      expect(VeloxAuthResultStatus.values, hasLength(5));
      expect(
        VeloxAuthResultStatus.values,
        containsAll([
          VeloxAuthResultStatus.success,
          VeloxAuthResultStatus.failed,
          VeloxAuthResultStatus.cancelled,
          VeloxAuthResultStatus.lockedOut,
          VeloxAuthResultStatus.error,
        ]),
      );
    });
  });

  group('VeloxBiometricAuthResult', () {
    final timestamp = DateTime(2024, 6, 15, 10, 30);

    test('construction with required fields', () {
      final result = VeloxBiometricAuthResult(
        status: VeloxAuthResultStatus.success,
        timestamp: timestamp,
      );

      expect(result.status, VeloxAuthResultStatus.success);
      expect(result.timestamp, timestamp);
      expect(result.biometricType, isNull);
      expect(result.errorMessage, isNull);
    });

    test('construction with all fields', () {
      final result = VeloxBiometricAuthResult(
        status: VeloxAuthResultStatus.error,
        timestamp: timestamp,
        biometricType: VeloxBiometricType.fingerprint,
        errorMessage: 'Sensor failed',
      );

      expect(result.status, VeloxAuthResultStatus.error);
      expect(result.biometricType, VeloxBiometricType.fingerprint);
      expect(result.errorMessage, 'Sensor failed');
      expect(result.timestamp, timestamp);
    });

    test('isSuccess returns true only for success status', () {
      final success = VeloxBiometricAuthResult(
        status: VeloxAuthResultStatus.success,
        timestamp: timestamp,
      );
      final failed = VeloxBiometricAuthResult(
        status: VeloxAuthResultStatus.failed,
        timestamp: timestamp,
      );

      expect(success.isSuccess, isTrue);
      expect(failed.isSuccess, isFalse);
    });

    test('isCancelled returns true only for cancelled status', () {
      final cancelled = VeloxBiometricAuthResult(
        status: VeloxAuthResultStatus.cancelled,
        timestamp: timestamp,
      );
      final success = VeloxBiometricAuthResult(
        status: VeloxAuthResultStatus.success,
        timestamp: timestamp,
      );

      expect(cancelled.isCancelled, isTrue);
      expect(success.isCancelled, isFalse);
    });

    test('equality works correctly', () {
      final result1 = VeloxBiometricAuthResult(
        status: VeloxAuthResultStatus.success,
        timestamp: timestamp,
        biometricType: VeloxBiometricType.fingerprint,
      );
      final result2 = VeloxBiometricAuthResult(
        status: VeloxAuthResultStatus.success,
        timestamp: timestamp,
        biometricType: VeloxBiometricType.fingerprint,
      );
      final result3 = VeloxBiometricAuthResult(
        status: VeloxAuthResultStatus.failed,
        timestamp: timestamp,
        biometricType: VeloxBiometricType.fingerprint,
      );

      expect(result1, equals(result2));
      expect(result1, isNot(equals(result3)));
      expect(result1.hashCode, result2.hashCode);
    });

    test('copyWith creates a modified copy', () {
      final original = VeloxBiometricAuthResult(
        status: VeloxAuthResultStatus.success,
        timestamp: timestamp,
        biometricType: VeloxBiometricType.fingerprint,
      );
      final copied = original.copyWith(
        status: VeloxAuthResultStatus.failed,
        errorMessage: 'No match',
      );

      expect(copied.status, VeloxAuthResultStatus.failed);
      expect(copied.errorMessage, 'No match');
      expect(copied.biometricType, VeloxBiometricType.fingerprint);
      expect(copied.timestamp, timestamp);
    });

    test('toString contains relevant information', () {
      final result = VeloxBiometricAuthResult(
        status: VeloxAuthResultStatus.success,
        timestamp: timestamp,
        biometricType: VeloxBiometricType.fingerprint,
      );
      final str = result.toString();

      expect(str, contains('VeloxBiometricAuthResult'));
      expect(str, contains('success'));
      expect(str, contains('fingerprint'));
    });
  });

  group('VeloxBiometricConfig', () {
    test('construction with required fields uses defaults', () {
      const config = VeloxBiometricConfig(
        localizedReason: 'Authenticate',
      );

      expect(config.localizedReason, 'Authenticate');
      expect(config.useErrorDialogs, isTrue);
      expect(config.stickyAuth, isFalse);
      expect(config.biometricOnly, isFalse);
      expect(config.authTimeout, isNull);
      expect(config.allowedTypes, hasLength(4));
    });

    test('construction with all fields', () {
      const config = VeloxBiometricConfig(
        localizedReason: 'Verify',
        useErrorDialogs: false,
        stickyAuth: true,
        biometricOnly: true,
        authTimeout: Duration(seconds: 30),
        allowedTypes: [VeloxBiometricType.fingerprint],
      );

      expect(config.localizedReason, 'Verify');
      expect(config.useErrorDialogs, isFalse);
      expect(config.stickyAuth, isTrue);
      expect(config.biometricOnly, isTrue);
      expect(config.authTimeout, const Duration(seconds: 30));
      expect(config.allowedTypes, [VeloxBiometricType.fingerprint]);
    });

    test('equality works correctly', () {
      const config1 = VeloxBiometricConfig(localizedReason: 'Auth');
      const config2 = VeloxBiometricConfig(localizedReason: 'Auth');
      const config3 = VeloxBiometricConfig(localizedReason: 'Different');

      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
      expect(config1.hashCode, config2.hashCode);
    });

    test('copyWith creates a modified copy', () {
      const original = VeloxBiometricConfig(
        localizedReason: 'Original',
      );
      final copied = original.copyWith(
        localizedReason: 'Modified',
        biometricOnly: true,
      );

      expect(copied.localizedReason, 'Modified');
      expect(copied.biometricOnly, isTrue);
      expect(copied.useErrorDialogs, isTrue);
      expect(copied.stickyAuth, isFalse);
    });

    test('toString contains relevant information', () {
      const config = VeloxBiometricConfig(
        localizedReason: 'Test reason',
      );
      final str = config.toString();

      expect(str, contains('VeloxBiometricConfig'));
      expect(str, contains('Test reason'));
    });
  });

  group('VeloxBiometricException', () {
    test('creation with required fields', () {
      const exception = VeloxBiometricException(
        message: 'Auth failed',
      );

      expect(exception.message, 'Auth failed');
      expect(exception.code, isNull);
      expect(exception.platform, isNull);
      expect(exception.biometricType, isNull);
    });

    test('creation with all fields', () {
      const exception = VeloxBiometricException(
        message: 'Sensor error',
        code: 'SENSOR_ERROR',
        platform: 'android',
        biometricType: VeloxBiometricType.fingerprint,
      );

      expect(exception.message, 'Sensor error');
      expect(exception.code, 'SENSOR_ERROR');
      expect(exception.platform, 'android');
      expect(exception.biometricType, VeloxBiometricType.fingerprint);
    });

    test('extends VeloxPlatformException', () {
      const exception = VeloxBiometricException(message: 'test');
      expect(exception, isA<VeloxPlatformException>());
      expect(exception, isA<VeloxException>());
    });

    test('toString includes biometric type', () {
      const exception = VeloxBiometricException(
        message: 'Failed',
        code: 'ERR',
        platform: 'ios',
        biometricType: VeloxBiometricType.face,
      );
      final str = exception.toString();

      expect(str, contains('VeloxBiometricException'));
      expect(str, contains('ERR'));
      expect(str, contains('ios'));
      expect(str, contains('Failed'));
      expect(str, contains('face'));
    });

    test('toString without optional fields', () {
      const exception = VeloxBiometricException(
        message: 'Basic error',
      );
      final str = exception.toString();

      expect(str, contains('VeloxBiometricException'));
      expect(str, contains('Basic error'));
    });
  });

  group('VeloxBiometricManager', () {
    late FakeBiometricAuthenticator fakeAuthenticator;
    late VeloxBiometricManager manager;

    const config = VeloxBiometricConfig(
      localizedReason: 'Test authentication',
    );

    setUp(() {
      fakeAuthenticator = FakeBiometricAuthenticator();
      manager = VeloxBiometricManager(fakeAuthenticator);
    });

    tearDown(() {
      manager.dispose();
    });

    test('authenticateWithResult returns Success on success', () async {
      final expectedResult = VeloxBiometricAuthResult(
        status: VeloxAuthResultStatus.success,
        biometricType: VeloxBiometricType.fingerprint,
        timestamp: DateTime(2024),
      );
      fakeAuthenticator.authenticateResult = expectedResult;

      final result = await manager.authenticateWithResult(config);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, equals(expectedResult));
    });

    test('authenticateWithResult returns Failure on VeloxBiometricException',
        () async {
      fakeAuthenticator.authenticateException =
          const VeloxBiometricException(
            message: 'Sensor error',
            code: 'SENSOR',
          );

      final result = await manager.authenticateWithResult(config);

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull?.message, 'Sensor error');
      expect(result.errorOrNull?.code, 'SENSOR');
    });

    test('authenticateWithResult wraps generic exceptions', () async {
      fakeAuthenticator.authenticateException =
          Exception('Unexpected error');

      final result = await manager.authenticateWithResult(config);

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<VeloxBiometricException>());
      expect(result.errorOrNull?.message, contains('Unexpected error'));
    });

    test('getAvailableBiometricsResult returns Success', () async {
      fakeAuthenticator.availableBiometrics = [
        VeloxBiometricType.fingerprint,
        VeloxBiometricType.face,
      ];

      final result = await manager.getAvailableBiometricsResult();

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, hasLength(2));
      expect(
        result.valueOrNull,
        containsAll([
          VeloxBiometricType.fingerprint,
          VeloxBiometricType.face,
        ]),
      );
    });

    test('getAvailableBiometricsResult returns Failure on exception',
        () async {
      fakeAuthenticator.getAvailableBiometricsException =
          const VeloxBiometricException(message: 'Hardware error');

      final result = await manager.getAvailableBiometricsResult();

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull?.message, 'Hardware error');
    });

    test('lastResult is null initially', () {
      expect(manager.lastResult, isNull);
    });

    test('lastResult is updated after authenticateWithResult', () async {
      final expectedResult = VeloxBiometricAuthResult(
        status: VeloxAuthResultStatus.success,
        biometricType: VeloxBiometricType.fingerprint,
        timestamp: DateTime(2024),
      );
      fakeAuthenticator.authenticateResult = expectedResult;

      await manager.authenticateWithResult(config);

      expect(manager.lastResult, equals(expectedResult));
    });

    test('lastResult is not updated on failure', () async {
      fakeAuthenticator.authenticateException =
          const VeloxBiometricException(message: 'fail');

      await manager.authenticateWithResult(config);

      expect(manager.lastResult, isNull);
    });

    test('onAuthResult emits results on successful authentication', () async {
      final expectedResult = VeloxBiometricAuthResult(
        status: VeloxAuthResultStatus.success,
        biometricType: VeloxBiometricType.fingerprint,
        timestamp: DateTime(2024),
      );
      fakeAuthenticator.authenticateResult = expectedResult;

      final future = manager.onAuthResult.first;
      await manager.authenticateWithResult(config);
      final emitted = await future;

      expect(emitted, equals(expectedResult));
    });

    test('onAuthResult does not emit on failure', () async {
      fakeAuthenticator.authenticateException =
          const VeloxBiometricException(message: 'fail');

      final emissions = <VeloxBiometricAuthResult>[];
      final sub = manager.onAuthResult.listen(emissions.add);

      await manager.authenticateWithResult(config);

      // Give stream a moment to process
      await Future<void>.delayed(Duration.zero);

      expect(emissions, isEmpty);
      await sub.cancel();
    });

    test('dispose closes the stream', () async {
      manager.dispose();

      // After dispose, the stream should be done
      expect(
        manager.onAuthResult.isEmpty,
        completion(isTrue),
      );
    });
  });
}

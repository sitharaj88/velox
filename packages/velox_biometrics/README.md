# velox_biometrics

Biometric authentication abstractions for Flutter with fingerprint, face recognition, and PIN fallback support through a unified platform interface.

Part of the [Velox](https://github.com/velox-flutter/velox) plugin collection.

## Features

- **Biometric type detection** - Fingerprint, face recognition, iris scan
- **Availability checking** - Device support, enrollment status, lockout detection
- **Result-based API** - Type-safe error handling with `Result<T, E>` from `velox_core`
- **Stream-based tracking** - Monitor authentication attempts via broadcast stream
- **Platform agnostic** - Abstract interface for any platform implementation

## Usage

```dart
import 'package:velox_biometrics/velox_biometrics.dart';

// Create a manager with your platform authenticator
final manager = VeloxBiometricManager(myAuthenticator);

// Authenticate with Result-based API
final result = await manager.authenticateWithResult(
  const VeloxBiometricConfig(
    localizedReason: 'Please authenticate to continue',
    biometricOnly: true,
  ),
);

result.when(
  success: (authResult) {
    if (authResult.isSuccess) {
      print('Authenticated!');
    }
  },
  failure: (error) => print('Error: ${error.message}'),
);

// Clean up
manager.dispose();
```

## Implementing a Platform Authenticator

```dart
class MyPlatformAuthenticator extends VeloxBiometricAuthenticator {
  @override
  Future<VeloxBiometricStatus> checkAvailability() async {
    // Check platform biometric availability
    return VeloxBiometricStatus.available;
  }

  @override
  Future<List<VeloxBiometricType>> getAvailableBiometrics() async {
    return [VeloxBiometricType.fingerprint];
  }

  @override
  Future<VeloxBiometricAuthResult> authenticate(
    VeloxBiometricConfig config,
  ) async {
    // Perform platform authentication
    return VeloxBiometricAuthResult(
      status: VeloxAuthResultStatus.success,
      biometricType: VeloxBiometricType.fingerprint,
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<bool> get isDeviceSupported async => true;

  @override
  Future<bool> get isEnrolled async => true;
}
```

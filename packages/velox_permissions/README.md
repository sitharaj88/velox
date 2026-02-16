# velox_permissions

Cross-platform permission handling for Flutter with a unified API for requesting, checking, and managing app permissions.

Part of the [Velox](https://github.com/velox-flutter/velox) Flutter plugin collection.

## Features

- `VeloxPermissionType` and `VeloxPermissionStatus` enums for type-safe permission handling
- `VeloxPermissionResult` immutable data class for permission check/request results
- `VeloxPermissionHandler` abstract interface for platform-specific implementations
- `VeloxPermissionManager` with in-memory caching and reactive streams

## Usage

```dart
import 'package:velox_permissions/velox_permissions.dart';

// Create a manager with your platform-specific handler
final manager = VeloxPermissionManager(handler: myHandler);

// Listen for permission changes
manager.onPermissionChanged.listen((result) {
  print('${result.permission.displayName}: ${result.status}');
});

// Check a permission (uses cache if available)
final status = await manager.check(VeloxPermissionType.camera);

// Request a permission
final result = await manager.request(VeloxPermissionType.camera);

if (result.status.isGranted) {
  // Permission granted, proceed
} else if (!result.status.canRequest) {
  // Permanently denied or restricted, open settings
  await manager.openSettings();
}

// Clean up when done
manager.dispose();
```

## License

MIT License - see [LICENSE](LICENSE) for details.

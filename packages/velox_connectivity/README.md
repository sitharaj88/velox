# velox_connectivity

Real-time network connectivity monitoring for Dart applications. Part of the
[Velox](https://github.com/velox-flutter/velox) plugin collection.

## Features

- **Connectivity status** detection (`connected`, `disconnected`, `unknown`)
- **Connection type** identification (`wifi`, `mobile`, `ethernet`, `bluetooth`, `vpn`)
- **Reactive streams** for real-time connectivity changes
- **Polling-based monitor** with configurable intervals
- **Platform-agnostic** interface for custom implementations

## Getting Started

Add `velox_connectivity` to your `pubspec.yaml`:

```yaml
dependencies:
  velox_connectivity:
    path: ../velox_connectivity
```

## Usage

### Define a platform-specific checker

```dart
import 'package:velox_connectivity/velox_connectivity.dart';

class MyPlatformChecker implements VeloxConnectivityChecker {
  @override
  Future<VeloxConnectivityInfo> checkConnectivity() async {
    // Your platform-specific connectivity detection logic
    return VeloxConnectivityInfo(
      status: VeloxConnectivityStatus.connected,
      connectionType: VeloxConnectionType.wifi,
      isOnline: true,
      timestamp: DateTime.now(),
    );
  }

  @override
  Stream<VeloxConnectivityInfo> get onConnectivityChanged =>
      Stream.empty();

  @override
  Future<bool> get isConnected async => true;

  @override
  void dispose() {}
}
```

### Use the polling monitor

```dart
final monitor = VeloxConnectivityMonitor(
  platformChecker: MyPlatformChecker(),
  pollInterval: Duration(seconds: 10),
);

monitor.start();

monitor.onConnectivityChanged.listen((info) {
  print('Status: ${info.status}');
  print('Type: ${info.connectionType}');
  print('Online: ${info.isOnline}');
});

// When done:
monitor.dispose();
```

### Check connection type properties

```dart
final type = VeloxConnectionType.mobile;
print(type.isWireless); // true
print(type.isMetered);  // true
```

## License

MIT License. See [LICENSE](LICENSE) for details.

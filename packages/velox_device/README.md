# velox_device

Device information abstractions for Flutter. Part of the [Velox](https://github.com/velox-flutter/velox) plugin collection.

## Features

- **Platform detection** - Identify Android, iOS, Web, macOS, Windows, Linux, and Fuchsia
- **Device type classification** - Phone, tablet, desktop, TV, and watch form factors
- **Screen metrics** - Physical and logical dimensions, pixel ratio, orientation
- **Battery information** - Battery level, charging state, and low power mode
- **Aggregate device info** - Model, manufacturer, OS version, app version
- **Abstract provider interface** - Easy to implement for any platform or mock for testing

## Usage

```dart
import 'package:velox_device/velox_device.dart';

// Check platform properties
const platform = VeloxDevicePlatform.android;
print(platform.isMobile);    // true
print(platform.displayName); // 'Android'

// Work with screen info
const screen = VeloxScreenInfo(
  width: 1080,
  height: 1920,
  pixelRatio: 3.0,
);
print(screen.logicalWidth); // 360.0
print(screen.isPortrait);   // true

// Create battery info
const battery = VeloxBatteryInfo(
  level: 0.85,
  state: VeloxBatteryState.charging,
  isLowPower: false,
);
print(battery.isCharging); // true

// Aggregate device information
const info = VeloxDeviceInfo(
  platform: VeloxDevicePlatform.android,
  deviceType: VeloxDeviceType.phone,
  model: 'Pixel 7',
  manufacturer: 'Google',
  osVersion: '14.0',
  appVersion: '1.2.3',
);
```

## Implementing a Provider

Create a platform-specific implementation by extending `VeloxDeviceInfoProvider`:

```dart
class MyDeviceInfoProvider extends VeloxDeviceInfoProvider {
  @override
  Future<VeloxDeviceInfo> getDeviceInfo() async {
    // Return device information from platform channels
  }

  @override
  Future<VeloxScreenInfo> getScreenInfo() async {
    // Return screen metrics
  }

  @override
  Future<VeloxBatteryInfo> getBatteryInfo() async {
    // Return battery information
  }

  @override
  VeloxDevicePlatform get currentPlatform => VeloxDevicePlatform.android;
}
```

## License

MIT License - see [LICENSE](LICENSE) for details.

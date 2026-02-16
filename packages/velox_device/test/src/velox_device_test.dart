import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:velox_device/velox_device.dart';

void main() {
  group('VeloxDevicePlatform', () {
    test('has all expected enum values', () {
      expect(VeloxDevicePlatform.values, hasLength(8));
      expect(
        VeloxDevicePlatform.values,
        containsAll([
          VeloxDevicePlatform.android,
          VeloxDevicePlatform.ios,
          VeloxDevicePlatform.web,
          VeloxDevicePlatform.macos,
          VeloxDevicePlatform.windows,
          VeloxDevicePlatform.linux,
          VeloxDevicePlatform.fuchsia,
          VeloxDevicePlatform.unknown,
        ]),
      );
    });

    test('isMobile returns true for android and ios', () {
      expect(VeloxDevicePlatform.android.isMobile, isTrue);
      expect(VeloxDevicePlatform.ios.isMobile, isTrue);
      expect(VeloxDevicePlatform.web.isMobile, isFalse);
      expect(VeloxDevicePlatform.macos.isMobile, isFalse);
      expect(VeloxDevicePlatform.windows.isMobile, isFalse);
      expect(VeloxDevicePlatform.linux.isMobile, isFalse);
      expect(VeloxDevicePlatform.fuchsia.isMobile, isFalse);
      expect(VeloxDevicePlatform.unknown.isMobile, isFalse);
    });

    test('isDesktop returns true for macos, windows, and linux', () {
      expect(VeloxDevicePlatform.macos.isDesktop, isTrue);
      expect(VeloxDevicePlatform.windows.isDesktop, isTrue);
      expect(VeloxDevicePlatform.linux.isDesktop, isTrue);
      expect(VeloxDevicePlatform.android.isDesktop, isFalse);
      expect(VeloxDevicePlatform.ios.isDesktop, isFalse);
      expect(VeloxDevicePlatform.web.isDesktop, isFalse);
      expect(VeloxDevicePlatform.fuchsia.isDesktop, isFalse);
      expect(VeloxDevicePlatform.unknown.isDesktop, isFalse);
    });

    test('isWeb returns true only for web', () {
      expect(VeloxDevicePlatform.web.isWeb, isTrue);
      expect(VeloxDevicePlatform.android.isWeb, isFalse);
      expect(VeloxDevicePlatform.ios.isWeb, isFalse);
      expect(VeloxDevicePlatform.macos.isWeb, isFalse);
    });

    test('displayName returns correct human-readable names', () {
      expect(VeloxDevicePlatform.android.displayName, 'Android');
      expect(VeloxDevicePlatform.ios.displayName, 'iOS');
      expect(VeloxDevicePlatform.web.displayName, 'Web');
      expect(VeloxDevicePlatform.macos.displayName, 'macOS');
      expect(VeloxDevicePlatform.windows.displayName, 'Windows');
      expect(VeloxDevicePlatform.linux.displayName, 'Linux');
      expect(VeloxDevicePlatform.fuchsia.displayName, 'Fuchsia');
      expect(VeloxDevicePlatform.unknown.displayName, 'Unknown');
    });
  });

  group('VeloxDeviceType', () {
    test('has all expected enum values', () {
      expect(VeloxDeviceType.values, hasLength(6));
      expect(
        VeloxDeviceType.values,
        containsAll([
          VeloxDeviceType.phone,
          VeloxDeviceType.tablet,
          VeloxDeviceType.desktop,
          VeloxDeviceType.tv,
          VeloxDeviceType.watch,
          VeloxDeviceType.unknown,
        ]),
      );
    });

    test('isHandheld returns true for phone and watch', () {
      expect(VeloxDeviceType.phone.isHandheld, isTrue);
      expect(VeloxDeviceType.watch.isHandheld, isTrue);
      expect(VeloxDeviceType.tablet.isHandheld, isFalse);
      expect(VeloxDeviceType.desktop.isHandheld, isFalse);
      expect(VeloxDeviceType.tv.isHandheld, isFalse);
      expect(VeloxDeviceType.unknown.isHandheld, isFalse);
    });

    test('hasLargeScreen returns true for tablet, desktop, and tv', () {
      expect(VeloxDeviceType.tablet.hasLargeScreen, isTrue);
      expect(VeloxDeviceType.desktop.hasLargeScreen, isTrue);
      expect(VeloxDeviceType.tv.hasLargeScreen, isTrue);
      expect(VeloxDeviceType.phone.hasLargeScreen, isFalse);
      expect(VeloxDeviceType.watch.hasLargeScreen, isFalse);
      expect(VeloxDeviceType.unknown.hasLargeScreen, isFalse);
    });
  });

  group('VeloxScreenInfo', () {
    test('constructs with required parameters', () {
      const screen = VeloxScreenInfo(
        width: 1080,
        height: 1920,
        pixelRatio: 3,
      );
      expect(screen.width, 1080);
      expect(screen.height, 1920);
      expect(screen.pixelRatio, 3);
    });

    test('computes logicalWidth correctly', () {
      const screen = VeloxScreenInfo(
        width: 1080,
        height: 1920,
        pixelRatio: 3,
      );
      expect(screen.logicalWidth, 360.0);
    });

    test('computes logicalHeight correctly', () {
      const screen = VeloxScreenInfo(
        width: 1080,
        height: 1920,
        pixelRatio: 3,
      );
      expect(screen.logicalHeight, 640.0);
    });

    test('computes diagonal correctly', () {
      const screen = VeloxScreenInfo(
        width: 3,
        height: 4,
        pixelRatio: 1,
      );
      expect(screen.diagonal, 5.0);
    });

    test('diagonal uses sqrt of width^2 + height^2', () {
      const screen = VeloxScreenInfo(
        width: 1080,
        height: 1920,
        pixelRatio: 3,
      );
      final expected = math.sqrt(1080 * 1080 + 1920 * 1920);
      expect(screen.diagonal, expected);
    });

    test('isPortrait returns true when height > width', () {
      const screen = VeloxScreenInfo(
        width: 1080,
        height: 1920,
        pixelRatio: 3,
      );
      expect(screen.isPortrait, isTrue);
      expect(screen.isLandscape, isFalse);
    });

    test('isLandscape returns true when width > height', () {
      const screen = VeloxScreenInfo(
        width: 1920,
        height: 1080,
        pixelRatio: 3,
      );
      expect(screen.isLandscape, isTrue);
      expect(screen.isPortrait, isFalse);
    });

    test('square screen is neither portrait nor landscape', () {
      const screen = VeloxScreenInfo(
        width: 1080,
        height: 1080,
        pixelRatio: 2,
      );
      expect(screen.isPortrait, isFalse);
      expect(screen.isLandscape, isFalse);
    });

    test('equality works correctly', () {
      const screen1 = VeloxScreenInfo(
        width: 1080,
        height: 1920,
        pixelRatio: 3,
      );
      const screen2 = VeloxScreenInfo(
        width: 1080,
        height: 1920,
        pixelRatio: 3,
      );
      const screen3 = VeloxScreenInfo(
        width: 720,
        height: 1280,
        pixelRatio: 2,
      );
      expect(screen1, equals(screen2));
      expect(screen1, isNot(equals(screen3)));
      expect(screen1.hashCode, screen2.hashCode);
    });

    test('copyWith creates a new instance with replaced fields', () {
      const screen = VeloxScreenInfo(
        width: 1080,
        height: 1920,
        pixelRatio: 3,
      );
      final copied = screen.copyWith(width: 720);
      expect(copied.width, 720);
      expect(copied.height, 1920);
      expect(copied.pixelRatio, 3);
    });

    test('toString returns expected representation', () {
      const screen = VeloxScreenInfo(
        width: 1080,
        height: 1920,
        pixelRatio: 3,
      );
      expect(
        screen.toString(),
        'VeloxScreenInfo(width: 1080.0, height: 1920.0, pixelRatio: 3.0)',
      );
    });
  });

  group('VeloxBatteryState', () {
    test('has all expected enum values', () {
      expect(VeloxBatteryState.values, hasLength(5));
      expect(
        VeloxBatteryState.values,
        containsAll([
          VeloxBatteryState.charging,
          VeloxBatteryState.discharging,
          VeloxBatteryState.full,
          VeloxBatteryState.notCharging,
          VeloxBatteryState.unknown,
        ]),
      );
    });
  });

  group('VeloxBatteryInfo', () {
    test('constructs with required parameters', () {
      const battery = VeloxBatteryInfo(
        level: 0.85,
        state: VeloxBatteryState.charging,
        isLowPower: false,
      );
      expect(battery.level, 0.85);
      expect(battery.state, VeloxBatteryState.charging);
      expect(battery.isLowPower, isFalse);
    });

    test('isCharging returns true when state is charging', () {
      const battery = VeloxBatteryInfo(
        level: 0.5,
        state: VeloxBatteryState.charging,
        isLowPower: false,
      );
      expect(battery.isCharging, isTrue);
    });

    test('isCharging returns false when state is not charging', () {
      const battery = VeloxBatteryInfo(
        level: 0.5,
        state: VeloxBatteryState.discharging,
        isLowPower: false,
      );
      expect(battery.isCharging, isFalse);
    });

    test('equality works correctly', () {
      const battery1 = VeloxBatteryInfo(
        level: 0.85,
        state: VeloxBatteryState.charging,
        isLowPower: false,
      );
      const battery2 = VeloxBatteryInfo(
        level: 0.85,
        state: VeloxBatteryState.charging,
        isLowPower: false,
      );
      const battery3 = VeloxBatteryInfo(
        level: 0.5,
        state: VeloxBatteryState.discharging,
        isLowPower: true,
      );
      expect(battery1, equals(battery2));
      expect(battery1, isNot(equals(battery3)));
      expect(battery1.hashCode, battery2.hashCode);
    });

    test('copyWith creates a new instance with replaced fields', () {
      const battery = VeloxBatteryInfo(
        level: 0.85,
        state: VeloxBatteryState.charging,
        isLowPower: false,
      );
      final copied = battery.copyWith(
        level: 1,
        state: VeloxBatteryState.full,
      );
      expect(copied.level, 1);
      expect(copied.state, VeloxBatteryState.full);
      expect(copied.isLowPower, isFalse);
    });

    test('toString returns expected representation', () {
      const battery = VeloxBatteryInfo(
        level: 0.85,
        state: VeloxBatteryState.charging,
        isLowPower: false,
      );
      expect(
        battery.toString(),
        'VeloxBatteryInfo(level: 0.85, state: VeloxBatteryState.charging, '
        'isLowPower: false)',
      );
    });
  });

  group('VeloxDeviceInfo', () {
    const screenInfo = VeloxScreenInfo(
      width: 1080,
      height: 1920,
      pixelRatio: 3,
    );
    const batteryInfo = VeloxBatteryInfo(
      level: 0.85,
      state: VeloxBatteryState.charging,
      isLowPower: false,
    );

    test('constructs with required parameters', () {
      const info = VeloxDeviceInfo(
        platform: VeloxDevicePlatform.android,
        deviceType: VeloxDeviceType.phone,
        model: 'Pixel 7',
        manufacturer: 'Google',
        osVersion: '14.0',
        appVersion: '1.2.3',
      );
      expect(info.platform, VeloxDevicePlatform.android);
      expect(info.deviceType, VeloxDeviceType.phone);
      expect(info.model, 'Pixel 7');
      expect(info.manufacturer, 'Google');
      expect(info.osVersion, '14.0');
      expect(info.appVersion, '1.2.3');
      expect(info.screenInfo, isNull);
      expect(info.batteryInfo, isNull);
    });

    test('constructs with optional screen and battery info', () {
      const info = VeloxDeviceInfo(
        platform: VeloxDevicePlatform.android,
        deviceType: VeloxDeviceType.phone,
        model: 'Pixel 7',
        manufacturer: 'Google',
        osVersion: '14.0',
        appVersion: '1.2.3',
        screenInfo: screenInfo,
        batteryInfo: batteryInfo,
      );
      expect(info.screenInfo, screenInfo);
      expect(info.batteryInfo, batteryInfo);
    });

    test('equality works correctly', () {
      const info1 = VeloxDeviceInfo(
        platform: VeloxDevicePlatform.android,
        deviceType: VeloxDeviceType.phone,
        model: 'Pixel 7',
        manufacturer: 'Google',
        osVersion: '14.0',
        appVersion: '1.2.3',
      );
      const info2 = VeloxDeviceInfo(
        platform: VeloxDevicePlatform.android,
        deviceType: VeloxDeviceType.phone,
        model: 'Pixel 7',
        manufacturer: 'Google',
        osVersion: '14.0',
        appVersion: '1.2.3',
      );
      const info3 = VeloxDeviceInfo(
        platform: VeloxDevicePlatform.ios,
        deviceType: VeloxDeviceType.phone,
        model: 'iPhone 15',
        manufacturer: 'Apple',
        osVersion: '17.1',
        appVersion: '1.2.3',
      );
      expect(info1, equals(info2));
      expect(info1, isNot(equals(info3)));
      expect(info1.hashCode, info2.hashCode);
    });

    test('copyWith creates a new instance with replaced fields', () {
      const info = VeloxDeviceInfo(
        platform: VeloxDevicePlatform.android,
        deviceType: VeloxDeviceType.phone,
        model: 'Pixel 7',
        manufacturer: 'Google',
        osVersion: '14.0',
        appVersion: '1.2.3',
      );
      final copied = info.copyWith(
        model: 'Pixel 8',
        osVersion: '15.0',
        screenInfo: screenInfo,
      );
      expect(copied.platform, VeloxDevicePlatform.android);
      expect(copied.model, 'Pixel 8');
      expect(copied.osVersion, '15.0');
      expect(copied.screenInfo, screenInfo);
      expect(copied.manufacturer, 'Google');
    });

    test('toString contains all field information', () {
      const info = VeloxDeviceInfo(
        platform: VeloxDevicePlatform.android,
        deviceType: VeloxDeviceType.phone,
        model: 'Pixel 7',
        manufacturer: 'Google',
        osVersion: '14.0',
        appVersion: '1.2.3',
      );
      final str = info.toString();
      expect(str, contains('VeloxDeviceInfo'));
      expect(str, contains('Pixel 7'));
      expect(str, contains('Google'));
      expect(str, contains('14.0'));
      expect(str, contains('1.2.3'));
    });
  });

  group('VeloxDeviceException', () {
    test('creates with required message', () {
      const exception = VeloxDeviceException(
        message: 'Device info unavailable',
      );
      expect(exception.message, 'Device info unavailable');
      expect(exception.code, isNull);
      expect(exception.platform, isNull);
      expect(exception.cause, isNull);
    });

    test('creates with all optional parameters', () {
      const exception = VeloxDeviceException(
        message: 'Battery info failed',
        code: 'BATTERY_ERROR',
        platform: 'web',
      );
      expect(exception.message, 'Battery info failed');
      expect(exception.code, 'BATTERY_ERROR');
      expect(exception.platform, 'web');
    });

    test('toString includes platform and code when present', () {
      const exception = VeloxDeviceException(
        message: 'Battery info failed',
        code: 'BATTERY_ERROR',
        platform: 'web',
      );
      final str = exception.toString();
      expect(str, contains('VeloxDeviceException'));
      expect(str, contains('[web]'));
      expect(str, contains('(BATTERY_ERROR)'));
      expect(str, contains('Battery info failed'));
    });

    test('toString includes cause when present', () {
      const exception = VeloxDeviceException(
        message: 'Failed',
        cause: 'original error',
      );
      final str = exception.toString();
      expect(str, contains('caused by: original error'));
    });

    test('toString with only message', () {
      const exception = VeloxDeviceException(
        message: 'Something went wrong',
      );
      expect(
        exception.toString(),
        'VeloxDeviceException: Something went wrong',
      );
    });

    test('is a VeloxPlatformException', () {
      const exception = VeloxDeviceException(
        message: 'test',
      );
      expect(exception, isA<VeloxDeviceException>());
      // VeloxDeviceException extends VeloxPlatformException which
      // extends VeloxException which implements Exception
      expect(exception, isA<Exception>());
    });
  });
}

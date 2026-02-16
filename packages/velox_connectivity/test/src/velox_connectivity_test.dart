import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:velox_connectivity/velox_connectivity.dart';
import 'package:velox_core/velox_core.dart';

/// A fake implementation of [VeloxConnectivityChecker] for testing.
class FakeConnectivityChecker implements VeloxConnectivityChecker {
  FakeConnectivityChecker({VeloxConnectivityInfo? initialInfo})
      : _currentInfo = initialInfo ??
            VeloxConnectivityInfo(
              status: VeloxConnectivityStatus.connected,
              connectionType: VeloxConnectionType.wifi,
              isOnline: true,
              timestamp: DateTime(2024),
            );

  VeloxConnectivityInfo _currentInfo;
  final StreamController<VeloxConnectivityInfo> _controller =
      StreamController<VeloxConnectivityInfo>.broadcast();
  bool _disposed = false;
  int checkCount = 0;

  bool get isDisposed => _disposed;

  void emitInfo(VeloxConnectivityInfo info) {
    _currentInfo = info;
    _controller.add(info);
  }

  @override
  Future<VeloxConnectivityInfo> checkConnectivity() async {
    checkCount++;
    return _currentInfo;
  }

  @override
  Stream<VeloxConnectivityInfo> get onConnectivityChanged => _controller.stream;

  @override
  Future<bool> get isConnected async => _currentInfo.isOnline;

  @override
  void dispose() {
    _disposed = true;
    _controller.close();
  }
}

void main() {
  // ── VeloxConnectivityStatus ──────────────────────────────────────────

  group('VeloxConnectivityStatus', () {
    test('has expected values', () {
      expect(VeloxConnectivityStatus.values, hasLength(3));
      expect(
        VeloxConnectivityStatus.values,
        containsAll([
          VeloxConnectivityStatus.connected,
          VeloxConnectivityStatus.disconnected,
          VeloxConnectivityStatus.unknown,
        ]),
      );
    });

    test('connected has correct index', () {
      expect(VeloxConnectivityStatus.connected.index, 0);
    });

    test('disconnected has correct index', () {
      expect(VeloxConnectivityStatus.disconnected.index, 1);
    });

    test('unknown has correct index', () {
      expect(VeloxConnectivityStatus.unknown.index, 2);
    });
  });

  // ── VeloxConnectionType ─────────────────────────────────────────────

  group('VeloxConnectionType', () {
    test('has expected values', () {
      expect(VeloxConnectionType.values, hasLength(7));
      expect(
        VeloxConnectionType.values,
        containsAll([
          VeloxConnectionType.wifi,
          VeloxConnectionType.mobile,
          VeloxConnectionType.ethernet,
          VeloxConnectionType.bluetooth,
          VeloxConnectionType.vpn,
          VeloxConnectionType.none,
          VeloxConnectionType.unknown,
        ]),
      );
    });

    test('isWireless returns true for wifi', () {
      expect(VeloxConnectionType.wifi.isWireless, isTrue);
    });

    test('isWireless returns true for mobile', () {
      expect(VeloxConnectionType.mobile.isWireless, isTrue);
    });

    test('isWireless returns true for bluetooth', () {
      expect(VeloxConnectionType.bluetooth.isWireless, isTrue);
    });

    test('isWireless returns false for ethernet', () {
      expect(VeloxConnectionType.ethernet.isWireless, isFalse);
    });

    test('isWireless returns false for vpn', () {
      expect(VeloxConnectionType.vpn.isWireless, isFalse);
    });

    test('isWireless returns false for none', () {
      expect(VeloxConnectionType.none.isWireless, isFalse);
    });

    test('isWireless returns false for unknown', () {
      expect(VeloxConnectionType.unknown.isWireless, isFalse);
    });

    test('isMetered returns true for mobile', () {
      expect(VeloxConnectionType.mobile.isMetered, isTrue);
    });

    test('isMetered returns true for bluetooth', () {
      expect(VeloxConnectionType.bluetooth.isMetered, isTrue);
    });

    test('isMetered returns false for wifi', () {
      expect(VeloxConnectionType.wifi.isMetered, isFalse);
    });

    test('isMetered returns false for ethernet', () {
      expect(VeloxConnectionType.ethernet.isMetered, isFalse);
    });

    test('isMetered returns false for vpn', () {
      expect(VeloxConnectionType.vpn.isMetered, isFalse);
    });
  });

  // ── VeloxConnectivityInfo ───────────────────────────────────────────

  group('VeloxConnectivityInfo', () {
    final timestamp = DateTime(2024, 1, 15, 10, 30);
    final info = VeloxConnectivityInfo(
      status: VeloxConnectivityStatus.connected,
      connectionType: VeloxConnectionType.wifi,
      isOnline: true,
      timestamp: timestamp,
    );

    test('constructor assigns all fields correctly', () {
      expect(info.status, VeloxConnectivityStatus.connected);
      expect(info.connectionType, VeloxConnectionType.wifi);
      expect(info.isOnline, isTrue);
      expect(info.timestamp, timestamp);
    });

    test('equality with identical values', () {
      final info2 = VeloxConnectivityInfo(
        status: VeloxConnectivityStatus.connected,
        connectionType: VeloxConnectionType.wifi,
        isOnline: true,
        timestamp: timestamp,
      );
      expect(info, equals(info2));
    });

    test('inequality with different status', () {
      final info2 = info.copyWith(status: VeloxConnectivityStatus.disconnected);
      expect(info, isNot(equals(info2)));
    });

    test('inequality with different connectionType', () {
      final info2 = info.copyWith(connectionType: VeloxConnectionType.mobile);
      expect(info, isNot(equals(info2)));
    });

    test('inequality with different isOnline', () {
      final info2 = info.copyWith(isOnline: false);
      expect(info, isNot(equals(info2)));
    });

    test('hashCode is consistent with equality', () {
      final info2 = VeloxConnectivityInfo(
        status: VeloxConnectivityStatus.connected,
        connectionType: VeloxConnectionType.wifi,
        isOnline: true,
        timestamp: timestamp,
      );
      expect(info.hashCode, equals(info2.hashCode));
    });

    test('hashCode differs for different objects', () {
      final info2 = info.copyWith(isOnline: false);
      expect(info.hashCode, isNot(equals(info2.hashCode)));
    });

    test('copyWith preserves unspecified fields', () {
      final copied = info.copyWith(isOnline: false);
      expect(copied.status, info.status);
      expect(copied.connectionType, info.connectionType);
      expect(copied.isOnline, isFalse);
      expect(copied.timestamp, info.timestamp);
    });

    test('copyWith replaces all fields when specified', () {
      final newTimestamp = DateTime(2025);
      final copied = info.copyWith(
        status: VeloxConnectivityStatus.disconnected,
        connectionType: VeloxConnectionType.none,
        isOnline: false,
        timestamp: newTimestamp,
      );
      expect(copied.status, VeloxConnectivityStatus.disconnected);
      expect(copied.connectionType, VeloxConnectionType.none);
      expect(copied.isOnline, isFalse);
      expect(copied.timestamp, newTimestamp);
    });

    test('toString contains all fields', () {
      final str = info.toString();
      expect(str, contains('VeloxConnectivityInfo'));
      expect(str, contains('connected'));
      expect(str, contains('wifi'));
      expect(str, contains('true'));
    });
  });

  // ── VeloxConnectivityMonitor ────────────────────────────────────────

  group('VeloxConnectivityMonitor', () {
    late FakeConnectivityChecker fakeChecker;
    late VeloxConnectivityMonitor monitor;

    setUp(() {
      fakeChecker = FakeConnectivityChecker();
      monitor = VeloxConnectivityMonitor(
        platformChecker: fakeChecker,
        pollInterval: const Duration(milliseconds: 50),
      );
    });

    tearDown(() {
      if (!fakeChecker.isDisposed) {
        monitor.dispose();
      }
    });

    test('checkConnectivity delegates to platformChecker', () async {
      final info = await monitor.checkConnectivity();
      expect(info.status, VeloxConnectivityStatus.connected);
      expect(fakeChecker.checkCount, 1);
    });

    test('isConnected delegates to platformChecker', () async {
      final connected = await monitor.isConnected;
      expect(connected, isTrue);
    });

    test('isMonitoring is false initially', () {
      expect(monitor.isMonitoring, isFalse);
    });

    test('start begins monitoring', () {
      monitor.start();
      expect(monitor.isMonitoring, isTrue);
    });

    test('stop halts monitoring', () {
      monitor
        ..start()
        ..stop();
      expect(monitor.isMonitoring, isFalse);
    });

    test('start is idempotent when already monitoring', () {
      monitor
        ..start()
        ..start(); // should not throw or create duplicate timers
      expect(monitor.isMonitoring, isTrue);
    });

    test('onConnectivityChanged emits initial poll result', () async {
      final future = monitor.onConnectivityChanged.first;
      monitor.start();
      final info = await future;
      expect(info.status, VeloxConnectivityStatus.connected);
    });

    test('onConnectivityChanged emits on status change', () async {
      final emissions = <VeloxConnectivityInfo>[];
      final sub = monitor.onConnectivityChanged.listen(emissions.add);

      monitor.start();

      // Wait for initial poll
      await Future<void>.delayed(const Duration(milliseconds: 30));

      // Change the fake checker's response
      final disconnectedInfo = VeloxConnectivityInfo(
        status: VeloxConnectivityStatus.disconnected,
        connectionType: VeloxConnectionType.none,
        isOnline: false,
        timestamp: DateTime(2024, 2),
      );
      fakeChecker.emitInfo(disconnectedInfo);

      // Wait for next poll
      await Future<void>.delayed(const Duration(milliseconds: 100));

      await sub.cancel();

      expect(emissions.length, greaterThanOrEqualTo(2));
      expect(emissions.first.status, VeloxConnectivityStatus.connected);
      expect(emissions.last.status, VeloxConnectivityStatus.disconnected);
    });

    test('lastInfo is null before any poll', () {
      expect(monitor.lastInfo, isNull);
    });

    test('lastInfo is updated after poll', () async {
      monitor.start();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(monitor.lastInfo, isNotNull);
      expect(monitor.lastInfo!.status, VeloxConnectivityStatus.connected);
    });

    test('dispose cleans up timer and stream controller', () async {
      monitor
        ..start()
        ..dispose();
      expect(monitor.isMonitoring, isFalse);
      expect(fakeChecker.isDisposed, isTrue);
    });

    test('dispose is idempotent', () {
      monitor
        ..dispose()
        ..dispose(); // should not throw
      expect(fakeChecker.isDisposed, isTrue);
    });

    test('start after dispose does nothing', () {
      monitor
        ..dispose()
        ..start();
      expect(monitor.isMonitoring, isFalse);
    });
  });

  // ── VeloxConnectivityException ──────────────────────────────────────

  group('VeloxConnectivityException', () {
    test('creates with required message', () {
      const exception = VeloxConnectivityException(
        message: 'Connection failed',
      );
      expect(exception.message, 'Connection failed');
      expect(exception.code, isNull);
      expect(exception.stackTrace, isNull);
      expect(exception.cause, isNull);
    });

    test('creates with all parameters', () {
      const exception = VeloxConnectivityException(
        message: 'Connection failed',
        code: 'CONN_FAILED',
        cause: 'Original error',
      );
      expect(exception.message, 'Connection failed');
      expect(exception.code, 'CONN_FAILED');
      expect(exception.cause, 'Original error');
    });

    test('toString includes class name and message', () {
      const exception = VeloxConnectivityException(
        message: 'Connection failed',
      );
      expect(
        exception.toString(),
        'VeloxConnectivityException: Connection failed',
      );
    });

    test('toString includes code when present', () {
      const exception = VeloxConnectivityException(
        message: 'Connection failed',
        code: 'CONN_FAILED',
      );
      expect(
        exception.toString(),
        'VeloxConnectivityException[CONN_FAILED]: Connection failed',
      );
    });

    test('toString includes cause when present', () {
      const exception = VeloxConnectivityException(
        message: 'Connection failed',
        cause: 'Timeout',
      );
      expect(
        exception.toString(),
        'VeloxConnectivityException: Connection failed (caused by: Timeout)',
      );
    });

    test('is a VeloxException', () {
      const exception = VeloxConnectivityException(
        message: 'Connection failed',
      );
      expect(exception, isA<VeloxException>());
    });

    test('is an Exception', () {
      const exception = VeloxConnectivityException(
        message: 'Connection failed',
      );
      expect(exception, isA<Exception>());
    });
  });
}

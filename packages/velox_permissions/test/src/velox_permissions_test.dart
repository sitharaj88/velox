import 'package:flutter_test/flutter_test.dart';
import 'package:velox_core/velox_core.dart';
import 'package:velox_permissions/velox_permissions.dart';

/// A fake implementation of [VeloxPermissionHandler] for testing.
class FakePermissionHandler implements VeloxPermissionHandler {
  final Map<VeloxPermissionType, VeloxPermissionStatus> _statuses = {};
  final Map<VeloxPermissionType, bool> _rationales = {};
  bool openSettingsCalled = false;

  void setStatus(VeloxPermissionType type, VeloxPermissionStatus status) {
    _statuses[type] = status;
  }

  void setRationale(VeloxPermissionType type, {required bool shouldShow}) {
    _rationales[type] = shouldShow;
  }

  @override
  Future<VeloxPermissionStatus> check(VeloxPermissionType permission) async =>
      _statuses[permission] ?? VeloxPermissionStatus.unknown;

  @override
  Future<VeloxPermissionResult> request(VeloxPermissionType permission) async {
    final status = _statuses[permission] ?? VeloxPermissionStatus.granted;
    return VeloxPermissionResult(
      permission: permission,
      status: status,
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<List<VeloxPermissionResult>> requestMultiple(
    List<VeloxPermissionType> permissions,
  ) async =>
      [
        for (final permission in permissions)
          VeloxPermissionResult(
            permission: permission,
            status: _statuses[permission] ?? VeloxPermissionStatus.granted,
            timestamp: DateTime.now(),
          ),
      ];

  @override
  Future<bool> shouldShowRationale(VeloxPermissionType permission) async =>
      _rationales[permission] ?? false;

  @override
  Future<void> openSettings() async {
    openSettingsCalled = true;
  }
}

void main() {
  group('VeloxPermissionType', () {
    test('has all expected values', () {
      expect(VeloxPermissionType.values, hasLength(13));
      expect(
        VeloxPermissionType.values,
        containsAll([
          VeloxPermissionType.camera,
          VeloxPermissionType.microphone,
          VeloxPermissionType.location,
          VeloxPermissionType.locationAlways,
          VeloxPermissionType.storage,
          VeloxPermissionType.photos,
          VeloxPermissionType.contacts,
          VeloxPermissionType.calendar,
          VeloxPermissionType.notifications,
          VeloxPermissionType.phone,
          VeloxPermissionType.sms,
          VeloxPermissionType.bluetooth,
          VeloxPermissionType.sensors,
        ]),
      );
    });

    test('displayName returns human-readable name for each type', () {
      expect(VeloxPermissionType.camera.displayName, 'Camera');
      expect(VeloxPermissionType.microphone.displayName, 'Microphone');
      expect(VeloxPermissionType.location.displayName, 'Location');
      expect(VeloxPermissionType.locationAlways.displayName, 'Location Always');
      expect(VeloxPermissionType.storage.displayName, 'Storage');
      expect(VeloxPermissionType.photos.displayName, 'Photos');
      expect(VeloxPermissionType.contacts.displayName, 'Contacts');
      expect(VeloxPermissionType.calendar.displayName, 'Calendar');
      expect(VeloxPermissionType.notifications.displayName, 'Notifications');
      expect(VeloxPermissionType.phone.displayName, 'Phone');
      expect(VeloxPermissionType.sms.displayName, 'SMS');
      expect(VeloxPermissionType.bluetooth.displayName, 'Bluetooth');
      expect(VeloxPermissionType.sensors.displayName, 'Sensors');
    });

    test('displayName returns multi-word name for locationAlways', () {
      expect(
        VeloxPermissionType.locationAlways.displayName,
        'Location Always',
      );
    });
  });

  group('VeloxPermissionStatus', () {
    test('has all expected values', () {
      expect(VeloxPermissionStatus.values, hasLength(6));
      expect(
        VeloxPermissionStatus.values,
        containsAll([
          VeloxPermissionStatus.granted,
          VeloxPermissionStatus.denied,
          VeloxPermissionStatus.permanentlyDenied,
          VeloxPermissionStatus.restricted,
          VeloxPermissionStatus.limited,
          VeloxPermissionStatus.unknown,
        ]),
      );
    });

    test('isGranted returns true for granted', () {
      expect(VeloxPermissionStatus.granted.isGranted, isTrue);
    });

    test('isGranted returns true for limited', () {
      expect(VeloxPermissionStatus.limited.isGranted, isTrue);
    });

    test('isGranted returns false for denied statuses', () {
      expect(VeloxPermissionStatus.denied.isGranted, isFalse);
      expect(VeloxPermissionStatus.permanentlyDenied.isGranted, isFalse);
      expect(VeloxPermissionStatus.restricted.isGranted, isFalse);
      expect(VeloxPermissionStatus.unknown.isGranted, isFalse);
    });

    test('isDenied returns true for denied and permanentlyDenied', () {
      expect(VeloxPermissionStatus.denied.isDenied, isTrue);
      expect(VeloxPermissionStatus.permanentlyDenied.isDenied, isTrue);
    });

    test('isDenied returns false for non-denied statuses', () {
      expect(VeloxPermissionStatus.granted.isDenied, isFalse);
      expect(VeloxPermissionStatus.limited.isDenied, isFalse);
      expect(VeloxPermissionStatus.restricted.isDenied, isFalse);
      expect(VeloxPermissionStatus.unknown.isDenied, isFalse);
    });

    test('canRequest returns true for requestable statuses', () {
      expect(VeloxPermissionStatus.granted.canRequest, isTrue);
      expect(VeloxPermissionStatus.denied.canRequest, isTrue);
      expect(VeloxPermissionStatus.limited.canRequest, isTrue);
      expect(VeloxPermissionStatus.unknown.canRequest, isTrue);
    });

    test('canRequest returns false for permanentlyDenied and restricted', () {
      expect(VeloxPermissionStatus.permanentlyDenied.canRequest, isFalse);
      expect(VeloxPermissionStatus.restricted.canRequest, isFalse);
    });
  });

  group('VeloxPermissionResult', () {
    final timestamp = DateTime(2024, 1, 15, 10, 30);

    test('constructs with required fields', () {
      final result = VeloxPermissionResult(
        permission: VeloxPermissionType.camera,
        status: VeloxPermissionStatus.granted,
        timestamp: timestamp,
      );

      expect(result.permission, VeloxPermissionType.camera);
      expect(result.status, VeloxPermissionStatus.granted);
      expect(result.timestamp, timestamp);
    });

    test('equality works for identical values', () {
      final result1 = VeloxPermissionResult(
        permission: VeloxPermissionType.camera,
        status: VeloxPermissionStatus.granted,
        timestamp: timestamp,
      );
      final result2 = VeloxPermissionResult(
        permission: VeloxPermissionType.camera,
        status: VeloxPermissionStatus.granted,
        timestamp: timestamp,
      );

      expect(result1, equals(result2));
      expect(result1.hashCode, equals(result2.hashCode));
    });

    test('equality fails for different values', () {
      final result1 = VeloxPermissionResult(
        permission: VeloxPermissionType.camera,
        status: VeloxPermissionStatus.granted,
        timestamp: timestamp,
      );
      final result2 = VeloxPermissionResult(
        permission: VeloxPermissionType.microphone,
        status: VeloxPermissionStatus.granted,
        timestamp: timestamp,
      );

      expect(result1, isNot(equals(result2)));
    });

    test('equality fails for different statuses', () {
      final result1 = VeloxPermissionResult(
        permission: VeloxPermissionType.camera,
        status: VeloxPermissionStatus.granted,
        timestamp: timestamp,
      );
      final result2 = VeloxPermissionResult(
        permission: VeloxPermissionType.camera,
        status: VeloxPermissionStatus.denied,
        timestamp: timestamp,
      );

      expect(result1, isNot(equals(result2)));
    });

    test('copyWith replaces individual fields', () {
      final original = VeloxPermissionResult(
        permission: VeloxPermissionType.camera,
        status: VeloxPermissionStatus.denied,
        timestamp: timestamp,
      );

      final updated = original.copyWith(
        status: VeloxPermissionStatus.granted,
      );

      expect(updated.permission, VeloxPermissionType.camera);
      expect(updated.status, VeloxPermissionStatus.granted);
      expect(updated.timestamp, timestamp);
    });

    test('copyWith returns equal result when no fields changed', () {
      final original = VeloxPermissionResult(
        permission: VeloxPermissionType.camera,
        status: VeloxPermissionStatus.granted,
        timestamp: timestamp,
      );

      final copy = original.copyWith();
      expect(copy, equals(original));
    });

    test('toString includes all fields', () {
      final result = VeloxPermissionResult(
        permission: VeloxPermissionType.camera,
        status: VeloxPermissionStatus.granted,
        timestamp: timestamp,
      );

      final string = result.toString();
      expect(string, contains('VeloxPermissionResult'));
      expect(string, contains('camera'));
      expect(string, contains('granted'));
    });
  });

  group('VeloxPermissionManager', () {
    late FakePermissionHandler handler;
    late VeloxPermissionManager manager;

    setUp(() {
      handler = FakePermissionHandler();
      manager = VeloxPermissionManager(handler: handler);
    });

    tearDown(() {
      manager.dispose();
    });

    test('check returns status from handler', () async {
      handler.setStatus(
        VeloxPermissionType.camera,
        VeloxPermissionStatus.granted,
      );

      final status = await manager.check(VeloxPermissionType.camera);
      expect(status, VeloxPermissionStatus.granted);
    });

    test('check returns cached value on second call', () async {
      handler.setStatus(
        VeloxPermissionType.camera,
        VeloxPermissionStatus.granted,
      );

      await manager.check(VeloxPermissionType.camera);

      // Change underlying status
      handler.setStatus(
        VeloxPermissionType.camera,
        VeloxPermissionStatus.denied,
      );

      // Should still return cached granted
      final status = await manager.check(VeloxPermissionType.camera);
      expect(status, VeloxPermissionStatus.granted);
    });

    test('check with forceRefresh bypasses cache', () async {
      handler.setStatus(
        VeloxPermissionType.camera,
        VeloxPermissionStatus.granted,
      );

      await manager.check(VeloxPermissionType.camera);

      // Change underlying status
      handler.setStatus(
        VeloxPermissionType.camera,
        VeloxPermissionStatus.denied,
      );

      // Force refresh should get the new status
      final status = await manager.check(
        VeloxPermissionType.camera,
        forceRefresh: true,
      );
      expect(status, VeloxPermissionStatus.denied);
    });

    test('request delegates to handler and caches result', () async {
      handler.setStatus(
        VeloxPermissionType.camera,
        VeloxPermissionStatus.granted,
      );

      final result = await manager.request(VeloxPermissionType.camera);
      expect(result.permission, VeloxPermissionType.camera);
      expect(result.status, VeloxPermissionStatus.granted);

      // Verify cached
      handler.setStatus(
        VeloxPermissionType.camera,
        VeloxPermissionStatus.denied,
      );
      final cachedStatus = await manager.check(VeloxPermissionType.camera);
      expect(cachedStatus, VeloxPermissionStatus.granted);
    });

    test('requestMultiple delegates and caches all results', () async {
      handler
        ..setStatus(
          VeloxPermissionType.camera,
          VeloxPermissionStatus.granted,
        )
        ..setStatus(
          VeloxPermissionType.microphone,
          VeloxPermissionStatus.denied,
        );

      final results = await manager.requestMultiple([
        VeloxPermissionType.camera,
        VeloxPermissionType.microphone,
      ]);

      expect(results, hasLength(2));
      expect(results[0].permission, VeloxPermissionType.camera);
      expect(results[0].status, VeloxPermissionStatus.granted);
      expect(results[1].permission, VeloxPermissionType.microphone);
      expect(results[1].status, VeloxPermissionStatus.denied);
    });

    test('onPermissionChanged emits on request', () async {
      handler.setStatus(
        VeloxPermissionType.camera,
        VeloxPermissionStatus.granted,
      );

      final future = manager.onPermissionChanged.first;
      await manager.request(VeloxPermissionType.camera);
      final emitted = await future;

      expect(emitted.permission, VeloxPermissionType.camera);
      expect(emitted.status, VeloxPermissionStatus.granted);
    });

    test('onPermissionChanged emits for each requestMultiple result', () async {
      handler
        ..setStatus(
          VeloxPermissionType.camera,
          VeloxPermissionStatus.granted,
        )
        ..setStatus(
          VeloxPermissionType.microphone,
          VeloxPermissionStatus.denied,
        );

      final results = <VeloxPermissionResult>[];
      final subscription = manager.onPermissionChanged.listen(results.add);

      await manager.requestMultiple([
        VeloxPermissionType.camera,
        VeloxPermissionType.microphone,
      ]);

      // Allow stream events to propagate
      await Future<void>.delayed(Duration.zero);

      expect(results, hasLength(2));
      expect(results[0].permission, VeloxPermissionType.camera);
      expect(results[1].permission, VeloxPermissionType.microphone);

      await subscription.cancel();
    });

    test('clearCache invalidates cached results', () async {
      handler.setStatus(
        VeloxPermissionType.camera,
        VeloxPermissionStatus.granted,
      );

      await manager.check(VeloxPermissionType.camera);

      // Change underlying status
      handler.setStatus(
        VeloxPermissionType.camera,
        VeloxPermissionStatus.denied,
      );

      // Clear cache
      manager.clearCache();

      // Should now get fresh status
      final status = await manager.check(VeloxPermissionType.camera);
      expect(status, VeloxPermissionStatus.denied);
    });

    test('shouldShowRationale delegates to handler', () async {
      handler.setRationale(VeloxPermissionType.camera, shouldShow: true);

      final shouldShow = await manager.shouldShowRationale(
        VeloxPermissionType.camera,
      );
      expect(shouldShow, isTrue);
    });

    test('openSettings delegates to handler', () async {
      await manager.openSettings();
      expect(handler.openSettingsCalled, isTrue);
    });

    test('dispose cleans up stream', () async {
      manager.dispose();

      // Stream should be closed after dispose
      expect(
        manager.onPermissionChanged.isEmpty,
        completion(isTrue),
      );
    });
  });

  group('VeloxPermissionException', () {
    test('creates with required message', () {
      const exception = VeloxPermissionException(
        message: 'Permission denied',
      );

      expect(exception.message, 'Permission denied');
      expect(exception.permission, isNull);
      expect(exception.code, isNull);
    });

    test('creates with all fields', () {
      const exception = VeloxPermissionException(
        message: 'Camera access required',
        code: 'CAMERA_REQUIRED',
        permission: VeloxPermissionType.camera,
      );

      expect(exception.message, 'Camera access required');
      expect(exception.code, 'CAMERA_REQUIRED');
      expect(exception.permission, VeloxPermissionType.camera);
    });

    test('toString includes message', () {
      const exception = VeloxPermissionException(
        message: 'Permission failed',
      );

      expect(exception.toString(), contains('VeloxPermissionException'));
      expect(exception.toString(), contains('Permission failed'));
    });

    test('toString includes code when present', () {
      const exception = VeloxPermissionException(
        message: 'Permission failed',
        code: 'ERR_001',
      );

      expect(exception.toString(), contains('[ERR_001]'));
    });

    test('toString includes permission when present', () {
      const exception = VeloxPermissionException(
        message: 'Permission failed',
        permission: VeloxPermissionType.camera,
      );

      expect(exception.toString(), contains('camera'));
    });

    test('toString includes cause when present', () {
      const exception = VeloxPermissionException(
        message: 'Permission failed',
        cause: 'original error',
      );

      expect(exception.toString(), contains('caused by: original error'));
    });

    test('is a VeloxException', () {
      const exception = VeloxPermissionException(
        message: 'test',
      );

      expect(exception, isA<VeloxException>());
    });
  });
}

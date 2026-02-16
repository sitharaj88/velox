import 'dart:async';

import 'package:flutter/services.dart';
import 'package:velox_connectivity/src/connection_type.dart';
import 'package:velox_connectivity/src/connectivity_checker.dart';
import 'package:velox_connectivity/src/connectivity_info.dart';
import 'package:velox_connectivity/src/connectivity_status.dart';

/// Platform implementation of [VeloxConnectivityChecker] using MethodChannel.
class VeloxConnectivityPlatform implements VeloxConnectivityChecker {
  /// Creates a [VeloxConnectivityPlatform].
  VeloxConnectivityPlatform() {
    _eventChannel.receiveBroadcastStream().listen(_onPlatformEvent);
  }

  static const MethodChannel _methodChannel =
      MethodChannel('com.velox.connectivity/method');
  static const EventChannel _eventChannel =
      EventChannel('com.velox.connectivity/event');

  final StreamController<VeloxConnectivityInfo> _controller =
      StreamController<VeloxConnectivityInfo>.broadcast();

  @override
  Future<VeloxConnectivityInfo> checkConnectivity() async {
    final result = await _methodChannel.invokeMapMethod<String, dynamic>(
      'checkConnectivity',
    );
    return _parseResult(result ?? {});
  }

  @override
  Stream<VeloxConnectivityInfo> get onConnectivityChanged => _controller.stream;

  @override
  Future<bool> get isConnected async {
    final info = await checkConnectivity();
    return info.isOnline;
  }

  @override
  void dispose() {
    _controller.close();
  }

  void _onPlatformEvent(dynamic event) {
    if (event is Map) {
      _controller.add(_parseResult(Map<String, dynamic>.from(event)));
    }
  }

  VeloxConnectivityInfo _parseResult(Map<String, dynamic> data) =>
      VeloxConnectivityInfo(
        status: _parseStatus(data['status'] as String? ?? 'unknown'),
        connectionType: _parseType(data['type'] as String? ?? 'unknown'),
        isOnline: data['isOnline'] as bool? ?? false,
        timestamp: DateTime.now(),
      );

  VeloxConnectivityStatus _parseStatus(String status) => switch (status) {
        'connected' => VeloxConnectivityStatus.connected,
        'disconnected' => VeloxConnectivityStatus.disconnected,
        _ => VeloxConnectivityStatus.unknown,
      };

  VeloxConnectionType _parseType(String type) => switch (type) {
        'wifi' => VeloxConnectionType.wifi,
        'mobile' => VeloxConnectionType.mobile,
        'ethernet' => VeloxConnectionType.ethernet,
        'bluetooth' => VeloxConnectionType.bluetooth,
        'vpn' => VeloxConnectionType.vpn,
        'none' => VeloxConnectionType.none,
        _ => VeloxConnectionType.unknown,
      };
}

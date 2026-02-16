import 'package:meta/meta.dart';

import 'package:velox_connectivity/src/connection_type.dart';
import 'package:velox_connectivity/src/connectivity_status.dart';

/// Immutable snapshot of the device's current network connectivity state.
///
/// Contains the [status], [connectionType], whether the device [isOnline],
/// and the [timestamp] at which this information was captured.
///
/// ```dart
/// final info = VeloxConnectivityInfo(
///   status: VeloxConnectivityStatus.connected,
///   connectionType: VeloxConnectionType.wifi,
///   isOnline: true,
///   timestamp: DateTime.now(),
/// );
/// ```
@immutable
class VeloxConnectivityInfo {
  /// Creates a [VeloxConnectivityInfo] instance.
  const VeloxConnectivityInfo({
    required this.status,
    required this.connectionType,
    required this.isOnline,
    required this.timestamp,
  });

  /// The overall connectivity status.
  final VeloxConnectivityStatus status;

  /// The type of network connection.
  final VeloxConnectionType connectionType;

  /// Whether the device currently has internet access.
  final bool isOnline;

  /// The time at which this connectivity information was captured.
  final DateTime timestamp;

  /// Creates a copy of this instance with the given fields replaced.
  ///
  /// Any field not provided will retain its current value.
  VeloxConnectivityInfo copyWith({
    VeloxConnectivityStatus? status,
    VeloxConnectionType? connectionType,
    bool? isOnline,
    DateTime? timestamp,
  }) =>
      VeloxConnectivityInfo(
        status: status ?? this.status,
        connectionType: connectionType ?? this.connectionType,
        isOnline: isOnline ?? this.isOnline,
        timestamp: timestamp ?? this.timestamp,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VeloxConnectivityInfo &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          connectionType == other.connectionType &&
          isOnline == other.isOnline &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(status, connectionType, isOnline, timestamp);

  @override
  String toString() =>
      'VeloxConnectivityInfo(status: $status, connectionType: $connectionType, '
      'isOnline: $isOnline, timestamp: $timestamp)';
}

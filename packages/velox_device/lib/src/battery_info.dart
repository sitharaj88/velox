import 'package:meta/meta.dart';

/// Enum representing the charging state of the device battery.
///
/// ```dart
/// final state = VeloxBatteryState.charging;
/// print(state); // VeloxBatteryState.charging
/// ```
enum VeloxBatteryState {
  /// The battery is currently charging.
  charging,

  /// The battery is currently discharging.
  discharging,

  /// The battery is fully charged.
  full,

  /// The battery is not charging (e.g., connected but not charging).
  notCharging,

  /// The battery state is unknown.
  unknown,
}

/// Immutable data class representing battery information.
///
/// Contains the battery [level] (0.0 to 1.0), the current [state],
/// and whether the device is in [isLowPower] mode.
///
/// ```dart
/// final battery = VeloxBatteryInfo(
///   level: 0.85,
///   state: VeloxBatteryState.charging,
///   isLowPower: false,
/// );
/// print(battery.isCharging); // true
/// ```
@immutable
class VeloxBatteryInfo {
  /// Creates a [VeloxBatteryInfo] with the given battery data.
  ///
  /// - [level] is the battery level from 0.0 (empty) to 1.0 (full).
  /// - [state] is the current charging state of the battery.
  /// - [isLowPower] indicates whether low power mode is enabled.
  const VeloxBatteryInfo({
    required this.level,
    required this.state,
    required this.isLowPower,
  });

  /// The battery level from 0.0 (empty) to 1.0 (full).
  final double level;

  /// The current charging state of the battery.
  final VeloxBatteryState state;

  /// Whether the device is in low power mode.
  final bool isLowPower;

  /// Whether the battery is currently charging.
  bool get isCharging => state == VeloxBatteryState.charging;

  /// Creates a copy of this [VeloxBatteryInfo] with the given fields replaced.
  VeloxBatteryInfo copyWith({
    double? level,
    VeloxBatteryState? state,
    bool? isLowPower,
  }) =>
      VeloxBatteryInfo(
        level: level ?? this.level,
        state: state ?? this.state,
        isLowPower: isLowPower ?? this.isLowPower,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VeloxBatteryInfo &&
          runtimeType == other.runtimeType &&
          level == other.level &&
          state == other.state &&
          isLowPower == other.isLowPower;

  @override
  int get hashCode => Object.hash(level, state, isLowPower);

  @override
  String toString() =>
      'VeloxBatteryInfo(level: $level, state: $state, isLowPower: $isLowPower)';
}

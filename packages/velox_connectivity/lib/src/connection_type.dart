/// Represents the type of network connection the device is using.
///
/// Provides convenience getters [isWireless] and [isMetered] to
/// help consumers make decisions about data usage and behavior.
///
/// ```dart
/// final type = VeloxConnectionType.wifi;
/// print(type.isWireless); // true
/// print(type.isMetered);  // false
/// ```
enum VeloxConnectionType {
  /// Connected via Wi-Fi.
  wifi,

  /// Connected via mobile/cellular data.
  mobile,

  /// Connected via Ethernet cable.
  ethernet,

  /// Connected via Bluetooth tethering.
  bluetooth,

  /// Connected via a VPN tunnel.
  vpn,

  /// No active connection.
  none,

  /// The connection type could not be determined.
  unknown;

  /// Whether this connection type is wireless.
  ///
  /// Returns `true` for [wifi], [mobile], and [bluetooth].
  bool get isWireless => switch (this) {
        wifi || mobile || bluetooth => true,
        _ => false,
      };

  /// Whether this connection type is typically metered.
  ///
  /// Returns `true` for [mobile] and [bluetooth], which are
  /// commonly subject to data caps or usage limits.
  bool get isMetered => switch (this) {
        mobile || bluetooth => true,
        _ => false,
      };
}

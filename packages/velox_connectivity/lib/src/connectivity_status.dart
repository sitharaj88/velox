/// Represents the overall connectivity status of the device.
///
/// Used by [VeloxConnectivityInfo] to indicate whether the device
/// has network access.
///
/// ```dart
/// final status = VeloxConnectivityStatus.connected;
/// print(status); // VeloxConnectivityStatus.connected
/// ```
enum VeloxConnectivityStatus {
  /// The device is connected to a network.
  connected,

  /// The device is not connected to any network.
  disconnected,

  /// The connectivity status could not be determined.
  unknown,
}

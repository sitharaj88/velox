import 'package:velox_connectivity/src/connectivity_info.dart';

/// Abstract interface for checking network connectivity.
///
/// Platform-specific implementations should extend this class to provide
/// actual connectivity detection. Use [VeloxConnectivityMonitor] to wrap
/// a platform checker with polling and stream support.
///
/// ```dart
/// class MyPlatformChecker extends VeloxConnectivityChecker {
///   @override
///   Future<VeloxConnectivityInfo> checkConnectivity() async {
///     // Platform-specific implementation
///   }
///
///   @override
///   Stream<VeloxConnectivityInfo> get onConnectivityChanged =>
///       // Platform-specific stream
///
///   @override
///   Future<bool> get isConnected async => // Platform-specific check
///
///   @override
///   void dispose() {
///     // Clean up resources
///   }
/// }
/// ```
abstract class VeloxConnectivityChecker {
  /// Checks the current connectivity status.
  ///
  /// Returns a [VeloxConnectivityInfo] snapshot of the current
  /// network state.
  Future<VeloxConnectivityInfo> checkConnectivity();

  /// A broadcast stream that emits [VeloxConnectivityInfo] whenever
  /// the connectivity state changes.
  Stream<VeloxConnectivityInfo> get onConnectivityChanged;

  /// Whether the device is currently connected to a network.
  Future<bool> get isConnected;

  /// Releases all resources held by this checker.
  ///
  /// After calling dispose, this instance should not be used again.
  void dispose();
}

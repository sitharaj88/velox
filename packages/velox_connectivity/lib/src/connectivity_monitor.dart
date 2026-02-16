import 'dart:async';

import 'package:velox_connectivity/src/connectivity_checker.dart';
import 'package:velox_connectivity/src/connectivity_info.dart';

/// A polling-based connectivity monitor that wraps a platform-specific
/// [VeloxConnectivityChecker].
///
/// Periodically polls the delegate [platformChecker] and emits
/// connectivity changes through [onConnectivityChanged]. Caches the
/// last known status for immediate access.
///
/// ```dart
/// final monitor = VeloxConnectivityMonitor(
///   platformChecker: myPlatformChecker,
///   pollInterval: Duration(seconds: 10),
/// );
///
/// monitor.start();
///
/// monitor.onConnectivityChanged.listen((info) {
///   print('Connectivity changed: ${info.status}');
/// });
///
/// // Later:
/// monitor.dispose();
/// ```
class VeloxConnectivityMonitor implements VeloxConnectivityChecker {
  /// Creates a [VeloxConnectivityMonitor].
  ///
  /// The [platformChecker] provides the actual connectivity detection.
  /// The [pollInterval] controls how frequently the monitor checks
  /// for changes (defaults to 5 seconds).
  VeloxConnectivityMonitor({
    required this.platformChecker,
    this.pollInterval = const Duration(seconds: 5),
  });

  /// The underlying platform-specific connectivity checker.
  final VeloxConnectivityChecker platformChecker;

  /// The interval between connectivity polls.
  final Duration pollInterval;

  final StreamController<VeloxConnectivityInfo> _controller =
      StreamController<VeloxConnectivityInfo>.broadcast();

  Timer? _timer;
  VeloxConnectivityInfo? _lastInfo;
  bool _disposed = false;

  /// The last known connectivity information, or `null` if no
  /// check has been performed yet.
  VeloxConnectivityInfo? get lastInfo => _lastInfo;

  /// Whether the monitor is currently polling for changes.
  bool get isMonitoring => _timer != null && _timer!.isActive;

  /// Starts periodic polling for connectivity changes.
  ///
  /// If already monitoring, this method does nothing. Each poll
  /// checks the current connectivity and emits on the stream if
  /// the status has changed since the last poll.
  void start() {
    if (_disposed || isMonitoring) return;

    _timer = Timer.periodic(pollInterval, (_) async {
      await _poll();
    });

    // Perform an initial poll immediately.
    unawaited(_poll());
  }

  /// Stops periodic polling without disposing the monitor.
  ///
  /// The monitor can be restarted by calling [start] again.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _poll() async {
    if (_disposed) return;

    final info = await platformChecker.checkConnectivity();

    if (_disposed) return;

    if (_lastInfo != info) {
      _lastInfo = info;
      if (!_controller.isClosed) {
        _controller.add(info);
      }
    }
  }

  @override
  Future<VeloxConnectivityInfo> checkConnectivity() =>
      platformChecker.checkConnectivity();

  @override
  Stream<VeloxConnectivityInfo> get onConnectivityChanged => _controller.stream;

  @override
  Future<bool> get isConnected => platformChecker.isConnected;

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    stop();
    _controller.close();
    platformChecker.dispose();
  }
}

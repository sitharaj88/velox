/// Real-time network connectivity monitoring.
///
/// Provides:
/// - [VeloxConnectivityStatus] and [VeloxConnectionType] enums
/// - [VeloxConnectivityInfo] immutable status data
/// - [VeloxConnectivityChecker] abstract interface
/// - [VeloxConnectivityMonitor] polling-based implementation
/// - [VeloxConnectivityPlatform] native platform implementation
library;

export 'src/connection_type.dart';
export 'src/connectivity_checker.dart';
export 'src/connectivity_exception.dart';
export 'src/connectivity_info.dart';
export 'src/connectivity_monitor.dart';
export 'src/connectivity_status.dart';
export 'src/velox_connectivity_platform.dart';

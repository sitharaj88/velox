import 'package:velox_core/velox_core.dart';

/// Exception thrown when a device information operation fails.
///
/// Extends [VeloxPlatformException] to include platform-specific context
/// for device-related errors.
///
/// ```dart
/// throw VeloxDeviceException(
///   message: 'Failed to retrieve battery info',
///   code: 'BATTERY_UNAVAILABLE',
///   platform: 'web',
/// );
/// ```
class VeloxDeviceException extends VeloxPlatformException {
  /// Creates a [VeloxDeviceException].
  ///
  /// - [message] is a human-readable description of the error.
  /// - [code] is an optional machine-readable error code.
  /// - [stackTrace] is an optional stack trace for debugging.
  /// - [cause] is an optional original exception that caused this one.
  /// - [platform] is an optional platform identifier where the error occurred.
  const VeloxDeviceException({
    required super.message,
    super.code,
    super.stackTrace,
    super.cause,
    super.platform,
  });

  @override
  String toString() {
    final buffer = StringBuffer('VeloxDeviceException');
    if (platform != null) {
      buffer.write('[$platform]');
    }
    if (code != null) {
      buffer.write('($code)');
    }
    buffer.write(': $message');
    if (cause != null) {
      buffer.write(' (caused by: $cause)');
    }
    return buffer.toString();
  }
}

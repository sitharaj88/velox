import 'package:velox_core/velox_core.dart';

/// Exception thrown when a connectivity operation fails.
///
/// Extends [VeloxException] to fit within the Velox exception hierarchy.
///
/// ```dart
/// throw VeloxConnectivityException(
///   message: 'Failed to check connectivity',
///   code: 'CONNECTIVITY_CHECK_FAILED',
/// );
/// ```
class VeloxConnectivityException extends VeloxException {
  /// Creates a [VeloxConnectivityException].
  const VeloxConnectivityException({
    required super.message,
    super.code,
    super.stackTrace,
    super.cause,
  });

  @override
  String toString() {
    final buffer = StringBuffer('VeloxConnectivityException');
    if (code != null) {
      buffer.write('[$code]');
    }
    buffer.write(': $message');
    if (cause != null) {
      buffer.write(' (caused by: $cause)');
    }
    return buffer.toString();
  }
}

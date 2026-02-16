import 'package:velox_core/velox_core.dart';

/// Exception type for authentication-related errors.
///
/// Extends [VeloxException] with an optional [statusCode] for HTTP errors
/// encountered during authentication flows.
///
/// ```dart
/// throw VeloxAuthException(
///   message: 'Token refresh failed',
///   code: 'REFRESH_FAILED',
///   statusCode: 401,
/// );
/// ```
class VeloxAuthException extends VeloxException {
  /// Creates a [VeloxAuthException].
  const VeloxAuthException({
    required super.message,
    super.code,
    super.stackTrace,
    super.cause,
    this.statusCode,
  });

  /// HTTP status code associated with this auth error, if applicable.
  final int? statusCode;

  @override
  String toString() {
    final buffer = StringBuffer('VeloxAuthException');
    if (code != null) {
      buffer.write('[$code]');
    }
    if (statusCode != null) {
      buffer.write('($statusCode)');
    }
    buffer.write(': $message');
    if (cause != null) {
      buffer.write(' (caused by: $cause)');
    }
    return buffer.toString();
  }
}

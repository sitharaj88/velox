/// Base exception for all Velox packages.
///
/// Provides a structured exception hierarchy with:
/// - A human-readable [message]
/// - An optional [code] for programmatic handling
/// - An optional [stackTrace] for debugging
/// - An optional [cause] for exception chaining
///
/// ```dart
/// throw VeloxException(
///   message: 'Failed to fetch user',
///   code: 'USER_NOT_FOUND',
///   cause: originalException,
/// );
/// ```
class VeloxException implements Exception {
  /// Creates a [VeloxException].
  const VeloxException({
    required this.message,
    this.code,
    this.stackTrace,
    this.cause,
  });

  /// Human-readable error message.
  final String message;

  /// Machine-readable error code for programmatic handling.
  final String? code;

  /// Stack trace from where the exception originated.
  final StackTrace? stackTrace;

  /// The original exception that caused this one.
  final Object? cause;

  @override
  String toString() {
    final buffer = StringBuffer('VeloxException');
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

/// Exception for network-related errors.
class VeloxNetworkException extends VeloxException {
  /// Creates a [VeloxNetworkException].
  const VeloxNetworkException({
    required super.message,
    super.code,
    super.stackTrace,
    super.cause,
    this.statusCode,
    this.url,
  });

  /// HTTP status code, if available.
  final int? statusCode;

  /// The URL that was being accessed.
  final String? url;

  @override
  String toString() {
    final buffer = StringBuffer('VeloxNetworkException');
    if (code != null) {
      buffer.write('[$code]');
    }
    if (statusCode != null) {
      buffer.write('($statusCode)');
    }
    buffer.write(': $message');
    if (url != null) {
      buffer.write(' [url: $url]');
    }
    return buffer.toString();
  }
}

/// Exception for storage-related errors.
class VeloxStorageException extends VeloxException {
  /// Creates a [VeloxStorageException].
  const VeloxStorageException({
    required super.message,
    super.code,
    super.stackTrace,
    super.cause,
    this.key,
  });

  /// The storage key that caused the error.
  final String? key;

  @override
  String toString() {
    final buffer = StringBuffer('VeloxStorageException');
    if (code != null) {
      buffer.write('[$code]');
    }
    buffer.write(': $message');
    if (key != null) {
      buffer.write(' [key: $key]');
    }
    return buffer.toString();
  }
}

/// Exception for validation errors.
class VeloxValidationException extends VeloxException {
  /// Creates a [VeloxValidationException].
  const VeloxValidationException({
    required super.message,
    super.code,
    super.stackTrace,
    super.cause,
    this.field,
    this.violations = const [],
  });

  /// The field that failed validation.
  final String? field;

  /// List of validation violations.
  final List<String> violations;

  @override
  String toString() {
    final buffer = StringBuffer('VeloxValidationException');
    if (field != null) {
      buffer.write('[$field]');
    }
    buffer.write(': $message');
    if (violations.isNotEmpty) {
      buffer.write(' (violations: ${violations.join(', ')})');
    }
    return buffer.toString();
  }
}

/// Exception for platform-specific errors.
class VeloxPlatformException extends VeloxException {
  /// Creates a [VeloxPlatformException].
  const VeloxPlatformException({
    required super.message,
    super.code,
    super.stackTrace,
    super.cause,
    this.platform,
  });

  /// The platform where the error occurred.
  final String? platform;

  @override
  String toString() {
    final buffer = StringBuffer('VeloxPlatformException');
    if (platform != null) {
      buffer.write('[$platform]');
    }
    buffer.write(': $message');
    return buffer.toString();
  }
}

/// Exception for timeout errors.
class VeloxTimeoutException extends VeloxException {
  /// Creates a [VeloxTimeoutException].
  const VeloxTimeoutException({
    required super.message,
    super.code,
    super.stackTrace,
    super.cause,
    this.duration,
  });

  /// The duration after which the timeout occurred.
  final Duration? duration;

  @override
  String toString() {
    final buffer = StringBuffer('VeloxTimeoutException: $message');
    if (duration != null) {
      buffer.write(' (after ${duration!.inMilliseconds}ms)');
    }
    return buffer.toString();
  }
}

import 'package:velox_logger/velox_logger.dart';
import 'package:velox_network/src/interceptors/velox_interceptor.dart';
import 'package:velox_network/src/models/velox_request.dart';
import 'package:velox_network/src/models/velox_response.dart';

/// An interceptor that logs detailed request and response information
/// using [VeloxLogger].
///
/// Logs request method, URL, headers, and body at debug level.
/// Logs response status code, headers, and body at debug level.
/// Logs errors at error level.
///
/// ```dart
/// final client = VeloxHttpClient(
///   config: VeloxNetworkConfig(
///     baseUrl: 'https://api.example.com',
///     interceptors: [
///       VeloxLoggingInterceptor(
///         logger: VeloxLogger(tag: 'HTTP'),
///         logRequestHeaders: true,
///         logResponseBody: true,
///       ),
///     ],
///   ),
/// );
/// ```
class VeloxLoggingInterceptor extends VeloxInterceptor {
  /// Creates a [VeloxLoggingInterceptor].
  ///
  /// [logger] is the logger instance to use for output.
  /// [logRequestHeaders] controls whether request headers are logged.
  /// [logRequestBody] controls whether request bodies are logged.
  /// [logResponseHeaders] controls whether response headers are logged.
  /// [logResponseBody] controls whether response bodies are logged.
  VeloxLoggingInterceptor({
    required this.logger,
    this.logRequestBody = false,
    this.logRequestHeaders = false,
    this.logResponseBody = false,
    this.logResponseHeaders = false,
  });

  /// The logger used for output.
  final VeloxLogger logger;

  /// Whether to log request headers.
  final bool logRequestHeaders;

  /// Whether to log request bodies.
  final bool logRequestBody;

  /// Whether to log response headers.
  final bool logResponseHeaders;

  /// Whether to log response bodies.
  final bool logResponseBody;

  @override
  Future<VeloxRequest> onRequest(VeloxRequest request) async {
    final buffer = StringBuffer()
      ..write('-> ${request.method.name.toUpperCase()} ${request.path}');

    if (logRequestHeaders && request.headers.isNotEmpty) {
      buffer.writeln();
      for (final entry in request.headers.entries) {
        buffer.writeln('   ${entry.key}: ${entry.value}');
      }
    }

    if (logRequestBody && request.body != null) {
      buffer
        ..writeln()
        ..writeln('   Body: ${request.body}');
    }

    logger.debug(buffer.toString());
    return request;
  }

  @override
  Future<VeloxResponse<dynamic>> onResponse(
    VeloxResponse<dynamic> response,
  ) async {
    final buffer = StringBuffer()
      ..write(
        '<- ${response.statusCode} '
        '${response.statusMessage ?? ''} '
        '${response.request.path}',
      );

    if (logResponseHeaders && response.headers.isNotEmpty) {
      buffer.writeln();
      for (final entry in response.headers.entries) {
        buffer.writeln('   ${entry.key}: ${entry.value}');
      }
    }

    if (logResponseBody && response.data != null) {
      buffer
        ..writeln()
        ..writeln('   Body: ${response.data}');
    }

    if (response.isSuccess) {
      logger.debug(buffer.toString());
    } else {
      logger.warning(buffer.toString());
    }

    return response;
  }

  @override
  Future<Object> onError(Object error, VeloxRequest request) async {
    logger.error(
      '!! ${request.method.name.toUpperCase()} ${request.path}: $error',
    );
    return error;
  }
}

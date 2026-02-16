import 'package:velox_network/src/models/velox_request.dart';
import 'package:velox_network/src/models/velox_response.dart';

/// Interface for intercepting HTTP requests and responses.
///
/// Interceptors can modify requests before they are sent and
/// responses before they are returned to the caller.
///
/// ```dart
/// class AuthInterceptor extends VeloxInterceptor {
///   @override
///   Future<VeloxRequest> onRequest(VeloxRequest request) async {
///     return request.copyWith(
///       headers: {...request.headers, 'Authorization': 'Bearer $token'},
///     );
///   }
/// }
/// ```
abstract class VeloxInterceptor {
  /// Called before a request is sent. Can modify the request.
  Future<VeloxRequest> onRequest(VeloxRequest request) async => request;

  /// Called after a response is received. Can modify the response.
  Future<VeloxResponse<dynamic>> onResponse(
    VeloxResponse<dynamic> response,
  ) async => response;

  /// Called when an error occurs. Can handle or transform the error.
  Future<Object> onError(Object error, VeloxRequest request) async => error;
}

/// An interceptor that logs request and response details.
class LoggingInterceptor extends VeloxInterceptor {
  /// Creates a [LoggingInterceptor].
  ///
  /// [onLog] receives the log message. Defaults to no-op.
  LoggingInterceptor({void Function(String message)? onLog})
      : _onLog = onLog ?? _defaultLog;

  final void Function(String message) _onLog;

  static void _defaultLog(String message) {
    // No-op by default - users should provide their own logger
  }

  @override
  Future<VeloxRequest> onRequest(VeloxRequest request) async {
    _onLog('-> ${request.method.name.toUpperCase()} ${request.path}');
    return request;
  }

  @override
  Future<VeloxResponse<dynamic>> onResponse(
    VeloxResponse<dynamic> response,
  ) async {
    _onLog(
      '<- ${response.statusCode} ${response.request.path}',
    );
    return response;
  }

  @override
  Future<Object> onError(Object error, VeloxRequest request) async {
    _onLog('!! Error on ${request.path}: $error');
    return error;
  }
}

/// An interceptor that adds default headers to every request.
class HeadersInterceptor extends VeloxInterceptor {
  /// Creates a [HeadersInterceptor] with the given [headers].
  HeadersInterceptor(this.headers);

  /// Headers to add to every request.
  final Map<String, String> headers;

  @override
  Future<VeloxRequest> onRequest(VeloxRequest request) async =>
      request.copyWith(
        headers: {...headers, ...request.headers},
      );
}

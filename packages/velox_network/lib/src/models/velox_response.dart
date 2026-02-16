import 'package:velox_network/src/models/velox_request.dart';

/// Represents an HTTP response.
class VeloxResponse<T> {
  /// Creates a [VeloxResponse].
  VeloxResponse({
    required this.statusCode,
    required this.request,
    this.data,
    this.headers = const {},
    this.statusMessage,
  });

  /// The HTTP status code.
  final int statusCode;

  /// The original request.
  final VeloxRequest request;

  /// The response data.
  final T? data;

  /// Response headers.
  final Map<String, String> headers;

  /// The status message (e.g., "OK", "Not Found").
  final String? statusMessage;

  /// Returns `true` if the status code indicates success (2xx).
  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  /// Returns `true` if the status code indicates a client error (4xx).
  bool get isClientError => statusCode >= 400 && statusCode < 500;

  /// Returns `true` if the status code indicates a server error (5xx).
  bool get isServerError => statusCode >= 500 && statusCode < 600;

  /// Returns `true` if the request should be retried (5xx or timeout).
  bool get isRetryable => isServerError || statusCode == 408 || statusCode == 429;

  @override
  String toString() =>
      'VeloxResponse($statusCode ${statusMessage ?? ''} for ${request.path})';
}

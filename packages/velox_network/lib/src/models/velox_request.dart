/// HTTP methods supported by [VeloxHttpClient].
enum HttpMethod {
  /// HTTP GET method.
  get,

  /// HTTP POST method.
  post,

  /// HTTP PUT method.
  put,

  /// HTTP PATCH method.
  patch,

  /// HTTP DELETE method.
  delete,

  /// HTTP HEAD method.
  head,
}

/// Represents an HTTP request.
class VeloxRequest {
  /// Creates a [VeloxRequest].
  VeloxRequest({
    required this.method,
    required this.path,
    this.queryParameters = const {},
    this.headers = const {},
    this.body,
    this.extra = const {},
  });

  /// The HTTP method.
  final HttpMethod method;

  /// The request path (appended to base URL).
  final String path;

  /// Query parameters.
  final Map<String, String> queryParameters;

  /// Request headers (merged with default headers).
  final Map<String, String> headers;

  /// Request body (for POST, PUT, PATCH).
  final Object? body;

  /// Extra data for interceptors to use.
  final Map<String, Object?> extra;

  /// The full URL after combining base URL and path.
  String fullUrl(String baseUrl) {
    final base = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    final path = this.path.startsWith('/') ? this.path.substring(1) : this.path;
    final uri = Uri.parse('$base$path').replace(
      queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
    );
    return uri.toString();
  }

  /// Creates a copy with the given fields replaced.
  VeloxRequest copyWith({
    HttpMethod? method,
    String? path,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    Object? body,
    Map<String, Object?>? extra,
  }) => VeloxRequest(
    method: method ?? this.method,
    path: path ?? this.path,
    queryParameters: queryParameters ?? this.queryParameters,
    headers: headers ?? this.headers,
    body: body ?? this.body,
    extra: extra ?? this.extra,
  );

  @override
  String toString() =>
      'VeloxRequest(${method.name.toUpperCase()} $path)';
}

import 'package:velox_network/src/interceptors/velox_interceptor.dart';

/// Configuration for [VeloxHttpClient].
class VeloxNetworkConfig {
  /// Creates a [VeloxNetworkConfig].
  const VeloxNetworkConfig({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 30),
    this.receiveTimeout = const Duration(seconds: 30),
    this.sendTimeout = const Duration(seconds: 30),
    this.headers = const {},
    this.interceptors = const [],
    this.maxRetries = 0,
    this.retryDelay = const Duration(seconds: 1),
    this.followRedirects = true,
    this.maxRedirects = 5,
  });

  /// The base URL for all requests.
  final String baseUrl;

  /// Timeout for establishing a connection.
  final Duration connectTimeout;

  /// Timeout for receiving a response.
  final Duration receiveTimeout;

  /// Timeout for sending a request.
  final Duration sendTimeout;

  /// Default headers added to all requests.
  final Map<String, String> headers;

  /// Interceptors applied to all requests.
  final List<VeloxInterceptor> interceptors;

  /// Maximum number of retry attempts for failed requests.
  final int maxRetries;

  /// Delay between retry attempts.
  final Duration retryDelay;

  /// Whether to follow redirects.
  final bool followRedirects;

  /// Maximum number of redirects to follow.
  final int maxRedirects;

  /// Creates a copy with the given fields replaced.
  VeloxNetworkConfig copyWith({
    String? baseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    Map<String, String>? headers,
    List<VeloxInterceptor>? interceptors,
    int? maxRetries,
    Duration? retryDelay,
    bool? followRedirects,
    int? maxRedirects,
  }) => VeloxNetworkConfig(
    baseUrl: baseUrl ?? this.baseUrl,
    connectTimeout: connectTimeout ?? this.connectTimeout,
    receiveTimeout: receiveTimeout ?? this.receiveTimeout,
    sendTimeout: sendTimeout ?? this.sendTimeout,
    headers: headers ?? this.headers,
    interceptors: interceptors ?? this.interceptors,
    maxRetries: maxRetries ?? this.maxRetries,
    retryDelay: retryDelay ?? this.retryDelay,
    followRedirects: followRedirects ?? this.followRedirects,
    maxRedirects: maxRedirects ?? this.maxRedirects,
  );
}

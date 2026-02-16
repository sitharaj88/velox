import 'package:velox_logger/velox_logger.dart';
import 'package:velox_network/src/config/velox_network_config.dart';
import 'package:velox_network/src/interceptors/velox_interceptor.dart';
import 'package:velox_network/src/velox_http_client.dart';

/// A fluent builder for creating configured [VeloxHttpClient] instances.
///
/// ```dart
/// final client = VeloxApiClientBuilder()
///   .baseUrl('https://api.example.com')
///   .connectTimeout(Duration(seconds: 10))
///   .addHeader('Accept', 'application/json')
///   .addInterceptor(AuthInterceptor())
///   .maxRetries(3)
///   .build();
/// ```
class VeloxApiClientBuilder {
  String _baseUrl = '';
  Duration _connectTimeout = const Duration(seconds: 30);
  Duration _receiveTimeout = const Duration(seconds: 30);
  Duration _sendTimeout = const Duration(seconds: 30);
  final Map<String, String> _headers = {};
  final List<VeloxInterceptor> _interceptors = [];
  int _maxRetries = 0;
  Duration _retryDelay = const Duration(seconds: 1);
  bool _followRedirects = true;
  int _maxRedirects = 5;
  VeloxLogger? _logger;

  /// Sets the base URL for all requests.
  // ignore: avoid_returning_this
  VeloxApiClientBuilder baseUrl(String url) {
    _baseUrl = url;
    return this; // ignore: avoid_returning_this
  }

  /// Sets the connection timeout.
  VeloxApiClientBuilder connectTimeout(Duration timeout) {
    _connectTimeout = timeout;
    return this; // ignore: avoid_returning_this
  }

  /// Sets the receive timeout.
  VeloxApiClientBuilder receiveTimeout(Duration timeout) {
    _receiveTimeout = timeout;
    return this; // ignore: avoid_returning_this
  }

  /// Sets the send timeout.
  VeloxApiClientBuilder sendTimeout(Duration timeout) {
    _sendTimeout = timeout;
    return this; // ignore: avoid_returning_this
  }

  /// Adds a single header.
  VeloxApiClientBuilder addHeader(String key, String value) {
    _headers[key] = value;
    return this; // ignore: avoid_returning_this
  }

  /// Adds multiple headers.
  VeloxApiClientBuilder addHeaders(Map<String, String> headers) {
    _headers.addAll(headers);
    return this; // ignore: avoid_returning_this
  }

  /// Adds an interceptor to the pipeline.
  VeloxApiClientBuilder addInterceptor(VeloxInterceptor interceptor) {
    _interceptors.add(interceptor);
    return this; // ignore: avoid_returning_this
  }

  /// Adds multiple interceptors.
  VeloxApiClientBuilder addInterceptors(List<VeloxInterceptor> interceptors) {
    _interceptors.addAll(interceptors);
    return this; // ignore: avoid_returning_this
  }

  /// Sets the maximum number of retry attempts.
  VeloxApiClientBuilder maxRetries(int retries) {
    _maxRetries = retries;
    return this; // ignore: avoid_returning_this
  }

  /// Sets the delay between retries.
  VeloxApiClientBuilder retryDelay(Duration delay) {
    _retryDelay = delay;
    return this; // ignore: avoid_returning_this
  }

  /// Sets whether to follow redirects.
  VeloxApiClientBuilder followRedirects({bool follow = true}) {
    _followRedirects = follow;
    return this; // ignore: avoid_returning_this
  }

  /// Sets the maximum number of redirects to follow.
  VeloxApiClientBuilder maxRedirects(int max) {
    _maxRedirects = max;
    return this; // ignore: avoid_returning_this
  }

  /// Sets the logger instance.
  VeloxApiClientBuilder logger(VeloxLogger logger) {
    _logger = logger;
    return this; // ignore: avoid_returning_this
  }

  /// Builds and returns the configured [VeloxHttpClient].
  VeloxHttpClient build() {
    if (_baseUrl.isEmpty) {
      throw ArgumentError('baseUrl must be set before building');
    }

    return VeloxHttpClient(
      config: VeloxNetworkConfig(
        baseUrl: _baseUrl,
        connectTimeout: _connectTimeout,
        receiveTimeout: _receiveTimeout,
        sendTimeout: _sendTimeout,
        headers: Map.unmodifiable(_headers),
        interceptors: List.unmodifiable(_interceptors),
        maxRetries: _maxRetries,
        retryDelay: _retryDelay,
        followRedirects: _followRedirects,
        maxRedirects: _maxRedirects,
      ),
      logger: _logger,
    );
  }
}

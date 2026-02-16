import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:velox_core/velox_core.dart';
import 'package:velox_logger/velox_logger.dart';
import 'package:velox_network/src/config/velox_network_config.dart';
import 'package:velox_network/src/models/velox_request.dart';
import 'package:velox_network/src/models/velox_response.dart';

/// A high-performance HTTP client with interceptors and retry support.
///
/// ```dart
/// final client = VeloxHttpClient(
///   config: VeloxNetworkConfig(baseUrl: 'https://api.example.com'),
/// );
///
/// final result = await client.get('/users/1');
/// result.when(
///   success: (response) => print(response.data),
///   failure: (error) => print(error.message),
/// );
/// ```
class VeloxHttpClient {
  /// Creates a [VeloxHttpClient] with the given [config].
  VeloxHttpClient({
    required this.config,
    HttpClient? httpClient,
    VeloxLogger? logger,
  }) : _httpClient = httpClient ?? HttpClient(),
       _logger = logger ?? VeloxLogger(tag: 'VeloxNetwork');

  /// The network configuration.
  final VeloxNetworkConfig config;

  final HttpClient _httpClient;
  final VeloxLogger _logger;

  /// Sends a GET request.
  Future<Result<VeloxResponse<String>, VeloxNetworkException>> get(
    String path, {
    Map<String, String> queryParameters = const {},
    Map<String, String> headers = const {},
  }) => _send(
    VeloxRequest(
      method: HttpMethod.get,
      path: path,
      queryParameters: queryParameters,
      headers: headers,
    ),
  );

  /// Sends a POST request.
  Future<Result<VeloxResponse<String>, VeloxNetworkException>> post(
    String path, {
    Object? body,
    Map<String, String> headers = const {},
  }) => _send(
    VeloxRequest(
      method: HttpMethod.post,
      path: path,
      headers: headers,
      body: body,
    ),
  );

  /// Sends a PUT request.
  Future<Result<VeloxResponse<String>, VeloxNetworkException>> put(
    String path, {
    Object? body,
    Map<String, String> headers = const {},
  }) => _send(
    VeloxRequest(
      method: HttpMethod.put,
      path: path,
      headers: headers,
      body: body,
    ),
  );

  /// Sends a PATCH request.
  Future<Result<VeloxResponse<String>, VeloxNetworkException>> patch(
    String path, {
    Object? body,
    Map<String, String> headers = const {},
  }) => _send(
    VeloxRequest(
      method: HttpMethod.patch,
      path: path,
      headers: headers,
      body: body,
    ),
  );

  /// Sends a DELETE request.
  Future<Result<VeloxResponse<String>, VeloxNetworkException>> delete(
    String path, {
    Map<String, String> headers = const {},
  }) => _send(
    VeloxRequest(
      method: HttpMethod.delete,
      path: path,
      headers: headers,
    ),
  );

  /// Sends a raw [VeloxRequest].
  Future<Result<VeloxResponse<String>, VeloxNetworkException>> send(
    VeloxRequest request,
  ) => _send(request);

  /// Disposes of the HTTP client and logger.
  void dispose() {
    _httpClient.close();
    _logger.dispose();
  }

  Future<Result<VeloxResponse<String>, VeloxNetworkException>> _send(
    VeloxRequest request,
  ) async {
    var currentRequest = request;

    // Apply request interceptors
    for (final interceptor in config.interceptors) {
      try {
        currentRequest = await interceptor.onRequest(currentRequest);
      } on Exception catch (e) {
        return Failure(
          VeloxNetworkException(
            message: 'Interceptor error: $e',
            code: 'INTERCEPTOR_ERROR',
            cause: e,
          ),
        );
      }
    }

    // Retry loop
    VeloxNetworkException? lastError;
    for (var attempt = 0; attempt <= config.maxRetries; attempt++) {
      if (attempt > 0) {
        final delay = config.retryDelay * attempt;
        _logger.debug('Retry attempt $attempt after ${delay.inMilliseconds}ms');
        await Future<void>.delayed(delay);
      }

      final result = await _executeRequest(currentRequest);
      final outcome = result.when(
        success: (response) {
          if (response.isRetryable && attempt < config.maxRetries) {
            lastError = VeloxNetworkException(
              message: 'Server error: ${response.statusCode}',
              code: 'SERVER_ERROR',
              statusCode: response.statusCode,
              url: currentRequest.fullUrl(config.baseUrl),
            );
            return null; // Retry
          }
          return Result<VeloxResponse<String>, VeloxNetworkException>.success(
            response,
          );
        },
        failure: (error) {
          lastError = error;
          if (attempt < config.maxRetries) return null; // Retry
          return Result<VeloxResponse<String>, VeloxNetworkException>.failure(
            error,
          );
        },
      );

      if (outcome != null) {
        // Apply response interceptors on success
        return outcome.when(
          success: (response) async {
            var currentResponse = response as VeloxResponse<dynamic>;
            for (final interceptor in config.interceptors) {
              currentResponse =
                  await interceptor.onResponse(currentResponse);
            }
            return Success(
              VeloxResponse<String>(
                statusCode: currentResponse.statusCode,
                request: currentResponse.request,
                data: currentResponse.data as String?,
                headers: currentResponse.headers,
                statusMessage: currentResponse.statusMessage,
              ),
            );
          },
          failure: Failure.new,
        );
      }
    }

    return Failure(
      lastError ??
          VeloxNetworkException(
            message: 'Request failed after ${config.maxRetries} retries',
            code: 'MAX_RETRIES_EXCEEDED',
            url: currentRequest.fullUrl(config.baseUrl),
          ),
    );
  }

  Future<Result<VeloxResponse<String>, VeloxNetworkException>>
      _executeRequest(VeloxRequest request) async {
    final url = request.fullUrl(config.baseUrl);
    _logger.debug('${request.method.name.toUpperCase()} $url');

    try {
      _httpClient.connectionTimeout = config.connectTimeout;

      final uri = Uri.parse(url);
      final httpRequest = await _openRequest(request.method, uri);

      // Set headers
      final allHeaders = {...config.headers, ...request.headers};
      allHeaders.forEach(httpRequest.headers.set); // ignore: cascade_invocations

      // Set body
      if (request.body != null) {
        final bodyBytes = utf8.encode(
          request.body is String
              ? request.body! as String
              : jsonEncode(request.body),
        );
        httpRequest.headers.contentLength = bodyBytes.length;
        if (!allHeaders.containsKey('content-type')) {
          httpRequest.headers.contentType = ContentType.json;
        }
        httpRequest.add(bodyBytes);
      }

      final httpResponse = await httpRequest.close().timeout(
        config.receiveTimeout,
      );

      final responseBody = await httpResponse.transform(utf8.decoder).join();
      final responseHeaders = <String, String>{};
      httpResponse.headers.forEach((name, values) {
        responseHeaders[name] = values.join(', ');
      });

      return Success(
        VeloxResponse<String>(
          statusCode: httpResponse.statusCode,
          request: request,
          data: responseBody,
          headers: responseHeaders,
          statusMessage: httpResponse.reasonPhrase,
        ),
      );
    } on TimeoutException catch (e) {
      return Failure(
        VeloxNetworkException(
          message: 'Request timed out',
          code: 'TIMEOUT',
          url: url,
          cause: e,
        ),
      );
    } on SocketException catch (e) {
      return Failure(
        VeloxNetworkException(
          message: 'Connection failed: ${e.message}',
          code: 'CONNECTION_ERROR',
          url: url,
          cause: e,
        ),
      );
    } on HttpException catch (e) {
      return Failure(
        VeloxNetworkException(
          message: 'HTTP error: ${e.message}',
          code: 'HTTP_ERROR',
          url: url,
          cause: e,
        ),
      );
    } on Exception catch (e) {
      return Failure(
        VeloxNetworkException(
          message: 'Unexpected error: $e',
          code: 'UNKNOWN',
          url: url,
          cause: e,
        ),
      );
    }
  }

  Future<HttpClientRequest> _openRequest(
    HttpMethod method,
    Uri uri,
  ) => switch (method) {
    HttpMethod.get => _httpClient.getUrl(uri),
    HttpMethod.post => _httpClient.postUrl(uri),
    HttpMethod.put => _httpClient.putUrl(uri),
    HttpMethod.patch => _httpClient.patchUrl(uri),
    HttpMethod.delete => _httpClient.deleteUrl(uri),
    HttpMethod.head => _httpClient.headUrl(uri),
  };
}

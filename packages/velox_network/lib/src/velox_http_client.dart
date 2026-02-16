import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:velox_core/velox_core.dart';
import 'package:velox_logger/velox_logger.dart';
import 'package:velox_network/src/cancellation/cancellation_token.dart';
import 'package:velox_network/src/config/timeout_config.dart';
import 'package:velox_network/src/config/velox_network_config.dart';
import 'package:velox_network/src/models/multipart_file.dart';
import 'package:velox_network/src/models/velox_request.dart';
import 'package:velox_network/src/models/velox_response.dart';

/// A callback for tracking download/upload progress.
///
/// [received] is the number of bytes transferred so far.
/// [total] is the total number of bytes, or -1 if unknown.
typedef ProgressCallback = void Function(int received, int total);

/// A high-performance HTTP client with interceptors, retry support,
/// multipart uploads, download with progress, and request cancellation.
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
    CancellationToken? cancellationToken,
    Map<String, String> headers = const {},
    Map<String, String> queryParameters = const {},
    TimeoutConfig? timeout,
  }) => _send(
    VeloxRequest(
      method: HttpMethod.get,
      path: path,
      queryParameters: queryParameters,
      headers: headers,
    ),
    cancellationToken: cancellationToken,
    timeout: timeout,
  );

  /// Sends a POST request.
  Future<Result<VeloxResponse<String>, VeloxNetworkException>> post(
    String path, {
    Object? body,
    CancellationToken? cancellationToken,
    Map<String, String> headers = const {},
    TimeoutConfig? timeout,
  }) => _send(
    VeloxRequest(
      method: HttpMethod.post,
      path: path,
      headers: headers,
      body: body,
    ),
    cancellationToken: cancellationToken,
    timeout: timeout,
  );

  /// Sends a PUT request.
  Future<Result<VeloxResponse<String>, VeloxNetworkException>> put(
    String path, {
    Object? body,
    CancellationToken? cancellationToken,
    Map<String, String> headers = const {},
    TimeoutConfig? timeout,
  }) => _send(
    VeloxRequest(
      method: HttpMethod.put,
      path: path,
      headers: headers,
      body: body,
    ),
    cancellationToken: cancellationToken,
    timeout: timeout,
  );

  /// Sends a PATCH request.
  Future<Result<VeloxResponse<String>, VeloxNetworkException>> patch(
    String path, {
    Object? body,
    CancellationToken? cancellationToken,
    Map<String, String> headers = const {},
    TimeoutConfig? timeout,
  }) => _send(
    VeloxRequest(
      method: HttpMethod.patch,
      path: path,
      headers: headers,
      body: body,
    ),
    cancellationToken: cancellationToken,
    timeout: timeout,
  );

  /// Sends a DELETE request.
  Future<Result<VeloxResponse<String>, VeloxNetworkException>> delete(
    String path, {
    CancellationToken? cancellationToken,
    Map<String, String> headers = const {},
    TimeoutConfig? timeout,
  }) => _send(
    VeloxRequest(
      method: HttpMethod.delete,
      path: path,
      headers: headers,
    ),
    cancellationToken: cancellationToken,
    timeout: timeout,
  );

  /// Sends a multipart POST request with files and fields.
  ///
  /// ```dart
  /// final result = await client.multipartPost(
  ///   '/upload',
  ///   files: [
  ///     VeloxMultipartFile(
  ///       field: 'avatar',
  ///       filename: 'photo.jpg',
  ///       bytes: imageBytes,
  ///       contentType: 'image/jpeg',
  ///     ),
  ///   ],
  ///   fields: {'description': 'Profile photo'},
  /// );
  /// ```
  Future<Result<VeloxResponse<String>, VeloxNetworkException>> multipartPost(
    String path, {
    CancellationToken? cancellationToken,
    Map<String, String> fields = const {},
    List<VeloxMultipartFile> files = const [],
    Map<String, String> headers = const {},
    TimeoutConfig? timeout,
  }) => _sendMultipart(
    method: HttpMethod.post,
    path: path,
    files: files,
    fields: fields,
    headers: headers,
    cancellationToken: cancellationToken,
    timeout: timeout,
  );

  /// Sends a multipart PUT request with files and fields.
  Future<Result<VeloxResponse<String>, VeloxNetworkException>> multipartPut(
    String path, {
    CancellationToken? cancellationToken,
    Map<String, String> fields = const {},
    List<VeloxMultipartFile> files = const [],
    Map<String, String> headers = const {},
    TimeoutConfig? timeout,
  }) => _sendMultipart(
    method: HttpMethod.put,
    path: path,
    files: files,
    fields: fields,
    headers: headers,
    cancellationToken: cancellationToken,
    timeout: timeout,
  );

  /// Downloads data from [path] with progress reporting.
  ///
  /// Returns the downloaded bytes as a [Uint8List].
  ///
  /// ```dart
  /// final result = await client.download(
  ///   '/files/report.pdf',
  ///   onProgress: (received, total) {
  ///     print('Downloaded $received / $total bytes');
  ///   },
  /// );
  /// ```
  Future<Result<VeloxResponse<Uint8List>, VeloxNetworkException>> download(
    String path, {
    CancellationToken? cancellationToken,
    Map<String, String> headers = const {},
    ProgressCallback? onProgress,
    Map<String, String> queryParameters = const {},
    TimeoutConfig? timeout,
  }) async {
    final request = VeloxRequest(
      method: HttpMethod.get,
      path: path,
      queryParameters: queryParameters,
      headers: headers,
    );

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

    final url = currentRequest.fullUrl(config.baseUrl);
    _logger.debug('DOWNLOAD $url');

    try {
      cancellationToken?.throwIfCancelled();

      final connectTimeout =
          timeout?.connectTimeout ?? config.connectTimeout;
      _httpClient.connectionTimeout = connectTimeout;

      final uri = Uri.parse(url);
      final httpRequest = await _openRequest(HttpMethod.get, uri);

      // Set headers
      final allHeaders = {...config.headers, ...currentRequest.headers};
      allHeaders.forEach(httpRequest.headers.set); // ignore: cascade_invocations

      final httpResponse = await httpRequest.close();

      cancellationToken?.throwIfCancelled();

      final contentLength = httpResponse.contentLength;
      final total = contentLength > 0 ? contentLength : -1;
      var received = 0;
      final chunks = <List<int>>[];

      await for (final chunk in httpResponse) {
        cancellationToken?.throwIfCancelled();
        chunks.add(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }

      final bytes = Uint8List(received);
      var offset = 0;
      for (final chunk in chunks) {
        bytes.setRange(offset, offset + chunk.length, chunk);
        offset += chunk.length;
      }

      final responseHeaders = <String, String>{};
      httpResponse.headers.forEach((name, values) {
        responseHeaders[name] = values.join(', ');
      });

      return Success(
        VeloxResponse<Uint8List>(
          statusCode: httpResponse.statusCode,
          request: currentRequest,
          data: bytes,
          headers: responseHeaders,
          statusMessage: httpResponse.reasonPhrase,
        ),
      );
    } on CancelledException {
      return Failure(
        VeloxNetworkException(
          message: 'Request cancelled'
              '${cancellationToken?.reason != null ? ': ${cancellationToken!.reason}' : ''}',
          code: 'CANCELLED',
          url: url,
        ),
      );
    } on TimeoutException catch (e) {
      return Failure(
        VeloxNetworkException(
          message: 'Download timed out',
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
    } on Exception catch (e) {
      return Failure(
        VeloxNetworkException(
          message: 'Download error: $e',
          code: 'UNKNOWN',
          url: url,
          cause: e,
        ),
      );
    }
  }

  /// Sends a raw [VeloxRequest].
  Future<Result<VeloxResponse<String>, VeloxNetworkException>> send(
    VeloxRequest request, {
    CancellationToken? cancellationToken,
    TimeoutConfig? timeout,
  }) => _send(request, cancellationToken: cancellationToken, timeout: timeout);

  /// Disposes of the HTTP client and logger.
  void dispose() {
    _httpClient.close();
    _logger.dispose();
  }

  Future<Result<VeloxResponse<String>, VeloxNetworkException>> _send(
    VeloxRequest request, {
    CancellationToken? cancellationToken,
    TimeoutConfig? timeout,
  }) async {
    var currentRequest = request;

    // Check cancellation before starting
    if (cancellationToken != null && cancellationToken.isCancelled) {
      return Failure(
        VeloxNetworkException(
          message: 'Request cancelled'
              '${cancellationToken.reason != null ? ': ${cancellationToken.reason}' : ''}',
          code: 'CANCELLED',
          url: currentRequest.fullUrl(config.baseUrl),
        ),
      );
    }

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
        _logger.debug(
          'Retry attempt $attempt after ${delay.inMilliseconds}ms',
        );
        await Future<void>.delayed(delay);
      }

      // Check cancellation before each attempt
      if (cancellationToken != null && cancellationToken.isCancelled) {
        return Failure(
          VeloxNetworkException(
            message: 'Request cancelled'
                '${cancellationToken.reason != null ? ': ${cancellationToken.reason}' : ''}',
            code: 'CANCELLED',
            url: currentRequest.fullUrl(config.baseUrl),
          ),
        );
      }

      final result = await _executeRequest(
        currentRequest,
        cancellationToken: cancellationToken,
        timeout: timeout,
      );
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

  Future<Result<VeloxResponse<String>, VeloxNetworkException>> _sendMultipart({
    required HttpMethod method,
    required String path,
    CancellationToken? cancellationToken,
    Map<String, String> fields = const {},
    List<VeloxMultipartFile> files = const [],
    Map<String, String> headers = const {},
    TimeoutConfig? timeout,
  }) async {
    final request = VeloxRequest(
      method: method,
      path: path,
      headers: headers,
    );

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

    final url = currentRequest.fullUrl(config.baseUrl);
    _logger.debug('MULTIPART ${method.name.toUpperCase()} $url');

    try {
      cancellationToken?.throwIfCancelled();

      final connectTimeout =
          timeout?.connectTimeout ?? config.connectTimeout;
      final receiveTimeout =
          timeout?.receiveTimeout ?? config.receiveTimeout;
      _httpClient.connectionTimeout = connectTimeout;

      // Generate boundary
      final boundary = _generateBoundary();

      final uri = Uri.parse(url);
      final httpRequest = await _openRequest(method, uri);

      // Set headers
      final allHeaders = {...config.headers, ...currentRequest.headers};
      // ignore: cascade_invocations
      allHeaders.forEach(httpRequest.headers.set);
      httpRequest.headers.set( // ignore: cascade_invocations
        'content-type',
        'multipart/form-data; boundary=$boundary',
      );

      // Build multipart body
      final bodyBytes = _buildMultipartBody(boundary, fields, files);
      httpRequest.headers.contentLength = bodyBytes.length;
      httpRequest.add(bodyBytes);

      cancellationToken?.throwIfCancelled();

      final httpResponse = await httpRequest.close().timeout(receiveTimeout);
      final responseBody = await httpResponse.transform(utf8.decoder).join();
      final responseHeaders = <String, String>{};
      httpResponse.headers.forEach((name, values) {
        responseHeaders[name] = values.join(', ');
      });

      final response = VeloxResponse<String>(
        statusCode: httpResponse.statusCode,
        request: currentRequest,
        data: responseBody,
        headers: responseHeaders,
        statusMessage: httpResponse.reasonPhrase,
      );

      // Apply response interceptors
      var currentResponse = response as VeloxResponse<dynamic>;
      for (final interceptor in config.interceptors) {
        currentResponse = await interceptor.onResponse(currentResponse);
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
    } on CancelledException {
      return Failure(
        VeloxNetworkException(
          message: 'Request cancelled'
              '${cancellationToken?.reason != null ? ': ${cancellationToken!.reason}' : ''}',
          code: 'CANCELLED',
          url: url,
        ),
      );
    } on TimeoutException catch (e) {
      return Failure(
        VeloxNetworkException(
          message: 'Multipart request timed out',
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
    } on Exception catch (e) {
      return Failure(
        VeloxNetworkException(
          message: 'Multipart error: $e',
          code: 'UNKNOWN',
          url: url,
          cause: e,
        ),
      );
    }
  }

  Future<Result<VeloxResponse<String>, VeloxNetworkException>>
      _executeRequest(
    VeloxRequest request, {
    CancellationToken? cancellationToken,
    TimeoutConfig? timeout,
  }) async {
    final url = request.fullUrl(config.baseUrl);
    _logger.debug('${request.method.name.toUpperCase()} $url');

    try {
      cancellationToken?.throwIfCancelled();

      final connectTimeout =
          timeout?.connectTimeout ?? config.connectTimeout;
      final receiveTimeout =
          timeout?.receiveTimeout ?? config.receiveTimeout;
      _httpClient.connectionTimeout = connectTimeout;

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

      cancellationToken?.throwIfCancelled();

      final httpResponse = await httpRequest.close().timeout(receiveTimeout);

      cancellationToken?.throwIfCancelled();

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
    } on CancelledException {
      return Failure(
        VeloxNetworkException(
          message: 'Request cancelled'
              '${cancellationToken?.reason != null ? ': ${cancellationToken!.reason}' : ''}',
          code: 'CANCELLED',
          url: url,
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

  String _generateBoundary() {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final buffer = StringBuffer('----VeloxBoundary');
    for (var i = 0; i < 16; i++) {
      buffer.write(chars[random.nextInt(chars.length)]);
    }
    return buffer.toString();
  }

  Uint8List _buildMultipartBody(
    String boundary,
    Map<String, String> fields,
    List<VeloxMultipartFile> files,
  ) {
    final buffer = BytesBuilder();
    final lineEnd = utf8.encode('\r\n');

    // Add fields
    for (final entry in fields.entries) {
      buffer
        ..add(utf8.encode('--$boundary\r\n'))
        ..add(
          utf8.encode(
            'Content-Disposition: form-data; name="${entry.key}"\r\n',
          ),
        )
        ..add(lineEnd)
        ..add(utf8.encode(entry.value))
        ..add(lineEnd);
    }

    // Add files
    for (final file in files) {
      buffer
        ..add(utf8.encode('--$boundary\r\n'))
        ..add(
          utf8.encode(
            'Content-Disposition: form-data; '
            'name="${file.field}"; '
            'filename="${file.filename}"\r\n',
          ),
        )
        ..add(utf8.encode('Content-Type: ${file.contentType}\r\n'))
        ..add(lineEnd)
        ..add(file.bytes)
        ..add(lineEnd);
    }

    // Final boundary
    buffer.add(utf8.encode('--$boundary--\r\n'));

    return buffer.toBytes();
  }
}

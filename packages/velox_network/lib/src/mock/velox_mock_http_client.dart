import 'package:velox_core/velox_core.dart';
import 'package:velox_network/src/models/velox_request.dart';
import 'package:velox_network/src/models/velox_response.dart';

/// A function that determines whether a request matches a stub.
typedef RequestMatcher = bool Function(VeloxRequest request);

/// A function that produces a response for a matched request.
typedef ResponseFactory = Future<VeloxResponse<String>> Function(
  VeloxRequest request,
);

/// A stub that matches requests and provides responses.
class RequestStub {
  /// Creates a [RequestStub].
  RequestStub({
    required this.matcher,
    required this.responseFactory,
  });

  /// The matcher that determines if this stub applies.
  final RequestMatcher matcher;

  /// The factory that produces the response.
  final ResponseFactory responseFactory;

  /// Number of times this stub has been matched.
  int matchCount = 0;
}

/// A mock HTTP client for testing that allows stubbing requests and
/// verifying interactions.
///
/// ```dart
/// final mock = VeloxMockHttpClient();
///
/// mock.stubGet('/users', response: VeloxResponse(
///   statusCode: 200,
///   request: request,
///   data: '{"users": []}',
/// ));
///
/// final result = await mock.send(
///   VeloxRequest(method: HttpMethod.get, path: '/users'),
///   baseUrl: 'https://api.example.com',
/// );
/// ```
class VeloxMockHttpClient {
  final List<RequestStub> _stubs = [];
  final List<VeloxRequest> _requests = [];

  /// All requests that have been sent through this mock client.
  List<VeloxRequest> get requests => List.unmodifiable(_requests);

  /// Number of requests sent.
  int get requestCount => _requests.length;

  /// Adds a stub that matches requests based on [matcher].
  void stub({
    required RequestMatcher matcher,
    required ResponseFactory responseFactory,
  }) {
    _stubs.add(RequestStub(matcher: matcher, responseFactory: responseFactory));
  }

  /// Adds a stub that matches GET requests to [path].
  void stubGet(
    String path, {
    int statusCode = 200,
    String? data,
    Map<String, String> headers = const {},
  }) {
    stub(
      matcher: (request) =>
          request.method == HttpMethod.get && request.path == path,
      responseFactory: (request) async => VeloxResponse<String>(
        statusCode: statusCode,
        request: request,
        data: data,
        headers: headers,
      ),
    );
  }

  /// Adds a stub that matches POST requests to [path].
  void stubPost(
    String path, {
    int statusCode = 200,
    String? data,
    Map<String, String> headers = const {},
  }) {
    stub(
      matcher: (request) =>
          request.method == HttpMethod.post && request.path == path,
      responseFactory: (request) async => VeloxResponse<String>(
        statusCode: statusCode,
        request: request,
        data: data,
        headers: headers,
      ),
    );
  }

  /// Adds a stub that matches PUT requests to [path].
  void stubPut(
    String path, {
    int statusCode = 200,
    String? data,
    Map<String, String> headers = const {},
  }) {
    stub(
      matcher: (request) =>
          request.method == HttpMethod.put && request.path == path,
      responseFactory: (request) async => VeloxResponse<String>(
        statusCode: statusCode,
        request: request,
        data: data,
        headers: headers,
      ),
    );
  }

  /// Adds a stub that matches DELETE requests to [path].
  void stubDelete(
    String path, {
    int statusCode = 200,
    String? data,
    Map<String, String> headers = const {},
  }) {
    stub(
      matcher: (request) =>
          request.method == HttpMethod.delete && request.path == path,
      responseFactory: (request) async => VeloxResponse<String>(
        statusCode: statusCode,
        request: request,
        data: data,
        headers: headers,
      ),
    );
  }

  /// Adds a stub that matches any request and returns an error response.
  void stubError({
    required String message,
    String code = 'MOCK_ERROR',
    int? statusCode,
  }) {
    stub(
      matcher: (_) => true,
      responseFactory: (_) async => throw VeloxNetworkException(
        message: message,
        code: code,
        statusCode: statusCode,
      ),
    );
  }

  /// Sends a request through the mock client, matching it against stubs.
  ///
  /// Returns a [Result] with the matched stub's response, or a failure
  /// if no stub matches.
  Future<Result<VeloxResponse<String>, VeloxNetworkException>> send(
    VeloxRequest request, {
    String baseUrl = '',
  }) async {
    _requests.add(request);

    for (final stub in _stubs.reversed) {
      if (stub.matcher(request)) {
        stub.matchCount++;
        try {
          final response = await stub.responseFactory(request);
          return Success(response);
        } on VeloxNetworkException catch (e) {
          return Failure(e);
        } on Exception catch (e) {
          return Failure(
            VeloxNetworkException(
              message: 'Mock error: $e',
              code: 'MOCK_ERROR',
              cause: e,
            ),
          );
        }
      }
    }

    return Failure(
      VeloxNetworkException(
        message: 'No stub matched request: '
            '${request.method.name.toUpperCase()} ${request.path}',
        code: 'NO_STUB_MATCH',
        url: request.fullUrl(baseUrl),
      ),
    );
  }

  /// Verifies that a request matching [matcher] was made [times] times.
  ///
  /// Throws a [StateError] if the verification fails.
  void verify(RequestMatcher matcher, {int? times}) {
    final matchedCount = _requests.where(matcher).length;
    if (times != null && matchedCount != times) {
      throw StateError(
        'Expected $times matching requests but found $matchedCount',
      );
    }
    if (times == null && matchedCount == 0) {
      throw StateError('Expected at least one matching request but found none');
    }
  }

  /// Verifies that no requests were made.
  void verifyNoRequests() {
    if (_requests.isNotEmpty) {
      throw StateError(
        'Expected no requests but found ${_requests.length}',
      );
    }
  }

  /// Clears all stubs and recorded requests.
  void reset() {
    _stubs.clear();
    _requests.clear();
  }
}

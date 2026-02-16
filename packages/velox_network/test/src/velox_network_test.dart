// ignore_for_file: avoid_redundant_argument_values, cascade_invocations
// ignore_for_file: unnecessary_lambdas

import 'dart:async';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:velox_logger/velox_logger.dart';
import 'package:velox_network/velox_network.dart';

void main() {
  // ── VeloxNetworkConfig ─────────────────────────────────────────────────

  group('VeloxNetworkConfig', () {
    test('creates with defaults', () {
      const config = VeloxNetworkConfig(baseUrl: 'https://api.example.com');

      expect(config.baseUrl, 'https://api.example.com');
      expect(config.connectTimeout, const Duration(seconds: 30));
      expect(config.maxRetries, 0);
      expect(config.headers, isEmpty);
      expect(config.interceptors, isEmpty);
    });

    test('copyWith replaces fields', () {
      const config = VeloxNetworkConfig(baseUrl: 'https://api.example.com');
      final updated = config.copyWith(
        baseUrl: 'https://api2.example.com',
        maxRetries: 3,
      );

      expect(updated.baseUrl, 'https://api2.example.com');
      expect(updated.maxRetries, 3);
      expect(updated.connectTimeout, config.connectTimeout);
    });
  });

  // ── VeloxRequest ───────────────────────────────────────────────────────

  group('VeloxRequest', () {
    test('creates correctly', () {
      final request = VeloxRequest(
        method: HttpMethod.get,
        path: '/users',
      );

      expect(request.method, HttpMethod.get);
      expect(request.path, '/users');
      expect(request.queryParameters, isEmpty);
      expect(request.headers, isEmpty);
      expect(request.body, isNull);
    });

    test('fullUrl combines base and path', () {
      final request = VeloxRequest(
        method: HttpMethod.get,
        path: '/users',
      );

      expect(
        request.fullUrl('https://api.example.com'),
        'https://api.example.com/users',
      );
    });

    test('fullUrl handles trailing slash', () {
      final request = VeloxRequest(
        method: HttpMethod.get,
        path: 'users',
      );

      expect(
        request.fullUrl('https://api.example.com/'),
        'https://api.example.com/users',
      );
    });

    test('fullUrl includes query parameters', () {
      final request = VeloxRequest(
        method: HttpMethod.get,
        path: '/users',
        queryParameters: {'page': '1', 'limit': '10'},
      );

      final url = request.fullUrl('https://api.example.com');
      expect(url, contains('page=1'));
      expect(url, contains('limit=10'));
    });

    test('copyWith replaces fields', () {
      final request = VeloxRequest(
        method: HttpMethod.get,
        path: '/users',
      );

      final updated = request.copyWith(
        method: HttpMethod.post,
        body: '{"name": "test"}',
      );

      expect(updated.method, HttpMethod.post);
      expect(updated.body, '{"name": "test"}');
      expect(updated.path, '/users');
    });

    test('toString is readable', () {
      final request = VeloxRequest(
        method: HttpMethod.get,
        path: '/users',
      );

      expect(request.toString(), 'VeloxRequest(GET /users)');
    });
  });

  // ── VeloxResponse ──────────────────────────────────────────────────────

  group('VeloxResponse', () {
    test('isSuccess for 2xx codes', () {
      final response = VeloxResponse<String>(
        statusCode: 200,
        request: VeloxRequest(method: HttpMethod.get, path: '/test'),
        data: 'ok',
      );

      expect(response.isSuccess, isTrue);
      expect(response.isClientError, isFalse);
      expect(response.isServerError, isFalse);
    });

    test('isClientError for 4xx codes', () {
      final response = VeloxResponse<String>(
        statusCode: 404,
        request: VeloxRequest(method: HttpMethod.get, path: '/test'),
      );

      expect(response.isSuccess, isFalse);
      expect(response.isClientError, isTrue);
    });

    test('isServerError for 5xx codes', () {
      final response = VeloxResponse<String>(
        statusCode: 500,
        request: VeloxRequest(method: HttpMethod.get, path: '/test'),
      );

      expect(response.isServerError, isTrue);
      expect(response.isRetryable, isTrue);
    });

    test('429 is retryable', () {
      final response = VeloxResponse<String>(
        statusCode: 429,
        request: VeloxRequest(method: HttpMethod.get, path: '/test'),
      );

      expect(response.isRetryable, isTrue);
    });
  });

  // ── VeloxInterceptor ───────────────────────────────────────────────────

  group('VeloxInterceptor', () {
    test('HeadersInterceptor adds headers', () async {
      final interceptor = HeadersInterceptor({
        'Authorization': 'Bearer token123',
        'Accept': 'application/json',
      });

      final request = VeloxRequest(
        method: HttpMethod.get,
        path: '/test',
      );

      final modified = await interceptor.onRequest(request);

      expect(modified.headers['Authorization'], 'Bearer token123');
      expect(modified.headers['Accept'], 'application/json');
    });

    test('HeadersInterceptor does not override existing headers', () async {
      final interceptor = HeadersInterceptor({
        'Accept': 'application/json',
      });

      final request = VeloxRequest(
        method: HttpMethod.get,
        path: '/test',
        headers: {'Accept': 'text/plain'},
      );

      final modified = await interceptor.onRequest(request);

      expect(modified.headers['Accept'], 'text/plain');
    });

    test('LoggingInterceptor calls onLog', () async {
      final logs = <String>[];
      final interceptor = LoggingInterceptor(onLog: logs.add);

      final request = VeloxRequest(
        method: HttpMethod.get,
        path: '/users',
      );

      await interceptor.onRequest(request);

      expect(logs, hasLength(1));
      expect(logs.first, contains('GET'));
      expect(logs.first, contains('/users'));
    });
  });

  // ── CircuitBreaker ─────────────────────────────────────────────────────

  group('VeloxCircuitBreaker', () {
    test('starts in closed state', () {
      final breaker = VeloxCircuitBreaker(
        failureThreshold: 3,
        recoveryTimeout: const Duration(seconds: 10),
      );

      expect(breaker.state, CircuitBreakerState.closed);
      expect(breaker.isAllowingRequests, isTrue);
      expect(breaker.failureCount, 0);
    });

    test('stays closed on successful requests', () async {
      final breaker = VeloxCircuitBreaker(
        failureThreshold: 3,
        recoveryTimeout: const Duration(seconds: 10),
      );

      final result = await breaker.execute(() async => 'success');
      expect(result, 'success');
      expect(breaker.state, CircuitBreakerState.closed);
    });

    test('opens after reaching failure threshold', () async {
      final breaker = VeloxCircuitBreaker(
        failureThreshold: 3,
        recoveryTimeout: const Duration(seconds: 10),
      );

      for (var i = 0; i < 3; i++) {
        try {
          await breaker.execute<String>(
            () async => throw Exception('fail'),
          );
        } on Exception {
          // Expected
        }
      }

      expect(breaker.state, CircuitBreakerState.open);
      expect(breaker.isAllowingRequests, isFalse);
    });

    test('rejects requests when open', () async {
      final breaker = VeloxCircuitBreaker(
        failureThreshold: 1,
        recoveryTimeout: const Duration(seconds: 60),
      );

      try {
        await breaker.execute<String>(
          () async => throw Exception('fail'),
        );
      } on Exception {
        // Opens
      }

      expect(
        () => breaker.execute(() async => 'should not run'),
        throwsA(isA<CircuitBreakerOpenException>()),
      );
    });

    test('transitions to half-open after recovery timeout', () async {
      final transitions = <String>[];
      final breaker = VeloxCircuitBreaker(
        failureThreshold: 1,
        recoveryTimeout: const Duration(milliseconds: 50),
        onStateChange: (from, to) => transitions.add('$from -> $to'),
      );

      try {
        await breaker.execute<String>(
          () async => throw Exception('fail'),
        );
      } on Exception {
        // Opens
      }

      expect(breaker.state, CircuitBreakerState.open);

      // Wait for recovery
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(breaker.state, CircuitBreakerState.halfOpen);
      expect(transitions, contains('CircuitBreakerState.closed -> CircuitBreakerState.open'));
      expect(transitions, contains('CircuitBreakerState.open -> CircuitBreakerState.halfOpen'));
    });

    test('closes from half-open on success', () async {
      final breaker = VeloxCircuitBreaker(
        failureThreshold: 1,
        recoveryTimeout: const Duration(milliseconds: 50),
      );

      try {
        await breaker.execute<String>(
          () async => throw Exception('fail'),
        );
      } on Exception {
        // Opens
      }

      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Should be half-open now
      final result = await breaker.execute(() async => 'recovered');
      expect(result, 'recovered');
      expect(breaker.state, CircuitBreakerState.closed);
    });

    test('reopens from half-open on failure', () async {
      final breaker = VeloxCircuitBreaker(
        failureThreshold: 1,
        recoveryTimeout: const Duration(milliseconds: 50),
      );

      try {
        await breaker.execute<String>(
          () async => throw Exception('fail'),
        );
      } on Exception {
        // Opens
      }

      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Half-open, try and fail again
      try {
        await breaker.execute<String>(
          () async => throw Exception('fail again'),
        );
      } on Exception {
        // Reopens
      }

      expect(breaker.state, CircuitBreakerState.open);
    });

    test('reset returns to closed state', () async {
      final breaker = VeloxCircuitBreaker(
        failureThreshold: 1,
        recoveryTimeout: const Duration(seconds: 60),
      );

      try {
        await breaker.execute<String>(
          () async => throw Exception('fail'),
        );
      } on Exception {
        // Opens
      }

      expect(breaker.state, CircuitBreakerState.open);
      breaker.reset();
      expect(breaker.state, CircuitBreakerState.closed);
      expect(breaker.failureCount, 0);
    });

    test('state change callback is invoked', () async {
      final transitions = <String>[];
      final breaker = VeloxCircuitBreaker(
        failureThreshold: 1,
        recoveryTimeout: const Duration(seconds: 60),
        onStateChange: (from, to) => transitions.add('$from->$to'),
      );

      try {
        await breaker.execute<String>(
          () async => throw Exception('fail'),
        );
      } on Exception {
        // Opens
      }

      expect(transitions, hasLength(1));
      expect(
        transitions.first,
        'CircuitBreakerState.closed->CircuitBreakerState.open',
      );
    });

    test('success resets failure count', () async {
      final breaker = VeloxCircuitBreaker(
        failureThreshold: 3,
        recoveryTimeout: const Duration(seconds: 60),
      );

      // Fail twice
      for (var i = 0; i < 2; i++) {
        try {
          await breaker.execute<String>(
            () async => throw Exception('fail'),
          );
        } on Exception {
          // Expected
        }
      }
      expect(breaker.failureCount, 2);

      // Succeed once
      await breaker.execute(() async => 'ok');
      expect(breaker.failureCount, 0);
    });

    test('CircuitBreakerOpenException has informative toString', () {
      const exception = CircuitBreakerOpenException(
        message: 'Circuit is open',
      );
      expect(
        exception.toString(),
        'CircuitBreakerOpenException: Circuit is open',
      );
    });
  });

  // ── VeloxLoggingInterceptor ────────────────────────────────────────────

  group('VeloxLoggingInterceptor', () {
    test('logs request at debug level', () async {
      final history = VeloxLogHistory();
      final logger = VeloxLogger(
        tag: 'HTTP',
        minLevel: LogLevel.debug,
        history: history,
      );
      final interceptor = VeloxLoggingInterceptor(logger: logger);

      final request = VeloxRequest(
        method: HttpMethod.post,
        path: '/users',
        headers: {'Authorization': 'Bearer xyz'},
        body: '{"name":"test"}',
      );

      await interceptor.onRequest(request);

      expect(history.records, isNotEmpty);
      expect(history.records.last.message, contains('POST'));
      expect(history.records.last.message, contains('/users'));
    });

    test('logs request headers when enabled', () async {
      final history = VeloxLogHistory();
      final logger = VeloxLogger(
        tag: 'HTTP',
        minLevel: LogLevel.debug,
        history: history,
      );
      final interceptor = VeloxLoggingInterceptor(
        logger: logger,
        logRequestHeaders: true,
      );

      final request = VeloxRequest(
        method: HttpMethod.get,
        path: '/data',
        headers: {'Accept': 'application/json'},
      );

      await interceptor.onRequest(request);

      expect(history.records.last.message, contains('Accept'));
    });

    test('logs request body when enabled', () async {
      final history = VeloxLogHistory();
      final logger = VeloxLogger(
        tag: 'HTTP',
        minLevel: LogLevel.debug,
        history: history,
      );
      final interceptor = VeloxLoggingInterceptor(
        logger: logger,
        logRequestBody: true,
      );

      final request = VeloxRequest(
        method: HttpMethod.post,
        path: '/data',
        body: '{"key":"value"}',
      );

      await interceptor.onRequest(request);

      expect(history.records.last.message, contains('{"key":"value"}'));
    });

    test('logs response with status code', () async {
      final history = VeloxLogHistory();
      final logger = VeloxLogger(
        tag: 'HTTP',
        minLevel: LogLevel.debug,
        history: history,
      );
      final interceptor = VeloxLoggingInterceptor(logger: logger);

      final response = VeloxResponse<String>(
        statusCode: 200,
        request: VeloxRequest(method: HttpMethod.get, path: '/data'),
        statusMessage: 'OK',
        data: 'response body',
      );

      await interceptor.onResponse(response);

      expect(history.records, isNotEmpty);
      expect(history.records.last.message, contains('200'));
      expect(history.records.last.message, contains('/data'));
    });

    test('logs errors at error level', () async {
      final history = VeloxLogHistory();
      final logger = VeloxLogger(
        tag: 'HTTP',
        minLevel: LogLevel.debug,
        history: history,
      );
      final interceptor = VeloxLoggingInterceptor(logger: logger);

      final request = VeloxRequest(method: HttpMethod.get, path: '/fail');

      await interceptor.onError('Connection refused', request);

      expect(history.records.last.level, LogLevel.error);
      expect(history.records.last.message, contains('Connection refused'));
    });
  });

  // ── CancellationToken ──────────────────────────────────────────────────

  group('CancellationToken', () {
    test('starts uncancelled', () {
      final token = CancellationToken();
      expect(token.isCancelled, isFalse);
      expect(token.reason, isNull);
    });

    test('cancel sets isCancelled to true', () {
      final token = CancellationToken();
      token.cancel();
      expect(token.isCancelled, isTrue);
    });

    test('cancel with reason preserves reason', () {
      final token = CancellationToken();
      token.cancel('User navigated away');
      expect(token.reason, 'User navigated away');
    });

    test('whenCancelled completes on cancel', () async {
      final token = CancellationToken();

      var completed = false;
      unawaited(token.whenCancelled.then((_) => completed = true));

      token.cancel();
      await Future<void>.delayed(Duration.zero);
      expect(completed, isTrue);
    });

    test('throwIfCancelled throws when cancelled', () {
      final token = CancellationToken();
      token.cancel('test');

      expect(
        () => token.throwIfCancelled(),
        throwsA(isA<CancelledException>()),
      );
    });

    test('throwIfCancelled does nothing when not cancelled', () {
      final token = CancellationToken();
      // Should not throw
      token.throwIfCancelled();
    });

    test('CancelledException has informative toString', () {
      const ex = CancelledException(reason: 'timeout');
      expect(ex.toString(), 'CancelledException: timeout');
    });

    test('CancelledException without reason has default message', () {
      const ex = CancelledException();
      expect(ex.toString(), 'CancelledException: Request cancelled');
    });

    test('double cancel is idempotent', () {
      final token = CancellationToken();
      token.cancel('first');
      token.cancel('second');
      expect(token.reason, 'first');
    });
  });

  // ── VeloxMockHttpClient ────────────────────────────────────────────────

  group('VeloxMockHttpClient', () {
    test('starts with no requests', () {
      final mock = VeloxMockHttpClient();
      expect(mock.requestCount, 0);
      expect(mock.requests, isEmpty);
    });

    test('stubGet returns expected response', () async {
      final mock = VeloxMockHttpClient();
      mock.stubGet('/users', data: '{"users": []}');

      final result = await mock.send(
        VeloxRequest(method: HttpMethod.get, path: '/users'),
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.data, '{"users": []}');
      expect(result.valueOrNull?.statusCode, 200);
    });

    test('stubPost returns expected response', () async {
      final mock = VeloxMockHttpClient();
      mock.stubPost('/users', statusCode: 201, data: '{"id": 1}');

      final result = await mock.send(
        VeloxRequest(method: HttpMethod.post, path: '/users'),
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.statusCode, 201);
    });

    test('stubPut returns expected response', () async {
      final mock = VeloxMockHttpClient();
      mock.stubPut('/users/1', data: '{"updated": true}');

      final result = await mock.send(
        VeloxRequest(method: HttpMethod.put, path: '/users/1'),
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.data, '{"updated": true}');
    });

    test('stubDelete returns expected response', () async {
      final mock = VeloxMockHttpClient();
      mock.stubDelete('/users/1', statusCode: 204);

      final result = await mock.send(
        VeloxRequest(method: HttpMethod.delete, path: '/users/1'),
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.statusCode, 204);
    });

    test('returns failure when no stub matches', () async {
      final mock = VeloxMockHttpClient();

      final result = await mock.send(
        VeloxRequest(method: HttpMethod.get, path: '/unknown'),
      );

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull?.code, 'NO_STUB_MATCH');
    });

    test('stubError returns failure result', () async {
      final mock = VeloxMockHttpClient();
      mock.stubError(message: 'Server down', statusCode: 500);

      final result = await mock.send(
        VeloxRequest(method: HttpMethod.get, path: '/anything'),
      );

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull?.message, 'Server down');
    });

    test('records all sent requests', () async {
      final mock = VeloxMockHttpClient();
      mock.stubGet('/a', data: 'a');
      mock.stubGet('/b', data: 'b');

      await mock.send(VeloxRequest(method: HttpMethod.get, path: '/a'));
      await mock.send(VeloxRequest(method: HttpMethod.get, path: '/b'));

      expect(mock.requestCount, 2);
      expect(mock.requests[0].path, '/a');
      expect(mock.requests[1].path, '/b');
    });

    test('verify succeeds when request was made', () async {
      final mock = VeloxMockHttpClient();
      mock.stubGet('/users', data: '[]');

      await mock.send(VeloxRequest(method: HttpMethod.get, path: '/users'));

      // Should not throw
      mock.verify(
        (r) => r.method == HttpMethod.get && r.path == '/users',
      );
    });

    test('verify fails when request was not made', () {
      final mock = VeloxMockHttpClient();

      expect(
        () => mock.verify(
          (r) => r.method == HttpMethod.get && r.path == '/missing',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('verify with times checks exact count', () async {
      final mock = VeloxMockHttpClient();
      mock.stubGet('/users', data: '[]');

      await mock.send(VeloxRequest(method: HttpMethod.get, path: '/users'));
      await mock.send(VeloxRequest(method: HttpMethod.get, path: '/users'));

      mock.verify(
        (r) => r.method == HttpMethod.get && r.path == '/users',
        times: 2,
      );

      expect(
        () => mock.verify(
          (r) => r.method == HttpMethod.get && r.path == '/users',
          times: 1,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('verifyNoRequests succeeds when empty', () {
      final mock = VeloxMockHttpClient();
      mock.verifyNoRequests(); // Should not throw
    });

    test('verifyNoRequests fails when requests exist', () async {
      final mock = VeloxMockHttpClient();
      mock.stubGet('/x', data: '');
      await mock.send(VeloxRequest(method: HttpMethod.get, path: '/x'));

      expect(() => mock.verifyNoRequests(), throwsA(isA<StateError>()));
    });

    test('reset clears stubs and requests', () async {
      final mock = VeloxMockHttpClient();
      mock.stubGet('/users', data: '[]');
      await mock.send(VeloxRequest(method: HttpMethod.get, path: '/users'));

      mock.reset();

      expect(mock.requestCount, 0);

      final result = await mock.send(
        VeloxRequest(method: HttpMethod.get, path: '/users'),
      );
      expect(result.isFailure, isTrue); // No stubs
    });

    test('later stubs take precedence', () async {
      final mock = VeloxMockHttpClient();
      mock.stubGet('/data', data: 'first');
      mock.stubGet('/data', data: 'second');

      final result = await mock.send(
        VeloxRequest(method: HttpMethod.get, path: '/data'),
      );

      expect(result.valueOrNull?.data, 'second');
    });

    test('custom stub with matcher', () async {
      final mock = VeloxMockHttpClient();
      mock.stub(
        matcher: (r) => r.headers.containsKey('X-Custom'),
        responseFactory: (r) async => VeloxResponse<String>(
          statusCode: 200,
          request: r,
          data: 'custom',
        ),
      );

      final result = await mock.send(
        VeloxRequest(
          method: HttpMethod.get,
          path: '/any',
          headers: {'X-Custom': 'true'},
        ),
      );

      expect(result.valueOrNull?.data, 'custom');
    });
  });

  // ── VeloxRequestQueue ──────────────────────────────────────────────────

  group('VeloxRequestQueue', () {
    test('executes requests immediately when under limit', () async {
      final queue = VeloxRequestQueue(maxConcurrent: 3);

      final result = await queue.add(() async => 42);
      expect(result, 42);

      queue.dispose();
    });

    test('limits concurrent requests', () async {
      final queue = VeloxRequestQueue(maxConcurrent: 2);
      var maxActive = 0;
      var currentActive = 0;

      Future<int> trackedTask(int id) async {
        currentActive++;
        if (currentActive > maxActive) maxActive = currentActive;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        currentActive--;
        return id;
      }

      final futures = [
        queue.add(() => trackedTask(1)),
        queue.add(() => trackedTask(2)),
        queue.add(() => trackedTask(3)),
        queue.add(() => trackedTask(4)),
      ];

      final results = await Future.wait(futures);

      expect(results, containsAll([1, 2, 3, 4]));
      expect(maxActive, lessThanOrEqualTo(2));

      queue.dispose();
    });

    test('reports activeCount and pendingCount', () async {
      final queue = VeloxRequestQueue(maxConcurrent: 1);
      final completer = Completer<void>();

      // Add a slow task to block the queue
      final future1 = queue.add(() => completer.future);

      // Give it time to start
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(queue.activeCount, 1);

      // Add another task (should be pending)
      final future2 = queue.add(() async => 'done');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(queue.pendingCount, 1);

      // Complete the first task
      completer.complete();
      await future1;
      await future2;

      queue.dispose();
    });

    test('dispose rejects new requests', () {
      final queue = VeloxRequestQueue(maxConcurrent: 1);
      queue.dispose();

      expect(
        () => queue.add(() async => 42),
        throwsA(isA<StateError>()),
      );
    });

    test('propagates errors from tasks', () async {
      final queue = VeloxRequestQueue(maxConcurrent: 1);

      expect(
        queue.add(() async => throw Exception('task failed')),
        throwsA(isA<Exception>()),
      );

      queue.dispose();
    });
  });

  // ── VeloxCacheInterceptor ──────────────────────────────────────────────

  group('VeloxCacheInterceptor', () {
    test('starts with empty cache', () {
      final interceptor = VeloxCacheInterceptor(
        ttl: const Duration(minutes: 5),
      );

      expect(interceptor.size, 0);
    });

    test('caches GET responses via onResponse', () async {
      final interceptor = VeloxCacheInterceptor(
        ttl: const Duration(minutes: 5),
      );

      final request = VeloxRequest(method: HttpMethod.get, path: '/data');
      final response = VeloxResponse<dynamic>(
        statusCode: 200,
        request: request,
        data: 'cached data',
      );

      await interceptor.onResponse(response);

      expect(interceptor.size, 1);
    });

    test('returns cached response on second request', () async {
      final interceptor = VeloxCacheInterceptor(
        ttl: const Duration(minutes: 5),
      );

      final request = VeloxRequest(method: HttpMethod.get, path: '/data');

      // First request - no cache
      final firstMod = await interceptor.onRequest(request);
      expect(firstMod.extra['_cacheHit'], isNull);

      // Simulate response being cached
      final response = VeloxResponse<dynamic>(
        statusCode: 200,
        request: request,
        data: 'cached data',
      );
      await interceptor.onResponse(response);

      // Second request - should find cache
      final secondMod = await interceptor.onRequest(request);
      expect(secondMod.extra['_cacheHit'], isTrue);

      // Response interceptor should return cached response
      final cachedResp = await interceptor.onResponse(
        VeloxResponse<dynamic>(
          statusCode: 200,
          request: secondMod,
          data: 'new data',
        ),
      );
      expect(cachedResp.data, 'cached data');
    });

    test('does not cache POST requests', () async {
      final interceptor = VeloxCacheInterceptor(
        ttl: const Duration(minutes: 5),
      );

      final request = VeloxRequest(method: HttpMethod.post, path: '/data');
      final response = VeloxResponse<dynamic>(
        statusCode: 200,
        request: request,
        data: 'data',
      );

      await interceptor.onResponse(response);

      expect(interceptor.size, 0);
    });

    test('does not cache error responses', () async {
      final interceptor = VeloxCacheInterceptor(
        ttl: const Duration(minutes: 5),
      );

      final request = VeloxRequest(method: HttpMethod.get, path: '/data');
      final response = VeloxResponse<dynamic>(
        statusCode: 500,
        request: request,
        data: 'error',
      );

      await interceptor.onResponse(response);

      expect(interceptor.size, 0);
    });

    test('respects skipCache extra flag', () async {
      final interceptor = VeloxCacheInterceptor(
        ttl: const Duration(minutes: 5),
      );

      // Cache a response
      final request = VeloxRequest(method: HttpMethod.get, path: '/data');
      final response = VeloxResponse<dynamic>(
        statusCode: 200,
        request: request,
        data: 'cached',
      );
      await interceptor.onResponse(response);

      // Request with skipCache
      final skipRequest = VeloxRequest(
        method: HttpMethod.get,
        path: '/data',
        extra: {'skipCache': true},
      );
      final modified = await interceptor.onRequest(skipRequest);
      expect(modified.extra['_cacheHit'], isNull);
    });

    test('clearCache removes all entries', () async {
      final interceptor = VeloxCacheInterceptor(
        ttl: const Duration(minutes: 5),
      );

      final request = VeloxRequest(method: HttpMethod.get, path: '/data');
      final response = VeloxResponse<dynamic>(
        statusCode: 200,
        request: request,
        data: 'data',
      );
      await interceptor.onResponse(response);
      expect(interceptor.size, 1);

      interceptor.clearCache();
      expect(interceptor.size, 0);
    });

    test('evict removes specific entry', () async {
      final interceptor = VeloxCacheInterceptor(
        ttl: const Duration(minutes: 5),
      );

      final request = VeloxRequest(method: HttpMethod.get, path: '/data');
      final response = VeloxResponse<dynamic>(
        statusCode: 200,
        request: request,
        data: 'data',
      );
      await interceptor.onResponse(response);
      expect(interceptor.size, 1);

      interceptor.evict('get:/data');
      expect(interceptor.size, 0);
    });

    test('evicts oldest when maxEntries exceeded', () async {
      final interceptor = VeloxCacheInterceptor(
        ttl: const Duration(minutes: 5),
        maxEntries: 2,
      );

      for (var i = 0; i < 3; i++) {
        final request = VeloxRequest(
          method: HttpMethod.get,
          path: '/data/$i',
        );
        final response = VeloxResponse<dynamic>(
          statusCode: 200,
          request: request,
          data: 'data$i',
        );
        await interceptor.onResponse(response);
      }

      expect(interceptor.size, 2);
    });

    test('custom cache key strategy', () async {
      final interceptor = VeloxCacheInterceptor(
        ttl: const Duration(minutes: 5),
        cacheKeyStrategy: (r) => 'custom:${r.path}',
      );

      final request = VeloxRequest(method: HttpMethod.get, path: '/test');
      final response = VeloxResponse<dynamic>(
        statusCode: 200,
        request: request,
        data: 'test',
      );
      await interceptor.onResponse(response);

      final cached = interceptor.getCachedResponse('custom:/test');
      expect(cached, isNotNull);
      expect(cached?.data, 'test');
    });
  });

  // ── TimeoutConfig ──────────────────────────────────────────────────────

  group('TimeoutConfig', () {
    test('creates with all fields', () {
      const config = TimeoutConfig(
        connectTimeout: Duration(seconds: 5),
        receiveTimeout: Duration(seconds: 10),
        sendTimeout: Duration(seconds: 3),
      );

      expect(config.connectTimeout, const Duration(seconds: 5));
      expect(config.receiveTimeout, const Duration(seconds: 10));
      expect(config.sendTimeout, const Duration(seconds: 3));
    });

    test('allows null fields for defaults', () {
      const config = TimeoutConfig(
        connectTimeout: Duration(seconds: 5),
      );

      expect(config.connectTimeout, isNotNull);
      expect(config.receiveTimeout, isNull);
      expect(config.sendTimeout, isNull);
    });

    test('copyWith replaces fields', () {
      const config = TimeoutConfig(
        connectTimeout: Duration(seconds: 5),
        receiveTimeout: Duration(seconds: 10),
      );

      final updated = config.copyWith(
        receiveTimeout: const Duration(seconds: 30),
      );

      expect(updated.connectTimeout, const Duration(seconds: 5));
      expect(updated.receiveTimeout, const Duration(seconds: 30));
    });

    test('toString is readable', () {
      const config = TimeoutConfig(
        connectTimeout: Duration(seconds: 5),
      );

      expect(config.toString(), contains('connect'));
    });
  });

  // ── VeloxApiClientBuilder ──────────────────────────────────────────────

  group('VeloxApiClientBuilder', () {
    test('builds a configured client', () {
      final client = VeloxApiClientBuilder()
          .baseUrl('https://api.example.com') // ignore: avoid_returning_this
          .connectTimeout(const Duration(seconds: 10))
          .receiveTimeout(const Duration(seconds: 20))
          .addHeader('Accept', 'application/json')
          .maxRetries(3)
          .retryDelay(const Duration(seconds: 2))
          .build();

      expect(client.config.baseUrl, 'https://api.example.com');
      expect(client.config.connectTimeout, const Duration(seconds: 10));
      expect(client.config.receiveTimeout, const Duration(seconds: 20));
      expect(client.config.headers['Accept'], 'application/json');
      expect(client.config.maxRetries, 3);
      expect(client.config.retryDelay, const Duration(seconds: 2));

      client.dispose();
    });

    test('throws when baseUrl is not set', () {
      expect(
        () => VeloxApiClientBuilder().build(),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('addHeaders adds multiple headers', () {
      final client = VeloxApiClientBuilder()
          .baseUrl('https://api.example.com')
          .addHeaders({
            'Accept': 'application/json',
            'X-Custom': 'value',
          })
          .build();

      expect(client.config.headers['Accept'], 'application/json');
      expect(client.config.headers['X-Custom'], 'value');

      client.dispose();
    });

    test('addInterceptor adds interceptor', () {
      final client = VeloxApiClientBuilder()
          .baseUrl('https://api.example.com')
          .addInterceptor(HeadersInterceptor({'X-Test': 'true'}))
          .build();

      expect(client.config.interceptors, hasLength(1));

      client.dispose();
    });

    test('addInterceptors adds multiple interceptors', () {
      final client = VeloxApiClientBuilder()
          .baseUrl('https://api.example.com')
          .addInterceptors([
            HeadersInterceptor({'X-Test': 'true'}),
            LoggingInterceptor(),
          ])
          .build();

      expect(client.config.interceptors, hasLength(2));

      client.dispose();
    });

    test('followRedirects and maxRedirects', () {
      final client = VeloxApiClientBuilder()
          .baseUrl('https://api.example.com')
          .followRedirects(follow: false)
          .maxRedirects(10)
          .build();

      expect(client.config.followRedirects, isFalse);
      expect(client.config.maxRedirects, 10);

      client.dispose();
    });

    test('sendTimeout is set', () {
      final client = VeloxApiClientBuilder()
          .baseUrl('https://api.example.com')
          .sendTimeout(const Duration(seconds: 15))
          .build();

      expect(client.config.sendTimeout, const Duration(seconds: 15));

      client.dispose();
    });

    test('logger is set', () {
      final logger = VeloxLogger(tag: 'TestLogger');
      final client = VeloxApiClientBuilder()
          .baseUrl('https://api.example.com')
          .logger(logger)
          .build();

      // Client is created successfully with logger
      expect(client, isNotNull);

      client.dispose();
      logger.dispose();
    });
  });

  // ── VeloxMultipartFile ─────────────────────────────────────────────────

  group('VeloxMultipartFile', () {
    test('creates with required fields', () {
      final file = VeloxMultipartFile(
        field: 'avatar',
        filename: 'photo.jpg',
        bytes: Uint8List.fromList([1, 2, 3]),
      );

      expect(file.field, 'avatar');
      expect(file.filename, 'photo.jpg');
      expect(file.bytes.length, 3);
      expect(file.contentType, 'application/octet-stream');
    });

    test('creates with custom content type', () {
      final file = VeloxMultipartFile(
        field: 'document',
        filename: 'report.pdf',
        bytes: Uint8List.fromList([1, 2, 3, 4]),
        contentType: 'application/pdf',
      );

      expect(file.contentType, 'application/pdf');
    });

    test('toString is informative', () {
      final file = VeloxMultipartFile(
        field: 'avatar',
        filename: 'photo.jpg',
        bytes: Uint8List.fromList([1, 2, 3]),
        contentType: 'image/jpeg',
      );

      final str = file.toString();
      expect(str, contains('avatar'));
      expect(str, contains('photo.jpg'));
      expect(str, contains('3 bytes'));
      expect(str, contains('image/jpeg'));
    });
  });

  // ── CacheEntry ─────────────────────────────────────────────────────────

  group('CacheEntry', () {
    test('isExpired returns false for fresh entry', () {
      final entry = CacheEntry(
        response: VeloxResponse<dynamic>(
          statusCode: 200,
          request: VeloxRequest(method: HttpMethod.get, path: '/test'),
        ),
        cachedAt: DateTime.now(),
        ttl: const Duration(minutes: 5),
      );

      expect(entry.isExpired, isFalse);
    });

    test('isExpired returns true for old entry', () {
      final entry = CacheEntry(
        response: VeloxResponse<dynamic>(
          statusCode: 200,
          request: VeloxRequest(method: HttpMethod.get, path: '/test'),
        ),
        cachedAt: DateTime.now().subtract(const Duration(minutes: 10)),
        ttl: const Duration(minutes: 5),
      );

      expect(entry.isExpired, isTrue);
    });
  });
}

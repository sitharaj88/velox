import 'package:test/test.dart';
import 'package:velox_network/velox_network.dart';

void main() {
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
}

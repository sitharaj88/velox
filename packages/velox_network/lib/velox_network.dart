/// A high-performance HTTP client abstraction for Flutter.
///
/// Provides:
/// - Type-safe request/response handling with [Result] types
/// - Interceptor pipeline for request/response transformation
/// - Configurable retry logic with exponential backoff
/// - Circuit breaker pattern for fault tolerance
/// - Request cancellation support
/// - Multipart file upload
/// - Download with progress tracking
/// - Response caching
/// - Request queuing and rate limiting
/// - Fluent API client builder
/// - Mock HTTP client for testing
library;

export 'src/builder/api_client_builder.dart';
export 'src/cancellation/cancellation_token.dart';
export 'src/circuit_breaker/velox_circuit_breaker.dart';
export 'src/config/timeout_config.dart';
export 'src/config/velox_network_config.dart';
export 'src/interceptors/cache_interceptor.dart';
export 'src/interceptors/logging_interceptor.dart';
export 'src/interceptors/velox_interceptor.dart';
export 'src/mock/velox_mock_http_client.dart';
export 'src/models/multipart_file.dart';
export 'src/models/velox_request.dart';
export 'src/models/velox_response.dart';
export 'src/queue/request_queue.dart';
export 'src/velox_http_client.dart';

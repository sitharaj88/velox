/// A high-performance HTTP client abstraction for Flutter.
///
/// Provides:
/// - Type-safe request/response handling with [Result] types
/// - Interceptor pipeline for request/response transformation
/// - Configurable retry logic with exponential backoff
/// - Circuit breaker pattern for fault tolerance
/// - Request cancellation support
library;

export 'src/config/velox_network_config.dart';
export 'src/interceptors/velox_interceptor.dart';
export 'src/models/velox_request.dart';
export 'src/models/velox_response.dart';
export 'src/velox_http_client.dart';

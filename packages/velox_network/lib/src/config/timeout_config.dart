/// Per-request timeout configuration that can override the client defaults.
///
/// Allows setting separate connect, send, and receive timeouts.
/// Any `null` values will fall back to the client's default configuration.
///
/// ```dart
/// final result = await client.get(
///   '/slow-endpoint',
///   timeout: TimeoutConfig(
///     connectTimeout: Duration(seconds: 5),
///     receiveTimeout: Duration(seconds: 60),
///   ),
/// );
/// ```
class TimeoutConfig {
  /// Creates a [TimeoutConfig].
  ///
  /// All parameters are optional. A `null` value means the client's
  /// default timeout will be used.
  const TimeoutConfig({
    this.connectTimeout,
    this.receiveTimeout,
    this.sendTimeout,
  });

  /// Timeout for establishing a connection.
  final Duration? connectTimeout;

  /// Timeout for receiving a response.
  final Duration? receiveTimeout;

  /// Timeout for sending the request body.
  final Duration? sendTimeout;

  /// Creates a copy with the given fields replaced.
  TimeoutConfig copyWith({
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
  }) => TimeoutConfig(
    connectTimeout: connectTimeout ?? this.connectTimeout,
    receiveTimeout: receiveTimeout ?? this.receiveTimeout,
    sendTimeout: sendTimeout ?? this.sendTimeout,
  );

  @override
  String toString() =>
      'TimeoutConfig(connect: $connectTimeout, '
      'receive: $receiveTimeout, send: $sendTimeout)';
}

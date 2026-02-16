import 'package:meta/meta.dart';

/// Configuration for [VeloxAuthManager].
///
/// Controls token refresh behavior, retry policy, and optional endpoint URLs
/// for login, refresh, and logout operations.
///
/// ```dart
/// final config = VeloxAuthConfig(
///   tokenRefreshThreshold: Duration(seconds: 120),
///   autoRefresh: true,
///   maxRefreshRetries: 5,
///   refreshUrl: '/auth/refresh',
/// );
/// ```
@immutable
class VeloxAuthConfig {
  /// Creates a [VeloxAuthConfig] with sensible defaults.
  ///
  /// - [tokenRefreshThreshold]: How early before expiry to trigger a refresh
  ///   (default: 60 seconds).
  /// - [autoRefresh]: Whether to automatically refresh expiring tokens
  ///   (default: true).
  /// - [maxRefreshRetries]: Maximum number of refresh retry attempts
  ///   (default: 3).
  /// - [refreshRetryDelay]: Delay between refresh retry attempts
  ///   (default: 1 second).
  /// - [loginUrl]: Optional endpoint URL for login.
  /// - [refreshUrl]: Optional endpoint URL for token refresh.
  /// - [logoutUrl]: Optional endpoint URL for logout.
  const VeloxAuthConfig({
    this.tokenRefreshThreshold = const Duration(seconds: 60),
    this.autoRefresh = true,
    this.maxRefreshRetries = 3,
    this.refreshRetryDelay = const Duration(seconds: 1),
    this.loginUrl,
    this.refreshUrl,
    this.logoutUrl,
  });

  /// How far in advance of token expiry to trigger a refresh.
  ///
  /// For example, a threshold of 60 seconds means tokens will be refreshed
  /// when they have less than 60 seconds until expiry.
  final Duration tokenRefreshThreshold;

  /// Whether to automatically refresh tokens when they are close to expiry.
  final bool autoRefresh;

  /// Maximum number of retry attempts for token refresh.
  final int maxRefreshRetries;

  /// Delay between refresh retry attempts.
  final Duration refreshRetryDelay;

  /// Optional endpoint URL for login operations.
  final String? loginUrl;

  /// Optional endpoint URL for token refresh operations.
  final String? refreshUrl;

  /// Optional endpoint URL for logout operations.
  final String? logoutUrl;

  /// Creates a copy of this config with the given fields replaced.
  VeloxAuthConfig copyWith({
    Duration? tokenRefreshThreshold,
    bool? autoRefresh,
    int? maxRefreshRetries,
    Duration? refreshRetryDelay,
    String? loginUrl,
    String? refreshUrl,
    String? logoutUrl,
  }) =>
      VeloxAuthConfig(
        tokenRefreshThreshold:
            tokenRefreshThreshold ?? this.tokenRefreshThreshold,
        autoRefresh: autoRefresh ?? this.autoRefresh,
        maxRefreshRetries: maxRefreshRetries ?? this.maxRefreshRetries,
        refreshRetryDelay: refreshRetryDelay ?? this.refreshRetryDelay,
        loginUrl: loginUrl ?? this.loginUrl,
        refreshUrl: refreshUrl ?? this.refreshUrl,
        logoutUrl: logoutUrl ?? this.logoutUrl,
      );

  @override
  String toString() =>
      'VeloxAuthConfig('
      'tokenRefreshThreshold: $tokenRefreshThreshold, '
      'autoRefresh: $autoRefresh, '
      'maxRefreshRetries: $maxRefreshRetries)';
}

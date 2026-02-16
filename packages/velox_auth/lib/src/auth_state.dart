import 'package:meta/meta.dart';

import 'package:velox_auth/src/token_pair.dart';

/// Represents the current authentication status.
///
/// Used by [VeloxAuthState] to indicate the phase of the authentication
/// lifecycle.
enum VeloxAuthStatus {
  /// The user is authenticated and has valid tokens.
  authenticated,

  /// The user is not authenticated (no tokens present).
  unauthenticated,

  /// The tokens are currently being refreshed.
  refreshing,

  /// The tokens have expired and automatic refresh is not available.
  expired,

  /// The authentication status has not yet been determined.
  unknown;

  /// Whether the user can be considered authenticated.
  ///
  /// Returns `true` for [authenticated] and [refreshing] statuses,
  /// since during a refresh the user still has a valid session.
  bool get isAuthenticated =>
      this == VeloxAuthStatus.authenticated ||
      this == VeloxAuthStatus.refreshing;

  /// Whether the user needs to log in.
  ///
  /// Returns `true` for [unauthenticated] and [expired] statuses.
  bool get needsLogin =>
      this == VeloxAuthStatus.unauthenticated ||
      this == VeloxAuthStatus.expired;
}

/// An immutable snapshot of the current authentication state.
///
/// Combines the [status] with the current [tokenPair] and optional
/// [userId]. The [timestamp] records when this state was created.
///
/// ```dart
/// final state = VeloxAuthState(
///   status: VeloxAuthStatus.authenticated,
///   tokenPair: tokens,
///   userId: 'user-123',
/// );
///
/// if (state.status.isAuthenticated) {
///   // Use state.tokenPair!.accessToken
/// }
/// ```
@immutable
class VeloxAuthState {
  /// Creates a [VeloxAuthState].
  ///
  /// The [timestamp] defaults to the current time if not provided.
  VeloxAuthState({
    required this.status,
    this.tokenPair,
    this.userId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// The current authentication status.
  final VeloxAuthStatus status;

  /// The current token pair, if available.
  final VeloxTokenPair? tokenPair;

  /// An optional user identifier associated with this session.
  final String? userId;

  /// The time when this state was created.
  final DateTime timestamp;

  /// Whether this state contains tokens.
  bool get hasTokens => tokenPair != null;

  /// Creates a copy of this state with the given fields replaced.
  VeloxAuthState copyWith({
    VeloxAuthStatus? status,
    VeloxTokenPair? tokenPair,
    String? userId,
    DateTime? timestamp,
  }) =>
      VeloxAuthState(
        status: status ?? this.status,
        tokenPair: tokenPair ?? this.tokenPair,
        userId: userId ?? this.userId,
        timestamp: timestamp ?? this.timestamp,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! VeloxAuthState) return false;
    return status == other.status &&
        tokenPair == other.tokenPair &&
        userId == other.userId &&
        timestamp == other.timestamp;
  }

  @override
  int get hashCode => Object.hash(status, tokenPair, userId, timestamp);

  @override
  String toString() =>
      'VeloxAuthState(status: $status, '
      'hasTokens: $hasTokens, '
      'userId: $userId)';
}

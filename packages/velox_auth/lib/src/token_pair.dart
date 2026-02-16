import 'package:meta/meta.dart';

/// An immutable representation of an OAuth2 token pair.
///
/// Contains the [accessToken] used for API authorization and an optional
/// [refreshToken] for obtaining new access tokens. Tracks token expiry
/// via [expiresAt] and supports OAuth2 scopes.
///
/// ```dart
/// final tokens = VeloxTokenPair(
///   accessToken: 'eyJhbGciOiJIUzI1NiIs...',
///   refreshToken: 'dGhpcyBpcyBhIHJlZnJlc2g...',
///   expiresAt: DateTime.now().add(Duration(hours: 1)),
///   scopes: ['read', 'write'],
/// );
///
/// if (tokens.isExpired) {
///   // Refresh the token
/// }
/// ```
@immutable
class VeloxTokenPair {
  /// Creates a [VeloxTokenPair].
  ///
  /// The [accessToken] is required. All other fields are optional:
  /// - [refreshToken] for obtaining new tokens
  /// - [expiresAt] for tracking token expiry
  /// - [tokenType] defaults to `'Bearer'`
  /// - [scopes] defaults to an empty list
  const VeloxTokenPair({
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.tokenType = 'Bearer',
    this.scopes = const [],
  });

  /// Creates a [VeloxTokenPair] from a JSON map.
  ///
  /// Expects keys: `accessToken`, `refreshToken`, `expiresAt`, `tokenType`,
  /// and `scopes`. The `expiresAt` value should be an ISO 8601 string.
  factory VeloxTokenPair.fromJson(Map<String, dynamic> json) =>
      VeloxTokenPair(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String?,
        expiresAt: json['expiresAt'] != null
            ? DateTime.parse(json['expiresAt'] as String)
            : null,
        tokenType: (json['tokenType'] as String?) ?? 'Bearer',
        scopes: json['scopes'] != null
            ? List<String>.from(json['scopes'] as List<dynamic>)
            : const [],
      );

  /// The access token used for API authorization.
  final String accessToken;

  /// The refresh token used to obtain new access tokens.
  final String? refreshToken;

  /// The date and time when the access token expires.
  final DateTime? expiresAt;

  /// The token type, typically `'Bearer'`.
  final String tokenType;

  /// The OAuth2 scopes granted by this token.
  final List<String> scopes;

  /// Whether the access token has expired.
  ///
  /// Returns `true` if [expiresAt] is set and is before the current time.
  /// Returns `false` if [expiresAt] is `null` (token never expires).
  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  /// Whether this token pair includes a refresh token.
  bool get hasRefreshToken => refreshToken != null;

  /// The time remaining until the access token expires.
  ///
  /// Returns `null` if [expiresAt] is not set.
  Duration? get timeUntilExpiry =>
      expiresAt?.difference(DateTime.now());

  /// Converts this token pair to a JSON map.
  ///
  /// The [expiresAt] is serialized as an ISO 8601 string.
  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'expiresAt': expiresAt?.toIso8601String(),
        'tokenType': tokenType,
        'scopes': scopes,
      };

  /// Creates a copy of this token pair with the given fields replaced.
  VeloxTokenPair copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    String? tokenType,
    List<String>? scopes,
  }) =>
      VeloxTokenPair(
        accessToken: accessToken ?? this.accessToken,
        refreshToken: refreshToken ?? this.refreshToken,
        expiresAt: expiresAt ?? this.expiresAt,
        tokenType: tokenType ?? this.tokenType,
        scopes: scopes ?? this.scopes,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! VeloxTokenPair) return false;
    return accessToken == other.accessToken &&
        refreshToken == other.refreshToken &&
        expiresAt == other.expiresAt &&
        tokenType == other.tokenType &&
        _listEquals(scopes, other.scopes);
  }

  @override
  int get hashCode => Object.hash(
        accessToken,
        refreshToken,
        expiresAt,
        tokenType,
        Object.hashAll(scopes),
      );

  @override
  String toString() =>
      'VeloxTokenPair(tokenType: $tokenType, '
      'hasRefreshToken: $hasRefreshToken, '
      'isExpired: $isExpired)';

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

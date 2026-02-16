import 'package:velox_auth/src/auth_exception.dart';
import 'package:velox_auth/src/token_pair.dart';
import 'package:velox_core/velox_core.dart';

/// Abstract interface for refreshing authentication tokens.
///
/// Implement this class to provide your own token refresh logic,
/// typically by calling your backend's refresh endpoint.
///
/// ```dart
/// class MyTokenRefresher extends VeloxTokenRefresher {
///   final VeloxHttpClient _client;
///
///   MyTokenRefresher(this._client);
///
///   @override
///   Future<Result<VeloxTokenPair, VeloxAuthException>> refreshToken(
///     VeloxTokenPair currentTokens,
///   ) async {
///     final result = await _client.post('/auth/refresh', body: {
///       'refresh_token': currentTokens.refreshToken,
///     });
///     return result.when(
///       success: (response) => Success(VeloxTokenPair.fromJson(
///         response.data as Map<String, dynamic>,
///       )),
///       failure: (error) => Failure(VeloxAuthException(
///         message: 'Token refresh failed',
///         statusCode: error.statusCode,
///       )),
///     );
///   }
/// }
/// ```
abstract class VeloxTokenRefresher {
  /// Refreshes the given [currentTokens] and returns the new token pair.
  ///
  /// Returns a [Success] with the new tokens on success, or a [Failure]
  /// with a [VeloxAuthException] describing what went wrong.
  Future<Result<VeloxTokenPair, VeloxAuthException>> refreshToken(
    VeloxTokenPair currentTokens,
  );
}

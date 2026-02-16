import 'package:velox_auth/src/auth_manager.dart';
import 'package:velox_network/velox_network.dart';

/// A network interceptor that automatically attaches authentication headers.
///
/// Reads the current access token from [VeloxAuthManager] and adds an
/// `Authorization` header to outgoing requests when the user is authenticated.
///
/// ```dart
/// final interceptor = VeloxAuthInterceptor(authManager: authManager);
/// final client = VeloxHttpClient(
///   config: VeloxNetworkConfig(
///     baseUrl: 'https://api.example.com',
///     interceptors: [interceptor],
///   ),
/// );
/// ```
class VeloxAuthInterceptor extends VeloxInterceptor {
  /// Creates a [VeloxAuthInterceptor].
  ///
  /// The [authManager] is used to check authentication status and
  /// retrieve the current access token.
  VeloxAuthInterceptor({required this.authManager});

  /// The auth manager providing token information.
  final VeloxAuthManager authManager;

  /// Adds an `Authorization` header if the user is authenticated.
  ///
  /// The header format is `{tokenType} {accessToken}`, typically
  /// `Bearer <token>`.
  @override
  Future<VeloxRequest> onRequest(VeloxRequest request) async {
    if (authManager.isAuthenticated) {
      final tokenPair = authManager.currentState.tokenPair;
      if (tokenPair != null) {
        return request.copyWith(
          headers: {
            ...request.headers,
            'Authorization': '${tokenPair.tokenType} ${tokenPair.accessToken}',
          },
        );
      }
    }
    return request;
  }

  /// Passes the response through without modification.
  @override
  Future<VeloxResponse<dynamic>> onResponse(
    VeloxResponse<dynamic> response,
  ) async => response;

  /// Passes the error through without modification.
  @override
  Future<Object> onError(Object error, VeloxRequest request) async => error;
}

/// Token management and OAuth2 authentication for Flutter.
///
/// Provides:
/// - [VeloxTokenPair] for token data
/// - [VeloxAuthState] and [VeloxAuthStatus] for auth state tracking
/// - [VeloxTokenStorage] for persistent token storage
/// - [VeloxAuthManager] for session lifecycle management
/// - [VeloxAuthInterceptor] for automatic auth headers
library;

export 'src/auth_config.dart';
export 'src/auth_exception.dart';
export 'src/auth_interceptor.dart';
export 'src/auth_manager.dart';
export 'src/auth_state.dart';
export 'src/token_pair.dart';
export 'src/token_refresher.dart';
export 'src/token_storage.dart';

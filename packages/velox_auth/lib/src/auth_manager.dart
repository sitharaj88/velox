import 'dart:async';

import 'package:velox_auth/src/auth_config.dart';
import 'package:velox_auth/src/auth_exception.dart';
import 'package:velox_auth/src/auth_state.dart';
import 'package:velox_auth/src/token_pair.dart';
import 'package:velox_auth/src/token_refresher.dart';
import 'package:velox_auth/src/token_storage.dart';
import 'package:velox_core/velox_core.dart';

/// Manages the authentication lifecycle including token persistence,
/// automatic refresh, and state change notifications.
///
/// The [VeloxAuthManager] coordinates between [VeloxTokenStorage] for
/// persistence, [VeloxTokenRefresher] for renewing tokens, and
/// [VeloxAuthConfig] for controlling refresh behavior.
///
/// ```dart
/// final manager = VeloxAuthManager(
///   tokenStorage: tokenStorage,
///   config: VeloxAuthConfig(),
///   tokenRefresher: myRefresher,
/// );
///
/// await manager.initialize();
///
/// manager.onAuthStateChanged.listen((state) {
///   print('Auth state: ${state.status}');
/// });
///
/// await manager.setTokens(tokens);
/// print(manager.isAuthenticated); // true
///
/// await manager.logout();
/// ```
class VeloxAuthManager {
  /// Creates a [VeloxAuthManager].
  ///
  /// - [tokenStorage] is used to persist and load tokens.
  /// - [config] controls refresh behavior and retry policy.
  /// - [tokenRefresher] is an optional strategy for refreshing tokens.
  ///   If not provided, [refresh] will return a failure.
  VeloxAuthManager({
    required this.tokenStorage,
    required this.config,
    this.tokenRefresher,
  });

  /// The storage layer for persisting tokens.
  final VeloxTokenStorage tokenStorage;

  /// The configuration for auth behavior.
  final VeloxAuthConfig config;

  /// The optional token refresh strategy.
  final VeloxTokenRefresher? tokenRefresher;

  final StreamController<VeloxAuthState> _stateController =
      StreamController<VeloxAuthState>.broadcast();

  VeloxAuthState _currentState = VeloxAuthState(
    status: VeloxAuthStatus.unknown,
  );

  /// The current authentication state.
  VeloxAuthState get currentState => _currentState;

  /// A broadcast stream of authentication state changes.
  ///
  /// Emits a new [VeloxAuthState] whenever the auth state changes,
  /// for example after [setTokens], [logout], or [refresh].
  Stream<VeloxAuthState> get onAuthStateChanged => _stateController.stream;

  /// Convenience getter for whether the user is currently authenticated.
  bool get isAuthenticated => _currentState.status.isAuthenticated;

  /// Convenience getter for the current access token, if available.
  String? get accessToken => _currentState.tokenPair?.accessToken;

  /// Whether the current tokens need to be refreshed.
  ///
  /// Returns `true` if tokens exist, have an expiry time, and that expiry
  /// is within the configured [VeloxAuthConfig.tokenRefreshThreshold].
  bool get needsRefresh {
    final tokenPair = _currentState.tokenPair;
    if (tokenPair == null) return false;
    final timeUntilExpiry = tokenPair.timeUntilExpiry;
    if (timeUntilExpiry == null) return false;
    return timeUntilExpiry <= config.tokenRefreshThreshold;
  }

  /// Initializes the auth manager by loading persisted tokens.
  ///
  /// If tokens are found in storage, the state is set to [VeloxAuthStatus.authenticated].
  /// Otherwise, the state is set to [VeloxAuthStatus.unauthenticated].
  Future<void> initialize() async {
    final tokens = await tokenStorage.loadTokens();
    if (tokens != null) {
      _updateState(
        VeloxAuthState(
          status: VeloxAuthStatus.authenticated,
          tokenPair: tokens,
        ),
      );
    } else {
      _updateState(
        VeloxAuthState(
          status: VeloxAuthStatus.unauthenticated,
        ),
      );
    }
  }

  /// Sets new tokens, persists them, and updates state to authenticated.
  ///
  /// This is typically called after a successful login or token exchange.
  Future<void> setTokens(VeloxTokenPair tokens) async {
    await tokenStorage.saveTokens(tokens);
    _updateState(
      VeloxAuthState(
        status: VeloxAuthStatus.authenticated,
        tokenPair: tokens,
      ),
    );
  }

  /// Attempts to refresh the current tokens using the [tokenRefresher].
  ///
  /// Returns a [Success] with the new tokens, or a [Failure] if refresh
  /// failed. Respects [VeloxAuthConfig.maxRefreshRetries] and
  /// [VeloxAuthConfig.refreshRetryDelay] for retry behavior.
  ///
  /// If no [tokenRefresher] is configured, returns a [Failure] immediately.
  /// If no current tokens exist, returns a [Failure].
  Future<Result<VeloxTokenPair, VeloxAuthException>> refresh() async {
    if (tokenRefresher == null) {
      return const Failure(
        VeloxAuthException(
          message: 'No token refresher configured',
          code: 'NO_REFRESHER',
        ),
      );
    }

    final currentTokens = _currentState.tokenPair;
    if (currentTokens == null) {
      return const Failure(
        VeloxAuthException(
          message: 'No tokens available to refresh',
          code: 'NO_TOKENS',
        ),
      );
    }

    _updateState(_currentState.copyWith(status: VeloxAuthStatus.refreshing));

    VeloxAuthException? lastError;

    for (var attempt = 0; attempt < config.maxRefreshRetries; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(config.refreshRetryDelay);
      }

      final result = await tokenRefresher!.refreshToken(currentTokens);

      switch (result) {
        case Success(:final value):
          await setTokens(value);
          return Success(value);
        case Failure(:final error):
          lastError = error;
      }
    }

    _updateState(
      VeloxAuthState(
        status: VeloxAuthStatus.expired,
        tokenPair: currentTokens,
      ),
    );

    return Failure(
      lastError ??
          const VeloxAuthException(
            message: 'Token refresh failed after retries',
            code: 'REFRESH_EXHAUSTED',
          ),
    );
  }

  /// Logs out the current user by clearing tokens and updating state.
  ///
  /// Removes all stored tokens and sets the state to
  /// [VeloxAuthStatus.unauthenticated].
  Future<void> logout() async {
    await tokenStorage.clearTokens();
    _updateState(
      VeloxAuthState(
        status: VeloxAuthStatus.unauthenticated,
      ),
    );
  }

  /// Disposes the auth manager and releases resources.
  ///
  /// After calling this, the [onAuthStateChanged] stream will be closed
  /// and no further state updates will be emitted.
  void dispose() {
    _stateController.close();
  }

  void _updateState(VeloxAuthState newState) {
    _currentState = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }
}

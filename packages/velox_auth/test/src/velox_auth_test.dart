import 'dart:async';

import 'package:test/test.dart';
import 'package:velox_auth/velox_auth.dart';
import 'package:velox_core/velox_core.dart';
import 'package:velox_network/velox_network.dart';
import 'package:velox_storage/velox_storage.dart';

/// A fake token refresher that succeeds with new tokens.
class _SuccessfulRefresher extends VeloxTokenRefresher {
  int callCount = 0;

  @override
  Future<Result<VeloxTokenPair, VeloxAuthException>> refreshToken(
    VeloxTokenPair currentTokens,
  ) async {
    callCount++;
    return Success(
      VeloxTokenPair(
        accessToken: 'refreshed_access_token',
        refreshToken: 'refreshed_refresh_token',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        scopes: currentTokens.scopes,
      ),
    );
  }
}

/// A fake token refresher that always fails.
class _FailingRefresher extends VeloxTokenRefresher {
  int callCount = 0;

  @override
  Future<Result<VeloxTokenPair, VeloxAuthException>> refreshToken(
    VeloxTokenPair currentTokens,
  ) async {
    callCount++;
    return const Failure(
      VeloxAuthException(
        message: 'Refresh failed',
        code: 'REFRESH_ERROR',
        statusCode: 401,
      ),
    );
  }
}

void main() {
  // ---------------------------------------------------------------------------
  // VeloxTokenPair
  // ---------------------------------------------------------------------------
  group('VeloxTokenPair', () {
    test('constructs with required and default fields', () {
      const pair = VeloxTokenPair(accessToken: 'abc123');
      expect(pair.accessToken, 'abc123');
      expect(pair.refreshToken, isNull);
      expect(pair.expiresAt, isNull);
      expect(pair.tokenType, 'Bearer');
      expect(pair.scopes, isEmpty);
    });

    test('constructs with all fields', () {
      final expiresAt = DateTime(2025, 6, 15, 12);
      final pair = VeloxTokenPair(
        accessToken: 'access',
        refreshToken: 'refresh',
        expiresAt: expiresAt,
        tokenType: 'MAC',
        scopes: const ['read', 'write'],
      );
      expect(pair.accessToken, 'access');
      expect(pair.refreshToken, 'refresh');
      expect(pair.expiresAt, expiresAt);
      expect(pair.tokenType, 'MAC');
      expect(pair.scopes, ['read', 'write']);
    });

    test('isExpired returns true for past date', () {
      final pair = VeloxTokenPair(
        accessToken: 'token',
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(pair.isExpired, isTrue);
    });

    test('isExpired returns false for future date', () {
      final pair = VeloxTokenPair(
        accessToken: 'token',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(pair.isExpired, isFalse);
    });

    test('isExpired returns false when expiresAt is null', () {
      const pair = VeloxTokenPair(accessToken: 'token');
      expect(pair.isExpired, isFalse);
    });

    test('hasRefreshToken returns true when refresh token exists', () {
      const pair = VeloxTokenPair(
        accessToken: 'token',
        refreshToken: 'refresh',
      );
      expect(pair.hasRefreshToken, isTrue);
    });

    test('hasRefreshToken returns false when refresh token is null', () {
      const pair = VeloxTokenPair(accessToken: 'token');
      expect(pair.hasRefreshToken, isFalse);
    });

    test('timeUntilExpiry returns null when expiresAt is null', () {
      const pair = VeloxTokenPair(accessToken: 'token');
      expect(pair.timeUntilExpiry, isNull);
    });

    test('timeUntilExpiry returns positive duration for future expiry', () {
      final pair = VeloxTokenPair(
        accessToken: 'token',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      final duration = pair.timeUntilExpiry!;
      expect(duration.inMinutes, greaterThanOrEqualTo(59));
    });

    test('timeUntilExpiry returns negative duration for past expiry', () {
      final pair = VeloxTokenPair(
        accessToken: 'token',
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      final duration = pair.timeUntilExpiry!;
      expect(duration.isNegative, isTrue);
    });

    test('toJson serializes all fields', () {
      final expiresAt = DateTime(2025, 6, 15, 12);
      final pair = VeloxTokenPair(
        accessToken: 'access',
        refreshToken: 'refresh',
        expiresAt: expiresAt,
        scopes: const ['read'],
      );
      final json = pair.toJson();
      expect(json['accessToken'], 'access');
      expect(json['refreshToken'], 'refresh');
      expect(json['expiresAt'], expiresAt.toIso8601String());
      expect(json['tokenType'], 'Bearer');
      expect(json['scopes'], ['read']);
    });

    test('fromJson deserializes all fields', () {
      final json = <String, dynamic>{
        'accessToken': 'access',
        'refreshToken': 'refresh',
        'expiresAt': '2025-06-15T12:00:00.000',
        'tokenType': 'Bearer',
        'scopes': <String>['read'],
      };
      final pair = VeloxTokenPair.fromJson(json);
      expect(pair.accessToken, 'access');
      expect(pair.refreshToken, 'refresh');
      expect(pair.expiresAt, DateTime(2025, 6, 15, 12));
      expect(pair.tokenType, 'Bearer');
      expect(pair.scopes, ['read']);
    });

    test('fromJson handles missing optional fields', () {
      final json = <String, dynamic>{'accessToken': 'access'};
      final pair = VeloxTokenPair.fromJson(json);
      expect(pair.accessToken, 'access');
      expect(pair.refreshToken, isNull);
      expect(pair.expiresAt, isNull);
      expect(pair.tokenType, 'Bearer');
      expect(pair.scopes, isEmpty);
    });

    test('toJson/fromJson round-trip preserves data', () {
      final original = VeloxTokenPair(
        accessToken: 'access',
        refreshToken: 'refresh',
        expiresAt: DateTime(2025, 6, 15, 12),
        scopes: const ['read', 'write'],
      );
      final restored = VeloxTokenPair.fromJson(original.toJson());
      expect(restored, equals(original));
    });

    test('equality works for identical token pairs', () {
      final a = VeloxTokenPair(
        accessToken: 'access',
        refreshToken: 'refresh',
        expiresAt: DateTime(2025),
        scopes: const ['a'],
      );
      final b = VeloxTokenPair(
        accessToken: 'access',
        refreshToken: 'refresh',
        expiresAt: DateTime(2025),
        scopes: const ['a'],
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('equality fails for different token pairs', () {
      const a = VeloxTokenPair(accessToken: 'abc');
      const b = VeloxTokenPair(accessToken: 'xyz');
      expect(a, isNot(equals(b)));
    });

    test('copyWith creates modified copy', () {
      const original = VeloxTokenPair(accessToken: 'old');
      final copy = original.copyWith(accessToken: 'new');
      expect(copy.accessToken, 'new');
      expect(copy.tokenType, original.tokenType);
    });

    test('toString returns meaningful representation', () {
      const pair = VeloxTokenPair(accessToken: 'token');
      expect(pair.toString(), contains('VeloxTokenPair'));
      expect(pair.toString(), contains('Bearer'));
    });
  });

  // ---------------------------------------------------------------------------
  // VeloxAuthStatus
  // ---------------------------------------------------------------------------
  group('VeloxAuthStatus', () {
    test('has all expected values', () {
      expect(VeloxAuthStatus.values, hasLength(5));
      expect(
        VeloxAuthStatus.values,
        containsAll([
          VeloxAuthStatus.authenticated,
          VeloxAuthStatus.unauthenticated,
          VeloxAuthStatus.refreshing,
          VeloxAuthStatus.expired,
          VeloxAuthStatus.unknown,
        ]),
      );
    });

    test('isAuthenticated returns true for authenticated', () {
      expect(VeloxAuthStatus.authenticated.isAuthenticated, isTrue);
    });

    test('isAuthenticated returns true for refreshing', () {
      expect(VeloxAuthStatus.refreshing.isAuthenticated, isTrue);
    });

    test('isAuthenticated returns false for unauthenticated', () {
      expect(VeloxAuthStatus.unauthenticated.isAuthenticated, isFalse);
    });

    test('isAuthenticated returns false for expired', () {
      expect(VeloxAuthStatus.expired.isAuthenticated, isFalse);
    });

    test('needsLogin returns true for unauthenticated', () {
      expect(VeloxAuthStatus.unauthenticated.needsLogin, isTrue);
    });

    test('needsLogin returns true for expired', () {
      expect(VeloxAuthStatus.expired.needsLogin, isTrue);
    });

    test('needsLogin returns false for authenticated', () {
      expect(VeloxAuthStatus.authenticated.needsLogin, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // VeloxAuthState
  // ---------------------------------------------------------------------------
  group('VeloxAuthState', () {
    test('constructs with required fields', () {
      final state = VeloxAuthState(status: VeloxAuthStatus.unauthenticated);
      expect(state.status, VeloxAuthStatus.unauthenticated);
      expect(state.tokenPair, isNull);
      expect(state.userId, isNull);
      expect(state.timestamp, isNotNull);
    });

    test('hasTokens returns true when tokenPair is present', () {
      final state = VeloxAuthState(
        status: VeloxAuthStatus.authenticated,
        tokenPair: const VeloxTokenPair(accessToken: 'token'),
      );
      expect(state.hasTokens, isTrue);
    });

    test('hasTokens returns false when tokenPair is null', () {
      final state = VeloxAuthState(status: VeloxAuthStatus.unauthenticated);
      expect(state.hasTokens, isFalse);
    });

    test('equality works for identical states', () {
      final timestamp = DateTime(2025);
      final a = VeloxAuthState(
        status: VeloxAuthStatus.unauthenticated,
        timestamp: timestamp,
      );
      final b = VeloxAuthState(
        status: VeloxAuthStatus.unauthenticated,
        timestamp: timestamp,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('copyWith creates modified copy', () {
      final original = VeloxAuthState(
        status: VeloxAuthStatus.unauthenticated,
      );
      final copy = original.copyWith(
        status: VeloxAuthStatus.authenticated,
        userId: 'user-1',
      );
      expect(copy.status, VeloxAuthStatus.authenticated);
      expect(copy.userId, 'user-1');
      expect(copy.timestamp, original.timestamp);
    });

    test('toString returns meaningful representation', () {
      final state = VeloxAuthState(
        status: VeloxAuthStatus.authenticated,
        userId: 'user-42',
      );
      expect(state.toString(), contains('VeloxAuthState'));
      expect(state.toString(), contains('authenticated'));
    });
  });

  // ---------------------------------------------------------------------------
  // VeloxAuthConfig
  // ---------------------------------------------------------------------------
  group('VeloxAuthConfig', () {
    test('constructs with defaults', () {
      const config = VeloxAuthConfig();
      expect(config.tokenRefreshThreshold, const Duration(seconds: 60));
      expect(config.autoRefresh, isTrue);
      expect(config.maxRefreshRetries, 3);
      expect(config.refreshRetryDelay, const Duration(seconds: 1));
      expect(config.loginUrl, isNull);
      expect(config.refreshUrl, isNull);
      expect(config.logoutUrl, isNull);
    });

    test('constructs with custom values', () {
      const config = VeloxAuthConfig(
        tokenRefreshThreshold: Duration(seconds: 120),
        autoRefresh: false,
        maxRefreshRetries: 5,
        refreshRetryDelay: Duration(seconds: 2),
        loginUrl: '/login',
        refreshUrl: '/refresh',
        logoutUrl: '/logout',
      );
      expect(config.tokenRefreshThreshold, const Duration(seconds: 120));
      expect(config.autoRefresh, isFalse);
      expect(config.maxRefreshRetries, 5);
      expect(config.refreshRetryDelay, const Duration(seconds: 2));
      expect(config.loginUrl, '/login');
      expect(config.refreshUrl, '/refresh');
      expect(config.logoutUrl, '/logout');
    });

    test('copyWith creates modified copy', () {
      const original = VeloxAuthConfig();
      final copy = original.copyWith(
        autoRefresh: false,
        maxRefreshRetries: 10,
      );
      expect(copy.autoRefresh, isFalse);
      expect(copy.maxRefreshRetries, 10);
      expect(copy.tokenRefreshThreshold, original.tokenRefreshThreshold);
    });

    test('toString returns meaningful representation', () {
      const config = VeloxAuthConfig();
      expect(config.toString(), contains('VeloxAuthConfig'));
      expect(config.toString(), contains('autoRefresh'));
    });
  });

  // ---------------------------------------------------------------------------
  // VeloxTokenStorage
  // ---------------------------------------------------------------------------
  group('VeloxTokenStorage', () {
    late VeloxStorage storage;
    late VeloxTokenStorage tokenStorage;

    setUp(() {
      storage = VeloxStorage(adapter: MemoryStorageAdapter());
      tokenStorage = VeloxTokenStorage(storage: storage);
    });

    test('saveTokens and loadTokens round-trip', () async {
      final tokens = VeloxTokenPair(
        accessToken: 'access',
        refreshToken: 'refresh',
        expiresAt: DateTime(2025, 6, 15, 12),
        scopes: const ['read', 'write'],
      );
      await tokenStorage.saveTokens(tokens);
      final loaded = await tokenStorage.loadTokens();
      expect(loaded, isNotNull);
      expect(loaded!.accessToken, 'access');
      expect(loaded.refreshToken, 'refresh');
      expect(loaded.expiresAt, DateTime(2025, 6, 15, 12));
      expect(loaded.scopes, ['read', 'write']);
    });

    test('loadTokens returns null when empty', () async {
      final loaded = await tokenStorage.loadTokens();
      expect(loaded, isNull);
    });

    test('clearTokens removes stored tokens', () async {
      await tokenStorage.saveTokens(
        const VeloxTokenPair(accessToken: 'token'),
      );
      await tokenStorage.clearTokens();
      final loaded = await tokenStorage.loadTokens();
      expect(loaded, isNull);
    });

    test('hasTokens returns true when tokens exist', () async {
      await tokenStorage.saveTokens(
        const VeloxTokenPair(accessToken: 'token'),
      );
      expect(await tokenStorage.hasTokens(), isTrue);
    });

    test('hasTokens returns false when no tokens', () async {
      expect(await tokenStorage.hasTokens(), isFalse);
    });

    test('uses custom key prefix', () async {
      final customStorage = VeloxTokenStorage(
        storage: storage,
        keyPrefix: 'my_app',
      );
      await customStorage.saveTokens(
        const VeloxTokenPair(accessToken: 'token'),
      );
      // Verify the token is stored under the custom key
      expect(await storage.containsKey('my_app_tokens'), isTrue);
      expect(await storage.containsKey('velox_auth_tokens'), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // VeloxAuthManager
  // ---------------------------------------------------------------------------
  group('VeloxAuthManager', () {
    late VeloxStorage storage;
    late VeloxTokenStorage tokenStorage;
    late VeloxAuthManager manager;

    setUp(() {
      storage = VeloxStorage(adapter: MemoryStorageAdapter());
      tokenStorage = VeloxTokenStorage(storage: storage);
      manager = VeloxAuthManager(
        tokenStorage: tokenStorage,
        config: const VeloxAuthConfig(),
      );
    });

    tearDown(() {
      manager.dispose();
    });

    test('initialize with no stored tokens sets unauthenticated', () async {
      await manager.initialize();
      expect(manager.currentState.status, VeloxAuthStatus.unauthenticated);
      expect(manager.isAuthenticated, isFalse);
    });

    test('initialize with stored tokens sets authenticated', () async {
      await tokenStorage.saveTokens(
        const VeloxTokenPair(accessToken: 'stored_token'),
      );
      await manager.initialize();
      expect(manager.currentState.status, VeloxAuthStatus.authenticated);
      expect(manager.isAuthenticated, isTrue);
      expect(manager.accessToken, 'stored_token');
    });

    test('setTokens updates state to authenticated', () async {
      await manager.initialize();
      await manager.setTokens(
        const VeloxTokenPair(accessToken: 'new_token'),
      );
      expect(manager.currentState.status, VeloxAuthStatus.authenticated);
      expect(manager.accessToken, 'new_token');
    });

    test('setTokens persists tokens', () async {
      await manager.initialize();
      await manager.setTokens(
        const VeloxTokenPair(accessToken: 'persisted'),
      );
      final loaded = await tokenStorage.loadTokens();
      expect(loaded, isNotNull);
      expect(loaded!.accessToken, 'persisted');
    });

    test('logout clears tokens and sets unauthenticated', () async {
      await manager.initialize();
      await manager.setTokens(
        const VeloxTokenPair(accessToken: 'token'),
      );
      await manager.logout();
      expect(manager.currentState.status, VeloxAuthStatus.unauthenticated);
      expect(manager.isAuthenticated, isFalse);
      expect(manager.accessToken, isNull);
      expect(await tokenStorage.hasTokens(), isFalse);
    });

    test('isAuthenticated convenience getter works', () async {
      await manager.initialize();
      expect(manager.isAuthenticated, isFalse);

      await manager.setTokens(
        const VeloxTokenPair(accessToken: 'token'),
      );
      expect(manager.isAuthenticated, isTrue);
    });

    test('accessToken convenience getter works', () async {
      await manager.initialize();
      expect(manager.accessToken, isNull);

      await manager.setTokens(
        const VeloxTokenPair(accessToken: 'my_token'),
      );
      expect(manager.accessToken, 'my_token');
    });

    test('onAuthStateChanged emits state changes', () async {
      final states = <VeloxAuthState>[];
      manager.onAuthStateChanged.listen(states.add);

      await manager.initialize();
      await manager.setTokens(
        const VeloxTokenPair(accessToken: 'token'),
      );
      await manager.logout();

      // Allow stream events to propagate
      await Future<void>.delayed(Duration.zero);

      expect(states, hasLength(3));
      expect(states[0].status, VeloxAuthStatus.unauthenticated);
      expect(states[1].status, VeloxAuthStatus.authenticated);
      expect(states[2].status, VeloxAuthStatus.unauthenticated);
    });

    test('refresh succeeds with successful refresher', () async {
      final refresher = _SuccessfulRefresher();
      final refreshManager = VeloxAuthManager(
        tokenStorage: tokenStorage,
        config: const VeloxAuthConfig(),
        tokenRefresher: refresher,
      );

      await refreshManager.setTokens(
        const VeloxTokenPair(
          accessToken: 'old_token',
          refreshToken: 'old_refresh',
        ),
      );

      final result = await refreshManager.refresh();

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.accessToken, 'refreshed_access_token');
      expect(refreshManager.accessToken, 'refreshed_access_token');
      expect(
        refreshManager.currentState.status,
        VeloxAuthStatus.authenticated,
      );
      expect(refresher.callCount, 1);

      refreshManager.dispose();
    });

    test('refresh fails with failing refresher', () async {
      final refresher = _FailingRefresher();
      final refreshManager = VeloxAuthManager(
        tokenStorage: tokenStorage,
        config: const VeloxAuthConfig(maxRefreshRetries: 2),
        tokenRefresher: refresher,
      );

      await refreshManager.setTokens(
        const VeloxTokenPair(accessToken: 'old_token'),
      );

      final result = await refreshManager.refresh();

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull!.code, 'REFRESH_ERROR');
      expect(refreshManager.currentState.status, VeloxAuthStatus.expired);
      expect(refresher.callCount, 2);

      refreshManager.dispose();
    });

    test('refresh fails when no refresher configured', () async {
      await manager.setTokens(
        const VeloxTokenPair(accessToken: 'token'),
      );
      final result = await manager.refresh();
      expect(result.isFailure, isTrue);
      expect(result.errorOrNull!.code, 'NO_REFRESHER');
    });

    test('refresh fails when no tokens available', () async {
      final refreshManager = VeloxAuthManager(
        tokenStorage: tokenStorage,
        config: const VeloxAuthConfig(),
        tokenRefresher: _SuccessfulRefresher(),
      );
      await refreshManager.initialize();

      final result = await refreshManager.refresh();
      expect(result.isFailure, isTrue);
      expect(result.errorOrNull!.code, 'NO_TOKENS');

      refreshManager.dispose();
    });

    test('needsRefresh detects tokens close to expiry', () async {
      await manager.setTokens(
        VeloxTokenPair(
          accessToken: 'token',
          expiresAt: DateTime.now().add(const Duration(seconds: 30)),
        ),
      );
      // Within 60-second threshold
      expect(manager.needsRefresh, isTrue);
    });

    test('needsRefresh returns false for tokens far from expiry', () async {
      await manager.setTokens(
        VeloxTokenPair(
          accessToken: 'token',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        ),
      );
      expect(manager.needsRefresh, isFalse);
    });

    test('needsRefresh returns false when no tokens', () async {
      await manager.initialize();
      expect(manager.needsRefresh, isFalse);
    });

    test('needsRefresh returns false when no expiresAt', () async {
      await manager.setTokens(
        const VeloxTokenPair(accessToken: 'token'),
      );
      expect(manager.needsRefresh, isFalse);
    });

    test('dispose closes the stream controller', () async {
      manager.dispose();

      // After dispose, subscribing should still work (broadcast stream)
      // but no new events should arrive
      final completer = Completer<bool>();
      manager.onAuthStateChanged.listen(
        (_) {},
        onDone: () => completer.complete(true),
      );

      expect(await completer.future, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // VeloxAuthInterceptor
  // ---------------------------------------------------------------------------
  group('VeloxAuthInterceptor', () {
    late VeloxStorage storage;
    late VeloxTokenStorage tokenStorage;
    late VeloxAuthManager manager;
    late VeloxAuthInterceptor interceptor;

    setUp(() {
      storage = VeloxStorage(adapter: MemoryStorageAdapter());
      tokenStorage = VeloxTokenStorage(storage: storage);
      manager = VeloxAuthManager(
        tokenStorage: tokenStorage,
        config: const VeloxAuthConfig(),
      );
      interceptor = VeloxAuthInterceptor(authManager: manager);
    });

    tearDown(() {
      manager.dispose();
    });

    test('adds Authorization header when authenticated', () async {
      await manager.setTokens(
        const VeloxTokenPair(accessToken: 'my_token'),
      );

      final request = VeloxRequest(method: HttpMethod.get, path: '/api/data');
      final modified = await interceptor.onRequest(request);

      expect(modified.headers['Authorization'], 'Bearer my_token');
    });

    test('skips Authorization header when not authenticated', () async {
      await manager.initialize();

      final request = VeloxRequest(method: HttpMethod.get, path: '/api/data');
      final modified = await interceptor.onRequest(request);

      expect(modified.headers.containsKey('Authorization'), isFalse);
    });

    test('preserves existing request headers', () async {
      await manager.setTokens(
        const VeloxTokenPair(accessToken: 'token'),
      );

      final request = VeloxRequest(
        method: HttpMethod.get,
        path: '/api/data',
        headers: const {'Accept': 'application/json'},
      );
      final modified = await interceptor.onRequest(request);

      expect(modified.headers['Accept'], 'application/json');
      expect(modified.headers['Authorization'], 'Bearer token');
    });

    test('onResponse passes through unchanged', () async {
      final request = VeloxRequest(method: HttpMethod.get, path: '/test');
      final response = VeloxResponse<dynamic>(
        statusCode: 200,
        request: request,
        data: 'ok',
      );
      final result = await interceptor.onResponse(response);
      expect(identical(result, response), isTrue);
    });

    test('onError passes through unchanged', () async {
      final request = VeloxRequest(method: HttpMethod.get, path: '/test');
      final error = Exception('test error');
      final result = await interceptor.onError(error, request);
      expect(identical(result, error), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // VeloxAuthException
  // ---------------------------------------------------------------------------
  group('VeloxAuthException', () {
    test('creates with required message', () {
      const exception = VeloxAuthException(message: 'Auth failed');
      expect(exception.message, 'Auth failed');
      expect(exception.code, isNull);
      expect(exception.statusCode, isNull);
      expect(exception.cause, isNull);
    });

    test('creates with all fields', () {
      const exception = VeloxAuthException(
        message: 'Unauthorized',
        code: 'UNAUTHORIZED',
        statusCode: 401,
      );
      expect(exception.message, 'Unauthorized');
      expect(exception.code, 'UNAUTHORIZED');
      expect(exception.statusCode, 401);
    });

    test('toString includes code and status code', () {
      const exception = VeloxAuthException(
        message: 'Token expired',
        code: 'TOKEN_EXPIRED',
        statusCode: 401,
      );
      final str = exception.toString();
      expect(str, contains('VeloxAuthException'));
      expect(str, contains('TOKEN_EXPIRED'));
      expect(str, contains('401'));
      expect(str, contains('Token expired'));
    });

    test('toString includes cause when present', () {
      const exception = VeloxAuthException(
        message: 'Auth error',
        cause: 'original error',
      );
      expect(exception.toString(), contains('caused by: original error'));
    });

    test('toString minimal for message-only exception', () {
      const exception = VeloxAuthException(message: 'Simple error');
      expect(exception.toString(), 'VeloxAuthException: Simple error');
    });

    test('is a VeloxException', () {
      const exception = VeloxAuthException(message: 'test');
      expect(exception, isA<VeloxException>());
    });
  });
}

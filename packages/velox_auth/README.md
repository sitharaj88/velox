# velox_auth

Token management and OAuth2 authentication for Flutter applications. Part of the [Velox](https://github.com/velox-flutter/velox) plugin collection.

## Features

- Immutable token pair model with expiry tracking
- Persistent token storage via `velox_storage`
- Authentication state management with stream-based notifications
- Automatic token refresh with configurable retry policy
- Network interceptor for automatic `Authorization` headers

## Getting Started

Add `velox_auth` to your `pubspec.yaml`:

```yaml
dependencies:
  velox_auth:
    path: ../velox_auth
```

## Usage

```dart
import 'package:velox_auth/velox_auth.dart';
import 'package:velox_storage/velox_storage.dart';

// Set up storage and auth manager
final storage = VeloxStorage(adapter: MemoryStorageAdapter());
final tokenStorage = VeloxTokenStorage(storage: storage);
final authManager = VeloxAuthManager(
  tokenStorage: tokenStorage,
  config: VeloxAuthConfig(),
);

// Initialize (loads persisted tokens)
await authManager.initialize();

// Listen for auth state changes
authManager.onAuthStateChanged.listen((state) {
  print('Auth status: ${state.status}');
});

// Set tokens after login
await authManager.setTokens(VeloxTokenPair(
  accessToken: 'your-access-token',
  refreshToken: 'your-refresh-token',
  expiresAt: DateTime.now().add(Duration(hours: 1)),
));

// Check authentication
print(authManager.isAuthenticated); // true

// Add auth headers to network requests
final interceptor = VeloxAuthInterceptor(authManager: authManager);

// Logout
await authManager.logout();
```

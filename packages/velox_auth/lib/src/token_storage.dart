import 'package:velox_auth/src/token_pair.dart';
import 'package:velox_storage/velox_storage.dart';

/// Persists [VeloxTokenPair] data using [VeloxStorage].
///
/// Tokens are serialized as JSON and stored under a configurable key prefix.
/// This allows multiple auth sessions to be stored independently.
///
/// ```dart
/// final storage = VeloxStorage(adapter: MemoryStorageAdapter());
/// final tokenStorage = VeloxTokenStorage(storage: storage);
///
/// await tokenStorage.saveTokens(tokens);
/// final loaded = await tokenStorage.loadTokens();
/// ```
class VeloxTokenStorage {
  /// Creates a [VeloxTokenStorage].
  ///
  /// Uses [storage] as the underlying persistence layer and [keyPrefix]
  /// to namespace the storage keys (default: `'velox_auth'`).
  VeloxTokenStorage({
    required this.storage,
    this.keyPrefix = 'velox_auth',
  });

  /// The underlying storage instance.
  final VeloxStorage storage;

  /// Prefix for storage keys to avoid collisions.
  final String keyPrefix;

  /// The full storage key used for token data.
  String get _tokensKey => '${keyPrefix}_tokens';

  /// Saves a [VeloxTokenPair] to persistent storage.
  ///
  /// The tokens are serialized to JSON before being stored.
  Future<void> saveTokens(VeloxTokenPair tokens) async {
    await storage.setJson(_tokensKey, tokens.toJson());
  }

  /// Loads a [VeloxTokenPair] from persistent storage.
  ///
  /// Returns `null` if no tokens are stored or if the stored data
  /// cannot be deserialized.
  Future<VeloxTokenPair?> loadTokens() async {
    final json = await storage.getJson(_tokensKey);
    if (json == null) return null;
    try {
      return VeloxTokenPair.fromJson(json);
    } on Object {
      return null;
    }
  }

  /// Removes all stored tokens from persistent storage.
  Future<void> clearTokens() async {
    await storage.remove(_tokensKey);
  }

  /// Checks whether tokens are stored.
  Future<bool> hasTokens() async =>
      storage.containsKey(_tokensKey);
}

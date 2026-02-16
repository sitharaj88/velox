/// Interface for storage backends.
///
/// Implement this to create custom storage adapters (e.g., SharedPreferences,
/// Hive, SQLite).
abstract class StorageAdapter {
  /// Reads a value by [key]. Returns `null` if not found.
  Future<String?> read(String key);

  /// Writes a [value] for the given [key].
  Future<void> write(String key, String value);

  /// Removes a value by [key].
  Future<void> remove(String key);

  /// Returns all keys in the storage.
  Future<List<String>> keys();

  /// Clears all values from the storage.
  Future<void> clear();

  /// Returns `true` if the [key] exists in storage.
  Future<bool> containsKey(String key);

  /// Disposes of any resources held by the adapter.
  Future<void> dispose();
}

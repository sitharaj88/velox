/// Defines the observer interface for monitoring storage operations.
///
/// Implement this to receive notifications about all read/write/remove
/// operations on a storage instance. Useful for analytics, debugging,
/// and auditing.
///
/// ```dart
/// class LoggingObserver extends StorageObserver {
///   @override
///   void onRead(String key, {String? value}) {
///     print('Read: $key -> $value');
///   }
///
///   @override
///   void onWrite(String key, String value) {
///     print('Write: $key -> $value');
///   }
/// }
/// ```
abstract class StorageObserver {
  /// Called when a value is read from storage.
  ///
  /// [key] is the storage key that was read.
  /// [value] is the value that was read, or `null` if not found.
  void onRead(String key, {String? value});

  /// Called when a value is written to storage.
  ///
  /// [key] is the storage key that was written.
  /// [value] is the value that was written.
  void onWrite(String key, String value);

  /// Called when a value is removed from storage.
  ///
  /// [key] is the storage key that was removed.
  void onRemove(String key);

  /// Called when all values are cleared from storage.
  void onClear();

  /// Called when a batch operation starts.
  void onBatchStart() {}

  /// Called when a batch operation completes.
  ///
  /// [operationCount] is the number of operations in the batch.
  /// [success] indicates whether the batch completed successfully.
  void onBatchComplete({required int operationCount, required bool success}) {}
}

/// A no-op observer that ignores all events.
///
/// Extend this class to override only the methods you care about.
class NoOpStorageObserver extends StorageObserver {
  @override
  void onRead(String key, {String? value}) {}

  @override
  void onWrite(String key, String value) {}

  @override
  void onRemove(String key) {}

  @override
  void onClear() {}
}

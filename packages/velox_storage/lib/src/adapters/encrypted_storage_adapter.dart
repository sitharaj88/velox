import 'dart:convert';

import 'package:velox_storage/src/adapters/storage_adapter.dart';

/// A storage adapter that encrypts/decrypts values using XOR cipher.
///
/// **WARNING**: This uses a simple XOR cipher for demonstration purposes only.
/// Do NOT use this for production cryptographic needs. Replace the [encrypt]
/// and [decrypt] methods with a proper encryption library (e.g., encrypt,
/// cryptography) for real-world use.
///
/// ```dart
/// final adapter = EncryptedStorageAdapter(
///   adapter: MemoryStorageAdapter(),
///   encryptionKey: 'my-secret-key',
/// );
///
/// await adapter.write('token', 'sensitive-data');
/// // Value is stored encrypted in the underlying adapter
/// ```
class EncryptedStorageAdapter implements StorageAdapter {
  /// Creates an [EncryptedStorageAdapter].
  ///
  /// [adapter] is the underlying storage adapter.
  /// [encryptionKey] is the key used for XOR encryption.
  EncryptedStorageAdapter({
    required this.adapter,
    required this.encryptionKey,
  });

  /// The underlying storage adapter.
  final StorageAdapter adapter;

  /// The encryption key.
  final String encryptionKey;

  /// Encrypts a plaintext value using XOR cipher + base64 encoding.
  ///
  /// This is for demonstration only. Replace with proper encryption
  /// for production use.
  String encrypt(String plaintext) {
    final keyBytes = utf8.encode(encryptionKey);
    final textBytes = utf8.encode(plaintext);
    final encrypted = List<int>.generate(
      textBytes.length,
      (i) => textBytes[i] ^ keyBytes[i % keyBytes.length],
    );
    return base64Encode(encrypted);
  }

  /// Decrypts a value that was encrypted with [encrypt].
  String decrypt(String ciphertext) {
    final keyBytes = utf8.encode(encryptionKey);
    final encrypted = base64Decode(ciphertext);
    final decrypted = List<int>.generate(
      encrypted.length,
      (i) => encrypted[i] ^ keyBytes[i % keyBytes.length],
    );
    return utf8.decode(decrypted);
  }

  @override
  Future<String?> read(String key) async {
    final encrypted = await adapter.read(key);
    if (encrypted == null) return null;
    return decrypt(encrypted);
  }

  @override
  Future<void> write(String key, String value) =>
      adapter.write(key, encrypt(value));

  @override
  Future<void> remove(String key) => adapter.remove(key);

  @override
  Future<List<String>> keys() => adapter.keys();

  @override
  Future<void> clear() => adapter.clear();

  @override
  Future<bool> containsKey(String key) => adapter.containsKey(key);

  @override
  Future<void> dispose() => adapter.dispose();
}

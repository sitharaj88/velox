import 'dart:convert';

/// Wraps a stored value with an optional time-to-live (TTL) expiry.
///
/// When [expiresAt] is set, the entry is considered expired after that time.
class TtlEntry {
  /// Creates a [TtlEntry].
  const TtlEntry({
    required this.value,
    this.expiresAt,
  });

  /// Creates a [TtlEntry] from a JSON string.
  factory TtlEntry.fromJson(String jsonString) {
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    return TtlEntry(
      value: map['value'] as String,
      expiresAt: map['expiresAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['expiresAt'] as int)
          : null,
    );
  }

  /// The stored value.
  final String value;

  /// When this entry expires. `null` means no expiry.
  final DateTime? expiresAt;

  /// Whether this entry has expired.
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Serializes this entry to a JSON string.
  String toJson() {
    final map = <String, dynamic>{
      'value': value,
      if (expiresAt != null) 'expiresAt': expiresAt!.millisecondsSinceEpoch,
    };
    return jsonEncode(map);
  }

  @override
  String toString() => 'TtlEntry(value: $value, expiresAt: $expiresAt)';
}

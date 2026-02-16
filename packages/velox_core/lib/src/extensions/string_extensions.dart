/// Extensions on [String] for common operations.
extension VeloxStringExtension on String {
  /// Returns `true` if this string is blank (empty or only whitespace).
  bool get isBlank => trim().isEmpty;

  /// Returns `true` if this string is not blank.
  bool get isNotBlank => !isBlank;

  /// Returns `null` if this string is blank, otherwise returns the string.
  String? get orNullIfBlank => isBlank ? null : this;

  /// Capitalizes the first letter of this string.
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Converts this string to camelCase.
  String get toCamelCase {
    final words = _splitIntoWords();
    if (words.isEmpty) return this;
    return [
      words.first.toLowerCase(),
      ...words.skip(1).map(
        (w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
      ),
    ].join();
  }

  /// Converts this string to snake_case.
  String get toSnakeCase => _splitIntoWords().map((w) => w.toLowerCase()).join('_');

  /// Converts this string to kebab-case.
  String get toKebabCase => _splitIntoWords().map((w) => w.toLowerCase()).join('-');

  /// Converts this string to PascalCase.
  String get toPascalCase => _splitIntoWords()
      .map(
        (w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
      )
      .join();

  /// Truncates this string to [maxLength] and appends [ellipsis].
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  /// Returns `true` if this string is a valid email address.
  bool get isEmail => RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  ).hasMatch(this);

  /// Returns `true` if this string is a valid URL.
  bool get isUrl => Uri.tryParse(this)?.hasScheme ?? false;

  /// Returns `true` if this string contains only digits.
  bool get isNumeric => RegExp(r'^\d+$').hasMatch(this);

  /// Reverses the string.
  String get reversed => split('').reversed.join();

  /// Removes all whitespace from this string.
  String get removeWhitespace => replaceAll(RegExp(r'\s+'), '');

  List<String> _splitIntoWords() =>
      // Split on underscores, hyphens, spaces, or camelCase boundaries
      replaceAllMapped(
        RegExp('[A-Z]'),
        (match) => ' ${match.group(0)}',
      )
          .split(RegExp(r'[\s_\-]+'))
          .where((w) => w.isNotEmpty)
          .toList();
}

/// Extensions on nullable [String] for safe operations.
extension VeloxNullableStringExtension on String? {
  /// Returns `true` if this string is null or blank.
  bool get isNullOrBlank => this == null || this!.isBlank;

  /// Returns `true` if this string is not null and not blank.
  bool get isNotNullOrBlank => !isNullOrBlank;

  /// Returns the string or an empty string if null.
  String get orEmpty => this ?? '';
}

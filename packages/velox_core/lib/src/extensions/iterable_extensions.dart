/// Extensions on [Iterable] for common operations.
extension VeloxIterableExtension<T> on Iterable<T> {
  /// Returns the first element matching [test], or `null` if none found.
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }

  /// Returns the last element matching [test], or `null` if none found.
  T? lastWhereOrNull(bool Function(T element) test) {
    T? result;
    for (final element in this) {
      if (test(element)) result = element;
    }
    return result;
  }

  /// Groups elements by a key.
  Map<K, List<T>> groupBy<K>(K Function(T element) keyOf) {
    final map = <K, List<T>>{};
    for (final element in this) {
      final key = keyOf(element);
      (map[key] ??= []).add(element);
    }
    return map;
  }

  /// Returns distinct elements based on a key.
  Iterable<T> distinctBy<K>(K Function(T element) keyOf) sync* {
    final seen = <K>{};
    for (final element in this) {
      final key = keyOf(element);
      if (seen.add(key)) {
        yield element;
      }
    }
  }

  /// Splits this iterable into chunks of [size].
  Iterable<List<T>> chunked(int size) sync* {
    if (size <= 0) {
      throw ArgumentError.value(size, 'size', 'Must be positive');
    }
    final iterator = this.iterator;
    while (iterator.moveNext()) {
      final chunk = <T>[iterator.current];
      for (var i = 1; i < size && iterator.moveNext(); i++) {
        chunk.add(iterator.current);
      }
      yield chunk;
    }
  }

  /// Returns a sorted copy of this iterable.
  List<T> sortedBy<K extends Comparable<Object>>(
    K Function(T element) keyOf,
  ) =>
      toList()..sort((a, b) => keyOf(a).compareTo(keyOf(b)));

  /// Returns a sorted copy in descending order.
  List<T> sortedByDescending<K extends Comparable<Object>>(
    K Function(T element) keyOf,
  ) =>
      toList()..sort((a, b) => keyOf(b).compareTo(keyOf(a)));

  /// Separates elements with a separator.
  Iterable<T> separated(T separator) sync* {
    var first = true;
    for (final element in this) {
      if (!first) yield separator;
      yield element;
      first = false;
    }
  }

  /// Returns the sum of elements mapped to a number.
  num sumBy(num Function(T element) selector) {
    var sum = 0.0;
    for (final element in this) {
      sum += selector(element);
    }
    return sum;
  }

  /// Returns `true` if no elements match [test].
  bool none(bool Function(T element) test) => !any(test);
}

/// Extensions on [Iterable] of nullable values.
extension VeloxNullableIterableExtension<T> on Iterable<T?> {
  /// Returns only non-null elements.
  Iterable<T> whereNotNull() sync* {
    for (final element in this) {
      if (element != null) yield element;
    }
  }
}

/// Extensions on nullable [Iterable].
extension VeloxIterableNullExtension<T> on Iterable<T>? {
  /// Returns `true` if this iterable is null or empty.
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// Returns `true` if this iterable is not null and not empty.
  bool get isNotNullOrEmpty => !isNullOrEmpty;

  /// Returns the iterable or an empty list if null.
  Iterable<T> get orEmpty => this ?? const [];
}

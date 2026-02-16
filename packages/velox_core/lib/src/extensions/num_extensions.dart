/// Extensions on [num] for common operations.
extension VeloxNumExtension on num {
  /// Returns a [Duration] of this many milliseconds.
  Duration get milliseconds => Duration(milliseconds: toInt());

  /// Returns a [Duration] of this many seconds.
  Duration get seconds => Duration(seconds: toInt());

  /// Returns a [Duration] of this many minutes.
  Duration get minutes => Duration(minutes: toInt());

  /// Returns a [Duration] of this many hours.
  Duration get hours => Duration(hours: toInt());

  /// Returns a [Duration] of this many days.
  Duration get days => Duration(days: toInt());

  /// Returns `true` if this number is between [min] and [max] (inclusive).
  bool isBetween(num min, num max) => this >= min && this <= max;

  /// Clamps this number to the range [min] to [max].
  num coerceIn(num min, num max) {
    if (this < min) return min;
    if (this > max) return max;
    return this;
  }

  /// Returns `true` if this number is negative.
  bool get isNegative => this < 0;

  /// Returns `true` if this number is positive.
  bool get isPositive => this > 0;

  /// Returns `true` if this number is zero.
  bool get isZero => this == 0;
}

/// Extensions on [int] for common operations.
extension VeloxIntExtension on int {
  /// Returns `true` if this integer is even.
  bool get isEvenNumber => isEven;

  /// Returns `true` if this integer is odd.
  bool get isOddNumber => isOdd;

  /// Returns the ordinal string (1st, 2nd, 3rd, 4th, etc.).
  String get ordinal {
    final remainder10 = this % 10;
    final remainder100 = this % 100;

    if (remainder100 >= 11 && remainder100 <= 13) {
      return '${this}th';
    }

    return switch (remainder10) {
      1 => '${this}st',
      2 => '${this}nd',
      3 => '${this}rd',
      _ => '${this}th',
    };
  }

  /// Repeats [action] this many times.
  void times(void Function(int index) action) {
    for (var i = 0; i < this; i++) {
      action(i);
    }
  }
}

/// Extensions on [double] for common operations.
extension VeloxDoubleExtension on double {
  /// Rounds to [places] decimal places.
  double roundToPlaces(int places) {
    final mod = _pow10(places);
    return (this * mod).round() / mod;
  }

  static double _pow10(int exponent) {
    var result = 1.0;
    for (var i = 0; i < exponent; i++) {
      result *= 10;
    }
    return result;
  }
}

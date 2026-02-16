/// Extensions on [DateTime] for common operations.
extension VeloxDateTimeExtension on DateTime {
  /// Returns `true` if this date is today.
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Returns `true` if this date is yesterday.
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Returns `true` if this date is tomorrow.
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  /// Returns `true` if this date is in the past.
  bool get isPast => isBefore(DateTime.now());

  /// Returns `true` if this date is in the future.
  bool get isFuture => isAfter(DateTime.now());

  /// Returns a new [DateTime] with only the date part (no time).
  DateTime get dateOnly => DateTime(year, month, day);

  /// Returns the start of the day (00:00:00).
  DateTime get startOfDay => DateTime(year, month, day);

  /// Returns the end of the day (23:59:59.999).
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  /// Returns the start of the month.
  DateTime get startOfMonth => DateTime(year, month);

  /// Returns the end of the month.
  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59, 999);

  /// Returns the start of the year.
  DateTime get startOfYear => DateTime(year);

  /// Returns the end of the year.
  DateTime get endOfYear => DateTime(year, 12, 31, 23, 59, 59, 999);

  /// Returns the number of days in this month.
  int get daysInMonth => DateTime(year, month + 1, 0).day;

  /// Returns the age in years from this date.
  int get age {
    final now = DateTime.now();
    var years = now.year - year;
    if (now.month < month || (now.month == month && now.day < day)) {
      years--;
    }
    return years;
  }

  /// Returns a new [DateTime] with the given fields replaced.
  DateTime copyWith({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
    int? millisecond,
    int? microsecond,
  }) => DateTime(
    year ?? this.year,
    month ?? this.month,
    day ?? this.day,
    hour ?? this.hour,
    minute ?? this.minute,
    second ?? this.second,
    millisecond ?? this.millisecond,
    microsecond ?? this.microsecond,
  );

  /// Adds the given number of days.
  DateTime addDays(int days) => add(Duration(days: days));

  /// Subtracts the given number of days.
  DateTime subtractDays(int days) => subtract(Duration(days: days));

  /// Returns `true` if this date is the same day as [other].
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  /// Returns the difference in days between this and [other].
  int differenceInDays(DateTime other) =>
      dateOnly.difference(other.dateOnly).inDays.abs();

  /// Returns `true` if this is a weekend (Saturday or Sunday).
  bool get isWeekend => weekday == DateTime.saturday || weekday == DateTime.sunday;

  /// Returns `true` if this is a weekday (Monday through Friday).
  bool get isWeekday => !isWeekend;
}

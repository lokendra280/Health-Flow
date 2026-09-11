extension DateTimeExtensions on DateTime {
  /// Returns a new DateTime with only the year, month, and day.
  DateTime get normalized => DateTime(year, month, day);
}

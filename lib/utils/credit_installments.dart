import 'dart:math' as math;

List<DateTime> monthlyInstallmentDates(DateTime firstDueDate, int count) {
  if (count < 1) {
    throw ArgumentError.value(count, 'count', 'Debe haber al menos una cuota.');
  }
  return List<DateTime>.generate(count, (index) {
    final monthIndex = firstDueDate.month - 1 + index;
    final year = firstDueDate.year + monthIndex ~/ 12;
    final month = monthIndex % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, math.min(firstDueDate.day, lastDay));
  });
}

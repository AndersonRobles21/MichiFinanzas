import 'dart:math' as math;

import '../models/future_expense.dart';

class FutureExpenseProgress {
  const FutureExpenseProgress({
    required this.amountMissing,
    required this.periodsRemaining,
    required this.recommendedPerPeriod,
    required this.isOverdue,
    required this.isComplete,
  });

  final double amountMissing;
  final int periodsRemaining;
  final double recommendedPerPeriod;
  final bool isOverdue;
  final bool isComplete;
}

FutureExpenseProgress calculateFutureExpenseProgress({
  required double targetAmount,
  required double reservedAmount,
  required FutureExpenseFrequency frequency,
  required DateTime targetDate,
  DateTime? startDate,
  DateTime? now,
}) {
  final currentDate = _dateOnly(now ?? DateTime.now());
  final dueDate = _dateOnly(targetDate);
  final missing = math.max(0.0, targetAmount - reservedAmount);
  final complete = missing <= 0;
  final overdue = dueDate.isBefore(currentDate) && !complete;

  if (complete) {
    return FutureExpenseProgress(
      amountMissing: 0,
      periodsRemaining: 0,
      recommendedPerPeriod: 0,
      isOverdue: overdue,
      isComplete: true,
    );
  }

  final plannedStart = startDate == null ? currentDate : _dateOnly(startDate);
  final periodStart = plannedStart.isAfter(currentDate)
      ? plannedStart
      : currentDate;
  final days = dueDate.difference(periodStart).inDays;
  final periods = overdue
      ? 1
      : switch (frequency) {
          FutureExpenseFrequency.daily => math.max(1, days),
          FutureExpenseFrequency.weekly => math.max(1, (days / 7).ceil()),
          FutureExpenseFrequency.fortnightly => math.max(1, (days / 15).ceil()),
          FutureExpenseFrequency.monthly => _monthlyPeriods(
            periodStart,
            dueDate,
          ),
          FutureExpenseFrequency.once => 1,
        };
  final recommendation = overdue
      ? missing
      : (missing * 100 / periods).floorToDouble() / 100;

  return FutureExpenseProgress(
    amountMissing: missing,
    periodsRemaining: periods,
    recommendedPerPeriod: recommendation,
    isOverdue: overdue,
    isComplete: false,
  );
}

int _monthlyPeriods(DateTime start, DateTime target) {
  var periods = 0;
  var cursor = start;
  while (cursor.isBefore(target)) {
    periods++;
    cursor = _addMonths(cursor, 1);
  }
  return math.max(1, periods);
}

DateTime _addMonths(DateTime date, int months) {
  final monthIndex = date.month - 1 + months;
  final year = date.year + monthIndex ~/ 12;
  final month = monthIndex % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, math.min(date.day, lastDay));
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

enum FutureExpenseFrequency {
  daily('diario', 'Diario'),
  weekly('semanal', 'Semanal'),
  fortnightly('quincenal', 'Quincenal'),
  monthly('mensual', 'Mensual'),
  once('unico', 'Fecha única');

  const FutureExpenseFrequency(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static FutureExpenseFrequency fromStorage(String value) {
    return FutureExpenseFrequency.values.firstWhere(
      (frequency) => frequency.storageValue == value,
      orElse: () => FutureExpenseFrequency.once,
    );
  }
}

enum FutureExpenseStatus {
  active('activo', 'Activo'),
  completed('completado', 'Completado'),
  archived('archivado', 'Archivado');

  const FutureExpenseStatus(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static FutureExpenseStatus fromStorage(String value) {
    return FutureExpenseStatus.values.firstWhere(
      (status) => status.storageValue == value,
      orElse: () => FutureExpenseStatus.active,
    );
  }
}

class FutureExpensePlan {
  const FutureExpensePlan({
    required this.id,
    required this.name,
    required this.category,
    required this.targetAmount,
    required this.plannedAmount,
    required this.frequency,
    required this.targetDate,
    required this.startDate,
    required this.notes,
    required this.status,
  });

  final int id;
  final String name;
  final String category;
  final double targetAmount;
  final double plannedAmount;
  final FutureExpenseFrequency frequency;
  final DateTime targetDate;
  final DateTime? startDate;
  final String? notes;
  final FutureExpenseStatus status;
}

class FutureExpenseSummary {
  const FutureExpenseSummary({
    required this.plan,
    required this.reservedAmount,
  });

  final FutureExpensePlan plan;
  final double reservedAmount;

  double get amountMissing =>
      (plan.targetAmount - reservedAmount).clamp(0.0, double.infinity);

  double get plannedAmountRemaining =>
      (plan.plannedAmount - reservedAmount).clamp(0.0, double.infinity);
}

class FutureExpenseInsufficientBalance implements Exception {
  const FutureExpenseInsufficientBalance({
    required this.requested,
    required this.available,
  });

  final double requested;
  final double available;

  double get missing => requested - available;
}

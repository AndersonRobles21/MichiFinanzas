enum SubscriptionFrequency {
  weekly('semanal', 'Semanal', 52 / 12),
  monthly('mensual', 'Mensual', 1),
  quarterly('trimestral', 'Trimestral', 1 / 3),
  yearly('anual', 'Anual', 1 / 12);

  const SubscriptionFrequency(
    this.storageValue,
    this.label,
    this.monthlyMultiplier,
  );

  final String storageValue;
  final String label;
  final double monthlyMultiplier;

  double monthlyCost(double amount) => amount * monthlyMultiplier;

  static SubscriptionFrequency? fromStorage(String? value) {
    for (final frequency in values) {
      if (frequency.storageValue == value) return frequency;
    }
    return null;
  }
}

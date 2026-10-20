enum MoneyMedium {
  cash('efectivo', 'Efectivo'),
  digital('digital', 'Digital');

  const MoneyMedium(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static MoneyMedium? fromStorage(String? value) {
    for (final medium in values) {
      if (medium.storageValue == value) return medium;
    }
    return null;
  }
}

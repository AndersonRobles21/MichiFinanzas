enum IncomeType {
  salary('sueldo', 'Sueldo'),
  extra('extra', 'Dinero extra'),
  loan('prestamo', 'Préstamo recibido'),
  legacy('ingreso', 'Ingreso');

  const IncomeType(this.storageValue, this.label);

  final String storageValue;
  final String label;

  bool get countsAsEarned => this != IncomeType.loan;

  static IncomeType fromStorage(String value) => values.firstWhere(
    (type) => type.storageValue == value,
    orElse: () => IncomeType.legacy,
  );
}

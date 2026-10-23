import 'dart:async';

import 'package:flutter/material.dart';

import '../../database/app_database.dart';
import '../../models/money_medium.dart';
import '../../services/app_settings_service.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/money_format.dart';
import '../../utils/user_messages.dart';
import '../../widgets/cat_illustration.dart';
import '../../widgets/money_medium_selector.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key, this.isActive = true, this.databaseService});

  final bool isActive;
  final DatabaseService? databaseService;

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  late final DatabaseService _databaseService;
  late final bool _ownsDatabaseService;
  Future<_ExpensesData>? _expensesFuture;
  AppSettings _settings = AppSettings.defaults();
  List<Gasto>? _loadedExpenses;
  List<CuentasDigitale> _loadedAccounts = const [];

  @override
  void initState() {
    super.initState();
    _ownsDatabaseService = widget.databaseService == null;
    _databaseService = widget.databaseService ?? DatabaseService(AppDatabase());
    if (widget.isActive) {
      _expensesFuture = _loadExpenses();
    }
  }

  @override
  void didUpdateWidget(covariant ExpensesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      setState(() {
        _expensesFuture = _loadExpenses();
      });
    }
  }

  @override
  void dispose() {
    if (_ownsDatabaseService) unawaited(_databaseService.close());
    super.dispose();
  }

  Future<_ExpensesData> _loadExpenses() async {
    try {
      _settings = await const AppSettingsService().load();
    } catch (error, stackTrace) {
      logOperationFailure(
        error,
        stackTrace,
        operation: 'cargar categorías de gastos',
      );
    }
    final expenses = await runWithLoggedErrors(
      'cargar gastos',
      _databaseService.obtenerGastos,
    );
    final sortedExpenses = _sortExpenses(expenses);
    final results = await Future.wait<Object>([
      _databaseService.obtenerTodosLosPagosDeuda(),
      _databaseService.obtenerDeudas(),
      _databaseService.obtenerCuentasDigitales(),
    ]);
    final data = _ExpensesData(
      expenses: sortedExpenses,
      debtPayments: results[0] as List<PagosDeudaData>,
      debts: results[1] as List<Deuda>,
      accounts: (results[2] as List<DigitalAccountBalance>)
          .map((item) => item.account)
          .toList(),
    );
    if (mounted) {
      setState(() {
        _loadedExpenses = sortedExpenses;
        _loadedAccounts = data.accounts;
      });
    } else {
      _loadedExpenses = sortedExpenses;
      _loadedAccounts = data.accounts;
    }
    return data;
  }

  Future<void> _addExpense() async {
    final existingExpenses = _loadedExpenses;
    if (existingExpenses == null) return;
    final categories = {
      ...AppSettingsService.normalizeCategories(_settings.expenseCategories),
      ...existingExpenses.map(
        (expense) => AppSettingsService.normalizeCategory(expense.categoria),
      ),
    }.toList();
    final draft = await showModalBottomSheet<_ExpenseDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      builder: (context) =>
          _ExpenseFormSheet(categories: categories, accounts: _loadedAccounts),
    );
    if (draft == null || !mounted) return;

    try {
      await _databaseService.agregarGasto(
        nombre: draft.nombre,
        monto: draft.monto,
        categoria: draft.categoria,
        fecha: draft.fecha,
        nota: draft.nota,
        medio: draft.medio,
        cuentaDigitalId: draft.digitalAccountId,
      );
      final expenses = _sortExpenses(await _databaseService.obtenerGastos());
      if (!mounted) return;
      setState(() {
        _loadedExpenses = expenses;
        _expensesFuture = _loadExpenses();
      });
      _showMessage('¡Listo! Otro movimiento bajo control 🐱', isSuccess: true);
    } catch (error, stackTrace) {
      logOperationFailure(error, stackTrace, operation: 'guardar un gasto');
      if (mounted) {
        _showMessage(friendlyOperationError(error, action: 'guardar el gasto'));
      }
    }
  }

  Future<void> _editExpense(Gasto expense) async {
    final categories = {
      ...AppSettingsService.normalizeCategories(_settings.expenseCategories),
      ...?_loadedExpenses?.map(
        (item) => AppSettingsService.normalizeCategory(item.categoria),
      ),
    }.toList();
    final draft = await showModalBottomSheet<_ExpenseDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      builder: (context) => _ExpenseFormSheet(
        categories: categories,
        accounts: _loadedAccounts,
        expense: expense,
      ),
    );
    if (draft == null || !mounted) return;

    try {
      await _databaseService.actualizarGasto(
        id: expense.id,
        nombre: draft.nombre,
        monto: draft.monto,
        categoria: draft.categoria,
        fecha: draft.fecha,
        nota: draft.nota,
        medio: draft.medio,
        cuentaDigitalId: draft.digitalAccountId,
      );
      final expenses = _sortExpenses(await _databaseService.obtenerGastos());
      if (!mounted) return;
      setState(() {
        _loadedExpenses = expenses;
        _expensesFuture = _loadExpenses();
      });
      _showMessage('Cambios guardados.', isSuccess: true);
    } catch (error, stackTrace) {
      logOperationFailure(error, stackTrace, operation: 'actualizar un gasto');
      if (mounted) {
        _showMessage(
          friendlyOperationError(error, action: 'actualizar el gasto'),
        );
      }
    }
  }

  Future<void> _deleteExpense(Gasto expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Borrar este gasto?'),
        content: Text(
          'Se quitará "${expense.nombre}" de tus gastos. No podrás deshacerlo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Conservar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Borrar gasto'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _databaseService.eliminarGasto(expense.id);
      final expenses = _sortExpenses(await _databaseService.obtenerGastos());
      if (!mounted) return;
      setState(() {
        _loadedExpenses = expenses;
        _expensesFuture = _loadExpenses();
      });
      _showMessage('Gasto borrado.', isSuccess: true);
    } catch (error, stackTrace) {
      logOperationFailure(error, stackTrace, operation: 'borrar un gasto');
      if (mounted) {
        _showMessage(friendlyOperationError(error, action: 'borrar el gasto'));
      }
    }
  }

  void _showMessage(String message, {bool isSuccess = false}) {
    showCatMessage(context, message, isSuccess: isSuccess);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadedExpenses == null ? null : _addExpense,
        tooltip: 'Agregar gasto',
        icon: const Icon(Icons.add_rounded),
        label: const Text('Agregar'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 420 ? 20.0 : 36.0;
            return FutureBuilder<_ExpensesData>(
              future: _expensesFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _ExpensesMessage(
                    icon: Icons.cloud_off_outlined,
                    message: 'Ups, no pudimos cargar tus gastos.',
                    actionLabel: 'Intentar de nuevo',
                    onAction: () {
                      setState(() {
                        _expensesFuture = _loadExpenses();
                      });
                    },
                  );
                }
                if (!snapshot.hasData) {
                  return Center(
                    child: Text(
                      'Estamos cargando tus gastos...',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }

                final data = snapshot.data!;
                final expenses = data.expenses;
                final debtNames = {
                  for (final debt in data.debts) debt.id: debt.nombre,
                };
                final history = <_ExpenseHistoryEntry>[
                  for (final expense in expenses)
                    _ExpenseHistoryEntry.expense(expense),
                  for (final payment in data.debtPayments)
                    _ExpenseHistoryEntry.payment(
                      payment,
                      debtNames[payment.deudaId] ?? 'Deuda',
                    ),
                ]..sort((first, second) => second.date.compareTo(first.date));
                final now = DateTime.now();
                final thisMonth = expenses.where(
                  (expense) =>
                      expense.fecha.year == now.year &&
                      expense.fecha.month == now.month,
                );
                final paymentsThisMonth = data.debtPayments.where(
                  (payment) =>
                      payment.fecha.year == now.year &&
                      payment.fecha.month == now.month,
                );
                final monthlyTotal =
                    thisMonth.fold<double>(
                      0,
                      (total, expense) => total + expense.monto,
                    ) +
                    paymentsThisMonth.fold<double>(
                      0,
                      (total, payment) => total + payment.monto,
                    );
                final monthlyCount =
                    thisMonth.length + paymentsThisMonth.length;

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    28,
                    horizontalPadding,
                    104,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Gastos',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium,
                                ),
                              ),
                              const AnimatedCat(
                                asset: CatAssets.gastos,
                                label: 'Gato organizando gastos',
                                width: 92,
                                height: 68,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Registra y consulta tus gastos.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 24),
                          _MonthlySummary(
                            total: monthlyTotal,
                            count: monthlyCount,
                          ),
                          const SizedBox(height: 28),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Gastos y pagos de deudas',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              Text(
                                '${history.length}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (history.isEmpty)
                            const _ExpensesMessage(
                              icon: Icons.receipt_long_outlined,
                              message:
                                  'Todavía no hay gastos por aquí. '
                                  '¡Ojalá siga así un buen rato!',
                              illustration: CatAssets.vacio,
                            )
                          else
                            ...history.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: entry.expense != null
                                    ? _ExpenseTile(
                                        expense: entry.expense!,
                                        mediumLabel: _moneyMediumLabel(
                                          entry.expense!.medio,
                                          entry.expense!.cuentaDigitalId,
                                          _loadedAccounts,
                                        ),
                                        onEdit: () =>
                                            _editExpense(entry.expense!),
                                        onDelete: () =>
                                            _deleteExpense(entry.expense!),
                                      )
                                    : _DebtPaymentTile(
                                        payment: entry.payment!,
                                        debtName: entry.debtName!,
                                      ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ExpenseDraft {
  const _ExpenseDraft({
    required this.nombre,
    required this.monto,
    required this.categoria,
    required this.fecha,
    required this.nota,
    required this.medio,
    required this.digitalAccountId,
  });

  final String nombre;
  final double monto;
  final String categoria;
  final DateTime fecha;
  final String? nota;
  final MoneyMedium? medio;
  final int? digitalAccountId;
}

class _ExpensesData {
  const _ExpensesData({
    required this.expenses,
    required this.debtPayments,
    required this.debts,
    required this.accounts,
  });

  final List<Gasto> expenses;
  final List<PagosDeudaData> debtPayments;
  final List<Deuda> debts;
  final List<CuentasDigitale> accounts;
}

class _ExpenseHistoryEntry {
  const _ExpenseHistoryEntry._({
    required this.date,
    this.expense,
    this.payment,
    this.debtName,
  });

  factory _ExpenseHistoryEntry.expense(Gasto expense) =>
      _ExpenseHistoryEntry._(date: expense.fecha, expense: expense);

  factory _ExpenseHistoryEntry.payment(
    PagosDeudaData payment,
    String debtName,
  ) => _ExpenseHistoryEntry._(
    date: payment.fecha,
    payment: payment,
    debtName: debtName,
  );

  final DateTime date;
  final Gasto? expense;
  final PagosDeudaData? payment;
  final String? debtName;
}

class _ExpenseFormSheet extends StatefulWidget {
  const _ExpenseFormSheet({
    required this.categories,
    required this.accounts,
    this.expense,
  });

  final List<String> categories;
  final List<CuentasDigitale> accounts;
  final Gasto? expense;

  @override
  State<_ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends State<_ExpenseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  String? _category;
  late MoneyMedium? _medium;
  int? _digitalAccountId;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _nameController = TextEditingController(text: expense?.nombre ?? '');
    _amountController = TextEditingController(
      text: expense == null ? '' : formatAmount(expense.monto),
    );
    _noteController = TextEditingController(text: expense?.nota ?? '');
    _medium = expense == null
        ? MoneyMedium.cash
        : MoneyMedium.fromStorage(expense.medio);
    _digitalAccountId = expense?.cuentaDigitalId;
    _category = expense == null
        ? null
        : AppSettingsService.normalizeCategory(expense.categoria);
    _date = expense?.fecha ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selectedDate != null) setState(() => _date = selectedDate);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _ExpenseDraft(
        nombre: _nameController.text.trim(),
        monto: parseMoney(_amountController.text),
        categoria: _category!,
        fecha: _date,
        medio: _medium,
        nota: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        digitalAccountId: _digitalAccountId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.expense == null ? 'Nuevo gasto' : 'Editar gasto',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  key: const ValueKey('expense-name'),
                  controller: _nameController,
                  autofocus: false,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del gasto',
                    hintText: 'Ej. Compra semanal',
                    prefixIcon: Icon(Icons.edit_outlined),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Escribe el nombre del gasto.'
                      : null,
                ),
                const SizedBox(height: 14),
                MoneyMediumSelector(
                  selected: _medium,
                  title: 'Medio de pago',
                  allowUnclassified: widget.expense != null,
                  onChanged: (medium) => setState(() {
                    _medium = medium;
                    if (medium != MoneyMedium.digital) {
                      _digitalAccountId = null;
                    }
                  }),
                ),
                if (_medium == MoneyMedium.digital) ...[
                  const SizedBox(height: 12),
                  DigitalAccountSelector(
                    accounts: widget.accounts,
                    selectedId: _digitalAccountId,
                    onChanged: (value) =>
                        setState(() => _digitalAccountId = value),
                  ),
                  if (widget.accounts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Agrega una cuenta digital en Configuración antes de elegir ese medio.',
                      ),
                    ),
                ],
                const SizedBox(height: 14),
                TextFormField(
                  key: const ValueKey('expense-amount'),
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: const [ThousandsInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Monto',
                    prefixText: '\$ ',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  validator: (value) {
                    final amount = tryParseMoney(value);
                    if (amount == null || amount <= 0) {
                      return 'Escribe un monto mayor que cero.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                FormField<String>(
                  initialValue: _category,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Elige una categoría.'
                      : null,
                  builder: (field) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        key: const ValueKey('expense-category'),
                        borderRadius: BorderRadius.circular(8),
                        onTap: () async {
                          final category = await showModalBottomSheet<String>(
                            context: context,
                            useSafeArea: true,
                            backgroundColor: AppColors.surface,
                            builder: (context) => SafeArea(
                              child: ListView(
                                shrinkWrap: true,
                                padding: const EdgeInsets.all(16),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      8,
                                      4,
                                      8,
                                      12,
                                    ),
                                    child: Text(
                                      'Elige una categoría',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                  ),
                                  for (final category in widget.categories)
                                    ListTile(
                                      key: ValueKey(
                                        'expense-category-option-$category',
                                      ),
                                      title: Text(category),
                                      trailing: _category == category
                                          ? const Icon(
                                              Icons.check_rounded,
                                              color: AppColors.primary,
                                            )
                                          : null,
                                      onTap: () =>
                                          Navigator.pop(context, category),
                                    ),
                                ],
                              ),
                            ),
                          );
                          if (category != null && mounted) {
                            setState(() => _category = category);
                            field.didChange(category);
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Categoría',
                            prefixIcon: const Icon(Icons.category_outlined),
                            suffixIcon: const Icon(Icons.expand_more_rounded),
                            errorText: field.errorText,
                          ),
                          child: Text(
                            _category ?? 'Elige una categoría',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text('Fecha: ${_formatDate(_date)}'),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: const ValueKey('expense-note'),
                  controller: _noteController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                  minLines: 1,
                  decoration: const InputDecoration(
                    labelText: 'Nota (opcional)',
                    prefixIcon: Icon(Icons.notes_rounded),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed:
                            _medium == MoneyMedium.digital &&
                                !widget.accounts.any(
                                  (account) => account.id == _digitalAccountId,
                                )
                            ? null
                            : _save,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(
                          widget.expense == null
                              ? 'Guardar gasto'
                              : 'Guardar cambios',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthlySummary extends StatelessWidget {
  const _MonthlySummary({required this.total, required this.count});

  final double total;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: AppCardDecorations.featured,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalItem = _SummaryValue(
            label: 'Gastos de este mes',
            value: _formatMoney(total),
            icon: Icons.payments_outlined,
          );
          final countItem = _SummaryValue(
            label: 'Movimientos este mes',
            value: '$count',
            icon: Icons.receipt_long_outlined,
          );

          if (constraints.maxWidth < 480) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [totalItem, const SizedBox(height: 18), countItem],
            );
          }
          return Row(
            children: [
              Expanded(child: totalItem),
              const SizedBox(width: 20),
              Expanded(child: countItem),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({
    required this.expense,
    required this.mediumLabel,
    required this.onEdit,
    required this.onDelete,
  });

  final Gasto expense;
  final String mediumLabel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('expense-${expense.id}'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: AppCardDecorations.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  _formatMoney(expense.monto),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _CategoryTag(expense.categoria),
                    Text(
                      _formatDate(expense.fecha),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      mediumLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                if (expense.nota case final note?) ...[
                  const SizedBox(height: 8),
                  Text(note, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                tooltip: 'Editar gasto',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                color: AppColors.primary,
              ),
              IconButton(
                tooltip: 'Eliminar gasto',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DebtPaymentTile extends StatelessWidget {
  const _DebtPaymentTile({required this.payment, required this.debtName});

  final PagosDeudaData payment;
  final String debtName;

  @override
  Widget build(BuildContext context) {
    final medium = MoneyMedium.fromStorage(payment.medio);
    return Container(
      key: ValueKey('debt-payment-expense-${payment.id}'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppCardDecorations.surface,
      child: Row(
        children: [
          const Icon(Icons.payments_outlined, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pago de deuda · $debtName',
                  key: ValueKey('debt-payment-title-${payment.id}'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(_formatDate(payment.fecha)),
                const SizedBox(height: 4),
                Text(medium?.label ?? 'Medio sin clasificar'),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatMoney(payment.monto),
            key: ValueKey('debt-payment-amount-${payment.id}'),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  const _CategoryTag(this.category);

  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        category,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.primary),
      ),
    );
  }
}

String _moneyMediumLabel(
  String? storageValue,
  int? accountId,
  List<CuentasDigitale> accounts,
) {
  final medium = MoneyMedium.fromStorage(storageValue);
  if (accountId != null) {
    for (final account in accounts) {
      if (account.id == accountId) return account.nombre;
    }
  }
  return medium?.label ?? 'Medio sin clasificar';
}

class _ExpensesMessage extends StatelessWidget {
  const _ExpensesMessage({
    required this.icon,
    required this.message,
    this.illustration,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? illustration;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (illustration case final asset?)
              AnimatedCat(
                asset: asset,
                label: 'Gato descansando, sin registros',
                width: 148,
                height: 112,
              )
            else
              Icon(icon, size: 32, color: AppColors.primary),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatMoney(double amount) {
  return formatMoney(amount);
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

List<Gasto> _sortExpenses(List<Gasto> expenses) {
  return expenses..sort((a, b) => b.fecha.compareTo(a.fecha));
}

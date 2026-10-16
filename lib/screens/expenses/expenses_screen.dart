import 'dart:async';

import 'package:flutter/material.dart';

import '../../database/app_database.dart';
import '../../services/app_settings_service.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/money_format.dart';
import '../../utils/user_messages.dart';
import '../../widgets/cat_illustration.dart';

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
  Future<List<Gasto>>? _expensesFuture;
  AppSettings _settings = AppSettings.defaults();
  List<Gasto>? _loadedExpenses;

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

  Future<List<Gasto>> _loadExpenses() async {
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
    if (mounted) {
      setState(() => _loadedExpenses = sortedExpenses);
    } else {
      _loadedExpenses = sortedExpenses;
    }
    return sortedExpenses;
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
      builder: (context) => _ExpenseFormSheet(categories: categories),
    );
    if (draft == null || !mounted) return;

    try {
      await _databaseService.agregarGasto(
        nombre: draft.nombre,
        monto: draft.monto,
        categoria: draft.categoria,
        fecha: draft.fecha,
        nota: draft.nota,
      );
      final expenses = _sortExpenses(await _databaseService.obtenerGastos());
      if (!mounted) return;
      setState(() {
        _loadedExpenses = expenses;
        _expensesFuture = Future.value(expenses);
      });
      _showMessage('¡Listo! El gasto quedó guardado.', isSuccess: true);
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
      builder: (context) =>
          _ExpenseFormSheet(categories: categories, expense: expense),
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
      );
      final expenses = _sortExpenses(await _databaseService.obtenerGastos());
      if (!mounted) return;
      setState(() {
        _loadedExpenses = expenses;
        _expensesFuture = Future.value(expenses);
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
        _expensesFuture = Future.value(expenses);
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
            return FutureBuilder<List<Gasto>>(
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

                final expenses = snapshot.data!;
                final now = DateTime.now();
                final thisMonth = expenses.where(
                  (expense) =>
                      expense.fecha.year == now.year &&
                      expense.fecha.month == now.month,
                );
                final monthlyTotal = thisMonth.fold<double>(
                  0,
                  (total, expense) => total + expense.monto,
                );
                final monthlyCount = thisMonth.length;

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
                                  'Todos los gastos',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              Text(
                                '${expenses.length}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (expenses.isEmpty)
                            const _ExpensesMessage(
                              icon: Icons.receipt_long_outlined,
                              message: 'Todavía no hay gastos por aquí.',
                              illustration: CatAssets.vacio,
                            )
                          else
                            ...expenses.map(
                              (expense) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _ExpenseTile(
                                  expense: expense,
                                  onEdit: () => _editExpense(expense),
                                  onDelete: () => _deleteExpense(expense),
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
  });

  final String nombre;
  final double monto;
  final String categoria;
  final DateTime fecha;
  final String? nota;
}

class _ExpenseFormSheet extends StatefulWidget {
  const _ExpenseFormSheet({required this.categories, this.expense});

  final List<String> categories;
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
        nota: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
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
                        onPressed: _save,
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
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceRaised, AppColors.surface],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outline),
      ),
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
    required this.onEdit,
    required this.onDelete,
  });

  final Gasto expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('expense-${expense.id}'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outline),
      ),
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

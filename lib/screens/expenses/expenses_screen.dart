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
import '../../widgets/month_navigator.dart';
import '../../widgets/money_source_selector.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({
    super.key,
    this.isActive = true,
    this.databaseService,
    this.registerRequestId = 0,
  });

  final bool isActive;
  final DatabaseService? databaseService;
  final int registerRequestId;

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
  List<DigitalAccountBalance> _loadedAccountBalances = const [];
  double _cashBalance = 0;
  double _digitalWithoutAccount = 0;
  late int _lastRegisterRequestId;
  late DateTime _selectedMonth;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _ownsDatabaseService = widget.databaseService == null;
    _databaseService = widget.databaseService ?? DatabaseService(AppDatabase());
    _lastRegisterRequestId = widget.registerRequestId;
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
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
    if (widget.registerRequestId != oldWidget.registerRequestId &&
        widget.registerRequestId != _lastRegisterRequestId) {
      _lastRegisterRequestId = widget.registerRequestId;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final future = _expensesFuture;
        if (future != null) await future;
        if (mounted) await _addExpense();
      });
    }
  }

  void _changeMonth(int offset) {
    final candidate = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + offset,
    );
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    if (candidate.isAfter(currentMonth)) return;
    setState(() {
      _selectedMonth = candidate;
      _selectedCategory = null;
    });
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
      _databaseService.obtenerSaldosPorMedio(),
      _databaseService.obtenerGastosCreditoIds(),
    ]);
    final digitalAccounts = results[2] as List<DigitalAccountBalance>;
    final balances = results[3] as AvailableBalanceBreakdown;
    final expensesWithPayments = sortedExpenses
        .map((expense) => expense.pagoDeudaId)
        .whereType<int>()
        .toSet();
    final data = _ExpensesData(
      expenses: sortedExpenses,
      debtPayments: (results[0] as List<PagosDeudaData>)
          .where((payment) => !expensesWithPayments.contains(payment.id))
          .toList(),
      debts: results[1] as List<Deuda>,
      digitalAccounts: digitalAccounts,
      balances: balances,
      creditExpenseIds: results[4] as Set<int>,
    );
    final digitalAccountsTotal = digitalAccounts.fold<double>(
      0,
      (total, account) => total + account.balance,
    );
    if (mounted) {
      setState(() {
        _loadedExpenses = sortedExpenses;
        _loadedAccounts = data.accounts;
        _loadedAccountBalances = digitalAccounts;
        _cashBalance = balances.cash;
        _digitalWithoutAccount = balances.digital - digitalAccountsTotal;
      });
    } else {
      _loadedExpenses = sortedExpenses;
      _loadedAccounts = data.accounts;
      _loadedAccountBalances = digitalAccounts;
      _cashBalance = balances.cash;
      _digitalWithoutAccount = balances.digital - digitalAccountsTotal;
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
      builder: (context) => _ExpenseFormSheet(
        categories: categories,
        accounts: _loadedAccountBalances,
        cashBalance: _cashBalance,
        digitalWithoutAccount: _digitalWithoutAccount,
      ),
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
        accounts: _loadedAccountBalances,
        cashBalance: _cashBalance,
        digitalWithoutAccount: _digitalWithoutAccount,
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 420
                ? AppSpacing.pageHorizontal
                : AppSpacing.pageHorizontalWide;
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
                final expensesThisMonth = expenses
                    .where(
                      (expense) =>
                          expense.fecha.year == _selectedMonth.year &&
                          expense.fecha.month == _selectedMonth.month,
                    )
                    .toList();
                final paymentsThisMonth = data.debtPayments
                    .where(
                      (payment) =>
                          payment.fecha.year == _selectedMonth.year &&
                          payment.fecha.month == _selectedMonth.month,
                    )
                    .toList();
                final categoryTotals = <String, double>{};
                for (final expense in expensesThisMonth) {
                  final category = AppSettingsService.normalizeCategory(
                    expense.categoria,
                  );
                  categoryTotals.update(
                    category,
                    (total) => total + expense.monto,
                    ifAbsent: () => expense.monto,
                  );
                }
                final categories = categoryTotals.entries.toList()
                  ..sort((first, second) => second.value.compareTo(first.value));
                final history = <_ExpenseHistoryEntry>[
                  for (final expense in expensesThisMonth)
                    if (_selectedCategory == null ||
                        AppSettingsService.normalizeCategory(
                              expense.categoria,
                            ) ==
                            _selectedCategory)
                    _ExpenseHistoryEntry.expense(expense),
                  for (final payment in paymentsThisMonth)
                    _ExpenseHistoryEntry.payment(
                      payment,
                      debtNames[payment.deudaId] ?? 'Deuda',
                    ),
                ]..sort((first, second) => second.date.compareTo(first.date));
                final monthlyTotal =
                    expensesThisMonth.fold<double>(
                      0,
                      (total, expense) => total + expense.monto,
                    ) +
                    paymentsThisMonth.fold<double>(
                      0,
                      (total, payment) => total + payment.monto,
                    );
                final monthlyCount = expensesThisMonth.length +
                    paymentsThisMonth.length;
                final groupedHistory = <String, List<_ExpenseHistoryEntry>>{};
                for (final entry in history) {
                  final dateKey = [
                    entry.date.year,
                    entry.date.month.toString().padLeft(2, '0'),
                    entry.date.day.toString().padLeft(2, '0'),
                  ].join('-');
                  groupedHistory.putIfAbsent(dateKey, () => []).add(entry);
                }

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    AppSpacing.pageTop,
                    horizontalPadding,
                    104,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            MonthNavigator(
                              month: _selectedMonth,
                              onPrevious: () => _changeMonth(-1),
                              onNext: () => _changeMonth(1),
                            ),
                            const SizedBox(height: 8),
                          _MonthlySummary(
                            total: monthlyTotal,
                            count: monthlyCount,
                              categories: categories,
                          ),
                            if (categories.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _ExpenseCategoryFilter(
                                      label: 'Todas',
                                      selected: _selectedCategory == null,
                                      onTap: () => setState(
                                        () => _selectedCategory = null,
                                      ),
                                    ),
                                    for (final category in categories)
                                      _ExpenseCategoryFilter(
                                        label: category.key,
                                        selected:
                                            _selectedCategory == category.key,
                                        onTap: () => setState(
                                          () => _selectedCategory = category.key,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                          const SizedBox(height: 6),
                          if (history.isEmpty)
                            _ExpensesMessage(
                              icon: Icons.receipt_long_outlined,
                              message:
                                  'Todavía no hay gastos este mes. Registra tu primer gasto para ver aquí en qué se va tu dinero.',
                              illustration: CatAssets.vacio,
                              actionLabel: 'Registrar gasto',
                              onAction: _loadedExpenses == null
                                  ? null
                                  : _addExpense,
                            )
                          else
                            for (final day in groupedHistory.entries) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(2, 10, 2, 4),
                                child: Text(
                                  _formatDayHeading(day.key),
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(color: AppColors.textSecondary),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                decoration: AppCardDecorations.surface,
                                child: Column(
                                  children: [
                                    for (
                                      var index = 0;
                                      index < day.value.length;
                                      index++
                                    ) ...[
                                      if (index > 0)
                                        Divider(
                                          height: 1,
                                          color: AppColors.outline.withValues(
                                            alpha: 0.25,
                                          ),
                                        ),
                                      _ExpenseMovementRow(
                                        entry: day.value[index],
                                        accounts: _loadedAccounts,
                                        creditExpenseIds: data.creditExpenseIds,
                                        onEdit: _editExpense,
                                        onDelete: _deleteExpense,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
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
    required this.digitalAccounts,
    required this.balances,
    required this.creditExpenseIds,
  });

  final List<Gasto> expenses;
  final List<PagosDeudaData> debtPayments;
  final List<Deuda> debts;
  final List<DigitalAccountBalance> digitalAccounts;
  final AvailableBalanceBreakdown balances;
  final Set<int> creditExpenseIds;

  List<CuentasDigitale> get accounts =>
      digitalAccounts.map((account) => account.account).toList();
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
    required this.cashBalance,
    required this.digitalWithoutAccount,
    this.expense,
  });

  final List<String> categories;
  final List<DigitalAccountBalance> accounts;
  final double cashBalance;
  final double digitalWithoutAccount;
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

  double get _cashBalanceForForm {
    final oldExpense = widget.expense;
    return widget.cashBalance +
        (oldExpense?.medio == MoneyMedium.cash.storageValue
            ? oldExpense!.monto
            : 0);
  }

  double get _unassignedDigitalAllowance {
    final oldExpense = widget.expense;
    return oldExpense?.medio == MoneyMedium.digital.storageValue &&
            oldExpense?.cuentaDigitalId == null
        ? oldExpense!.monto
        : 0;
  }

  double get _selectedAvailableBalance {
    if (_medium == MoneyMedium.cash) return _cashBalanceForForm;
    if (_medium != MoneyMedium.digital) return 0;
    if (_digitalAccountId == null) {
      return widget.digitalWithoutAccount + _unassignedDigitalAllowance;
    }
    final account = widget.accounts.where(
      (item) => item.account.id == _digitalAccountId,
    );
    if (account.isEmpty) return 0;
    final oldExpense = widget.expense;
    return account.first.balance +
        (oldExpense?.medio == MoneyMedium.digital.storageValue &&
                oldExpense?.cuentaDigitalId == _digitalAccountId
            ? oldExpense!.monto
            : 0);
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
                MoneySourceSelector(
                  selectedMedium: _medium,
                  selectedAccountId: _digitalAccountId,
                  cashBalance: _cashBalanceForForm,
                  digitalWithoutAccount:
                      widget.digitalWithoutAccount +
                      _unassignedDigitalAllowance,
                  digitalAccounts: widget.accounts,
                  amount: tryParseMoney(_amountController.text),
                  allowUnclassified: widget.expense != null,
                  allowUnassignedDigital: widget.expense != null,
                  title: '¿De dónde sale el dinero?',
                  onChanged: (medium, accountId) => setState(() {
                    _medium = medium;
                    _digitalAccountId = accountId;
                  }),
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
                    if (widget.expense == null &&
                        amount > _selectedAvailableBalance + 1e-8) {
                      return 'El saldo de esta cuenta es insuficiente '
                          '(${formatMoney(_selectedAvailableBalance)} disponibles).';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
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
                                          ? Icon(
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
                                (widget.expense == null &&
                                        _digitalAccountId == null ||
                                    _digitalAccountId != null &&
                                        !widget.accounts.any(
                                          (account) =>
                                              account.account.id ==
                                              _digitalAccountId,
                                        ))
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
  const _MonthlySummary({
    required this.total,
    required this.count,
    required this.categories,
  });

  final double total;
  final int count;
  final List<MapEntry<String, double>> categories;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppCardDecorations.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total gastado', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 1),
          Text(
            _formatMoney(total),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.negative,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            '$count movimientos',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (categories.isNotEmpty && total > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              child: SizedBox(
                height: 12,
                child: Row(
                  children: [
                    for (var index = 0; index < categories.length; index++)
                      Expanded(
                        flex: (categories[index].value / total * 1000)
                            .round()
                            .clamp(1, 1000)
                            .toInt(),
                        child: ColoredBox(
                          color: AppColors.chartPalette[
                              index % AppColors.chartPalette.length],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                for (
                var index = 0;
                index < categories.length && index < 4;
                index++
                )
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.chartPalette[
                              index % AppColors.chartPalette.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${categories[index].key} ${_formatMoney(categories[index].value)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ExpenseCategoryFilter extends StatelessWidget {
  const _ExpenseCategoryFilter({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 38),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.outline,
              ),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: selected ? AppColors.actionForeground : AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpenseMovementRow extends StatelessWidget {
  const _ExpenseMovementRow({
    required this.entry,
    required this.accounts,
    required this.creditExpenseIds,
    required this.onEdit,
    required this.onDelete,
  });

  final _ExpenseHistoryEntry entry;
  final List<CuentasDigitale> accounts;
  final Set<int> creditExpenseIds;
  final ValueChanged<Gasto> onEdit;
  final ValueChanged<Gasto> onDelete;

  @override
  Widget build(BuildContext context) {
    final expense = entry.expense;
    if (expense == null) {
      final payment = entry.payment!;
      return _MovementRow(
        icon: Icons.lock_outline_rounded,
        title: 'Abono · ${entry.debtName}',
        subtitle:
            'Pago de deuda · ${_moneyMediumLabel(payment.medio, payment.cuentaDigitalId, accounts)}',
        amount: payment.monto,
        isDebt: true,
      );
    }

    final isDebtPayment = expense.pagoDeudaId != null;
    final isCreditPurchase = creditExpenseIds.contains(expense.id);
    final medium = _moneyMediumLabel(
      expense.medio,
      expense.cuentaDigitalId,
      accounts,
      isCreditPurchase: isCreditPurchase,
    );
    final canEdit = !isDebtPayment;
    return _MovementRow(
      icon: isDebtPayment ? Icons.lock_outline_rounded : Icons.receipt_outlined,
      title: expense.nombre,
      subtitle: isDebtPayment
          ? 'Abono de deuda · $medium'
          : '${expense.categoria} · $medium',
      amount: expense.monto,
      isDebt: isDebtPayment,
      onTap: canEdit ? () => onEdit(expense) : null,
      trailing: canEdit
          ? PopupMenuButton<String>(
              tooltip: 'Acciones de ${expense.nombre}',
              onSelected: (action) {
                if (action == 'edit') onEdit(expense);
                if (action == 'delete') onDelete(expense);
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Editar gasto')),
                PopupMenuItem(value: 'delete', child: Text('Eliminar gasto')),
              ],
              icon: const Icon(Icons.more_horiz_rounded),
            )
          : null,
    );
  }
}

class _MovementRow extends StatelessWidget {
  const _MovementRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.isDebt = false,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final double amount;
  final bool isDebt;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Row(
            children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isDebt ? AppColors.textSecondary : AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '−${_formatMoney(amount)}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.negative,
                ),
              ),
              if (isDebt)
                Text(
                  'Solo lectura',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
          if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDayHeading(String key) {
  final parts = key.split('-').map(int.parse).toList();
  final date = DateTime(parts[0], parts[1], parts[2]);
  final today = DateUtils.dateOnly(DateTime.now());
  final difference = today.difference(date).inDays;
  if (difference == 0) return 'Hoy';
  if (difference == 1) return 'Ayer';
  const months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  return '${date.day} de ${months[date.month - 1]}';
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({
    required this.expense,
    required this.mediumLabel,
    required this.isCreditPurchase,
    required this.isDebtPayment,
    required this.onEdit,
    required this.onDelete,
  });

  final Gasto expense;
  final String mediumLabel;
  final bool isCreditPurchase;
  final bool isDebtPayment;
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
          if (isCreditPurchase || isDebtPayment)
            Padding(
              padding: EdgeInsets.all(8),
              child: Icon(
                isCreditPurchase
                    ? Icons.credit_card_outlined
                    : Icons.payments_outlined,
                semanticLabel: isCreditPurchase
                    ? 'Compra financiada'
                    : 'Pago de deuda',
                color: AppColors.primary,
              ),
            )
          else
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
  const _DebtPaymentTile({
    required this.payment,
    required this.debtName,
    required this.mediumLabel,
  });

  final PagosDeudaData payment;
  final String debtName;
  final String mediumLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('debt-payment-expense-${payment.id}'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppCardDecorations.surface,
      child: Row(
        children: [
          Icon(Icons.payments_outlined, color: AppColors.primary),
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
                Text(mediumLabel),
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
  List<CuentasDigitale> accounts, {
  bool isCreditPurchase = false,
}) {
  if (isCreditPurchase) return 'Compra financiada';
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

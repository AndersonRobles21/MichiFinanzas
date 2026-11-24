import 'dart:math' as math;
import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../database/app_database.dart';
import '../../models/money_medium.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/money_format.dart';
import '../../utils/user_messages.dart';
import '../../widgets/app_page_header.dart';
import '../../widgets/cat_illustration.dart';

enum StatisticsPeriod { thisMonth, previousMonth, last7Days, last30Days }

extension on StatisticsPeriod {
  String get label => switch (this) {
    StatisticsPeriod.thisMonth => 'Este mes',
    StatisticsPeriod.previousMonth => 'Mes anterior',
    StatisticsPeriod.last7Days => 'Últimos 7 días',
    StatisticsPeriod.last30Days => 'Últimos 30 días',
  };
}

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({
    super.key,
    this.isActive = true,
    this.databaseService,
  });

  final bool isActive;
  final DatabaseService? databaseService;

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late final DatabaseService _databaseService;
  late final bool _ownsDatabaseService;
  late final StreamSubscription<void> _financialChanges;
  Future<_StatisticsData>? _statisticsFuture;
  StatisticsPeriod _period = StatisticsPeriod.thisMonth;
  String _view = 'general';

  @override
  void initState() {
    super.initState();
    _ownsDatabaseService = widget.databaseService == null;
    _databaseService = widget.databaseService ?? DatabaseService(AppDatabase());
    if (widget.isActive) _statisticsFuture = _loadData();
    _financialChanges = _databaseService.observarCambiosFinancieros().listen((
      _,
    ) {
      if (!mounted) return;
      setState(() {
        _statisticsFuture = _loadData();
      });
    });
  }

  @override
  void didUpdateWidget(covariant StatisticsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _statisticsFuture = _loadData();
    }
  }

  Future<_StatisticsData> _loadData() async {
    return runWithLoggedErrors('cargar estadísticas', () async {
      final results = await Future.wait<Object>([
        _databaseService.obtenerIngresos(),
        _databaseService.obtenerGastos(),
        _databaseService.obtenerMovimientosAhorro(),
        _databaseService.obtenerSaldosPorMedio(),
        _databaseService.obtenerTodosLosMovimientosReservaGastoFuturo(),
        _databaseService.obtenerTodosLosPagosDeuda(),
        _databaseService.obtenerCuentasDigitales(),
        _databaseService.obtenerGastosCreditoIds(),
      ]);
      final expenses = results[1] as List<Gasto>;
      final balances = results[3] as AvailableBalanceBreakdown;
      final representedPaymentIds = expenses
          .map((expense) => expense.pagoDeudaId)
          .whereType<int>()
          .toSet();
      return _StatisticsData(
        incomes: results[0] as List<Ingreso>,
        expenses: expenses,
        savingsMovements: results[2] as List<MovimientosAhorroData>,
        availableBalance: balances.total,
        balances: balances,
        futureExpenses: _netFutureExpenseReservations(
          results[4] as List<MovimientosReservaGastoFuturoData>,
        ),
        debtPayments: (results[5] as List<PagosDeudaData>)
            .where((payment) => !representedPaymentIds.contains(payment.id))
            .toList(),
        digitalAccounts: results[6] as List<DigitalAccountBalance>,
        creditExpenseIds: results[7] as Set<int>,
      );
    });
  }

  @override
  void dispose() {
    unawaited(_financialChanges.cancel());
    if (_ownsDatabaseService) unawaited(_databaseService.close());
    super.dispose();
  }

  void _retry() {
    setState(() {
      _statisticsFuture = _loadData();
    });
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
            return FutureBuilder<_StatisticsData>(
              future: _statisticsFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _StatisticsError(onRetry: _retry);
                }
                if (!snapshot.hasData) {
                  return const _StatisticsLoading();
                }

                final data = snapshot.data!;
                if (data.incomes.isEmpty &&
                    data.expenses.isEmpty &&
                    data.debtPayments.isEmpty &&
                    data.futureExpenses.isEmpty) {
                  return const _StatisticsEmpty();
                }

                final range = _StatisticsRange.forPeriod(
                  _period,
                  DateTime.now(),
                );
                final periodExpenses = data.expenses
                    .where((expense) => range.contains(expense.fecha))
                    .toList();
                final periodIncomes = data.incomes
                    .where((income) => range.contains(income.fecha))
                    .toList();
                final periodDebtPayments = data.debtPayments
                    .where((payment) => range.contains(payment.fecha))
                    .toList();
                final periodFutureExpenses = data.futureExpenses
                    .where((expense) => range.contains(expense.date))
                    .toList();
                final periodSavings = data.savingsMovements
                    .where((movement) => range.contains(movement.fecha))
                    .toList();
                final summary = _StatisticsSummary.fromRecords(
                  incomes: periodIncomes,
                  expenses: periodExpenses,
                  debtPayments: periodDebtPayments,
                  futureExpenses: periodFutureExpenses,
                  savingsMovements: periodSavings,
                  availableBalance: data.availableBalance,
                  creditExpenseIds: data.creditExpenseIds,
                );
                bool matchesView(String? medium) => switch (_view) {
                  'general' => true,
                  'efectivo' =>
                    MoneyMedium.fromStorage(medium) == MoneyMedium.cash,
                  'digital' =>
                    MoneyMedium.fromStorage(medium) == MoneyMedium.digital,
                  _ => false,
                };
                final selectedExpenses = periodExpenses
                    .where((expense) => matchesView(expense.medio))
                    .toList();
                final selectedDebtPayments = periodDebtPayments
                    .where((payment) => matchesView(payment.medio))
                    .toList();
                final selectedCategories = switch (_view) {
                  'efectivo' => summary.cashCategories,
                  'digital' => summary.digitalCategories,
                  _ => summary.categories,
                };
                final selectedExpenseCount =
                    selectedExpenses.length + selectedDebtPayments.length;
                final selectedIncomes = _view == 'general'
                    ? periodIncomes
                    : periodIncomes
                          .where((income) => matchesView(income.medio))
                          .toList();

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    AppSpacing.pageTop,
                    horizontalPadding,
                    36,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 960),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppPageHeader(
                            title: 'Estadísticas',
                            subtitle: '',
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Actualizar estadísticas',
                                  onPressed: _retry,
                                  icon: const Icon(Icons.refresh_rounded),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.section),
                          _PeriodSelector(
                            selected: _period,
                            onChanged: (period) => setState(() {
                              _period = period;
                            }),
                          ),
                          const SizedBox(height: 8),
                          _StatisticsViewSelector(
                            selected: _view,
                            onChanged: (view) => setState(() => _view = view),
                          ),
                          const SizedBox(height: 12),
                          _StatisticsKpis(
                            summary: summary,
                            view: _view,
                            expenseCount: selectedExpenseCount,
                            balance: switch (_view) {
                              'efectivo' => data.balances.cash,
                              'digital' => data.balances.digital,
                              _ => null,
                            },
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Gastos por categoría',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          _CategoryChart(
                            key: ValueKey('statistics-$_view-block'),
                            categories: selectedCategories,
                            remaining: null,
                            chartKey: ValueKey(
                              '$_view-category-pie-chart',
                            ),
                            showSpendingTotalKey: _view == 'general',
                            emptyMessage: 'Sin gastos en este período.',
                          ),
                          if (_view == 'general' &&
                              summary.unclassifiedExpenses > 0) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Movimientos sin medio: ${_formatMoney(summary.unclassifiedExpenses)}. Se incluyen aquí, no en efectivo ni digital.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                          if (_view == 'digital') ...[
                            const SizedBox(height: 18),
                            _DigitalAccountStatistics(
                              accounts: data.digitalAccounts
                                  .where((account) => account.balance > 1e-8)
                                  .map(
                                    (account) => _DigitalAccountPeriodSummary(
                                      account: account,
                                      expenses: periodExpenses
                                          .where(
                                            (expense) =>
                                                expense.cuentaDigitalId ==
                                                account.account.id,
                                          )
                                          .toList(),
                                      range: range,
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                          const SizedBox(height: 18),
                          Text(
                            'Tendencia de gastos',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          _TrendChart(
                            points: _dailyTotals(
                              range,
                              selectedIncomes,
                              selectedExpenses,
                              selectedDebtPayments,
                            ),
                          ),
                          if (_view == 'general') ...[
                            const SizedBox(height: 18),
                            Text(
                              'Los abonos de deudas se cuentan una sola vez y los préstamos recibidos no cuentan como ingreso. Lo reservado para gastos futuros y los aportes al ahorro no cuentan como gasto.',
                              style: Theme.of(context).textTheme.bodySmall,
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

class _StatisticsRange {
  const _StatisticsRange(this.start, this.endExclusive);

  final DateTime start;
  final DateTime endExclusive;

  bool contains(DateTime date) =>
      !date.isBefore(start) && date.isBefore(endExclusive);

  factory _StatisticsRange.forPeriod(StatisticsPeriod period, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    return switch (period) {
      StatisticsPeriod.thisMonth => _StatisticsRange(
        DateTime(today.year, today.month),
        tomorrow,
      ),
      StatisticsPeriod.previousMonth => _StatisticsRange(
        DateTime(today.year, today.month - 1),
        DateTime(today.year, today.month),
      ),
      StatisticsPeriod.last7Days => _StatisticsRange(
        today.subtract(const Duration(days: 6)),
        tomorrow,
      ),
      StatisticsPeriod.last30Days => _StatisticsRange(
        today.subtract(const Duration(days: 29)),
        tomorrow,
      ),
    };
  }

  int get dayCount => endExclusive.difference(start).inDays;
}

class _StatisticsData {
  const _StatisticsData({
    required this.incomes,
    required this.expenses,
    required this.savingsMovements,
    required this.availableBalance,
    required this.balances,
    required this.futureExpenses,
    required this.debtPayments,
    required this.digitalAccounts,
    required this.creditExpenseIds,
  });

  final List<Ingreso> incomes;
  final List<Gasto> expenses;
  final List<MovimientosAhorroData> savingsMovements;
  final double availableBalance;
  final AvailableBalanceBreakdown balances;
  final List<_FutureExpenseReservation> futureExpenses;
  final List<PagosDeudaData> debtPayments;
  final List<DigitalAccountBalance> digitalAccounts;
  final Set<int> creditExpenseIds;
}

class _DigitalAccountPeriodSummary {
  const _DigitalAccountPeriodSummary({
    required this.account,
    required this.expenses,
    required this.range,
  });

  final DigitalAccountBalance account;
  final List<Gasto> expenses;
  final _StatisticsRange range;

  double get spent =>
      expenses.fold<double>(0, (total, expense) => total + expense.monto);
}

class _DigitalAccountStatistics extends StatelessWidget {
  const _DigitalAccountStatistics({required this.accounts});

  final List<_DigitalAccountPeriodSummary> accounts;

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Por cuenta digital',
          key: const ValueKey('statistics-accounts-title'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(
          'Saldos actuales y gastos del período en cuentas con dinero disponible.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        for (final account in accounts)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _DigitalAccountStatisticsCard(summary: account),
          ),
      ],
    );
  }
}

class _DigitalAccountStatisticsCard extends StatelessWidget {
  const _DigitalAccountStatisticsCard({required this.summary});

  final _DigitalAccountPeriodSummary summary;

  @override
  Widget build(BuildContext context) {
    final name = summary.account.account.nombre;
    final expenseDays = summary.expenses
        .map(
          (expense) => DateTime(
            expense.fecha.year,
            expense.fecha.month,
            expense.fecha.day,
          ),
        )
        .toSet();
    return Container(
      key: ValueKey('statistics-account-${summary.account.account.id}'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.card),
      decoration: AppCardDecorations.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                child: Text(
                  name.substring(0, 1).toUpperCase(),
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.accent),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _AccountMetric(
                  label: 'Saldo actual',
                  amount: summary.account.balance,
                  amountKey: ValueKey(
                    'statistics-account-balance-${summary.account.account.id}',
                  ),
                  color: AppColors.positive,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AccountMetric(
                  label: 'Gastos del período',
                  amount: summary.spent,
                  amountKey: ValueKey(
                    'statistics-account-spent-${summary.account.account.id}',
                  ),
                  color: AppColors.negative,
                ),
              ),
            ],
          ),
          if (expenseDays.length > 1) ...[
            const SizedBox(height: 14),
            Text(
              'Evolución de gastos',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            _AccountSpendingTrend(summary: summary),
          ],
        ],
      ),
    );
  }
}

class _AccountMetric extends StatelessWidget {
  const _AccountMetric({
    required this.label,
    required this.amount,
    required this.amountKey,
    required this.color,
  });

  final String label;
  final double amount;
  final Key amountKey;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          _formatMoney(amount),
          key: amountKey,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _AccountSpendingTrend extends StatelessWidget {
  const _AccountSpendingTrend({required this.summary});

  final _DigitalAccountPeriodSummary summary;

  @override
  Widget build(BuildContext context) {
    final totals = List<double>.filled(summary.range.dayCount, 0);
    for (final expense in summary.expenses) {
      final date = DateTime(
        expense.fecha.year,
        expense.fecha.month,
        expense.fecha.day,
      );
      final index = date.difference(summary.range.start).inDays;
      if (index >= 0 && index < totals.length) totals[index] += expense.monto;
    }
    final maxAmount = totals.fold<double>(
      0,
      (maximum, amount) => math.max(maximum, amount),
    );
    return SizedBox(
      key: ValueKey('statistics-account-trend-${summary.account.account.id}'),
      height: 72,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: math.max(1, maxAmount * 1.15),
          minX: 0,
          maxX: math.max(1, totals.length - 1).toDouble(),
          titlesData: const FlTitlesData(show: false),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var index = 0; index < totals.length; index++)
                  FlSpot(index.toDouble(), totals[index]),
              ],
              isCurved: true,
              color: AppColors.primary,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FutureExpenseReservation {
  const _FutureExpenseReservation({required this.date, required this.amount});

  final DateTime date;
  final double amount;
}

class _FutureExpenseReservationBalance {
  _FutureExpenseReservationBalance(this.date, this.remaining);

  final DateTime date;
  double remaining;
}

List<_FutureExpenseReservation> _netFutureExpenseReservations(
  List<MovimientosReservaGastoFuturoData> movements,
) {
  final orderedMovements = [...movements]
    ..sort((first, second) {
      final dateOrder = first.fecha.compareTo(second.fecha);
      return dateOrder != 0 ? dateOrder : first.id.compareTo(second.id);
    });
  final reservationsByPlan = <int?, List<_FutureExpenseReservationBalance>>{};

  for (final movement in orderedMovements) {
    final reservations = reservationsByPlan.putIfAbsent(
      movement.gastoFuturoId,
      () => [],
    );
    if (movement.tipo == DatabaseService.reservaGastoFuturo) {
      reservations.add(
        _FutureExpenseReservationBalance(movement.fecha, movement.monto),
      );
      continue;
    }
    if (movement.tipo != DatabaseService.liberacionGastoFuturo) continue;

    var remainingRelease = movement.monto;
    for (final reservation in reservations) {
      if (remainingRelease <= 1e-8) break;
      if (reservation.remaining <= 1e-8) continue;
      final released = math.min(reservation.remaining, remainingRelease);
      reservation.remaining -= released;
      remainingRelease -= released;
    }
  }

  return [
    for (final reservations in reservationsByPlan.values)
      for (final reservation in reservations)
        if (reservation.remaining > 1e-8)
          _FutureExpenseReservation(
            date: reservation.date,
            amount: reservation.remaining,
          ),
  ];
}

class _CategoryTotal {
  const _CategoryTotal(this.name, this.amount);

  final String name;
  final double amount;
}

class _StatisticsSummary {
  const _StatisticsSummary({
    required this.incomeTotal,
    required this.expenseTotal,
    required this.expenseCount,
    required this.expenseAverage,
    required this.availableBalance,
    required this.savingsContributions,
    required this.savingsWithdrawals,
    required this.reservedTotal,
    required this.categories,
    required this.cashCategories,
    required this.digitalCategories,
    required this.unclassifiedExpenses,
    required this.generalRemaining,
    required this.cashRemaining,
    required this.digitalRemaining,
  });

  factory _StatisticsSummary.fromRecords({
    required List<Ingreso> incomes,
    required List<Gasto> expenses,
    required List<PagosDeudaData> debtPayments,
    required List<_FutureExpenseReservation> futureExpenses,
    required List<MovimientosAhorroData> savingsMovements,
    required double availableBalance,
    required Set<int> creditExpenseIds,
  }) {
    final categoryAmounts = <String, double>{};
    final cashCategoryAmounts = <String, double>{};
    final digitalCategoryAmounts = <String, double>{};
    var cashExpenses = 0.0;
    var digitalExpenses = 0.0;
    var unclassifiedExpenses = 0.0;

    void addCategory(
      Map<String, double> totals,
      String category,
      double amount,
    ) {
      totals.update(
        category,
        (previous) => previous + amount,
        ifAbsent: () => amount,
      );
    }

    for (final expense in expenses) {
      categoryAmounts.update(
        expense.categoria,
        (amount) => amount + expense.monto,
        ifAbsent: () => expense.monto,
      );
      switch (MoneyMedium.fromStorage(expense.medio)) {
        case MoneyMedium.cash:
          cashExpenses += expense.monto;
          addCategory(cashCategoryAmounts, expense.categoria, expense.monto);
        case MoneyMedium.digital:
          digitalExpenses += expense.monto;
          addCategory(digitalCategoryAmounts, expense.categoria, expense.monto);
        case null:
          if (!creditExpenseIds.contains(expense.id)) {
            unclassifiedExpenses += expense.monto;
          }
      }
    }
    for (final payment in debtPayments) {
      categoryAmounts.update(
        'Pagos de deudas',
        (amount) => amount + payment.monto,
        ifAbsent: () => payment.monto,
      );
      switch (MoneyMedium.fromStorage(payment.medio)) {
        case MoneyMedium.cash:
          cashExpenses += payment.monto;
          addCategory(cashCategoryAmounts, 'Pagos de deudas', payment.monto);
        case MoneyMedium.digital:
          digitalExpenses += payment.monto;
          addCategory(digitalCategoryAmounts, 'Pagos de deudas', payment.monto);
        case null:
          unclassifiedExpenses += payment.monto;
      }
    }
    final expenseTotal =
        expenses.fold<double>(0, (sum, expense) => sum + expense.monto) +
        debtPayments.fold<double>(0, (sum, payment) => sum + payment.monto);
    final reservedTotal = futureExpenses.fold<double>(
      0,
      (sum, reservation) => sum + reservation.amount,
    );
    final incomeTotal = incomes.fold<double>(
      0,
      (sum, income) => sum + income.monto,
    );
    var cashIncomeTotal = 0.0;
    var digitalIncomeTotal = 0.0;
    for (final income in incomes) {
      switch (MoneyMedium.fromStorage(income.medio)) {
        case MoneyMedium.cash:
          cashIncomeTotal += income.monto;
        case MoneyMedium.digital:
          digitalIncomeTotal += income.monto;
        case null:
          break;
      }
    }
    final savingsContributions = savingsMovements
        .where((movement) => movement.tipo == DatabaseService.aporteAhorro)
        .fold<double>(0, (sum, movement) => sum + movement.monto);
    final savingsWithdrawals = savingsMovements
        .where((movement) => movement.tipo == DatabaseService.retiroAhorro)
        .fold<double>(0, (sum, movement) => sum + movement.monto);
    final categories =
        categoryAmounts.entries
            .map((entry) => _CategoryTotal(entry.key, entry.value))
            .toList()
          ..sort(_compareCategoryTotals);
    final cashCategories =
        cashCategoryAmounts.entries
            .map((entry) => _CategoryTotal(entry.key, entry.value))
            .toList()
          ..sort(_compareCategoryTotals);
    final digitalCategories =
        digitalCategoryAmounts.entries
            .map((entry) => _CategoryTotal(entry.key, entry.value))
            .toList()
          ..sort(_compareCategoryTotals);
    final generalRemaining = incomeTotal > 0 && incomeTotal >= expenseTotal
        ? incomeTotal - expenseTotal
        : null;
    final cashRemaining =
        unclassifiedExpenses == 0 &&
            cashIncomeTotal > 0 &&
            cashIncomeTotal >= cashExpenses
        ? cashIncomeTotal - cashExpenses
        : null;
    final digitalRemaining =
        unclassifiedExpenses == 0 &&
            digitalIncomeTotal > 0 &&
            digitalIncomeTotal >= digitalExpenses
        ? digitalIncomeTotal - digitalExpenses
        : null;

    return _StatisticsSummary(
      incomeTotal: incomeTotal,
      expenseTotal: expenseTotal,
      expenseCount: expenses.length + debtPayments.length,
      expenseAverage: expenses.isEmpty && debtPayments.isEmpty
          ? 0
          : expenseTotal / (expenses.length + debtPayments.length),
      availableBalance: availableBalance,
      savingsContributions: savingsContributions,
      savingsWithdrawals: savingsWithdrawals,
      reservedTotal: reservedTotal,
      categories: categories,
      cashCategories: cashCategories,
      digitalCategories: digitalCategories,
      unclassifiedExpenses: unclassifiedExpenses,
      generalRemaining: generalRemaining,
      cashRemaining: cashRemaining,
      digitalRemaining: digitalRemaining,
    );
  }

  final double incomeTotal;
  final double expenseTotal;
  final int expenseCount;
  final double expenseAverage;
  final double availableBalance;
  final double savingsContributions;
  final double savingsWithdrawals;
  final double reservedTotal;
  final List<_CategoryTotal> categories;
  final List<_CategoryTotal> cashCategories;
  final List<_CategoryTotal> digitalCategories;
  final double unclassifiedExpenses;
  final double? generalRemaining;
  final double? cashRemaining;
  final double? digitalRemaining;
}

int _compareCategoryTotals(_CategoryTotal first, _CategoryTotal second) {
  final amountOrder = second.amount.compareTo(first.amount);
  return amountOrder != 0 ? amountOrder : first.name.compareTo(second.name);
}

class _DailyTotal {
  const _DailyTotal(this.date, this.income, this.expense);

  final DateTime date;
  final double income;
  final double expense;
}

List<_DailyTotal> _dailyTotals(
  _StatisticsRange range,
  List<Ingreso> incomes,
  List<Gasto> expenses,
  List<PagosDeudaData> debtPayments,
) {
  final incomeByDay = <DateTime, double>{};
  final expenseByDay = <DateTime, double>{};
  for (final income in incomes) {
    final day = DateTime(
      income.fecha.year,
      income.fecha.month,
      income.fecha.day,
    );
    incomeByDay.update(
      day,
      (amount) => amount + income.monto,
      ifAbsent: () => income.monto,
    );
  }
  for (final expense in expenses) {
    final day = DateTime(
      expense.fecha.year,
      expense.fecha.month,
      expense.fecha.day,
    );
    expenseByDay.update(
      day,
      (amount) => amount + expense.monto,
      ifAbsent: () => expense.monto,
    );
  }
  for (final payment in debtPayments) {
    final day = DateTime(
      payment.fecha.year,
      payment.fecha.month,
      payment.fecha.day,
    );
    expenseByDay.update(
      day,
      (amount) => amount + payment.monto,
      ifAbsent: () => payment.monto,
    );
  }
  return List.generate(range.dayCount, (index) {
    final day = range.start.add(Duration(days: index));
    return _DailyTotal(day, incomeByDay[day] ?? 0, expenseByDay[day] ?? 0);
  });
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selected, required this.onChanged});

  final StatisticsPeriod selected;
  final ValueChanged<StatisticsPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final period in StatisticsPeriod.values)
          _StatisticsChip(
            key: ValueKey('period-${period.name}'),
            label: period.label,
            selected: selected == period,
            onTap: () => onChanged(period),
          ),
      ],
    );
  }
}

class _StatisticsChip extends StatelessWidget {
  const _StatisticsChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
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
              color: selected
                  ? AppColors.actionForeground
                  : AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatisticsViewSelector extends StatelessWidget {
  const _StatisticsViewSelector({
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const views = [
      ('general', 'General'),
      ('efectivo', 'Efectivo'),
      ('digital', 'Digital'),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final view in views)
            Expanded(
              child: Material(
                color: selected == view.$1
                    ? AppColors.surface
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
                child: InkWell(
                  borderRadius: BorderRadius.circular(11),
                  onTap: () => onChanged(view.$1),
                  child: SizedBox(
                    height: 40,
                    child: Center(
                      child: Text(
                        view.$2,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: selected == view.$1
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatisticsKpis extends StatelessWidget {
  const _StatisticsKpis({
    required this.summary,
    required this.view,
    required this.expenseCount,
    required this.balance,
  });

  final _StatisticsSummary summary;
  final String view;
  final int expenseCount;
  final double? balance;

  @override
  Widget build(BuildContext context) {
    final selectedCategories = switch (view) {
      'efectivo' => summary.cashCategories,
      'digital' => summary.digitalCategories,
      _ => summary.categories,
    };
    final spent = selectedCategories.fold<double>(
      0,
      (total, category) => total + category.amount,
    );
    final List<_StatisticsMetric> metrics = view == 'general'
        ? [
            _StatisticsMetric(
              label: 'Ingresos',
              value: summary.incomeTotal,
              color: AppColors.positive,
            ),
            _StatisticsMetric(
              label: 'Gastos',
              value: summary.expenseTotal,
              color: AppColors.negative,
            ),
            _StatisticsMetric(
              label: 'Restante',
              value: summary.generalRemaining ?? 0,
              color: AppColors.textPrimary,
            ),
          ]
        : [
            _StatisticsMetric(
              label: 'Gastado',
              value: spent,
              color: AppColors.negative,
            ),
            _StatisticsMetric(
              label: 'Movimientos',
              value: expenseCount.toDouble(),
              color: AppColors.textPrimary,
              isCount: true,
            ),
            _StatisticsMetric(
              label: 'Saldo actual',
              value: balance ?? 0,
              color: AppColors.textPrimary,
            ),
          ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = 8.0;
        final width = (constraints.maxWidth - gap * 2) / 3;
        return Wrap(
          spacing: gap,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: width,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: AppCardDecorations.surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        metric.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        metric.isCount
                            ? '${metric.value.round()}'
                            : _formatMoney(metric.value),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: metric.color,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StatisticsMetric {
  const _StatisticsMetric({
    required this.label,
    required this.value,
    required this.color,
    this.isCount = false,
  });

  final String label;
  final double value;
  final Color color;
  final bool isCount;
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.summary});

  final _StatisticsSummary summary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 4 : 2;
        final gap = 10.0;
        final cardWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        final leadingCategory = summary.categories.isEmpty
            ? null
            : summary.categories.first;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                key: const ValueKey('statistics-income-total'),
                icon: Icons.south_west_rounded,
                label: 'Ingresos del período',
                value: _formatMoney(summary.incomeTotal),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                key: const ValueKey('statistics-total'),
                icon: Icons.north_east_rounded,
                label: 'Gastos del período',
                value: _formatMoney(summary.expenseTotal),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                key: const ValueKey('statistics-available-balance'),
                icon: Icons.account_balance_wallet_outlined,
                label: 'Saldo actual · no filtrado',
                value: _formatMoney(summary.availableBalance),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                key: const ValueKey('statistics-reserved-total'),
                icon: Icons.lock_clock_outlined,
                label: 'Reservado · no gastado',
                value: _formatMoney(summary.reservedTotal),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                key: const ValueKey('statistics-count'),
                icon: Icons.receipt_long_outlined,
                label: 'Gastos registrados',
                value: '${summary.expenseCount}',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                key: const ValueKey('statistics-top-category'),
                icon: Icons.category_outlined,
                label: 'Mayor categoría',
                value: leadingCategory?.name ?? '—',
                detail: leadingCategory == null
                    ? null
                    : _formatMoney(leadingCategory.amount),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                key: const ValueKey('statistics-average'),
                icon: Icons.calculate_outlined,
                label: 'Promedio por gasto',
                value: summary.expenseCount == 0
                    ? '—'
                    : _formatMoney(summary.expenseAverage),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SavingsMovementSummary extends StatelessWidget {
  const _SavingsMovementSummary({required this.summary});

  final _StatisticsSummary summary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = 10.0;
        final width = constraints.maxWidth >= 560
            ? (constraints.maxWidth - gap) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: width,
              child: _SummaryCard(
                key: const ValueKey('statistics-savings-contributions'),
                icon: Icons.savings_outlined,
                label: 'Aportes (transferencia interna)',
                value: _formatMoney(summary.savingsContributions),
              ),
            ),
            SizedBox(
              width: width,
              child: _SummaryCard(
                key: const ValueKey('statistics-savings-withdrawals'),
                icon: Icons.output_rounded,
                label: 'Retiros (transferencia interna)',
                value: _formatMoney(summary.savingsWithdrawals),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    this.detail,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 126),
      padding: const EdgeInsets.all(15),
      decoration: AppCardDecorations.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 10),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (detail != null) ...[
            const SizedBox(height: 2),
            Text(detail!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class _CategoryChart extends StatelessWidget {
  const _CategoryChart({
    required this.categories,
    required this.remaining,
    required this.chartKey,
    required this.showSpendingTotalKey,
    required this.emptyMessage,
    super.key,
  });

  final List<_CategoryTotal> categories;
  final double? remaining;
  final Key chartKey;
  final bool showSpendingTotalKey;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final spending = categories.fold<double>(
      0,
      (total, category) => total + category.amount,
    );
    final base = spending + (remaining ?? 0);
    if (categories.isEmpty && remaining == null) {
      return _ChartPanel(child: _ChartEmpty(emptyMessage));
    }
    return _ChartPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final chart = SizedBox(
                key: chartKey,
                width: 220,
                height: 210,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 55,
                        sections: [
                          for (
                            var index = 0;
                            index < categories.length;
                            index++
                          )
                            PieChartSectionData(
                              value: categories[index].amount,
                              color:
                                  AppColors.chartPalette[index %
                                      AppColors.chartPalette.length],
                              radius: 48,
                              showTitle: false,
                            ),
                          if ((remaining ?? 0) > 0)
                            PieChartSectionData(
                              value: remaining!,
                              color: AppColors.outline,
                              radius: 48,
                              showTitle: false,
                            ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Gastado',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          _formatMoney(spending),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              );
              final legend = Column(
                children: [
                  for (var index = 0; index < categories.length; index++)
                    _CategoryLegendRow(
                      key: ValueKey(
                        'statistics-category-${categories[index].name}',
                      ),
                      category: categories[index],
                      color: AppColors
                          .chartPalette[index % AppColors.chartPalette.length],
                      total: base,
                    ),
                  if (remaining != null)
                    _RemainingLegendRow(amount: remaining!, total: base),
                ],
              );

              if (constraints.maxWidth >= 620) {
                return Row(
                  children: [
                    chart,
                    const SizedBox(width: 24),
                    Expanded(child: legend),
                  ],
                );
              }
              return Column(
                children: [chart, const SizedBox(height: 12), legend],
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total gastado',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                _formatMoney(spending),
                key: showSpendingTotalKey
                    ? const ValueKey('statistics-recorded-spending-total')
                    : null,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          if (remaining != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Dinero restante de la base',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Text(_formatMoney(remaining!)),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text(
            remaining == null
                ? 'No se muestra un restante cuando no puede calcularse con '
                      'movimientos clasificados de este período.'
                : 'El restante se calcula con ingresos del período menos '
                      'gastos y pagos de deuda registrados.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _RemainingLegendRow extends StatelessWidget {
  const _RemainingLegendRow({required this.amount, required this.total});

  final double amount;
  final double total;

  @override
  Widget build(BuildContext context) {
    final share = total <= 0 ? 0 : amount / total * 100;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: AppColors.outline,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 9),
          const Expanded(child: Text('Dinero restante')),
          Text(_formatMoney(amount)),
          const SizedBox(width: 8),
          SizedBox(
            width: 42,
            child: Text(
              '${share.toStringAsFixed(0)}%',
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryLegendRow extends StatelessWidget {
  const _CategoryLegendRow({
    super.key,
    required this.category,
    required this.color,
    required this.total,
  });

  final _CategoryTotal category;
  final Color color;
  final double total;

  @override
  Widget build(BuildContext context) {
    final share = total == 0 ? 0 : category.amount / total * 100;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatMoney(category.amount),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 42,
            child: Text(
              '${share.toStringAsFixed(0)}%',
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.points});

  final List<_DailyTotal> points;

  @override
  Widget build(BuildContext context) {
    return _ChartPanel(
      child: points.every((point) => point.income == 0 && point.expense == 0)
          ? const _ChartEmpty('Sin ingresos ni gastos en este período.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 18,
                  runSpacing: 8,
                  children: [
                    _ChartLegend(color: AppColors.positive, label: 'Ingresos'),
                    _ChartLegend(color: AppColors.negative, label: 'Gastos'),
                  ],
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final chartWidth = math.max(
                      constraints.maxWidth,
                      points.length * 27.0,
                    );
                    final maxAmount = points.fold<double>(
                      0,
                      (current, point) => math.max(
                        current,
                        math.max(point.income, point.expense),
                      ),
                    );
                    final labelInterval = math.max(
                      1,
                      (points.length / 7).ceil(),
                    );

                    return SingleChildScrollView(
                      key: const ValueKey('trend-chart-scroll'),
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        key: const ValueKey('trend-bar-chart'),
                        width: chartWidth,
                        height: 240,
                        child: BarChart(
                          BarChartData(
                            minY: 0,
                            maxY: maxAmount == 0 ? 1 : maxAmount * 1.18,
                            barGroups: [
                              for (
                                var index = 0;
                                index < points.length;
                                index++
                              )
                                BarChartGroupData(
                                  x: index,
                                  barRods: [
                                    BarChartRodData(
                                      toY: points[index].income,
                                      color: AppColors.positive,
                                      width: 9,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    BarChartRodData(
                                      toY: points[index].expense,
                                      color: AppColors.negative,
                                      width: 9,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ],
                                ),
                            ],
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: maxAmount == 0
                                  ? 1
                                  : maxAmount / 4,
                              getDrawingHorizontalLine: (_) => FlLine(
                                color: AppColors.outline.withValues(
                                  alpha: 0.65,
                                ),
                                strokeWidth: 1,
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 48,
                                  getTitlesWidget: (value, meta) => Text(
                                    _formatAxisMoney(value),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontSize: 10),
                                  ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 34,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index < 0 || index >= points.length) {
                                      return const SizedBox.shrink();
                                    }
                                    if (index % labelInterval != 0 &&
                                        index != points.length - 1) {
                                      return const SizedBox.shrink();
                                    }
                                    return SideTitleWidget(
                                      meta: meta,
                                      space: 8,
                                      child: Text(
                                        '${points[index].date.day}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(fontSize: 10),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  final date = points[group.x].date;
                                  return BarTooltipItem(
                                    '${rodIndex == 0 ? 'Ingreso' : 'Gasto'} · ${date.day}/${date.month}\n${_formatMoney(rod.toY)}',
                                    TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 9, height: 9, color: color),
        const SizedBox(width: 7),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _ChartPanel extends StatelessWidget {
  const _ChartPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppCardDecorations.surface,
      child: child,
    );
  }
}

class _ChartEmpty extends StatelessWidget {
  const _ChartEmpty(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _StatisticsLoading extends StatelessWidget {
  const _StatisticsLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Estamos preparando tus estadísticas...',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _StatisticsEmpty extends StatelessWidget {
  const _StatisticsEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AnimatedCat(
                asset: CatAssets.vacio,
                label: 'Gato descansando, sin registros',
                width: 156,
                height: 116,
              ),
              const SizedBox(height: 16),
              Text(
                'Todavía no hay movimientos por aquí. '
                'Cuando aparezcan, los revisamos juntos.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Cuando tengas ingresos o gastos, aquí veremos cómo se mueve tu dinero.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatisticsError extends StatelessWidget {
  const _StatisticsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              'Ups, tus estadísticas no cargaron esta vez.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Intentar de nuevo'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatMoney(double amount) {
  return formatMoney(amount);
}

String _formatAxisMoney(double amount) {
  if (amount >= 1000000) return '\$ ${formatAmount(amount / 1000000)} M';
  if (amount >= 1000) return '\$ ${formatAmount(amount / 1000)} mil';
  return formatMoney(amount);
}

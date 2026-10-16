import 'dart:math' as math;
import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../database/app_database.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/money_format.dart';
import '../../utils/user_messages.dart';
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
        _databaseService.obtenerSaldoDisponible(),
        _databaseService.obtenerTodosLosMovimientosReservaGastoFuturo(),
      ]);
      return _StatisticsData(
        incomes: results[0] as List<Ingreso>,
        expenses: results[1] as List<Gasto>,
        savingsMovements: results[2] as List<MovimientosAhorroData>,
        availableBalance: results[3] as double,
        futureExpenses: _netFutureExpenseReservations(
          results[4] as List<MovimientosReservaGastoFuturoData>,
        ),
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
            final horizontalPadding = constraints.maxWidth < 420 ? 20.0 : 36.0;
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
                final periodFutureExpenses = data.futureExpenses
                    .where((expense) => range.contains(expense.date))
                    .toList();
                final periodSavings = data.savingsMovements
                    .where((movement) => range.contains(movement.fecha))
                    .toList();
                final summary = _StatisticsSummary.fromRecords(
                  incomes: periodIncomes,
                  expenses: periodExpenses,
                  futureExpenses: periodFutureExpenses,
                  savingsMovements: periodSavings,
                  availableBalance: data.availableBalance,
                );

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    28,
                    horizontalPadding,
                    36,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 960),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Estadísticas',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.headlineMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Ingresos, gastos y ahorros en un vistazo.',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              const AnimatedCat(
                                asset: CatAssets.estadisticas,
                                label: 'Gato revisando estadísticas',
                                width: 88,
                                height: 66,
                              ),
                              IconButton(
                                tooltip: 'Actualizar estadísticas',
                                onPressed: _retry,
                                icon: const Icon(Icons.refresh_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          _PeriodSelector(
                            selected: _period,
                            onChanged: (period) => setState(() {
                              _period = period;
                            }),
                          ),
                          const SizedBox(height: 24),
                          _SummaryGrid(summary: summary),
                          const SizedBox(height: 28),
                          Text(
                            'Gastos por categoría',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          _CategoryChart(categories: summary.categories),
                          const SizedBox(height: 28),
                          Text(
                            'Evolución del dinero',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          _TrendChart(
                            points: _dailyTotals(
                              range,
                              periodIncomes,
                              periodExpenses,
                              periodFutureExpenses,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'Movimientos de ahorro',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Aportes y retiros son transferencias internas; no cuentan como ingresos ni gastos.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          _SavingsMovementSummary(summary: summary),
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
    required this.futureExpenses,
  });

  final List<Ingreso> incomes;
  final List<Gasto> expenses;
  final List<MovimientosAhorroData> savingsMovements;
  final double availableBalance;
  final List<_FutureExpenseReservation> futureExpenses;
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
    required this.categories,
  });

  factory _StatisticsSummary.fromRecords({
    required List<Ingreso> incomes,
    required List<Gasto> expenses,
    required List<_FutureExpenseReservation> futureExpenses,
    required List<MovimientosAhorroData> savingsMovements,
    required double availableBalance,
  }) {
    final categoryAmounts = <String, double>{};
    var expenseTotal = expenses.fold<double>(0, (sum, expense) {
      categoryAmounts.update(
        expense.categoria,
        (amount) => amount + expense.monto,
        ifAbsent: () => expense.monto,
      );
      return sum + expense.monto;
    });
    for (final expense in futureExpenses) {
      categoryAmounts.update(
        'Gastos futuros',
        (amount) => amount + expense.amount,
        ifAbsent: () => expense.amount,
      );
      expenseTotal += expense.amount;
    }
    final expenseCount = expenses.length + futureExpenses.length;
    final incomeTotal = incomes.fold<double>(
      0,
      (sum, income) => sum + income.monto,
    );
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
          ..sort((a, b) {
            final amountOrder = b.amount.compareTo(a.amount);
            return amountOrder != 0 ? amountOrder : a.name.compareTo(b.name);
          });

    return _StatisticsSummary(
      incomeTotal: incomeTotal,
      expenseTotal: expenseTotal,
      expenseCount: expenseCount,
      expenseAverage: expenseCount == 0 ? 0 : expenseTotal / expenseCount,
      availableBalance: availableBalance,
      savingsContributions: savingsContributions,
      savingsWithdrawals: savingsWithdrawals,
      categories: categories,
    );
  }

  final double incomeTotal;
  final double expenseTotal;
  final int expenseCount;
  final double expenseAverage;
  final double availableBalance;
  final double savingsContributions;
  final double savingsWithdrawals;
  final List<_CategoryTotal> categories;
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
  List<_FutureExpenseReservation> futureExpenses,
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
  for (final expense in futureExpenses) {
    final day = DateTime(
      expense.date.year,
      expense.date.month,
      expense.date.day,
    );
    expenseByDay.update(
      day,
      (amount) => amount + expense.amount,
      ifAbsent: () => expense.amount,
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
          ChoiceChip(
            key: ValueKey('period-${period.name}'),
            label: Text(period.label),
            selected: selected == period,
            onSelected: (_) => onChanged(period),
            showCheckmark: false,
          ),
      ],
    );
  }
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
                label: 'Saldo disponible',
                value: _formatMoney(summary.availableBalance),
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
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outline),
      ),
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

const _chartColors = [
  AppColors.primary,
  Color(0xFF74C8B0),
  Color(0xFFFFB86B),
  Color(0xFF86A7F5),
  Color(0xFFE98D9B),
  Color(0xFFC9C46C),
  Color(0xFF9F8AD8),
  Color(0xFF64B5CD),
];

class _CategoryChart extends StatelessWidget {
  const _CategoryChart({required this.categories});

  final List<_CategoryTotal> categories;

  @override
  Widget build(BuildContext context) {
    return _ChartPanel(
      child: categories.isEmpty
          ? const _ChartEmpty('Sin gastos en este período.')
          : LayoutBuilder(
              builder: (context, constraints) {
                final chart = SizedBox(
                  key: const ValueKey('category-pie-chart'),
                  width: 220,
                  height: 210,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 55,
                      sections: [
                        for (var index = 0; index < categories.length; index++)
                          PieChartSectionData(
                            value: categories[index].amount,
                            color: _chartColors[index % _chartColors.length],
                            radius: 48,
                            showTitle: false,
                          ),
                      ],
                    ),
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
                        color: _chartColors[index % _chartColors.length],
                        total: categories.fold<double>(
                          0,
                          (sum, category) => sum + category.amount,
                        ),
                      ),
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
                const Wrap(
                  spacing: 18,
                  runSpacing: 8,
                  children: [
                    _ChartLegend(color: Color(0xFF65B89C), label: 'Ingresos'),
                    _ChartLegend(color: Color(0xFFE98D9B), label: 'Gastos'),
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
                                      color: const Color(0xFF65B89C),
                                      width: 9,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    BarChartRodData(
                                      toY: points[index].expense,
                                      color: const Color(0xFFE98D9B),
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
                                    const TextStyle(
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
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outline),
      ),
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
                'Todavía no hay movimientos por aquí.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Cuando tengas ingresos o gastos, aquí verás cómo se mueve tu dinero.',
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
            const Icon(Icons.cloud_off_outlined, color: AppColors.primary),
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

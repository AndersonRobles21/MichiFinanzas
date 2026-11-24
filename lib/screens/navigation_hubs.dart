import 'dart:async';

import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/future_expense.dart';
import '../models/income_type.dart';
import '../models/money_medium.dart';
import '../models/subscription.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../utils/money_format.dart';
import '../widgets/app_page_header.dart';
import '../widgets/cat_illustration.dart';
import 'expenses/expenses_screen.dart';
import 'home/home_screen.dart';

class MovementsScreen extends StatefulWidget {
  const MovementsScreen({
    super.key,
    required this.databaseService,
    required this.initialTab,
    required this.expenseRegisterRequestId,
    required this.incomeRegisterRequestId,
  });

  final DatabaseService databaseService;
  final int initialTab;
  final int expenseRegisterRequestId;
  final int incomeRegisterRequestId;

  @override
  State<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends State<MovementsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;
  late int _currentTab;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
    _controller = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    )..addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (_controller.index != _currentTab) {
      setState(() => _currentTab = _controller.index);
    }
  }

  @override
  void didUpdateWidget(covariant MovementsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab &&
        _controller.index != widget.initialTab) {
      _controller.animateTo(widget.initialTab);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTabChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: const AppPageHeader(title: 'Movimientos', subtitle: ''),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _MovementTabButton(
                      label: 'Gastos',
                      selected: _currentTab == 0,
                      onTap: () => _controller.animateTo(0),
                    ),
                    _MovementTabButton(
                      label: 'Ingresos',
                      selected: _currentTab == 1,
                      onTap: () => _controller.animateTo(1),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _controller,
                children: [
                  ExpensesScreen(
                    key: const ValueKey('movements-expenses'),
                    databaseService: widget.databaseService,
                    isActive: _currentTab == 0,
                    registerRequestId: widget.expenseRegisterRequestId,
                  ),
                  IncomesScreen(
                    key: const ValueKey('movements-incomes'),
                    databaseService: widget.databaseService,
                    isActive: _currentTab == 1,
                    registerRequestId: widget.incomeRegisterRequestId,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MovementTabButton extends StatelessWidget {
  const _MovementTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? AppColors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: onTap,
          child: SizedBox(
            height: 40,
            child: Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CommitmentsHubScreen extends StatefulWidget {
  const CommitmentsHubScreen({
    super.key,
    required this.databaseService,
    required this.onSubscriptions,
    required this.onFutureExpenses,
    required this.onDebts,
    required this.onCredits,
  });

  final DatabaseService databaseService;
  final VoidCallback onSubscriptions;
  final VoidCallback onFutureExpenses;
  final VoidCallback onDebts;
  final VoidCallback onCredits;

  @override
  State<CommitmentsHubScreen> createState() => _CommitmentsHubScreenState();
}

class _CommitmentsHubScreenState extends State<CommitmentsHubScreen> {
  late Future<_CommitmentsData> _dataFuture;
  late final StreamSubscription<void> _financialChanges;

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
    _financialChanges = widget.databaseService
        .observarCambiosFinancieros()
        .listen((_) {
          if (mounted) setState(() => _dataFuture = _load());
        });
  }

  @override
  void dispose() {
    unawaited(_financialChanges.cancel());
    super.dispose();
  }

  Future<_CommitmentsData> _load() async {
    final values = await Future.wait<Object>([
      widget.databaseService.obtenerSuscripciones(),
      widget.databaseService.obtenerPlanesGastosFuturos(),
      widget.databaseService.obtenerDeudas(),
      widget.databaseService.obtenerTodosLosPagosDeuda(),
      widget.databaseService.obtenerEntidadesCredito(),
    ]);
    return _CommitmentsData.fromRecords(
      subscriptions: values[0] as List<Suscripcion>,
      plans: values[1] as List<FutureExpenseSummary>,
      debts: values[2] as List<Deuda>,
      debtPayments: values[3] as List<PagosDeudaData>,
      creditEntities: values[4] as List<CreditEntitySummary>,
    );
  }

  void _retry() {
    setState(() => _dataFuture = _load());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<_CommitmentsData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No pudimos cargar tus compromisos.'),
                  TextButton(
                    onPressed: _retry,
                    child: const Text('Intentar de nuevo'),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          return LayoutBuilder(
            builder: (context, constraints) {
              final horizontal = constraints.maxWidth < 420 ? 20.0 : 32.0;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 36),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppPageHeader(
                          title: 'Compromisos',
                          subtitle: 'Ten a la vista los pagos y planes que vienen.',
                        ),
                        const SizedBox(height: 18),
                        _CommitmentMonthSummary(data: data),
                        const SizedBox(height: 18),
                        const _SectionHeading(title: 'Módulos'),
                        const SizedBox(height: 8),
                        _CommitmentModules(
                          data: data,
                          onSubscriptions: widget.onSubscriptions,
                          onFutureExpenses: widget.onFutureExpenses,
                          onDebts: widget.onDebts,
                          onCredits: widget.onCredits,
                        ),
                        const SizedBox(height: 18),
                        const _SectionHeading(title: 'Próximos pagos'),
                        const SizedBox(height: 8),
                        _CommitmentUpcomingList(
                          due: data.upcoming,
                          onSubscriptions: widget.onSubscriptions,
                          onDebts: widget.onDebts,
                          onFutureExpenses: widget.onFutureExpenses,
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
    );
  }
}

class _CommitmentsData {
  const _CommitmentsData({
    required this.activeSubscriptions,
    required this.monthlySubscriptionCost,
    required this.activePlans,
    required this.reservedForPlans,
    required this.outstandingDebt,
    required this.upcoming,
    required this.activeCreditEntities,
    required this.availableCredit,
    required this.dueThisMonth,
  });

  factory _CommitmentsData.fromRecords({
    required List<Suscripcion> subscriptions,
    required List<FutureExpenseSummary> plans,
    required List<Deuda> debts,
    required List<PagosDeudaData> debtPayments,
    required List<CreditEntitySummary> creditEntities,
  }) {
    final activeSubscriptions = subscriptions.where((item) => item.activa).toList()
      ..sort((first, second) => first.proximoPago.compareTo(second.proximoPago));
    var monthlySubscriptionCost = 0.0;
    for (final subscription in activeSubscriptions) {
      final frequency = SubscriptionFrequency.fromStorage(
        subscription.frecuencia,
      );
      if (frequency == null) {
        throw StateError('La frecuencia de una suscripción no es válida.');
      }
      monthlySubscriptionCost += frequency.monthlyCost(subscription.precio);
    }

    final activePlans = plans
        .where((item) => item.plan.status == FutureExpenseStatus.active)
        .toList()
      ..sort(
        (first, second) =>
            first.plan.targetDate.compareTo(second.plan.targetDate),
      );
    final reservedForPlans = activePlans.fold<double>(
      0,
      (total, plan) => total + plan.reservedAmount,
    );

    final paidByDebt = <int, double>{};
    for (final payment in debtPayments) {
      paidByDebt.update(
        payment.deudaId,
        (total) => total + payment.monto,
        ifAbsent: () => payment.monto,
      );
    }

    final upcoming = <_CommitmentDue>[
      for (final subscription in activeSubscriptions)
        _CommitmentDue(
          title: subscription.nombre,
          detail: 'Suscripción · ${subscription.frecuencia}',
          date: subscription.proximoPago,
          amount: subscription.precio,
          type: _CommitmentDueType.subscription,
        ),
      for (final debt in debts)
        if (debt.fechaProximoPago case final DateTime date)
          if (debt.montoOriginal - (paidByDebt[debt.id] ?? 0) > 0)
            _CommitmentDue(
              title: debt.nombre,
              detail: 'Próxima cuota',
              date: date,
              amount: debt.cuota <
                      debt.montoOriginal - (paidByDebt[debt.id] ?? 0)
                  ? debt.cuota
                  : debt.montoOriginal - (paidByDebt[debt.id] ?? 0),
              type: _CommitmentDueType.debt,
            ),
      for (final plan in activePlans)
        _CommitmentDue(
          title: plan.plan.name,
          detail: 'Gasto futuro · reservado ${formatMoney(plan.reservedAmount)}',
          date: plan.plan.targetDate,
          amount: plan.plan.targetAmount,
          reservedAmount: plan.reservedAmount,
          type: _CommitmentDueType.futurePlan,
          isFuturePlan: true,
        ),
    ]..sort((first, second) => first.date.compareTo(second.date));

    final now = DateUtils.dateOnly(DateTime.now());
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    final dueThisMonth = upcoming
        .where(
          (item) =>
              !item.isFuturePlan &&
              !DateUtils.dateOnly(item.date).isAfter(monthEnd) &&
              !DateUtils.dateOnly(item.date).isBefore(now),
        )
        .fold<double>(0, (total, item) => total + item.amount);

    return _CommitmentsData(
      activeSubscriptions: activeSubscriptions.length,
      monthlySubscriptionCost: monthlySubscriptionCost,
      activePlans: activePlans.length,
      reservedForPlans: reservedForPlans,
      outstandingDebt: debts.fold<double>(0, (total, debt) {
        final balance = debt.montoOriginal - (paidByDebt[debt.id] ?? 0);
        return total + balance.clamp(0.0, double.infinity).toDouble();
      }),
      upcoming: upcoming,
      activeCreditEntities: creditEntities.length,
      availableCredit: creditEntities.fold<double>(
        0,
        (total, entity) =>
            total +
            entity.cupoDisponible.clamp(0.0, double.infinity).toDouble(),
      ),
      dueThisMonth: dueThisMonth,
    );
  }

  final int activeSubscriptions;
  final double monthlySubscriptionCost;
  final int activePlans;
  final double reservedForPlans;
  final double outstandingDebt;
  final List<_CommitmentDue> upcoming;
  final int activeCreditEntities;
  final double availableCredit;
  final double dueThisMonth;
}

enum _CommitmentDueType { subscription, debt, futurePlan }

class _CommitmentDue {
  const _CommitmentDue({
    required this.title,
    required this.detail,
    required this.date,
    required this.amount,
    required this.type,
    this.reservedAmount,
    this.isFuturePlan = false,
  });

  final String title;
  final String detail;
  final DateTime date;
  final double amount;
  final _CommitmentDueType type;
  final double? reservedAmount;
  final bool isFuturePlan;
}

class _CommitmentMonthSummary extends StatelessWidget {
  const _CommitmentMonthSummary({required this.data});

  final _CommitmentsData data;

  @override
  Widget build(BuildContext context) {
    final month = const [
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
    ][DateTime.now().month - 1];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: AppCardDecorations.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Por pagar en lo que queda de $month',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 2),
          Text(
            formatMoney(data.dueThisMonth),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Suscripciones y cuotas. Los gastos futuros se cubren con lo que reservas.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _CommitmentModules extends StatelessWidget {
  const _CommitmentModules({
    required this.data,
    required this.onSubscriptions,
    required this.onFutureExpenses,
    required this.onDebts,
    required this.onCredits,
  });

  final _CommitmentsData data;
  final VoidCallback onSubscriptions;
  final VoidCallback onFutureExpenses;
  final VoidCallback onDebts;
  final VoidCallback onCredits;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _HubTile(
        icon: Icons.autorenew_rounded,
        title: 'Suscripciones',
        subtitle:
            '${data.activeSubscriptions} activas · ${formatMoney(data.monthlySubscriptionCost)} al mes',
        onTap: onSubscriptions,
      ),
      _HubTile(
        icon: Icons.track_changes_rounded,
        title: 'Gastos futuros',
        subtitle:
            '${data.activePlans} ${data.activePlans == 1 ? 'plan activo' : 'planes activos'} · ${formatMoney(data.reservedForPlans)} reservados',
        onTap: onFutureExpenses,
      ),
      _HubTile(
        icon: Icons.account_balance_outlined,
        title: 'Deudas y préstamos',
        subtitle: 'Saldo por pagar ${formatMoney(data.outstandingDebt)}',
        onTap: onDebts,
      ),
      _HubTile(
        icon: Icons.credit_card_outlined,
        title: 'Créditos de compra',
        subtitle: data.activeCreditEntities == 0
            ? 'Sin entidades'
            : '${data.activeCreditEntities} ${data.activeCreditEntities == 1 ? 'entidad' : 'entidades'} · disponible ${formatMoney(data.availableCredit)}',
        onTap: onCredits,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: AppCardDecorations.surface,
      child: Column(
        children: [
          for (var index = 0; index < tiles.length; index++) ...[
            if (index > 0)
              Divider(
                height: 1,
                color: AppColors.outline.withValues(alpha: 0.25),
              ),
            _CommitmentModuleRow(tile: tiles[index]),
          ],
        ],
      ),
    );
  }
}

class _CommitmentModuleRow extends StatelessWidget {
  const _CommitmentModuleRow({required this.tile});

  final _HubTile tile;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: tile.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(tile.icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tile.title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      tile.subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommitmentUpcomingList extends StatelessWidget {
  const _CommitmentUpcomingList({
    required this.due,
    required this.onSubscriptions,
    required this.onDebts,
    required this.onFutureExpenses,
  });

  final List<_CommitmentDue> due;
  final VoidCallback onSubscriptions;
  final VoidCallback onDebts;
  final VoidCallback onFutureExpenses;

  @override
  Widget build(BuildContext context) {
    final visible = due.take(8).toList();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: AppCardDecorations.surface,
      child: visible.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  const AnimatedCat(
                    asset: CatAssets.vacio,
                    label: 'Gato descansando',
                    width: 64,
                    height: 56,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nada pendiente',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          'No tienes pagos o planes próximos.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                for (var index = 0; index < visible.length; index++) ...[
                  if (index > 0)
                    Divider(
                      height: 1,
                      color: AppColors.outline.withValues(alpha: 0.25),
                    ),
                  _CommitmentDueRow(
                    item: visible[index],
                    onTap: switch (visible[index].type) {
                      _CommitmentDueType.subscription => onSubscriptions,
                      _CommitmentDueType.debt => onDebts,
                      _CommitmentDueType.futurePlan => onFutureExpenses,
                    },
                  ),
                ],
              ],
            ),
    );
  }
}

class _CommitmentDueRow extends StatelessWidget {
  const _CommitmentDueRow({required this.item, required this.onTap});

  final _CommitmentDue item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final dayOffset = DateUtils.dateOnly(item.date).difference(today).inDays;
    final month = const [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ][item.date.month - 1];
    final dueLabel = dayOffset < 0
        ? 'Venció hace ${-dayOffset} ${dayOffset == -1 ? 'día' : 'días'}'
        : dayOffset == 0
        ? 'Hoy'
        : dayOffset == 1
        ? 'Mañana'
        : 'En $dayOffset días';
    final urgent = dayOffset <= 7;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${item.date.day}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  month.toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  item.detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (item.reservedAmount != null && item.amount > 0) ...[
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    child: LinearProgressIndicator(
                      value: (item.reservedAmount! / item.amount)
                          .clamp(0.0, 1.0)
                          .toDouble(),
                      minHeight: 6,
                      backgroundColor: AppColors.surfaceRaised,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatMoney(item.amount),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: urgent
                      ? AppColors.warning.withValues(alpha: 0.14)
                      : AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  dueLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: urgent
                        ? AppColors.warning
                        : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
            ],
          ),
        ),
      ),
    );
  }
}

class MoreHubScreen extends StatefulWidget {
  const MoreHubScreen({
    super.key,
    required this.databaseService,
    required this.onAccounts,
    required this.onStatistics,
    required this.onSavings,
    required this.onSettings,
  });

  final DatabaseService databaseService;
  final VoidCallback onAccounts;
  final VoidCallback onStatistics;
  final VoidCallback onSavings;
  final VoidCallback onSettings;

  @override
  State<MoreHubScreen> createState() => _MoreHubScreenState();
}

class _MoreHubScreenState extends State<MoreHubScreen> {
  late Future<double> _savingsFuture;
  late final StreamSubscription<void> _financialChanges;

  @override
  void initState() {
    super.initState();
    _savingsFuture = widget.databaseService.obtenerTotalAhorros();
    _financialChanges = widget.databaseService
        .observarCambiosFinancieros()
        .listen((_) {
          if (mounted) {
            setState(
              () => _savingsFuture = widget.databaseService.obtenerTotalAhorros(),
            );
          }
        });
  }

  @override
  void dispose() {
    unawaited(_financialChanges.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double>(
      future: _savingsFuture,
      builder: (context, snapshot) {
        final savingsSubtitle = snapshot.hasError
            ? 'No se pudo cargar el ahorro'
            : snapshot.hasData
            ? 'Ahorro ${formatMoney(snapshot.data!)} · préstamos a terceros'
            : 'Cargando ahorro…';
        return _NavigationHub(
          title: 'Más',
          subtitle: '',
          tiles: [
            _HubTile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Cuentas',
              subtitle: 'Efectivo y cuentas digitales',
              onTap: widget.onAccounts,
            ),
            _HubTile(
              icon: Icons.insights_outlined,
              title: 'Estadísticas',
              subtitle: 'General, efectivo y digital',
              onTap: widget.onStatistics,
            ),
            _HubTile(
              icon: Icons.savings_outlined,
              title: 'Ahorros y préstamos',
              subtitle: savingsSubtitle,
              onTap: widget.onSavings,
            ),
            _HubTile(
              icon: Icons.tune_rounded,
              title: 'Configuración',
              subtitle: 'Nombre, categorías, cuentas, transferencias',
              onTap: widget.onSettings,
            ),
          ],
        );
      },
    );
  }
}

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({
    super.key,
    required this.databaseService,
    required this.onTransfer,
    required this.onSettings,
  });

  final DatabaseService databaseService;
  final Future<void> Function() onTransfer;
  final VoidCallback onSettings;

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  late Future<_AccountsData> _accountsFuture;
  late final StreamSubscription<void> _financialChanges;
  String? _expandedAccount;

  @override
  void initState() {
    super.initState();
    _accountsFuture = _load();
    _financialChanges = widget.databaseService
        .observarCambiosFinancieros()
        .listen((_) {
          if (mounted) setState(() => _accountsFuture = _load());
        });
  }

  @override
  void dispose() {
    unawaited(_financialChanges.cancel());
    super.dispose();
  }

  Future<_AccountsData> _load() async {
    final values = await Future.wait<Object>([
      widget.databaseService.obtenerCuentasDigitales(),
      widget.databaseService.obtenerSaldosPorMedio(),
      widget.databaseService.obtenerTransferencias(),
      widget.databaseService.obtenerGastos(),
      widget.databaseService.obtenerIngresos(),
      widget.databaseService.obtenerTodosLosDestinosIngreso(),
    ]);
    final incomes = values[4] as List<Ingreso>;
    final incomeDestinations =
        values[5] as List<({int ingresoId, IncomeDestination destino})>;
    final incomeIds = {for (final income in incomes) income.id};
    if (incomeDestinations.any((entry) => !incomeIds.contains(entry.ingresoId))) {
      throw StateError('Un destino de ingreso no tiene ingreso asociado.');
    }
    return _AccountsData(
      accounts: values[0] as List<DigitalAccountBalance>,
      balances: values[1] as AvailableBalanceBreakdown,
      transfers: values[2] as List<TransferenciasDineroData>,
      expenses: values[3] as List<Gasto>,
      incomes: incomes,
      incomeDestinations: incomeDestinations,
    );
  }

  void _retry() {
    setState(() => _accountsFuture = _load());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<_AccountsData>(
        future: _accountsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No pudimos cargar tus cuentas.'),
                  TextButton(
                    onPressed: _retry,
                    child: const Text('Intentar de nuevo'),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final accountNames = {
            for (final item in data.accounts)
              item.account.id: item.account.nombre,
          };
          return LayoutBuilder(
            builder: (context, constraints) {
              final horizontal = constraints.maxWidth < 420 ? 20.0 : 32.0;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 36),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppPageHeader(
                          title: 'Cuentas',
                          subtitle: '',
                        ),
                        const SizedBox(height: 18),
                        _AccountDistributionCard(
                          data: data,
                          onTransfer: widget.onTransfer,
                        ),
                        const SizedBox(height: 20),
                        _SectionHeading(
                          title: 'Efectivo',
                          trailing: Text(
                            formatMoney(data.balances.cash),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        _AccountBalanceRow(
                          name: 'Efectivo',
                          icon: Icons.payments_outlined,
                          color: AppColors.chartPalette.first,
                          amount: data.balances.cash,
                          total: data.balances.total,
                          spentThisMonth: data.spentThisMonth(
                            medium: MoneyMedium.cash.storageValue,
                          ),
                          expanded:
                              _expandedAccount == _AccountsData.cashAccountKey,
                          activities: data.activitiesFor(
                            medium: MoneyMedium.cash.storageValue,
                            accountNames: accountNames,
                          ),
                          onTap: () => setState(() {
                            _expandedAccount =
                                _expandedAccount == _AccountsData.cashAccountKey
                                ? null
                                : _AccountsData.cashAccountKey;
                          }),
                        ),
                        const SizedBox(height: 14),
                        _SectionHeading(
                          title: 'Digital',
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                formatMoney(data.balances.digital),
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              TextButton(
                                onPressed: widget.onSettings,
                                child: const Text('Administrar'),
                              ),
                            ],
                          ),
                        ),
                        if (data.accounts.isEmpty)
                          _EmptyAccounts(onSettings: widget.onSettings)
                        else
                          for (var index = 0;
                              index < data.accounts.length;
                              index++)
                            _AccountBalanceRow(
                              name: data.accounts[index].account.nombre,
                              icon: Icons.account_balance_wallet_outlined,
                              color: AppColors.chartPalette[
                                  (index + 1) % AppColors.chartPalette.length],
                              amount: data.accounts[index].balance,
                              total: data.balances.total,
                              spentThisMonth: data.spentThisMonth(
                                accountId: data.accounts[index].account.id,
                              ),
                              expanded:
                                  _expandedAccount ==
                                  '${data.accounts[index].account.id}',
                              activities: data.activitiesFor(
                                accountId: data.accounts[index].account.id,
                                accountNames: accountNames,
                              ),
                              onTap: () => setState(() {
                                final key =
                                    '${data.accounts[index].account.id}';
                                _expandedAccount =
                                    _expandedAccount == key ? null : key;
                              }),
                            ),
                        const SizedBox(height: 20),
                        const _SectionHeading(title: 'Transferencias recientes'),
                        if (data.transfers.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: AppCardDecorations.surface,
                            child: Text(
                              'Todavía no has movido dinero entre tus cuentas.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: AppCardDecorations.surface,
                            child: Column(
                              children: [
                                for (
                                  var index = 0;
                                  index < data.transfers.length && index < 3;
                                  index++
                                ) ...[
                                  if (index > 0)
                                    Divider(
                                      height: 1,
                                      color: AppColors.outline.withValues(
                                        alpha: 0.25,
                                      ),
                                    ),
                                  _AccountTransferRow(
                                    transfer: data.transfers[index],
                                    accountNames: accountNames,
                                  ),
                                ],
                              ],
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
    );
  }

  static String _mediumName(
    String medium,
    int? accountId,
    Map<int, String> accountNames,
  ) {
    if (accountId != null && accountNames.containsKey(accountId)) {
      return accountNames[accountId]!;
    }
    return MoneyMedium.fromStorage(medium)?.label ?? medium;
  }
}

class _AccountsData {
  const _AccountsData({
    required this.accounts,
    required this.balances,
    required this.transfers,
    required this.expenses,
    required this.incomes,
    required this.incomeDestinations,
  });

  static const cashAccountKey = 'cash';

  final List<DigitalAccountBalance> accounts;
  final AvailableBalanceBreakdown balances;
  final List<TransferenciasDineroData> transfers;
  final List<Gasto> expenses;
  final List<Ingreso> incomes;
  final List<({int ingresoId, IncomeDestination destino})> incomeDestinations;

  double spentThisMonth({int? accountId, String? medium}) {
    final now = DateTime.now();
    return expenses
        .where(
          (expense) =>
              expense.fecha.year == now.year &&
              expense.fecha.month == now.month &&
              _matchesAccount(
                expense.cuentaDigitalId,
                expense.medio,
                accountId,
                medium,
              ),
        )
        .fold<double>(0, (total, expense) => total + expense.monto);
  }

  List<_AccountActivity> activitiesFor({
    int? accountId,
    String? medium,
    required Map<int, String> accountNames,
  }) {
    final activities = <_AccountActivity>[];
    for (final expense in expenses) {
      if (_matchesAccount(
        expense.cuentaDigitalId,
        expense.medio,
        accountId,
        medium,
      )) {
        activities.add(
          _AccountActivity(
            date: expense.fecha,
            title: expense.nombre,
            amount: -expense.monto,
          ),
        );
      }
    }

    final incomeIdsWithDestinations = <int>{};
    for (final entry in incomeDestinations) {
      incomeIdsWithDestinations.add(entry.ingresoId);
      if (!_matchesAccount(
        entry.destino.cuentaDigitalId,
        entry.destino.medio.storageValue,
        accountId,
        medium,
      )) {
        continue;
      }
      final income = incomes.where((item) => item.id == entry.ingresoId);
      if (income.isEmpty) {
        throw StateError('Un destino de ingreso no tiene ingreso asociado.');
      }
      final item = income.first;
      activities.add(
        _AccountActivity(
          date: item.fecha,
          title: (item.descripcion?.trim().isNotEmpty ?? false)
              ? item.descripcion!.trim()
              : IncomeType.fromStorage(item.tipo).label,
          amount: entry.destino.monto,
        ),
      );
    }
    for (final income in incomes) {
      if (incomeIdsWithDestinations.contains(income.id) ||
          !_matchesAccount(
            income.cuentaDigitalId,
            income.medio,
            accountId,
            medium,
          )) {
        continue;
      }
      activities.add(
        _AccountActivity(
          date: income.fecha,
          title: (income.descripcion?.trim().isNotEmpty ?? false)
              ? income.descripcion!.trim()
              : IncomeType.fromStorage(income.tipo).label,
          amount: income.monto,
        ),
      );
    }

    for (final transfer in transfers) {
      if (_matchesAccount(
        transfer.cuentaOrigenId,
        transfer.medioOrigen,
        accountId,
        medium,
      )) {
        activities.add(
          _AccountActivity(
            date: transfer.fecha,
            title:
                'Transferencia a ${_accountEndpoint(transfer.cuentaDestinoId, transfer.medioDestino, accountNames)}',
            amount: -transfer.monto,
          ),
        );
      }
      if (_matchesAccount(
        transfer.cuentaDestinoId,
        transfer.medioDestino,
        accountId,
        medium,
      )) {
        activities.add(
          _AccountActivity(
            date: transfer.fecha,
            title:
                'Transferencia de ${_accountEndpoint(transfer.cuentaOrigenId, transfer.medioOrigen, accountNames)}',
            amount: transfer.monto,
          ),
        );
      }
    }
    activities.sort((first, second) => second.date.compareTo(first.date));
    return activities.take(3).toList();
  }

  bool _matchesAccount(
    int? recordAccountId,
    String? recordMedium,
    int? accountId,
    String? medium,
  ) {
    if (accountId != null) return recordAccountId == accountId;
    return recordAccountId == null && recordMedium == medium;
  }

  String _accountEndpoint(
    int? accountId,
    String medium,
    Map<int, String> accountNames,
  ) {
    if (accountId != null) return accountNames[accountId] ?? 'Cuenta digital';
    return MoneyMedium.fromStorage(medium)?.label ?? 'Medio sin clasificar';
  }
}

class _NavigationHub extends StatelessWidget {
  const _NavigationHub({
    required this.title,
    required this.subtitle,
    required this.tiles,
  });

  final String title;
  final String subtitle;
  final List<_HubTile> tiles;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth < 420 ? 20.0 : 32.0;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 36),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppPageHeader(
                      title: title,
                      subtitle: subtitle,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: AppCardDecorations.surface,
                      child: Column(
                        children: [
                          for (var index = 0; index < tiles.length; index++) ...[
                            if (index > 0)
                              Divider(
                                height: 1,
                                color: AppColors.outline.withValues(
                                  alpha: 0.25,
                                ),
                              ),
                            _CommitmentModuleRow(tile: tiles[index]),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HubTile {
  const _HubTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _AccountActivity {
  const _AccountActivity({
    required this.date,
    required this.title,
    required this.amount,
  });

  final DateTime date;
  final String title;
  final double amount;
}

class _AccountDistributionCard extends StatelessWidget {
  const _AccountDistributionCard({
    required this.data,
    required this.onTransfer,
  });

  final _AccountsData data;
  final Future<void> Function() onTransfer;

  @override
  Widget build(BuildContext context) {
    final digitalAccountTotal = data.accounts.fold<double>(
      0,
      (total, account) => total + account.balance,
    );
    final segments = <({String name, double value, Color color})>[
      (
        name: 'Efectivo',
        value: data.balances.cash,
        color: AppColors.chartPalette.first,
      ),
      for (var index = 0; index < data.accounts.length; index++)
        (
          name: data.accounts[index].account.nombre,
          value: data.accounts[index].balance,
          color:
              AppColors.chartPalette[(index + 1) %
                  AppColors.chartPalette.length],
        ),
      if (data.balances.digital - digitalAccountTotal > 0)
        (
          name: 'Digital sin cuenta',
          value: data.balances.digital - digitalAccountTotal,
          color: AppColors.chartPalette.last,
        ),
      if (data.balances.unclassified > 0)
        (
          name: 'Sin clasificar',
          value: data.balances.unclassified,
          color: AppColors.textSecondary,
        ),
    ];
    final total = data.balances.total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppCardDecorations.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total de tu dinero',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            formatMoney(total),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (total > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              child: SizedBox(
                height: 14,
                child: Row(
                  children: [
                    for (final segment in segments)
                      if (segment.value > 0)
                        Expanded(
                          flex: (segment.value / total * 1000)
                              .round()
                              .clamp(1, 1000)
                              .toInt(),
                          child: ColoredBox(color: segment.color),
                        ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                for (final segment in segments)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: segment.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${segment.name} ${(segment.value / total * 100).round()} %',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('accounts-transfer'),
              onPressed: onTransfer,
              icon: const Icon(Icons.swap_horiz_rounded),
              label: const Text('Transferir entre cuentas'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountBalanceRow extends StatelessWidget {
  const _AccountBalanceRow({
    required this.name,
    required this.icon,
    required this.color,
    required this.amount,
    required this.total,
    required this.spentThisMonth,
    required this.expanded,
    required this.activities,
    required this.onTap,
  });

  final String name;
  final IconData icon;
  final Color color;
  final double amount;
  final double total;
  final double spentThisMonth;
  final bool expanded;
  final List<_AccountActivity> activities;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final share = total > 0 ? (amount / total * 100).round() : 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: AppCardDecorations.surface,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceRaised,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, size: 20, color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            '$share % del total',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            'Salió ${formatMoney(spentThisMonth)} este mes',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatMoney(amount),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                if (expanded) ...[
                  const SizedBox(height: 10),
                  Divider(
                    height: 1,
                    color: AppColors.outline.withValues(alpha: 0.25),
                  ),
                  if (activities.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          'Sin movimientos todavía.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    )
                  else
                    for (final activity in activities)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${activity.date.day}/${activity.date.month} · ${activity.title}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${activity.amount < 0 ? '−' : '+'}${formatMoney(activity.amount.abs())}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: activity.amount < 0
                                        ? AppColors.negative
                                        : AppColors.positive,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountTransferRow extends StatelessWidget {
  const _AccountTransferRow({
    required this.transfer,
    required this.accountNames,
  });

  final TransferenciasDineroData transfer;
  final Map<int, String> accountNames;

  @override
  Widget build(BuildContext context) {
    final from = _AccountsScreenState._mediumName(
      transfer.medioOrigen,
      transfer.cuentaOrigenId,
      accountNames,
    );
    final to = _AccountsScreenState._mediumName(
      transfer.medioDestino,
      transfer.cuentaDestinoId,
      accountNames,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
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
              Icons.swap_horiz_rounded,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transferencia',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  '$from → $to · ${transfer.fecha.day}/${transfer.fecha.month}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatMoney(transfer.monto),
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _EmptyAccounts extends StatelessWidget {
  const _EmptyAccounts({required this.onSettings});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const AnimatedCat(
              asset: CatAssets.vacio,
              label: 'Gato de cuentas vacías',
              width: 64,
              height: 56,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Todavía no tienes cuentas digitales configuradas.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            TextButton(onPressed: onSettings, child: const Text('Agregar')),
          ],
        ),
      ),
    );
  }
}

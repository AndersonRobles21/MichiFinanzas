import 'dart:async';

import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/money_medium.dart';
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
              child: AppPageHeader(
                title: 'Movimientos',
                subtitle: 'Consulta y organiza tus ingresos y gastos.',
                trailing: AnimatedCat(
                  asset: CatAssets.gastos,
                  label: 'Gato de movimientos',
                  width: 52,
                  height: 46,
                ),
              ),
            ),
            TabBar(
              controller: _controller,
              tabs: const [
                Tab(text: 'Gastos'),
                Tab(text: 'Ingresos'),
              ],
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

class CommitmentsHubScreen extends StatelessWidget {
  const CommitmentsHubScreen({
    super.key,
    required this.onSubscriptions,
    required this.onFutureExpenses,
    required this.onDebts,
    required this.onCredits,
  });

  final VoidCallback onSubscriptions;
  final VoidCallback onFutureExpenses;
  final VoidCallback onDebts;
  final VoidCallback onCredits;

  @override
  Widget build(BuildContext context) {
    return _NavigationHub(
      title: 'Compromisos',
      subtitle: 'Ten a la vista los pagos y planes que vienen.',
      icon: Icons.event_available_outlined,
      tiles: [
        _HubTile(
          icon: Icons.autorenew_rounded,
          title: 'Suscripciones',
          subtitle: 'Pagos recurrentes y su historial.',
          onTap: onSubscriptions,
        ),
        _HubTile(
          icon: Icons.event_note_outlined,
          title: 'Gastos futuros',
          subtitle: 'Organiza y reserva dinero para tus planes.',
          onTap: onFutureExpenses,
        ),
        _HubTile(
          icon: Icons.account_balance_outlined,
          title: 'Deudas y préstamos',
          subtitle: 'Cuotas, abonos y préstamos recibidos.',
          onTap: onDebts,
        ),
        _HubTile(
          icon: Icons.credit_card_outlined,
          title: 'Créditos de compra',
          subtitle: 'Entidades, cupos y compras pendientes.',
          onTap: onCredits,
        ),
      ],
    );
  }
}

class MoreHubScreen extends StatelessWidget {
  const MoreHubScreen({
    super.key,
    required this.onAccounts,
    required this.onStatistics,
    required this.onSavings,
    required this.onSettings,
  });

  final VoidCallback onAccounts;
  final VoidCallback onStatistics;
  final VoidCallback onSavings;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return _NavigationHub(
      title: 'Más',
      subtitle: 'Cuentas, análisis, objetivos y preferencias.',
      icon: Icons.grid_view_rounded,
      tiles: [
        _HubTile(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Cuentas',
          subtitle: 'Saldos disponibles y transferencias.',
          onTap: onAccounts,
        ),
        _HubTile(
          icon: Icons.insights_outlined,
          title: 'Estadísticas',
          subtitle: 'Revisa cómo se mueve tu dinero.',
          onTap: onStatistics,
        ),
        _HubTile(
          icon: Icons.savings_outlined,
          title: 'Ahorros y préstamos',
          subtitle: 'Ahorra y lleva el control del dinero prestado.',
          onTap: onSavings,
        ),
        _HubTile(
          icon: Icons.tune_rounded,
          title: 'Configuración',
          subtitle: 'Personaliza tu experiencia y categorías.',
          onTap: onSettings,
        ),
      ],
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
    ]);
    return _AccountsData(
      accounts: values[0] as List<DigitalAccountBalance>,
      balances: values[1] as AvailableBalanceBreakdown,
      transfers: values[2] as List<TransferenciasDineroData>,
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
            for (final item in data.accounts) item.account.id: item.account.nombre,
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
                          subtitle: 'Tu dinero, donde lo tienes.',
                          trailing: AnimatedCat(
                            asset: CatAssets.icono,
                            label: 'Gato de cuentas',
                            width: 58,
                            height: 48,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Card(
                          color: AppColors.brand,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dinero disponible',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(color: Colors.white70),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  formatMoney(data.balances.total),
                                  style: Theme.of(context).textTheme.headlineSmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 18,
                                  runSpacing: 8,
                                  children: [
                                    _BalanceLabel(
                                      label: 'Efectivo',
                                      amount: data.balances.cash,
                                    ),
                                    _BalanceLabel(
                                      label: 'Digital',
                                      amount: data.balances.digital,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            key: const ValueKey('accounts-transfer'),
                            onPressed: widget.onTransfer,
                            icon: const Icon(Icons.swap_horiz_rounded),
                            label: const Text('Transferir dinero'),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _SectionHeading(
                          title: 'Cuentas digitales',
                          trailing: TextButton(
                            onPressed: widget.onSettings,
                            child: const Text('Administrar'),
                          ),
                        ),
                        if (data.accounts.isEmpty)
                          _EmptyAccounts(onSettings: widget.onSettings)
                        else
                          for (final item in data.accounts)
                            Card(
                              child: ListTile(
                                leading: const CircleAvatar(
                                  child: Icon(
                                    Icons.account_balance_wallet_outlined,
                                  ),
                                ),
                                title: Text(item.account.nombre),
                                trailing: Text(
                                  formatMoney(item.balance),
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                            ),
                        const SizedBox(height: 20),
                        const _SectionHeading(title: 'Transferencias recientes'),
                        if (data.transfers.isEmpty)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('Aún no tienes transferencias.'),
                            ),
                          )
                        else
                          for (final transfer in data.transfers.take(5))
                            Card(
                              child: ListTile(
                                leading: const Icon(Icons.swap_horiz_rounded),
                                title: Text(
                                  '${_mediumName(transfer.medioOrigen, transfer.cuentaOrigenId, accountNames)} → '
                                  '${_mediumName(transfer.medioDestino, transfer.cuentaDestinoId, accountNames)}',
                                ),
                                subtitle: Text(
                                  '${transfer.fecha.day}/${transfer.fecha.month}/${transfer.fecha.year}',
                                ),
                                trailing: Text(formatMoney(transfer.monto)),
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
  });

  final List<DigitalAccountBalance> accounts;
  final AvailableBalanceBreakdown balances;
  final List<TransferenciasDineroData> transfers;
}

class _NavigationHub extends StatelessWidget {
  const _NavigationHub({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tiles,
  });

  final String title;
  final String subtitle;
  final IconData icon;
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
                      trailing: Icon(icon, size: 42, color: AppColors.primary),
                    ),
                    const SizedBox(height: 18),
                    for (final tile in tiles)
                      Card(
                        child: ListTile(
                          minVerticalPadding: 14,
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.12,
                            ),
                            child: Icon(tile.icon, color: AppColors.primary),
                          ),
                          title: Text(tile.title),
                          subtitle: Text(tile.subtitle),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: tile.onTap,
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

class _BalanceLabel extends StatelessWidget {
  const _BalanceLabel({required this.label, required this.amount});

  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label  ${formatMoney(amount)}',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w600,
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

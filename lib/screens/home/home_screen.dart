import 'dart:async';

import 'package:flutter/material.dart';

import '../../database/app_database.dart';
import '../../models/future_expense.dart';
import '../../models/income_type.dart';
import '../../models/money_medium.dart';
import '../../services/app_settings_service.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_format.dart';
import '../../utils/money_format.dart';
import '../../utils/user_messages.dart';
import '../../widgets/cat_illustration.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.databaseService,
    this.isActive = true,
    this.onViewFutureExpenses,
    this.onViewExpenses,
    this.onViewIncomes,
    this.onViewSubscriptions,
    this.onViewSettings,
  });

  final DatabaseService? databaseService;
  final bool isActive;
  final VoidCallback? onViewFutureExpenses;
  final VoidCallback? onViewExpenses;
  final VoidCallback? onViewIncomes;
  final VoidCallback? onViewSubscriptions;
  final VoidCallback? onViewSettings;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final DatabaseService _databaseService;
  late final bool _ownsDatabaseService;
  late Future<_DashboardData> _dashboardFuture;
  late final StreamSubscription<void> _financialChanges;
  bool _isSavingIncome = false;
  bool _isSavingDistribution = false;

  @override
  void initState() {
    super.initState();
    _ownsDatabaseService = widget.databaseService == null;
    _databaseService = widget.databaseService ?? DatabaseService(AppDatabase());
    _dashboardFuture = _loadDashboard(_databaseService);
    _financialChanges = _databaseService.observarCambiosFinancieros().listen((
      _,
    ) {
      if (!mounted) return;
      setState(() {
        _dashboardFuture = _loadDashboard(_databaseService);
      });
    });
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      setState(() {
        _dashboardFuture = _loadDashboard(_databaseService);
      });
    }
  }

  void _retry() {
    setState(() {
      _dashboardFuture = _loadDashboard(_databaseService);
    });
  }

  Future<void> _addIncome() async {
    if (_isSavingIncome) return;
    final dashboard = await _dashboardFuture;
    if (!mounted) return;
    final draft = await showModalBottomSheet<_IncomeDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      backgroundColor: AppColors.surface,
      builder: (context) => _IncomeFormSheet(
        accounts: dashboard.digitalAccounts
            .map((item) => item.account)
            .toList(),
      ),
    );
    if (draft == null || !mounted || _isSavingIncome) return;

    setState(() => _isSavingIncome = true);
    try {
      if (draft.type == IncomeType.loan) {
        await _databaseService.registrarPrestamo(
          nombre: draft.descripcion,
          monto: draft.monto,
          fechaRecepcion: draft.fecha,
          cuotasTotales: draft.cuotasTotales!,
          fechaPrimerPago: draft.fechaPrimerPago!,
          destinos: draft.destinos,
        );
      } else {
        await _databaseService.agregarIngreso(
          monto: draft.monto,
          fecha: draft.fecha,
          descripcion: draft.descripcion,
          tipo: draft.type.storageValue,
          destinos: draft.destinos,
        );
      }
      if (!mounted) return;
      final userName = (await _dashboardFuture).userName;
      if (!mounted) return;
      setState(() {
        _dashboardFuture = _loadDashboard(_databaseService);
      });
      _showMessage(
        userName.isNotEmpty
            ? '¡Listo, $userName! Tu dinero quedó registrado.'
            : draft.type == IncomeType.loan
            ? 'Préstamo guardado y cuotas listas para organizar.'
            : 'El ingreso quedó guardado.',
        isSuccess: true,
        successAsset: CatAssets.ingresos,
      );
    } catch (error, stackTrace) {
      logOperationFailure(error, stackTrace, operation: 'registrar un ingreso');
      if (mounted) {
        _showMessage(
          friendlyOperationError(error, action: 'guardar el ingreso'),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingIncome = false);
    }
  }

  Future<void> _editDistribution() async {
    if (_isSavingDistribution) return;
    try {
      final current = await _databaseService.obtenerSaldosPorMedio();
      if (!mounted) return;
      final draft = await showDialog<_DistributionDraft>(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: AppColors.surface,
          child: _DistributionFormSheet(
            total: current.total,
            cash: current.cash,
            digital: current.digital,
          ),
        ),
      );
      if (draft == null || !mounted) return;
      setState(() => _isSavingDistribution = true);
      await _databaseService.distribuirSaldoDisponible(
        efectivo: draft.cash,
        digital: draft.digital,
      );
      if (!mounted) return;
      setState(() => _dashboardFuture = _loadDashboard(_databaseService));
      _showMessage('Distribución actualizada.', isSuccess: true);
    } catch (error, stackTrace) {
      logOperationFailure(
        error,
        stackTrace,
        operation: 'distribuir el dinero disponible',
      );
      if (mounted) {
        _showMessage(
          friendlyOperationError(error, action: 'guardar la distribución'),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingDistribution = false);
    }
  }

  void _showMessage(
    String message, {
    bool isSuccess = false,
    String? successAsset,
  }) {
    showCatMessage(
      context,
      message,
      isSuccess: isSuccess,
      successAsset: successAsset,
    );
  }

  @override
  void dispose() {
    unawaited(_financialChanges.cancel());
    if (_ownsDatabaseService) _databaseService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth < 420 ? 22.0 : 36.0;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              28,
              horizontalPadding,
              36,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AnimatedCat(
                          asset: CatAssets.inicio,
                          label: 'Gato de inicio',
                          width: 64,
                          height: 54,
                          floating: widget.isActive,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Michi Finanzas',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),
                    Text(
                      'Inicio',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<_DashboardData>(
                      future: _dashboardFuture,
                      builder: (context, snapshot) {
                        final name = snapshot.data?.userName ?? '';
                        return Text(
                          name.isEmpty
                              ? 'Aquí ves cómo va tu dinero, sin enredos.'
                              : 'Hola, $name. Aquí ves cómo va tu dinero.',
                          key: const ValueKey('home-user-greeting'),
                          style: Theme.of(context).textTheme.bodyLarge,
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatSpanishLongDate(DateTime.now()),
                      key: const ValueKey('home-current-date'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    FutureBuilder<_DashboardData>(
                      future: _dashboardFuture,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return _DashboardError(onRetry: _retry);
                        }
                        if (!snapshot.hasData) {
                          return const _DashboardLoading();
                        }
                        return _DashboardContent(
                          data: snapshot.data!,
                          onAddIncome: _addIncome,
                          isSavingIncome: _isSavingIncome,
                          onDistributeBalance: _editDistribution,
                          isSavingDistribution: _isSavingDistribution,
                          onViewFutureExpenses: widget.onViewFutureExpenses,
                          onViewExpenses: widget.onViewExpenses,
                          onViewIncomes: widget.onViewIncomes,
                          onViewSubscriptions: widget.onViewSubscriptions,
                          onViewSettings: widget.onViewSettings,
                        );
                      },
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

class IncomesScreen extends StatefulWidget {
  const IncomesScreen({super.key, this.databaseService, this.isActive = true});

  final DatabaseService? databaseService;
  final bool isActive;

  @override
  State<IncomesScreen> createState() => _IncomesScreenState();
}

class _IncomesScreenState extends State<IncomesScreen> {
  late final DatabaseService _databaseService;
  late final bool _ownsDatabaseService;
  late Future<_IncomeHistoryData> _historyFuture;
  late final StreamSubscription<void> _changes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ownsDatabaseService = widget.databaseService == null;
    _databaseService = widget.databaseService ?? DatabaseService(AppDatabase());
    _historyFuture = _load();
    _changes = _databaseService.observarCambiosFinancieros().listen((_) {
      if (mounted) {
        setState(() {
          _historyFuture = _load();
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant IncomesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      setState(() {
        _historyFuture = _load();
      });
    }
  }

  Future<_IncomeHistoryData> _load() async {
    final values = await Future.wait<Object>([
      _databaseService.obtenerIngresos(),
      _databaseService.obtenerCuentasDigitales(),
      _databaseService.obtenerTodosLosDestinosIngreso(),
    ]);
    final incomes = values[0] as List<Ingreso>;
    incomes.sort((a, b) => b.fecha.compareTo(a.fecha));
    return _IncomeHistoryData(
      incomes: incomes,
      accounts: (values[1] as List<DigitalAccountBalance>)
          .map((item) => item.account)
          .toList(),
      destinations:
          values[2] as List<({int ingresoId, IncomeDestination destino})>,
    );
  }

  @override
  void dispose() {
    unawaited(_changes.cancel());
    if (_ownsDatabaseService) unawaited(_databaseService.close());
    super.dispose();
  }

  Future<void> _addIncome(List<CuentasDigitale> accounts) async {
    if (_saving) return;
    final draft = await showModalBottomSheet<_IncomeDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      backgroundColor: AppColors.surface,
      builder: (context) => _IncomeFormSheet(accounts: accounts),
    );
    if (draft == null || !mounted) return;
    setState(() => _saving = true);
    try {
      if (draft.type == IncomeType.loan) {
        await _databaseService.registrarPrestamo(
          nombre: draft.descripcion,
          monto: draft.monto,
          fechaRecepcion: draft.fecha,
          cuotasTotales: draft.cuotasTotales!,
          fechaPrimerPago: draft.fechaPrimerPago!,
          destinos: draft.destinos,
        );
      } else {
        await _databaseService.agregarIngreso(
          monto: draft.monto,
          fecha: draft.fecha,
          descripcion: draft.descripcion,
          tipo: draft.type.storageValue,
          destinos: draft.destinos,
        );
      }
      if (mounted) _showMessage('Ingreso guardado.', isSuccess: true);
    } catch (error, stackTrace) {
      logOperationFailure(error, stackTrace, operation: 'registrar un ingreso');
      if (mounted) {
        _showMessage(
          friendlyOperationError(error, action: 'guardar el ingreso'),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editIncome(
    Ingreso income,
    List<CuentasDigitale> accounts,
  ) async {
    if (_saving) return;
    late final List<IncomeDestination> destinations;
    try {
      destinations = await _databaseService.obtenerDestinosIngreso(income.id);
    } catch (error, stackTrace) {
      logOperationFailure(
        error,
        stackTrace,
        operation: 'cargar destinos del ingreso',
      );
      if (mounted) {
        _showMessage(
          friendlyOperationError(error, action: 'cargar el ingreso'),
        );
      }
      return;
    }
    if (!mounted) return;
    final draft = await showModalBottomSheet<_IncomeDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      backgroundColor: AppColors.surface,
      builder: (context) => _IncomeFormSheet(
        income: income,
        accounts: accounts,
        initialDestinations: destinations,
      ),
    );
    if (draft == null || !mounted) return;
    setState(() => _saving = true);
    try {
      await _databaseService.actualizarIngreso(
        id: income.id,
        monto: draft.monto,
        fecha: draft.fecha,
        descripcion: draft.descripcion,
        tipo: draft.type.storageValue,
        destinos: draft.destinos,
      );
      if (mounted) _showMessage('Ingreso actualizado.', isSuccess: true);
    } catch (error, stackTrace) {
      logOperationFailure(
        error,
        stackTrace,
        operation: 'actualizar un ingreso',
      );
      if (mounted) {
        _showMessage(
          friendlyOperationError(error, action: 'actualizar el ingreso'),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteIncome(Ingreso income) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar este ingreso?'),
        content: const Text(
          'El saldo asociado se revertirá. Si es un préstamo recibido, también se eliminará su deuda vinculada.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Conservar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar ingreso'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _saving) return;
    setState(() => _saving = true);
    try {
      await _databaseService.eliminarIngreso(income.id);
      if (mounted) _showMessage('Ingreso eliminado.', isSuccess: true);
    } catch (error, stackTrace) {
      logOperationFailure(error, stackTrace, operation: 'eliminar un ingreso');
      if (mounted) {
        _showMessage(
          friendlyOperationError(error, action: 'eliminar el ingreso'),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message, {bool isSuccess = false}) {
    showCatMessage(context, message, isSuccess: isSuccess);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<_IncomeHistoryData>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No pudimos cargar tus ingresos.'),
                  TextButton(
                    onPressed: () => setState(() {
                      _historyFuture = _load();
                    }),
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
          final total = data.incomes.fold<double>(
            0,
            (sum, income) => sum + income.monto,
          );
          return LayoutBuilder(
            builder: (context, constraints) {
              final padding = constraints.maxWidth < 420 ? 20.0 : 36.0;
              return ListView(
                padding: EdgeInsets.fromLTRB(padding, 26, padding, 100),
                children: [
                  Text(
                    'Ingresos',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Aquí tienes el historial de todo el dinero que has recibido.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: AppCardDecorations.featured,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ingresos registrados',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          formatMoney(total),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text('${data.incomes.length} movimientos'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (data.incomes.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: AppCardDecorations.surface,
                      child: const Text(
                        'Todavía no hay ingresos por aquí. Registra tu sueldo, un extra o un préstamo recibido.',
                      ),
                    )
                  else
                    for (final income in data.incomes)
                      _IncomeHistoryTile(
                        income: income,
                        destinations: data.destinationLabel(income),
                        saving: _saving,
                        onEdit: () => _editIncome(income, data.accounts),
                        onDelete: () => _deleteIncome(income),
                      ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _saving ? null : () => _addIncome(data.accounts),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Registrar ingreso'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _IncomeHistoryData {
  const _IncomeHistoryData({
    required this.incomes,
    required this.accounts,
    required this.destinations,
  });

  final List<Ingreso> incomes;
  final List<CuentasDigitale> accounts;
  final List<({int ingresoId, IncomeDestination destino})> destinations;

  String destinationLabel(Ingreso income) {
    final entries = destinations
        .where((entry) => entry.ingresoId == income.id)
        .map((entry) {
          final destination = entry.destino;
          final accountName = _accountName(destination.cuentaDigitalId);
          return [
            destination.medio.label,
            ?accountName,
            formatMoney(destination.monto),
          ].join(' · ');
        })
        .toList();
    if (entries.isNotEmpty) return entries.join('  /  ');
    final medium = MoneyMedium.fromStorage(income.medio);
    final accountName = _accountName(income.cuentaDigitalId);
    return [medium?.label ?? 'Medio sin clasificar', ?accountName].join(' · ');
  }

  String? _accountName(int? id) {
    if (id == null) return null;
    for (final account in accounts) {
      if (account.id == id) return account.nombre;
    }
    return null;
  }
}

class _IncomeHistoryTile extends StatelessWidget {
  const _IncomeHistoryTile({
    required this.income,
    required this.destinations,
    required this.saving,
    required this.onEdit,
    required this.onDelete,
  });

  final Ingreso income;
  final String destinations;
  final bool saving;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final type = IncomeType.fromStorage(income.tipo);
    final medium = MoneyMedium.fromStorage(income.medio);
    return Container(
      key: ValueKey('income-history-${income.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: AppCardDecorations.surface,
      child: Row(
        children: [
          const Icon(Icons.south_west_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  income.descripcion?.trim().isNotEmpty == true
                      ? income.descripcion!
                      : type.label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${type.label} · ${_shortDate(income.fecha)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  destinations.isEmpty
                      ? medium?.label ?? 'Medio sin clasificar'
                      : destinations,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(formatMoney(income.monto)),
          PopupMenuButton<String>(
            enabled: !saving,
            tooltip: 'Acciones del ingreso',
            onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Editar')),
              PopupMenuItem(value: 'delete', child: Text('Eliminar')),
            ],
          ),
        ],
      ),
    );
  }
}

Future<_DashboardData> _loadDashboard(DatabaseService service) async {
  return runWithLoggedErrors('cargar el resumen financiero', () async {
    var userName = '';
    try {
      userName = (await const AppSettingsService().load()).userName;
    } catch (error, stackTrace) {
      logOperationFailure(
        error,
        stackTrace,
        operation: 'cargar el nombre del usuario',
      );
    }
    final balanceBreakdown = await service.obtenerSaldosPorMedio();
    final results = await Future.wait<Object>([
      service.obtenerIngresos(),
      service.obtenerGastos(),
      service.obtenerDeudas(),
      service.obtenerTodosLosPagosDeuda(),
      service.obtenerPlanesGastosFuturos(),
      service.obtenerCuentasDigitales(),
      service.obtenerSuscripciones(),
    ]);

    return _DashboardData.fromRecords(
      ingresos: results[0] as List<Ingreso>,
      gastos: results[1] as List<Gasto>,
      deudas: results[2] as List<Deuda>,
      pagos: results[3] as List<PagosDeudaData>,
      futureExpenses: results[4] as List<FutureExpenseSummary>,
      balanceBreakdown: balanceBreakdown,
      userName: userName,
      digitalAccounts: results[5] as List<DigitalAccountBalance>,
      subscriptions: results[6] as List<Suscripcion>,
    );
  });
}

class _DashboardData {
  const _DashboardData({
    required this.totalIngresos,
    required this.ingresosDelMes,
    required this.totalRecibidoDelMes,
    required this.totalGanadoDelMes,
    required this.totalPrestamosDelMes,
    required this.totalGastos,
    required this.totalGastosDelMes,
    required this.totalPagosDeuda,
    required this.dineroDisponible,
    required this.balanceBreakdown,
    required this.userName,
    required this.digitalAccounts,
    required this.subscriptions,
    required this.recentExpenses,
    required this.porcentajeGastado,
    required this.cantidadIngresos,
    required this.cantidadGastos,
    required this.cantidadGastosDelMes,
    required this.cantidadPagosDeuda,
    required this.cantidadDeudas,
    required this.deudasPendientes,
    required this.totalDeudaPendiente,
    required this.pagosProximos,
    required this.futureExpenses,
  });

  factory _DashboardData.fromRecords({
    required List<Ingreso> ingresos,
    required List<Gasto> gastos,
    required List<Deuda> deudas,
    required List<PagosDeudaData> pagos,
    required List<FutureExpenseSummary> futureExpenses,
    required AvailableBalanceBreakdown balanceBreakdown,
    required String userName,
    required List<DigitalAccountBalance> digitalAccounts,
    required List<Suscripcion> subscriptions,
  }) {
    final totalIngresos = ingresos.fold<double>(
      0,
      (total, ingreso) => total + ingreso.monto,
    );
    final now = DateTime.now();
    final ingresosDelMes =
        ingresos
            .where(
              (ingreso) =>
                  ingreso.fecha.year == now.year &&
                  ingreso.fecha.month == now.month,
            )
            .toList()
          ..sort((a, b) => b.fecha.compareTo(a.fecha));
    final totalRecibidoDelMes = ingresosDelMes.fold<double>(
      0,
      (total, ingreso) => total + ingreso.monto,
    );
    final totalPrestamosDelMes = ingresosDelMes
        .where(
          (ingreso) => IncomeType.fromStorage(ingreso.tipo) == IncomeType.loan,
        )
        .fold<double>(0, (total, ingreso) => total + ingreso.monto);
    final totalGanadoDelMes = totalRecibidoDelMes - totalPrestamosDelMes;
    final totalGastos = gastos.fold<double>(
      0,
      (total, gasto) => total + gasto.monto,
    );
    final recentExpenses = [...gastos]
      ..sort((first, second) => second.fecha.compareTo(first.fecha));
    final upcomingSubscriptions =
        subscriptions.where((item) => item.activa).toList()..sort(
          (first, second) => first.proximoPago.compareTo(second.proximoPago),
        );
    final gastosDelMes = gastos
        .where(
          (gasto) =>
              gasto.fecha.year == now.year && gasto.fecha.month == now.month,
        )
        .toList();
    final totalGastosDelMes = gastosDelMes.fold<double>(
      0,
      (total, gasto) => total + gasto.monto,
    );
    final totalPagosDeuda = pagos.fold<double>(
      0,
      (total, pago) => total + pago.monto,
    );
    final totalGastado = totalGastos + totalPagosDeuda;
    final porcentajeGastado = totalIngresos > 0
        ? totalGastado / totalIngresos * 100
        : null;

    final pagosPorDeuda = <int, double>{};
    for (final pago in pagos) {
      pagosPorDeuda.update(
        pago.deudaId,
        (total) => total + pago.monto,
        ifAbsent: () => pago.monto,
      );
    }

    final pagosProximos = <_PendingDebt>[];
    for (final deuda in deudas) {
      final saldoPendiente =
          deuda.montoOriginal - (pagosPorDeuda[deuda.id] ?? 0);
      if (saldoPendiente <= 0) continue;

      pagosProximos.add(
        _PendingDebt(
          deuda: deuda,
          saldoPendiente: saldoPendiente,
          montoProximoPago: deuda.cuota < saldoPendiente
              ? deuda.cuota
              : saldoPendiente,
        ),
      );
    }
    pagosProximos.sort(
      (a, b) => (a.deuda.fechaProximoPago ?? DateTime(9999)).compareTo(
        b.deuda.fechaProximoPago ?? DateTime(9999),
      ),
    );

    return _DashboardData(
      totalIngresos: totalIngresos,
      ingresosDelMes: ingresosDelMes,
      totalRecibidoDelMes: totalRecibidoDelMes,
      totalGanadoDelMes: totalGanadoDelMes,
      totalPrestamosDelMes: totalPrestamosDelMes,
      totalGastos: totalGastos,
      totalGastosDelMes: totalGastosDelMes,
      totalPagosDeuda: totalPagosDeuda,
      dineroDisponible: balanceBreakdown.total,
      balanceBreakdown: balanceBreakdown,
      userName: userName,
      digitalAccounts: digitalAccounts,
      subscriptions: upcomingSubscriptions,
      recentExpenses: recentExpenses.take(3).toList(),
      porcentajeGastado: porcentajeGastado,
      cantidadIngresos: ingresos.length,
      cantidadGastos: gastos.length,
      cantidadGastosDelMes: gastosDelMes.length,
      cantidadPagosDeuda: pagos.length,
      cantidadDeudas: deudas.length,
      deudasPendientes: pagosProximos.length,
      totalDeudaPendiente: pagosProximos.fold<double>(
        0,
        (total, deuda) => total + deuda.saldoPendiente,
      ),
      pagosProximos: pagosProximos,
      futureExpenses: futureExpenses,
    );
  }

  final double totalIngresos;
  final List<Ingreso> ingresosDelMes;
  final double totalRecibidoDelMes;
  final double totalGanadoDelMes;
  final double totalPrestamosDelMes;
  final double totalGastos;
  final double totalGastosDelMes;
  final double totalPagosDeuda;
  final double dineroDisponible;
  final AvailableBalanceBreakdown balanceBreakdown;
  final String userName;
  final List<DigitalAccountBalance> digitalAccounts;
  final List<Suscripcion> subscriptions;
  final List<Gasto> recentExpenses;
  final double? porcentajeGastado;
  final int cantidadIngresos;
  final int cantidadGastos;
  final int cantidadGastosDelMes;
  final int cantidadPagosDeuda;
  final int cantidadDeudas;
  final int deudasPendientes;
  final double totalDeudaPendiente;
  final List<_PendingDebt> pagosProximos;
  final List<FutureExpenseSummary> futureExpenses;

  bool get tieneMovimientos =>
      cantidadIngresos > 0 || cantidadGastos > 0 || cantidadPagosDeuda > 0;

  String get consejo {
    if (totalIngresos <= 0) {
      return 'Agrega tu primer ingreso y empieza a organizar tu dinero.';
    }

    final porcentaje = porcentajeGastado ?? 0;
    if (porcentaje >= 80) {
      return '¡Ojo con los gastos! Revisa cuáles están pesando más.';
    }
    if (dineroDisponible <= totalIngresos * 0.1) {
      return 'Te queda poquito disponible. Prioriza lo más importante.';
    }
    if (pagosProximos.isNotEmpty) {
      return 'Ten presentes tus próximos pagos para llegar con calma.';
    }
    if (porcentaje <= 50) {
      return 'Vas muy bien; todavía tienes margen para tus planes.';
    }
    return 'Sigue llevando el control de lo que entra y sale.';
  }
}

class _PendingDebt {
  const _PendingDebt({
    required this.deuda,
    required this.saldoPendiente,
    required this.montoProximoPago,
  });

  final Deuda deuda;
  final double saldoPendiente;
  final double montoProximoPago;
}

class _IncomeDraft {
  const _IncomeDraft({
    required this.type,
    required this.descripcion,
    required this.monto,
    required this.fecha,
    this.cuotasTotales,
    this.fechaPrimerPago,
    required this.destinos,
  });

  final IncomeType type;
  final String descripcion;
  final double monto;
  final DateTime fecha;
  final int? cuotasTotales;
  final DateTime? fechaPrimerPago;
  final List<IncomeDestination> destinos;
}

class _IncomeFormSheet extends StatefulWidget {
  const _IncomeFormSheet({
    required this.accounts,
    this.income,
    this.initialDestinations = const [],
  });

  final Ingreso? income;
  final List<CuentasDigitale> accounts;
  final List<IncomeDestination> initialDestinations;

  @override
  State<_IncomeFormSheet> createState() => _IncomeFormSheetState();
}

class _IncomeFormSheetState extends State<_IncomeFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _installmentsController = TextEditingController(text: '1');
  final List<_IncomeDestinationEditor> _destinations = [];
  late IncomeType _type;
  late DateTime _receivedDate;
  late DateTime _firstPaymentDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final income = widget.income;
    _type = income == null
        ? IncomeType.salary
        : IncomeType.fromStorage(income.tipo);
    _descriptionController.text = income?.descripcion ?? '';
    _amountController.text = income == null ? '' : formatAmount(income.monto);
    _receivedDate = income?.fecha ?? now;
    _firstPaymentDate = DateTime(now.year, now.month, now.day + 30);
    if (widget.initialDestinations.isNotEmpty) {
      _destinations.addAll(
        widget.initialDestinations.map(
          (destination) => _IncomeDestinationEditor(
            medio: destination.medio,
            monto: formatAmount(destination.monto),
            cuentaDigitalId: destination.cuentaDigitalId,
          ),
        ),
      );
    } else {
      final legacyMedium = MoneyMedium.fromStorage(income?.medio);
      _destinations.add(
        _IncomeDestinationEditor(
          medio: legacyMedium ?? MoneyMedium.cash,
          monto: legacyMedium == null || income == null
              ? ''
              : formatAmount(income.monto),
          cuentaDigitalId: income?.cuentaDigitalId,
        ),
      );
    }
    _amountController.addListener(_updateDistribution);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _installmentsController.dispose();
    for (final destination in _destinations) {
      destination.dispose();
    }
    super.dispose();
  }

  void _updateDistribution() {
    if (mounted) setState(() {});
  }

  void _addDestination() {
    final hasCash = _destinations.any(
      (destination) => destination.medio == MoneyMedium.cash,
    );
    setState(() {
      _destinations.add(
        _IncomeDestinationEditor(
          medio: hasCash ? MoneyMedium.digital : MoneyMedium.cash,
        ),
      );
    });
  }

  void _removeDestination(int index) {
    setState(() {
      _destinations.removeAt(index).dispose();
    });
  }

  Future<void> _selectDate({required bool isFirstPayment}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: isFirstPayment ? _firstPaymentDate : _receivedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (isFirstPayment) {
        _firstPaymentDate = selected;
      } else {
        _receivedDate = selected;
      }
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (!_distributionIsValid) return;
    final description = _descriptionController.text.trim();
    Navigator.pop(
      context,
      _IncomeDraft(
        type: _type,
        descripcion: description,
        monto: parseMoney(_amountController.text),
        fecha: _receivedDate,
        cuotasTotales: _type == IncomeType.loan
            ? int.parse(_installmentsController.text.trim())
            : null,
        fechaPrimerPago: _type == IncomeType.loan ? _firstPaymentDate : null,
        destinos: [
          for (final destination in _destinations)
            IncomeDestination(
              medio: destination.medio,
              monto: parseMoney(destination.controller.text),
              cuentaDigitalId: destination.cuentaDigitalId,
            ),
        ],
      ),
    );
  }

  double get _incomeAmount => tryParseMoney(_amountController.text) ?? 0;

  double get _distributionTotal => _destinations.fold<double>(
    0,
    (total, destination) =>
        total + (tryParseMoney(destination.controller.text) ?? 0),
  );

  bool get _distributionIsValid {
    if (_incomeAmount <= 0 || _destinations.isEmpty) return false;
    final selected = <String>{};
    for (final destination in _destinations) {
      final amount = tryParseMoney(destination.controller.text);
      if (amount == null || amount <= 0) return false;
      if (destination.medio == MoneyMedium.digital &&
          (destination.cuentaDigitalId == null ||
              !widget.accounts.any(
                (account) => account.id == destination.cuentaDigitalId,
              ))) {
        return false;
      }
      final key =
          '${destination.medio.storageValue}:'
          '${destination.cuentaDigitalId ?? 'cash'}';
      if (!selected.add(key)) return false;
    }
    return (_distributionTotal - _incomeAmount).abs() <= 1e-8;
  }

  Widget _buildDestination(int index) {
    final destination = _destinations[index];
    return Container(
      key: ValueKey('income-destination-$index'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: AppCardDecorations.surface,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<MoneyMedium>(
                  initialValue: destination.medio,
                  decoration: const InputDecoration(labelText: 'Destino'),
                  items: [
                    for (final medium in MoneyMedium.values)
                      DropdownMenuItem(
                        value: medium,
                        child: Text(medium.label),
                      ),
                  ],
                  onChanged: (medium) {
                    if (medium == null) return;
                    setState(() {
                      destination.medio = medium;
                      if (medium != MoneyMedium.digital) {
                        destination.cuentaDigitalId = null;
                      }
                    });
                  },
                ),
              ),
              if (_destinations.length > 1)
                IconButton(
                  tooltip: 'Quitar destino',
                  onPressed: () => _removeDestination(index),
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                ),
            ],
          ),
          if (destination.medio == MoneyMedium.digital) ...[
            const SizedBox(height: 10),
            if (widget.accounts.isEmpty)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Agrega una cuenta digital en Configuración.'),
              )
            else
              DropdownButtonFormField<int>(
                key: ValueKey('income-destination-account-$index'),
                initialValue: destination.cuentaDigitalId,
                decoration: const InputDecoration(labelText: 'Cuenta digital'),
                items: [
                  for (final account in widget.accounts)
                    DropdownMenuItem(
                      value: account.id,
                      child: Text(account.nombre),
                    ),
                ],
                onChanged: (accountId) =>
                    setState(() => destination.cuentaDigitalId = accountId),
              ),
          ],
          const SizedBox(height: 10),
          TextFormField(
            key: ValueKey('income-destination-amount-$index'),
            controller: destination.controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [ThousandsInputFormatter()],
            decoration: const InputDecoration(
              labelText: 'Importe para este destino',
              prefixText: r'$ ',
            ),
            onChanged: (_) => _updateDistribution(),
            validator: (value) {
              final amount = tryParseMoney(value);
              return amount == null || amount <= 0
                  ? 'Escribe un importe mayor que cero.'
                  : null;
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(22, 22, 22, 24 + bottomInset),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.income == null
                              ? 'Agregar dinero'
                              : 'Editar ingreso',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const AnimatedCat(
                        asset: CatAssets.ingresos,
                        label: 'Gato acompañando tus ingresos',
                        width: 82,
                        height: 68,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<IncomeType>(
                    key: const ValueKey('income-type'),
                    isExpanded: true,
                    initialValue: _type,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de ingreso',
                      prefixIcon: Icon(Icons.south_west_rounded),
                    ),
                    items: [
                      for (final type in [
                        IncomeType.salary,
                        IncomeType.extra,
                        if (widget.income == null || _type == IncomeType.loan)
                          IncomeType.loan,
                        if (widget.income != null) IncomeType.legacy,
                      ])
                        DropdownMenuItem(value: type, child: Text(type.label)),
                    ],
                    onChanged: widget.income == null || _type != IncomeType.loan
                        ? (type) {
                            if (type != null) setState(() => _type = type);
                          }
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const ValueKey('income-description'),
                    controller: _descriptionController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: _type == IncomeType.loan
                          ? 'Nombre o concepto del préstamo'
                          : 'Descripción o concepto',
                      prefixIcon: const Icon(Icons.edit_outlined),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? _type == IncomeType.loan
                              ? 'Escribe el nombre del préstamo.'
                              : null
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const ValueKey('income-amount'),
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: const [ThousandsInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Valor recibido',
                      prefixText: r'$ ',
                    ),
                    validator: (value) {
                      final amount = tryParseMoney(value);
                      return amount == null || amount <= 0
                          ? 'Escribe un valor mayor que cero.'
                          : null;
                    },
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Distribuye el importe entre tus destinos',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  for (var index = 0; index < _destinations.length; index++)
                    _buildDestination(index),
                  TextButton.icon(
                    onPressed: _addDestination,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Agregar otro destino'),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Total distribuido: ${formatMoney(_distributionTotal)}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  if (_incomeAmount > 0)
                    Text(
                      (_incomeAmount - _distributionTotal).abs() <= 1e-8
                          ? '¡Todo listo! La distribución coincide con el ingreso.'
                          : _distributionTotal < _incomeAmount
                          ? 'Te faltan ${formatMoney(_incomeAmount - _distributionTotal)} por distribuir.'
                          : 'Sobran ${formatMoney(_distributionTotal - _incomeAmount)} en la distribución.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _distributionTotal > _incomeAmount
                            ? Theme.of(context).colorScheme.error
                            : AppColors.primary,
                      ),
                    ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _selectDate(isFirstPayment: false),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Recibido · ${_shortDate(_receivedDate)}',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_type == IncomeType.loan && widget.income == null) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      key: const ValueKey('income-installments'),
                      controller: _installmentsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Número de cuotas',
                        prefixIcon: Icon(Icons.format_list_numbered_rounded),
                      ),
                      validator: (value) {
                        if (_type != IncomeType.loan) return null;
                        final installments = int.tryParse((value ?? '').trim());
                        return installments == null || installments <= 0
                            ? 'Indica cuántas cuotas tendrá.'
                            : null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _selectDate(isFirstPayment: true),
                      child: Row(
                        children: [
                          const Icon(Icons.event_outlined),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Primer pago · ${_shortDate(_firstPaymentDate)}',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Se creará una deuda vinculada. La cuota inicial será el '
                      'valor recibido dividido entre las cuotas.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _distributionIsValid ? _save : null,
                      icon: const Icon(Icons.add_rounded),
                      label: Text(
                        widget.income != null
                            ? 'Guardar cambios'
                            : _type == IncomeType.loan
                            ? 'Registrar préstamo'
                            : 'Guardar ingreso',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IncomeDestinationEditor {
  _IncomeDestinationEditor({
    required this.medio,
    String monto = '',
    this.cuentaDigitalId,
  }) : controller = TextEditingController(text: monto);

  final TextEditingController controller;
  MoneyMedium medio;
  int? cuentaDigitalId;

  void dispose() => controller.dispose();
}

class _DistributionDraft {
  const _DistributionDraft({required this.cash, required this.digital});

  final double cash;
  final double digital;
}

class _DistributionFormSheet extends StatefulWidget {
  const _DistributionFormSheet({
    required this.total,
    required this.cash,
    required this.digital,
  });

  final double total;
  final double cash;
  final double digital;

  @override
  State<_DistributionFormSheet> createState() => _DistributionFormSheetState();
}

class _DistributionFormSheetState extends State<_DistributionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _cashController;
  late final TextEditingController _digitalController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cashController = TextEditingController(text: formatAmount(widget.cash));
    _digitalController = TextEditingController(
      text: formatAmount(widget.digital),
    );
  }

  @override
  void dispose() {
    _cashController.dispose();
    _digitalController.dispose();
    super.dispose();
  }

  String? _validateAmount(String? value) {
    final amount = tryParseMoney(value);
    return amount == null || amount < 0
        ? 'Escribe un valor válido igual o mayor que cero.'
        : null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final cash = parseMoney(_cashController.text);
    final digital = parseMoney(_digitalController.text);
    if ((cash + digital - widget.total).abs() > 1e-8) {
      setState(() {
        _error = cash + digital < widget.total
            ? 'Te faltan ${_formatMoney(widget.total - cash - digital)} por distribuir.'
            : 'Sobran ${_formatMoney(cash + digital - widget.total)} en la distribución.';
      });
      return;
    }
    Navigator.pop(context, _DistributionDraft(cash: cash, digital: digital));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(22, 22, 22, 24 + bottomInset),
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
                    'Distribuir dinero disponible',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total disponible: ${_formatMoney(widget.total)}. '
                    'La suma de efectivo y digital debe coincidir con el total.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('distribution-cash'),
                    controller: _cashController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: const [ThousandsInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Dinero en efectivo',
                      prefixText: r'$ ',
                    ),
                    validator: _validateAmount,
                    onChanged: (_) => setState(() => _error = null),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const ValueKey('distribution-digital'),
                    controller: _digitalController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: const [ThousandsInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Dinero digital',
                      prefixText: r'$ ',
                    ),
                    validator: _validateAmount,
                    onChanged: (_) => setState(() => _error = null),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total distribuido: '
                    '${_formatMoney((tryParseMoney(_cashController.text) ?? 0) + (tryParseMoney(_digitalController.text) ?? 0))} '
                    'de ${_formatMoney(widget.total)}',
                  ),
                  if (widget.total -
                          (tryParseMoney(_cashController.text) ?? 0) -
                          (tryParseMoney(_digitalController.text) ?? 0) >
                      1e-8)
                    Text(
                      'Te faltan ${_formatMoney(widget.total - (tryParseMoney(_cashController.text) ?? 0) - (tryParseMoney(_digitalController.text) ?? 0))} por distribuir.',
                    )
                  else if ((tryParseMoney(_cashController.text) ?? 0) +
                          (tryParseMoney(_digitalController.text) ?? 0) -
                          widget.total >
                      1e-8)
                    Text(
                      'Sobran ${_formatMoney((tryParseMoney(_cashController.text) ?? 0) + (tryParseMoney(_digitalController.text) ?? 0) - widget.total)} en la distribución.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed:
                          ((tryParseMoney(_cashController.text) ?? 0) +
                                      (tryParseMoney(_digitalController.text) ??
                                          0) -
                                      widget.total)
                                  .abs() <=
                              1e-8
                          ? _save
                          : null,
                      icon: const Icon(Icons.account_balance_wallet_outlined),
                      label: const Text('Guardar distribución'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.data,
    required this.onAddIncome,
    required this.isSavingIncome,
    required this.onDistributeBalance,
    required this.isSavingDistribution,
    required this.onViewFutureExpenses,
    required this.onViewExpenses,
    required this.onViewIncomes,
    required this.onViewSubscriptions,
    required this.onViewSettings,
  });

  final _DashboardData data;
  final VoidCallback onAddIncome;
  final bool isSavingIncome;
  final VoidCallback onDistributeBalance;
  final bool isSavingDistribution;
  final VoidCallback? onViewFutureExpenses;
  final VoidCallback? onViewExpenses;
  final VoidCallback? onViewIncomes;
  final VoidCallback? onViewSubscriptions;
  final VoidCallback? onViewSettings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AvailableBalanceCard(
          data: data,
          onDistributeBalance: onDistributeBalance,
          isSavingDistribution: isSavingDistribution,
        ),
        const SizedBox(height: 12),
        _BalanceBreakdownCards(data: data),
        const SizedBox(height: 18),
        _IncomeSummaryPanel(
          data: data,
          onAddIncome: onAddIncome,
          isSavingIncome: isSavingIncome,
          onViewExpenses: onViewExpenses,
          onViewIncomes: onViewIncomes,
        ),
        const SizedBox(height: 18),
        _RecentExpensesPanel(expenses: data.recentExpenses),
        const SizedBox(height: 18),
        _UpcomingSubscriptionsPanel(
          subscriptions: data.subscriptions.take(3).toList(),
          onViewAll: onViewSubscriptions,
        ),
        const SizedBox(height: 12),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton.icon(
            onPressed: onViewSettings,
            icon: const Icon(Icons.swap_horiz_rounded),
            label: const Text('Ver todas las cuentas · mover dinero'),
          ),
        ),
        const SizedBox(height: 28),
        const _SectionHeading('Deudas pendientes'),
        const SizedBox(height: 12),
        _DebtSummaryPanel(data: data),
        const SizedBox(height: 26),
        const _SectionHeading('Mis gastos futuros'),
        const SizedBox(height: 12),
        _FutureExpensesSummaryPanel(
          plans: data.futureExpenses,
          onViewAll: onViewFutureExpenses,
        ),
        const SizedBox(height: 26),
        const _SectionHeading('Próximos pagos'),
        const SizedBox(height: 12),
        _UpcomingPaymentsPanel(data: data),
        const SizedBox(height: 26),
        _AdvicePanel(advice: data.consejo),
      ],
    );
  }
}

class _IncomeSummaryPanel extends StatelessWidget {
  const _IncomeSummaryPanel({
    required this.data,
    required this.onAddIncome,
    required this.isSavingIncome,
    required this.onViewExpenses,
    required this.onViewIncomes,
  });

  final _DashboardData data;
  final VoidCallback onAddIncome;
  final bool isSavingIncome;
  final VoidCallback? onViewExpenses;
  final VoidCallback? onViewIncomes;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: AppCardDecorations.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final total = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dinero recibido este mes',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatMoney(data.totalRecibidoDelMes),
                    key: const ValueKey('home-monthly-received'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              );
              final addButton = FilledButton.icon(
                onPressed: isSavingIncome ? null : onAddIncome,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Agregar dinero'),
              );
              final addExpenseButton = OutlinedButton.icon(
                onPressed: onViewExpenses,
                icon: const Icon(Icons.add_shopping_cart_outlined),
                label: const Text('Registrar gasto'),
              );
              if (constraints.maxWidth < 420) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    total,
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [addButton, addExpenseButton],
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: total),
                  addButton,
                  const SizedBox(width: 8),
                  addExpenseButton,
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              _IncomeBreakdown(
                label: 'Sueldo y dinero extra',
                value: data.totalGanadoDelMes,
              ),
              _IncomeBreakdown(
                label: 'Préstamos recibidos',
                value: data.totalPrestamosDelMes,
              ),
            ],
          ),
          if (data.porcentajeGastado != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 5,
              children: [
                Text(
                  '${_formatPercent(data.porcentajeGastado!)}%',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  'de tus ingresos se han usado en gastos y pagos de deuda.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          TextButton.icon(
            key: const ValueKey('home-view-incomes'),
            onPressed: onViewIncomes,
            icon: const Icon(Icons.history_rounded),
            label: const Text('Ver historial de ingresos'),
          ),
        ],
      ),
    );
  }
}

class _IncomeBreakdown extends StatelessWidget {
  const _IncomeBreakdown({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 3),
        Text(
          formatMoney(value),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}

class _BalanceBreakdownCards extends StatelessWidget {
  const _BalanceBreakdownCards({required this.data});

  final _DashboardData data;

  @override
  Widget build(BuildContext context) {
    final visibleAccounts = data.digitalAccounts.take(2).toList();
    final remainingAccounts =
        data.digitalAccounts.length - visibleAccounts.length;
    final digitalDetail = visibleAccounts.isEmpty
        ? 'Sin cuentas agregadas'
        : visibleAccounts
              .map(
                (account) =>
                    '${account.account.nombre}: ${formatMoney(account.balance)}',
              )
              .followedBy(
                remainingAccounts > 0
                    ? ['+$remainingAccounts cuentas más']
                    : const <String>[],
              )
              .join(' · ');
    return LayoutBuilder(
      builder: (context, constraints) {
        final cashCard = _BalanceMediumCard(
          label: 'Dinero en efectivo',
          amount: data.balanceBreakdown.cash,
          detail: 'Movimientos en efectivo',
          icon: Icons.payments_outlined,
        );
        final digitalCard = _BalanceMediumCard(
          label: 'Dinero digital',
          amount: data.balanceBreakdown.digital,
          detail: digitalDetail,
          icon: Icons.account_balance_wallet_outlined,
        );
        if (constraints.maxWidth < 440) {
          return Column(
            children: [cashCard, const SizedBox(height: 10), digitalCard],
          );
        }
        return Row(
          children: [
            Expanded(child: cashCard),
            const SizedBox(width: 12),
            Expanded(child: digitalCard),
          ],
        );
      },
    );
  }
}

class _BalanceMediumCard extends StatelessWidget {
  const _BalanceMediumCard({
    required this.label,
    required this.amount,
    required this.detail,
    required this.icon,
  });

  final String label;
  final double amount;
  final String detail;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppCardDecorations.surface,
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 5),
                Text(
                  formatMoney(amount),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailableBalanceCard extends StatelessWidget {
  const _AvailableBalanceCard({
    required this.data,
    required this.onDistributeBalance,
    required this.isSavingDistribution,
  });

  final _DashboardData data;
  final VoidCallback onDistributeBalance;
  final bool isSavingDistribution;

  @override
  Widget build(BuildContext context) {
    final separated =
        data.balanceBreakdown.cash + data.balanceBreakdown.digital;
    final distributionProgress = data.dineroDisponible <= 0
        ? 0.0
        : (separated / data.dineroDisponible).clamp(0.0, 1.0).toDouble();
    final description = data.cantidadIngresos == 0
        ? 'Todavía no hay ingresos por aquí.'
        : 'Ingresos menos gastos, pagos, ahorros y reservas reales.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: AppCardDecorations.featured,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Dinero disponible',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            data.tieneMovimientos ? _formatMoney(data.dineroDisponible) : '—',
            key: const ValueKey('home-available-balance'),
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontSize: 32),
          ),
          const SizedBox(height: 4),
          Text(
            'Total disponible',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Efectivo + digital',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Text(_formatMoney(separated)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: distributionProgress,
              minHeight: 8,
              backgroundColor: AppColors.outline.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 12),
          _BalanceMediumLine(
            label: 'Efectivo',
            amount: data.balanceBreakdown.cash,
          ),
          const SizedBox(height: 8),
          _BalanceMediumLine(
            label: 'Digital',
            amount: data.balanceBreakdown.digital,
          ),
          const SizedBox(height: 8),
          _BalanceMediumLine(
            label: 'Pendiente de asignación',
            amount: data.balanceBreakdown.unclassified,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const ValueKey('distribute-available-balance'),
              onPressed: isSavingDistribution ? null : onDistributeBalance,
              icon: isSavingDistribution
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.swap_horiz_rounded),
              label: const Text('Distribuir / editar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceMediumLine extends StatelessWidget {
  const _BalanceMediumLine({required this.label, required this.amount});

  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(_formatMoney(amount)),
      ],
    );
  }
}

class _RecentExpensesPanel extends StatelessWidget {
  const _RecentExpensesPanel({required this.expenses});

  final List<Gasto> expenses;

  @override
  Widget build(BuildContext context) {
    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading('Gastos recientes'),
          const SizedBox(height: 10),
          if (expenses.isEmpty)
            const _EmptyMessage('Todavía no hay gastos registrados.'),
          for (var index = 0; index < expenses.length; index++) ...[
            if (index > 0) const Divider(height: 18),
            Row(
              children: [
                const Icon(
                  Icons.north_east_rounded,
                  color: AppColors.primary,
                  size: 19,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expenses[index].nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        '${expenses[index].categoria} · '
                        '${MoneyMedium.fromStorage(expenses[index].medio)?.label ?? 'Medio sin clasificar'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(formatMoney(expenses[index].monto)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _UpcomingSubscriptionsPanel extends StatelessWidget {
  const _UpcomingSubscriptionsPanel({
    required this.subscriptions,
    required this.onViewAll,
  });

  final List<Suscripcion> subscriptions;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading('Próximos pagos de suscripciones'),
          const SizedBox(height: 10),
          if (subscriptions.isEmpty)
            const _EmptyMessage('No tienes pagos de suscripción próximos.'),
          for (var index = 0; index < subscriptions.length; index++) ...[
            if (index > 0) const Divider(height: 18),
            Row(
              children: [
                const Icon(
                  Icons.autorenew_rounded,
                  color: AppColors.primary,
                  size: 19,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subscriptions[index].nombre,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        _shortDate(subscriptions[index].proximoPago),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(formatMoney(subscriptions[index].precio)),
              ],
            ),
          ],
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: onViewAll,
              child: const Text('Ver suscripciones'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtSummaryPanel extends StatelessWidget {
  const _DebtSummaryPanel({required this.data});

  final _DashboardData data;

  @override
  Widget build(BuildContext context) {
    return _DashboardPanel(
      child: data.cantidadDeudas == 0
          ? const _EmptyMessage('Todavía no hay deudas por aquí.')
          : data.deudasPendientes == 0
          ? const _EmptyMessage('¡Bien! No hay deudas pendientes.')
          : Row(
              children: [
                const Icon(
                  Icons.account_balance_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _recordCount(
                          data.deudasPendientes,
                          'deuda pendiente',
                          'deudas pendientes',
                        ),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Saldo pendiente total',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _formatMoney(data.totalDeudaPendiente),
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
    );
  }
}

class _UpcomingPaymentsPanel extends StatelessWidget {
  const _UpcomingPaymentsPanel({required this.data});

  final _DashboardData data;

  @override
  Widget build(BuildContext context) {
    if (data.cantidadDeudas == 0) {
      return const _DashboardPanel(
        child: _EmptyMessage('Todavía no hay deudas por aquí.'),
      );
    }
    if (data.pagosProximos.isEmpty) {
      return const _DashboardPanel(
        child: _EmptyMessage('Por ahora no hay pagos próximos.'),
      );
    }

    return _DashboardPanel(
      child: Column(
        children: [
          for (var index = 0; index < data.pagosProximos.length; index++) ...[
            _UpcomingPaymentRow(payment: data.pagosProximos[index]),
            if (index < data.pagosProximos.length - 1)
              const Divider(height: 22),
          ],
        ],
      ),
    );
  }
}

class _FutureExpensesSummaryPanel extends StatelessWidget {
  const _FutureExpensesSummaryPanel({
    required this.plans,
    required this.onViewAll,
  });

  final List<FutureExpenseSummary> plans;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final activePlans = plans
        .where((item) => item.plan.status == FutureExpenseStatus.active)
        .take(3)
        .toList();
    return _DashboardPanel(
      child: Column(
        key: const ValueKey('home-future-expenses'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (activePlans.isEmpty)
            const _EmptyMessage('Todavía no hay planes por aquí.'),
          for (var index = 0; index < activePlans.length; index++) ...[
            _FutureExpenseSummaryRow(summary: activePlans[index]),
            if (index < activePlans.length - 1) const Divider(height: 20),
          ],
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              key: const ValueKey('home-future-expenses-see-all'),
              onPressed: onViewAll,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Ver todos'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FutureExpenseSummaryRow extends StatelessWidget {
  const _FutureExpenseSummaryRow({required this.summary});

  final FutureExpenseSummary summary;

  @override
  Widget build(BuildContext context) {
    final plan = summary.plan;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                plan.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formatMoney(plan.targetAmount),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
        const SizedBox(height: 5),
        Wrap(
          spacing: 14,
          runSpacing: 4,
          children: [
            Text('Reservado: ${formatMoney(summary.reservedAmount)}'),
            Text('Falta: ${formatMoney(summary.amountMissing)}'),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${formatSpanishLongDate(plan.targetDate)} · ${plan.frequency.label}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _UpcomingPaymentRow extends StatelessWidget {
  const _UpcomingPaymentRow({required this.payment});

  final _PendingDebt payment;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.event_outlined,
            color: AppColors.primary,
            size: 19,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                payment.deuda.nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                payment.deuda.fechaProximoPago == null
                    ? 'Fecha no definida'
                    : _formatDebtDate(payment.deuda.fechaProximoPago!),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _formatMoney(payment.montoProximoPago),
          textAlign: TextAlign.end,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}

class _AdvicePanel extends StatelessWidget {
  const _AdvicePanel({required this.advice});

  final String advice;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: AppCardDecorations.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: AppColors.accent),
          const SizedBox(height: 12),
          Text(
            'CONSEJO FINANCIERO',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 7),
          Text(advice, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _DashboardPanel extends StatelessWidget {
  const _DashboardPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: AppCardDecorations.surface,
      child: child,
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(message, style: Theme.of(context).textTheme.bodyMedium);
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return _DashboardPanel(
      child: Center(
        child: Text(
          'Estamos preparando tu resumen...',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ups, tu resumen no cargó esta vez.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Intentar de nuevo'),
          ),
        ],
      ),
    );
  }
}

String _recordCount(int count, String singular, String plural) {
  return '$count ${count == 1 ? singular : plural}';
}

String _formatMoney(double amount) {
  return formatMoney(amount);
}

String _formatPercent(double percent) {
  return percent.toStringAsFixed(1).replaceAll('.', ',');
}

String _formatDebtDate(DateTime date) {
  const months = [
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
  ];
  final dueDate = DateTime(date.year, date.month, date.day);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dateLabel = '${date.day} ${months[date.month - 1]}';

  if (dueDate.isBefore(today)) return 'Vencido - $dateLabel';
  if (dueDate == today) return 'Hoy';
  if (dueDate == today.add(const Duration(days: 1))) return 'Mañana';
  return dateLabel;
}

String _shortDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

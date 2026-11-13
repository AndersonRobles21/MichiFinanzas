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
import '../../widgets/app_page_header.dart';
import '../../widgets/cat_illustration.dart';
import 'dashboard_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.databaseService,
    this.isActive = true,
    this.onViewFutureExpenses,
    this.onViewExpenses,
    this.onViewIncomes,
    this.onViewSubscriptions,
    this.onViewDebts,
    this.onViewSavings,
    this.onViewSettings,
    this.onTransferMoney,
  });

  final DatabaseService? databaseService;
  final bool isActive;
  final VoidCallback? onViewFutureExpenses;
  final VoidCallback? onViewExpenses;
  final VoidCallback? onViewIncomes;
  final VoidCallback? onViewSubscriptions;
  final VoidCallback? onViewDebts;
  final VoidCallback? onViewSavings;
  final VoidCallback? onViewSettings;
  final VoidCallback? onTransferMoney;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final DatabaseService _databaseService;
  late final bool _ownsDatabaseService;
  late Future<DashboardData> _dashboardFuture;
  late final StreamSubscription<void> _financialChanges;
  bool _isSavingIncome = false;

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
          final horizontalPadding = constraints.maxWidth < 420
              ? AppSpacing.pageHorizontal
              : AppSpacing.pageHorizontalWide;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              AppSpacing.pageTop,
              horizontalPadding,
              36,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<DashboardData>(
                      future: _dashboardFuture,
                      builder: (context, snapshot) {
                        final name = snapshot.data?.userName ?? '';
                        return AppPageHeader(
                          title: 'Inicio',
                          subtitleKey: const ValueKey('home-user-greeting'),
                          subtitle: name.isEmpty
                              ? 'Aquí ves cómo va tu dinero, sin enredos.'
                              : 'Hola, $name. Aquí ves cómo va tu dinero.',
                          caption: formatSpanishLongDate(DateTime.now()),
                          captionKey: const ValueKey('home-current-date'),
                          trailing: AnimatedCat(
                            asset: CatAssets.inicio,
                            label: 'Gato de inicio',
                            width: 64,
                            height: 54,
                            floating: widget.isActive,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.section),
                    FutureBuilder<DashboardData>(
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
                          onViewFutureExpenses: widget.onViewFutureExpenses,
                          onViewExpenses: widget.onViewExpenses,
                          onViewIncomes: widget.onViewIncomes,
                          onViewSubscriptions: widget.onViewSubscriptions,
                          onViewDebts: widget.onViewDebts,
                          onViewSavings: widget.onViewSavings,
                          onViewSettings: widget.onViewSettings,
                          onTransferMoney: widget.onTransferMoney,
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
              final padding = constraints.maxWidth < 420
                  ? AppSpacing.pageHorizontal
                  : AppSpacing.pageHorizontalWide;
              return ListView(
                padding: EdgeInsets.fromLTRB(
                  padding,
                  AppSpacing.pageTop,
                  padding,
                  100,
                ),
                children: [
                  const AppPageHeader(
                    title: 'Ingresos',
                    subtitle:
                        'Aquí tienes el historial de todo el dinero que has recibido.',
                  ),
                  const SizedBox(height: AppSpacing.section),
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
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: AppColors.positive),
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

Future<DashboardData> _loadDashboard(DatabaseService service) async {
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
      service.obtenerTotalAhorros(),
      service.obtenerMovimientosAhorro(),
      service.obtenerTransferencias(),
    ]);

    return DashboardData.fromRecords(
      ingresos: results[0] as List<Ingreso>,
      gastos: results[1] as List<Gasto>,
      deudas: results[2] as List<Deuda>,
      pagos: results[3] as List<PagosDeudaData>,
      futureExpenses: results[4] as List<FutureExpenseSummary>,
      balanceBreakdown: balanceBreakdown,
      userName: userName,
      digitalAccounts: results[5] as List<DigitalAccountBalance>,
      subscriptions: results[6] as List<Suscripcion>,
      totalAhorros: results[7] as double,
      savingsMovements: results[8] as List<MovimientosAhorroData>,
      transfers: results[9] as List<TransferenciasDineroData>,
    );
  });
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
                            ? AppColors.negative
                            : AppColors.positive,
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

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.data,
    required this.onAddIncome,
    required this.isSavingIncome,
    required this.onViewFutureExpenses,
    required this.onViewExpenses,
    required this.onViewIncomes,
    required this.onViewSubscriptions,
    required this.onViewDebts,
    required this.onViewSavings,
    required this.onViewSettings,
    required this.onTransferMoney,
  });

  final DashboardData data;
  final VoidCallback onAddIncome;
  final bool isSavingIncome;
  final VoidCallback? onViewFutureExpenses;
  final VoidCallback? onViewExpenses;
  final VoidCallback? onViewIncomes;
  final VoidCallback? onViewSubscriptions;
  final VoidCallback? onViewDebts;
  final VoidCallback? onViewSavings;
  final VoidCallback? onViewSettings;
  final VoidCallback? onTransferMoney;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AvailableBalanceCard(data: data, onViewSettings: onViewSettings),
        const SizedBox(height: 16),
        _QuickActionsPanel(
          onAddIncome: onAddIncome,
          isSavingIncome: isSavingIncome,
          onViewExpenses: onViewExpenses,
          onTransferMoney: onTransferMoney,
        ),
        const SizedBox(height: AppSpacing.section),
        _FinancialSummaryPanel(
          data: data,
          onViewDebts: onViewDebts,
          onViewSavings: onViewSavings,
        ),
        const SizedBox(height: AppSpacing.section),
        _RecentActivityPanel(
          activities: data.recentActivities,
          onViewIncomes: onViewIncomes,
          onViewExpenses: onViewExpenses,
          onViewSavings: onViewSavings,
          onViewSettings: onViewSettings,
        ),
        const SizedBox(height: AppSpacing.section),
        _RemindersPanel(
          data: data,
          onViewFutureExpenses: onViewFutureExpenses,
          onViewSubscriptions: onViewSubscriptions,
          onViewDebts: onViewDebts,
        ),
        const SizedBox(height: AppSpacing.section),
        _AdvicePanel(advice: data.consejo),
      ],
    );
  }
}

class _QuickActionsPanel extends StatelessWidget {
  const _QuickActionsPanel({
    required this.onAddIncome,
    required this.isSavingIncome,
    required this.onViewExpenses,
    required this.onTransferMoney,
  });

  final VoidCallback onAddIncome;
  final bool isSavingIncome;
  final VoidCallback? onViewExpenses;
  final VoidCallback? onTransferMoney;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          key: const ValueKey('home-quick-income'),
          onPressed: isSavingIncome ? null : onAddIncome,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Agregar ingreso'),
        ),
        OutlinedButton.icon(
          key: const ValueKey('home-quick-expense'),
          onPressed: onViewExpenses,
          icon: const Icon(Icons.north_east_rounded),
          label: const Text('Registrar gasto'),
        ),
        FilledButton.tonalIcon(
          key: const ValueKey('home-quick-transfer'),
          onPressed: onTransferMoney,
          icon: const Icon(Icons.swap_horiz_rounded),
          label: const Text('Transferir dinero'),
        ),
      ],
    );
  }
}

class _FinancialSummaryPanel extends StatelessWidget {
  const _FinancialSummaryPanel({
    required this.data,
    required this.onViewDebts,
    required this.onViewSavings,
  });

  final DashboardData data;
  final VoidCallback? onViewDebts;
  final VoidCallback? onViewSavings;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final month = '${_monthName(now.month)} ${now.year}';

    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen financiero',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 3),
          Text(month, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 12.0;
              final itemWidth = (constraints.maxWidth - spacing) / 2;
              return Wrap(
                spacing: spacing,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _SummaryMetric(
                      label: 'Ingresos del mes',
                      value: data.totalRecibidoDelMes,
                      color: AppColors.positive,
                      valueKey: const ValueKey('home-monthly-received'),
                      footnote: data.totalPrestamosDelMes > 0
                          ? 'Incluye préstamos'
                          : 'Sueldo y dinero extra',
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _SummaryMetric(
                      label: 'Gastos del mes',
                      value: data.totalGastosDelMes,
                      color: AppColors.negative,
                      valueKey: const ValueKey('home-monthly-expenses'),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _SummaryMetric(
                      label: 'Ahorro acumulado',
                      value: data.totalAhorros,
                      color: AppColors.accent,
                      valueKey: const ValueKey('home-total-savings'),
                      footnote: 'Total registrado',
                      onTap: onViewSavings,
                    ),
                  ),
                  if (data.deudasPendientes > 0)
                    SizedBox(
                      width: itemWidth,
                      child: _SummaryMetric(
                        label: 'Deuda pendiente',
                        value: data.totalDeudaPendiente,
                        color: AppColors.warning,
                        valueKey: const ValueKey('home-outstanding-debt'),
                        footnote: _recordCount(
                          data.deudasPendientes,
                          'deuda',
                          'deudas',
                        ),
                        onTap: onViewDebts,
                      ),
                    ),
                ],
              );
            },
          ),
          if (data.porcentajeGastado != null) ...[
            const SizedBox(height: 14),
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
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    this.valueKey,
    required this.label,
    required this.value,
    required this.color,
    this.footnote,
    this.onTap,
  });

  final Key? valueKey;
  final String label;
  final double value;
  final Color color;
  final String? footnote;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 5),
        Text(
          formatMoney(value),
          key: valueKey,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (footnote != null) ...[
          const SizedBox(height: 3),
          Text(footnote!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
    if (onTap == null) return content;
    return Semantics(
      button: true,
      label: 'Ver $label',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.small),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: content,
        ),
      ),
    );
  }
}

class _AvailableBalanceCard extends StatelessWidget {
  const _AvailableBalanceCard({
    required this.data,
    required this.onViewSettings,
  });

  final DashboardData data;
  final VoidCallback? onViewSettings;

  @override
  Widget build(BuildContext context) {
    final digitalAccountTotal = data.digitalAccounts.fold<double>(
      0,
      (total, account) => total + account.balance,
    );
    final digitalWithoutAccount =
        data.balanceBreakdown.digital - digitalAccountTotal;
    final description = data.cantidadIngresos == 0
        ? 'Agrega un ingreso para comenzar a organizar tu dinero.'
        : 'Saldo real después de gastos, pagos, ahorros y reservas.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
              const AnimatedCat(
                asset: CatAssets.inicio,
                label: 'Gato de MichiFinanzas',
                width: 42,
                height: 38,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data.tieneMovimientos || data.digitalAccounts.isNotEmpty
                ? _formatMoney(data.dineroDisponible)
                : '—',
            key: const ValueKey('home-available-balance'),
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontSize: 32),
          ),
          const SizedBox(height: 4),
          Text(
            'Total disponible · no incluye deudas ni planes futuros',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          Text(
            '¿Dónde está mi dinero?',
            key: const ValueKey('home-money-location-title'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          _BalanceMediumLine(
            label: 'Efectivo',
            amount: data.balanceBreakdown.cash,
            icon: Icons.payments_outlined,
            valueKey: const ValueKey('home-cash-balance'),
          ),
          const SizedBox(height: 8),
          _BalanceMediumLine(
            label: 'Digital',
            amount: data.balanceBreakdown.digital,
            icon: Icons.account_balance_wallet_outlined,
            valueKey: const ValueKey('home-digital-balance'),
          ),
          for (final account in data.digitalAccounts) ...[
            const SizedBox(height: 8),
            _DigitalAccountBalanceLine(account: account),
          ],
          if (digitalWithoutAccount > 1e-8) ...[
            const SizedBox(height: 8),
            _BalanceMediumLine(
              label: 'Digital sin cuenta',
              amount: digitalWithoutAccount,
              icon: Icons.account_balance_wallet_outlined,
              valueKey: const ValueKey('home-unassigned-digital-balance'),
            ),
          ],
          if (data.balanceBreakdown.unclassified > 1e-8) ...[
            const SizedBox(height: 8),
            _BalanceMediumLine(
              label: 'Sin asignar a un medio',
              amount: data.balanceBreakdown.unclassified,
              icon: Icons.help_outline_rounded,
              valueKey: const ValueKey('home-unclassified-balance'),
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              key: const ValueKey('home-view-accounts'),
              onPressed: onViewSettings,
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: const Text('Administrar cuentas'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceMediumLine extends StatelessWidget {
  const _BalanceMediumLine({
    required this.label,
    required this.amount,
    this.icon,
    this.valueKey,
  });

  final String label;
  final double amount;
  final IconData? icon;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: AppColors.accent),
          const SizedBox(width: 8),
        ],
        Expanded(child: Text(label)),
        Text(_formatMoney(amount), key: valueKey),
      ],
    );
  }
}

class _DigitalAccountBalanceLine extends StatelessWidget {
  const _DigitalAccountBalanceLine({required this.account});

  final DigitalAccountBalance account;

  @override
  Widget build(BuildContext context) {
    final name = account.account.nombre;
    return Container(
      key: ValueKey('home-account-balance-${account.account.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(AppRadii.small),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
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
            child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Text(
            _formatMoney(account.balance),
            key: ValueKey('home-account-balance-value-${account.account.id}'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}

class _RecentActivityPanel extends StatelessWidget {
  const _RecentActivityPanel({
    required this.activities,
    required this.onViewIncomes,
    required this.onViewExpenses,
    required this.onViewSavings,
    required this.onViewSettings,
  });

  final List<DashboardActivity> activities;
  final VoidCallback? onViewIncomes;
  final VoidCallback? onViewExpenses;
  final VoidCallback? onViewSavings;
  final VoidCallback? onViewSettings;

  @override
  Widget build(BuildContext context) {
    return _DashboardPanel(
      child: Column(
        key: const ValueKey('home-future-expenses'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading('Actividad reciente'),
          const SizedBox(height: 12),
          if (activities.isEmpty)
            const _EmptyMessage('Tus movimientos aparecerán aquí.'),
          for (var index = 0; index < activities.length; index++) ...[
            if (index > 0) const Divider(height: 20),
            _ActivityRow(
              activity: activities[index],
              onTap: _destinationFor(activities[index].kind),
            ),
          ],
          if (activities.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: [
                TextButton(
                  key: const ValueKey('home-view-incomes'),
                  onPressed: onViewIncomes,
                  child: const Text('Ingresos'),
                ),
                TextButton(
                  key: const ValueKey('home-view-expenses'),
                  onPressed: onViewExpenses,
                  child: const Text('Gastos'),
                ),
                TextButton(
                  onPressed: onViewSettings,
                  child: const Text('Transferencias'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  VoidCallback? _destinationFor(DashboardActivityKind kind) {
    return switch (kind) {
      DashboardActivityKind.income => onViewIncomes,
      DashboardActivityKind.expense ||
      DashboardActivityKind.debtPayment => onViewExpenses,
      DashboardActivityKind.transfer => onViewSettings,
      DashboardActivityKind.savingsContribution ||
      DashboardActivityKind.savingsWithdrawal => onViewSavings,
    };
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity, required this.onTap});

  final DashboardActivity activity;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = _activityStyle(activity.kind);
    final amount = switch (activity.kind) {
      DashboardActivityKind.income || DashboardActivityKind.savingsWithdrawal =>
        '+${formatMoney(activity.amount)}',
      DashboardActivityKind.expense ||
      DashboardActivityKind.debtPayment ||
      DashboardActivityKind.savingsContribution =>
        '-${formatMoney(activity.amount)}',
      DashboardActivityKind.transfer => formatMoney(activity.amount),
    };

    return Semantics(
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.small),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(style.icon, color: style.color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      '${activity.detail} · ${_shortDate(activity.date)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                amount,
                textAlign: TextAlign.end,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: style.color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityStyle {
  const _ActivityStyle(this.icon, this.color);

  final IconData icon;
  final Color color;
}

_ActivityStyle _activityStyle(DashboardActivityKind kind) {
  return switch (kind) {
    DashboardActivityKind.income => const _ActivityStyle(
      Icons.south_west_rounded,
      AppColors.positive,
    ),
    DashboardActivityKind.expense => const _ActivityStyle(
      Icons.north_east_rounded,
      AppColors.negative,
    ),
    DashboardActivityKind.debtPayment => const _ActivityStyle(
      Icons.payments_outlined,
      AppColors.warning,
    ),
    DashboardActivityKind.transfer => const _ActivityStyle(
      Icons.swap_horiz_rounded,
      AppColors.primary,
    ),
    DashboardActivityKind.savingsContribution => const _ActivityStyle(
      Icons.savings_outlined,
      AppColors.accent,
    ),
    DashboardActivityKind.savingsWithdrawal => const _ActivityStyle(
      Icons.savings_outlined,
      AppColors.positive,
    ),
  };
}

class _RemindersPanel extends StatelessWidget {
  const _RemindersPanel({
    required this.data,
    required this.onViewFutureExpenses,
    required this.onViewSubscriptions,
    required this.onViewDebts,
  });

  final DashboardData data;
  final VoidCallback? onViewFutureExpenses;
  final VoidCallback? onViewSubscriptions;
  final VoidCallback? onViewDebts;

  @override
  Widget build(BuildContext context) {
    final subscriptions = data.subscriptions.take(3).toList();
    final debts = data.pagosProximos
        .where((payment) => payment.deuda.fechaProximoPago != null)
        .take(3)
        .toList();
    final plans = data.futureExpenses
        .where((item) => item.plan.status == FutureExpenseStatus.active)
        .take(3)
        .toList();
    final hasReminders =
        subscriptions.isNotEmpty || debts.isNotEmpty || plans.isNotEmpty;

    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading('Recordatorios'),
          const SizedBox(height: 12),
          if (!hasReminders)
            Row(
              children: [
                const AnimatedCat(
                  asset: CatAssets.vacio,
                  label: 'Gato descansando',
                  width: 52,
                  height: 46,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No tienes pagos o planes próximos.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          if (subscriptions.isNotEmpty) ...[
            _ReminderGroupTitle(
              buttonKey: const ValueKey('home-view-subscriptions'),
              title: 'Suscripciones',
              onTap: onViewSubscriptions,
            ),
            for (final subscription in subscriptions)
              _ReminderLine(
                icon: Icons.autorenew_rounded,
                title: subscription.nombre,
                detail:
                    'Próximo cobro · ${_shortDate(subscription.proximoPago)}',
                amount: subscription.precio,
              ),
          ],
          if (debts.isNotEmpty) ...[
            _ReminderGroupTitle(
              buttonKey: const ValueKey('home-view-debts'),
              title: 'Cuotas',
              onTap: onViewDebts,
            ),
            for (final payment in debts)
              _ReminderLine(
                icon: Icons.event_outlined,
                title: payment.deuda.nombre,
                detail: _formatDebtDate(payment.deuda.fechaProximoPago!),
                amount: payment.montoProximoPago,
              ),
          ],
          if (plans.isNotEmpty) ...[
            _ReminderGroupTitle(
              buttonKey: const ValueKey('home-future-expenses-see-all'),
              title: 'Gastos futuros planeados',
              onTap: onViewFutureExpenses,
              actionLabel: 'Ver todos',
            ),
            for (final plan in plans)
              _ReminderLine(
                icon: Icons.event_note_outlined,
                title: plan.plan.name,
                detail: 'Planeado · ${_shortDate(plan.plan.targetDate)}',
                amount: plan.plan.targetAmount,
              ),
          ],
        ],
      ),
    );
  }
}

class _ReminderGroupTitle extends StatelessWidget {
  const _ReminderGroupTitle({
    this.buttonKey,
    required this.title,
    required this.onTap,
    this.actionLabel = 'Ver',
  });

  final Key? buttonKey;
  final String title;
  final VoidCallback? onTap;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleSmall),
          ),
          TextButton(
            key: buttonKey,
            onPressed: onTap,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _ReminderLine extends StatelessWidget {
  const _ReminderLine({
    required this.icon,
    required this.title,
    required this.detail,
    required this.amount,
  });

  final IconData icon;
  final String title;
  final String detail;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(detail, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(formatMoney(amount)),
        ],
      ),
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

String _monthName(int month) {
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
  return months[month - 1];
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

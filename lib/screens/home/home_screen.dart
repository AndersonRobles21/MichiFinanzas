import 'dart:async';

import 'package:flutter/material.dart';

import '../../database/app_database.dart';
import '../../models/future_expense.dart';
import '../../models/income_type.dart';
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
  });

  final DatabaseService? databaseService;
  final bool isActive;
  final VoidCallback? onViewFutureExpenses;

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
    final draft = await showModalBottomSheet<_IncomeDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      builder: (context) => const _IncomeFormSheet(),
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
        );
      } else {
        await _databaseService.agregarIngreso(
          monto: draft.monto,
          fecha: draft.fecha,
          descripcion: draft.descripcion,
          tipo: draft.type.storageValue,
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

  Future<void> _editIncome(Ingreso income) async {
    final draft = await showModalBottomSheet<_IncomeDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      builder: (context) => _IncomeFormSheet(income: income),
    );
    if (draft == null || !mounted) return;
    try {
      await _databaseService.actualizarIngreso(
        id: income.id,
        monto: draft.monto,
        fecha: draft.fecha,
        descripcion: draft.descripcion,
        tipo: draft.type.storageValue,
      );
      if (!mounted) return;
      setState(() => _dashboardFuture = _loadDashboard(_databaseService));
      _showMessage('Ingreso actualizado.', isSuccess: true);
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
    }
  }

  Future<void> _deleteIncome(Ingreso income) async {
    final linkedDebt = IncomeType.fromStorage(income.tipo) == IncomeType.loan;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar este ingreso?'),
        content: Text(
          linkedDebt
              ? 'También se eliminarán la deuda vinculada y su historial de abonos. Esta acción no se puede deshacer.'
              : 'El registro se eliminará y el saldo se recalculará. Esta acción no se puede deshacer.',
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
    if (confirmed != true || !mounted) return;
    try {
      await _databaseService.eliminarIngreso(income.id);
      if (!mounted) return;
      setState(() => _dashboardFuture = _loadDashboard(_databaseService));
      _showMessage('Ingreso eliminado.', isSuccess: true);
    } catch (error, stackTrace) {
      logOperationFailure(error, stackTrace, operation: 'eliminar un ingreso');
      if (mounted) {
        _showMessage(
          friendlyOperationError(error, action: 'eliminar el ingreso'),
        );
      }
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
                          onEditIncome: _editIncome,
                          onDeleteIncome: _deleteIncome,
                          onDistributeBalance: _editDistribution,
                          isSavingDistribution: _isSavingDistribution,
                          onViewFutureExpenses: widget.onViewFutureExpenses,
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
    ]);

    return _DashboardData.fromRecords(
      ingresos: results[0] as List<Ingreso>,
      gastos: results[1] as List<Gasto>,
      deudas: results[2] as List<Deuda>,
      pagos: results[3] as List<PagosDeudaData>,
      futureExpenses: results[4] as List<FutureExpenseSummary>,
      balanceBreakdown: balanceBreakdown,
      userName: userName,
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
    required this.totalPagosDeuda,
    required this.dineroDisponible,
    required this.balanceBreakdown,
    required this.userName,
    required this.allIncomes,
    required this.porcentajeGastado,
    required this.cantidadIngresos,
    required this.cantidadGastos,
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
  }) {
    final totalIngresos = ingresos.fold<double>(
      0,
      (total, ingreso) => total + ingreso.monto,
    );
    final now = DateTime.now();
    final allIncomes = [...ingresos]
      ..sort((first, second) => second.fecha.compareTo(first.fecha));
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
      totalPagosDeuda: totalPagosDeuda,
      dineroDisponible: balanceBreakdown.total,
      balanceBreakdown: balanceBreakdown,
      userName: userName,
      allIncomes: allIncomes,
      porcentajeGastado: porcentajeGastado,
      cantidadIngresos: ingresos.length,
      cantidadGastos: gastos.length,
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
  final double totalPagosDeuda;
  final double dineroDisponible;
  final AvailableBalanceBreakdown balanceBreakdown;
  final String userName;
  final List<Ingreso> allIncomes;
  final double? porcentajeGastado;
  final int cantidadIngresos;
  final int cantidadGastos;
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
  });

  final IncomeType type;
  final String descripcion;
  final double monto;
  final DateTime fecha;
  final int? cuotasTotales;
  final DateTime? fechaPrimerPago;
}

class _IncomeFormSheet extends StatefulWidget {
  const _IncomeFormSheet({this.income});

  final Ingreso? income;

  @override
  State<_IncomeFormSheet> createState() => _IncomeFormSheetState();
}

class _IncomeFormSheetState extends State<_IncomeFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _installmentsController = TextEditingController(text: '1');
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
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _installmentsController.dispose();
    super.dispose();
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
    Navigator.pop(
      context,
      _IncomeDraft(
        type: _type,
        descripcion: _descriptionController.text.trim(),
        monto: parseMoney(_amountController.text),
        fecha: _receivedDate,
        cuotasTotales: _type == IncomeType.loan
            ? int.parse(_installmentsController.text.trim())
            : null,
        fechaPrimerPago: _type == IncomeType.loan ? _firstPaymentDate : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SingleChildScrollView(
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
                      if (widget.income == null) IncomeType.loan,
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
                      ? 'Cuéntanos de dónde viene este dinero.'
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
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _selectDate(isFirstPayment: false),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('Recibido · ${_shortDate(_receivedDate)}'),
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
                    onPressed: _save,
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
    );
  }
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
    if (cash + digital > widget.total + 1e-8) {
      setState(() {
        _error = 'La suma no puede superar el total disponible.';
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
                    'Puedes dejar una parte por distribuir y asignarla después.',
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
                      onPressed: _save,
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
    required this.onEditIncome,
    required this.onDeleteIncome,
    required this.onDistributeBalance,
    required this.isSavingDistribution,
    required this.onViewFutureExpenses,
  });

  final _DashboardData data;
  final VoidCallback onAddIncome;
  final bool isSavingIncome;
  final ValueChanged<Ingreso> onEditIncome;
  final ValueChanged<Ingreso> onDeleteIncome;
  final VoidCallback onDistributeBalance;
  final bool isSavingDistribution;
  final VoidCallback? onViewFutureExpenses;

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
        const SizedBox(height: 18),
        _IncomeSummaryPanel(
          data: data,
          onAddIncome: onAddIncome,
          isSavingIncome: isSavingIncome,
          onEditIncome: onEditIncome,
          onDeleteIncome: onDeleteIncome,
        ),
        const SizedBox(height: 18),
        _MetricsGrid(data: data),
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
    required this.onEditIncome,
    required this.onDeleteIncome,
  });

  final _DashboardData data;
  final VoidCallback onAddIncome;
  final bool isSavingIncome;
  final ValueChanged<Ingreso> onEditIncome;
  final ValueChanged<Ingreso> onDeleteIncome;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outline),
      ),
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
              if (constraints.maxWidth < 420) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [total, const SizedBox(height: 12), addButton],
                );
              }
              return Row(
                children: [
                  Expanded(child: total),
                  addButton,
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
          if (data.allIncomes.isNotEmpty) ...[
            const Divider(height: 24),
            Text(
              'Historial de ingresos',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            for (final income in data.allIncomes)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    Icon(
                      IncomeType.fromStorage(income.tipo) == IncomeType.loan
                          ? Icons.account_balance_outlined
                          : Icons.south_west_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            income.descripcion?.trim().isNotEmpty == true
                                ? income.descripcion!
                                : IncomeType.fromStorage(income.tipo).label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${IncomeType.fromStorage(income.tipo).label} · '
                            '${_shortDate(income.fecha)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatMoney(income.monto),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    PopupMenuButton<_IncomeAction>(
                      tooltip: 'Acciones del ingreso',
                      onSelected: (action) {
                        if (action == _IncomeAction.edit) {
                          onEditIncome(income);
                        } else {
                          onDeleteIncome(income);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: _IncomeAction.edit,
                          child: Text('Editar'),
                        ),
                        PopupMenuItem(
                          value: _IncomeAction.delete,
                          child: Text('Eliminar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
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

enum _IncomeAction { edit, delete }

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
    final description = data.cantidadIngresos == 0
        ? 'Todavía no hay ingresos por aquí.'
        : 'Ingresos menos gastos, pagos, ahorros y reservas reales.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceRaised, AppColors.surface],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outline),
      ),
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
            label: 'Por distribuir',
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

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.data});

  final _DashboardData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth >= 680
            ? (constraints.maxWidth - 24) / 3
            : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: cardWidth,
              child: _DashboardMetric(
                icon: Icons.south_west_rounded,
                title: 'Total de ingresos',
                value: data.cantidadIngresos > 0
                    ? _formatMoney(data.totalIngresos)
                    : '—',
                detail: data.cantidadIngresos > 0
                    ? _recordCount(data.cantidadIngresos, 'ingreso', 'ingresos')
                    : 'Todavía no hay ingresos por aquí.',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _DashboardMetric(
                icon: Icons.north_east_rounded,
                title: 'Total de gastos',
                value: data.cantidadGastos > 0
                    ? _formatMoney(data.totalGastos)
                    : '—',
                detail: data.cantidadGastos > 0
                    ? _recordCount(data.cantidadGastos, 'gasto', 'gastos')
                    : 'Todavía no hay gastos por aquí. ¡Ojalá siga así un buen rato!',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _DashboardMetric(
                icon: Icons.pie_chart_outline_rounded,
                title: 'Gastado de ingresos',
                value: data.porcentajeGastado == null
                    ? '—'
                    : '${_formatPercent(data.porcentajeGastado!)}%',
                detail: data.porcentajeGastado == null
                    ? 'Agrega ingresos para ver este porcentaje.'
                    : 'Incluye gastos y pagos de deuda.',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DashboardMetric extends StatelessWidget {
  const _DashboardMetric({
    required this.icon,
    required this.title,
    required this.value,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontSize: 21),
          ),
          const SizedBox(height: 6),
          Text(detail, style: Theme.of(context).textTheme.bodyMedium),
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
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outline),
      ),
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
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outline),
      ),
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

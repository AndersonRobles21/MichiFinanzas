import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../database/app_database.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/money_format.dart';
import '../../utils/user_messages.dart';
import '../../widgets/cat_illustration.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key, this.isActive = true, this.databaseService});

  final bool isActive;
  final DatabaseService? databaseService;

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  late final DatabaseService _databaseService;
  late final bool _ownsDatabaseService;
  Future<_DebtDashboardData>? _debtsFuture;
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    _ownsDatabaseService = widget.databaseService == null;
    _databaseService = widget.databaseService ?? DatabaseService(AppDatabase());
    if (widget.isActive) _debtsFuture = _loadDebts();
  }

  @override
  void didUpdateWidget(covariant DebtsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _debtsFuture = _loadDebts();
    }
  }

  Future<_DebtDashboardData> _loadDebts() async {
    return runWithLoggedErrors(
      'cargar deudas',
      () => _readDebtData(_databaseService),
    );
  }

  @override
  void dispose() {
    if (_ownsDatabaseService) unawaited(_databaseService.close());
    super.dispose();
  }

  Future<void> _addDebt() async {
    final draft = await showModalBottomSheet<_DebtDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      builder: (context) => const _DebtFormSheet(),
    );
    if (draft == null || !mounted) return;

    try {
      await _databaseService.agregarDeuda(
        nombre: draft.nombre,
        montoOriginal: draft.montoOriginal,
        cuota: draft.cuota,
        cuotasTotales: draft.cuotasTotales,
        cuotasPagadas: draft.cuotasPagadas,
        fechaProximoPago: draft.fechaProximoPago,
      );
      final data = await _readDebtData(_databaseService);
      if (!mounted) return;
      setState(() {
        _debtsFuture = Future.value(data);
      });
      _showMessage('¡Listo! La deuda quedó guardada.', isSuccess: true);
    } catch (error, stackTrace) {
      logOperationFailure(error, stackTrace, operation: 'guardar una deuda');
      if (mounted) {
        _showMessage(friendlyOperationError(error, action: 'guardar la deuda'));
      }
    }
  }

  Future<void> _registerPayment(_DebtEntry entry) async {
    if (_isProcessingPayment || entry.saldoRestante <= 0) return;

    final draft = await showModalBottomSheet<_PaymentDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      builder: (context) => _PaymentFormSheet(
        debtName: entry.deuda.nombre,
        remainingBalance: entry.saldoRestante,
        installment: entry.deuda.cuota,
      ),
    );
    if (draft == null || !mounted || _isProcessingPayment) return;

    setState(() => _isProcessingPayment = true);
    try {
      final saved = await showDialog<bool>(
        context: context,
        builder: (context) => _PaymentReviewDialog(
          debtName: entry.deuda.nombre,
          draft: draft,
          onSave: () => _databaseService.registrarPagoDeuda(
            deudaId: entry.deuda.id,
            monto: draft.monto,
            fecha: draft.fecha,
            operationId: draft.operationId,
          ),
        ),
      );
      if (saved != true || !mounted) return;
      final data = await _readDebtData(_databaseService);
      if (!mounted) return;
      setState(() {
        _debtsFuture = Future.value(data);
      });
      _showMessage(
        'Abono guardado. El saldo ya está actualizado.',
        isSuccess: true,
      );
    } catch (error, stackTrace) {
      logOperationFailure(error, stackTrace, operation: 'registrar un abono');
      if (mounted) {
        _showMessage(
          friendlyOperationError(error, action: 'registrar el abono'),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingPayment = false);
    }
  }

  Future<void> _showPaymentHistory(_DebtEntry entry) async {
    final payments = [...entry.pagos]
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      builder: (context) => _PaymentHistorySheet(
        debtName: entry.deuda.nombre,
        payments: payments,
      ),
    );
  }

  Future<void> _reviewLegacyInstallments(_DebtEntry entry) async {
    final action = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dato histórico de cuotas'),
        content: Text(
          'El registro conserva ${entry.cuotasDeclaradas} cuotas indicadas '
          'como pagadas, pero los movimientos registrados respaldan '
          '${entry.cuotasPagadas}. No se sumó ningún pago ni se descontó '
          'dinero por ese dato. Puedes conservarlo como referencia o '
          'registrar únicamente un abono real.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Conservar referencia'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Registrar abono real'),
          ),
        ],
      ),
    );
    if (!mounted || action == null) return;
    if (action) {
      await _databaseService.confirmarRevisionCuotasLegadas(entry.deuda.id);
      final data = await _readDebtData(_databaseService);
      if (!mounted) return;
      setState(() {
        _debtsFuture = Future.value(data);
      });
      _showMessage('Referencia guardada para tenerla presente.');
    } else {
      await _registerPayment(entry);
    }
  }

  Future<void> _deleteDebt(_DebtEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Borrar esta deuda?'),
        content: Text(
          'Se borrará "${entry.deuda.nombre}" junto con el historial '
          'de ${entry.pagos.length} ${entry.pagos.length == 1 ? 'abono' : 'abonos'}. '
          'No podrás deshacerlo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Conservar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Borrar deuda'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _databaseService.eliminarDeuda(entry.deuda.id);
      final data = await _readDebtData(_databaseService);
      if (!mounted) return;
      setState(() {
        _debtsFuture = Future.value(data);
      });
      _showMessage('Deuda borrada junto con su historial.');
    } catch (error, stackTrace) {
      logOperationFailure(error, stackTrace, operation: 'borrar una deuda');
      if (mounted) {
        _showMessage(friendlyOperationError(error, action: 'borrar la deuda'));
      }
    }
  }

  void _retry() {
    setState(() {
      _debtsFuture = _loadDebts();
    });
  }

  void _showMessage(String message, {bool isSuccess = false}) {
    showCatMessage(context, message, isSuccess: isSuccess);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDebt,
        tooltip: 'Registrar deuda',
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva deuda'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 420 ? 20.0 : 36.0;
            return FutureBuilder<_DebtDashboardData>(
              future: _debtsFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _DebtError(onRetry: _retry);
                }
                if (!snapshot.hasData) {
                  return const _DebtLoading();
                }

                final debts = [...snapshot.data!.deudas]
                  ..sort(_compareDebtEntries);
                final outstandingTotal = debts.fold<double>(
                  0,
                  (total, entry) => total + entry.saldoRestante,
                );
                final pendingCount = debts
                    .where((entry) => !entry.estaPagada)
                    .length;

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
                          Text(
                            'Deudas',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Controla tus cuotas, abonos y saldos pendientes.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          if (debts.isNotEmpty) ...[
                            const SizedBox(height: 22),
                            _DebtOverview(
                              count: debts.length,
                              pendingCount: pendingCount,
                              outstandingTotal: outstandingTotal,
                            ),
                          ],
                          const SizedBox(height: 26),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Tus deudas',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              Text(
                                '${debts.length}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (debts.isEmpty)
                            const _DebtEmpty()
                          else
                            ...debts.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _DebtCard(
                                  entry: entry,
                                  isProcessingPayment: _isProcessingPayment,
                                  onRegisterPayment: () =>
                                      _registerPayment(entry),
                                  onReviewLegacy: () =>
                                      _reviewLegacyInstallments(entry),
                                  onShowHistory: () =>
                                      _showPaymentHistory(entry),
                                  onDelete: () => _deleteDebt(entry),
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

Future<_DebtDashboardData> _readDebtData(DatabaseService service) async {
  final debts = await service.obtenerDeudas();
  final payments = await service.obtenerTodosLosPagosDeuda();
  return _DebtDashboardData.fromRecords(debts, payments);
}

int _compareDebtEntries(_DebtEntry first, _DebtEntry second) {
  if (first.estaPagada != second.estaPagada) {
    return first.estaPagada ? 1 : -1;
  }
  final firstDue = first.deuda.fechaProximoPago ?? DateTime(9999);
  final secondDue = second.deuda.fechaProximoPago ?? DateTime(9999);
  return firstDue.compareTo(secondDue);
}

class _DebtDashboardData {
  const _DebtDashboardData(this.deudas);

  factory _DebtDashboardData.fromRecords(
    List<Deuda> debts,
    List<PagosDeudaData> payments,
  ) {
    final paymentsByDebt = <int, List<PagosDeudaData>>{};
    for (final payment in payments) {
      paymentsByDebt.putIfAbsent(payment.deudaId, () => []).add(payment);
    }
    return _DebtDashboardData([
      for (final debt in debts)
        _DebtEntry(debt, paymentsByDebt[debt.id] ?? const []),
    ]);
  }

  final List<_DebtEntry> deudas;
}

class _DebtEntry {
  _DebtEntry(this.deuda, this.pagos)
    : totalAbonado = pagos.fold<double>(
        0,
        (total, payment) => total + payment.monto,
      ),
      cuotasPagadas = _countCompletedInstallments(
        deuda,
        pagos.fold<double>(0, (total, payment) => total + payment.monto),
      ),
      saldoRestante =
          (deuda.montoOriginal -
                  pagos.fold<double>(
                    0,
                    (total, payment) => total + payment.monto,
                  ))
              .clamp(0.0, double.infinity);

  int get cuotasDeclaradas =>
      deuda.cuotasPagadasDeclaradas.clamp(0, deuda.cuotasTotales);

  bool get tieneDiscrepanciaLegada =>
      cuotasDeclaradas != cuotasPagadas && !deuda.cuotasLegadasRevisadas;

  bool get referenciaLegadaRevisada => deuda.cuotasLegadasRevisadas;

  final Deuda deuda;
  final List<PagosDeudaData> pagos;
  final double totalAbonado;
  final int cuotasPagadas;
  final double saldoRestante;

  bool get estaPagada => saldoRestante <= 1e-8;

  int get cuotasPendientes => deuda.cuotasTotales - cuotasPagadas;

  double get progreso => deuda.cuotasTotales <= 0
      ? 0
      : (cuotasPagadas / deuda.cuotasTotales).clamp(0.0, 1.0);
}

class _DebtDraft {
  const _DebtDraft({
    required this.nombre,
    required this.montoOriginal,
    required this.cuota,
    required this.cuotasTotales,
    required this.cuotasPagadas,
    required this.fechaProximoPago,
  });

  final String nombre;
  final double montoOriginal;
  final double cuota;
  final int cuotasTotales;
  final int cuotasPagadas;
  final DateTime? fechaProximoPago;
}

class _PaymentDraft {
  const _PaymentDraft({
    required this.monto,
    required this.fecha,
    required this.operationId,
  });

  final double monto;
  final DateTime fecha;
  final String operationId;
}

int _countCompletedInstallments(Deuda debt, double totalPaid) {
  if (!debt.cuota.isFinite || debt.cuota <= 0 || debt.cuotasTotales <= 0) {
    return 0;
  }
  if (debt.montoOriginal - totalPaid <= 1e-8) return debt.cuotasTotales;
  return ((totalPaid + 1e-8) / debt.cuota).floor().clamp(0, debt.cuotasTotales);
}

String _newPaymentOperationId() {
  final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
  final random = Random.secure().nextInt(0x100000000).toRadixString(16);
  return '$timestamp-$random';
}

class _DebtFormSheet extends StatefulWidget {
  const _DebtFormSheet();

  @override
  State<_DebtFormSheet> createState() => _DebtFormSheetState();
}

class _DebtFormSheetState extends State<_DebtFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _installmentController = TextEditingController();
  final _totalInstallmentsController = TextEditingController();
  final _paidInstallmentsController = TextEditingController(text: '0');
  DateTime? _nextPaymentDate;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _installmentController.dispose();
    _totalInstallmentsController.dispose();
    _paidInstallmentsController.dispose();
    super.dispose();
  }

  Future<void> _selectNextPaymentDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _nextPaymentDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _nextPaymentDate = date);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _DebtDraft(
        nombre: _nameController.text.trim(),
        montoOriginal: _parseAmount(_amountController.text),
        cuota: _parseAmount(_installmentController.text),
        cuotasTotales: int.parse(_totalInstallmentsController.text.trim()),
        cuotasPagadas: int.parse(_paidInstallmentsController.text.trim()),
        fechaProximoPago: _nextPaymentDate,
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
                Text(
                  'Registrar deuda',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  key: const ValueKey('debt-name'),
                  controller: _nameController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Nombre o descripción',
                    prefixIcon: Icon(Icons.edit_outlined),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Escribe un nombre para la deuda.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('debt-amount'),
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: const [ThousandsInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Monto original',
                    prefixText: '\$ ',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  validator: (value) => _validatePositiveAmount(
                    value,
                    'Escribe un monto mayor que cero.',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('debt-installment'),
                  controller: _installmentController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: const [ThousandsInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Valor de la cuota',
                    prefixText: '\$ ',
                    prefixIcon: Icon(Icons.event_repeat_outlined),
                  ),
                  validator: (value) => _validatePositiveAmount(
                    value,
                    'Escribe una cuota mayor que cero.',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('debt-installments-total'),
                  controller: _totalInstallmentsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Número total de cuotas',
                    prefixIcon: Icon(Icons.format_list_numbered_rounded),
                  ),
                  validator: (value) {
                    final total = int.tryParse((value ?? '').trim());
                    if (total == null || total <= 0) {
                      return 'Indica cuántas cuotas son.';
                    }
                    final paid = int.tryParse(
                      _paidInstallmentsController.text.trim(),
                    );
                    if (paid != null && paid > total) {
                      return 'No pueden estar pagadas más cuotas de las que hay.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('debt-installments-paid'),
                  controller: _paidInstallmentsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cuotas indicadas como pagadas',
                    prefixIcon: Icon(Icons.check_circle_outline_rounded),
                  ),
                  validator: (value) {
                    final paid = int.tryParse((value ?? '').trim());
                    if (paid == null || paid < 0) {
                      return 'Indica cero o más cuotas pagadas.';
                    }
                    final total = int.tryParse(
                      _totalInstallmentsController.text.trim(),
                    );
                    if (total != null && paid > total) {
                      return 'No pueden estar pagadas más cuotas de las que hay.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  'Se conservará como referencia histórica. El total pagado, '
                  'las cuotas y el saldo se calcularán solo con abonos reales.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  children: [
                    TextButton.icon(
                      onPressed: _selectNextPaymentDate,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(
                        _nextPaymentDate == null
                            ? 'Próximo pago (opcional)'
                            : 'Próximo pago: ${_formatDate(_nextPaymentDate!)}',
                      ),
                    ),
                    if (_nextPaymentDate != null)
                      IconButton(
                        tooltip: 'Quitar fecha',
                        onPressed: () =>
                            setState(() => _nextPaymentDate = null),
                        icon: const Icon(Icons.close_rounded),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Guardar deuda'),
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

class _PaymentFormSheet extends StatefulWidget {
  const _PaymentFormSheet({
    required this.debtName,
    required this.remainingBalance,
    required this.installment,
  });

  final String debtName;
  final double remainingBalance;
  final double installment;

  @override
  State<_PaymentFormSheet> createState() => _PaymentFormSheetState();
}

class _PaymentFormSheetState extends State<_PaymentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  late final double _installmentSuggestion = widget.installment.clamp(
    0.0,
    widget.remainingBalance,
  );
  _PaymentAmountOption _selectedOption = _PaymentAmountOption.installment;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _amountController.text = formatAmount(_installmentSuggestion);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _date = date);
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _PaymentDraft(
        monto: _parseAmount(_amountController.text),
        fecha: _date,
        operationId: _newPaymentOperationId(),
      ),
    );
  }

  void _selectAmount(_PaymentAmountOption option) {
    setState(() {
      _selectedOption = option;
      _amountController.text = switch (option) {
        _PaymentAmountOption.installment => formatAmount(
          _installmentSuggestion,
        ),
        _PaymentAmountOption.payAll => formatAmount(widget.remainingBalance),
        _PaymentAmountOption.custom => '',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(22, 22, 22, 24 + bottomInset),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Registrar abono',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  widget.debtName,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Saldo: ${_formatMoney(widget.remainingBalance)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Pagar cuota'),
                      selected:
                          _selectedOption == _PaymentAmountOption.installment,
                      onSelected: (_) =>
                          _selectAmount(_PaymentAmountOption.installment),
                    ),
                    ChoiceChip(
                      label: const Text('Pagar todo'),
                      selected: _selectedOption == _PaymentAmountOption.payAll,
                      onSelected: (_) =>
                          _selectAmount(_PaymentAmountOption.payAll),
                    ),
                    ChoiceChip(
                      label: const Text('Abonar otro valor'),
                      selected: _selectedOption == _PaymentAmountOption.custom,
                      onSelected: (_) =>
                          _selectAmount(_PaymentAmountOption.custom),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('debt-payment-amount'),
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: const [ThousandsInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Monto del abono',
                    prefixText: '\$ ',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  validator: (value) {
                    final amount = _tryParseAmount(value);
                    if (amount == null || amount <= 0) {
                      return 'Escribe un abono mayor que cero.';
                    }
                    if (amount > widget.remainingBalance) {
                      return 'Ese abono supera lo que todavía debes.';
                    }
                    return null;
                  },
                  onChanged: (_) {
                    if (_selectedOption != _PaymentAmountOption.custom) {
                      setState(
                        () => _selectedOption = _PaymentAmountOption.custom,
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text('Fecha del abono: ${_formatDate(_date)}'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _continue,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Revisar abono'),
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

enum _PaymentAmountOption { installment, payAll, custom }

class _PaymentReviewDialog extends StatefulWidget {
  const _PaymentReviewDialog({
    required this.debtName,
    required this.draft,
    required this.onSave,
  });

  final String debtName;
  final _PaymentDraft draft;
  final Future<int> Function() onSave;

  @override
  State<_PaymentReviewDialog> createState() => _PaymentReviewDialogState();
}

class _PaymentReviewDialogState extends State<_PaymentReviewDialog> {
  bool _isSaving = false;
  String? _error;

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await widget.onSave();
      if (mounted) Navigator.pop(context, true);
    } catch (error, stackTrace) {
      logOperationFailure(error, stackTrace, operation: 'guardar un abono');
      if (mounted) {
        setState(
          () => _error = friendlyOperationError(
            error,
            action: 'guardar el abono',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Revisar abono'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Deuda: ${widget.debtName}'),
          const SizedBox(height: 6),
          Text('Monto: ${_formatMoney(widget.draft.monto)}'),
          Text('Fecha: ${_formatDate(widget.draft.fecha)}'),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}

class _DebtOverview extends StatelessWidget {
  const _DebtOverview({
    required this.count,
    required this.pendingCount,
    required this.outstandingTotal,
  });

  final int count;
  final int pendingCount;
  final double outstandingTotal;

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
          final items = [
            _OverviewValue(label: 'Deudas', value: '$count'),
            _OverviewValue(label: 'Pendientes', value: '$pendingCount'),
            _OverviewValue(
              label: 'Saldo por pagar',
              value: _formatMoney(outstandingTotal),
            ),
          ];
          if (constraints.maxWidth < 500) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  if (index > 0) const SizedBox(height: 14),
                  items[index],
                ],
              ],
            );
          }
          return Row(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                if (index > 0) const SizedBox(width: 20),
                Expanded(child: items[index]),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _OverviewValue extends StatelessWidget {
  const _OverviewValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }
}

class _DebtCard extends StatelessWidget {
  const _DebtCard({
    required this.entry,
    required this.isProcessingPayment,
    required this.onRegisterPayment,
    required this.onReviewLegacy,
    required this.onShowHistory,
    required this.onDelete,
  });

  final _DebtEntry entry;
  final bool isProcessingPayment;
  final VoidCallback onRegisterPayment;
  final VoidCallback onReviewLegacy;
  final VoidCallback onShowHistory;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final debt = entry.deuda;
    final isPaid = entry.estaPagada;
    return Container(
      key: ValueKey('debt-${debt.id}'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPaid
              ? AppColors.accent.withValues(alpha: 0.55)
              : AppColors.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Text(
                  debt.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              _DebtStatus(isPaid: isPaid),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _DebtValue(
                label: 'Monto original',
                value: _formatMoney(debt.montoOriginal),
              ),
              _DebtValue(label: 'Cuota', value: _formatMoney(debt.cuota)),
              _DebtValue(
                label: 'Cuotas',
                value: '${entry.cuotasPagadas}/${debt.cuotasTotales}',
              ),
              _DebtValue(
                label: 'Total pagado',
                value: _formatMoney(entry.totalAbonado),
              ),
              _DebtValue(
                label: 'Pendientes',
                value: '${entry.cuotasPendientes}',
              ),
              _DebtValue(
                label: 'Saldo restante',
                value: _formatMoney(entry.saldoRestante),
                emphasize: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              key: ValueKey('debt-progress-${debt.id}'),
              value: entry.progreso,
              minHeight: 7,
              backgroundColor: AppColors.surfaceRaised,
              valueColor: AlwaysStoppedAnimation(
                isPaid ? AppColors.accent : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(entry.progreso * 100).round()}% de cuotas completadas',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (entry.cuotasDeclaradas > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Referencia anterior: ${entry.cuotasDeclaradas} cuotas indicadas; '
              'el cálculo usa solo abonos del historial.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          if (entry.tieneDiscrepanciaLegada) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onReviewLegacy,
              icon: const Icon(Icons.history_rounded),
              label: const Text('Revisar dato histórico'),
            ),
          ],
          if (debt.fechaProximoPago != null) ...[
            const SizedBox(height: 8),
            Text(
              'Próximo pago: ${_formatDate(debt.fechaProximoPago!)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!isPaid)
                FilledButton.tonalIcon(
                  onPressed: isProcessingPayment ? null : onRegisterPayment,
                  icon: isProcessingPayment
                      ? const Icon(Icons.hourglass_top_rounded)
                      : const Icon(Icons.add_card_rounded),
                  label: const Text('Registrar abono'),
                ),
              OutlinedButton.icon(
                onPressed: onShowHistory,
                icon: const Icon(Icons.receipt_long_outlined),
                label: Text('Historial (${entry.pagos.length})'),
              ),
              IconButton(
                key: ValueKey('debt-delete-${debt.id}'),
                tooltip: 'Eliminar deuda',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DebtStatus extends StatelessWidget {
  const _DebtStatus({required this.isPaid});

  final bool isPaid;

  @override
  Widget build(BuildContext context) {
    final color = isPaid ? AppColors.accent : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isPaid ? 'Pagada' : 'Pendiente',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
      ),
    );
  }
}

class _DebtValue extends StatelessWidget {
  const _DebtValue({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 95, maxWidth: 220),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: emphasize ? AppColors.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentHistorySheet extends StatelessWidget {
  const _PaymentHistorySheet({required this.debtName, required this.payments});

  final String debtName;
  final List<PagosDeudaData> payments;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.72;
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Historial de pagos',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar historial',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(debtName, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 14),
            Expanded(
              child: payments.isEmpty
                  ? Center(
                      child: Text(
                        'Todavía no hay abonos por aquí.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : ListView.separated(
                      itemCount: payments.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final payment = payments[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.payments_outlined,
                            color: AppColors.primary,
                          ),
                          title: Text(_formatMoney(payment.monto)),
                          subtitle: Text(_formatDate(payment.fecha)),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DebtEmpty extends StatelessWidget {
  const _DebtEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AnimatedCat(
              asset: CatAssets.vacio,
              label: 'Gato descansando, sin deudas registradas',
              width: 150,
              height: 112,
            ),
            const SizedBox(height: 14),
            Text(
              'Todavía no hay deudas por aquí.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Tus compras a crédito y préstamos aparecerán aquí.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _DebtLoading extends StatelessWidget {
  const _DebtLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Estamos cargando tus deudas...',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _DebtError extends StatelessWidget {
  const _DebtError({required this.onRetry});

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
              'Ups, tus deudas no cargaron esta vez.',
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

String? _validatePositiveAmount(String? value, String errorMessage) {
  final amount = _tryParseAmount(value);
  return amount == null || amount <= 0 ? errorMessage : null;
}

double _parseAmount(String value) => parseMoney(value);

double? _tryParseAmount(String? value) => tryParseMoney(value);

String _formatMoney(double amount) {
  return formatMoney(amount);
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

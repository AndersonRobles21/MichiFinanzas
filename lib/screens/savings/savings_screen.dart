import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../database/app_database.dart';
import '../../models/money_medium.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_format.dart';
import '../../utils/money_format.dart';
import '../../utils/user_messages.dart';
import '../../widgets/app_page_header.dart';
import '../../widgets/cat_illustration.dart';
import '../../widgets/money_medium_selector.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key, this.isActive = true, this.databaseService});

  final bool isActive;
  final DatabaseService? databaseService;

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  late final DatabaseService _databaseService;
  late final bool _ownsDatabaseService;
  late final StreamSubscription<void> _financialChanges;
  late Future<_SavingsData> _dataFuture;
  bool _isSaving = false;
  int _savingsBounceTrigger = 0;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _ownsDatabaseService = widget.databaseService == null;
    _databaseService = widget.databaseService ?? DatabaseService(AppDatabase());
    _dataFuture = _loadData();
    _financialChanges = _databaseService.observarCambiosFinancieros().listen((
      _,
    ) {
      if (mounted) {
        setState(() {
          _dataFuture = _loadData();
          _savingsBounceTrigger++;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant SavingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      setState(() {
        _dataFuture = _loadData();
      });
    }
  }

  Future<_SavingsData> _loadData() async {
    return runWithLoggedErrors('cargar ahorros y préstamos', () async {
      final values = await Future.wait<Object>([
        _databaseService.obtenerMovimientosAhorro(),
        _databaseService.obtenerTotalAhorros(),
        _databaseService.obtenerSaldoDisponible(),
        _databaseService.obtenerPrestamosTerceros(),
        _databaseService.obtenerMovimientosPrestamo(),
      ]);
      final loans = values[3] as List<PrestamosTercero>;
      final loanMovements = values[4] as List<MovimientosPrestamoData>;
      return _SavingsData(
        movements: values[0] as List<MovimientosAhorroData>,
        total: values[1] as double,
        available: values[2] as double,
        loans: [
          for (final loan in loans)
            _ThirdPartyLoan(
              loan,
              loanMovements
                  .where((movement) => movement.prestamoId == loan.id)
                  .toList(),
            ),
        ],
      );
    });
  }

  Future<void> _moveMoney({required bool isWithdrawal}) async {
    if (_isSaving) return;
    final data = await _dataFuture;
    if (!mounted) return;
    final result =
        await showModalBottomSheet<({double amount, MoneyMedium medium})>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: AppColors.surface,
          builder: (context) => _SavingsAmountSheet(
            isWithdrawal: isWithdrawal,
            limit: isWithdrawal ? data.total : data.available,
          ),
        );
    if (result == null || !mounted || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      if (isWithdrawal) {
        await _databaseService.retirarAhorro(
          monto: result.amount,
          fecha: DateTime.now(),
          medio: result.medium,
        );
      } else {
        await _databaseService.registrarAporteAhorro(
          monto: result.amount,
          fecha: DateTime.now(),
          medio: result.medium,
        );
      }
      if (!mounted) return;
      setState(() {
        _dataFuture = _loadData();
      });
      _showMessage(
        isWithdrawal
            ? 'Retiro listo. El saldo ya está actualizado.'
            : 'Aporte guardado. ¡Buen trabajo!',
        isSuccess: true,
      );
    } catch (error, stackTrace) {
      logOperationFailure(
        error,
        stackTrace,
        operation: isWithdrawal ? 'retirar ahorros' : 'guardar un aporte',
      );
      if (mounted) {
        _showMessage(
          friendlyOperationError(
            error,
            action: isWithdrawal ? 'completar el retiro' : 'guardar el aporte',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _registerLoan() async {
    if (_isSaving) return;
    final data = await _dataFuture;
    if (!mounted) return;
    final draft = await showDialog<_LoanDraft>(
      context: context,
      builder: (context) =>
          Dialog(child: _LoanFormSheet(available: data.available)),
    );
    if (draft == null || !mounted || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => _LoanReviewDialog(
          draft: draft,
          onConfirm: () => _databaseService.registrarPrestamoTercero(
            persona: draft.person,
            monto: draft.amount,
            fechaEntrega: draft.deliveryDate,
            fechaDevolucionAcordada: draft.dueDate,
            operationId: draft.operationId,
            medio: draft.medium,
          ),
        ),
      );
      if (confirmed != true || !mounted) return;
      if (!mounted) return;
      setState(() {
        _dataFuture = _loadData();
      });
      _showMessage('¡Listo! El préstamo quedó registrado.', isSuccess: true);
    } catch (error, stackTrace) {
      logOperationFailure(
        error,
        stackTrace,
        operation: 'registrar un préstamo',
      );
      if (mounted) {
        _showMessage(
          friendlyOperationError(error, action: 'registrar el préstamo'),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _returnLoan(_ThirdPartyLoan loan) async {
    if (_isSaving || loan.remaining <= 0) return;
    final draft = await showDialog<_ReturnDraft>(
      context: context,
      builder: (context) => Dialog(
        child: _LoanReturnSheet(
          person: loan.loan.persona,
          remaining: loan.remaining,
        ),
      ),
    );
    if (draft == null || !mounted || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      await _databaseService.registrarDevolucionPrestamo(
        prestamoId: loan.loan.id,
        monto: draft.amount,
        fecha: draft.date,
        operationId: draft.operationId,
        medio: draft.medium,
      );
      if (!mounted) return;
      setState(() {
        _dataFuture = _loadData();
      });
      _showMessage(
        'Devolución guardada. El saldo ya está actualizado.',
        isSuccess: true,
      );
    } catch (error, stackTrace) {
      logOperationFailure(
        error,
        stackTrace,
        operation: 'registrar una devolución',
      );
      if (mounted) {
        _showMessage(
          friendlyOperationError(error, action: 'registrar la devolución'),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message, {bool isSuccess = false}) {
    showCatMessage(context, message, isSuccess: isSuccess);
  }

  @override
  void dispose() {
    unawaited(_financialChanges.cancel());
    if (_ownsDatabaseService) unawaited(_databaseService.close());
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
          return FutureBuilder<_SavingsData>(
            future: _dataFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.pets_rounded, size: 36),
                      const SizedBox(height: 12),
                      const Text('Ups, tus ahorros no cargaron esta vez.'),
                      TextButton(
                        onPressed: () => setState(() {
                          _dataFuture = _loadData();
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
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  AppSpacing.pageTop,
                  horizontalPadding,
                  36,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppPageHeader(
                          title: 'Ahorros y préstamos',
                          subtitle: '',
                        ),
                        const SizedBox(height: 18),
                        _SavingsTabSelector(
                          selected: _selectedTab,
                          onChanged: (index) =>
                              setState(() => _selectedTab = index),
                        ),
                        const SizedBox(height: 14),
                        if (_selectedTab == 0) ...[
                          _SavingsBalancePanel(
                            total: data.total,
                            isSaving: _isSaving,
                            bounceTrigger: _savingsBounceTrigger,
                            onContribute: () =>
                                _moveMoney(isWithdrawal: false),
                            onWithdraw: () => _moveMoney(isWithdrawal: true),
                          ),
                          const SizedBox(height: 14),
                          _SavingsNote(
                            text:
                                'Separar y retirar son movimientos internos: no cuentan como ingresos ni gastos. Tu ahorro no se suma al dinero disponible.',
                          ),
                          const SizedBox(height: 20),
                          _SectionHeading(
                            title: 'Tu historial',
                            count: data.movements.length,
                          ),
                          const SizedBox(height: 8),
                          if (data.movements.isEmpty)
                            _SavingsEmpty(
                              onAdd: () => _moveMoney(isWithdrawal: false),
                            )
                          else
                            _SavingsMovementList(movements: data.movements),
                        ] else ...[
                          _ThirdPartyLoanSummary(loans: data.loans),
                          const SizedBox(height: 14),
                          _SavingsNote(
                            text:
                                'Es dinero que le prestaste a otras personas. No es tu ahorro ni una deuda tuya.',
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _SectionHeading(
                                  title: 'Préstamos',
                                  count: data.loans.length,
                                ),
                              ),
                              FilledButton.icon(
                                key: const ValueKey('third-party-loan-add'),
                                onPressed: _isSaving || data.available <= 0
                                    ? null
                                    : _registerLoan,
                                icon: const Icon(Icons.call_made_rounded),
                                label: const Text('Prestar dinero'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (data.loans.isEmpty)
                            const _LoansEmpty()
                          else
                            for (final loan in data.loans)
                              _ThirdPartyLoanCard(
                                loan: loan,
                                isBusy: _isSaving,
                                onReturn: () => _returnLoan(loan),
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
    );
  }
}

class _SavingsData {
  const _SavingsData({
    required this.movements,
    required this.total,
    required this.available,
    required this.loans,
  });

  final List<MovimientosAhorroData> movements;
  final double total;
  final double available;
  final List<_ThirdPartyLoan> loans;
}

class _ThirdPartyLoan {
  _ThirdPartyLoan(this.loan, this.movements)
    : totalReturned = movements
          .where(
            (movement) => movement.tipo == DatabaseService.devolucionPrestamo,
          )
          .fold<double>(0, (total, movement) => total + movement.monto),
      remaining =
          (loan.montoPrincipal -
                  movements
                      .where(
                        (movement) =>
                            movement.tipo == DatabaseService.devolucionPrestamo,
                      )
                      .fold<double>(
                        0,
                        (total, movement) => total + movement.monto,
                      ))
              .clamp(0.0, double.infinity);

  final PrestamosTercero loan;
  final List<MovimientosPrestamoData> movements;
  final double totalReturned;
  final double remaining;

  String get status => totalReturned <= 0
      ? 'Pendiente'
      : remaining <= 1e-8
      ? 'Devuelto'
      : 'Parcialmente devuelto';
}

class _LoanDraft {
  const _LoanDraft({
    required this.person,
    required this.amount,
    required this.deliveryDate,
    required this.dueDate,
    required this.operationId,
    required this.medium,
  });

  final String person;
  final double amount;
  final DateTime deliveryDate;
  final DateTime dueDate;
  final String operationId;
  final MoneyMedium medium;
}

class _ReturnDraft {
  const _ReturnDraft({
    required this.amount,
    required this.date,
    required this.operationId,
    required this.medium,
  });

  final double amount;
  final DateTime date;
  final String operationId;
  final MoneyMedium medium;
}

String _newLoanOperationId() {
  final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
  final random = Random.secure().nextInt(0x100000000).toRadixString(16);
  return '$timestamp-$random';
}

class _SavingsBalancePanel extends StatelessWidget {
  const _SavingsBalancePanel({
    required this.total,
    required this.isSaving,
    required this.bounceTrigger,
    required this.onContribute,
    required this.onWithdraw,
  });

  final double total;
  final bool isSaving;
  final int bounceTrigger;
  final VoidCallback onContribute;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.brand,
        borderRadius: BorderRadius.circular(AppRadii.large),
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            top: 0,
            end: 0,
            child: AnimatedCat(
              asset: CatAssets.ahorros,
              label: 'Gato cuidando sus ahorros',
              width: 76,
              height: 66,
              bounceTrigger: bounceTrigger,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ahorro acumulado',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  formatMoney(total),
                  key: ValueKey(total),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 34,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 78),
                child: Text(
                  'Un poquito hoy, un gran paso mañana.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      key: const ValueKey('savings-add'),
                      onPressed: isSaving ? null : onContribute,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.brand,
                        minimumSize: const Size.fromHeight(44),
                      ),
                      child: const Text('Separar dinero'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      key: const ValueKey('savings-withdraw'),
                      onPressed: isSaving || total <= 0 ? null : onWithdraw,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                        minimumSize: const Size.fromHeight(44),
                      ),
                      child: const Text('Retirar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SavingsTabSelector extends StatelessWidget {
  const _SavingsTabSelector({
    required this.selected,
    required this.onChanged,
  });

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['Mi ahorro', 'Dinero prestado'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++)
            Expanded(
              child: Material(
                color: selected == index
                    ? AppColors.surface
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
                child: InkWell(
                  borderRadius: BorderRadius.circular(11),
                  onTap: () => onChanged(index),
                  child: SizedBox(
                    height: 40,
                    child: Center(
                      child: Text(
                        labels[index],
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: selected == index
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

class _SavingsNote extends StatelessWidget {
  const _SavingsNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadii.small),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 17,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        Text('$count', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ThirdPartyLoanSummary extends StatelessWidget {
  const _ThirdPartyLoanSummary({required this.loans});

  final List<_ThirdPartyLoan> loans;

  @override
  Widget build(BuildContext context) {
    final lent = loans.fold<double>(
      0,
      (total, loan) => total + loan.loan.montoPrincipal,
    );
    final returned = loans.fold<double>(
      0,
      (total, loan) => total + loan.totalReturned,
    );
    final pending = loans.fold<double>(
      0,
      (total, loan) => total + loan.remaining,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppCardDecorations.surface,
      child: Column(
        children: [
          _LoanSummaryValue(label: 'Prestado', amount: lent),
          const SizedBox(height: 10),
          _LoanSummaryValue(
            label: 'Devuelto',
            amount: returned,
            color: AppColors.positive,
          ),
          const SizedBox(height: 10),
          _LoanSummaryValue(
            label: 'Pendiente por cobrar',
            amount: pending,
            color: pending > 0 ? AppColors.warning : AppColors.positive,
          ),
        ],
      ),
    );
  }
}

class _LoanSummaryValue extends StatelessWidget {
  const _LoanSummaryValue({
    required this.label,
    required this.amount,
    this.color,
  });

  final String label;
  final double amount;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(
          formatMoney(amount),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _SavingsMovementList extends StatelessWidget {
  const _SavingsMovementList({required this.movements});

  final List<MovimientosAhorroData> movements;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: AppCardDecorations.surface,
      child: Column(
        children: [
          for (var index = 0; index < movements.length; index++) ...[
            if (index > 0)
              Divider(
                height: 1,
                color: AppColors.outline.withValues(alpha: 0.25),
              ),
            _SavingsMovementTile(movement: movements[index]),
          ],
        ],
      ),
    );
  }
}

class _SavingsMovementTile extends StatelessWidget {
  const _SavingsMovementTile({required this.movement});

  final MovimientosAhorroData movement;

  @override
  Widget build(BuildContext context) {
    final isContribution = movement.tipo == DatabaseService.aporteAhorro;
    final color = isContribution ? AppColors.positive : AppColors.negative;
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
              isContribution ? Icons.savings_outlined : Icons.output_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isContribution ? 'Aporte a tus ahorros' : 'Retiro de ahorros',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  '${isContribution ? 'Desde' : 'Hacia'} ${MoneyMedium.fromStorage(movement.medio)?.label ?? 'Medio sin clasificar'} · ${formatSpanishLongDate(movement.fecha)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isContribution ? '+' : '−'}${formatMoney(movement.monto)}',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _SavingsEmpty extends StatelessWidget {
  const _SavingsEmpty({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: AppCardDecorations.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const AnimatedCat(
            asset: CatAssets.vacio,
            label: 'Gato descansando, sin movimientos',
            width: 104,
            height: 78,
          ),
          const SizedBox(height: 8),
          Text(
            'Tu primer aporte empieza aquí',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Separa un poquito de lo que recibes y míralo crecer.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onAdd, child: const Text('Separar dinero')),
        ],
      ),
    );
  }
}

class _LoansEmpty extends StatelessWidget {
  const _LoansEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: AppCardDecorations.surface,
      child: Text(
        'Todavía no has prestado dinero a nadie.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _ThirdPartyLoanCard extends StatelessWidget {
  const _ThirdPartyLoanCard({
    required this.loan,
    required this.isBusy,
    required this.onReturn,
  });

  final _ThirdPartyLoan loan;
  final bool isBusy;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    final history = [...loan.movements]
      ..sort((first, second) => first.fecha.compareTo(second.fecha));
    return Container(
      key: ValueKey('third-party-loan-${loan.loan.id}'),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppCardDecorations.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                loan.loan.persona,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Chip(label: Text(loan.status)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Entregado ${formatSpanishLongDate(loan.loan.fechaEntrega)} · '
            'Acordado ${formatSpanishLongDate(loan.loan.fechaDevolucionAcordada)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 20,
            runSpacing: 10,
            children: [
              _LoanValue(label: 'Prestado', amount: loan.loan.montoPrincipal),
              _LoanValue(label: 'Devuelto', amount: loan.totalReturned),
              _LoanValue(label: 'Pendiente por cobrar', amount: loan.remaining),
            ],
          ),
          if (history.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('Movimientos', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            for (final movement in history)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${movement.tipo == DatabaseService.entregaPrestamo ? 'Entrega' : 'Devolución'} · '
                        '${formatSpanishLongDate(movement.fecha)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '${movement.tipo == DatabaseService.entregaPrestamo ? '-' : '+'}${formatMoney(movement.monto)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
          ],
          if (loan.remaining > 0) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: ValueKey('third-party-loan-return-${loan.loan.id}'),
              onPressed: isBusy ? null : onReturn,
              icon: const Icon(Icons.call_received_rounded),
              label: const Text('Registrar devolución'),
            ),
          ],
        ],
      ),
    );
  }
}

class _LoanValue extends StatelessWidget {
  const _LoanValue({required this.label, required this.amount});

  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 3),
        Text(
          formatMoney(amount),
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ],
    );
  }
}

class _LoanFormSheet extends StatefulWidget {
  const _LoanFormSheet({required this.available});

  final double available;

  @override
  State<_LoanFormSheet> createState() => _LoanFormSheetState();
}

class _LoanFormSheetState extends State<_LoanFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _personController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _deliveryDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  MoneyMedium _medium = MoneyMedium.cash;

  @override
  void dispose() {
    _personController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate({required bool isDueDate}) async {
    final initialDate = isDueDate ? _dueDate : _deliveryDate;
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    setState(() {
      if (isDueDate) {
        _dueDate = date;
      } else {
        _deliveryDate = date;
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_dueDate.isBefore(_deliveryDate)) {
      _formKey.currentState!.validate();
      return;
    }
    Navigator.pop(
      context,
      _LoanDraft(
        person: _personController.text.trim(),
        amount: parseMoney(_amountController.text),
        deliveryDate: _deliveryDate,
        dueDate: _dueDate,
        operationId: _newLoanOperationId(),
        medium: _medium,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: SizedBox(
        height: min(
          680,
          (MediaQuery.sizeOf(context).height - bottomInset) * 0.9,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Prestar dinero',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const ValueKey('third-party-loan-person'),
                        controller: _personController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: 'Persona'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Escribe el nombre de la persona.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const ValueKey('third-party-loan-amount'),
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: const [ThousandsInputFormatter()],
                        decoration: const InputDecoration(
                          labelText: 'Cantidad prestada',
                          prefixText: r'$ ',
                        ),
                        validator: (value) {
                          final amount = tryParseMoney(value);
                          if (amount == null || amount <= 0) {
                            return 'Escribe un monto mayor que cero.';
                          }
                          if (amount > widget.available) {
                            return 'Uy, parece que no alcanza la platica para eso.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      MoneyMediumSelector(
                        selected: _medium,
                        title: 'Medio de entrega',
                        onChanged: (medium) {
                          if (medium != null) setState(() => _medium = medium);
                        },
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => _selectDate(isDueDate: false),
                        icon: const Icon(Icons.event_outlined),
                        label: Text(
                          'Entrega: ${formatSpanishLongDate(_deliveryDate)}',
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _selectDate(isDueDate: true),
                        icon: const Icon(Icons.event_available_outlined),
                        label: Text(
                          'Devolución acordada: '
                          '${formatSpanishLongDate(_dueDate)}',
                        ),
                      ),
                      if (_dueDate.isBefore(_deliveryDate))
                        const Text(
                          'La fecha acordada debe ser posterior a la entrega.',
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.call_made_rounded),
                  label: const Text('Revisar entrega'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoanReturnSheet extends StatefulWidget {
  const _LoanReturnSheet({required this.person, required this.remaining});

  final String person;
  final double remaining;

  @override
  State<_LoanReturnSheet> createState() => _LoanReturnSheetState();
}

class _LoanReviewDialog extends StatefulWidget {
  const _LoanReviewDialog({required this.draft, required this.onConfirm});

  final _LoanDraft draft;
  final Future<int> Function() onConfirm;

  @override
  State<_LoanReviewDialog> createState() => _LoanReviewDialogState();
}

class _LoanReviewDialogState extends State<_LoanReviewDialog> {
  bool _isSaving = false;
  String? _error;

  Future<void> _confirm() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await widget.onConfirm();
      if (mounted) Navigator.pop(context, true);
    } catch (error, stackTrace) {
      logOperationFailure(error, stackTrace, operation: 'confirmar la entrega');
      if (mounted) {
        setState(
          () => _error = friendlyOperationError(
            error,
            action: 'registrar el préstamo',
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
      title: const Text('Revisar entrega'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Persona: ${widget.draft.person}'),
          const SizedBox(height: 6),
          Text('Monto: ${formatMoney(widget.draft.amount)}'),
          Text(
            'Fecha de entrega: '
            '${formatSpanishLongDate(widget.draft.deliveryDate)}',
          ),
          Text(
            'Fecha límite de pago: '
            '${formatSpanishLongDate(widget.draft.dueDate)}',
          ),
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
          onPressed: _isSaving ? null : _confirm,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Confirmar entrega'),
        ),
      ],
    );
  }
}

class _LoanReturnSheetState extends State<_LoanReturnSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  DateTime _date = DateTime.now();
  MoneyMedium _medium = MoneyMedium.cash;

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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _ReturnDraft(
        amount: parseMoney(_amountController.text),
        date: _date,
        operationId: _newLoanOperationId(),
        medium: _medium,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: SizedBox(
        height: min(
          680,
          (MediaQuery.sizeOf(context).height - bottomInset) * 0.9,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Devolución de ${widget.person}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text('Pendiente: ${formatMoney(widget.remaining)}'),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const ValueKey('third-party-loan-return-amount'),
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: const [ThousandsInputFormatter()],
                        decoration: const InputDecoration(
                          labelText: 'Importe recibido',
                          prefixText: r'$ ',
                        ),
                        validator: (value) {
                          final amount = tryParseMoney(value);
                          if (amount == null || amount <= 0) {
                            return 'Escribe un monto mayor que cero.';
                          }
                          if (amount > widget.remaining) {
                            return 'Esa cantidad supera lo que falta por cobrar.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      MoneyMediumSelector(
                        selected: _medium,
                        title: 'Medio de recepción',
                        onChanged: (medium) {
                          if (medium != null) setState(() => _medium = medium);
                        },
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _selectDate,
                        icon: const Icon(Icons.event_outlined),
                        label: Text('Fecha: ${formatSpanishLongDate(_date)}'),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.call_received_rounded),
                  label: const Text('Registrar devolución'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavingsAmountSheet extends StatefulWidget {
  const _SavingsAmountSheet({required this.isWithdrawal, required this.limit});

  final bool isWithdrawal;
  final double limit;

  @override
  State<_SavingsAmountSheet> createState() => _SavingsAmountSheetState();
}

class _SavingsAmountSheetState extends State<_SavingsAmountSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  MoneyMedium _medium = MoneyMedium.cash;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, (
      amount: parseMoney(_amountController.text),
      medium: _medium,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.isWithdrawal ? 'Retirar' : 'Separar dinero';
    return Padding(
      padding: EdgeInsets.fromLTRB(
        22,
        22,
        22,
        22 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(action, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('savings-amount'),
              controller: _amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: const [ThousandsInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Monto',
                prefixText: r'$ ',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              validator: (value) {
                final amount = tryParseMoney(value);
                if (amount == null || amount <= 0) {
                  return 'Escribe un monto mayor que cero.';
                }
                if (amount > widget.limit) {
                  return widget.isWithdrawal
                      ? 'No puedes retirar más de lo que tienes ahorrado.'
                      : 'Uy, parece que no alcanza la platica para eso.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            MoneyMediumSelector(
              selected: _medium,
              title: 'Medio del movimiento',
              onChanged: (medium) {
                if (medium != null) setState(() => _medium = medium);
              },
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _submit,
              icon: Icon(
                widget.isWithdrawal
                    ? Icons.output_rounded
                    : Icons.savings_outlined,
              ),
              label: Text(action),
            ),
          ],
        ),
      ),
    );
  }
}

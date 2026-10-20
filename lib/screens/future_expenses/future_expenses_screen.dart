import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../database/app_database.dart';
import '../../models/future_expense.dart';
import '../../models/money_medium.dart';
import '../../services/app_settings_service.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_format.dart';
import '../../utils/future_expense_calculator.dart';
import '../../utils/money_format.dart';
import '../../utils/user_messages.dart';
import '../../widgets/cat_illustration.dart';
import '../../widgets/money_medium_selector.dart';

class FutureExpensesScreen extends StatefulWidget {
  const FutureExpensesScreen({super.key, this.databaseService});

  final DatabaseService? databaseService;

  @override
  State<FutureExpensesScreen> createState() => _FutureExpensesScreenState();
}

class _FutureExpensesScreenState extends State<FutureExpensesScreen> {
  late final DatabaseService _databaseService;
  late final bool _ownsDatabaseService;
  late final StreamSubscription<void> _changes;
  late Future<_FutureExpensesData> _dataFuture;
  FutureExpenseStatus _selectedStatus = FutureExpenseStatus.active;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _ownsDatabaseService = widget.databaseService == null;
    _databaseService = widget.databaseService ?? DatabaseService(AppDatabase());
    _dataFuture = _loadData();
    _changes = _databaseService.observarCambiosFinancieros().listen((_) {
      if (mounted) {
        setState(() {
          _dataFuture = _loadData();
        });
      }
    });
  }

  Future<_FutureExpensesData> _loadData() async {
    AppSettings settings;
    try {
      settings = await const AppSettingsService().load();
    } catch (error, stackTrace) {
      logOperationFailure(
        error,
        stackTrace,
        operation: 'cargar categorías para gastos futuros',
      );
      settings = AppSettings.defaults();
    }
    final results = await runWithLoggedErrors(
      'cargar planes de gastos futuros',
      () => Future.wait<Object>([
        _databaseService.obtenerPlanesGastosFuturos(),
        _databaseService.obtenerSaldoDisponible(),
      ]),
    );
    return _FutureExpensesData(
      plans: results[0] as List<FutureExpenseSummary>,
      available: results[1] as double,
      categories: AppSettingsService.normalizeCategories([
        ...settings.expenseCategories,
        for (final item in results[0] as List<FutureExpenseSummary>)
          item.plan.category,
      ]),
    );
  }

  @override
  void dispose() {
    unawaited(_changes.cancel());
    if (_ownsDatabaseService) unawaited(_databaseService.close());
    super.dispose();
  }

  Future<void> _openPlanForm(
    _FutureExpensesData data, {
    FutureExpensePlan? plan,
  }) async {
    if (_isSaving) return;
    final draft = await showDialog<_FutureExpensesDraft>(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
          child: _FutureExpenseFormSheet(
            categories: data.categories,
            plan: plan,
          ),
        ),
      ),
    );
    if (draft == null || !mounted || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      if (plan == null) {
        await _databaseService.crearPlanGastoFuturo(
          nombre: draft.name,
          categoria: draft.category,
          montoNecesario: draft.targetAmount,
          montoPlaneado: draft.plannedAmount,
          frecuencia: draft.frequency.storageValue,
          fechaObjetivo: draft.targetDate,
          fechaInicio: draft.startDate,
          notas: draft.notes,
        );
      } else {
        await _databaseService.actualizarPlanGastoFuturo(
          id: plan.id,
          nombre: draft.name,
          categoria: draft.category,
          montoNecesario: draft.targetAmount,
          montoPlaneado: draft.plannedAmount,
          frecuencia: draft.frequency.storageValue,
          fechaObjetivo: draft.targetDate,
          fechaInicio: draft.startDate,
          notas: draft.notes,
        );
      }
      if (!mounted) return;
      setState(() {
        _dataFuture = _loadData();
      });
      _showMessage(
        plan == null
            ? 'Plan guardado. Ya puedes organizarlo.'
            : 'Plan actualizado.',
        isSuccess: true,
      );
    } catch (error, stackTrace) {
      logOperationFailure(
        error,
        stackTrace,
        operation: plan == null
            ? 'guardar un gasto futuro'
            : 'actualizar un gasto futuro',
      );
      if (mounted) {
        _showMessage(
          friendlyOperationError(
            error,
            action: plan == null ? 'guardar el plan' : 'actualizar el plan',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _reserve(FutureExpenseSummary summary) async {
    if (_isSaving || summary.plan.status != FutureExpenseStatus.active) return;
    setState(() => _isSaving = true);
    try {
      final available = await _databaseService.obtenerSaldoDisponible();
      if (!mounted) return;
      final progress = calculateFutureExpenseProgress(
        targetAmount: summary.plan.targetAmount,
        reservedAmount: summary.reservedAmount,
        frequency: summary.plan.frequency,
        targetDate: summary.plan.targetDate,
        startDate: summary.plan.startDate,
      );
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => _FutureExpenseReservationDialog(
          summary: summary,
          progress: progress,
          available: available,
          onReserve: (amount, operationId, medium) =>
              _databaseService.registrarReservaGastoFuturo(
                planId: summary.plan.id,
                monto: amount,
                fecha: DateTime.now(),
                operationId: operationId,
                medio: medium,
              ),
        ),
      );
      if (confirmed != true || !mounted) return;
      setState(() {
        _dataFuture = _loadData();
      });
      _showMessage(
        'Reserva confirmada. El dinero ya está apartado.',
        isSuccess: true,
      );
    } catch (error, stackTrace) {
      logOperationFailure(
        error,
        stackTrace,
        operation: 'reservar dinero para un gasto futuro',
      );
      if (mounted) {
        _showMessage(
          friendlyOperationError(error, action: 'reservar el dinero'),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _release(FutureExpenseSummary summary) async {
    if (_isSaving || summary.reservedAmount <= 0) return;
    var selectedMedium = '';
    final selectedValue = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('¿Liberar lo reservado?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Los ${formatMoney(summary.reservedAmount)} de “${summary.plan.name}” '
                'volverán a tu dinero disponible. El historial se conservará.',
              ),
              const SizedBox(height: 16),
              MoneyMediumSelector(
                selected: MoneyMedium.fromStorage(selectedMedium),
                title: 'Medio al que vuelve',
                allowUnclassified: true,
                onChanged: (medium) => setDialogState(
                  () => selectedMedium = medium?.storageValue ?? '',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ahora no'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, selectedMedium),
              child: const Text('Liberar dinero'),
            ),
          ],
        ),
      ),
    );
    if (selectedValue == null || !mounted || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      await _databaseService.liberarReservaGastoFuturo(
        planId: summary.plan.id,
        monto: summary.reservedAmount,
        fecha: DateTime.now(),
        operationId: _newFutureExpenseOperationId(),
        medio: MoneyMedium.fromStorage(selectedValue),
      );
      if (!mounted) return;
      setState(() {
        _dataFuture = _loadData();
      });
      _showMessage(
        'Listo, ese dinero volvió a estar disponible.',
        isSuccess: true,
      );
    } catch (error, stackTrace) {
      logOperationFailure(
        error,
        stackTrace,
        operation: 'liberar una reserva de gasto futuro',
      );
      if (mounted) {
        _showMessage(
          friendlyOperationError(error, action: 'liberar el dinero'),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _changeStatus(
    FutureExpenseSummary summary,
    FutureExpenseStatus status,
  ) async {
    try {
      await _databaseService.actualizarEstadoPlanGastoFuturo(
        id: summary.plan.id,
        estado: status,
      );
      if (!mounted) return;
      setState(() {
        _dataFuture = _loadData();
      });
      _showMessage('Estado actualizado.', isSuccess: true);
    } catch (error, stackTrace) {
      logOperationFailure(
        error,
        stackTrace,
        operation: 'actualizar el estado de un gasto futuro',
      );
      if (mounted) {
        _showMessage(
          friendlyOperationError(error, action: 'actualizar el plan'),
        );
      }
    }
  }

  Future<void> _deletePlan(FutureExpenseSummary summary) async {
    if (summary.reservedAmount > 1e-8) {
      _showMessage(
        'Libera primero el dinero reservado para poder eliminar el plan.',
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Borrar este plan?'),
        content: Text('Se quitará “${summary.plan.name}”.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Conservar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar plan'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _databaseService.eliminarPlanGastoFuturo(summary.plan.id);
      if (!mounted) return;
      setState(() {
        _dataFuture = _loadData();
      });
      _showMessage('Plan eliminado.');
    } catch (error, stackTrace) {
      logOperationFailure(
        error,
        stackTrace,
        operation: 'eliminar un gasto futuro',
      );
      if (mounted) {
        _showMessage(friendlyOperationError(error, action: 'eliminar el plan'));
      }
    }
  }

  void _showMessage(String message, {bool isSuccess = false}) {
    showCatMessage(context, message, isSuccess: isSuccess);
  }

  Future<void> _retry() async {
    setState(() {
      _dataFuture = _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('future-expense-add'),
        onPressed: _isSaving
            ? null
            : () async {
                final data = await _dataFuture;
                if (mounted) await _openPlanForm(data);
              },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo plan'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 420 ? 18.0 : 36.0;
            return FutureBuilder<_FutureExpensesData>(
              future: _dataFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _FutureExpensesError(onRetry: _retry);
                }
                if (!snapshot.hasData) return const _FutureExpensesLoading();
                final data = snapshot.data!;
                final visiblePlans = data.plans
                    .where((item) => item.plan.status == _selectedStatus)
                    .toList();
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            26,
                            horizontalPadding,
                            120,
                          ),
                          sliver: SliverList.list(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Gastos futuros',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.headlineMedium,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Organiza con tiempo lo que vas a necesitar.',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyLarge,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const AnimatedCat(
                                    asset: CatAssets.gastos,
                                    label: 'Gato organizando sus gastos',
                                    width: 66,
                                    height: 58,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _AvailableFutureFunds(available: data.available),
                              const SizedBox(height: 20),
                              SegmentedButton<FutureExpenseStatus>(
                                segments: const [
                                  ButtonSegment(
                                    value: FutureExpenseStatus.active,
                                    label: Text('Activos'),
                                  ),
                                  ButtonSegment(
                                    value: FutureExpenseStatus.completed,
                                    label: Text('Completados'),
                                  ),
                                  ButtonSegment(
                                    value: FutureExpenseStatus.archived,
                                    label: Text('Archivados'),
                                  ),
                                ],
                                selected: {_selectedStatus},
                                onSelectionChanged: (selection) => setState(
                                  () => _selectedStatus = selection.first,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (visiblePlans.isEmpty)
                                _FutureExpensesEmpty(status: _selectedStatus)
                              else
                                for (final summary in visiblePlans) ...[
                                  _FutureExpenseCard(
                                    summary: summary,
                                    isSaving: _isSaving,
                                    onReserve: () => _reserve(summary),
                                    onEdit: () =>
                                        _openPlanForm(data, plan: summary.plan),
                                    onRelease: () => _release(summary),
                                    onStatus: (status) =>
                                        _changeStatus(summary, status),
                                    onDelete: () => _deletePlan(summary),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                            ],
                          ),
                        ),
                      ],
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

class _FutureExpensesData {
  const _FutureExpensesData({
    required this.plans,
    required this.available,
    required this.categories,
  });

  final List<FutureExpenseSummary> plans;
  final double available;
  final List<String> categories;
}

class _FutureExpensesDraft {
  const _FutureExpensesDraft({
    required this.name,
    required this.category,
    required this.targetAmount,
    required this.plannedAmount,
    required this.frequency,
    required this.targetDate,
    required this.startDate,
    required this.notes,
  });

  final String name;
  final String category;
  final double targetAmount;
  final double plannedAmount;
  final FutureExpenseFrequency frequency;
  final DateTime targetDate;
  final DateTime? startDate;
  final String? notes;
}

class _FutureExpenseFormSheet extends StatefulWidget {
  const _FutureExpenseFormSheet({required this.categories, this.plan});

  final List<String> categories;
  final FutureExpensePlan? plan;

  @override
  State<_FutureExpenseFormSheet> createState() =>
      _FutureExpenseFormSheetState();
}

class _FutureExpenseFormSheetState extends State<_FutureExpenseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _targetController;
  late final TextEditingController _plannedController;
  late final TextEditingController _notesController;
  late List<String> _categories;
  late String _category;
  late FutureExpenseFrequency _frequency;
  late DateTime _targetDate;
  late DateTime _startDate;
  bool _plannedAmountEdited = false;
  String? _dateError;

  @override
  void initState() {
    super.initState();
    final plan = widget.plan;
    _categories = [...widget.categories];
    if (plan != null && !_categories.contains(plan.category)) {
      _categories.add(plan.category);
    }
    _category =
        plan?.category ?? (_categories.isEmpty ? '' : _categories.first);
    _frequency = plan?.frequency ?? FutureExpenseFrequency.once;
    _targetDate =
        plan?.targetDate ?? DateTime.now().add(const Duration(days: 30));
    _startDate = plan?.startDate ?? DateTime.now();
    _nameController = TextEditingController(text: plan?.name ?? '');
    _targetController = TextEditingController(
      text: plan == null ? '' : formatAmount(plan.targetAmount),
    );
    _plannedController = TextEditingController(
      text: plan == null ? '' : formatAmount(plan.plannedAmount),
    );
    _notesController = TextEditingController(text: plan?.notes ?? '');
    _plannedAmountEdited = plan != null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _plannedController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isTarget}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: isTarget ? _targetDate : _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected == null) return;
    setState(() {
      if (isTarget) {
        _targetDate = selected;
      } else {
        _startDate = selected;
      }
      _dateError = null;
    });
  }

  Future<void> _addCategory() async {
    final category = await showDialog<String>(
      context: context,
      builder: (context) => const _NewFutureCategoryDialog(),
    );
    if (category == null || !mounted) return;
    final normalized = AppSettingsService.normalizeCategory(category);
    if (_categories.any(
      (item) => item.toLowerCase() == normalized.toLowerCase(),
    )) {
      setState(() => _category = normalized);
      return;
    }
    setState(() {
      _categories.add(normalized);
      _category = normalized;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_frequency != FutureExpenseFrequency.once &&
        _startDate.isAfter(_targetDate)) {
      setState(
        () => _dateError =
            'La fecha de inicio debe ser anterior a la fecha en que lo necesitas.',
      );
      return;
    }
    final target = tryParseMoney(_targetController.text)!;
    final planned = tryParseMoney(_plannedController.text)!;
    Navigator.pop(
      context,
      _FutureExpensesDraft(
        name: _nameController.text.trim(),
        category: _category,
        targetAmount: target,
        plannedAmount: planned,
        frequency: _frequency,
        targetDate: _dateOnly(_targetDate),
        startDate: _frequency == FutureExpenseFrequency.once
            ? null
            : _dateOnly(_startDate),
        notes: _notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(22, 22, 22, 22 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.plan == null ? 'Nuevo gasto futuro' : 'Editar plan',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('future-expense-name'),
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nombre del gasto'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Escribe un nombre para tu plan.'
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: const ValueKey('future-expense-category'),
                    isExpanded: true,
                    initialValue: _category.isEmpty ? null : _category,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    items: [
                      for (final category in {..._categories, _category})
                        DropdownMenuItem(
                          value: category,
                          child: Text(
                            category,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _category = value);
                    },
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Elige una categoría.'
                        : null,
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Agregar categoría personalizada',
                  onPressed: _addCategory,
                  icon: const Icon(Icons.add_circle_outline_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('future-expense-target'),
              controller: _targetController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: const [ThousandsInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Valor que necesitas',
                prefixText: r'$ ',
              ),
              validator: (value) {
                final amount = tryParseMoney(value);
                if (amount == null || amount <= 0) {
                  return 'Escribe un valor mayor que cero.';
                }
                final planned = tryParseMoney(_plannedController.text);
                if (_plannedAmountEdited &&
                    planned != null &&
                    planned > amount) {
                  return 'Lo planeado no puede superar lo que necesitas.';
                }
                return null;
              },
              onChanged: (value) {
                if (!_plannedAmountEdited) {
                  _plannedController.text = value;
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('future-expense-planned'),
              controller: _plannedController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: const [ThousandsInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Cantidad que planeas guardar',
                prefixText: r'$ ',
              ),
              validator: (value) {
                final planned = tryParseMoney(value);
                final target = tryParseMoney(_targetController.text);
                if (planned == null || planned < 0) {
                  return 'Escribe cero o una cantidad mayor.';
                }
                if (target != null && planned > target) {
                  return 'No planees guardar más de lo que necesitas.';
                }
                return null;
              },
              onChanged: (_) => _plannedAmountEdited = true,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<FutureExpenseFrequency>(
              key: const ValueKey('future-expense-frequency'),
              initialValue: _frequency,
              decoration: const InputDecoration(labelText: 'Frecuencia'),
              items: [
                for (final frequency in FutureExpenseFrequency.values)
                  DropdownMenuItem(
                    value: frequency,
                    child: Text(frequency.label),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _frequency = value);
              },
            ),
            if (_frequency != FutureExpenseFrequency.once) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => _pickDate(isTarget: false),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text('Empezar: ${formatSpanishLongDate(_startDate)}'),
              ),
            ],
            TextButton.icon(
              onPressed: () => _pickDate(isTarget: true),
              icon: const Icon(Icons.event_outlined),
              label: Text(
                'Necesito el dinero: ${formatSpanishLongDate(_targetDate)}',
              ),
            ),
            if (_dateError != null)
              Text(
                _dateError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 8),
            TextFormField(
              key: const ValueKey('future-expense-notes'),
              controller: _notesController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notas (opcional)'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check_rounded),
              label: Text(
                widget.plan == null ? 'Guardar plan' : 'Guardar cambios',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewFutureCategoryDialog extends StatefulWidget {
  const _NewFutureCategoryDialog();

  @override
  State<_NewFutureCategoryDialog> createState() =>
      _NewFutureCategoryDialogState();
}

class _NewFutureCategoryDialogState extends State<_NewFutureCategoryDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar categoría'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          key: const ValueKey('future-expense-custom-category'),
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Nombre de categoría'),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Escribe un nombre para la categoría.'
              : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, _controller.text.trim());
          },
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}

class _FutureExpenseReservationDialog extends StatefulWidget {
  const _FutureExpenseReservationDialog({
    required this.summary,
    required this.progress,
    required this.available,
    required this.onReserve,
  });

  final FutureExpenseSummary summary;
  final FutureExpenseProgress progress;
  final double available;
  final Future<int> Function(
    double amount,
    String operationId,
    MoneyMedium medium,
  )
  onReserve;

  @override
  State<_FutureExpenseReservationDialog> createState() =>
      _FutureExpenseReservationDialogState();
}

class _FutureExpenseReservationDialogState
    extends State<_FutureExpenseReservationDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final String _operationId;
  bool _isSaving = false;
  String? _error;
  MoneyMedium _medium = MoneyMedium.cash;

  double get _amount => tryParseMoney(_amountController.text) ?? 0;

  @override
  void initState() {
    super.initState();
    final maxReserve = min(
      min(widget.summary.amountMissing, widget.summary.plannedAmountRemaining),
      widget.available,
    );
    final recommendation = widget.progress.recommendedPerPeriod;
    final initial = min(
      maxReserve,
      recommendation > 0 ? recommendation : maxReserve,
    );
    _amountController = TextEditingController(text: formatAmount(initial));
    _operationId = _newFutureExpenseOperationId();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await widget.onReserve(_amount, _operationId, _medium);
      if (mounted) Navigator.pop(context, true);
    } catch (error, stackTrace) {
      logOperationFailure(
        error,
        stackTrace,
        operation: 'confirmar una reserva de gasto futuro',
      );
      if (mounted) {
        setState(
          () => _error = friendlyOperationError(
            error,
            action: 'reservar el dinero',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final insufficient = _amount > widget.available;
    final after = insufficient ? widget.available : widget.available - _amount;
    return AlertDialog(
      key: const ValueKey('future-expense-reservation-dialog'),
      title: const Text('Confirmar reserva'),
      content: SizedBox(
        width: min(460, MediaQuery.sizeOf(context).width - 64),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.summary.plan.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _ReviewValue(
                  label: 'Concepto',
                  value: widget.summary.plan.name,
                ),
                _ReviewValue(
                  label: 'Dinero disponible antes de reservar',
                  value: formatMoney(widget.available),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('future-expense-reserve-amount'),
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: const [ThousandsInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Valor que vas a reservar',
                    prefixText: r'$ ',
                  ),
                  onChanged: (_) => setState(() => _error = null),
                  validator: (value) {
                    final amount = tryParseMoney(value);
                    if (amount == null || amount <= 0) {
                      return 'Escribe una cantidad mayor que cero.';
                    }
                    if (amount > widget.summary.amountMissing) {
                      return 'No hace falta reservar más para completar la meta.';
                    }
                    if (amount > widget.summary.plannedAmountRemaining) {
                      return 'Supera lo que planeaste guardar para este plan.';
                    }
                    if (amount > widget.available) {
                      return 'Te faltan ${formatMoney(amount - widget.available)}.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                MoneyMediumSelector(
                  selected: _medium,
                  title: 'Medio reservado',
                  onChanged: (medium) {
                    if (medium != null) setState(() => _medium = medium);
                  },
                ),
                const SizedBox(height: 8),
                _ReviewValue(
                  label: 'Valor de esta reserva',
                  value: formatMoney(_amount),
                ),
                _ReviewValue(
                  label: 'Saldo disponible después de confirmar',
                  value: formatMoney(after),
                ),
                if (insufficient) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Te faltan ${formatMoney(_amount - widget.available)} para reservar esa cantidad.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'El dinero solo se descontará después de confirmar.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const ValueKey('future-expense-confirm-reservation'),
          onPressed: _isSaving ? null : _confirm,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Confirmar reserva'),
        ),
      ],
    );
  }
}

class _ReviewValue extends StatelessWidget {
  const _ReviewValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Flexible(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

class _AvailableFutureFunds extends StatelessWidget {
  const _AvailableFutureFunds({required this.available});

  final double available;

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final balance = Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dinero disponible',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      formatMoney(available),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ],
          );
          if (constraints.maxWidth < 460) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                balance,
                const SizedBox(height: 8),
                const Text('El saldo cambia al confirmar una reserva.'),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: balance),
              const SizedBox(width: 16),
              const Flexible(
                child: Text('El saldo cambia al confirmar una reserva.'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FutureExpenseCard extends StatelessWidget {
  const _FutureExpenseCard({
    required this.summary,
    required this.isSaving,
    required this.onReserve,
    required this.onEdit,
    required this.onRelease,
    required this.onStatus,
    required this.onDelete,
  });

  final FutureExpenseSummary summary;
  final bool isSaving;
  final VoidCallback onReserve;
  final VoidCallback onEdit;
  final VoidCallback onRelease;
  final ValueChanged<FutureExpenseStatus> onStatus;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final plan = summary.plan;
    final progress = calculateFutureExpenseProgress(
      targetAmount: plan.targetAmount,
      reservedAmount: summary.reservedAmount,
      frequency: plan.frequency,
      targetDate: plan.targetDate,
      startDate: plan.startDate,
    );
    final percent = plan.targetAmount <= 0
        ? 0.0
        : (summary.reservedAmount / plan.targetAmount).clamp(0.0, 1.0);
    return Container(
      key: ValueKey('future-expense-${plan.id}'),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${plan.category} · ${plan.frequency.label}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<_PlanAction>(
                tooltip: 'Más opciones para ${plan.name}',
                onSelected: (action) => switch (action) {
                  _PlanAction.edit => onEdit(),
                  _PlanAction.complete => onStatus(
                    FutureExpenseStatus.completed,
                  ),
                  _PlanAction.archive => onStatus(FutureExpenseStatus.archived),
                  _PlanAction.activate => onStatus(FutureExpenseStatus.active),
                  _PlanAction.delete => onDelete(),
                },
                itemBuilder: (context) => [
                  if (plan.status != FutureExpenseStatus.archived)
                    const PopupMenuItem(
                      value: _PlanAction.edit,
                      child: Text('Editar plan'),
                    ),
                  if (plan.status == FutureExpenseStatus.active)
                    const PopupMenuItem(
                      value: _PlanAction.complete,
                      child: Text('Marcar como completado'),
                    ),
                  if (plan.status != FutureExpenseStatus.archived)
                    const PopupMenuItem(
                      value: _PlanAction.archive,
                      child: Text('Archivar'),
                    ),
                  if (plan.status == FutureExpenseStatus.archived)
                    const PopupMenuItem(
                      value: _PlanAction.activate,
                      child: Text('Volver a activar'),
                    ),
                  const PopupMenuItem(
                    value: _PlanAction.delete,
                    child: Text('Eliminar plan'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 20,
            runSpacing: 10,
            children: [
              _PlanAmount(label: 'Necesitas', amount: plan.targetAmount),
              _PlanAmount(label: 'Planeas guardar', amount: plan.plannedAmount),
              _PlanAmount(
                label: 'Reservado de verdad',
                amount: summary.reservedAmount,
              ),
              _PlanAmount(
                label: 'Todavía falta',
                amount: summary.amountMissing,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: percent, minHeight: 7),
          ),
          const SizedBox(height: 10),
          Text(
            'Necesitas el dinero: ${formatSpanishLongDate(plan.targetDate)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (progress.isOverdue) ...[
            const SizedBox(height: 6),
            Text(
              'La fecha ya pasó. Puedes ajustar el plan para ponerte al día.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ] else if (!progress.isComplete &&
              plan.status == FutureExpenseStatus.active) ...[
            const SizedBox(height: 6),
            Text(
              'Sugerencia: ${formatMoney(progress.recommendedPerPeriod)} '
              '${plan.frequency.label.toLowerCase()}.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (plan.notes?.isNotEmpty == true) ...[
            const SizedBox(height: 7),
            Text(plan.notes!, style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (plan.status == FutureExpenseStatus.active &&
                  !progress.isComplete)
                FilledButton.tonalIcon(
                  key: ValueKey('future-expense-reserve-${plan.id}'),
                  onPressed: isSaving ? null : onReserve,
                  icon: const Icon(Icons.savings_outlined),
                  label: const Text('Reservar'),
                ),
              if (summary.reservedAmount > 1e-8)
                OutlinedButton.icon(
                  key: ValueKey('future-expense-release-${plan.id}'),
                  onPressed: onRelease,
                  icon: const Icon(Icons.undo_rounded),
                  label: const Text('Liberar reserva'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _PlanAction { edit, complete, archive, activate, delete }

class _PlanAmount extends StatelessWidget {
  const _PlanAmount({required this.label, required this.amount});

  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 3),
          Text(
            formatMoney(amount),
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}

class _FutureExpensesEmpty extends StatelessWidget {
  const _FutureExpensesEmpty({required this.status});

  final FutureExpenseStatus status;

  @override
  Widget build(BuildContext context) {
    final message = switch (status) {
      FutureExpenseStatus.active =>
        'Todavía no hay planes por aquí. Crea uno para empezar.',
      FutureExpenseStatus.completed => 'Todavía no has completado ningún plan.',
      FutureExpenseStatus.archived => 'Todavía no hay planes archivados.',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const AnimatedCat(
            asset: CatAssets.vacio,
            label: 'Gato descansando',
            width: 128,
            height: 104,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _FutureExpensesLoading extends StatelessWidget {
  const _FutureExpensesLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _FutureExpensesError extends StatelessWidget {
  const _FutureExpensesError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ups, no pudimos cargar tus planes.'),
            const SizedBox(height: 10),
            FilledButton.icon(
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

String _newFutureExpenseOperationId() {
  final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
  final random = Random.secure().nextInt(0x100000000).toRadixString(16);
  return '$timestamp-$random';
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

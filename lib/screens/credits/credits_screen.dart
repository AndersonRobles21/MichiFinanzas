import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../database/app_database.dart';
import '../../models/money_medium.dart';
import '../../services/app_settings_service.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_format.dart';
import '../../utils/money_format.dart';
import '../../utils/user_messages.dart';
import '../../widgets/app_page_header.dart';
import '../../widgets/cat_illustration.dart';

class CreditsScreen extends StatefulWidget {
  const CreditsScreen({super.key, this.databaseService, this.onViewDebts});

  final DatabaseService? databaseService;
  final ValueChanged<int>? onViewDebts;

  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen> {
  late final DatabaseService _databaseService;
  late final bool _ownsDatabaseService;
  Future<List<CreditEntitySummary>>? _entitiesFuture;

  @override
  void initState() {
    super.initState();
    _ownsDatabaseService = widget.databaseService == null;
    _databaseService = widget.databaseService ?? DatabaseService(AppDatabase());
    _entitiesFuture = _loadEntities();
  }

  Future<List<CreditEntitySummary>> _loadEntities() => runWithLoggedErrors(
    'cargar créditos',
    _databaseService.obtenerEntidadesCredito,
  );

  @override
  void dispose() {
    if (_ownsDatabaseService) unawaited(_databaseService.close());
    super.dispose();
  }

  Future<void> _addEntity() async {
    final draft = await showModalBottomSheet<_CreditEntityDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      builder: (context) => const _CreditEntityFormSheet(),
    );
    if (draft == null || !mounted) return;
    try {
      await _databaseService.crearEntidadCredito(
        nombre: draft.name,
        cupoAprobado: draft.limit,
      );
      if (!mounted) return;
      final entities = await _databaseService.obtenerEntidadesCredito();
      if (!mounted) return;
      setState(() {
        _entitiesFuture = Future.value(entities);
      });
      _showMessage('Entidad agregada.', success: true);
    } catch (error, stackTrace) {
      logOperationFailure(error, stackTrace, operation: 'crear una entidad');
      if (mounted) _showMessage(_creditError(error, 'crear la entidad'));
    }
  }

  Future<void> _openEntity(EntidadCredito entity) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => CreditEntityDetailScreen(
          initialEntity: entity,
          databaseService: _databaseService,
          onViewDebts: widget.onViewDebts,
        ),
      ),
    );
    if (mounted) setState(() => _entitiesFuture = _loadEntities());
  }

  void _showMessage(String message, {bool success = false}) {
    showCatMessage(context, message, isSuccess: success);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addEntity,
        tooltip: 'Agregar entidad de crédito',
        icon: const Icon(Icons.add_rounded),
        label: const Text('Agregar entidad'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 420
                ? AppSpacing.pageHorizontal
                : AppSpacing.pageHorizontalWide;
            return FutureBuilder<List<CreditEntitySummary>>(
              future: _entitiesFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _CreditError(
                    onRetry: () =>
                        setState(() => _entitiesFuture = _loadEntities()),
                  );
                }
                if (!snapshot.hasData) return const _CreditLoading();
                final entities = snapshot.data!;
                final totalApproved = entities.fold<double>(
                  0,
                  (sum, item) => sum + item.entidad.cupoAprobado,
                );
                final totalUsed = entities.fold<double>(
                  0,
                  (sum, item) => sum + item.cupoUtilizado,
                );
                final totalAvailable = entities.fold<double>(
                  0,
                  (sum, item) => sum + item.cupoDisponible,
                );
                final outstanding = entities.fold<double>(
                  0,
                  (sum, item) => sum + item.deudaPendiente,
                );

                return RefreshIndicator(
                  onRefresh: () async =>
                      setState(() => _entitiesFuture = _loadEntities()),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      AppSpacing.pageTop,
                      horizontalPadding,
                      104,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppPageHeader(
                              title: 'Créditos',
                              subtitle:
                                  'Organiza tus compras y el cupo de cada entidad.',
                              trailing: AnimatedCat(
                                asset: CatAssets.estadisticas,
                                label: 'Gato organizando créditos',
                                width: 72,
                                height: 58,
                              ),
                            ),
                            if (entities.isNotEmpty) ...[
                              const SizedBox(height: 22),
                              _CreditOverview(
                                approved: totalApproved,
                                used: totalUsed,
                                available: totalAvailable,
                                outstanding: outstanding,
                              ),
                            ],
                            const SizedBox(height: 28),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Tus entidades',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                ),
                                Text(
                                  '${entities.length}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (entities.isEmpty)
                              _CreditEmpty(onAdd: _addEntity)
                            else
                              ...entities.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _CreditEntityCard(
                                    summary: item,
                                    onTap: () => _openEntity(item.entidad),
                                  ),
                                ),
                              ),
                          ],
                        ),
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

class CreditEntityDetailScreen extends StatefulWidget {
  const CreditEntityDetailScreen({
    super.key,
    required this.initialEntity,
    required this.databaseService,
    this.onViewDebts,
  });

  final EntidadCredito initialEntity;
  final DatabaseService databaseService;
  final ValueChanged<int>? onViewDebts;

  @override
  State<CreditEntityDetailScreen> createState() =>
      _CreditEntityDetailScreenState();
}

class _CreditEntityDetailScreenState extends State<CreditEntityDetailScreen> {
  late Future<_CreditEntityData> _dataFuture;
  bool _isWorking = false;

  Future<_CreditEntityData> _loadData() async {
    final results = await Future.wait<Object>([
      widget.databaseService.obtenerEntidadesCredito(incluirRetiradas: true),
      widget.databaseService.obtenerComprasCredito(widget.initialEntity.id),
      widget.databaseService.obtenerHistorialCupoCredito(
        widget.initialEntity.id,
      ),
      widget.databaseService.obtenerCuentasDigitales(),
    ]);
    final entities = results[0] as List<CreditEntitySummary>;
    final summary = entities.where(
      (item) => item.entidad.id == widget.initialEntity.id,
    );
    if (summary.isEmpty) throw StateError('La entidad ya no existe.');
    return _CreditEntityData(
      summary: summary.first,
      purchases: results[1] as List<CreditPurchaseDetails>,
      limitChanges: results[2] as List<CambioCupoCredito>,
      digitalAccounts: results[3] as List<DigitalAccountBalance>,
    );
  }

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  void _reload() => setState(() => _dataFuture = _loadData());

  Future<void> _editLimit(CreditEntitySummary summary) async {
    final newLimit = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      builder: (context) => _CreditLimitFormSheet(summary: summary),
    );
    if (newLimit == null || !mounted) return;
    try {
      await widget.databaseService.actualizarCupoCredito(
        entidadId: summary.entidad.id,
        nuevoCupo: newLimit,
        fecha: DateTime.now(),
      );
      _reload();
      _showMessage('Cupo actualizado. El utilizado no cambió.', success: true);
    } catch (error, stackTrace) {
      logOperationFailure(error, stackTrace, operation: 'actualizar el cupo');
      _showMessage(_creditError(error, 'actualizar el cupo'));
    }
  }

  Future<void> _addPurchase(CreditEntitySummary summary) async {
    AppSettings settings;
    try {
      settings = await const AppSettingsService().load();
    } catch (error, stackTrace) {
      logOperationFailure(
        error,
        stackTrace,
        operation: 'cargar categorías para la compra',
      );
      if (mounted) _showMessage('No pudimos cargar tus categorías.');
      return;
    }
    if (!mounted) return;
    final draft = await showModalBottomSheet<_CreditPurchaseDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      builder: (context) => _CreditPurchaseFormSheet(
        categories: settings.expenseCategories,
        available: summary.cupoDisponible,
      ),
    );
    if (draft == null || !mounted) return;
    setState(() => _isWorking = true);
    try {
      await widget.databaseService.registrarCompraCredito(
        entidadId: summary.entidad.id,
        descripcion: draft.description,
        monto: draft.amount,
        categoria: draft.category,
        fecha: draft.date,
        cuotasTotales: draft.installmentCount,
        valorCuota: draft.installmentAmount,
        primerVencimiento: draft.firstDueDate,
      );
      _reload();
      _showMessage('Compra guardada y agregada a Deudas.', success: true);
    } catch (error, stackTrace) {
      logOperationFailure(error, stackTrace, operation: 'guardar una compra');
      _showMessage(_creditError(error, 'guardar la compra'));
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _retire(CreditEntitySummary summary) async {
    if (summary.deudaPendiente > 1e-8) {
      _showMessage('Primero termina de pagar las deudas de esta entidad.');
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Retirar esta entidad?'),
        content: const Text(
          'Se ocultará de tu lista, pero sus compras y movimientos quedarán guardados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Conservar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Retirar entidad'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await widget.databaseService.retirarEntidadCredito(summary.entidad.id);
      if (mounted) Navigator.pop(context);
    } catch (error, stackTrace) {
      logOperationFailure(error, stackTrace, operation: 'retirar una entidad');
      _showMessage(_creditError(error, 'retirar la entidad'));
    }
  }

  void _viewAssociatedDebts() {
    final entityId = widget.initialEntity.id;
    Navigator.pop(context);
    widget.onViewDebts?.call(entityId);
  }

  void _showMessage(String message, {bool success = false}) {
    showCatMessage(context, message, isSuccess: success);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de crédito')),
      body: SafeArea(
        child: FutureBuilder<_CreditEntityData>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _CreditError(onRetry: _reload);
            }
            if (!snapshot.hasData) return const _CreditLoading();
            final data = snapshot.data!;
            final summary = data.summary;
            final usedRatio = summary.entidad.cupoAprobado <= 0
                ? 0.0
                : (summary.cupoUtilizado / summary.entidad.cupoAprobado).clamp(
                    0.0,
                    1.0,
                  );
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                16,
                AppSpacing.pageHorizontal,
                32,
              ),
              children: [
                AppPageHeader(
                  title: summary.entidad.nombre,
                  subtitle: 'Crédito de compra',
                  trailing: const Icon(
                    Icons.credit_card_rounded,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 22),
                _CreditLimitCard(
                  approved: summary.entidad.cupoAprobado,
                  used: summary.cupoUtilizado,
                  available: summary.cupoDisponible,
                  outstanding: summary.deudaPendiente,
                  progress: usedRatio,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: _isWorking
                          ? null
                          : () => _addPurchase(summary),
                      icon: const Icon(Icons.add_shopping_cart_rounded),
                      label: const Text('Nueva compra'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _editLimit(summary),
                      icon: const Icon(Icons.tune_rounded),
                      label: const Text('Actualizar cupo'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _viewAssociatedDebts,
                      icon: const Icon(Icons.account_balance_outlined),
                      label: const Text('Ver deudas asociadas'),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  'Compras y movimientos',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                if (data.purchases.isEmpty)
                  const _CreditEmptyMessage(
                    text: 'Todavía no hay compras en esta entidad.',
                  )
                else
                  ...data.purchases.map(
                    (purchase) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CreditPurchaseCard(
                        details: purchase,
                        accounts: data.digitalAccounts,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                Text(
                  'Cambios de cupo',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                if (data.limitChanges.isEmpty)
                  const _CreditEmptyMessage(
                    text: 'Todavía no hay cambios registrados.',
                  )
                else
                  ...data.limitChanges.map(
                    (change) => _LimitHistoryTile(change: change),
                  ),
                if (summary.deudaPendiente <= 1e-8) ...[
                  const SizedBox(height: 24),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: () => _retire(summary),
                      icon: const Icon(Icons.archive_outlined),
                      label: const Text('Retirar entidad'),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CreditEntityData {
  const _CreditEntityData({
    required this.summary,
    required this.purchases,
    required this.limitChanges,
    required this.digitalAccounts,
  });

  final CreditEntitySummary summary;
  final List<CreditPurchaseDetails> purchases;
  final List<CambioCupoCredito> limitChanges;
  final List<DigitalAccountBalance> digitalAccounts;
}

class _CreditOverview extends StatelessWidget {
  const _CreditOverview({
    required this.approved,
    required this.used,
    required this.available,
    required this.outstanding,
  });

  final double approved;
  final double used;
  final double available;
  final double outstanding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.card),
      decoration: AppCardDecorations.surfaceWithBorder(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen general',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _Metric(label: 'Cupo aprobado', amount: approved),
              _Metric(label: 'Cupo utilizado', amount: used),
              _Metric(label: 'Cupo disponible', amount: available),
              _Metric(label: 'Deuda pendiente', amount: outstanding),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreditLimitCard extends StatelessWidget {
  const _CreditLimitCard({
    required this.approved,
    required this.used,
    required this.available,
    required this.outstanding,
    required this.progress,
  });

  final double approved;
  final double used;
  final double available;
  final double outstanding;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.card),
      decoration: AppCardDecorations.surfaceWithBorder(
        borderColor: AppColors.primary.withValues(alpha: 0.45),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 18,
            runSpacing: 14,
            children: [
              _Metric(label: 'Cupo aprobado', amount: approved),
              _Metric(label: 'Cupo utilizado', amount: used),
              _Metric(label: 'Cupo disponible', amount: available),
              _Metric(label: 'Deuda pendiente', amount: outstanding),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceRaised,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(progress * 100).round()}% del cupo utilizado',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _CreditEntityCard extends StatelessWidget {
  const _CreditEntityCard({required this.summary, required this.onTap});

  final CreditEntitySummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final approved = summary.entidad.cupoAprobado;
    final progress = approved <= 0
        ? 0.0
        : (summary.cupoUtilizado / approved).clamp(0.0, 1.0);
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.medium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.medium),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.card),
          decoration: AppCardDecorations.surfaceWithBorder(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.credit_card_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      summary.entidad.nombre,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 20,
                runSpacing: 10,
                children: [
                  _Metric(label: 'Aprobado', amount: approved),
                  _Metric(label: 'Utilizado', amount: summary.cupoUtilizado),
                  _Metric(label: 'Disponible', amount: summary.cupoDisponible),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  backgroundColor: AppColors.surfaceRaised,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Deuda pendiente: ${formatMoney(summary.deudaPendiente)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.amount});

  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 120, maxWidth: 190),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            formatMoney(amount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _CreditPurchaseCard extends StatelessWidget {
  const _CreditPurchaseCard({required this.details, required this.accounts});

  final CreditPurchaseDetails details;
  final List<DigitalAccountBalance> accounts;

  @override
  Widget build(BuildContext context) {
    final purchase = details.compra;
    final totalPaid = purchase.monto - details.deudaPendiente;
    return ExpansionTile(
      key: ValueKey('credit-purchase-${purchase.id}'),
      tilePadding: const EdgeInsets.symmetric(horizontal: 14),
      childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.outline.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(AppRadii.medium),
      ),
      collapsedShape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.outline.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(AppRadii.medium),
      ),
      backgroundColor: AppColors.surface,
      collapsedBackgroundColor: AppColors.surface,
      title: Text(purchase.descripcion, maxLines: 2),
      subtitle: Text(
        '${formatMoney(purchase.monto)} · ${_formatDate(purchase.fecha)}',
      ),
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              Text('Categoría: ${purchase.categoria}'),
              Text('Pagado: ${formatMoney(totalPaid)}'),
              Text('Pendiente: ${formatMoney(details.deudaPendiente)}'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        for (final installment in details.cuotas)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 14,
              child: Text('${installment.numero}'),
            ),
            title: Text(formatMoney(installment.monto)),
            trailing: Text(_formatDate(installment.vencimiento)),
          ),
        if (details.pagos.isNotEmpty) ...[
          const Divider(),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              'Pagos realizados',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          for (final payment in details.pagos)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle_outline_rounded),
              title: Text(formatMoney(payment.monto)),
              subtitle: Text(_paymentSourceLabel(payment, accounts)),
              trailing: Text(_formatDate(payment.fecha)),
            ),
        ],
      ],
    );
  }
}

class _LimitHistoryTile extends StatelessWidget {
  const _LimitHistoryTile({required this.change});

  final CambioCupoCredito change;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: const Icon(Icons.history_rounded, color: AppColors.primary),
      title: Text(
        '${formatMoney(change.cupoAnterior)}  →  ${formatMoney(change.cupoNuevo)}',
      ),
      subtitle: Text(_formatDate(change.fecha)),
    );
  }
}

class _CreditEntityDraft {
  const _CreditEntityDraft({required this.name, required this.limit});

  final String name;
  final double limit;
}

class _CreditEntityFormSheet extends StatefulWidget {
  const _CreditEntityFormSheet();

  @override
  State<_CreditEntityFormSheet> createState() => _CreditEntityFormSheetState();
}

class _CreditEntityFormSheetState extends State<_CreditEntityFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _limitController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _CreditEntityDraft(
        name: _nameController.text.trim(),
        limit: parseMoney(_limitController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _SheetFrame(
    title: 'Agregar entidad',
    child: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            key: const ValueKey('credit-entity-name'),
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nombre de la entidad',
              hintText: 'Ej. Addi',
              prefixIcon: Icon(Icons.storefront_outlined),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Escribe el nombre de la entidad.'
                : null,
          ),
          const SizedBox(height: 14),
          _MoneyField(
            key: const ValueKey('credit-entity-limit'),
            controller: _limitController,
            label: 'Cupo aprobado',
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              child: const Text('Guardar entidad'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _CreditLimitFormSheet extends StatefulWidget {
  const _CreditLimitFormSheet({required this.summary});

  final CreditEntitySummary summary;

  @override
  State<_CreditLimitFormSheet> createState() => _CreditLimitFormSheetState();
}

class _CreditLimitFormSheetState extends State<_CreditLimitFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: _moneyInput(widget.summary.entidad.cupoAprobado),
    );
    _controller.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, parseMoney(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    final parsed = tryParseMoney(_controller.text);
    final available = parsed == null
        ? null
        : parsed - widget.summary.cupoUtilizado;
    return _SheetFrame(
      title: 'Actualizar cupo',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cupo aprobado actual: '
              '${formatMoney(widget.summary.entidad.cupoAprobado)}',
            ),
            const SizedBox(height: 6),
            Text(
              'Cupo utilizado: ${formatMoney(widget.summary.cupoUtilizado)}',
            ),
            const SizedBox(height: 14),
            _MoneyField(
              key: const ValueKey('credit-new-limit'),
              controller: _controller,
              label: 'Nuevo cupo aprobado',
              validator: (value) {
                final amount = tryParseMoney(value);
                if (amount == null || amount <= 0) {
                  return 'Escribe un cupo mayor que cero.';
                }
                if (amount + 1e-8 < widget.summary.cupoUtilizado) {
                  return 'No puede ser menor al cupo utilizado.';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            Text(
              'Nuevo cupo disponible: '
              '${available == null ? '—' : formatMoney(available)}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text('Fecha del cambio: ${_formatDate(DateTime.now())}'),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: const Text('Guardar nuevo cupo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreditPurchaseDraft {
  const _CreditPurchaseDraft({
    required this.description,
    required this.amount,
    required this.category,
    required this.date,
    required this.installmentCount,
    required this.installmentAmount,
    required this.firstDueDate,
  });

  final String description;
  final double amount;
  final String category;
  final DateTime date;
  final int installmentCount;
  final double installmentAmount;
  final DateTime firstDueDate;
}

class _CreditPurchaseFormSheet extends StatefulWidget {
  const _CreditPurchaseFormSheet({
    required this.categories,
    required this.available,
  });

  final List<String> categories;
  final double available;

  @override
  State<_CreditPurchaseFormSheet> createState() =>
      _CreditPurchaseFormSheetState();
}

class _CreditPurchaseFormSheetState extends State<_CreditPurchaseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _installmentController = TextEditingController();
  final _countController = TextEditingController(text: '1');
  late DateTime _date;
  late DateTime _firstDueDate;
  String? _category;
  bool _installmentEdited = false;

  @override
  void initState() {
    super.initState();
    _date = DateTime.now();
    final nextMonth = DateTime(_date.year, _date.month + 1, 1);
    _firstDueDate = DateTime(
      nextMonth.year,
      nextMonth.month,
      math.min(_date.day, DateTime(nextMonth.year, nextMonth.month + 1, 0).day),
    );
    _amountController.addListener(_syncAutoInstallment);
    _countController.addListener(_syncAutoInstallment);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController
      ..removeListener(_syncAutoInstallment)
      ..dispose();
    _installmentController.dispose();
    _countController
      ..removeListener(_syncAutoInstallment)
      ..dispose();
    super.dispose();
  }

  int get _count => int.tryParse(_countController.text.trim()) ?? 0;

  void _syncAutoInstallment() {
    if (_installmentEdited) return;
    final amount = tryParseMoney(_amountController.text);
    final count = _count;
    if (amount == null || amount <= 0 || count < 1) {
      _installmentController.clear();
    } else {
      final cents = (amount * 100).round();
      final installmentCents = (cents / count).floor();
      _installmentController.text = _moneyInput(installmentCents / 100);
    }
    if (mounted) setState(() {});
  }

  Future<void> _pickDate({required bool forDueDate}) async {
    final initial = forDueDate ? _firstDueDate : _date;
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected == null) return;
    setState(() {
      if (forDueDate) {
        _firstDueDate = selected;
      } else {
        _date = selected;
      }
    });
  }

  Future<void> _pickCategory() async {
    final category = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              'Elige una categoría',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          for (final option in widget.categories)
            ListTile(
              title: Text(option),
              trailing: option == _category ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(context, option),
            ),
        ],
      ),
    );
    if (category != null) setState(() => _category = category);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final amount = parseMoney(_amountController.text);
    final count = _count;
    final installment = parseMoney(_installmentController.text);
    final lastCents =
        (amount * 100).round() - (installment * 100).round() * (count - 1);
    if (lastCents < 1) {
      _formKey.currentState!.validate();
      return;
    }
    Navigator.pop(
      context,
      _CreditPurchaseDraft(
        description: _descriptionController.text.trim(),
        amount: amount,
        category: _category!,
        date: _date,
        installmentCount: count,
        installmentAmount: installment,
        firstDueDate: _firstDueDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _SheetFrame(
    title: 'Nueva compra',
    child: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            key: const ValueKey('credit-purchase-description'),
            controller: _descriptionController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Descripción',
              hintText: '¿Qué compraste?',
              prefixIcon: Icon(Icons.shopping_bag_outlined),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Escribe una descripción.'
                : null,
          ),
          const SizedBox(height: 12),
          _MoneyField(
            key: const ValueKey('credit-purchase-amount'),
            controller: _amountController,
            label: 'Valor de la compra',
            validator: (value) {
              final amount = tryParseMoney(value);
              if (amount == null || amount <= 0) {
                return 'Escribe un valor mayor que cero.';
              }
              if (amount > widget.available + 1e-8) {
                return 'No hay suficiente cupo. '
                    '${formatMoney(widget.available)} disponibles.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          FormField<String>(
            validator: (_) => _category == null ? 'Elige una categoría.' : null,
            builder: (field) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OutlinedButton.icon(
                  key: const ValueKey('credit-purchase-category'),
                  onPressed: _pickCategory,
                  icon: const Icon(Icons.category_outlined),
                  label: Text(_category ?? 'Elegir categoría'),
                ),
                if (field.hasError)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12, top: 4),
                      child: Text(
                        field.errorText!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _DateButton(
            label: 'Fecha de compra',
            date: _date,
            onPressed: () => _pickDate(forDueDate: false),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey('credit-purchase-count'),
            controller: _countController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Número de cuotas',
              prefixIcon: Icon(Icons.format_list_numbered_rounded),
            ),
            validator: (value) {
              final count = int.tryParse(value ?? '');
              if (count == null || count < 1 || count > 600) {
                return 'Indica entre 1 y 600 cuotas.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          _MoneyField(
            key: const ValueKey('credit-purchase-installment'),
            controller: _installmentController,
            label: 'Valor de cada cuota',
            onChanged: (_) => _installmentEdited = true,
            validator: (value) {
              final installment = tryParseMoney(value);
              final amount = tryParseMoney(_amountController.text);
              final count = _count;
              if (installment == null || installment <= 0) {
                return 'Escribe un valor de cuota mayor que cero.';
              }
              if (amount != null &&
                  count > 0 &&
                  (amount * 100).round() -
                          (installment * 100).round() * (count - 1) <
                      1) {
                return 'Las primeras cuotas superan el valor de la compra.';
              }
              return null;
            },
          ),
          const SizedBox(height: 6),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              'La última cuota se ajustará para completar el total.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 12),
          _DateButton(
            label: 'Vencimiento de la primera cuota',
            date: _firstDueDate,
            onPressed: () => _pickDate(forDueDate: true),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              child: const Text('Guardar compra'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _MoneyField extends StatelessWidget {
  const _MoneyField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: const [ThousandsInputFormatter()],
    onChanged: onChanged,
    decoration: InputDecoration(
      labelText: label,
      prefixText: '\$ ',
      prefixIcon: const Icon(Icons.payments_outlined),
    ),
    validator:
        validator ??
        (value) {
          final amount = tryParseMoney(value);
          return amount == null || amount <= 0
              ? 'Escribe un valor mayor que cero.'
              : null;
        },
  );
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.date,
    required this.onPressed,
  });

  final String label;
  final DateTime date;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.calendar_month_rounded),
      label: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text('$label: ${_formatDate(date)}'),
      ),
    ),
  );
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(22, 22, 22, 22 + bottomInset),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 18),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _CreditEmpty extends StatelessWidget {
  const _CreditEmpty({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 18),
      child: Column(
        children: [
          const AnimatedCat(
            asset: CatAssets.vacio,
            label: 'Gato esperando para organizar tus créditos',
            width: 132,
            height: 104,
          ),
          const SizedBox(height: 12),
          Text(
            'Todavía no hay entidades registradas.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega una entidad para empezar a organizar tus compras.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Agregar entidad'),
          ),
        ],
      ),
    ),
  );
}

class _CreditEmptyMessage extends StatelessWidget {
  const _CreditEmptyMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: AppCardDecorations.surface,
    child: Text(text, textAlign: TextAlign.center),
  );
}

class _CreditLoading extends StatelessWidget {
  const _CreditLoading();

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class _CreditError extends StatelessWidget {
  const _CreditError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 38),
          const SizedBox(height: 12),
          const Text('No pudimos cargar tus créditos.'),
          TextButton(
            onPressed: onRetry,
            child: const Text('Intentar de nuevo'),
          ),
        ],
      ),
    ),
  );
}

String _creditError(Object error, String action) {
  final cause = error is DatabaseServiceException ? error.causa : error;
  final message = cause.toString().toLowerCase();
  if (message.contains('cupo') && message.contains('disponible')) {
    return 'No hay suficiente cupo disponible. Revisa el cupo de la entidad.';
  }
  if (message.contains('menor al cupo utilizado')) {
    return 'El nuevo cupo no puede ser menor al que ya utilizaste.';
  }
  if (message.contains('cuotas') || message.contains('valor de la cuota')) {
    return 'Revisa el número y el valor de las cuotas.';
  }
  return friendlyOperationError(error, action: action);
}

String _formatDate(DateTime date) => formatSpanishLongDate(date);

String _moneyInput(double value) => value.toStringAsFixed(2);

String _paymentSourceLabel(
  PagosDeudaData payment,
  List<DigitalAccountBalance> accounts,
) {
  for (final account in accounts) {
    if (account.account.id == payment.cuentaDigitalId) {
      return account.account.nombre;
    }
  }
  return MoneyMedium.fromStorage(payment.medio)?.label ??
      'Medio sin clasificar';
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../../database/app_database.dart';
import '../../models/money_medium.dart';
import '../../models/subscription.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/money_format.dart';
import '../../utils/user_messages.dart';
import '../../widgets/cat_illustration.dart';
import '../../widgets/money_medium_selector.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key, required this.databaseService});

  final DatabaseService databaseService;

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  List<Suscripcion> _subscriptions = const [];
  List<DigitalAccountBalance> _digitalAccounts = const [];
  Object? _loadError;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    unawaited(_refreshSubscriptions());
  }

  Future<List<Suscripcion>> _loadSubscriptions() {
    return runWithLoggedErrors(
      'cargar suscripciones',
      widget.databaseService.obtenerSuscripciones,
    );
  }

  Future<void> _refreshSubscriptions() async {
    try {
      final values = await Future.wait<Object>([
        _loadSubscriptions(),
        runWithLoggedErrors(
          'cargar cuentas para suscripciones',
          widget.databaseService.obtenerCuentasDigitales,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _subscriptions = values[0] as List<Suscripcion>;
        _digitalAccounts = values[1] as List<DigitalAccountBalance>;
        _loadError = null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _isLoading = false;
      });
    }
  }

  Future<void> _editSubscription([Suscripcion? subscription]) async {
    if (_isSaving) return;
    final draft = await showModalBottomSheet<_SubscriptionDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      builder: (context) => _SubscriptionForm(
        subscription: subscription,
        accounts: _digitalAccounts.map((item) => item.account).toList(),
      ),
    );
    if (draft == null || !mounted) return;
    setState(() => _isSaving = true);
    try {
      if (subscription == null) {
        await widget.databaseService.agregarSuscripcion(
          nombre: draft.name,
          precio: draft.amount,
          proximoPago: draft.nextPayment,
          frecuencia: draft.frequency,
          medio: draft.medium,
          cuentaDigitalId: draft.digitalAccountId,
        );
      } else {
        await widget.databaseService.actualizarSuscripcion(
          id: subscription.id,
          nombre: draft.name,
          precio: draft.amount,
          proximoPago: draft.nextPayment,
          frecuencia: draft.frequency,
          medio: draft.medium,
          cuentaDigitalId: draft.digitalAccountId,
        );
      }
      if (!mounted) return;
      await _refreshSubscriptions();
      _showMessage(
        subscription == null
            ? 'Suscripción guardada.'
            : 'Suscripción actualizada.',
        success: true,
      );
    } catch (error, stackTrace) {
      logOperationFailure(
        error,
        stackTrace,
        operation: subscription == null
            ? 'guardar una suscripción'
            : 'actualizar una suscripción',
      );
      if (mounted) {
        _showMessage(
          friendlyOperationError(
            error,
            action: subscription == null
                ? 'guardar la suscripción'
                : 'actualizar la suscripción',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _cancelSubscription(Suscripcion subscription) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cancelar esta suscripción?'),
        content: Text(
          'Se detendrán los próximos recordatorios de ${subscription.nombre}. '
          'Su historial de pagos y gastos se conservará.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar suscripción'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.databaseService.cancelarSuscripcion(subscription.id);
      if (!mounted) return;
      await _refreshSubscriptions();
      _showMessage(
        'Suscripción cancelada. Su historial sigue guardado.',
        success: true,
      );
    } catch (error, stackTrace) {
      logOperationFailure(
        error,
        stackTrace,
        operation: 'cancelar una suscripción',
      );
      if (mounted) {
        _showMessage(
          friendlyOperationError(error, action: 'cancelar la suscripción'),
        );
      }
    }
  }

  Future<void> _reactivateSubscription(Suscripcion subscription) async {
    try {
      await widget.databaseService.reactivarSuscripcion(subscription.id);
      if (!mounted) return;
      await _refreshSubscriptions();
      _showMessage('Suscripción reactivada.', success: true);
    } catch (error, stackTrace) {
      logOperationFailure(
        error,
        stackTrace,
        operation: 'reactivar una suscripción',
      );
      if (mounted) {
        _showMessage(
          friendlyOperationError(error, action: 'reactivar la suscripción'),
        );
      }
    }
  }

  Future<void> _paySubscription(Suscripcion subscription) async {
    if (_isSaving || !subscription.activa) return;
    final draft = await showDialog<_SubscriptionPaymentDraft>(
      context: context,
      builder: (context) => _SubscriptionPaymentConfirmation(
        subscription: subscription,
        accounts: _digitalAccounts.map((item) => item.account).toList(),
      ),
    );
    if (draft == null || !mounted) return;
    setState(() => _isSaving = true);
    try {
      await widget.databaseService.pagarSuscripcion(
        suscripcionId: subscription.id,
        periodoEsperado: subscription.proximoPago,
        medio: draft.medium,
        cuentaDigitalId: draft.digitalAccountId,
        fecha: DateTime.now(),
      );
      if (!mounted) return;
      await _refreshSubscriptions();
      _showMessage(
        '¡Listo! El pago quedó registrado en tus gastos.',
        success: true,
      );
    } catch (error, stackTrace) {
      logOperationFailure(
        error,
        stackTrace,
        operation: 'pagar una suscripción',
      );
      if (mounted) {
        _showMessage(
          friendlyOperationError(error, action: 'pagar la suscripción'),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _showPaymentHistory(Suscripcion subscription) async {
    try {
      final payments = await widget.databaseService.obtenerPagosSuscripcion(
        subscription.id,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Pagos de ${subscription.nombre}'),
          content: SizedBox(
            width: 420,
            child: payments.isEmpty
                ? const Text('Todavía no hay pagos registrados.')
                : ListView(
                    shrinkWrap: true,
                    children: [
                      for (final payment in payments)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(formatMoney(payment.monto)),
                          subtitle: Text(
                            '${_formatDate(payment.fecha)} · '
                            '${MoneyMedium.fromStorage(payment.medio)?.label ?? 'Medio no disponible'}',
                          ),
                        ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (error, stackTrace) {
      logOperationFailure(
        error,
        stackTrace,
        operation: 'cargar historial de pagos',
      );
      if (mounted) {
        _showMessage(
          friendlyOperationError(error, action: 'cargar el historial'),
        );
      }
    }
  }

  void _showMessage(String message, {bool success = false}) {
    showCatMessage(
      context,
      message,
      isSuccess: success,
      successAsset: success ? CatAssets.exitoso : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final padding = constraints.maxWidth < 420 ? 20.0 : 36.0;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(padding, 26, padding, 36),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
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
                                'Suscripciones',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Ten a la vista tus cobros recurrentes.',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const AnimatedCat(
                          asset: CatAssets.gastos,
                          label: 'Gato organizando gastos',
                          width: 78,
                          height: 64,
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    if (_loadError != null)
                      _SubscriptionsError(
                        onRetry: () {
                          setState(() {
                            _isLoading = true;
                            _loadError = null;
                          });
                          unawaited(_refreshSubscriptions());
                        },
                      )
                    else if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(28),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else
                      _buildSubscriptions(_subscriptions),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubscriptions(List<Suscripcion> subscriptions) {
    final monthlyTotal = subscriptions.fold<double>(0, (total, item) {
      if (!item.activa) return total;
      final frequency = SubscriptionFrequency.fromStorage(item.frecuencia);
      if (frequency == null) return total;
      return total + frequency.monthlyCost(item.precio);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SubscriptionSummary(
          monthlyTotal: monthlyTotal,
          annualTotal: monthlyTotal * 12,
          count: subscriptions.where((item) => item.activa).length,
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const ValueKey('subscription-add'),
            onPressed: _isSaving ? null : () => _editSubscription(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Agregar suscripción'),
          ),
        ),
        const SizedBox(height: 14),
        if (subscriptions.isEmpty)
          _SubscriptionsEmpty(onAdd: () => _editSubscription())
        else
          for (final subscription in subscriptions)
            _SubscriptionCard(
              subscription: subscription,
              accountName: _accountName(subscription.cuentaDigitalId),
              onEdit: () => _editSubscription(subscription),
              onPay: () => _paySubscription(subscription),
              onCancel: () => _cancelSubscription(subscription),
              onReactivate: () => _reactivateSubscription(subscription),
              onHistory: () => _showPaymentHistory(subscription),
            ),
        const SizedBox(height: 10),
        Text(
          'Los pagos solo se registran cuando confirmas la acción. No hay '
          'cobros automáticos.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  String? _accountName(int? id) {
    if (id == null) return null;
    for (final account in _digitalAccounts) {
      if (account.account.id == id) return account.account.nombre;
    }
    return null;
  }
}

class _SubscriptionSummary extends StatelessWidget {
  const _SubscriptionSummary({
    required this.monthlyTotal,
    required this.annualTotal,
    required this.count,
  });

  final double monthlyTotal;
  final double annualTotal;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: AppCardDecorations.featured,
      child: Wrap(
        spacing: 24,
        runSpacing: 18,
        children: [
          _SummaryAmount(
            label: 'Estimado mensual',
            amount: monthlyTotal,
            key: const ValueKey('subscription-monthly-total'),
          ),
          _SummaryAmount(
            label: 'Compromiso anual estimado',
            amount: annualTotal,
            key: const ValueKey('subscription-annual-total'),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Activas', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text('$count', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryAmount extends StatelessWidget {
  const _SummaryAmount({required this.label, required this.amount, super.key});

  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(
          formatMoney(amount),
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.subscription,
    required this.accountName,
    required this.onEdit,
    required this.onPay,
    required this.onCancel,
    required this.onReactivate,
    required this.onHistory,
  });

  final Suscripcion subscription;
  final String? accountName;
  final VoidCallback onEdit;
  final VoidCallback onPay;
  final VoidCallback onCancel;
  final VoidCallback onReactivate;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final frequency = SubscriptionFrequency.fromStorage(
      subscription.frecuencia,
    );
    final date = DateTime(
      subscription.proximoPago.year,
      subscription.proximoPago.month,
      subscription.proximoPago.day,
    );
    final daysUntil = date
        .difference(DateUtils.dateOnly(DateTime.now()))
        .inDays;
    final isSoon = subscription.activa && daysUntil <= 7;
    final dueLabel = !subscription.activa
        ? 'Suscripción cancelada'
        : daysUntil < 0
        ? 'Venció hace ${daysUntil.abs()} días'
        : daysUntil == 0
        ? 'Próximo cobro hoy'
        : daysUntil <= 7
        ? 'Próximo cobro en $daysUntil días'
        : 'Próximo cobro ${_formatDate(subscription.proximoPago)}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.autorenew_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    subscription.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Acciones de ${subscription.nombre}',
                  onSelected: (action) {
                    switch (action) {
                      case 'edit':
                        onEdit();
                      case 'cancel':
                        onCancel();
                      case 'reactivate':
                        onReactivate();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                    if (subscription.activa)
                      const PopupMenuItem(
                        value: 'cancel',
                        child: Text('Cancelar'),
                      )
                    else
                      const PopupMenuItem(
                        value: 'reactivate',
                        child: Text('Reactivar'),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              formatMoney(subscription.precio),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              '${frequency?.label ?? 'Frecuencia desconocida'} · '
              '${formatMoney(frequency?.monthlyCost(subscription.precio) ?? 0)} / mes',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            Text(
              [
                subscription.medio == null
                    ? 'Medio sin definir'
                    : 'Pago ${MoneyMedium.fromStorage(subscription.medio)?.label.toLowerCase()}',
                ?accountName,
                dueLabel,
              ].join(' · '),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSoon ? AppColors.primary : null,
                fontWeight: isSoon ? FontWeight.w700 : null,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (subscription.activa)
                  FilledButton.icon(
                    key: ValueKey('subscription-pay-${subscription.id}'),
                    onPressed: onPay,
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Pagar'),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: onReactivate,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reactivar'),
                  ),
                TextButton.icon(
                  onPressed: onHistory,
                  icon: const Icon(Icons.history_rounded),
                  label: const Text('Historial'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionsEmpty extends StatelessWidget {
  const _SubscriptionsEmpty({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: AppCardDecorations.surface,
      child: Column(
        children: [
          const AnimatedCat(
            asset: CatAssets.vacio,
            label: 'Gato esperando suscripciones',
            width: 122,
            height: 102,
          ),
          const SizedBox(height: 12),
          Text(
            'Todavía no tienes suscripciones.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Agrega tus cobros recurrentes y consulta cuánto representan '
            'al mes, sin registrarlos como gastos automáticamente.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Agregar la primera'),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionDraft {
  const _SubscriptionDraft({
    required this.name,
    required this.amount,
    required this.nextPayment,
    required this.frequency,
    required this.medium,
    required this.digitalAccountId,
  });

  final String name;
  final double amount;
  final DateTime nextPayment;
  final SubscriptionFrequency frequency;
  final MoneyMedium medium;
  final int? digitalAccountId;
}

class _SubscriptionForm extends StatefulWidget {
  const _SubscriptionForm({required this.accounts, this.subscription});

  final Suscripcion? subscription;
  final List<CuentasDigitale> accounts;

  @override
  State<_SubscriptionForm> createState() => _SubscriptionFormState();
}

class _SubscriptionFormState extends State<_SubscriptionForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late DateTime _nextPayment;
  late SubscriptionFrequency _frequency;
  MoneyMedium? _medium;
  int? _digitalAccountId;

  @override
  void initState() {
    super.initState();
    final subscription = widget.subscription;
    _nameController = TextEditingController(text: subscription?.nombre ?? '');
    _priceController = TextEditingController(
      text: subscription == null ? '' : formatAmount(subscription.precio),
    );
    _nextPayment =
        subscription?.proximoPago ??
        DateTime.now().add(const Duration(days: 1));
    _frequency =
        SubscriptionFrequency.fromStorage(subscription?.frecuencia) ??
        SubscriptionFrequency.monthly;
    _medium = MoneyMedium.fromStorage(subscription?.medio) ?? MoneyMedium.cash;
    _digitalAccountId = subscription?.cuentaDigitalId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _nextPayment,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Elige la fecha del próximo cobro',
    );
    if (date != null && mounted) setState(() => _nextPayment = date);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_medium == MoneyMedium.digital &&
        !widget.accounts.any((account) => account.id == _digitalAccountId)) {
      return;
    }
    final price = tryParseMoney(_priceController.text)!;
    Navigator.pop(
      context,
      _SubscriptionDraft(
        name: _nameController.text.trim(),
        amount: price,
        nextPayment: _nextPayment,
        frequency: _frequency,
        medium: _medium ?? MoneyMedium.cash,
        digitalAccountId: _digitalAccountId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(22, 22, 22, 24 + bottomInset),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.subscription == null
                    ? 'Nueva suscripción'
                    : 'Editar suscripción',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('subscription-name'),
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nombre del servicio',
                  hintText: 'Por ejemplo, música o streaming',
                ),
                validator: (value) => value?.trim().isEmpty == true
                    ? 'Escribe el nombre del servicio.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('subscription-price'),
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: const [ThousandsInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Precio por cobro',
                  prefixText: r'$ ',
                ),
                validator: (value) {
                  final amount = tryParseMoney(value);
                  return amount == null || amount <= 0
                      ? 'Escribe un precio mayor que cero.'
                      : null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<SubscriptionFrequency>(
                initialValue: _frequency,
                decoration: const InputDecoration(labelText: 'Frecuencia'),
                items: [
                  for (final frequency in SubscriptionFrequency.values)
                    DropdownMenuItem(
                      value: frequency,
                      child: Text(frequency.label),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _frequency = value);
                },
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _chooseDate,
                icon: const Icon(Icons.calendar_month_rounded),
                label: Text('Próximo pago · ${_formatDate(_nextPayment)}'),
              ),
              const SizedBox(height: 14),
              MoneyMediumSelector(
                selected: _medium,
                onChanged: (value) => setState(() => _medium = value),
                title: 'Medio de pago habitual',
              ),
              if (_medium == MoneyMedium.digital) ...[
                const SizedBox(height: 12),
                if (widget.accounts.isEmpty)
                  const Text(
                    'Agrega primero una cuenta digital en Configuración.',
                  )
                else
                  DigitalAccountSelector(
                    accounts: widget.accounts,
                    selectedId: _digitalAccountId,
                    onChanged: (id) => setState(() => _digitalAccountId = id),
                  ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed:
                      _medium == MoneyMedium.digital &&
                          !widget.accounts.any(
                            (account) => account.id == _digitalAccountId,
                          )
                      ? null
                      : _save,
                  child: Text(
                    widget.subscription == null ? 'Guardar' : 'Guardar cambios',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubscriptionPaymentDraft {
  const _SubscriptionPaymentDraft({
    required this.medium,
    required this.digitalAccountId,
  });

  final MoneyMedium medium;
  final int? digitalAccountId;
}

class _SubscriptionPaymentConfirmation extends StatefulWidget {
  const _SubscriptionPaymentConfirmation({
    required this.subscription,
    required this.accounts,
  });

  final Suscripcion subscription;
  final List<CuentasDigitale> accounts;

  @override
  State<_SubscriptionPaymentConfirmation> createState() =>
      _SubscriptionPaymentConfirmationState();
}

class _SubscriptionPaymentConfirmationState
    extends State<_SubscriptionPaymentConfirmation> {
  late MoneyMedium _medium;
  int? _accountId;

  @override
  void initState() {
    super.initState();
    _medium =
        MoneyMedium.fromStorage(widget.subscription.medio) ?? MoneyMedium.cash;
    _accountId = widget.subscription.cuentaDigitalId;
  }

  bool get _canConfirm =>
      _medium != MoneyMedium.digital ||
      widget.accounts.any((account) => account.id == _accountId);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Pagar ${widget.subscription.nombre}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatMoney(widget.subscription.precio),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Próximo pago · ${_formatDate(widget.subscription.proximoPago)}',
            ),
            const SizedBox(height: 16),
            MoneyMediumSelector(
              selected: _medium,
              title: '¿Desde dónde pagas?',
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _medium = value;
                    if (value != MoneyMedium.digital) _accountId = null;
                  });
                }
              },
            ),
            if (_medium == MoneyMedium.digital) ...[
              const SizedBox(height: 12),
              if (widget.accounts.isEmpty)
                const Text('Agrega una cuenta digital en Configuración.')
              else
                DigitalAccountSelector(
                  accounts: widget.accounts,
                  selectedId: _accountId,
                  onChanged: (id) => setState(() => _accountId = id),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Ahora no'),
        ),
        FilledButton(
          onPressed: _canConfirm
              ? () => Navigator.pop(
                  context,
                  _SubscriptionPaymentDraft(
                    medium: _medium,
                    digitalAccountId: _accountId,
                  ),
                )
              : null,
          child: const Text('Confirmar pago'),
        ),
      ],
    );
  }
}

class _SubscriptionsError extends StatelessWidget {
  const _SubscriptionsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _SubscriptionsEmptyState(
      icon: Icons.cloud_off_outlined,
      message: 'No pudimos cargar tus suscripciones.',
      action: TextButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Intentar de nuevo'),
      ),
    );
  }
}

class _SubscriptionsEmptyState extends StatelessWidget {
  const _SubscriptionsEmptyState({
    required this.icon,
    required this.message,
    required this.action,
  });

  final IconData icon;
  final String message;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(icon, size: 40, color: AppColors.primary),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            action,
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';

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
      final subscriptions = await _loadSubscriptions();
      if (!mounted) return;
      setState(() {
        _subscriptions = subscriptions;
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
      builder: (context) => _SubscriptionForm(subscription: subscription),
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
        );
      } else {
        await widget.databaseService.actualizarSuscripcion(
          id: subscription.id,
          nombre: draft.name,
          precio: draft.amount,
          proximoPago: draft.nextPayment,
          frecuencia: draft.frequency,
          medio: draft.medium,
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

  Future<void> _deleteSubscription(Suscripcion subscription) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar esta suscripción?'),
        content: Text(
          'Se eliminará ${subscription.nombre} de tu lista. '
          'No se registrará ni eliminará ningún gasto.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Conservar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.databaseService.eliminarSuscripcion(subscription.id);
      if (!mounted) return;
      await _refreshSubscriptions();
      _showMessage('Suscripción eliminada.', success: true);
    } catch (error, stackTrace) {
      logOperationFailure(
        error,
        stackTrace,
        operation: 'eliminar una suscripción',
      );
      if (mounted) {
        _showMessage(
          friendlyOperationError(error, action: 'eliminar la suscripción'),
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
          count: subscriptions.length,
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
              onEdit: () => _editSubscription(subscription),
              onDelete: () => _deleteSubscription(subscription),
            ),
        const SizedBox(height: 10),
        Text(
          'La fecha de cobro es un recordatorio. Los pagos no se registran '
          'automáticamente como gastos.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
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
    required this.onEdit,
    required this.onDelete,
  });

  final Suscripcion subscription;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
    final isSoon = daysUntil <= 7;
    final dueLabel = daysUntil < 0
        ? 'Venció hace ${daysUntil.abs()} días'
        : daysUntil == 0
        ? 'Próximo cobro hoy'
        : daysUntil <= 7
        ? 'Próximo cobro en $daysUntil días'
        : 'Próximo cobro ${_formatDate(subscription.proximoPago)}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subscription.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subscription.medio == null
                        ? 'Medio sin definir'
                        : 'Pago ${MoneyMedium.fromStorage(subscription.medio)?.label.toLowerCase()}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    dueLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isSoon ? AppColors.primary : null,
                      fontWeight: isSoon ? FontWeight.w700 : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatMoney(subscription.precio),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${frequency?.label ?? 'Frecuencia desconocida'} · '
                  '${formatMoney(subscription.precio)} por cobro'
                  ' · ${formatMoney(frequency?.monthlyCost(subscription.precio) ?? 0)} / mes',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            PopupMenuButton<String>(
              tooltip: 'Acciones de ${subscription.nombre}',
              onSelected: (action) => action == 'edit' ? onEdit() : onDelete(),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Editar')),
                PopupMenuItem(value: 'delete', child: Text('Eliminar')),
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
  });

  final String name;
  final double amount;
  final DateTime nextPayment;
  final SubscriptionFrequency frequency;
  final MoneyMedium? medium;
}

class _SubscriptionForm extends StatefulWidget {
  const _SubscriptionForm({this.subscription});

  final Suscripcion? subscription;

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
    _medium = MoneyMedium.fromStorage(subscription?.medio);
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
    final price = tryParseMoney(_priceController.text)!;
    Navigator.pop(
      context,
      _SubscriptionDraft(
        name: _nameController.text.trim(),
        amount: price,
        nextPayment: _nextPayment,
        frequency: _frequency,
        medium: _medium,
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
                title: 'Medio de pago habitual (opcional)',
                allowUnclassified: true,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
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

import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/money_medium.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';
import '../utils/money_format.dart';

class TransferMoneyDialog extends StatefulWidget {
  const TransferMoneyDialog({
    super.key,
    required this.accounts,
    required this.balances,
    this.transfer,
  });

  final List<DigitalAccountBalance> accounts;
  final AvailableBalanceBreakdown balances;
  final TransferenciasDineroData? transfer;

  @override
  State<TransferMoneyDialog> createState() => _TransferMoneyDialogState();
}

class _TransferMoneyDialogState extends State<TransferMoneyDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late final List<TransferEndpoint> _endpoints;
  late String _originKey;
  late String _destinationKey;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final accountsTotal = widget.accounts.fold<double>(
      0,
      (total, account) => total + account.balance,
    );
    _endpoints = [
      TransferEndpoint(
        key: 'cash',
        label: 'Efectivo',
        medium: MoneyMedium.cash,
      ),
      TransferEndpoint(
        key: 'digital-unassigned',
        label: 'Digital sin cuenta',
        medium: MoneyMedium.digital,
      ),
      for (final account in widget.accounts)
        TransferEndpoint(
          key: 'account-${account.account.id}',
          label: account.account.nombre,
          medium: MoneyMedium.digital,
          accountId: account.account.id,
        ),
    ];
    final transfer = widget.transfer;
    _originKey = _endpointKey(transfer?.medioOrigen, transfer?.cuentaOrigenId);
    _destinationKey = _endpointKey(
      transfer?.medioDestino,
      transfer?.cuentaDestinoId,
    );
    if (_originKey == _destinationKey) {
      _originKey = 'cash';
      _destinationKey = 'digital-unassigned';
    }
    _amountController = TextEditingController(
      text: transfer == null ? '' : formatAmount(transfer.monto),
    )..addListener(_refresh);
    _noteController = TextEditingController(text: transfer?.nota ?? '');
    _date = transfer?.fecha ?? DateTime.now();
    _unassignedDigitalBalance = widget.balances.digital - accountsTotal;
  }

  late final double _unassignedDigitalBalance;

  String _endpointKey(String? medium, int? accountId) {
    if (accountId != null &&
        _endpoints.any((item) => item.accountId == accountId)) {
      return 'account-$accountId';
    }
    return medium == MoneyMedium.cash.storageValue
        ? 'cash'
        : 'digital-unassigned';
  }

  TransferEndpoint _endpoint(String key) =>
      _endpoints.firstWhere((item) => item.key == key);

  double _balanceFor(TransferEndpoint endpoint) {
    if (endpoint.medium == MoneyMedium.cash) return widget.balances.cash;
    if (endpoint.accountId != null) {
      return widget.accounts
          .firstWhere((item) => item.account.id == endpoint.accountId)
          .balance;
    }
    return _unassignedDigitalBalance;
  }

  double _balanceBefore(TransferEndpoint endpoint) {
    var balance = _balanceFor(endpoint);
    final transfer = widget.transfer;
    if (transfer == null) return balance;
    if (_sameAsTransferOrigin(endpoint, transfer)) balance += transfer.monto;
    if (_sameAsTransferDestination(endpoint, transfer)) {
      balance -= transfer.monto;
    }
    return balance;
  }

  bool _sameAsTransferOrigin(
    TransferEndpoint endpoint,
    TransferenciasDineroData transfer,
  ) =>
      endpoint.medium.storageValue == transfer.medioOrigen &&
      endpoint.accountId == transfer.cuentaOrigenId;

  bool _sameAsTransferDestination(
    TransferEndpoint endpoint,
    TransferenciasDineroData transfer,
  ) =>
      endpoint.medium.storageValue == transfer.medioDestino &&
      endpoint.accountId == transfer.cuentaDestinoId;

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _amountController
      ..removeListener(_refresh)
      ..dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null && mounted) setState(() => _date = date);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      TransferMoneyDraft(
        origin: _endpoint(_originKey),
        destination: _endpoint(_destinationKey),
        amount: parseMoney(_amountController.text),
        date: _date,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final origin = _endpoint(_originKey);
    final destination = _endpoint(_destinationKey);
    final amount = tryParseMoney(_amountController.text);
    final originBalance = _balanceBefore(origin);
    final destinationBalance = _balanceBefore(destination);
    return AlertDialog(
      title: Text(
        widget.transfer == null ? 'Transferir dinero' : 'Editar transferencia',
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 440,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _endpointDropdown(
                  label: 'Desde',
                  value: _originKey,
                  excludedKey: null,
                  onChanged: (value) => setState(() {
                    _originKey = value;
                    if (_destinationKey == value) {
                      _destinationKey = _endpoints
                          .firstWhere((endpoint) => endpoint.key != value)
                          .key;
                    }
                  }),
                ),
                const SizedBox(height: 12),
                _endpointDropdown(
                  label: 'Hacia',
                  value: _destinationKey,
                  excludedKey: _originKey,
                  onChanged: (value) => setState(() => _destinationKey = value),
                  validator: (value) => value == _originKey
                      ? 'Elige un destino distinto al origen.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('transfer-amount'),
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: const [ThousandsInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Monto',
                    prefixText: r'$ ',
                  ),
                  validator: (value) {
                    final parsedAmount = tryParseMoney(value);
                    if (parsedAmount == null || parsedAmount <= 0) {
                      return 'Escribe un monto mayor que cero.';
                    }
                    if (parsedAmount > originBalance + 1e-8) {
                      return 'No alcanza el saldo de ${origin.label} '
                          '(${formatMoney(originBalance)} disponibles).';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _TransferPreview(
                  origin: origin,
                  destination: destination,
                  amount: amount,
                  originBalance: originBalance,
                  destinationBalance: destinationBalance,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Nota (opcional)',
                  ),
                ),
                TextButton.icon(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(formatSpanishLongDate(_date)),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Confirmar transferencia'),
        ),
      ],
    );
  }

  Widget _endpointDropdown({
    required String label,
    required String value,
    required String? excludedKey,
    required ValueChanged<String> onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final endpoint in _endpoints)
          if (endpoint.key != excludedKey)
            DropdownMenuItem(
              value: endpoint.key,
              child: Text(
                '${endpoint.label} · ${formatMoney(_balanceBefore(endpoint))}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
      ],
      validator: validator,
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
    );
  }
}

class _TransferPreview extends StatelessWidget {
  const _TransferPreview({
    required this.origin,
    required this.destination,
    required this.amount,
    required this.originBalance,
    required this.destinationBalance,
  });

  final TransferEndpoint origin;
  final TransferEndpoint destination;
  final double? amount;
  final double originBalance;
  final double destinationBalance;

  @override
  Widget build(BuildContext context) {
    final transferAmount = amount ?? 0;
    return Container(
      key: const ValueKey('transfer-preview'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadii.small),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Así quedarán tus saldos',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          _PreviewBalanceLine(
            name: origin.label,
            before: originBalance,
            after: originBalance - transferAmount,
          ),
          const SizedBox(height: 4),
          _PreviewBalanceLine(
            name: destination.label,
            before: destinationBalance,
            after: destinationBalance + transferAmount,
          ),
        ],
      ),
    );
  }
}

class _PreviewBalanceLine extends StatelessWidget {
  const _PreviewBalanceLine({
    required this.name,
    required this.before,
    required this.after,
  });

  final String name;
  final double before;
  final double after;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          '${formatMoney(before)}  →  ${formatMoney(after)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class TransferEndpoint {
  const TransferEndpoint({
    required this.key,
    required this.label,
    required this.medium,
    this.accountId,
  });

  final String key;
  final String label;
  final MoneyMedium medium;
  final int? accountId;
}

class TransferMoneyDraft {
  const TransferMoneyDraft({
    required this.origin,
    required this.destination,
    required this.amount,
    required this.date,
    required this.note,
  });

  final TransferEndpoint origin;
  final TransferEndpoint destination;
  final double amount;
  final DateTime date;
  final String? note;
}

import 'package:flutter/material.dart';

import '../models/money_medium.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../utils/money_format.dart';

class MoneySourceSelector extends StatelessWidget {
  const MoneySourceSelector({
    super.key,
    required this.selectedMedium,
    required this.selectedAccountId,
    required this.digitalAccounts,
    required this.cashBalance,
    required this.onChanged,
    required this.title,
    this.amount,
    this.digitalWithoutAccount = 0,
    this.cashUnclassifiedAllowance = 0,
    this.allowUnassignedDigital = false,
    this.allowUnclassified = false,
  });

  final MoneyMedium? selectedMedium;
  final int? selectedAccountId;
  final List<DigitalAccountBalance> digitalAccounts;
  final double cashBalance;
  final String title;
  final double? amount;
  final double digitalWithoutAccount;
  final double cashUnclassifiedAllowance;
  final bool allowUnassignedDigital;
  final bool allowUnclassified;
  final void Function(MoneyMedium? medium, int? accountId) onChanged;

  double get _remainingAmount => amount ?? 0;

  @override
  Widget build(BuildContext context) {
    final selectedBalance = _selectedBalance;
    final isInsufficient =
        amount != null &&
        selectedBalance != null &&
        amount! > selectedBalance + 1e-8;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        _SourceOption(
          key: const ValueKey('money-source-cash'),
          name: cashUnclassifiedAllowance > 1e-8
              ? 'Efectivo + sin asignar'
              : 'Efectivo',
          balance: cashBalance + cashUnclassifiedAllowance,
          amount: amount,
          icon: Icons.payments_outlined,
          selected: selectedMedium == MoneyMedium.cash,
          onTap: () => onChanged(MoneyMedium.cash, null),
        ),
        for (final account in digitalAccounts) ...[
          const SizedBox(height: 8),
          _SourceOption(
            key: ValueKey('money-source-account-${account.account.id}'),
            name: account.account.nombre,
            balance: account.balance,
            amount: amount,
            icon: Icons.account_balance_wallet_outlined,
            selected:
                selectedMedium == MoneyMedium.digital &&
                selectedAccountId == account.account.id,
            onTap: () => onChanged(MoneyMedium.digital, account.account.id),
          ),
        ],
        if (allowUnassignedDigital) ...[
          const SizedBox(height: 8),
          _SourceOption(
            key: const ValueKey('money-source-unassigned-digital'),
            name: 'Digital sin cuenta',
            balance: digitalWithoutAccount,
            amount: amount,
            icon: Icons.account_balance_wallet_outlined,
            selected:
                selectedMedium == MoneyMedium.digital &&
                selectedAccountId == null,
            onTap: () => onChanged(MoneyMedium.digital, null),
          ),
        ],
        if (allowUnclassified) ...[
          const SizedBox(height: 8),
          _SourceOption(
            key: const ValueKey('money-source-unclassified'),
            name: 'Sin clasificar',
            balance: null,
            amount: null,
            icon: Icons.help_outline_rounded,
            selected: selectedMedium == null,
            onTap: () => onChanged(null, null),
          ),
        ],
        if (digitalAccounts.isEmpty && !allowUnassignedDigital)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Agrega una cuenta digital desde Configuración para seleccionarla aquí.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (isInsufficient) ...[
          const SizedBox(height: 8),
          Text(
            'No alcanza el saldo de esta opción. '
            'Disponible: ${formatMoney(selectedBalance)}.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.negative),
          ),
        ] else if (selectedBalance != null && amount != null) ...[
          const SizedBox(height: 8),
          Text(
            'Te quedarán: '
            '${formatMoney(selectedBalance - _remainingAmount)}',
            key: const ValueKey('money-source-remaining'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }

  double? get _selectedBalance {
    if (selectedMedium == MoneyMedium.cash) {
      return cashBalance + cashUnclassifiedAllowance;
    }
    if (selectedMedium != MoneyMedium.digital) return null;
    if (selectedAccountId == null) {
      return allowUnassignedDigital ? digitalWithoutAccount : null;
    }
    for (final account in digitalAccounts) {
      if (account.account.id == selectedAccountId) return account.balance;
    }
    return null;
  }
}

class _SourceOption extends StatelessWidget {
  const _SourceOption({
    super.key,
    required this.name,
    required this.balance,
    required this.amount,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final double? balance;
  final double? amount;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final insufficient =
        amount != null && balance != null && amount! > balance! + 1e-8;
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.12)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.small),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.small),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.small),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.outline,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? AppColors.accent : AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(name),
                    if (balance != null)
                      Text(
                        '${formatMoney(balance!)} disponibles',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: insufficient
                              ? AppColors.negative
                              : AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 6),
                const Icon(Icons.check_circle, color: AppColors.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

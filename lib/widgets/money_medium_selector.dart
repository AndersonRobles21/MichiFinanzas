import 'package:flutter/material.dart';

import '../models/money_medium.dart';

class MoneyMediumSelector extends StatelessWidget {
  const MoneyMediumSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.title,
    this.allowUnclassified = false,
  });

  final MoneyMedium? selected;
  final ValueChanged<MoneyMedium?> onChanged;
  final String title;
  final bool allowUnclassified;

  @override
  Widget build(BuildContext context) {
    final selectedValue = selected?.storageValue ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: [
            if (allowUnclassified)
              const ButtonSegment<String>(
                value: '',
                label: Text('Sin clasificar'),
              ),
            const ButtonSegment<String>(
              value: 'efectivo',
              icon: Icon(Icons.payments_outlined),
              label: Text('Efectivo'),
            ),
            const ButtonSegment<String>(
              value: 'digital',
              icon: Icon(Icons.account_balance_wallet_outlined),
              label: Text('Digital'),
            ),
          ],
          selected: {
            selectedValue.isEmpty && !allowUnclassified
                ? MoneyMedium.cash.storageValue
                : selectedValue,
          },
          onSelectionChanged: (values) {
            onChanged(MoneyMedium.fromStorage(values.single));
          },
        ),
      ],
    );
  }
}

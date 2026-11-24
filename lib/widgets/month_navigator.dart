import 'package:flutter/material.dart';

class MonthNavigator extends StatelessWidget {
  const MonthNavigator({
    super.key,
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth = month.year == now.year && month.month == now.month;
    final monthName = const [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ][month.month - 1];

    return Row(
      children: [
        IconButton(
          tooltip: 'Mes anterior',
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Center(
            child: Text(
              '${monthName[0].toUpperCase()}${monthName.substring(1)} ${month.year}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Mes siguiente',
          onPressed: isCurrentMonth ? null : onNext,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

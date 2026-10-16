import 'package:flutter/services.dart';

String formatMoney(double amount) {
  final sign = amount < 0 ? '-' : '';
  return '$sign\$ ${formatAmount(amount.abs())}';
}

String formatAmount(double amount) {
  final parts = amount.abs().toStringAsFixed(2).split('.');
  final integer = parts.first.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  final decimals = parts.last.replaceFirst(RegExp(r'0+$'), '');
  return decimals.isEmpty ? integer : '$integer,$decimals';
}

double? tryParseMoney(String? value) {
  final parts = _parseParts(value ?? '');
  if (parts == null || parts.fraction.length > 2) return null;
  final fraction = parts.fraction.isEmpty ? '' : '.${parts.fraction}';
  final sign = parts.negative ? '-' : '';
  final amount = double.tryParse('$sign${parts.integer}$fraction');
  return amount != null && amount.isFinite ? amount : null;
}

double parseMoney(String value) {
  final amount = tryParseMoney(value);
  if (amount == null || !amount.isFinite) {
    throw FormatException('El valor monetario no es válido.', value);
  }
  return amount;
}

class ThousandsInputFormatter extends TextInputFormatter {
  const ThousandsInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final parts = _parseParts(newValue.text);
    if (parts == null || parts.fraction.length > 2) return oldValue;

    final formatted = _formatParts(parts);
    final selection = newValue.selection;
    final cursor = selection.isValid && selection.isCollapsed
        ? _mapCursor(newValue.text, selection.extentOffset, formatted, parts)
        : formatted.length;
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursor),
      composing: TextRange.empty,
    );
  }
}

class _MoneyParts {
  const _MoneyParts({
    required this.integer,
    required this.fraction,
    required this.negative,
    required this.decimalIndex,
  });

  final String integer;
  final String fraction;
  final bool negative;
  final int? decimalIndex;
}

_MoneyParts? _parseParts(String input) {
  final value = input.trim().replaceAll(RegExp(r'[\s\$]'), '');
  if (value.isEmpty || !RegExp(r'^-?[0-9.,]+$').hasMatch(value)) return null;

  final negative = value.startsWith('-');
  final unsigned = negative ? value.substring(1) : value;
  final commaIndex = unsigned.lastIndexOf(',');
  final dotIndexes = [
    for (var index = 0; index < unsigned.length; index++)
      if (unsigned[index] == '.') index,
  ];

  int? decimalIndex;
  if (commaIndex >= 0) {
    decimalIndex = commaIndex;
  } else if (dotIndexes.length == 1 &&
      unsigned.length - dotIndexes.single - 1 <= 2) {
    decimalIndex = dotIndexes.single;
  }

  final integerSource = decimalIndex == null
      ? unsigned
      : unsigned.substring(0, decimalIndex);
  final fractionSource = decimalIndex == null
      ? ''
      : unsigned.substring(decimalIndex + 1);
  final integerDigits = integerSource.replaceAll(RegExp(r'[^0-9]'), '');
  final fractionDigits = fractionSource.replaceAll(RegExp(r'[^0-9]'), '');
  if (integerDigits.isEmpty) return null;

  return _MoneyParts(
    integer: integerDigits,
    fraction: fractionDigits,
    negative: negative,
    decimalIndex: decimalIndex,
  );
}

String _formatParts(_MoneyParts parts) {
  final integer = parts.integer.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  final sign = parts.negative ? '-' : '';
  if (parts.decimalIndex == null) return '$sign$integer';
  return '$sign$integer,${parts.fraction}';
}

int _mapCursor(
  String source,
  int sourceOffset,
  String formatted,
  _MoneyParts parts,
) {
  if (sourceOffset >= source.length) return formatted.length;
  final safeOffset = sourceOffset.clamp(0, source.length);
  final sourceBeforeCursor = source.substring(0, safeOffset);
  final decimalIndex = parts.decimalIndex;
  final isInFraction = decimalIndex != null && safeOffset > decimalIndex;

  if (isInFraction) {
    final fractionDigits = source
        .substring(decimalIndex + 1, safeOffset)
        .replaceAll(RegExp(r'[^0-9]'), '')
        .length;
    final commaIndex = formatted.indexOf(',');
    return (commaIndex + 1 + fractionDigits).clamp(0, formatted.length);
  }

  final digitsBeforeCursor = sourceBeforeCursor
      .replaceAll(RegExp(r'[^0-9]'), '')
      .length;
  if (digitsBeforeCursor == 0) return 0;
  var digits = 0;
  for (var index = 0; index < formatted.length; index++) {
    if (RegExp(r'[0-9]').hasMatch(formatted[index])) digits++;
    if (digits >= digitsBeforeCursor) return index + 1;
  }
  return formatted.length;
}

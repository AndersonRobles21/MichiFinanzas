String formatSpanishLongDate(DateTime date) {
  const weekdays = [
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo',
  ];
  const months = [
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
  ];
  final weekday = weekdays[date.weekday - 1];
  final month = months[date.month - 1];
  return '${weekday[0].toUpperCase()}${weekday.substring(1)}, '
      '${date.day} de $month de ${date.year}';
}

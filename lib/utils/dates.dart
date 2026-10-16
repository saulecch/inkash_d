/// 'Octubre 2026'. Para el encabezado del Inicio y del Historial.
String monthName(DateTime date) =>
    '${_monthNames[date.month - 1]} ${date.year}';

/// Primer instante del mes de [date] y del mes siguiente. Un rango
/// [inicio, siguiente) evita el error clásico de "¿el 31 a las 23:59 entra?".
DateTime monthStart(DateTime date) => DateTime(date.year, date.month);

// Diciembre + 1 = enero del año siguiente: DateTime lo resuelve solo.
DateTime nextMonthStart(DateTime date) => DateTime(date.year, date.month + 1);

/// '15 Oct'. La fecha corta de cada fila.
String shortDate(DateTime date) =>
    '${date.day} ${_monthNames[date.month - 1].substring(0, 3)}';

/// 'Jue 15 Oct'. El encabezado de cada día en el Historial.
String dayLabel(DateTime date) =>
    '${_weekdays[date.weekday - 1]} ${shortDate(date)}';

const _weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

const _monthNames = [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
];

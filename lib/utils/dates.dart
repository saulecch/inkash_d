/// 'Octubre 2026'. Para el encabezado del Inicio (y luego del Historial).
String monthName(DateTime date) =>
    '${_monthNames[date.month - 1]} ${date.year}';

/// Primer instante del mes de [date] y del mes siguiente. Un rango
/// [inicio, siguiente) evita el error clásico de "¿el 31 a las 23:59 entra?".
DateTime monthStart(DateTime date) => DateTime(date.year, date.month);

// Diciembre + 1 = enero del año siguiente: DateTime lo resuelve solo.
DateTime nextMonthStart(DateTime date) => DateTime(date.year, date.month + 1);

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

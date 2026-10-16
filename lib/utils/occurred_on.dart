/// `occurredOn` en inkash_d: entero LOCAL de 17 dígitos `yyyyMMddHHmmssSSS`.
///
/// Ej.: 15 oct 2026 08:15:03.007 -> 20261015081503007.
/// Es una decisión del equipo (ver S10): se lee "a ojo" en SQLite, ordena
/// bien y `substr(occurred_on, 1, 6)` da el mes. NO es epoch: eso es
/// `createdAtMs`. No guarda zona horaria (hora local del teléfono).
int encodeOccurredOn(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');

  final encoded =
      '${date.year.toString().padLeft(4, '0')}'
      '${two(date.month)}'
      '${two(date.day)}'
      '${two(date.hour)}'
      '${two(date.minute)}'
      '${two(date.second)}'
      '${date.millisecond.toString().padLeft(3, '0')}';
  return int.parse(encoded);
}

/// S15-03: el camino de regreso, para agrupar y mostrar fechas.
/// 20261015081503007 -> DateTime(2026, 10, 15, 8, 15, 3, 7) (hora local).
DateTime decodeOccurredOn(int occurredOn) {
  final value = occurredOn.toString().padLeft(17, '0');
  int part(int start, int end) => int.parse(value.substring(start, end));
  return DateTime(
    part(0, 4),
    part(4, 6),
    part(6, 8),
    part(8, 10),
    part(10, 12),
    part(12, 14),
    part(14, 17),
  );
}

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

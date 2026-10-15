/// Convierte el texto del campo "Monto" a centavos **sin pasar por double**.
///
/// Ejemplos: '12.5' -> 1250 · '12,50' -> 1250 · '0.05' -> 5.
/// Devuelve `null` si no es un monto válido: vacío, cero, negativo,
/// más de 2 decimales, letras o mayor que [maxMinor].
///
/// ¿Por qué no `(double.parse(texto) * 100).round()`? Porque en binario
/// 0.1 + 0.2 != 0.3. Separamos parte entera y decimales como TEXTO y
/// armamos un entero.
int? parseAmountMinor(String input, {int maxMinor = 100000000}) {
  // Como en S11: la coma se acepta como separador DECIMAL ('12,50').
  final normalized = input.trim().replaceAll(',', '.');
  // \d{1,9}: antes era \d+ y un número de 20 dígitos hacía que int.parse
  // lanzara FormatException dentro del validator (la app se caía).
  final match = RegExp(r'^(\d{1,9})(?:\.(\d{1,2}))?$').firstMatch(normalized);
  if (match == null) return null;

  final whole = int.parse(match.group(1)!);
  // '5' -> 50 centavos, '05' -> 5 centavos, sin decimales -> 0.
  final decimals = int.parse((match.group(2) ?? '').padRight(2, '0'));
  final amountMinor = whole * 100 + decimals;

  if (amountMinor <= 0 || amountMinor > maxMinor) return null;
  return amountMinor;
}

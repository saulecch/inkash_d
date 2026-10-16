/// 'Q1,234.50' a partir de centavos (siempre positivo; el signo lo pone
/// quien lo muestra). S15-03: sale de Movement para que el Historial pueda
/// formatear sus totales sin copiar la función otra vez.
String formatQuetzales(int minor) {
  final cents = minor.abs();
  final whole = cents ~/ 100;
  final decimals = (cents % 100).toString().padLeft(2, '0');
  final thousands = whole.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  return 'Q$thousands.$decimals';
}

/// S16-01: centavos -> '500.00' para precargar un campo de texto, solo con
/// enteros (lo inverso de parseAmountMinor). Sin 'Q' ni comas de miles.
String amountInputText(int minor) =>
    '${minor ~/ 100}.${(minor % 100).toString().padLeft(2, '0')}';

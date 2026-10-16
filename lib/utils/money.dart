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

// Cuántos quetzales vale un dólar.
//
// La tasa trae 4 decimales (7.6543), así que la guardamos como ENTERO en
// diezmilésimas (76543): misma regla que el dinero en centavos.
class ExchangeRate {
  const ExchangeRate({
    required this.gtqPerUsdTenThousandths,
    required this.updatedAt,
    this.fromCache = false,
  });

  final int gtqPerUsdTenThousandths;
  final DateTime updatedAt;

  // true = no hubo red y mostramos el último dato guardado.
  final bool fromCache;

  // 76543 diezmilésimas -> 765 centavos ('Q7.65'). Redondeo con enteros:
  // sumar la mitad (50) antes de dividir con ~/ evita pasar por double.
  int get centsPerUsd => (gtqPerUsdTenThousandths + 50) ~/ 100;
}

// Error con mensaje para humanos. La UI nunca muestra un stack trace.
class ExchangeRateException implements Exception {
  const ExchangeRateException(this.message);

  final String message;

  @override
  String toString() => 'ExchangeRateException: $message';
}

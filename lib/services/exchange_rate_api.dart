import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/exchange_rate.dart';

// Fuente de datos REMOTA. Es la única clase que sabe de HTTP y JSON.
// API pública y gratuita, sin API key: https://www.exchangerate-api.com/docs/free
class ExchangeRateApi {
  // El cliente se inyecta: en las pruebas usamos MockClient (sin internet).
  ExchangeRateApi({
    http.Client? client,
    this.timeout = const Duration(seconds: 5),
  }) : _client = client ?? http.Client();

  static final _url = Uri.parse('https://open.er-api.com/v6/latest/USD');

  final http.Client _client;
  final Duration timeout;

  // Convierte CADA forma de fallar en un ExchangeRateException con un
  // mensaje claro. Las 4 pasan en la vida real.
  Future<int> fetchGtqPerUsdTenThousandths() async {
    final http.Response response;
    try {
      // Sin timeout, una red lenta deja la app "cargando" para siempre.
      response = await _client.get(_url).timeout(timeout);
    } on TimeoutException {
      throw const ExchangeRateException('El servidor tardó demasiado.');
    } on http.ClientException {
      // 1. Sin internet, DNS caído, modo avión...
      throw const ExchangeRateException('Sin conexión a internet.');
    }

    // 2. El servidor respondió, pero con error (404, 429, 500...).
    if (response.statusCode != 200) {
      throw ExchangeRateException(
        'El servidor respondió ${response.statusCode}.',
      );
    }

    // 3. Respondió 200 pero el JSON no trae lo que esperamos.
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final rates = json['rates'] as Map<String, dynamic>;
      final gtq = rates['GTQ'] as num;
      // Aquí sí aparece un double (viene así del JSON); lo convertimos a
      // entero UNA vez, en la frontera, y el resto de la app usa enteros.
      return (gtq * 10000).round();
    } catch (_) {
      throw const ExchangeRateException('Respuesta inesperada del servidor.');
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/exchange_rate.dart';
import '../../../../repositories/exchange_rate_repository.dart';

final exchangeRateRepositoryProvider = Provider<ExchangeRateRepository>((ref) {
  return ExchangeRateRepository();
});

// FutureProvider: no hay métodos que llamar (solo leer), así que no hace
// falta un AsyncNotifier. Para recargar: ref.invalidate(exchangeRateProvider).
final exchangeRateProvider = FutureProvider<ExchangeRate>(
  (ref) => ref.watch(exchangeRateRepositoryProvider).getUsdRate(),
  retry: (_, _) => null,
);

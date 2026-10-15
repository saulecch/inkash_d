import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/exchange_rate.dart';
import '../../../../theme.dart';
import '../controllers/exchange_rate_provider.dart';

// Tarjeta "Dólar hoy". Los mismos estados que el dashboard, en pequeño.
class ExchangeRateCard extends ConsumerWidget {
  const ExchangeRateCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rate = ref.watch(exchangeRateProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: kSuperficie,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorde),
      ),
      child: Row(
        children: [
          const Icon(Icons.currency_exchange, color: kLima, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: rate.when(
              loading: () => const Text(
                'Consultando el dólar…',
                style: TextStyle(color: kMuted),
              ),
              error: (error, _) => Text(
                error is ExchangeRateException
                    ? 'Dólar no disponible: ${error.message}'
                    : 'Dólar no disponible.',
                style: const TextStyle(color: kMuted, fontSize: 12),
              ),
              data: (value) => _Rate(rate: value),
            ),
          ),
          IconButton(
            tooltip: 'Actualizar tipo de cambio',
            onPressed: rate.isLoading
                ? null
                : () => ref.invalidate(exchangeRateProvider),
            icon: const Icon(Icons.refresh, size: 20),
          ),
        ],
      ),
    );
  }
}

class _Rate extends StatelessWidget {
  const _Rate({required this.rate});

  final ExchangeRate rate;

  @override
  Widget build(BuildContext context) {
    final cents = rate.centsPerUsd;
    final quetzales =
        'Q${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';
    final time = TimeOfDay.fromDateTime(rate.updatedAt).format(context);
    final date = '${rate.updatedAt.day}/${rate.updatedAt.month}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dólar hoy · $quetzales'),
        Text(
          // Honestidad con el usuario: decir cuando el dato es viejo.
          rate.fromCache
              ? 'Sin conexión · último dato $date $time'
              : 'Actualizado $time',
          style: TextStyle(
            fontSize: 11,
            color: rate.fromCache ? kPeligro : kMuted,
          ),
        ),
      ],
    );
  }
}

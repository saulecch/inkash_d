import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/exchange_rate.dart';
import '../../../../theme.dart';
import '../controllers/exchange_rate_provider.dart';

// Tarjeta "Dólar hoy". Los mismos estados que el dashboard, en pequeño.
// S17-01: Card del tema (radio y borde de tarjeta), sin estilos sueltos.
class ExchangeRateCard extends ConsumerWidget {
  const ExchangeRateCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rate = ref.watch(exchangeRateProvider);
    final text = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Spacing.l, Spacing.s, 0, Spacing.s),
        child: Row(
          children: [
            const Icon(Icons.currency_exchange, color: kLima, size: 20),
            const SizedBox(width: Spacing.m),
            Expanded(
              child: rate.when(
                loading: () =>
                    Text('Consultando el dólar…', style: text.bodySmall),
                error: (error, _) => Text(
                  error is ExchangeRateException
                      ? 'Dólar no disponible: ${error.message}'
                      : 'Dólar no disponible.',
                  style: text.bodySmall,
                ),
                data: (value) => _Rate(rate: value),
              ),
            ),
            IconButton(
              tooltip: 'Actualizar tipo de cambio',
              onPressed: rate.isLoading
                  ? null
                  : () => ref.invalidate(exchangeRateProvider),
              icon: const Icon(Icons.refresh, size: 20, color: kMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _Rate extends StatelessWidget {
  const _Rate({required this.rate});

  final ExchangeRate rate;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final cents = rate.centsPerUsd;
    final quetzales =
        'Q${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';
    final time = TimeOfDay.fromDateTime(rate.updatedAt).format(context);
    final date = '${rate.updatedAt.day}/${rate.updatedAt.month}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dólar hoy · $quetzales',
          style: text.bodyMedium?.copyWith(fontFeatures: kTabularFigures),
        ),
        Text(
          // Honestidad con el usuario: decir cuando el dato es viejo.
          rate.fromCache
              ? 'Sin conexión · último dato $date $time'
              : 'Actualizado $time',
          style: text.bodySmall?.copyWith(
            color: rate.fromCache ? kPeligro : kMuted,
          ),
        ),
      ],
    );
  }
}

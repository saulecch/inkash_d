import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/home/presentation/controllers/home_controller.dart';
import 'features/home/presentation/widgets/exchange_rate_card.dart';
import 'features/home/presentation/widgets/movement_tile.dart';
import 'features/navigation/navigation_controller.dart';
import 'models/home_summary.dart';
import 'theme.dart';
import 'utils/dates.dart';

// S14-02: ConsumerWidget = StatelessWidget + acceso a `ref`. Ya no hace
// falta addListener/setState: ref.watch reconstruye cuando cambia el estado.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // watch: cuando el estado cambie, este build se vuelve a ejecutar.
    final summary = ref.watch(homeControllerProvider);

    // S15-01: ya no es un Scaffold. La barra inferior vive en InkashShell.
    return SafeArea(
      // Los estados de una consulta asíncrona, explícitos y sin if anidados.
      // Al recargar (tras guardar) se siguen viendo los datos anteriores.
      child: summary.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: kLima)),
        error: (error, _) =>
            _LoadError(onRetry: () => ref.invalidate(homeControllerProvider)),
        data: (summary) => _buildDashboard(summary, ref),
      ),
    );
  }

  Widget _buildDashboard(HomeSummary summary, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Text('Hola, Kevin', style: TextStyle(fontSize: 15)),
            const Spacer(),
            // S15-02: el mes real, no 'Julio 2026' escrito a mano.
            Text(
              monthName(summary.month),
              style: const TextStyle(fontSize: 12, color: kMuted),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _buildBudgetSection(summary),
        const SizedBox(height: 22),
        _buildHeroCards(summary),
        const SizedBox(height: 12),
        // S14-03: dato remoto. Si falla, el resto del dashboard sigue vivo:
        // cada provider tiene su propio estado de carga y error.
        const ExchangeRateCard(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Últimos movimientos',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            TextButton(
              // Navegar = cambiar el estado de la pestaña activa.
              onPressed: () =>
                  ref.read(navigationProvider.notifier).goTo(AppTab.history),
              child: const Text(
                'Ver todo',
                style: TextStyle(fontSize: 13, color: kLima),
              ),
            ),
          ],
        ),
        // Estado vacío: también es un estado que hay que diseñar.
        if (summary.recentMovements.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Text(
              'Aún no hay movimientos.\nToca + para registrar el primero.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kMuted),
            ),
          ),
        for (final movement in summary.recentMovements)
          MovementTile(movement: movement),
      ],
    );
  }

  Widget _buildBudgetSection(HomeSummary summary) {
    final balanceFormatted = summary.formatQuetzales(summary.totalBalanceMinor);
    final spentFormatted = summary.formatQuetzales(summary.monthlySpentMinor);
    final budgetFormatted = summary.formatQuetzales(summary.monthlyBudgetMinor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TE QUEDAN DISPONIBLES',
          style: TextStyle(fontSize: 11, color: kLima),
        ),
        Text(
          balanceFormatted,
          style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        if (summary.monthlyBudgetMinor > 0)
          LinearProgressIndicator(
            value: summary.budgetProgress,
            color: kLima,
            minHeight: 8,
            borderRadius: const BorderRadius.all(Radius.circular(4)),
          ),
        const SizedBox(height: 8),
        if (summary.monthlyBudgetMinor > 0)
          Text(
            'Has usado $spentFormatted de $budgetFormatted',
            style: const TextStyle(fontSize: 12, color: kMuted),
          )
        else
          const Text(
            'Sin presupuesto definido',
            style: TextStyle(fontSize: 12, color: kMuted),
          ),
      ],
    );
  }

  Widget _buildHeroCards(HomeSummary summary) {
    final goals = summary.activeGoals;
    final goalsText = '$goals activa${goals != 1 ? 's' : ''}';

    return Row(
      children: [
        heroCard('Cuentas', summary.formatQuetzales(summary.totalBalanceMinor)),
        const SizedBox(width: 16),
        heroCard('Metas de ahorro', goalsText),
      ],
    );
  }
}

Widget heroCard(String title, String content) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSuperficie,
        border: Border.all(color: kBorde),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14)),
          Text(content, style: const TextStyle(fontSize: 20)),
        ],
      ),
    ),
  );
}

// Estado de error: mensaje humano + una acción. Nunca un stack trace.
class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: kPeligro, size: 40),
            const SizedBox(height: 12),
            const Text(
              'No pudimos leer tus movimientos.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

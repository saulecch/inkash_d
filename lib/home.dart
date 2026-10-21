import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/accounts/accounts_page.dart';
import 'features/goals/goals_page.dart';
import 'features/home/presentation/controllers/home_controller.dart';
import 'features/home/presentation/widgets/exchange_rate_card.dart';
import 'features/home/presentation/widgets/movement_tile.dart';
import 'features/home/presentation/widgets/open_movement_form.dart';
import 'features/navigation/navigation_controller.dart';
import 'models/home_summary.dart';
import 'theme.dart';
import 'utils/dates.dart';
import 'utils/money.dart';
import 'widgets/ui/empty_state.dart';
import 'widgets/ui/money_text.dart';
import 'widgets/ui/summary_card.dart';

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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            _LoadError(onRetry: () => ref.invalidate(homeControllerProvider)),
        data: (summary) => _buildDashboard(context, summary, ref),
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    HomeSummary summary,
    WidgetRef ref,
  ) {
    final text = Theme.of(context).textTheme;
    final goals = summary.activeGoals;
    void push(Widget page) => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => page));

    // S17-01: todos los espacios y estilos salen de los tokens del tema.
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Spacing.l,
        Spacing.xl,
        Spacing.l,
        Spacing.xxl,
      ),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Hola, Kevin', style: text.titleMedium),
            // S15-02: el mes real, no 'Julio 2026' escrito a mano.
            Text(monthName(summary.month), style: text.bodySmall),
          ],
        ),
        const SizedBox(height: Spacing.xxl),
        _MonthHero(summary: summary),
        const SizedBox(height: Spacing.xl),
        Row(
          children: [
            // S16-01: el total es real (SUM en SQL); tocarlo abre Cuentas.
            SummaryCard(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Cuentas',
              value:
                  '${summary.totalBalanceMinor < 0 ? '−' : ''}'
                  '${formatQuetzales(summary.totalBalanceMinor)}',
              onTap: () => push(const AccountsPage()),
            ),
            const SizedBox(width: Spacing.m),
            // S16-05: Navigator.push abre Metas ENCIMA de las pestañas.
            SummaryCard(
              icon: Icons.savings_outlined,
              label: 'Metas de ahorro',
              value: goals == 0
                  ? 'Crear una'
                  : '$goals activa${goals != 1 ? 's' : ''}',
              onTap: () => push(const GoalsPage()),
            ),
          ],
        ),
        const SizedBox(height: Spacing.m),
        // S14-03: dato remoto. Si falla, el resto del dashboard sigue vivo:
        // cada provider tiene su propio estado de carga y error.
        const ExchangeRateCard(),
        const SizedBox(height: Spacing.xl),
        Row(
          children: [
            Expanded(
              child: Text('Últimos movimientos', style: text.titleLarge),
            ),
            TextButton(
              // Navegar = cambiar el estado de la pestaña activa.
              onPressed: () =>
                  ref.read(navigationProvider.notifier).goTo(AppTab.history),
              child: const Text('Ver todo'),
            ),
          ],
        ),
        // Estado vacío: una invitación con su acción, no solo un texto.
        if (summary.recentMovements.isEmpty)
          EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Aún no hay movimientos',
            message: 'Registra tu primer gasto o ingreso del mes.',
            action: 'Registrar movimiento',
            onAction: () => openMovementForm(context, ref),
          ),
        for (final movement in summary.recentMovements)
          MovementTile(
            movement: movement,
            onTap: () => openMovementForm(context, ref, edit: movement),
          ),
      ],
    );
  }
}

// S17-01: lo más importante de la app, en una frase y sin mayúsculas
// sostenidas: cuánto te queda del mes frente a tu límite.
class _MonthHero extends StatelessWidget {
  const _MonthHero({required this.summary});

  final HomeSummary summary;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final limit = summary.monthlyBudgetMinor;
    final spent = summary.monthlySpentMinor;

    if (limit == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Llevas gastado este mes',
            style: text.bodyMedium?.copyWith(color: kLima),
          ),
          const SizedBox(height: Spacing.xs),
          MoneyText(spent, style: text.displayLarge),
          const SizedBox(height: Spacing.s),
          Text('Aún no tienes un límite mensual.', style: text.bodySmall),
        ],
      );
    }

    final left = summary.availableBudgetMinor;
    final exceeded = left < 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          exceeded ? 'Te pasaste del límite por' : 'Te quedan este mes',
          style: text.bodyMedium?.copyWith(color: exceeded ? kPeligro : kLima),
        ),
        const SizedBox(height: Spacing.xs),
        MoneyText(
          left.abs(),
          style: text.displayLarge?.copyWith(
            color: exceeded ? kPeligro : kTexto,
          ),
        ),
        const SizedBox(height: Spacing.l),
        LinearProgressIndicator(
          // clamp en budgetProgress: si gastó de más, la barra no se desborda.
          value: summary.budgetProgress,
          color: exceeded ? kPeligro : kLima,
          minHeight: Spacing.s,
          borderRadius: BorderRadius.circular(Spacing.xs),
        ),
        const SizedBox(height: Spacing.s),
        Text(
          'Has usado ${formatQuetzales(spent)} de ${formatQuetzales(limit)}',
          style: text.bodySmall,
        ),
      ],
    );
  }
}

// Estado de error: mensaje humano + una acción. Nunca un stack trace.
class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: kPeligro, size: 40),
            const SizedBox(height: Spacing.m),
            const Text(
              'No pudimos leer tus movimientos.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.m),
            OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

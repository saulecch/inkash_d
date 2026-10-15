import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/home/presentation/controllers/home_controller.dart';
import 'features/home/presentation/widgets/movement_bottom_sheet.dart';
import 'models/home_summary.dart';
import 'theme.dart';

// S14-02: ConsumerWidget = StatelessWidget + acceso a `ref`. Ya no hace
// falta addListener/setState: ref.watch reconstruye cuando cambia el estado.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // watch: cuando el estado cambie, este build se vuelve a ejecutar.
    final summary = ref.watch(homeControllerProvider);

    return Scaffold(
      body: SafeArea(
        // Los estados de una consulta asíncrona, explícitos y sin if anidados.
        // Al recargar (tras guardar) se siguen viendo los datos anteriores.
        child: summary.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: kLima)),
          error: (error, _) =>
              _LoadError(onRetry: () => ref.invalidate(homeControllerProvider)),
          data: _buildDashboard,
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context, ref),
    );
  }

  Widget _buildDashboard(HomeSummary summary) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: const [
            Text('Hola, Kevin', style: TextStyle(fontSize: 15)),
            Spacer(),
            Text('Julio 2026', style: TextStyle(fontSize: 12, color: kMuted)),
          ],
        ),
        const SizedBox(height: 22),
        _buildBudgetSection(summary),
        const SizedBox(height: 22),
        _buildHeroCards(summary),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Últimos movimientos',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            TextButton(
              onPressed: () {},
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
        for (final mov in summary.recentMovements)
          detailListTile(
            Icons.receipt,
            mov.description,
            _formatDate(mov.occurredOn),
            '${mov.amount >= 0 ? '+' : '−'} ${mov.amountFormatted}',
            _formatDate(mov.occurredOn),
            isIncome: mov.amount >= 0,
          ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, WidgetRef ref) {
    return BottomNavigationBar(
      currentIndex: 0,
      selectedItemColor: kLima,
      type: BottomNavigationBarType.fixed,
      onTap: (index) async {
        if (index != 2) return;
        // read (no watch): en un callback solo queremos llamar un método.
        final controller = ref.read(homeControllerProvider.notifier);
        // El sheet devuelve true con Navigator.pop(true) si guardó.
        final saved = await showMovementBottomSheet(
          context: context,
          loadOptions: controller.loadFormOptions,
          onSave: controller.saveMovement,
        );
        if (saved != true || !context.mounted) return;
        // El controller ya reconsultó SQLite; la lista se actualiza sola
        // porque HomePage hace ref.watch.
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Movimiento guardado')));
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: 'Presupuesto',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle, size: 34),
          label: 'Agregar',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Historial'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Ajustes'),
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

  String _formatDate(int encodedDate) {
    try {
      final value = encodedDate.toString();
      if (value.length < 8) return value;
      final day = int.parse(value.substring(6, 8));
      final month = int.parse(value.substring(4, 6));
      final months = [
        '',
        'Ene',
        'Feb',
        'Mar',
        'Abr',
        'May',
        'Jun',
        'Jul',
        'Ago',
        'Sep',
        'Oct',
        'Nov',
        'Dic',
      ];
      return '$day ${months[month]}';
    } catch (_) {
      return encodedDate.toString();
    }
  }
}

Widget detailListTile(
  IconData icon,
  String title,
  String subtitle,
  String amount,
  String date, {
  bool isIncome = false,
}) {
  return ListTile(
    leading: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: kIconoFondo,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(icon, color: kLima),
    ),
    title: Text(title, style: const TextStyle(color: kTexto)),
    subtitle: Text(subtitle, style: const TextStyle(color: kMuted)),
    trailing: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          amount,
          style: TextStyle(fontSize: 13, color: isIncome ? kLima : kTexto),
        ),
        Text(date, style: const TextStyle(fontSize: 10, color: kMuted)),
      ],
    ),
  );
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

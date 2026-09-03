import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';

import 'features/home/presentation/controllers/home_controller.dart';
import 'models/home_summary.dart';
import 'theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    required this.controller,
    required this.container,
    super.key,
  });

  final MovimientosController controller;
  final ProviderContainer container;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.loadHomeData();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.controller.summary;
    final loading = widget.controller.loading;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: const [
                Text('Hola, Kevin', style: TextStyle(fontSize: 15)),
                Spacer(),
                Text(
                  'Julio 2026',
                  style: TextStyle(fontSize: 12, color: kMuted),
                ),
              ],
            ),
            const SizedBox(height: 22),
            if (loading && summary == null)
              const Center(child: CircularProgressIndicator(color: kLima))
            else if (summary != null)
              _buildBudgetSection(summary)
            else
              const Center(
                child: Text(
                  'Sin datos disponibles',
                  style: TextStyle(color: kMuted),
                ),
              ),
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
            if (summary != null)
              for (final mov in summary.recentMovements)
                detailListTile(
                  Icons.receipt,
                  mov.description,
                  _formatDate(mov.occurredOn),
                  '${mov.amountMinor >= 0 ? '+' : '−'} ${mov.amountFormatted}',
                  _formatDate(mov.occurredOn),
                  isIncome: mov.amountMinor >= 0,
                ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: kLima,
        type: BottomNavigationBarType.fixed,
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
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Historial',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetSection(HomeSummary summary) {
    final balanceFormatted = summary.formatQuetzales(summary.totalBalanceMinor);
    final spentFormatted = summary.formatQuetzales(summary.monthlySpentMinor);
    final budgetFormatted =
        summary.formatQuetzales(summary.monthlyBudgetMinor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TE QUEDAN DISPONIBLES',
          style: TextStyle(fontSize: 11, color: kLima),
        ),
        Text(
          balanceFormatted,
          style: const TextStyle(
            fontSize: 52,
            fontWeight: FontWeight.w600,
          ),
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

  Widget _buildHeroCards(HomeSummary? summary) {
    final goalsText = summary != null
        ? '${summary.activeGoals} activa${summary.activeGoals != 1 ? 's' : ''}'
        : '0 activas';

    return Row(
      children: [
        heroCard('Cuentas', summary?.formatQuetzales(summary.totalBalanceMinor) ?? 'Q0.00'),
        const SizedBox(width: 16),
        heroCard('Metas de ahorro', goalsText),
      ],
    );
  }

  String _formatDate(String isoDate) {
    try {
      final parts = isoDate.split('-');
      if (parts.length != 3) return isoDate;
      final day = int.parse(parts[2]);
      final month = int.parse(parts[1]);
      final months = [
        '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
      ];
      return '$day ${months[month]}';
    } catch (_) {
      return isoDate;
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
          style: TextStyle(
            fontSize: 13,
            color: isIncome ? kLima : kTexto,
          ),
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

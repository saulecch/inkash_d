import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/savings_goal.dart';
import '../../repositories/savings_goals_repository.dart';
import '../../theme.dart';
import '../../utils/money.dart';
import '../../widgets/amount_sheet.dart';
import '../home/presentation/controllers/home_controller.dart';
import 'goal_sheet.dart';
import 'goals_provider.dart';

// S16-05: pantalla que se ABRE ENCIMA (Navigator.push) desde la tarjeta
// "Metas de ahorro" del Inicio. No es una pestaña: tiene su propio Scaffold
// con AppBar y flecha para volver.
class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(savingsGoalsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Metas de ahorro')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nueva meta'),
      ),
      body: goals.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: kLima)),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No pudimos leer tus metas.'),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.invalidate(savingsGoalsProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (list) => list.isEmpty
            ? const Center(
                child: Text(
                  'Aún no tienes metas.\nCrea la primera con "Nueva meta".',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kMuted),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  for (final goal in list)
                    _GoalRow(
                      goal: goal,
                      onMoveMoney: () => _moveMoney(context, ref, goal),
                      onEdit: () => _openForm(context, ref, goal: goal),
                    ),
                ],
              ),
      ),
    );
  }

  // Metas y el conteo del Inicio dependen de la misma tabla.
  void _refresh(WidgetRef ref) {
    ref.invalidate(savingsGoalsProvider);
    ref.invalidate(homeControllerProvider);
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    SavingsGoal? goal,
  }) {
    final repository = ref.read(savingsGoalsRepositoryProvider);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: kSuperficie,
      builder: (_) => GoalSheet(
        goal: goal,
        onSave: (data) async {
          goal == null
              ? await repository.create(data.name, data.targetMinor)
              : await repository.edit(goal.id!, data.name, data.targetMinor);
          _refresh(ref);
        },
        onDelete: goal == null
            ? null
            : () async {
                await repository.delete(goal.id!);
                _refresh(ref);
              },
      ),
    );
  }

  Future<void> _moveMoney(
    BuildContext context,
    WidgetRef ref,
    SavingsGoal goal,
  ) async {
    // askAmount (S16-04): la misma hoja de monto que el Presupuesto.
    final answer = await askAmount(
      context,
      title: goal.name,
      help:
          'Llevas ${formatQuetzales(goal.savedAmountMinor)} de '
          '${formatQuetzales(goal.targetAmountMinor)}.',
      actions: const ['Retirar', 'Aportar'],
    );
    final amount = answer?.amountMinor;
    if (answer == null || amount == null) return;

    final repository = ref.read(savingsGoalsRepositoryProvider);
    try {
      answer.action == 'Aportar'
          ? await repository.contribute(goal.id!, amount)
          : await repository.withdraw(goal.id!, amount);
    } on SavingsGoalException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
    _refresh(ref);
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({
    required this.goal,
    required this.onMoveMoney,
    required this.onEdit,
  });

  final SavingsGoal goal;
  final VoidCallback onMoveMoney;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onMoveMoney,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        goal.isCompleted ? Icons.check_circle : Icons.savings_outlined,
        color: kLima,
      ),
      title: Text(goal.name),
      trailing: IconButton(
        tooltip: 'Editar meta',
        onPressed: onEdit,
        icon: const Icon(Icons.edit_outlined, color: kMuted),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: goal.progress,
            minHeight: 6,
            color: kLima,
            borderRadius: const BorderRadius.all(Radius.circular(3)),
          ),
          const SizedBox(height: 4),
          Text(
            '${formatQuetzales(goal.savedAmountMinor)} de '
            '${formatQuetzales(goal.targetAmountMinor)}',
            style: const TextStyle(fontSize: 12, color: kMuted),
          ),
        ],
      ),
    );
  }
}

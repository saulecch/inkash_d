import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/savings_goal.dart';
import '../home/presentation/controllers/home_controller.dart';

// S16-05: las metas para la pantalla de metas. El conteo del Inicio sigue
// saliendo de HomeController (getActiveCount, un COUNT en SQL).
final savingsGoalsProvider = FutureProvider<List<SavingsGoal>>(
  (ref) => ref.watch(savingsGoalsRepositoryProvider).getActive(),
  retry: (_, _) => null,
);

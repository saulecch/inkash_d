import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/account_balance.dart';
import '../home/presentation/controllers/home_controller.dart';

// S16-01: saldo por cuenta para la pantalla Cuentas.
// Se invalida al guardar/borrar/deshacer (ver HomeController._refreshAll).
final accountBalancesProvider = FutureProvider<List<AccountBalance>>(
  (ref) => ref.watch(accountsRepositoryProvider).getWithBalances(),
  retry: (_, _) => null,
);

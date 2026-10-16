import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/account_balance.dart';
import '../../theme.dart';
import '../../utils/money.dart';
import '../../widgets/app_icons.dart';
import '../history/history_controller.dart';
import '../home/presentation/controllers/home_controller.dart';
import 'account_balances_provider.dart';
import 'account_sheet.dart';

// S16-01: se abre con Navigator.push desde la tarjeta "Cuentas" del Inicio
// (y desde Ajustes). Crear, editar y borrar cuentas con su saldo inicial.
class AccountsPage extends ConsumerWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountBalancesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Cuentas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nueva cuenta'),
      ),
      body: accounts.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: kLima)),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No pudimos leer tus cuentas.'),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.invalidate(accountBalancesProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (list) {
          final total = list.fold(0, (t, a) => t + a.balanceMinor);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              const Text(
                'Total',
                style: TextStyle(color: kMuted, fontSize: 12),
              ),
              Text(
                _signed(total),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              for (final account in list)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: kIconoFondo,
                    child: Icon(iconFor(account.iconKey), color: kLima),
                  ),
                  title: Text(account.name),
                  subtitle: Text(
                    '${AccountBalance.typeLabels[account.type]} · '
                    'inicial ${_signed(account.initialBalanceMinor)}',
                    style: const TextStyle(color: kMuted, fontSize: 12),
                  ),
                  trailing: Text(
                    _signed(account.balanceMinor),
                    style: TextStyle(
                      color: account.balanceMinor < 0 ? kPeligro : kTexto,
                    ),
                  ),
                  onTap: () => _openForm(context, ref, account: account),
                ),
            ],
          );
        },
      ),
    );
  }

  String _signed(int minor) =>
      '${minor < 0 ? '−' : ''}${formatQuetzales(minor)}';

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    AccountBalance? account,
  }) {
    final repository = ref.read(accountsRepositoryProvider);
    // El nombre de la cuenta aparece en los movimientos ("Súper · Banco") y
    // el saldo inicial en el total: refrescar también Inicio e Historial.
    void refresh() {
      ref.invalidate(accountBalancesProvider);
      ref.invalidate(homeControllerProvider);
      ref.invalidate(historyProvider);
    }

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: kSuperficie,
      builder: (_) => AccountSheet(
        account: account,
        onSave: (data) async {
          await repository.save(
            id: account?.id,
            name: data.name,
            type: data.type,
            initialBalanceMinor: data.initialBalanceMinor,
          );
          refresh();
        },
        onDelete: account == null
            ? null
            : () async {
                await repository.delete(account.id);
                refresh();
              },
      ),
    );
  }
}

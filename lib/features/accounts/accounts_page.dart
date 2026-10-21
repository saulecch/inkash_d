import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/account_balance.dart';
import '../../theme.dart';
import '../../utils/money.dart';
import '../../widgets/app_icons.dart';
import '../history/history_controller.dart';
import '../home/presentation/controllers/home_controller.dart';
import '../../widgets/ui/form_sheet.dart';
import '../../widgets/ui/money_text.dart';
import '../../widgets/ui/section.dart';
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No pudimos leer tus cuentas.'),
              const SizedBox(height: Spacing.m),
              OutlinedButton(
                onPressed: () => ref.invalidate(accountBalancesProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (list) {
          final text = Theme.of(context).textTheme;
          final total = list.fold(0, (t, a) => t + a.balanceMinor);
          // S17-01: total arriba y las cuentas en una Sección.
          return ListView(
            padding: const EdgeInsets.only(top: Spacing.s, bottom: 96),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.l,
                  0,
                  Spacing.l,
                  Spacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total en tus cuentas', style: text.bodySmall),
                    const SizedBox(height: Spacing.xs),
                    MoneyText(
                      total,
                      style: text.headlineSmall?.copyWith(fontSize: 32),
                    ),
                  ],
                ),
              ),
              Section(
                children: [
                  for (final account in list)
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: kIconoFondo,
                        child: Icon(iconFor(account.iconKey), color: kLima),
                      ),
                      title: Text(account.name),
                      subtitle: Text(
                        '${AccountBalance.typeLabels[account.type]} · '
                        'inicial ${_signed(account.initialBalanceMinor)}',
                      ),
                      trailing: MoneyText(
                        account.balanceMinor,
                        style: text.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: account.balanceMinor < 0 ? kPeligro : kTexto,
                        ),
                      ),
                      onTap: () => _openForm(context, ref, account: account),
                    ),
                ],
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

    return showFormSheet<void>(
      context,
      (_) => AccountSheet(
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

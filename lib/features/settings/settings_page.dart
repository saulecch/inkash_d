import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_settings.dart';
import '../../theme.dart';
import '../../utils/money.dart';
import '../../widgets/amount_sheet.dart';
import '../../widgets/text_sheet.dart';
import '../../widgets/ui/page_header.dart';
import '../../widgets/ui/section.dart';
import '../accounts/accounts_page.dart';
import '../categories/categories_page.dart';
import 'settings_controller.dart';

// S17-02: Ajustes completo. Perfil arriba (quién usa la app), luego lo que
// se ajusta seguido (el límite), la gestión de datos y, al final y
// separado, lo peligroso.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return SafeArea(
      child: settings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No pudimos leer los ajustes.'),
              const SizedBox(height: Spacing.m),
              OutlinedButton(
                onPressed: () => ref.invalidate(settingsProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (s) => _Content(settings: s),
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(settingsProvider.notifier);
    final text = Theme.of(context).textTheme;
    final name = settings.userName;
    void open(Widget page) => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => page));

    return ListView(
      padding: const EdgeInsets.only(bottom: Spacing.xxl),
      children: [
        const PageHeader(title: 'Ajustes'),
        // Perfil: la inicial en grande y el nombre; tocar = editar.
        Section(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.all(Spacing.l),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: kLima,
                foregroundColor: kFondo,
                child: Text(
                  name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                  style: text.titleLarge?.copyWith(color: kFondo),
                ),
              ),
              title: Text(name.isEmpty ? 'Agrega tu nombre' : name),
              subtitle: const Text('Toca para cambiarlo'),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () async {
                final answer = await askText(
                  context,
                  title: '¿Cómo te llamas?',
                  description: 'Lo usamos para saludarte en el Inicio.',
                  initial: name,
                  label: 'Tu nombre',
                );
                if (answer != null) await controller.changeUserName(answer);
              },
            ),
          ],
        ),
        Section(
          title: 'Este mes',
          children: [
            ListTile(
              leading: const Icon(Icons.speed),
              title: const Text('Límite mensual'),
              subtitle: const Text('Cuánto quieres gastar como máximo'),
              trailing: Text(
                settings.monthlyLimitMinor == 0
                    ? 'Sin límite'
                    : formatQuetzales(settings.monthlyLimitMinor),
                style: text.titleMedium?.copyWith(
                  color: kLima,
                  fontFeatures: kTabularFigures,
                ),
              ),
              onTap: () async {
                // La misma hoja de monto (y el mismo parser sin double)
                // que Presupuesto y Metas.
                final answer = await askAmount(
                  context,
                  title: 'Límite mensual',
                  help: 'El Inicio te dice cuánto te queda de este monto.',
                  initialMinor: settings.monthlyLimitMinor == 0
                      ? null
                      : settings.monthlyLimitMinor,
                );
                final amount = answer?.amountMinor;
                if (amount != null) await controller.changeMonthlyLimit(amount);
              },
            ),
          ],
        ),
        Section(
          title: 'Tus datos',
          children: [
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text('Cuentas'),
              subtitle: const Text('Efectivo, bancos, tarjetas y saldos'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => open(const AccountsPage()),
            ),
            ListTile(
              leading: const Icon(Icons.category_outlined),
              title: const Text('Categorías'),
              subtitle: const Text('Crear, renombrar y archivar'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => open(const CategoriesPage()),
            ),
          ],
        ),
        // Lo peligroso, aparte: nunca junto a algo que se toca seguido.
        Section(
          children: [
            ListTile(
              leading: const Icon(Icons.delete_forever, color: kPeligro),
              title: const Text(
                'Borrar todos mis datos',
                style: TextStyle(color: kPeligro),
              ),
              subtitle: const Text(
                'Movimientos, presupuestos, metas y ajustes',
              ),
              onTap: () => _confirmDeleteAll(context, ref),
            ),
          ],
        ),
        Center(
          child: Text(
            'Inkash 0.9 · Proyecto de PDM, UMES 2026',
            style: text.bodySmall,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteAll(BuildContext context, WidgetRef ref) async {
    // Acción destructiva e irreversible: SIEMPRE confirmar, y el botón
    // peligroso dice qué hace ("Borrar todo"), no "Aceptar".
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Borrar todos tus datos?'),
        content: const Text(
          'Se borran tus movimientos, presupuestos, metas y ajustes. '
          'Las cuentas y categorías se quedan. No se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: kPeligro,
              minimumSize: const Size(0, 44),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Borrar todo'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(settingsProvider.notifier).deleteAllUserData();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Datos borrados')));
    }
  }
}

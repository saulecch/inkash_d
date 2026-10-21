import 'package:flutter/material.dart';

import '../../theme.dart';
import '../accounts/accounts_page.dart';
import '../categories/categories_page.dart';

// S16-02: primera versión de Ajustes: la entrada a la gestión de datos.
// (El nombre, el límite mensual y "borrar mis datos" llegan en S17.)
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    void open(Widget page) => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => page));

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('Ajustes', style: TextStyle(fontSize: 20)),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Cuentas'),
            subtitle: const Text(
              'Efectivo, bancos, tarjetas y saldos iniciales',
            ),
            trailing: const Icon(Icons.chevron_right, color: kMuted),
            onTap: () => open(const AccountsPage()),
          ),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Categorías'),
            subtitle: const Text('Crear, renombrar y archivar'),
            trailing: const Icon(Icons.chevron_right, color: kMuted),
            onTap: () => open(const CategoriesPage()),
          ),
        ],
      ),
    );
  }
}

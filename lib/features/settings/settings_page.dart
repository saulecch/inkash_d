import 'package:flutter/material.dart';

import '../../widgets/ui/page_header.dart';
import '../../widgets/ui/section.dart';
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

    // S17-01: encabezado y Sección del sistema de diseño.
    return SafeArea(
      child: ListView(
        children: [
          const PageHeader(title: 'Ajustes'),
          Section(
            title: 'Tus datos',
            children: [
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text('Cuentas'),
                subtitle: const Text(
                  'Efectivo, bancos, tarjetas y saldos iniciales',
                ),
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
        ],
      ),
    );
  }
}

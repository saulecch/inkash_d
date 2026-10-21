import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/history/history_page.dart';
import 'features/home/presentation/widgets/open_movement_form.dart';
import 'features/navigation/navigation_controller.dart';
import 'features/settings/settings_page.dart';
import 'home.dart';
import 'theme.dart';
import 'widgets/coming_soon_page.dart';

// S15-01: el "cascarón" de la app: la barra inferior y una pantalla por
// pestaña. Antes la barra vivía dentro de HomePage, así que solo existía
// el Inicio.
class InkashShell extends ConsumerWidget {
  const InkashShell({super.key});

  // Orden de la barra: Inicio · Presupuesto · (+) · Historial · Ajustes.
  // El índice 2 es el botón Agregar, que no tiene pantalla.
  static const _addIndex = 2;
  static const _tabsByIndex = {
    0: AppTab.home,
    1: AppTab.budget,
    3: AppTab.history,
    4: AppTab.settings,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(navigationProvider);

    return Scaffold(
      // IndexedStack construye TODAS las pantallas y muestra una. Cada
      // pestaña conserva su scroll y sus filtros al cambiar de pestaña.
      // El orden de children es el del enum AppTab.
      body: IndexedStack(
        index: current.index,
        children: const [
          HomePage(),
          ComingSoonPage(title: 'Presupuesto', icon: Icons.bar_chart),
          HistoryPage(),
          SettingsPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabsByIndex.entries
            .firstWhere((entry) => entry.value == current)
            .key,
        selectedItemColor: kLima,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == _addIndex) {
            openMovementForm(context, ref); // S16-03: helper compartido
            return;
          }
          ref.read(navigationProvider.notifier).goTo(_tabsByIndex[index]!);
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
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Historial',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Ajustes'),
        ],
      ),
    );
  }
}

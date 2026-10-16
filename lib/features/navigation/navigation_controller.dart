import 'package:flutter_riverpod/flutter_riverpod.dart';

// Las pestañas que son PANTALLAS. "Agregar" no está aquí: no es un lugar,
// es una acción (abre el formulario encima de la pestaña actual).
enum AppTab { home, budget, history, settings }

// La pestaña activa también es estado de la app. Al ponerla en un provider,
// cualquier pantalla puede navegar (p. ej. "Ver todo" en el Inicio) sin
// recibir callbacks por constructor.
final navigationProvider = NotifierProvider<NavigationController, AppTab>(
  NavigationController.new,
);

class NavigationController extends Notifier<AppTab> {
  @override
  AppTab build() => AppTab.home;

  // Asignar `state` notifica a todos los que hacen ref.watch.
  void goTo(AppTab tab) => state = tab;
}

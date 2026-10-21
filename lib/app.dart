import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/settings/settings_controller.dart';
import 'features/welcome/welcome_page.dart';
import 'shell.dart';
import 'theme.dart';

// Ya no recibe controller ni container: cada pantalla los pide con ref.
// S15-01: la pantalla raíz es el cascarón con las pestañas.
// S17-03: la raíz decide entre la bienvenida y las pestañas mirando Ajustes.
// Al terminar la bienvenida no hay que navegar: cambia el estado y esto se
// vuelve a construir.
class InkashApp extends ConsumerWidget {
  const InkashApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // select: solo se reconstruye si cambia la bandera, no el nombre.
    final welcomeCompleted = ref.watch(
      settingsProvider.select((s) => s.whenData((v) => v.welcomeCompleted)),
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Inkash',
      theme: buildInkashTheme(),
      home: welcomeCompleted.when(
        // Un instante al abrir: el fondo de la app, sin parpadeo blanco.
        loading: () => const Scaffold(),
        // Si no se pueden leer los ajustes, no bloqueamos la app.
        error: (_, _) => const InkashShell(),
        data: (completed) =>
            completed ? const InkashShell() : const WelcomePage(),
      ),
    );
  }
}

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  // ProviderScope reemplaza al ProviderContainer manual de S09: crea el
  // contenedor, lo entrega a todos los widgets y lo libera al cerrar.
  //
  // Ya no abrimos la base aquí con un FutureBuilder: ahora la abre el primer
  // provider que la necesita, y si falla se ve en el dashboard con un botón
  // "Reintentar" (antes había que cerrar y abrir la app).
  runApp(const ProviderScope(child: InkashApp()));
}

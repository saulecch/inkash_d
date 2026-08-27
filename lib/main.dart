import 'package:flutter/widgets.dart';
import 'package:riverpod/riverpod.dart';

import 'app.dart';
import 'features/home/presentation/controllers/home_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const InkashBootstrap());
}

// Este widget es el punto donde se conectan Riverpod y la aplicación.
class InkashBootstrap extends StatefulWidget {
  const InkashBootstrap({super.key});

  @override
  State<InkashBootstrap> createState() => _InkashBootstrapState();
}

class _InkashBootstrapState extends State<InkashBootstrap> {
  late final ProviderContainer container;

  @override
  void initState() {
    super.initState();

    // El contenedor guarda y administra los providers de Riverpod.
    container = ProviderContainer();
  }

  @override
  void dispose() {
    // El contenedor se libera junto con el widget que lo creó.
    container.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // main.dart obtiene el controlador y lo entrega a la aplicación.
    return InkashApp(controller: container.read(movimientosControllerProvider));
  }
}

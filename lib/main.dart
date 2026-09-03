import 'package:flutter/widgets.dart';
import 'package:riverpod/riverpod.dart';

import 'app.dart';
import 'features/home/presentation/controllers/home_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const InkashBootstrap());
}

class InkashBootstrap extends StatefulWidget {
  const InkashBootstrap({super.key});

  @override
  State<InkashBootstrap> createState() => _InkashBootstrapState();
}

class _InkashBootstrapState extends State<InkashBootstrap> {
  late final ProviderContainer container;
  late final MovimientosController controller;

  @override
  void initState() {
    super.initState();
    container = ProviderContainer();
    controller = container.read(movimientosControllerProvider);
  }

  @override
  void dispose() {
    container.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkashApp(
      controller: controller,
      container: container,
    );
  }
}

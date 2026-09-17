import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';

import 'app.dart';
import 'database/app_database.dart';
import 'features/home/presentation/controllers/home_controller.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final databaseReady = AppDatabase.instance.database.then<void>((_) {});
  runApp(InkashBootstrap(databaseReady: databaseReady));
}

class InkashBootstrap extends StatefulWidget {
  const InkashBootstrap({required this.databaseReady, super.key});

  final Future<void> databaseReady;

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
    return FutureBuilder<void>(
      future: widget.databaseReady,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildInkashTheme(),
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator(color: kLima)),
            ),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildInkashTheme(),
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.storage_rounded,
                        color: kPeligro,
                        size: 44,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No se pudo iniciar la base de datos',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: kMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return InkashApp(controller: controller, container: container);
      },
    );
  }
}

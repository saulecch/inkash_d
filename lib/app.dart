import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';

import 'features/home/presentation/controllers/home_controller.dart';
import 'home.dart';
import 'theme.dart';

class InkashApp extends StatelessWidget {
  const InkashApp({
    required this.controller,
    required this.container,
    super.key,
  });

  final MovimientosController controller;
  final ProviderContainer container;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Inkash',
      theme: buildInkashTheme(),
      home: HomePage(controller: controller, container: container),
    );
  }
}

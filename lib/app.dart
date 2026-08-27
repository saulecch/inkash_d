import 'package:flutter/material.dart';
import 'package:inkash_d/features/home/presentation/controllers/home_controller.dart';
import 'package:inkash_d/home.dart';
import 'package:inkash_d/theme.dart';

class InkashApp extends StatelessWidget {
  const InkashApp({required this.controller, super.key});

  final MovimientosController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Inkash',
      theme: buildInkashTheme(),
      home: HomePage(controller: controller),
    );
  }
}

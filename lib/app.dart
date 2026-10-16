import 'package:flutter/material.dart';

import 'shell.dart';
import 'theme.dart';

// Ya no recibe controller ni container: cada pantalla los pide con ref.
// S15-01: la pantalla raíz es el cascarón con las pestañas.
class InkashApp extends StatelessWidget {
  const InkashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Inkash',
      theme: buildInkashTheme(),
      home: const InkashShell(),
    );
  }
}

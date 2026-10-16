import 'package:flutter/material.dart';

import '../theme.dart';

// Pantalla temporal para pestañas que aún no existen. Mejor esto que un
// botón que no hace nada: el usuario sabe que no es un error.
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({required this.title, required this.icon, super.key});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: kMuted, size: 40),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            const Text('Próximamente', style: TextStyle(color: kMuted)),
          ],
        ),
      ),
    );
  }
}

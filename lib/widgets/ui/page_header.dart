import 'package:flutter/material.dart';

import '../../theme.dart';

/// S17-01: encabezado común de las pestañas: título grande a la izquierda,
/// una línea de contexto opcional y, si hace falta, una acción a la derecha.
/// Antes cada pantalla inventaba el suyo (tamaños 18, 20, centrado…).
class PageHeader extends StatelessWidget {
  const PageHeader({
    required this.title,
    this.subtitle,
    this.action,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.l,
        Spacing.xl,
        Spacing.l,
        Spacing.l,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.headlineSmall),
                if (subtitle != null) ...[
                  const SizedBox(height: Spacing.xs),
                  Text(subtitle!, style: text.bodySmall),
                ],
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

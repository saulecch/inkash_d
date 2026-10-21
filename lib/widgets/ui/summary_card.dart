import 'package:flutter/material.dart';

import '../../theme.dart';

/// S17-01: tarjeta pequeña del Inicio: icono, etiqueta y valor; se puede
/// tocar. Antes "Cuentas" y "Metas" eran dos copias del mismo Container.
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(Spacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 20, color: kLima),
                const SizedBox(height: Spacing.m),
                Text(label, style: text.bodySmall),
                const SizedBox(height: Spacing.xs),
                Text(
                  value,
                  style: text.titleLarge?.copyWith(
                    fontFeatures: kTabularFigures,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

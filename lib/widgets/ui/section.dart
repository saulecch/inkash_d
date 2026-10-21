import 'package:flutter/material.dart';

import '../../theme.dart';

/// S17-01: grupo de filas sobre una superficie, con título opcional encima.
/// Se usa en Ajustes, Cuentas, Categorías, Metas y Presupuesto: misma forma
/// = misma función.
class Section extends StatelessWidget {
  const Section({required this.children, this.title, super.key});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.l, 0, Spacing.l, Spacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(
                left: Spacing.xs,
                bottom: Spacing.s,
              ),
              child: Text(
                title!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          Material(
            color: kSuperficie,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Corners.card),
              side: const BorderSide(color: kBorde),
            ),
            clipBehavior: Clip.antiAlias, // el "ripple" respeta las esquinas
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const Divider(indent: 56),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

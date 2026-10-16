import 'package:flutter/material.dart';

import '../theme.dart';
import 'app_icons.dart';

// S16-01: rejilla para elegir un icono del catálogo. La usan las hojas de
// Cuentas y Categorías. Recibe las claves y avisa cuál se tocó.
class IconPicker extends StatelessWidget {
  const IconPicker({
    required this.options,
    required this.selected,
    required this.onSelected,
    this.labels = const {},
    super.key,
  });

  final List<String> options; // claves de appIcons
  final String selected;
  final ValueChanged<String> onSelected;
  final Map<String, String> labels; // texto opcional bajo cada icono

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final key in options)
          Tooltip(
            message: labels[key] ?? key,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onSelected(key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: labels.isEmpty ? 44 : 84,
                height: labels.isEmpty ? 44 : 60,
                decoration: BoxDecoration(
                  color: key == selected ? kIconoFondo : kFondo,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: key == selected ? kLima : kBorde),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      iconFor(key),
                      size: 20,
                      color: key == selected ? kLima : kMuted,
                    ),
                    if (labels[key] case final label?) ...[
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          color: key == selected ? kLima : kMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

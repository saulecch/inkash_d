import 'package:flutter/material.dart';

import '../../theme.dart';

/// S17-01: cuerpo común de las hojas inferiores con formulario: título,
/// campos y botones, con el espacio del teclado ya resuelto. Antes cada hoja
/// repetía el mismo Padding con `viewInsets` y su propio título.
class FormSheet extends StatelessWidget {
  const FormSheet({
    required this.title,
    required this.children,
    this.description,
    super.key,
  });

  final String title;
  final String? description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        Spacing.xl,
        0,
        Spacing.xl,
        Spacing.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: text.titleLarge),
          if (description != null) ...[
            const SizedBox(height: Spacing.xs),
            Text(description!, style: text.bodySmall),
          ],
          const SizedBox(height: Spacing.xl),
          ...children,
        ],
      ),
    );
  }
}

/// Abre una hoja inferior con el estilo del tema (asa, esquinas, fondo).
Future<T?> showFormSheet<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: builder,
  );
}

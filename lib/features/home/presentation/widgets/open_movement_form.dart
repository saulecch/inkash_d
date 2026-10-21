import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/deleted_movement.dart';
import '../../../../models/movement.dart';
import '../../../accounts/accounts_page.dart';
import '../../../categories/categories_page.dart';
import '../controllers/home_controller.dart';
import 'movement_bottom_sheet.dart';

/// S16-03: abre el formulario para crear (edit == null) o editar un
/// movimiento. Antes vivía dentro del shell; ahora lo usan el botón (+), el
/// Inicio y el Historial (tocar un movimiento): UN solo lugar.
Future<void> openMovementForm(
  BuildContext context,
  WidgetRef ref, {
  Movement? edit,
}) async {
  final messenger = ScaffoldMessenger.of(context);

  // El 'Saldo inicial' es parte de la cuenta (ADR-0004): se edita allá.
  if (edit?.categoryClassification == 'adjustment') {
    messenger.showSnackBar(
      SnackBar(
        content: const Text('El saldo inicial se edita en Cuentas.'),
        action: SnackBarAction(
          label: 'Abrir',
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const AccountsPage())),
        ),
      ),
    );
    return;
  }

  // read (no watch): en un callback solo queremos llamar métodos.
  final controller = ref.read(homeControllerProvider.notifier);
  DeletedMovement? deleted;

  final result = await showMovementBottomSheet(
    context: context,
    loadOptions: controller.loadFormOptions,
    initial: edit,
    onSave: (newMovement) => edit == null
        ? controller.saveMovement(newMovement)
        : controller.editMovement(edit.id!, newMovement),
    onDelete: edit == null
        ? null
        : () async => deleted = await controller.deleteMovement(edit.id!),
    // S16-02: "+ Nueva" abre la hoja de categoría encima del formulario.
    onNewCategory: (classification) =>
        openCategoryForm(context, ref, initialClassification: classification),
  );
  if (result == null) return;

  // El controller ya reconsultó SQLite; las pantallas se actualizan solas
  // porque hacen ref.watch.
  final undo = deleted;
  // Sin esto, el aviso nuevo espera en fila a que se cierre el anterior.
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(switch (result) {
        'deleted' => 'Movimiento eliminado',
        _ when edit != null => 'Cambios guardados',
        _ => 'Movimiento guardado',
      }),
      action: undo == null
          ? null
          : SnackBarAction(
              label: 'Deshacer',
              onPressed: () => controller.undoDelete(undo),
            ),
    ),
  );
}

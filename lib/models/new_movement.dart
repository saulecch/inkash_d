import '../utils/occurred_on.dart';
import 'movement.dart';

// Lo que entrega el formulario para guardar. Es distinto de `Movement`
// (la fila de la tabla): aquí todavía no hay id, ni signo, ni createdAtMs.
class NewMovement {
  const NewMovement({
    required this.accountId,
    required this.categoryId,
    required this.amountMinor,
    required this.description,
    required this.occurredAt,
    this.notes,
  }) : assert(amountMinor > 0, 'El monto siempre llega positivo');

  final int accountId;
  final int categoryId;

  // Positivo siempre. El signo lo decide la CATEGORÍA al guardar
  // (ver MovementsRepository.insertNew), no el botón Gasto/Ingreso.
  final int amountMinor;
  final String description;
  final DateTime occurredAt;
  final String? notes;

  // Convierte a la fila que se inserta. Dos formatos distintos a propósito:
  // occurredOn = local de 17 dígitos; createdAtMs = epoch en milisegundos.
  Movement toMovement({required int signedAmount, required int createdAtMs}) {
    return Movement(
      accountId: accountId,
      categoryId: categoryId,
      amount: signedAmount,
      description: description,
      occurredOn: encodeOccurredOn(occurredAt),
      notes: notes,
      createdAtMs: createdAtMs,
    );
  }
}

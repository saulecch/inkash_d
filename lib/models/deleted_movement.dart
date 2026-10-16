// S15-04: lo necesario para "Deshacer" un borrado. Para la UI es una caja
// cerrada: no sabe qué hay adentro, solo se la devuelve al repositorio.
class DeletedMovement {
  const DeletedMovement(this.row);

  // La fila tal cual estaba en SQLite (mismo id, categoría, occurred_on y
  // created_at_ms). Restaurar con la fila original evita "parecidos":
  // es EL mismo registro, no uno nuevo con otro id y otra fecha.
  final Map<String, Object?> row;
}

// S16-04: una fila de la pestaña Presupuesto: cuánto se puede gastar en una
// categoría este mes y cuánto se lleva.
class CategoryBudget {
  const CategoryBudget({
    required this.categoryId,
    required this.name,
    required this.spentMinor,
    this.limitMinor,
    this.iconKey,
  });

  final int categoryId;
  final String name;
  final int spentMinor; // positivo, aunque el gasto se guarda negativo
  final int? limitMinor; // null = sin límite definido
  final String? iconKey; // catálogo app_icons

  bool get isExceeded => limitMinor != null && spentMinor > limitMinor!;

  // 0..1 para la barra. Aquí un double está bien: es para dibujar, no dinero.
  double? get progress => limitMinor == null
      ? null
      : (spentMinor / limitMinor!).clamp(0, 1).toDouble();
}

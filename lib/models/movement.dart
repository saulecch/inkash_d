import '../utils/money.dart';

class Movement {
  final int? id;
  final int accountId;
  final int categoryId;
  final int amount;
  final String description;
  final int occurredOn;
  final String? notes;
  final int createdAtMs;

  // S16-01: nombres que llegan por JOIN al LEER (no son columnas de la
  // tabla movements, por eso no van en toMap). null si no se pidieron.
  final String? categoryName;
  final String? accountName;
  // S16-02: el icono de la categoría (catálogo app_icons), también por JOIN.
  final String? categoryIconKey;
  // S16-03: 'expense' / 'income' / 'adjustment', para abrir el formulario
  // en el tipo correcto (y no editar ahí el 'Saldo inicial').
  final String? categoryClassification;

  const Movement({
    this.id,
    required this.accountId,
    required this.categoryId,
    required this.amount,
    required this.description,
    required this.occurredOn,
    this.notes,
    required this.createdAtMs,
    this.categoryName,
    this.accountName,
    this.categoryIconKey,
    this.categoryClassification,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'account_id': accountId,
      'category_id': categoryId,
      'amount': amount,
      'description': description,
      'occurred_on': occurredOn,
      'notes': notes,
      'created_at_ms': createdAtMs,
    };
  }

  factory Movement.fromMap(Map<String, dynamic> map) {
    return Movement(
      id: map['id'] as int?,
      accountId: map['account_id'] as int,
      categoryId: map['category_id'] as int,
      amount: map['amount'] as int,
      description: map['description'] as String,
      occurredOn: map['occurred_on'] as int,
      notes: map['notes'] as String?,
      createdAtMs: map['created_at_ms'] as int,
      categoryName: map['category_name'] as String?,
      accountName: map['account_name'] as String?,
      categoryIconKey: map['category_icon'] as String?,
      categoryClassification: map['category_classification'] as String?,
    );
  }

  Movement copyWith({
    int? id,
    int? accountId,
    int? categoryId,
    int? amount,
    String? description,
    int? occurredOn,
    String? notes,
    int? createdAtMs,
  }) {
    return Movement(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      occurredOn: occurredOn ?? this.occurredOn,
      notes: notes ?? this.notes,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      categoryName: categoryName,
      accountName: accountName,
      categoryIconKey: categoryIconKey,
      categoryClassification: categoryClassification,
    );
  }

  bool get isIngres => amount > 0;
  String get amountFormatted => formatQuetzales(amount);
}

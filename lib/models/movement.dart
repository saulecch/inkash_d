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

  const Movement({
    this.id,
    required this.accountId,
    required this.categoryId,
    required this.amount,
    required this.description,
    required this.occurredOn,
    this.notes,
    required this.createdAtMs,
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
    );
  }

  bool get isIngres => amount > 0;
  String get amountFormatted => formatQuetzales(amount);
}

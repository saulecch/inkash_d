class Movement {
  final int? id;
  final int accountId;
  final int categoryId;
  final int amountMinor;
  final String description;
  final String occurredOn;
  final String? notes;
  final int createdAtMs;

  const Movement({
    this.id,
    required this.accountId,
    required this.categoryId,
    required this.amountMinor,
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
      'amount_minor': amountMinor,
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
      amountMinor: map['amount_minor'] as int,
      description: map['description'] as String,
      occurredOn: map['occurred_on'] as String,
      notes: map['notes'] as String?,
      createdAtMs: map['created_at_ms'] as int,
    );
  }

  Movement copyWith({
    int? id,
    int? accountId,
    int? categoryId,
    int? amountMinor,
    String? description,
    String? occurredOn,
    String? notes,
    int? createdAtMs,
  }) {
    return Movement(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      amountMinor: amountMinor ?? this.amountMinor,
      description: description ?? this.description,
      occurredOn: occurredOn ?? this.occurredOn,
      notes: notes ?? this.notes,
      createdAtMs: createdAtMs ?? this.createdAtMs,
    );
  }

  bool get isIngres => amountMinor > 0;
  String get amountFormatted => _formatQuetzales(amountMinor.abs());

  String _formatQuetzales(int centavos) {
    final entero = centavos ~/ 100;
    final decimales = (centavos % 100).toString().padLeft(2, '0');
    final miles = entero.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
    return 'Q$miles.$decimales';
  }
}

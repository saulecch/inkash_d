class SavingsGoal {
  final int? id;
  final String name;
  final int targetAmountMinor;
  final int savedAmountMinor;
  final String? targetDate;
  final bool isArchived;
  final int createdAtMs;

  const SavingsGoal({
    this.id,
    required this.name,
    required this.targetAmountMinor,
    this.savedAmountMinor = 0,
    this.targetDate,
    this.isArchived = false,
    required this.createdAtMs,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'target_amount_minor': targetAmountMinor,
      'saved_amount_minor': savedAmountMinor,
      'target_date': targetDate,
      'is_archived': isArchived ? 1 : 0,
      'created_at_ms': createdAtMs,
    };
  }

  factory SavingsGoal.fromMap(Map<String, dynamic> map) {
    return SavingsGoal(
      id: map['id'] as int?,
      name: map['name'] as String,
      targetAmountMinor: map['target_amount_minor'] as int,
      savedAmountMinor: map['saved_amount_minor'] as int? ?? 0,
      targetDate: map['target_date'] as String?,
      isArchived: (map['is_archived'] as int) == 1,
      createdAtMs: map['created_at_ms'] as int,
    );
  }

  SavingsGoal copyWith({
    int? id,
    String? name,
    int? targetAmountMinor,
    int? savedAmountMinor,
    String? targetDate,
    bool? isArchived,
    int? createdAtMs,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmountMinor: targetAmountMinor ?? this.targetAmountMinor,
      savedAmountMinor: savedAmountMinor ?? this.savedAmountMinor,
      targetDate: targetDate ?? this.targetDate,
      isArchived: isArchived ?? this.isArchived,
      createdAtMs: createdAtMs ?? this.createdAtMs,
    );
  }

  bool get isActive => !isArchived && savedAmountMinor < targetAmountMinor;

  double get progress {
    if (targetAmountMinor == 0) return 0;
    return (savedAmountMinor / targetAmountMinor).clamp(0.0, 1.0);
  }
}

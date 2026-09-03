class Account {
  final int? id;
  final String name;
  final String type;
  final bool isArchived;
  final int createdAtMs;

  const Account({
    this.id,
    required this.name,
    required this.type,
    this.isArchived = false,
    required this.createdAtMs,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type,
      'is_archived': isArchived ? 1 : 0,
      'created_at_ms': createdAtMs,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      isArchived: (map['is_archived'] as int) == 1,
      createdAtMs: map['created_at_ms'] as int,
    );
  }

  Account copyWith({
    int? id,
    String? name,
    String? type,
    bool? isArchived,
    int? createdAtMs,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isArchived: isArchived ?? this.isArchived,
      createdAtMs: createdAtMs ?? this.createdAtMs,
    );
  }

  String get displayName {
    switch (type) {
      case 'bank':
        return 'Banco';
      case 'card':
        return 'Tarjeta';
      case 'cash':
        return 'Efectivo';
      default:
        return name;
    }
  }
}

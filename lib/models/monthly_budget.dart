class MonthlyBudget {
  final String monthStart;
  final int limitMinor;
  final int createdAtMs;

  const MonthlyBudget({
    required this.monthStart,
    required this.limitMinor,
    required this.createdAtMs,
  });

  Map<String, dynamic> toMap() {
    return {
      'month_start': monthStart,
      'limit_minor': limitMinor,
      'created_at_ms': createdAtMs,
    };
  }

  factory MonthlyBudget.fromMap(Map<String, dynamic> map) {
    return MonthlyBudget(
      monthStart: map['month_start'] as String,
      limitMinor: map['limit_minor'] as int,
      createdAtMs: map['created_at_ms'] as int,
    );
  }

  MonthlyBudget copyWith({
    String? monthStart,
    int? limitMinor,
    int? createdAtMs,
  }) {
    return MonthlyBudget(
      monthStart: monthStart ?? this.monthStart,
      limitMinor: limitMinor ?? this.limitMinor,
      createdAtMs: createdAtMs ?? this.createdAtMs,
    );
  }

  String get limitFormatted => _formatQuetzales(limitMinor);

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

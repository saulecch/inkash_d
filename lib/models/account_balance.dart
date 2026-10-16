// S16-01: una cuenta con su saldo, ya calculado por SQLite.
class AccountBalance {
  const AccountBalance({
    required this.id,
    required this.name,
    required this.type,
    required this.balanceMinor,
    this.initialBalanceMinor = 0,
  });

  final int id;
  final String name;
  final String type;

  // SUM(amount) de sus movimientos. El saldo inicial NO es una columna:
  // en inkash_d es un movimiento de la categoría 'Saldo inicial' (S10),
  // así que ya viene incluido en la suma.
  final int balanceMinor;

  // S16-01: el monto del movimiento 'Saldo inicial' de esta cuenta
  // (negativo = deuda, p. ej. una tarjeta). 0 si no tiene.
  final int initialBalanceMinor;

  // El icono depende del TIPO de cuenta (la tabla no tiene columna icono).
  static const typeIcons = {
    'cash': 'payments',
    'bank': 'account_balance',
    'card': 'credit_card',
  };
  static const typeLabels = {
    'cash': 'Efectivo',
    'bank': 'Banco',
    'card': 'Tarjeta',
  };

  String get iconKey => typeIcons[type] ?? 'payments';
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Riverpod 3 movió el tipo Override a misc.dart.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:inkash_d/app.dart';
import 'package:inkash_d/features/home/presentation/controllers/exchange_rate_provider.dart';
import 'package:inkash_d/features/home/presentation/controllers/home_controller.dart';
import 'package:inkash_d/features/home/presentation/widgets/movement_bottom_sheet.dart';
import 'package:inkash_d/models/account.dart';
import 'package:inkash_d/models/category.dart';
import 'package:inkash_d/models/exchange_rate.dart';
import 'package:inkash_d/models/month_totals.dart';
import 'package:inkash_d/models/monthly_budget.dart';
import 'package:inkash_d/models/movement.dart';
import 'package:inkash_d/models/new_movement.dart';
import 'package:inkash_d/repositories/accounts_repository.dart';
import 'package:inkash_d/repositories/budgets_repository.dart';
import 'package:inkash_d/repositories/categories_repository.dart';
import 'package:inkash_d/repositories/movements_repository.dart';
import 'package:inkash_d/repositories/savings_goals_repository.dart';
import 'package:inkash_d/utils/clock.dart';
import 'package:inkash_d/utils/dates.dart';
import 'package:inkash_d/utils/occurred_on.dart';

// Datos de PRUEBA: occurredOn en el formato real (local, 17 dígitos).
// "Hoy" en estas pruebas es el 15 de octubre de 2026 (ver clockProvider).
Movement _mov(
  int id,
  String description,
  int categoryId,
  int amount,
  int occurredOn,
) => Movement(
  id: id,
  accountId: 1,
  categoryId: categoryId,
  amount: amount,
  description: description,
  occurredOn: occurredOn,
  createdAtMs: 1760537700000,
);

final sampleMovements = [
  _mov(6, 'Uber al trabajo', 3, -3800, 20261015081500000),
  _mov(5, 'Súper La Torre', 4, -28550, 20261014120000000),
  _mov(4, 'Salario quincena', 1, 420000, 20261014090000000),
  _mov(3, 'Café con Ana', 7, -6500, 20261014080000000),
  _mov(2, 'Recibo de luz', 6, -42000, 20261012090000000),
  // Septiembre: NO cuenta para los totales de octubre.
  _mov(1, 'Renta septiembre', 6, -289500, 20260915090000000),
];

// Repositorios falsos: responden lo que la prueba quiera, sin SQLite.
// `rows` hace de tabla `movements` compartida entre los falsos.
class FakeMovementsRepository extends MovementsRepository {
  FakeMovementsRepository(this.recent);

  Future<List<Movement>> Function() recent;
  final rows = <Movement>[];
  var recentCalls = 0;

  @override
  Future<List<Movement>> getRecent(int limit) async {
    recentCalls++;
    return (await recent()).take(limit).toList();
  }

  // En el falso sumamos en Dart; en el real lo hace SQLite (ver la prueba
  // de SQL en save_movement_test.dart).
  @override
  Future<MonthTotals> getMonthTotals(DateTime month) async {
    final from = encodeOccurredOn(monthStart(month));
    final to = encodeOccurredOn(nextMonthStart(month));
    final inMonth = (await recent()).where(
      (m) => m.occurredOn >= from && m.occurredOn < to,
    );
    int sum(bool income) => inMonth
        .where((m) => (m.amount > 0) == income)
        .fold(0, (total, m) => total + m.amount.abs());
    return MonthTotals(expensesMinor: sum(false), incomeMinor: sum(true));
  }

  @override
  Future<int> insertNew(NewMovement newMovement) async {
    rows.insert(
      0,
      newMovement.toMovement(
        signedAmount: -newMovement.amountMinor,
        createdAtMs: 0,
      ),
    );
    return rows.length;
  }
}

class FakeAccountsRepository extends AccountsRepository {
  @override
  Future<int> getTotalBalance() async => 416200;

  @override
  Future<List<Account>> getActive() async => const [
    Account(id: 1, name: 'Efectivo', type: 'cash', createdAtMs: 0),
  ];
}

class FakeCategoriesRepository extends CategoriesRepository {
  @override
  Future<List<Category>> getAll() async => const [
    Category(id: 3, name: 'Transporte', classification: 'expense'),
  ];
}

// Solo octubre tiene presupuesto: si el reloj no se usara, no habría.
class FakeBudgetsRepository extends BudgetsRepository {
  @override
  Future<MonthlyBudget?> getByMonth(String monthStart) async =>
      monthStart == '2026-10-01'
      ? const MonthlyBudget(
          monthStart: '2026-10-01',
          limitMinor: 650000,
          createdAtMs: 0,
        )
      : null;
}

class FakeSavingsGoalsRepository extends SavingsGoalsRepository {
  @override
  Future<int> getActiveCount() async => 3;
}

List<Override> overridesWith(FakeMovementsRepository movements) => [
  // Override: en la prueba, cada provider entrega su repositorio falso.
  movementsRepositoryProvider.overrideWithValue(movements),
  accountsRepositoryProvider.overrideWithValue(FakeAccountsRepository()),
  categoriesRepositoryProvider.overrideWithValue(FakeCategoriesRepository()),
  budgetsRepositoryProvider.overrideWithValue(FakeBudgetsRepository()),
  savingsGoalsRepositoryProvider.overrideWithValue(
    FakeSavingsGoalsRepository(),
  ),
  // Reloj fijo: la prueba dice "Octubre 2026" hoy y dentro de un año.
  clockProvider.overrideWithValue(() => DateTime(2026, 10, 15, 9)),
  // La tarjeta del dólar no debe salir a internet en una prueba.
  exchangeRateProvider.overrideWith(
    (ref) async => ExchangeRate(
      gtqPerUsdTenThousandths: 76543,
      updatedAt: DateTime(2026, 10, 15, 8),
    ),
  ),
];

Widget appWith(FakeMovementsRepository movements) {
  return ProviderScope(
    overrides: overridesWith(movements),
    child: const InkashApp(),
  );
}

void main() {
  testWidgets('cargando -> datos: saldo, mes real y totales del mes', (
    tester,
  ) async {
    final reading = Completer<List<Movement>>();
    await tester.pumpWidget(
      appWith(FakeMovementsRepository(() => reading.future)),
    );

    // Mientras el Future no termina: estado de carga.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    reading.complete(sampleMovements);
    await tester.pumpAndSettle();

    // Saldo grande + tarjeta "Cuentas".
    expect(find.textContaining('Q4,162.00'), findsNWidgets(2));
    expect(find.text('Uber al trabajo'), findsOneWidget);
    expect(find.text('3 activas'), findsOneWidget);
    expect(find.text('Dólar hoy · Q7.65'), findsOneWidget);
    // S15-02: el mes sale del reloj (fijo en la prueba).
    expect(find.text('Octubre 2026'), findsOneWidget);
    // Gastos de octubre: 38 + 285.50 + 65 + 420. La renta de septiembre no.
    expect(find.textContaining('Q808.50 de'), findsOneWidget);
    // Solo los últimos 5 de 6 en el Inicio.
    expect(find.text('Renta septiembre'), findsNothing);
  });

  testWidgets('vacío: invita a registrar el primer movimiento', (tester) async {
    await tester.pumpWidget(appWith(FakeMovementsRepository(() async => [])));
    await tester.pumpAndSettle();

    expect(find.textContaining('Aún no hay movimientos'), findsOneWidget);
  });

  testWidgets('error -> Reintentar -> datos', (tester) async {
    final movements = FakeMovementsRepository(
      () async => throw Exception('disco lleno'),
    );
    await tester.pumpWidget(appWith(movements));
    await tester.pumpAndSettle();

    expect(find.text('No pudimos leer tus movimientos.'), findsOneWidget);
    // retry: null -> Riverpod NO reintentó por su cuenta.
    expect(movements.recentCalls, 1);

    // El usuario reintenta y esta vez la base responde.
    movements.recent = () async => sampleMovements;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Uber al trabajo'), findsOneWidget);
  });

  test('saveMovement guarda y vuelve a consultar (invalidateSelf)', () async {
    late final FakeMovementsRepository movements;
    movements = FakeMovementsRepository(() async => [...movements.rows]);
    final container = ProviderContainer(overrides: overridesWith(movements));
    addTearDown(container.dispose);

    expect(
      (await container.read(homeControllerProvider.future)).recentMovements,
      isEmpty,
    );

    await container
        .read(homeControllerProvider.notifier)
        .saveMovement(
          NewMovement(
            accountId: 1,
            categoryId: 3,
            amountMinor: 1250,
            description: 'Bus demo',
            occurredAt: DateTime(2026, 10, 15, 8, 15),
          ),
        );

    final summary = container.read(homeControllerProvider).requireValue;
    expect(summary.recentMovements.single.description, 'Bus demo');
    expect(movements.recentCalls, 2); // se leyó de nuevo, no lista.add
  });

  testWidgets('la barra cambia de pestaña y "Ver todo" abre Historial', (
    tester,
  ) async {
    await tester.pumpWidget(
      appWith(FakeMovementsRepository(() async => sampleMovements)),
    );
    await tester.pumpAndSettle();

    // IndexedStack: las pestañas ocultas existen pero están "offstage",
    // y find las ignora por defecto.
    expect(find.text('Próximamente'), findsNothing);

    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();
    expect(find.text('Próximamente'), findsOneWidget);

    // "Agregar" es una acción: abre el formulario sobre la pestaña actual.
    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();
    expect(find.byType(MovementBottomSheet), findsOneWidget);
    Navigator.of(tester.element(find.byType(MovementBottomSheet))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Inicio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver todo'));
    await tester.pumpAndSettle();
    expect(find.text('Historial'), findsNWidgets(2)); // barra + pantalla
    expect(find.text('Próximamente'), findsOneWidget);
  });
}

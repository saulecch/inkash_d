import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Riverpod 3 movió el tipo Override a misc.dart.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:inkash_d/app.dart';
import 'package:inkash_d/features/home/presentation/controllers/exchange_rate_provider.dart';
import 'package:inkash_d/features/home/presentation/controllers/home_controller.dart';
import 'package:inkash_d/models/exchange_rate.dart';
import 'package:inkash_d/models/monthly_budget.dart';
import 'package:inkash_d/models/movement.dart';
import 'package:inkash_d/models/new_movement.dart';
import 'package:inkash_d/repositories/accounts_repository.dart';
import 'package:inkash_d/repositories/budgets_repository.dart';
import 'package:inkash_d/repositories/movements_repository.dart';
import 'package:inkash_d/repositories/savings_goals_repository.dart';

// Datos de PRUEBA: occurredOn en el formato real (local, 17 dígitos).
const sampleMovements = [
  Movement(
    id: 2,
    accountId: 1,
    categoryId: 3,
    amount: -3800,
    description: 'Uber al trabajo',
    occurredOn: 20261015081500000,
    createdAtMs: 1760537700000,
  ),
  Movement(
    id: 1,
    accountId: 1,
    categoryId: 1,
    amount: 420000,
    description: 'Salario quincena',
    occurredOn: 20261014090000000,
    createdAtMs: 1760454000000,
  ),
];

// Repositorios falsos: responden lo que la prueba quiera, sin SQLite.
// `rows` hace de tabla `movements` compartida entre los falsos.
class FakeMovementsRepository extends MovementsRepository {
  FakeMovementsRepository(this.recent);

  Future<List<Movement>> Function() recent;
  final rows = <Movement>[];
  var recentCalls = 0;

  @override
  Future<List<Movement>> getRecent(int limit) {
    recentCalls++;
    return recent();
  }

  @override
  Future<int> getMonthlyExpenses(String yearMonth) async => -3800;

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
}

class FakeBudgetsRepository extends BudgetsRepository {
  @override
  Future<MonthlyBudget?> getByMonth(String monthStart) async => null;
}

class FakeSavingsGoalsRepository extends SavingsGoalsRepository {
  @override
  Future<int> getActiveCount() async => 3;
}

List<Override> overridesWith(FakeMovementsRepository movements) => [
  // Override: en la prueba, cada provider entrega su repositorio falso.
  movementsRepositoryProvider.overrideWithValue(movements),
  accountsRepositoryProvider.overrideWithValue(FakeAccountsRepository()),
  budgetsRepositoryProvider.overrideWithValue(FakeBudgetsRepository()),
  savingsGoalsRepositoryProvider.overrideWithValue(
    FakeSavingsGoalsRepository(),
  ),
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
  testWidgets('cargando -> datos: muestra saldo y movimientos', (tester) async {
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
}

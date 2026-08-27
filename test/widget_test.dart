import 'package:flutter_test/flutter_test.dart';
import 'package:inkash_d/app.dart';
import 'package:inkash_d/features/home/presentation/controllers/home_controller.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  test('suma los gastos y calcula el saldo disponible', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(movimientosControllerProvider);

    expect(controller.totalGastadoCentavos, 370350);
    expect(controller.saldoDisponibleCentavos, 279650);
  });

  testWidgets('muestra el saldo calculado en la pantalla', (tester) async {
    final controller = MovimientosController();
    await tester.pumpWidget(InkashApp(controller: controller));

    expect(find.text('Q2,796.50'), findsOneWidget);
    expect(find.text('Has usado Q3,703.50 de Q6,500.00'), findsOneWidget);
  });
}

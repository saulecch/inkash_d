import 'package:riverpod/riverpod.dart';

final movimientosControllerProvider = Provider<MovimientosController>((ref) {
  return MovimientosController();
});

class MovimientosController {
  MovimientosController()
    : gastosCentavos = const [3800, 28550, 6500, 42000, 289500];

  final int limiteMensualCentavos = 650000;
  final List<int> gastosCentavos;

  int get totalGastadoCentavos {
    return gastosCentavos.fold(0, (total, gasto) => total + gasto);
  }

  int get saldoDisponibleCentavos {
    return limiteMensualCentavos - totalGastadoCentavos;
  }
}

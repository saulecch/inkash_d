import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/category.dart';
import '../home/presentation/controllers/home_controller.dart';

// S16-02: TODAS las categorías (también archivadas y 'adjustment'). La
// pantalla de gestión decide cuáles mostrar; el formulario de movimientos
// ofrece solo las activas del tipo elegido.
final categoriesProvider = FutureProvider<List<Category>>(
  (ref) => ref.watch(categoriesRepositoryProvider).getAll(),
  retry: (_, _) => null,
);

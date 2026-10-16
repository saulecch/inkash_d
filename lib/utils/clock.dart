import 'package:flutter_riverpod/flutter_riverpod.dart';

// S15-02: "¿qué hora es?" también es una dependencia. Si el código llama
// DateTime.now() directo, una prueba que pasa hoy falla el mes que viene.
// Con este provider, las pruebas lo reemplazan por una fecha fija.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

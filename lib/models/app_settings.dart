// S17-02: lo que el usuario configura en Ajustes.
class AppSettings {
  const AppSettings({required this.userName, required this.monthlyLimitMinor});

  final String userName; // '' = el usuario no lo ha dicho
  final int monthlyLimitMinor; // 0 = sin límite definido

  // Antes el Inicio decía 'Hola, Kevin' escrito a mano.
  String get greeting => userName.isEmpty ? 'Hola' : 'Hola, $userName';
}

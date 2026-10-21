// S17-02: lo que el usuario configura en Ajustes.
class AppSettings {
  const AppSettings({
    required this.userName,
    required this.monthlyLimitMinor,
    this.welcomeCompleted = false,
  });

  final String userName; // '' = el usuario no lo ha dicho
  final int monthlyLimitMinor; // 0 = sin límite definido

  // S17-03: ¿ya pasó por la bienvenida? Vive en app_settings, así que
  // "Borrar todos mis datos" lo reinicia: quien empieza de cero la ve otra vez.
  final bool welcomeCompleted;

  // Antes el Inicio decía 'Hola, Kevin' escrito a mano.
  String get greeting => userName.isEmpty ? 'Hola' : 'Hola, $userName';
}

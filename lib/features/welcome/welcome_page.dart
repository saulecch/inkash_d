import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/account_balance.dart';
import '../../theme.dart';
import '../../utils/parse_amount.dart';
import '../../widgets/app_icons.dart';
import '../accounts/account_balances_provider.dart';
import '../settings/settings_controller.dart';

/// S17-03: la primera vez que se abre la app. Tres preguntas en orden, y
/// cada una deja algo listo para que el Inicio no empiece vacío:
/// 1. ¿Cómo te llamas? (opcional)
/// 2. ¿Cuánto quieres gastar al mes? (obligatorio: sin límite, el Inicio
///    no puede decir "te quedan")
/// 3. ¿Cuánto tienes hoy en cada cuenta? (opcional)
class WelcomePage extends ConsumerStatefulWidget {
  const WelcomePage({super.key});

  @override
  ConsumerState<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends ConsumerState<WelcomePage> {
  static const _steps = 3;
  final _pages = PageController();
  final _name = TextEditingController();
  final _limit = TextEditingController();
  final _balances = <int, TextEditingController>{}; // por id de cuenta
  int _step = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _limit.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pages.dispose();
    _name.dispose();
    _limit.dispose();
    for (final controller in _balances.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _balance(AccountBalance account) =>
      _balances.putIfAbsent(account.id, TextEditingController.new);

  // Cada paso decide si se puede avanzar. Mismo parser sin double.
  bool get _stepValid => switch (_step) {
    1 => parseAmountMinor(_limit.text) != null,
    _ => true, // el nombre y los saldos son opcionales
  };

  Future<void> _goTo(int step) async {
    FocusScope.of(context).unfocus();
    setState(() => _step = step);
    await _pages.animateToPage(
      step,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _next(List<AccountBalance> accounts) async {
    if (_step < _steps - 1) return _goTo(_step + 1);
    if (_saving) return; // guard de doble toque
    setState(() => _saving = true);
    await ref
        .read(settingsProvider.notifier)
        .completeWelcome(
          name: _name.text,
          monthlyLimitMinor: parseAmountMinor(_limit.text)!,
          initialBalances: [
            for (final account in accounts)
              if (parseAmountMinor(_balance(account).text) case final minor?)
                (account, minor),
          ],
        );
    // No hace falta navegar: la raíz de la app hace watch de Ajustes y,
    // con welcomeCompleted = true, muestra las pestañas.
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final accounts =
        ref.watch(accountBalancesProvider).value ?? const <AccountBalance>[];

    Widget question(String title, String help, Widget field) {
      return ListView(
        padding: const EdgeInsets.all(Spacing.xl),
        children: [
          Text(title, style: text.headlineSmall),
          const SizedBox(height: Spacing.s),
          Text(help, style: text.bodyMedium?.copyWith(color: kMuted)),
          const SizedBox(height: Spacing.xl),
          field,
        ],
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Indicador de avance: aquí SÍ es una secuencia real de pasos.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.xl,
                Spacing.xl,
                Spacing.xl,
                0,
              ),
              child: Row(
                children: [
                  for (var i = 0; i < _steps; i++) ...[
                    if (i > 0) const SizedBox(width: Spacing.s),
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: Spacing.xs,
                        decoration: BoxDecoration(
                          color: i <= _step ? kLima : kBorde,
                          borderRadius: BorderRadius.circular(Spacing.xs),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.xl,
                Spacing.s,
                Spacing.xl,
                0,
              ),
              child: Text(
                'Paso ${_step + 1} de $_steps',
                style: text.bodySmall,
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                // Se avanza con los botones: así el paso 2 no se salta.
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  question(
                    'Te damos la bienvenida a Inkash',
                    'Lleva tus gastos en quetzales. Todo se queda en tu '
                        'teléfono. Para empezar, ¿cómo te llamas?',
                    TextField(
                      controller: _name,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Tu nombre (opcional)',
                      ),
                    ),
                  ),
                  question(
                    '¿Cuánto quieres gastar al mes?',
                    'Es tu límite. El Inicio te dirá cuánto te queda. '
                        'Lo puedes cambiar en Ajustes.',
                    TextField(
                      controller: _limit,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: text.headlineSmall?.copyWith(
                        fontFeatures: kTabularFigures,
                      ),
                      decoration: InputDecoration(
                        prefixText: 'Q ',
                        hintText: '0.00',
                        errorText:
                            _limit.text.isNotEmpty &&
                                parseAmountMinor(_limit.text) == null
                            ? 'Mayor que 0 y hasta 2 decimales'
                            : null,
                      ),
                    ),
                  ),
                  question(
                    '¿Cuánto tienes hoy?',
                    'Así tus cuentas empiezan con el saldo real. Puedes '
                        'dejarlo en blanco y agregar más cuentas después.',
                    Column(
                      children: [
                        for (final account in accounts)
                          Padding(
                            padding: const EdgeInsets.only(bottom: Spacing.m),
                            child: TextField(
                              controller: _balance(account),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: account.name,
                                prefixText: 'Q ',
                                prefixIcon: Icon(iconFor(account.iconKey)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Spacing.xl),
              child: Row(
                children: [
                  if (_step > 0) ...[
                    TextButton(
                      onPressed: () => _goTo(_step - 1),
                      child: const Text('Atrás'),
                    ),
                    const SizedBox(width: Spacing.m),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: _stepValid && !_saving
                          ? () => _next(accounts)
                          : null,
                      child: Text(
                        _step == _steps - 1 ? 'Empezar' : 'Continuar',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

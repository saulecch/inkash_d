import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../utils/money.dart';

/// S17-01: un monto en quetzales con números tabulares. Con [signed], el
/// signo se escribe ("−Q12.50", "+Q12.50"); con [colored], positivo en lima
/// y negativo en rojo: el color REPITE lo que dice el signo, no lo
/// reemplaza (hay personas que no distinguen esos colores).
class MoneyText extends StatelessWidget {
  const MoneyText(
    this.minor, {
    this.style,
    this.colored = false,
    this.signed = false,
    super.key,
  });

  final int minor;
  final TextStyle? style;
  final bool colored;
  final bool signed;

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    final color = !colored || minor == 0
        ? null
        : minor < 0
        ? kPeligro
        : kLima;
    final sign = minor < 0 ? '−' : (signed && minor > 0 ? '+' : '');
    return Text(
      '$sign${formatQuetzales(minor)}',
      style: base.copyWith(color: color, fontFeatures: kTabularFigures),
    );
  }
}

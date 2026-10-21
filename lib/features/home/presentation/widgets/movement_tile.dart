import 'package:flutter/material.dart';

import '../../../../models/movement.dart';
import '../../../../theme.dart';
import '../../../../utils/dates.dart';
import '../../../../utils/occurred_on.dart';
import '../../../../widgets/app_icons.dart';
import '../../../../widgets/ui/money_text.dart';

// S15-03: antes era la función detailListTile() de home.dart, con 5
// parámetros sueltos. Ahora la usan el Inicio y el Historial: un widget
// reutilizable que recibe el Movement y decide cómo mostrarlo.
class MovementTile extends StatelessWidget {
  const MovementTile({required this.movement, this.onTap, super.key});

  final Movement movement;
  final VoidCallback? onTap; // S16-03: tocar = editar

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final isIncome = movement.amount >= 0;
    // decodeOccurredOn reemplaza el substring a mano que había en HomePage.
    final date = shortDate(decodeOccurredOn(movement.occurredOn));
    // S16-01: 'Transporte · Efectivo'. Si no vinieron los nombres, la fecha.
    final names = [?movement.categoryName, ?movement.accountName];
    final subtitle = names.isEmpty ? date : names.join(' · ');

    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: kIconoFondo,
          borderRadius: BorderRadius.circular(Corners.control),
        ),
        child: Icon(iconFor(movement.categoryIconKey), color: kLima, size: 20),
      ),
      title: Text(movement.description),
      subtitle: Text(subtitle),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // S17-01: el signo SIEMPRE se escribe; el lima solo lo refuerza.
          MoneyText(
            movement.amount,
            signed: true,
            style: text.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: isIncome ? kLima : kTexto,
            ),
          ),
          Text(date, style: text.bodySmall?.copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../models/movement.dart';
import '../../../../theme.dart';
import '../../../../utils/dates.dart';
import '../../../../utils/occurred_on.dart';
import '../../../../widgets/app_icons.dart';

// S15-03: antes era la función detailListTile() de home.dart, con 5
// parámetros sueltos. Ahora la usan el Inicio y el Historial: un widget
// reutilizable que recibe el Movement y decide cómo mostrarlo.
class MovementTile extends StatelessWidget {
  const MovementTile({required this.movement, super.key});

  final Movement movement;

  @override
  Widget build(BuildContext context) {
    final isIncome = movement.amount >= 0;
    // decodeOccurredOn reemplaza el substring a mano que había en HomePage.
    final date = shortDate(decodeOccurredOn(movement.occurredOn));
    // S16-01: 'Transporte · Efectivo'. Si no vinieron los nombres, la fecha.
    final names = [?movement.categoryName, ?movement.accountName];
    final subtitle = names.isEmpty ? date : names.join(' · ');

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: kIconoFondo,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(iconFor(movement.categoryIconKey), color: kLima),
      ),
      title: Text(movement.description, style: const TextStyle(color: kTexto)),
      subtitle: Text(subtitle, style: const TextStyle(color: kMuted)),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${isIncome ? '+' : '−'} ${movement.amountFormatted}',
            style: TextStyle(fontSize: 13, color: isIncome ? kLima : kTexto),
          ),
          Text(date, style: const TextStyle(fontSize: 10, color: kMuted)),
        ],
      ),
    );
  }
}

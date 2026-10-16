import 'package:flutter/material.dart';

// S16-01: el icono se guarda en SQLite como TEXTO (SQLite no sabe qué es un
// IconData). Este catálogo es la ÚNICA traducción texto -> icono de la app,
// y también la lista que ofrecen los selectores (cuentas y categorías).
const appIcons = <String, IconData>{
  // Cuentas (una por tipo: cash, bank, card)
  'payments': Icons.payments_outlined,
  'account_balance': Icons.account_balance_outlined,
  'credit_card': Icons.credit_card,
  // Categorías
  'directions_bus': Icons.directions_bus,
  'shopping_cart': Icons.shopping_cart,
  'restaurant': Icons.restaurant,
  'local_cafe': Icons.local_cafe,
  'movie': Icons.movie_outlined,
  'bolt': Icons.bolt,
  'home': Icons.home_outlined,
  'school': Icons.school_outlined,
  'health': Icons.local_hospital_outlined,
  'soap': Icons.soap_outlined,
  'pets': Icons.pets,
  'phone': Icons.phone_iphone,
  'gift': Icons.card_giftcard,
  'work': Icons.work_outline,
  'savings': Icons.savings_outlined,
  'arrow_upward': Icons.arrow_upward,
  'attach_money': Icons.attach_money,
};

// null o una clave desconocida (dato viejo) -> un icono genérico.
IconData iconFor(String? key) => appIcons[key] ?? Icons.receipt_long;

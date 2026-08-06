import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

const kFondo = Color(0xFF0E120C);
const kSuperficie = Color(0xFF181E14);
const kBorde = Color(0xFF2A3222);
const kTexto = Color(0xFFF1F4EA);
const kMuted = Color(0xFF8F9C80);
const kLima = Color(0xFFC8F54E); // --color-accent
const kIconoFondo = Color(0xFF37491C); // --color-accent-300

const kFig = TextStyle(fontFamily: 'monospace'); // cifras (Azeret Mono)

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Inkash',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kFondo,
        colorScheme: .fromSeed(seedColor: kLima, brightness: Brightness.dark),
      ),
      home: Scaffold(
        body: ListView(
          padding: EdgeInsets.all(16),
          children: [
            Row(
              children: const [
                Text('Hola, Kevin', style: TextStyle(fontSize: 15)),
                Spacer(),
                Text(
                  'Julio 2026',
                  style: TextStyle(fontSize: 12, color: kMuted),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'TE QUEDAN DISPONIBLES',
                  style: TextStyle(fontSize: 11, color: kLima),
                ),
                Text(
                  'Q2,796.50',
                  style: TextStyle(fontSize: 52, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 10),
                LinearProgressIndicator(
                  value: 0.57,
                  color: kLima,
                  minHeight: 8,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
                SizedBox(height: 8),
                Text(
                  'Has usado Q3,703.50 de Q6,500.00',
                  style: TextStyle(fontSize: 12, color: kMuted),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                heroCard('Cuentas', 'Q7,810.00'),
                SizedBox(width: 16),
                heroCard('Metas de ahorro', '3 activas'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: .spaceBetween,
              children: [
                const Text(
                  'Últimos movimientos',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Ver todo',
                    style: TextStyle(fontSize: 13, color: kLima),
                  ),
                ),
              ],
            ),
            detailListTile(
              Icons.directions_bus,
              'Uber al trabajo',
              'Transporte · Tarjeta',
              '− Q38.00',
              'Hoy',
            ),
            detailListTile(
              Icons.shopping_cart,
              'Súper La Torre',
              'Súper y comida · Tarjeta',
              '− Q285.50',
              'Ayer',
            ),
            detailListTile(
              Icons.arrow_upward,
              'Salario quincena',
              'Ingreso · Banco',
              '+ Q4,200.00',
              'Ayer',
              isIncome: true,
            ),
            detailListTile(
              Icons.local_cafe,
              'Café con Ana',
              'Entretenimiento · Efectivo',
              '− Q65.00',
              'Ayer',
            ),
            detailListTile(
              Icons.bolt,
              'Recibo de luz (EEGSA)',
              'Servicios · Banco',
              '− Q420.00',
              'Lun 20',
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 0,
          selectedItemColor: kLima,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Presupuesto',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle, size: 34),
              label: 'Agregar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt),
              label: 'Historial',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Ajustes',
            ),
          ],
        ),
      ),
    );
  }
}

Widget detailListTile(
  IconData icon,
  String title,
  String subtitle,
  String amount,
  String date, {
  bool isIncome = false,
}) {
  return ListTile(
    leading: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: kIconoFondo,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(icon, color: kLima),
    ),
    title: Text(title, style: TextStyle(color: kTexto)),
    subtitle: Text(subtitle, style: TextStyle(color: kMuted)),
    trailing: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          amount,
          style: TextStyle(fontSize: 13, color: isIncome ? kLima : kTexto),
        ),
        Text(date, style: TextStyle(fontSize: 10, color: kMuted)),
      ],
    ),
  );
}

Widget heroCard(String title, String content) {
  return Expanded(
    child: Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSuperficie,
        border: Border.all(color: kBorde),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(title, style: TextStyle(fontSize: 14)),
          Text(content, style: TextStyle(fontSize: 20)),
        ],
      ),
    ),
  );
}

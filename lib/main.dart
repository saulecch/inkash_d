import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: Scaffold(
        body: ListView(
          padding: EdgeInsets.all(16),
          children: [
            Row(
              children: const [
                Text('Hola, Kevin', style: TextStyle(fontSize: 15)),
                Spacer(),
                Text('Julio 2026', style: TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 22),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('TE QUEDAN DISPONIBLES', style: TextStyle(fontSize: 11)),
                SizedBox(height: 6),
                Text('Q2,796.50', style: TextStyle(fontSize: 52)),
                SizedBox(height: 16),
                LinearProgressIndicator(value: 0.57),
                SizedBox(height: 7),
                Text(
                  'Has usado Q3,703.50 de Q6,500.00',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    color: Colors.grey.shade300,
                    child: Column(
                      crossAxisAlignment: .start,
                      children: [
                        Text('Cuentas', style: TextStyle(fontSize: 14)),
                        Text('Q.7,810', style: TextStyle(fontSize: 20)),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    color: Colors.grey.shade300,
                    child: Column(
                      crossAxisAlignment: .start,
                      children: [
                        Text('Metas de ahorro', style: TextStyle(fontSize: 14)),
                        Text('3 activas', style: TextStyle(fontSize: 20)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

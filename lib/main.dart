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
          children: [
            Row(
              mainAxisAlignment: .spaceBetween,
              children: [Text('Hola, Kevin'), Text('Julio 2026')],
            ),
            Column(
              children: [
                Text('TE QUEDAN DISPONIBLES', style: TextStyle(fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

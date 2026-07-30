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
              mainAxisAlignment: .spaceBetween,
              children: [Text('Hola, Kevin'), Text('Julio 2026')],
            ),
            SizedBox(height: 20),
            Column(
              crossAxisAlignment: .start,
              children: [
                Text('TE QUEDAN DISPONIBLES', style: TextStyle(fontSize: 10)),
                Text('Q.2976.50', style: TextStyle(fontSize: 50)),
                LinearProgressIndicator(value: 0.57),
                Text('Has usado Q.3,7...', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

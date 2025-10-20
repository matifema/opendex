import 'package:flutter/material.dart';

import 'pages/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PokeSnapApp());
}

class PokeSnapApp extends StatelessWidget {
  const PokeSnapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PokéSnap PixelMon',
      theme: ThemeData(
        colorSchemeSeed: Colors.redAccent,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
      title: 'PokéDex',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFDC0A2D), // Pokedex Red
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.vt323TextTheme(),
      ),
      home: const HomePage(),
    );
  }
}

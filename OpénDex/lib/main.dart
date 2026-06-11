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
      title: 'OpénDex',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFDC0A2D),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.vt323TextTheme().copyWith(
          displayLarge: GoogleFonts.vt323(fontSize: 48, fontWeight: FontWeight.bold),
          displayMedium: GoogleFonts.vt323(fontSize: 36, fontWeight: FontWeight.bold),
          titleLarge: GoogleFonts.vt323(fontSize: 28, fontWeight: FontWeight.bold),
          titleMedium: GoogleFonts.vt323(fontSize: 22),
          bodyLarge: GoogleFonts.vt323(fontSize: 20),
          bodyMedium: GoogleFonts.vt323(fontSize: 18),
          bodySmall: GoogleFonts.vt323(fontSize: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 4,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        dialogTheme: DialogTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

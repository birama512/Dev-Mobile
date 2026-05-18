import 'package:flutter/material.dart';
import 'pages/page_accueil.dart';

void main() {
  runApp(const MonApp());
}

class MonApp extends StatelessWidget {
  const MonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AudioNova',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D14),
        primaryColor: const Color(0xFF6C63FF),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6C63FF),
          secondary: Color(0xFF00E5FF),
          surface: Color(0xFF1A1A24),
        ),
        fontFamily: 'Inter', // Assuming standard clean font fallback
        useMaterial3: true,
      ),
      home: PageAccueil(),
    );
  }
}

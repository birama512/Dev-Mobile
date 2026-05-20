import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'pages/page_accueil.dart';

void main() async {
  // Obligatoire avant tout appel aux plugins (path_provider, sqflite…)
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise sqflite_common_ffi sur Windows / Linux / macOS
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MonApp());
}

class MonApp extends StatelessWidget {
  const MonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Musique',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF6C63FF),
        colorScheme: ColorScheme.dark(
          primary:   const Color(0xFF6C63FF),
          secondary: const Color(0xFF00E5FF),
        ),
        scaffoldBackgroundColor: const Color(0xFF0D0D14),
      ),
      home: const PageAccueil(),
    );
  }
}

import 'package:flutter/material.dart';
import 'pages/page_liste_morceaux.dart';

void main() {
  runApp(const MonApplication());
}

class MonApplication extends StatelessWidget {
  const MonApplication({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lecteur Audio',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const PageListeMorceaux(),
    );
  }
}
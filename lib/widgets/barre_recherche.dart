import 'package:flutter/material.dart';

class BarreRecherche extends StatelessWidget {
  final Function(String)? onChanged;

  const BarreRecherche({super.key, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Rechercher un morceau, artiste...",
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          border: InputBorder.none,
          icon: Icon(Icons.search, color: Colors.white.withOpacity(0.5)),
        ),
      ),
    );
  }
}
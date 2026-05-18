import 'package:flutter/material.dart';

class BarreRecherche extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final String placeholder;

  const BarreRecherche({
    super.key,
    required this.onChanged,
    this.placeholder = 'Rechercher...',
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF1A1A2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: const Icon(Icons.search_rounded, color: Colors.white38),
      ),
    );
  }
}

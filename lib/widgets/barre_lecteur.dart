import 'package:flutter/material.dart';

class BarreLecteur extends StatelessWidget {
  const BarreLecteur({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(color: Color(0xFF0F0F1A)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('No track', style: TextStyle(color: Colors.white70)),
          IconButton(
            icon: const Icon(Icons.play_arrow_rounded, color: Color(0xFF7C3AED)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

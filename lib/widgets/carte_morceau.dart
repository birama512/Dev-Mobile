import 'package:flutter/material.dart';
import '../models/morceau.dart';

class CarteMorceau extends StatelessWidget {
  final Morceau morceau;
  final VoidCallback onTap;
  final VoidCallback onFavoriToggle;

  const CarteMorceau({
    super.key,
    required this.morceau,
    required this.onTap,
    required this.onFavoriToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A1A2E),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withAlpha(38),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.music_note_rounded, color: Colors.white70),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      morceau.titre,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      morceau.artiste,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onFavoriToggle,
                icon: Icon(
                  morceau.estFavori ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: morceau.estFavori ? const Color(0xFFEC4899) : Colors.white38,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

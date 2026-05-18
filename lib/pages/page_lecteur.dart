import 'package:flutter/material.dart';
import '../models/morceau.dart';

class PageLecteur extends StatelessWidget {
  final Morceau morceau;
  final List<Morceau> playlist;

  const PageLecteur({
    super.key,
    required this.morceau,
    required this.playlist,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Lecteur'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              morceau.titre,
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              morceau.artiste,
              style: const TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Text('Playlist', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: playlist.length,
                itemBuilder: (ctx, index) {
                  final item = playlist[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                    title: Text(item.titre, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(item.artiste, style: const TextStyle(color: Colors.white54)),
                    trailing: index == 0 ? const Icon(Icons.play_arrow_rounded, color: Color(0xFF7C3AED)) : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

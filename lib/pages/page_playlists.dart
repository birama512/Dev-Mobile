import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../models/morceau.dart';
import 'page_lecteur.dart';
import '../widgets/carte_morceau.dart';
import 'page_details_playlist.dart';

class PagePlaylists extends StatelessWidget {
  PagePlaylists({super.key});

  final List<Playlist> playlists = [
    Playlist(
      nom: "Chill Vibes",
      morceaux: [
        Morceau(titre: "Ocean Echoes", artiste: "Deep Blue", chemin: "", duree: const Duration(minutes: 2, seconds: 50)),
        Morceau(titre: "Midnight Drive", artiste: "Luna", chemin: "", duree: const Duration(minutes: 5, seconds: 12)),
      ],
    ),
    Playlist(
      nom: "Workout Mix",
      morceaux: [
        Morceau(titre: "Cyberpunk City", artiste: "Nexus 9", chemin: "", duree: const Duration(minutes: 4, seconds: 30)),
        Morceau(titre: "Neon Dreams", artiste: "Synthwave Collective", chemin: "", duree: const Duration(minutes: 3, seconds: 45)),
      ],
    ),
    Playlist(
      nom: "Deep Focus",
      morceaux: [
        Morceau(titre: "Interstellar Resonance", artiste: "Cosmic Harmonics", chemin: "", duree: const Duration(minutes: 4, seconds: 5)),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1E1E2C),
                  Color(0xFF0D0D14),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with back button
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 24, top: 24, bottom: 16),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        "Playlists",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.library_music, color: Color(0xFF6C63FF), size: 28),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Grille des playlists
                Expanded(
                  child: GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = playlists[index];
                      return _buildPlaylistCard(context, playlist, index);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistCard(BuildContext context, Playlist playlist, int index) {
    // Generate different gradient colors for playlists
    final colors = [
      [const Color(0xFF6C63FF), const Color(0xFF3B3B98)],
      [const Color(0xFFFF6584), const Color(0xFFC0392B)],
      [const Color(0xFF00E5FF), const Color(0xFF00838F)],
    ];
    final gradientColors = colors[index % colors.length];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PageDetailsPlaylist(playlist: playlist)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Icon(
                Icons.album,
                color: Colors.white,
                size: 40,
              ),
              const Spacer(),
              Text(
                playlist.nom,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "${playlist.morceaux.length} morceaux",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
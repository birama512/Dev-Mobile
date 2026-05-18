import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/morceau.dart';
import '../widgets/carte_morceau.dart';
import 'page_lecteur.dart';
import 'page_favoris.dart';
import 'page_playlists.dart';
import 'page_recherche.dart';
import 'page_profil.dart';

class PageAccueil extends StatelessWidget {
  PageAccueil({super.key});

  final List<Morceau> playlist = [
    Morceau(titre: "Interstellar Resonance", artiste: "Cosmic Harmonics", chemin: "", duree: const Duration(minutes: 4, seconds: 5)),
    Morceau(titre: "Neon Dreams", artiste: "Synthwave Collective", chemin: "", duree: const Duration(minutes: 3, seconds: 45)),
    Morceau(titre: "Midnight Drive", artiste: "Luna", chemin: "", duree: const Duration(minutes: 5, seconds: 12)),
    Morceau(titre: "Ocean Echoes", artiste: "Deep Blue", chemin: "", duree: const Duration(minutes: 2, seconds: 50)),
    Morceau(titre: "Cyberpunk City", artiste: "Nexus 9", chemin: "", duree: const Duration(minutes: 4, seconds: 30)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            FilePickerResult? result = await FilePicker.pickFiles(
              type: FileType.audio,
              allowMultiple: true,
            );
            if (result != null) {
              int count = result.files.length;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$count fichier(s) audio importé(s) avec succès !')),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur lors de l\'importation : $e')),
            );
          }
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.upload_file, color: Colors.white),
      ),
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
                // Header
                Padding(
                  padding: const EdgeInsets.only(left: 24, right: 24, top: 32, bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Bibliothèque",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.05),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.search, color: Colors.white),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => PageRecherche()));
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const PageProfil()));
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6C63FF), Color(0xFF00E5FF)],
                                ),
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Center(
                                child: Text(
                                  "JD",
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Filtres / Categories
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Row(
                    children: [
                      _buildChip(context, "Tous", isActive: true),
                      const SizedBox(width: 12),
                      _buildChip(context, "Favoris", onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => PageFavoris()));
                      }),
                      const SizedBox(width: 12),
                      _buildChip(context, "Playlists", onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => PagePlaylists()));
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Liste des musiques
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: playlist.length,
                    itemBuilder: (context, index) {
                      final morceau = playlist[index];
                      return CarteMorceau(
                        titre: morceau.titre,
                        artiste: morceau.artiste,
                        onTap: () {
                          // Animation de transition fluide vers le lecteur
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => const PageLecteur(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                const begin = Offset(0.0, 1.0);
                                const end = Offset.zero;
                                const curve = Curves.easeOutCubic;
                                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                return SlideTransition(
                                  position: animation.drive(tween),
                                  child: child,
                                );
                              },
                            ),
                          );
                        },
                      );
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

  Widget _buildChip(BuildContext context, String text, {bool isActive = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Theme.of(context).primaryColor : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Theme.of(context).primaryColor : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/morceau.dart';
import '../widgets/carte_morceau.dart';
import 'page_lecteur.dart';

class PageFavoris extends StatelessWidget {
  PageFavoris({super.key});

  final List<Morceau> favoris = [
    Morceau(titre: "Neon Dreams", artiste: "Synthwave Collective", chemin: "", duree: const Duration(minutes: 3, seconds: 45)),
    Morceau(titre: "Ocean Echoes", artiste: "Deep Blue", chemin: "", duree: const Duration(minutes: 2, seconds: 50)),
    Morceau(titre: "Cyberpunk City", artiste: "Nexus 9", chemin: "", duree: const Duration(minutes: 4, seconds: 30)),
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
                        "Favoris",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.favorite, color: Color(0xFF6C63FF), size: 28),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Liste des musiques favorites
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: favoris.length,
                    itemBuilder: (context, index) {
                      final morceau = favoris[index];
                      return CarteMorceau(
                        titre: morceau.titre,
                        artiste: morceau.artiste,
                        onTap: () {
                          Navigator.push(
                            context,
                            PageLecteur.route(
                              morceau: morceau,
                              playlist: favoris,
                              initialIndex: index,
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
}
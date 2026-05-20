import 'package:flutter/material.dart';
import '../models/morceau.dart';
import '../widgets/carte_morceau.dart';
import '../widgets/barre_recherche.dart';
import 'page_lecteur.dart';

class PageRecherche extends StatelessWidget {
  PageRecherche({super.key});

  final List<Morceau> resultats = [
    Morceau(titre: "Neon Dreams", artiste: "Synthwave Collective", chemin: "", duree: const Duration(minutes: 3, seconds: 45)),
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
                        "Recherche",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                // Barre de recherche
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: BarreRecherche(),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    "Résultats récents",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Liste des résultats
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: resultats.length,
                    itemBuilder: (context, index) {
                      final morceau = resultats[index];
                      return CarteMorceau(
                        titre: morceau.titre,
                        artiste: morceau.artiste,
                        onTap: () {
                          Navigator.push(
                            context,
                            PageLecteur.route(
                              morceau: morceau,
                              playlist: resultats,
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

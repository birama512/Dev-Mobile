import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../widgets/carte_morceau.dart';
import 'page_lecteur.dart';

class PageDetailsPlaylist extends StatelessWidget {
  final Playlist playlist;

  const PageDetailsPlaylist({super.key, required this.playlist});

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
                      Expanded(
                        child: Text(
                          playlist.nom,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Cover and Info
                Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF6C63FF), Color(0xFF3B3B98)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.music_note,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    "${playlist.morceaux.length} morceaux",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Play Button
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (playlist.morceaux.isNotEmpty) {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => const PageLecteur(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return SlideTransition(
                                position: animation.drive(Tween(begin: const Offset(0.0, 1.0), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic))),
                                child: child,
                              );
                            },
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text("Tout lire"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Liste des morceaux
                Expanded(
                  child: playlist.morceaux.isEmpty
                      ? Center(
                          child: Text(
                            "Cette playlist est vide",
                            style: TextStyle(color: Colors.white.withOpacity(0.5)),
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: playlist.morceaux.length,
                          itemBuilder: (context, index) {
                            final morceau = playlist.morceaux[index];
                            return CarteMorceau(
                              titre: morceau.titre,
                              artiste: morceau.artiste,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) => const PageLecteur(),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      return SlideTransition(
                                        position: animation.drive(Tween(begin: const Offset(0.0, 1.0), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic))),
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
}

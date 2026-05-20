import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../services/service_audio.dart';
import '../widgets/carte_morceau.dart';
import 'page_lecteur.dart';

class PageDetailsPlaylist extends StatefulWidget {
  final Playlist playlist;

  const PageDetailsPlaylist({super.key, required this.playlist});

  @override
  State<PageDetailsPlaylist> createState() => _PageDetailsPlaylistState();
}

class _PageDetailsPlaylistState extends State<PageDetailsPlaylist> {
  // ── Service ─────────────────────────────────────────────────
  final ServiceAudio _audio = ServiceAudio.instance;

  // Indique si un chargement est en cours (ex: bouton "Tout lire")
  bool _enChargement = false;

  // Lance toute la playlist depuis l'index donné
  Future<void> _jouerDepuis(int index) async {
    if (widget.playlist.morceaux.isEmpty) return;

    setState(() => _enChargement = true);

    final charge = await _audio.chargerPlaylist(
      widget.playlist.morceaux,
      index: index,
    );

    if (!charge) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Aucun fichier audio valide dans cette playlist."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      setState(() => _enChargement = false);
      return;
    }

    await _audio.play();
    setState(() => _enChargement = false);

    if (mounted) {
      Navigator.push(
        context,
        PageLecteur.route(
          morceau:      widget.playlist.morceaux[index],
          playlist:     widget.playlist.morceaux,
          initialIndex: index,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final playlist = widget.playlist;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1E1E2C), Color(0xFF0D0D14)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
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

                // Pochette
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
                    child: const Icon(Icons.music_note, size: 80, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 24),

                // Nombre de morceaux
                Center(
                  child: Text(
                    "${playlist.morceaux.length} morceau${playlist.morceaux.length > 1 ? 'x' : ''}",
                    style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.7)),
                  ),
                ),
                const SizedBox(height: 24),

                // Bouton "Tout lire" — branché sur ServiceAudio
                Center(
                  child: _enChargement
                      ? const CircularProgressIndicator(color: Color(0xFF6C63FF))
                      : ElevatedButton.icon(
                          onPressed: playlist.morceaux.isNotEmpty
                              ? () => _jouerDepuis(0)
                              : null,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text("Tout lire"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
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
                              titre:   morceau.titre,
                              artiste: morceau.artiste,
                              // Chaque morceau lance la playlist à partir de sa position
                              onTap: () => _jouerDepuis(index),
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

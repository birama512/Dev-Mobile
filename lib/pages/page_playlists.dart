import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../models/morceau.dart';
import '../services/service_audio.dart';
import '../services/service_fichier.dart';
import 'page_details_playlist.dart';

class PagePlaylists extends StatefulWidget {
  const PagePlaylists({super.key});

  @override
  State<PagePlaylists> createState() => _PagePlaylistsState();
}

class _PagePlaylistsState extends State<PagePlaylists> {
  // ── Services ────────────────────────────────────────────────
  final ServiceAudio    _audio    = ServiceAudio.instance;
  final ServiceFichiers _fichiers = ServiceFichiers();

  // ── État ────────────────────────────────────────────────────
  List<Playlist> _playlists = [];
  bool           _chargement = false;

  // ── Cycle de vie ────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _chargerPlaylists();
  }

  // Scanne la bibliothèque du téléphone et regroupe en une playlist "Bibliothèque"
  // Tu peux remplacer cette logique par ta vraie source de playlists.
  Future<void> _chargerPlaylists() async {
    setState(() => _chargement = true);

    final morceaux = await _fichiers.scannerBibliotheque();

    // Exemple : on crée une playlist par groupe de 10 morceaux
    // À adapter selon ta vraie logique de playlists
    final playlists = <Playlist>[];

    if (morceaux.isNotEmpty) {
      // Playlist "Tout"
      playlists.add(Playlist(nom: "Bibliothèque complète", morceaux: morceaux));

      // Playlist "Récents" (10 premiers)
      if (morceaux.length > 1) {
        playlists.add(Playlist(
          nom: "Récents",
          morceaux: morceaux.take(10).toList(),
        ));
      }
    }

    // Si aucun fichier trouvé, on garde des playlists de demo
    if (playlists.isEmpty) {
      playlists.addAll([
        Playlist(
          nom: "Chill Vibes",
          morceaux: [
            Morceau(titre: "Ocean Echoes",   artiste: "Deep Blue", chemin: "", duree: const Duration(minutes: 2, seconds: 50)),
            Morceau(titre: "Midnight Drive", artiste: "Luna",      chemin: "", duree: const Duration(minutes: 5, seconds: 12)),
          ],
        ),
        Playlist(
          nom: "Workout Mix",
          morceaux: [
            Morceau(titre: "Cyberpunk City", artiste: "Nexus 9",              chemin: "", duree: const Duration(minutes: 4, seconds: 30)),
            Morceau(titre: "Neon Dreams",    artiste: "Synthwave Collective",  chemin: "", duree: const Duration(minutes: 3, seconds: 45)),
          ],
        ),
        Playlist(
          nom: "Deep Focus",
          morceaux: [
            Morceau(titre: "Interstellar Resonance", artiste: "Cosmic Harmonics", chemin: "", duree: const Duration(minutes: 4, seconds: 5)),
          ],
        ),
      ]);
    }

    setState(() {
      _playlists  = playlists;
      _chargement = false;
    });
  }

  // Lance la lecture d'une playlist entière via ServiceAudio
  Future<void> _lancerPlaylist(Playlist playlist) async {
    if (playlist.morceaux.isEmpty) return;
    await _audio.chargerPlaylist(playlist.morceaux, index: 0);
    await _audio.play();
  }

  // ── UI ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
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
                      const Text(
                        "Playlists",
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const Spacer(),
                      // Bouton importer des fichiers
                      IconButton(
                        icon: const Icon(Icons.add, color: Color(0xFF6C63FF), size: 28),
                        tooltip: "Importer des fichiers",
                        onPressed: _importerFichiers,
                      ),
                      const Icon(Icons.library_music, color: Color(0xFF6C63FF), size: 28),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Contenu
                Expanded(
                  child: _chargement
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
                      : _playlists.isEmpty
                          ? _buildVide()
                          : GridView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.85,
                              ),
                              itemCount: _playlists.length,
                              itemBuilder: (context, index) =>
                                  _buildPlaylistCard(context, _playlists[index], index),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Importe des fichiers et crée une nouvelle playlist avec
  Future<void> _importerFichiers() async {
    final morceaux = await _fichiers.choisirFichiers();
    if (morceaux.isEmpty) return;

    setState(() {
      _playlists.add(Playlist(
        nom: "Import ${DateTime.now().hour}h${DateTime.now().minute}",
        morceaux: morceaux,
      ));
    });
  }

  Widget _buildVide() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.library_music_outlined, color: Colors.white24, size: 64),
          const SizedBox(height: 16),
          const Text("Aucune playlist", style: TextStyle(color: Colors.white54, fontSize: 18)),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _importerFichiers,
            icon: const Icon(Icons.add, color: Color(0xFF6C63FF)),
            label: const Text("Importer des fichiers", style: TextStyle(color: Color(0xFF6C63FF))),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistCard(BuildContext context, Playlist playlist, int index) {
    final palettes = [
      [const Color(0xFF6C63FF), const Color(0xFF3B3B98)],
      [const Color(0xFFFF6584), const Color(0xFFC0392B)],
      [const Color(0xFF00E5FF), const Color(0xFF00838F)],
    ];
    final couleurs = palettes[index % palettes.length];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PageDetailsPlaylist(playlist: playlist)),
        );
      },
      // Appui long → lance directement la playlist
      onLongPress: () => _lancerPlaylist(playlist),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: couleurs,
          ),
          boxShadow: [
            BoxShadow(
              color: couleurs[0].withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icône play dans le coin haut droit
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => _lancerPlaylist(playlist),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.album, color: Colors.white, size: 40),
              const SizedBox(height: 8),
              Text(
                playlist.nom,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                "${playlist.morceaux.length} morceau${playlist.morceaux.length > 1 ? 'x' : ''}",
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

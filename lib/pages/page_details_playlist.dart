import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../services/service_audio.dart';
import '../services/service_fichier.dart';
import '../services/database_service.dart';
import '../widgets/carte_morceau.dart';
import 'page_lecteur.dart';

class PageDetailsPlaylist extends StatefulWidget {
  final Playlist playlist;

  const PageDetailsPlaylist({super.key, required this.playlist});

  @override
  State<PageDetailsPlaylist> createState() => _PageDetailsPlaylistState();
}

class _PageDetailsPlaylistState extends State<PageDetailsPlaylist> {
  // ── Services ─────────────────────────────────────────────────
  final ServiceAudio    _audio    = ServiceAudio.instance;
  final ServiceFichiers _fichiers = ServiceFichiers();
  final DatabaseService _db       = DatabaseService.instance;

  // ── État ─────────────────────────────────────────────────────
  late Playlist _playlist;
  bool _enChargement = false;

  @override
  void initState() {
    super.initState();
    _playlist = widget.playlist;
  }

  /// Recharge la playlist depuis la DB pour avoir la liste à jour.
  Future<void> _rechargerPlaylist() async {
    final playlists = await _db.lirePlaylists();
    final maj = playlists.firstWhere(
      (p) => p.nom == _playlist.nom,
      orElse: () => _playlist,
    );
    if (mounted) setState(() => _playlist = maj);
  }

  /// Lance la playlist depuis l'index donné.
  Future<void> _jouerDepuis(int index) async {
    if (_playlist.morceaux.isEmpty) return;

    setState(() => _enChargement = true);

    final charge = await _audio.chargerPlaylist(_playlist.morceaux, index: index);

    if (!charge) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucun fichier audio valide dans cette playlist.'),
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
          morceau:      _playlist.morceaux[index],
          playlist:     _playlist.morceaux,
          initialIndex: index,
        ),
      );
    }
  }

  /// Importe des fichiers audio et les ajoute à la playlist courante en DB.
  Future<void> _ajouterMorceaux() async {
    final morceaux = await _fichiers.choisirFichiers();
    if (morceaux.isEmpty) return;

    // Sauvegarde d'abord les morceaux dans la bibliothèque
    await _db.sauvegarderMorceaux(morceaux);

    // Puis les associe à la playlist
    for (final m in morceaux) {
      await _db.ajouterMorceauAPlaylist(_playlist.nom, m);
    }

    // Recharge depuis la DB
    await _rechargerPlaylist();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${morceaux.length} morceau(x) ajouté(s) à "${_playlist.nom}".'),
        ),
      );
    }
  }

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
                      Expanded(
                        child: Text(
                          _playlist.nom,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Bouton ajouter des morceaux
                      IconButton(
                        icon: const Icon(Icons.add, color: Color(0xFF6C63FF), size: 28),
                        tooltip: 'Ajouter des morceaux',
                        onPressed: _ajouterMorceaux,
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
                          color:      const Color(0xFF6C63FF).withOpacity(0.3),
                          blurRadius: 20,
                          offset:     const Offset(0, 10),
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
                    '${_playlist.morceaux.length} morceau${_playlist.morceaux.length > 1 ? 'x' : ''}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Bouton "Tout lire"
                Center(
                  child: _enChargement
                      ? const CircularProgressIndicator(color: Color(0xFF6C63FF))
                      : ElevatedButton.icon(
                          onPressed: _playlist.morceaux.isNotEmpty
                              ? () => _jouerDepuis(0)
                              : null,
                          icon:  const Icon(Icons.play_arrow),
                          label: const Text('Tout lire'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 24),

                // Liste des morceaux
                Expanded(
                  child: _playlist.morceaux.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Cette playlist est vide',
                                style: TextStyle(color: Colors.white.withOpacity(0.5)),
                              ),
                              const SizedBox(height: 12),
                              TextButton.icon(
                                onPressed: _ajouterMorceaux,
                                icon: const Icon(Icons.add, color: Color(0xFF6C63FF)),
                                label: const Text(
                                  'Ajouter des morceaux',
                                  style: TextStyle(color: Color(0xFF6C63FF)),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: _playlist.morceaux.length,
                          itemBuilder: (context, index) {
                            final morceau = _playlist.morceaux[index];
                            return CarteMorceau(
                              titre:   morceau.titre,
                              artiste: morceau.artiste,
                              onTap:   () => _jouerDepuis(index),
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

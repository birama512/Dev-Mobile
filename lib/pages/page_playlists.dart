import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../models/morceau.dart';
import '../services/service_audio.dart';
import '../services/service_fichier.dart';
import '../services/database_service.dart';
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
  final DatabaseService _db       = DatabaseService.instance;

  // ── État ────────────────────────────────────────────────────
  List<Playlist> _playlists  = [];
  bool           _chargement = false;

  // ── Cycle de vie ────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _chargerPlaylists();
  }

  /// Charge toutes les playlists depuis la base de données SQLite.
  Future<void> _chargerPlaylists() async {
    setState(() => _chargement = true);
    final playlists = await _db.lirePlaylists();
    if (!mounted) return;
    setState(() {
      _playlists  = playlists;
      _chargement = false;
    });
  }

  /// Lance la lecture d'une playlist entière via ServiceAudio.
  Future<void> _lancerPlaylist(Playlist playlist) async {
    if (playlist.morceaux.isEmpty) return;
    await _audio.chargerPlaylist(playlist.morceaux, index: 0);
    await _audio.play();
  }

  /// Ouvre une boîte de dialogue pour saisir le nom d'une nouvelle playlist,
  /// puis la crée en base de données.
  Future<void> _creerPlaylist() async {
    final nomController = TextEditingController();

    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text(
          'Nouvelle playlist',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: nomController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Nom de la playlist',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF6C63FF)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Créer', style: TextStyle(color: Color(0xFF6C63FF))),
          ),
        ],
      ),
    );

    if (confirme != true) return;
    final nom = nomController.text.trim();
    if (nom.isEmpty) return;

    await _db.creerPlaylist(nom);
    await _chargerPlaylists();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Playlist "$nom" créée.')),
      );
    }
  }

  /// Importe des fichiers audio, crée une playlist horodatée et
  /// y ajoute tous les morceaux — le tout persisté en base.
  Future<void> _importerFichiers() async {
    final morceaux = await _fichiers.choisirFichiers();
    if (morceaux.isEmpty) return;

    // 1. Sauvegarde les morceaux dans la bibliothèque
    await _db.sauvegarderMorceaux(morceaux);

    // 2. Crée une playlist horodatée
    final nom = 'Import ${DateTime.now().hour}h${DateTime.now().minute.toString().padLeft(2, '0')}';
    await _db.creerPlaylist(nom);

    // 3. Ajoute chaque morceau à cette playlist
    for (final m in morceaux) {
      await _db.ajouterMorceauAPlaylist(nom, m);
    }

    // 4. Recharge les playlists depuis la base
    await _chargerPlaylists();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${morceaux.length} morceau(x) importé(s) dans "$nom".',
          ),
        ),
      );
    }
  }

  /// Supprime une playlist après confirmation.
  Future<void> _supprimerPlaylist(Playlist playlist) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text(
          'Supprimer la playlist ?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'La playlist "${playlist.nom}" sera supprimée définitivement.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirme != true) return;
    await _db.supprimerPlaylist(playlist.nom);
    await _chargerPlaylists();
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
                        'Playlists',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      // Bouton importer des fichiers
                      IconButton(
                        icon: const Icon(Icons.upload_file, color: Color(0xFF6C63FF), size: 26),
                        tooltip: 'Importer des fichiers',
                        onPressed: _importerFichiers,
                      ),
                      // Bouton nouvelle playlist (vide)
                      IconButton(
                        icon: const Icon(Icons.add, color: Color(0xFF6C63FF), size: 28),
                        tooltip: 'Nouvelle playlist',
                        onPressed: _creerPlaylist,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Contenu
                Expanded(
                  child: _chargement
                      ? const Center(
                          child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                        )
                      : _playlists.isEmpty
                          ? _buildVide()
                          : GridView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 8,
                              ),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount:  2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing:  16,
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

  Widget _buildVide() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.library_music_outlined,
            color: Colors.white24,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune playlist',
            style: TextStyle(color: Colors.white54, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: _creerPlaylist,
                icon: const Icon(Icons.add, color: Color(0xFF6C63FF)),
                label: const Text(
                  'Créer une playlist',
                  style: TextStyle(color: Color(0xFF6C63FF)),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _importerFichiers,
                icon: const Icon(Icons.upload_file, color: Color(0xFF6C63FF)),
                label: const Text(
                  'Importer',
                  style: TextStyle(color: Color(0xFF6C63FF)),
                ),
              ),
            ],
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
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PageDetailsPlaylist(playlist: playlist),
          ),
        );
        // Recharge au retour si des morceaux ont été ajoutés
        await _chargerPlaylists();
      },
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
              color:      couleurs[0].withOpacity(0.3),
              blurRadius: 10,
              offset:     const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Actions : play + supprimer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Bouton supprimer
                  GestureDetector(
                    onTap: () => _supprimerPlaylist(playlist),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ),
                  ),
                  // Bouton play
                  GestureDetector(
                    onTap: () => _lancerPlaylist(playlist),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(Icons.album, color: Colors.white, size: 40),
              const SizedBox(height: 8),
              Text(
                playlist.nom,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${playlist.morceaux.length} morceau${playlist.morceaux.length > 1 ? 'x' : ''}',
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

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/morceau.dart';
import '../services/service_fichier.dart';
import '../services/database_service.dart';
import '../services/service_audio.dart';
import '../widgets/barre_lecteur.dart';
import '../widgets/carte_morceau.dart';
import 'page_favoris.dart';
import 'page_lecteur.dart';
import 'page_playlists.dart';
import 'page_profil.dart';
import 'page_recherche.dart';

class PageAccueil extends StatefulWidget {
  const PageAccueil({super.key});

  @override
  State<PageAccueil> createState() => _PageAccueilState();
}

class _PageAccueilState extends State<PageAccueil> {
  final ServiceFichiers _serviceFichiers = ServiceFichiers();
  final DatabaseService _db             = DatabaseService.instance;
  final ServiceAudio _audio             = ServiceAudio.instance;

  List<Morceau> _bibliotheque = [];
  List<Morceau> _playlistActive = [];
  int _lastKnownIndex = 0;
  bool          _isLoading    = true;

  @override
  void initState() {
    super.initState();
    _chargerBibliotheque();
  }
  Future<void> _chargerBibliotheque() async {
    try {
      final enBase = await _db.lireMorceaux();
      if (mounted) {
        setState(() {
          _bibliotheque = enBase;
          _isLoading    = enBase.isEmpty;
        });
      }
      final morceauxScan = await _serviceFichiers.scannerBibliotheque();
      if (morceauxScan.isNotEmpty) {
        await _db.sauvegarderMorceaux(morceauxScan);
        final complet = await _db.lireMorceaux();
        if (mounted) setState(() => _bibliotheque = complet);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  Future<void> _importerAudio() async {
    final morceaux = await _serviceFichiers.choisirFichiers();
    if (!mounted || morceaux.isEmpty) return;
    setState(() {
      final chemins = _bibliotheque.map((m) => m.chemin).toSet();
      final nouveaux = morceaux.where((m) => !chemins.contains(m.chemin)).toList();
      _bibliotheque.insertAll(0, nouveaux);
    });
    await _db.sauvegarderMorceaux(morceaux);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${morceaux.length} fichier(s) audio ajouté(s).')),
    );
    await Navigator.push(
      context,
      PageLecteur.route(
        morceau:      morceaux.first,
        playlist:     morceaux,
        initialIndex: 0,
      ),
    );
    if (mounted) {
      setState(() {
        _playlistActive = morceaux;
        _lastKnownIndex = 0;
      });
    }
  }
  Future<void> _ouvrirLecteur(Morceau morceau, int index) async {
    setState(() {
      _playlistActive = _bibliotheque;
      _lastKnownIndex = index;
    });
    await Navigator.push(
      context,
      PageLecteur.route(
        morceau:      morceau,
        playlist:     _bibliotheque,
        initialIndex: index,
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final hasAudio = _bibliotheque.isNotEmpty;
    return Scaffold(
      bottomNavigationBar: StreamBuilder<int?>(
        stream: _audio.currentIndexStream,
        builder: (context, indexSnapshot) {
          final playlist = _playlistActive;
          if (playlist.isEmpty) return const SizedBox.shrink();
          final streamIndex = indexSnapshot.data;
          final safeIndex = (streamIndex ?? _lastKnownIndex)
              .clamp(0, playlist.length - 1);
          final morceauCourant = playlist[safeIndex];
          return StreamBuilder<PlayerState>(
            stream: _audio.playerStateStream,
            builder: (context, playerSnapshot) {
              final isPlaying = playerSnapshot.data?.playing ?? false;
              return SafeArea(
                top: false,
                child: BarreLecteur(
                  morceau: morceauCourant,
                  playlist: playlist,
                  initialIndex: safeIndex,
                  reprendreLectureEnCours: true,
                  isPlaying: isPlaying,
                  onPlayPause: _audio.togglePlayPause,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _importerAudio,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        icon:  const Icon(Icons.upload_file),
        label: const Text('Importer'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
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
                Padding(
                  padding: const EdgeInsets.only(
                    left: 24, right: 24, top: 32, bottom: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Bibliothèque',
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
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PageRecherche(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PageProfil(),
                              ),
                            ),
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
                                  'JD',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      _buildChip(context, 'Tous', isActive: true),
                      const SizedBox(width: 12),
                      _buildChip(
                        context, 'Favoris',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PageFavoris()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildChip(
                        context, 'Playlists',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PagePlaylists()),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _isLoading
                        ? 'Recherche de morceaux sur l\'appareil...'
                        : hasAudio
                            ? '${_bibliotheque.length} morceau(s) prêt(s) à lire'
                            : 'Importe des fichiers audio pour lancer la lecture.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.68),
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : hasAudio
                          ? ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 100),
                              itemCount: _bibliotheque.length,
                              itemBuilder: (context, index) {
                                final morceau = _bibliotheque[index];
                                return CarteMorceau(
                                  titre:   morceau.titre,
                                  artiste: morceau.artiste,
                                  onTap:   () => _ouvrirLecteur(morceau, index),
                                );
                              },
                            )
                          : Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 150,
                                      height: 150,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            Theme.of(context).primaryColor.withOpacity(0.35),
                                            Theme.of(context).colorScheme.secondary.withOpacity(0.22),
                                          ],
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.library_music,
                                        color: Colors.white,
                                        size: 66,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    const Text(
                                      'Aucun morceau trouvé',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Appuie sur Importer pour choisir des fichiers audio.',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton.icon(
                                      onPressed: _importerAudio,
                                      icon:  const Icon(Icons.upload_file),
                                      label: const Text('Importer maintenant'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context).primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(28),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(
    BuildContext context,
    String text, {
    bool isActive = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).primaryColor
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? Theme.of(context).primaryColor
                : Colors.white.withOpacity(0.1),
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

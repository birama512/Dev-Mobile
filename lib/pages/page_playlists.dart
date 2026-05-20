import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../models/morceau.dart';
import '../services/service_audio.dart';
import '../services/database_service.dart';
import 'page_details_playlist.dart';

class PagePlaylists extends StatefulWidget {
  const PagePlaylists({super.key});

  @override
  State<PagePlaylists> createState() => _PagePlaylistsState();
}

class _PagePlaylistsState extends State<PagePlaylists> {
  final ServiceAudio    _audio    = ServiceAudio.instance;
  final DatabaseService _db       = DatabaseService.instance;
  List<Playlist> _playlists  = [];
  bool           _chargement = false;

  @override
  void initState() {
    super.initState();
    _chargerPlaylists();
  }

  Future<void> _chargerPlaylists() async {
    setState(() => _chargement = true);
    final playlists = await _db.lirePlaylists();
    if (!mounted) return;
    setState(() {
      _playlists  = playlists;
      _chargement = false;
    });
  }

  Future<void> _lancerPlaylist(Playlist playlist) async {
    if (playlist.morceaux.isEmpty) return;
    await _audio.chargerPlaylist(playlist.morceaux, index: 0);
    await _audio.play();
  }

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

  Future<void> _creerPlaylistDepuisBibliotheque() async {
    final bibliotheque = await _db.lireMorceaux();
    if (bibliotheque.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun morceau importé. Ajoute d\'abord des audios dans la bibliothèque.')),
      );
      return;
    }

    final nomController = TextEditingController();
    final selection = <String>{};

    final result = await showDialog<(String, List<Morceau>)>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E2C),
            title: const Text('Nouvelle playlist', style: TextStyle(color: Colors.white)),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nomController,
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
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 280,
                    child: ListView.builder(
                      itemCount: bibliotheque.length,
                      itemBuilder: (_, index) {
                        final morceau = bibliotheque[index];
                        final selected = selection.contains(morceau.chemin);
                        return CheckboxListTile(
                          activeColor: const Color(0xFF6C63FF),
                          value: selected,
                          onChanged: (value) {
                            setModalState(() {
                              if (value == true) {
                                selection.add(morceau.chemin);
                              } else {
                                selection.remove(morceau.chemin);
                              }
                            });
                          },
                          title: Text(
                            morceau.titre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            morceau.artiste,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler', style: TextStyle(color: Colors.white54)),
              ),
              TextButton(
                onPressed: () {
                  final nom = nomController.text.trim();
                  if (nom.isEmpty || selection.isEmpty) return;
                  final morceaux = bibliotheque
                      .where((m) => selection.contains(m.chemin))
                      .toList();
                  Navigator.pop(ctx, (nom, morceaux));
                },
                child: const Text('Créer', style: TextStyle(color: Color(0xFF6C63FF))),
              ),
            ],
          );
        },
      ),
    );

    if (result == null) return;
    final nom = result.$1;
    final morceaux = result.$2;
    if (nom.isEmpty || morceaux.isEmpty) return;

    await _db.creerPlaylist(nom);
    for (final m in morceaux) {
      await _db.ajouterMorceauAPlaylist(nom, m);
    }

    await _chargerPlaylists();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Playlist "$nom" créée avec ${morceaux.length} morceau(x).')),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      IconButton(
                        icon: const Icon(Icons.library_add, color: Color(0xFF6C63FF), size: 26),
                        tooltip: 'Créer depuis la bibliothèque',
                        onPressed: _creerPlaylistDepuisBibliotheque,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Color(0xFF6C63FF), size: 28),
                        tooltip: 'Nouvelle playlist',
                        onPressed: _creerPlaylist,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

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
                onPressed: _creerPlaylistDepuisBibliotheque,
                icon: const Icon(Icons.library_add, color: Color(0xFF6C63FF)),
                label: const Text(
                  'Depuis bibliothèque',
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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

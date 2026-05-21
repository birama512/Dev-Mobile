import 'package:flutter/material.dart';
import '../models/morceau.dart';
import '../models/playlist.dart';
import '../services/service_audio.dart';
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
  final ServiceAudio    _audio    = ServiceAudio.instance;
  final DatabaseService _db       = DatabaseService.instance;
  late Playlist _playlist;
  bool _enChargement = false;
  @override
  void initState() {
    super.initState();
    _playlist = widget.playlist;
  }
  Future<void> _rechargerPlaylist() async {
    final playlists = await _db.lirePlaylists();
    final maj = playlists.firstWhere(
      (p) => p.nom == _playlist.nom,
      orElse: () => _playlist,
    );
    if (mounted) setState(() => _playlist = maj);
  }
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

    if (!mounted) return;

    final cheminSupprime = await Navigator.push<String?>(
      context,
      PageLecteur.route(
        morceau:      _playlist.morceaux[index],
        playlist:     _playlist.morceaux,
        initialIndex: index,
      ),
    );

    if (!mounted) return;

    if (cheminSupprime != null) {
      setState(() {
        _playlist.morceaux.removeWhere((m) => m.chemin == cheminSupprime);
      });
    }
  }
  Future<void> _ajouterMorceaux() async {
    final bibliotheque = await _db.lireMorceaux();
    final dejaDansPlaylist = _playlist.morceaux.map((m) => m.chemin).toSet();
    final disponibles = bibliotheque
        .where((m) => !dejaDansPlaylist.contains(m.chemin))
        .toList();

    if (disponibles.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun nouveau morceau à ajouter depuis la bibliothèque.')),
      );
      return;
    }

    final selection = <String>{};
    final morceaux = await showDialog<List<Morceau>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E2C),
            title: const Text(
              'Ajouter à la playlist',
              style: TextStyle(color: Colors.white),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 360,
              child: ListView.builder(
                itemCount: disponibles.length,
                itemBuilder: (_, index) {
                  final morceau = disponibles[index];
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
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler', style: TextStyle(color: Colors.white54)),
              ),
              TextButton(
                onPressed: selection.isEmpty
                    ? null
                    : () {
                        final result = disponibles
                            .where((m) => selection.contains(m.chemin))
                            .toList();
                        Navigator.pop(ctx, result);
                      },
                child: const Text('Ajouter', style: TextStyle(color: Color(0xFF6C63FF))),
              ),
            ],
          );
        },
      ),
    );

    if (morceaux == null || morceaux.isEmpty) return;
    for (final m in morceaux) {
      await _db.ajouterMorceauAPlaylist(_playlist.nom, m);
    }
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
                      IconButton(
                        icon: const Icon(Icons.add, color: Color(0xFF6C63FF), size: 28),
                        tooltip: 'Ajouter des morceaux',
                        onPressed: _ajouterMorceaux,
                      ),
                    ],
                  ),
                ),
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
                Center(
                  child: Text(
                    '${_playlist.morceaux.length} morceau${_playlist.morceaux.length > 1 ? 'x' : ''}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
                const SizedBox(height: 24),                Center(
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

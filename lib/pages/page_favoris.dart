import 'package:flutter/material.dart';
import '../models/morceau.dart';
import '../services/service_audio.dart';
import '../services/database_service.dart';
import '../widgets/carte_morceau.dart';
import 'page_lecteur.dart';

class PageFavoris extends StatefulWidget {
  const PageFavoris({super.key});

  @override
  State<PageFavoris> createState() => _PageFavorisState();
}

class _PageFavorisState extends State<PageFavoris> {
  final ServiceAudio    _audio    = ServiceAudio.instance;
  final DatabaseService _db       = DatabaseService.instance;
  List<Morceau> _favoris    = [];
  bool          _chargement = false;
  @override
  void initState() {
    super.initState();
    _chargerFavoris();
  }
  Future<void> _chargerFavoris() async {
    setState(() => _chargement = true);
    final favoris = await _db.lireFavoris();
    if (!mounted) return;
    setState(() {
      _favoris    = favoris;
      _chargement = false;
    });
  }
  Future<void> _jouerMorceau(Morceau morceau, int index) async {
    final charge = await _audio.chargerPlaylist(_favoris, index: index);
    if (!charge) {
      await _audio.chargerEtLire(morceau);
      return;
    }
    await _audio.play();
  }
  Future<void> _retirerFavori(int index) async {
    final morceau = _favoris[index];
    setState(() => _favoris.removeAt(index));
    await _db.retirerFavori(morceau.chemin);
  }
  Future<void> _ajouterDepuisBibliotheque() async {
    final bibliotheque = await _db.lireMorceaux();
    final cheminsFavoris = _favoris.map((m) => m.chemin).toSet();
    final disponibles = bibliotheque
        .where((m) => !cheminsFavoris.contains(m.chemin))
        .toList();
    if (disponibles.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun nouveau morceau à ajouter depuis la bibliothèque.')),
      );
      return;
    }
    final selection = <String>{};
    final choisis = await showDialog<List<Morceau>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E2C),
            title: const Text(
              'Ajouter aux favoris',
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

    if (choisis == null || choisis.isEmpty) return;

    for (final m in choisis) {
      await _db.ajouterFavori(m);
    }

    await _chargerFavoris();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${choisis.length} morceau(x) ajouté(s) aux favoris.')),
    );
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
                        'Favoris',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add, color: Color(0xFF6C63FF), size: 28),
                        tooltip: 'Ajouter aux favoris',
                        onPressed: _ajouterDepuisBibliotheque,
                      ),
                      const Icon(Icons.favorite, color: Color(0xFF6C63FF), size: 28),
                    ],
                  ),
                ),
                if (_favoris.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GestureDetector(
                      onTap: () => _jouerMorceau(_favoris.first, 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF3B3B98)],
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Tout lire',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),
                Expanded(
                  child: _chargement
                      ? const Center(
                          child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                        )
                      : _favoris.isEmpty
                          ? _buildVide()
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 24),
                              itemCount: _favoris.length,
                              itemBuilder: (context, index) {
                                final morceau = _favoris[index];
                                return Dismissible(
                                  key: Key(morceau.chemin + index.toString()),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 24),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.favorite_border,
                                      color: Colors.red,
                                    ),
                                  ),
                                  onDismissed: (_) => _retirerFavori(index),
                                  child: CarteMorceau(
                                    titre:   morceau.titre,
                                    artiste: morceau.artiste,
                                    onTap: () async {
                                      _jouerMorceau(morceau, index);
                                      final cheminSupprime = await Navigator.push<String?>(
                                        context,
                                        PageLecteur.route(
                                          morceau:      morceau,
                                          playlist:     _favoris,
                                          initialIndex: index,
                                        ),
                                      );
                                      if (!mounted) return;
                                      if (cheminSupprime != null) {
                                        setState(() {
                                          _favoris.removeWhere((m) => m.chemin == cheminSupprime);
                                        });
                                      }
                                    },
                                  ),
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

  Widget _buildVide() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite_border, color: Colors.white24, size: 64),
          const SizedBox(height: 16),
          const Text(
            'Aucun favori',
            style: TextStyle(color: Colors.white54, fontSize: 18),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _ajouterDepuisBibliotheque,
            icon: const Icon(Icons.add, color: Color(0xFF6C63FF)),
            label: const Text(
              'Ajouter des morceaux',
              style: TextStyle(color: Color(0xFF6C63FF)),
            ),
          ),
        ],
      ),
    );
  }
}

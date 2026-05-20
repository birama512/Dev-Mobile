import 'package:flutter/material.dart';
import '../models/morceau.dart';
import '../services/service_audio.dart';
import '../services/service_fichier.dart';
import '../services/database_service.dart';
import '../widgets/carte_morceau.dart';
import 'page_lecteur.dart';

class PageFavoris extends StatefulWidget {
  const PageFavoris({super.key});

  @override
  State<PageFavoris> createState() => _PageFavorisState();
}

class _PageFavorisState extends State<PageFavoris> {
  // ── Services ────────────────────────────────────────────────
  final ServiceAudio    _audio    = ServiceAudio.instance;
  final ServiceFichiers _fichiers = ServiceFichiers();
  final DatabaseService _db       = DatabaseService.instance;

  // ── État ────────────────────────────────────────────────────
  List<Morceau> _favoris    = [];
  bool          _chargement = false;

  // ── Cycle de vie ────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _chargerFavoris();
  }

  /// Charge les favoris depuis la base de données SQLite.
  Future<void> _chargerFavoris() async {
    setState(() => _chargement = true);
    final favoris = await _db.lireFavoris();
    if (!mounted) return;
    setState(() {
      _favoris    = favoris;
      _chargement = false;
    });
  }

  /// Lance la lecture d'un morceau dans la liste des favoris.
  Future<void> _jouerMorceau(Morceau morceau, int index) async {
    final charge = await _audio.chargerPlaylist(_favoris, index: index);
    if (!charge) {
      await _audio.chargerEtLire(morceau);
      return;
    }
    await _audio.play();
  }

  /// Retire un morceau des favoris (glisser pour supprimer) — persisté en DB.
  Future<void> _retirerFavori(int index) async {
    final morceau = _favoris[index];
    setState(() => _favoris.removeAt(index));
    await _db.retirerFavori(morceau.chemin);
  }

  /// Importe des fichiers et les ajoute directement aux favoris en DB.
  Future<void> _importerFichiers() async {
    final morceaux = await _fichiers.choisirFichiers();
    if (morceaux.isEmpty) return;

    // Sauvegarde chaque morceau comme favori en base
    for (final m in morceaux) {
      await _db.ajouterFavori(m);
    }

    // Recharge la liste depuis la DB pour rester cohérent
    await _chargerFavoris();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${morceaux.length} morceau(x) ajouté(s) aux favoris.')),
      );
    }
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
                        onPressed: _importerFichiers,
                      ),
                      const Icon(Icons.favorite, color: Color(0xFF6C63FF), size: 28),
                    ],
                  ),
                ),

                // Bouton "Tout lire"
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

                // Contenu
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

                                // Glisser vers la gauche pour retirer des favoris
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
                                    onTap: () {
                                      _jouerMorceau(morceau, index);
                                      Navigator.push(
                                        context,
                                        PageLecteur.route(
                                          morceau:      morceau,
                                          playlist:     _favoris,
                                          initialIndex: index,
                                        ),
                                      );
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
            onPressed: _importerFichiers,
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

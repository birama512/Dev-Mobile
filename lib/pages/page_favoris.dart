import 'package:flutter/material.dart';
import '../models/morceau.dart';
import '../widgets/carte_morceau.dart';
import '../widgets/barre_recherche.dart';
import 'page_lecteur.dart';

class PageFavoris extends StatefulWidget {
  final List<Morceau> tousLesMorceaux;

  const PageFavoris({super.key, required this.tousLesMorceaux});

  @override
  State<PageFavoris> createState() => _PageFavorisState();
}

class _PageFavorisState extends State<PageFavoris> {
  String _recherche = '';

  List<Morceau> get _favoris =>
      widget.tousLesMorceaux.where((m) => m.estFavori).toList();

  List<Morceau> get _favorisFiltres {
    if (_recherche.isEmpty) return _favoris;
    final q = _recherche.toLowerCase();
    return _favoris
        .where((m) =>
            m.titre.toLowerCase().contains(q) ||
            m.artiste.toLowerCase().contains(q))
        .toList();
  }

  void _retirerFavori(Morceau morceau) {
    setState(() => morceau.estFavori = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('« ${morceau.titre} » retiré des favoris'),
        backgroundColor: const Color(0xFF1E1E30),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Annuler',
          textColor: const Color(0xFF7C3AED),
          onPressed: () => setState(() => morceau.estFavori = true),
        ),
      ),
    );
  }

  void _lireTout() {
    if (_favorisFiltres.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PageLecteur(
          morceau: _favorisFiltres.first,
          playlist: _favorisFiltres,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favoris = _favorisFiltres;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── En-tête ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Favoris',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_favoris.length} morceau${_favoris.length != 1 ? 'x' : ''}',
                        style: TextStyle(
                          color: Colors.white.withAlpha(102),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  // Bouton Lire tout
                  if (_favoris.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: _lireTout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                      label: const Text('Lire tout', style: TextStyle(fontSize: 13)),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ─── Barre de recherche ───────────────────────────────────────
            if (_favoris.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: BarreRecherche(
                  onChanged: (val) => setState(() => _recherche = val),
                  placeholder: 'Rechercher dans les favoris...',
                ),
              ),

            const SizedBox(height: 16),

            // ─── Contenu ──────────────────────────────────────────────────
            Expanded(
              child: favoris.isEmpty ? _buildVide() : _buildListe(favoris),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVide() {
    final pasDeRecherche = _favoris.isEmpty;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
            ).createShader(bounds),
            child: Icon(
              pasDeRecherche ? Icons.favorite_border_rounded : Icons.search_off_rounded,
              size: 72,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            pasDeRecherche ? 'Aucun favori pour l\'instant' : 'Aucun résultat',
            style: TextStyle(color: Colors.white.withAlpha(128), fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            pasDeRecherche
                ? 'Appuie sur ♡ pour ajouter un morceau'
                : 'Essaie un autre terme',
            style: TextStyle(color: Colors.white.withAlpha(64), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildListe(List<Morceau> liste) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: liste.length,
      itemBuilder: (ctx, i) {
        final morceau = liste[i];
        return Dismissible(
          key: Key('favori_${morceau.chemin}'),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => _retirerFavori(morceau),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.transparent, Color(0x33EC4899)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.heart_broken_rounded, color: Color(0xFFEC4899)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: CarteMorceau(
              morceau: morceau,
              onTap: () => Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (_) => PageLecteur(morceau: morceau, playlist: liste),
                ),
              ),
              onFavoriToggle: () => _retirerFavori(morceau),
            ),
          ),
        );
      },
    );
  }
}
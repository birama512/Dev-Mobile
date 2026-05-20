import 'package:flutter/material.dart';
import '../models/morceau.dart';
import '../services/service_audio.dart';
import '../services/database_service.dart';
import '../widgets/carte_morceau.dart';
import '../widgets/barre_recherche.dart';
import 'page_lecteur.dart';

class PageRecherche extends StatefulWidget {
  const PageRecherche({super.key});

  @override
  State<PageRecherche> createState() => _PageRechercheState();
}

class _PageRechercheState extends State<PageRecherche> {
  // ── Services ────────────────────────────────────────────────
  final ServiceAudio    _audio = ServiceAudio.instance;
  final DatabaseService _db    = DatabaseService.instance;

  // ── État ────────────────────────────────────────────────────
  List<Morceau> _tousMorceaux = [];
  List<Morceau> _resultats    = [];
  String        _requete      = '';
  bool          _chargement   = true;

  // ── Cycle de vie ────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _chargerBibliotheque();
  }

  /// Charge tous les morceaux depuis la base de données.
  Future<void> _chargerBibliotheque() async {
    final morceaux = await _db.lireMorceaux();
    if (!mounted) return;
    setState(() {
      _tousMorceaux = morceaux;
      _resultats    = morceaux; // au départ : tout est affiché
      _chargement   = false;
    });
  }

  /// Filtre en temps réel via la DB (recherche côté SQL).
  Future<void> _rechercher(String requete) async {
    final q = requete.trim();
    setState(() => _requete = q.toLowerCase());

    if (q.isEmpty) {
      setState(() => _resultats = _tousMorceaux);
      return;
    }

    // Délègue la recherche à la DB pour filtrer sur titre ET artiste
    final resultats = await _db.rechercherMorceaux(q);
    if (!mounted) return;
    setState(() => _resultats = resultats);
  }

  /// Lance la lecture d'un morceau dans le contexte des résultats.
  Future<void> _jouerMorceau(Morceau morceau, int index) async {
    final charge = await _audio.chargerPlaylist(_resultats, index: index);
    if (!charge) await _audio.chargerEtLire(morceau);
    else await _audio.play();
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
                  padding: const EdgeInsets.only(
                    left: 16, right: 24, top: 24, bottom: 16,
                  ),
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
                        'Recherche',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Barre de recherche
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 8.0,
                  ),
                  child: BarreRecherche(onChanged: _rechercher),
                ),
                const SizedBox(height: 16),

                // Label dynamique
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    _chargement
                        ? 'Chargement...'
                        : _requete.isEmpty
                            ? '${_tousMorceaux.length} morceau(x) en bibliothèque'
                            : '${_resultats.length} résultat${_resultats.length > 1 ? 's' : ''} pour "$_requete"',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Contenu
                Expanded(
                  child: _chargement
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF6C63FF),
                          ),
                        )
                      : _resultats.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.search_off,
                                    color: Colors.white24,
                                    size: 64,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _tousMorceaux.isEmpty
                                        ? 'La bibliothèque est vide.\nImporte des morceaux depuis l\'accueil.'
                                        : 'Aucun résultat pour "$_requete"',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 24),
                              itemCount: _resultats.length,
                              itemBuilder: (context, index) {
                                final morceau = _resultats[index];
                                return CarteMorceau(
                                  titre:   morceau.titre,
                                  artiste: morceau.artiste,
                                  onTap: () {
                                    _jouerMorceau(morceau, index);
                                    Navigator.push(
                                      context,
                                      PageLecteur.route(
                                        morceau:      morceau,
                                        playlist:     _resultats,
                                        initialIndex: index,
                                      ),
                                    );
                                  },
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

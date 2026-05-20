import 'package:flutter/material.dart';
import '../models/morceau.dart';
import '../services/service_audio.dart';
import '../services/service_fichier.dart';
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
  final ServiceAudio    _audio    = ServiceAudio.instance;
  final ServiceFichiers _fichiers = ServiceFichiers();

  // ── État ────────────────────────────────────────────────────
  List<Morceau> _tousMorceaux = []; // bibliothèque complète
  List<Morceau> _resultats    = []; // résultats filtrés
  String        _requete      = '';
  bool          _chargement   = true;

  // ── Cycle de vie ────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _chargerBibliotheque();
  }

  Future<void> _chargerBibliotheque() async {
    final morceaux = await _fichiers.scannerBibliotheque();
    setState(() {
      _tousMorceaux = morceaux;
      _resultats    = morceaux; // au départ : tout est affiché
      _chargement   = false;
    });
  }

  // Filtre les morceaux selon la requête (titre ou artiste)
  void _rechercher(String requete) {
    setState(() {
      _requete = requete.trim().toLowerCase();
      if (_requete.isEmpty) {
        _resultats = _tousMorceaux;
      } else {
        _resultats = _tousMorceaux.where((m) {
          return m.titre.toLowerCase().contains(_requete) ||
                 m.artiste.toLowerCase().contains(_requete);
        }).toList();
      }
    });
  }

  // Lance la lecture d'un morceau dans le contexte des résultats
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
                        "Recherche",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Barre de recherche — branchée sur _rechercher()
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: BarreRecherche(
                    onChanged: _rechercher,
                  ),
                ),
                const SizedBox(height: 16),

                // Label dynamique
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    _requete.isEmpty
                        ? "Toute la bibliothèque"
                        : "${_resultats.length} résultat${_resultats.length > 1 ? 's' : ''} pour \"$_requete\"",
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
                          child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                        )
                      : _resultats.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.search_off, color: Colors.white24, size: 64),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Aucun résultat pour \"$_requete\"",
                                    style: const TextStyle(color: Colors.white54, fontSize: 16),
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

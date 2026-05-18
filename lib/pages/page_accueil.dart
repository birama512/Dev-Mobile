import 'package:flutter/material.dart';
import '../models/morceau.dart';
import '../models/playlist.dart';
import '../widgets/carte_morceau.dart';
import '../widgets/barre_recherche.dart';
import 'page_lecteur.dart';
import 'page_playlists.dart';
import 'page_favoris.dart';

class PageAccueil extends StatefulWidget {
  const PageAccueil({super.key});

  @override
  State<PageAccueil> createState() => _PageAccueilState();
}

class _PageAccueilState extends State<PageAccueil> {
  int _indexOnglet = 0;
  String _recherche = '';

  // Données fictives pour la démo — à remplacer par le service réel
  final List<Morceau> _morceauxRecents = [
    Morceau(titre: 'Sunflower', artiste: 'Post Malone', chemin: '/music/sunflower.mp3', duree: 158),
    Morceau(titre: 'Blinding Lights', artiste: 'The Weeknd', chemin: '/music/blinding.mp3', duree: 200),
    Morceau(titre: 'Mood', artiste: '24kGoldn', chemin: '/music/mood.mp3', duree: 140),
    Morceau(titre: 'Levitating', artiste: 'Dua Lipa', chemin: '/music/levitating.mp3', duree: 203),
    Morceau(titre: 'Peaches', artiste: 'Justin Bieber', chemin: '/music/peaches.mp3', duree: 198),
  ];

  final List<Playlist> _playlists = [
    Playlist(nom: 'Mes coups de cœur', morceaux: []),
    Playlist(nom: 'Workout', morceaux: []),
    Playlist(nom: 'Soirée', morceaux: []),
  ];

  List<Morceau> get _morceauxFiltres {
    if (_recherche.isEmpty) return _morceauxRecents;
    final q = _recherche.toLowerCase();
    return _morceauxRecents
        .where((m) =>
            m.titre.toLowerCase().contains(q) ||
            m.artiste.toLowerCase().contains(q))
        .toList();
  }

  void _onMorceauTap(Morceau morceau) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PageLecteur(morceau: morceau, playlist: _morceauxRecents),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: IndexedStack(
        index: _indexOnglet,
        children: [
          _buildAccueil(),
          PagePlaylists(playlists: _playlists, tousLesMorceaux: _morceauxRecents),
          PageFavoris(tousLesMorceaux: _morceauxRecents),
        ],
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildAccueil() {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // En-tête
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bonsoir 👋',
                            style: TextStyle(
                              color: Colors.white.withAlpha(153),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Qu\'on écoute ?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFF7C3AED),
                        child: const Text('M', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  BarreRecherche(
                    onChanged: (val) => setState(() => _recherche = val),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),

          // Section playlists rapides
          if (_recherche.isEmpty) ...[
            _sliverTitre('Mes playlists'),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _playlists.length + 1,
                  itemBuilder: (ctx, i) {
                    if (i == _playlists.length) return _carteNouvellePlaylist();
                    return _cartePlaylistRapide(_playlists[i]);
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
            _sliverTitre('Écoutés récemment'),
          ] else ...[
            _sliverTitre('Résultats (${_morceauxFiltres.length})'),
          ],

          // Liste des morceaux
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final morceau = _morceauxFiltres[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: CarteMorceau(
                    morceau: morceau,
                    onTap: () => _onMorceauTap(morceau),
                    onFavoriToggle: () => setState(() => morceau.estFavori = !morceau.estFavori),
                  ),
                );
              },
              childCount: _morceauxFiltres.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 90)),
        ],
      ),
    );
  }

  SliverToBoxAdapter _sliverTitre(String titre) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Text(
          titre,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _cartePlaylistRapide(Playlist playlist) {
    final couleurs = [
      [const Color(0xFF7C3AED), const Color(0xFF4F46E5)],
      [const Color(0xFFEC4899), const Color(0xFFF97316)],
      [const Color(0xFF06B6D4), const Color(0xFF6366F1)],
    ];
    final idx = _playlists.indexOf(playlist) % couleurs.length;

    return GestureDetector(
      onTap: () => setState(() => _indexOnglet = 1),
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: couleurs[idx],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.queue_music_rounded, color: Colors.white, size: 28),
            Text(
              playlist.nom,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _carteNouvellePlaylist() {
    return GestureDetector(
      onTap: () => setState(() => _indexOnglet = 1),
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withAlpha(38)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: Colors.white54, size: 30),
            SizedBox(height: 6),
            Text('Nouvelle\nplaylist', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  BottomNavigationBar _buildNavBar() {
    return BottomNavigationBar(
      currentIndex: _indexOnglet,
      onTap: (i) => setState(() => _indexOnglet = i),
      backgroundColor: const Color(0xFF1A1A2E),
      selectedItemColor: const Color(0xFF7C3AED),
      unselectedItemColor: Colors.white38,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Accueil'),
        BottomNavigationBarItem(icon: Icon(Icons.queue_music_rounded), label: 'Playlists'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite_rounded), label: 'Favoris'),
      ],
    );
  }
}
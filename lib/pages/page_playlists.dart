import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../models/morceau.dart';
import '../widgets/carte_morceau.dart';
import 'page_lecteur.dart';

class PagePlaylists extends StatefulWidget {
  final List<Playlist> playlists;
  final List<Morceau> tousLesMorceaux;

  const PagePlaylists({
    super.key,
    required this.playlists,
    required this.tousLesMorceaux,
  });

  @override
  State<PagePlaylists> createState() => _PagePlaylistsState();
}

class _PagePlaylistsState extends State<PagePlaylists> {
  // ─── Création d'une playlist ──────────────────────────────────────────────

  void _afficherDialogCreation() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E30),
        title: const Text('Nouvelle playlist', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Nom de la playlist',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF7C3AED)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
            onPressed: () {
              final nom = controller.text.trim();
              if (nom.isNotEmpty) {
                setState(() => widget.playlists.add(Playlist(nom: nom, morceaux: [])));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  // ─── Renommer une playlist ────────────────────────────────────────────────

  void _renommerPlaylist(Playlist playlist) {
    final controller = TextEditingController(text: playlist.nom);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E30),
        title: const Text('Renommer', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF7C3AED)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
            onPressed: () {
              final nom = controller.text.trim();
              if (nom.isNotEmpty) {
                setState(() => playlist.nom = nom);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  // ─── Supprimer une playlist ───────────────────────────────────────────────

  void _supprimerPlaylist(Playlist playlist) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E30),
        title: const Text('Supprimer la playlist ?', style: TextStyle(color: Colors.white)),
        content: Text(
          '« ${playlist.nom} » sera définitivement supprimée.',
          style: const TextStyle(color: Colors.white60),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              setState(() => widget.playlists.remove(playlist));
              Navigator.pop(ctx);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  // ─── Détail d'une playlist ────────────────────────────────────────────────

  void _ouvrirPlaylist(Playlist playlist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _DetailPlaylist(
          playlist: playlist,
          tousLesMorceaux: widget.tousLesMorceaux,
        ),
      ),
    );
  }

  // ─── UI principale ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Playlists',
                    style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${widget.playlists.length} liste${widget.playlists.length > 1 ? 's' : ''}',
                    style: TextStyle(color: Colors.white.withAlpha(102), fontSize: 14),
                  ),
                ],
              ),
            ),

            // Liste
            Expanded(
              child: widget.playlists.isEmpty
                  ? _buildVide()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: widget.playlists.length,
                      itemBuilder: (ctx, i) => _cartePlaylist(widget.playlists[i], i),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _afficherDialogCreation,
        backgroundColor: const Color(0xFF7C3AED),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouvelle playlist'),
      ),
    );
  }

  Widget _buildVide() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.queue_music_rounded, size: 72, color: Colors.white.withAlpha(26)),
          const SizedBox(height: 16),
          Text('Aucune playlist', style: TextStyle(color: Colors.white.withAlpha(102), fontSize: 16)),
          const SizedBox(height: 8),
          Text('Crée ta première liste de lecture', style: TextStyle(color: Colors.white.withAlpha(64), fontSize: 13)),
        ],
      ),
    );
  }

  // Couleurs alternées pour les avatars
  static const _couleurs = [
    Color(0xFF7C3AED), Color(0xFFEC4899), Color(0xFF06B6D4),
    Color(0xFFF97316), Color(0xFF10B981), Color(0xFFF59E0B),
  ];

  Widget _cartePlaylist(Playlist playlist, int index) {
    final couleur = _couleurs[index % _couleurs.length];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: couleur.withAlpha(51),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.queue_music_rounded, color: couleur, size: 26),
        ),
        title: Text(playlist.nom, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${playlist.morceaux.length} morceau${playlist.morceaux.length != 1 ? 'x' : ''}',
          style: TextStyle(color: Colors.white.withAlpha(102), fontSize: 12),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white38),
          color: const Color(0xFF1E1E30),
          onSelected: (action) {
            if (action == 'renommer') _renommerPlaylist(playlist);
            if (action == 'supprimer') _supprimerPlaylist(playlist);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'renommer',
              child: Row(children: [
                Icon(Icons.edit_rounded, color: Colors.white60, size: 18),
                SizedBox(width: 10),
                Text('Renommer', style: TextStyle(color: Colors.white)),
              ]),
            ),
            const PopupMenuItem(
              value: 'supprimer',
              child: Row(children: [
                Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                SizedBox(width: 10),
                Text('Supprimer', style: TextStyle(color: Colors.redAccent)),
              ]),
            ),
          ],
        ),
        onTap: () => _ouvrirPlaylist(playlist),
      ),
    );
  }
}

// ─── Page détail d'une playlist ──────────────────────────────────────────────

class _DetailPlaylist extends StatefulWidget {
  final Playlist playlist;
  final List<Morceau> tousLesMorceaux;

  const _DetailPlaylist({required this.playlist, required this.tousLesMorceaux});

  @override
  State<_DetailPlaylist> createState() => _DetailPlaylistState();
}

class _DetailPlaylistState extends State<_DetailPlaylist> {
  void _ajouterMorceaux() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E30),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Ajouter des morceaux', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: widget.tousLesMorceaux.length,
                itemBuilder: (_, i) {
                  final m = widget.tousLesMorceaux[i];
                  final dejaPresent = widget.playlist.morceaux.contains(m);
                  return ListTile(
                    leading: Icon(
                      dejaPresent ? Icons.check_circle_rounded : Icons.music_note_rounded,
                      color: dejaPresent ? const Color(0xFF7C3AED) : Colors.white38,
                    ),
                    title: Text(m.titre, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(m.artiste, style: TextStyle(color: Colors.white.withAlpha(102))),
                    onTap: () {
                      setModalState(() {
                        if (dejaPresent) {
                          widget.playlist.morceaux.remove(m);
                        } else {
                          widget.playlist.morceaux.add(m);
                        }
                      });
                      setState(() {});
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final morceaux = widget.playlist.morceaux;
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(widget.playlist.nom),
        actions: [
          IconButton(icon: const Icon(Icons.add_rounded), onPressed: _ajouterMorceaux),
        ],
      ),
      body: morceaux.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.music_off_rounded, size: 64, color: Colors.white.withAlpha(26)),
                  const SizedBox(height: 12),
                  Text('Playlist vide', style: TextStyle(color: Colors.white.withAlpha(102))),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _ajouterMorceaux,
                    icon: const Icon(Icons.add_rounded, color: Color(0xFF7C3AED)),
                    label: const Text('Ajouter des morceaux', style: TextStyle(color: Color(0xFF7C3AED))),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: morceaux.length,
              itemBuilder: (ctx, i) => Dismissible(
                key: Key(morceaux[i].chemin),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withAlpha(51),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                ),
                onDismissed: (_) => setState(() => morceaux.removeAt(i)),
                child: CarteMorceau(
                  morceau: morceaux[i],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PageLecteur(morceau: morceaux[i], playlist: morceaux),
                    ),
                  ),
                  onFavoriToggle: () => setState(() => morceaux[i].estFavori = !morceaux[i].estFavori),
                ),
              ),
            ),
    );
  }
}
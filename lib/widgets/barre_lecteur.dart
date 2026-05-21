import 'package:flutter/material.dart';
import '../models/morceau.dart';
import '../services/database_service.dart';
import '../pages/page_lecteur.dart';

class BarreLecteur extends StatefulWidget {
  final Morceau morceau;
  final List<Morceau> playlist;
  final int initialIndex;
  final bool reprendreLectureEnCours;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final Future<void> Function(String cheminSupprime)? onLecteurClosed;

  const BarreLecteur({
    super.key,
    required this.morceau,
    this.playlist = const [],
    this.initialIndex = 0,
    this.reprendreLectureEnCours = false,
    this.isPlaying = true,
    required this.onPlayPause,
    this.onLecteurClosed,
  });

  @override
  State<BarreLecteur> createState() => _BarreLecteurState();
}

class _BarreLecteurState extends State<BarreLecteur> {
  final DatabaseService _db = DatabaseService.instance;
  bool _estFavori = false;
  bool _chargementFavori = false;

  @override
  void initState() {
    super.initState();
    _chargerEtatFavori();
  }

  @override
  void didUpdateWidget(covariant BarreLecteur oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.morceau.chemin != widget.morceau.chemin) {
      _chargerEtatFavori();
    }
  }

  Future<void> _chargerEtatFavori() async {
    if (widget.morceau.chemin.isEmpty) {
      if (mounted) {
        setState(() => _estFavori = false);
      }
      return;
    }

    final estFavori = await _db.estFavori(widget.morceau.chemin);
    if (!mounted) return;
    setState(() => _estFavori = estFavori);
  }

  Future<void> _basculerFavori() async {
    if (_chargementFavori || widget.morceau.chemin.isEmpty) return;

    setState(() => _chargementFavori = true);
    final etaitFavori = _estFavori;

    try {
      if (etaitFavori) {
        await _db.retirerFavori(widget.morceau.chemin);
      } else {
        await _db.ajouterFavori(widget.morceau);
      }

      if (!mounted) return;
      setState(() => _estFavori = !etaitFavori);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            etaitFavori ? 'Retiré des favoris.' : 'Ajouté aux favoris.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _chargementFavori = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final cheminSupprime = await Navigator.push<String?>(
          context,
          PageLecteur.route(
            morceau: widget.morceau,
            playlist: widget.playlist.isEmpty ? [widget.morceau] : widget.playlist,
            initialIndex: widget.initialIndex,
            reprendreLectureEnCours: widget.reprendreLectureEnCours,
          ),
        );
        if (cheminSupprime != null && widget.onLecteurClosed != null) {
          await widget.onLecteurClosed!(cheminSupprime);
        }
      },
      child: Container(
        height: 70,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C3E),
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF00E5FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.music_note, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    morceau.titre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    morceau.artiste,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                _estFavori ? Icons.favorite : Icons.favorite_border,
                color: _estFavori ? const Color(0xFF6C63FF) : Colors.white,
              ),
              onPressed: _chargementFavori ? null : _basculerFavori,
            ),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).primaryColor,
              ),
              child: IconButton(
                icon: Icon(
                  widget.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
                onPressed: widget.onPlayPause,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
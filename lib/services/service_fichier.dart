import 'package:on_audio_query/on_audio_query.dart';
import 'package:file_picker/file_picker.dart';
import '../models/morceau.dart';

class ServiceFichiers {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  // ── Scan automatique de la bibliothèque du téléphone ───────
  // Retourne tous les fichiers audio détectés par Android/iOS.
  Future<List<Morceau>> scannerBibliotheque() async {
    // Demande la permission (obligatoire sur Android 13+)
    final permissionOk = await _audioQuery.permissionsRequest();
    if (!permissionOk) return [];

    final songs = await _audioQuery.querySongs(
      sortType:   SongSortType.TITLE,
      orderType:  OrderType.ASC_OR_SMALLER,
      uriType:    UriType.EXTERNAL,
      ignoreCase: true,
    );

    return songs
        .where((s) => s.data.isNotEmpty) // ignore les entrées sans chemin
        .map((s) => Morceau(
              titre:   s.title,
              artiste: s.artist  ?? 'Artiste inconnu',
              chemin:  s.data,
              duree:   Duration(milliseconds: s.duration ?? 0),
            ))
        .toList();
  }

  // ── Sélection manuelle via le sélecteur système ────────────
  // L'utilisateur choisit lui-même un ou plusieurs fichiers audio.
  Future<List<Morceau>> choisirFichiers() async {
    final result = await FilePicker.platform.pickFiles(
      type:          FileType.audio,
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty) return [];

    return result.files
        .where((f) => f.path != null)
        .map((f) {
          // Nom affiché = nom du fichier sans extension
          final nomBrut     = f.name;
          final nomSansExt  = nomBrut.contains('.')
              ? nomBrut.substring(0, nomBrut.lastIndexOf('.'))
              : nomBrut;

          return Morceau(
            titre:   nomSansExt,
            artiste: 'Artiste inconnu',
            chemin:  f.path!,
            duree:   Duration.zero, // durée inconnue avant lecture
          );
        })
        .toList();
  }

  // ── Pochette d'un morceau (Android uniquement) ─────────────
  Future<List<int>?> chargerPochette(int songId) async {
    return _audioQuery.queryArtwork(
      songId,
      ArtworkType.AUDIO,
      format: ArtworkFormat.JPEG,
      size:   200,
    );
  }
}

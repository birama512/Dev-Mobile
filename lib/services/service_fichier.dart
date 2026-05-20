import 'package:on_audio_query/on_audio_query.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../models/morceau.dart';

class ServiceFichiers {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  String _mimeTypePourFichier(String nomFichier) {
    final extension = nomFichier.split('.').last.toLowerCase();
    switch (extension) {
      case 'mp3':
        return 'audio/mpeg';
      case 'm4a':
        return 'audio/mp4';
      case 'aac':
        return 'audio/aac';
      case 'wav':
        return 'audio/wav';
      case 'ogg':
        return 'audio/ogg';
      case 'flac':
        return 'audio/flac';
      default:
        return 'audio/mpeg';
    }
  }

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
    final result = await FilePicker.pickFiles(
      type:          FileType.audio,
      allowMultiple: true,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return [];

    final morceaux = await Future.wait(
      result.files
        .where((f) => f.path != null || f.bytes != null)
        .map((f) async {
          final nomBrut = f.name;
          final nomSansExt = nomBrut.contains('.')
              ? nomBrut.substring(0, nomBrut.lastIndexOf('.'))
              : nomBrut;

          return Morceau(
            titre: nomSansExt,
            artiste: 'Artiste inconnu',
            chemin: f.path ?? '',
            duree: Duration.zero,
            bytes: f.bytes,
            mimeType: _mimeTypePourFichier(f.name),
          );
        }),
    );

    return morceaux;
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
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/morceau.dart';

class ServiceFichiers {

  String _mimeTypePourFichier(String nomFichier) {
    final ext = nomFichier.split('.').last.toLowerCase();
    switch (ext) {
      case 'mp3':  return 'audio/mpeg';
      case 'm4a':  return 'audio/mp4';
      case 'aac':  return 'audio/aac';
      case 'wav':  return 'audio/wav';
      case 'ogg':  return 'audio/ogg';
      case 'flac': return 'audio/flac';
      default:     return 'audio/mpeg';
    }
  }

  /// Sur Windows/desktop : retourne [] — pas de scan système disponible.
  Future<List<Morceau>> scannerBibliotheque() async => [];

  /// Sélection manuelle de fichiers audio via le sélecteur système.
  Future<List<Morceau>> choisirFichiers() async {
    final estDesktop =
        Platform.isWindows || Platform.isLinux || Platform.isMacOS;

    // file_picker >= 10.3.9 : FilePicker.pickFiles() — plus de .platform
    final result = await FilePicker.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
      withData: !estDesktop, // bytes uniquement sur mobile
    );

    if (result == null || result.files.isEmpty) return [];

    return result.files
        .where((f) => f.path != null || f.bytes != null)
        .map((f) {
          final nomBrut    = f.name;
          final nomSansExt = nomBrut.contains('.')
              ? nomBrut.substring(0, nomBrut.lastIndexOf('.'))
              : nomBrut;

          return Morceau(
            titre:    nomSansExt,
            artiste:  'Artiste inconnu',
            chemin:   f.path ?? '',
            duree:    Duration.zero,
            bytes:    estDesktop ? null : f.bytes,
            mimeType: _mimeTypePourFichier(f.name),
          );
        })
        .toList();
  }
}

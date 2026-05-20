import 'dart:io';
import 'package:flutter/foundation.dart';
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
  Future<List<Morceau>> scannerBibliotheque() async => [];
  Future<List<Morceau>> choisirFichiers() async {
    final estDesktop =
        !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
    final result = await FilePicker.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
      withData: !estDesktop,
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

import 'dart:typed_data';

class Morceau {
  final String titre;
  final String artiste;
  final String chemin;
  final Duration duree;
  final Uint8List? bytes;
  final String? mimeType;

  Morceau({
    required this.titre,
    required this.artiste,
    required this.chemin,
    required this.duree,
    this.bytes,
    this.mimeType,
  });

  bool get hasSource => chemin.isNotEmpty || bytes != null;
}
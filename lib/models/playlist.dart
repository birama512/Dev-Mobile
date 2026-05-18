import 'morceau.dart';

class Playlist {
  final String nom;
  final List<Morceau> morceaux;

  Playlist({
    required this.nom,
    required this.morceaux,
  });
}
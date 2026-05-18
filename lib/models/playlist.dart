import 'morceau.dart';

class Playlist {
  String nom;
  final List<Morceau> morceaux;

  Playlist({
    required this.nom,
    required this.morceaux,
  });
}
class Morceau {
  final String titre;
  final String artiste;
  final String chemin;
  final int duree; // durée en secondes
  bool estFavori;

  Morceau({
    required this.titre,
    required this.artiste,
    required this.chemin,
    required this.duree,
    this.estFavori = false,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Morceau &&
            runtimeType == other.runtimeType &&
            chemin == other.chemin;
  }

  @override
  int get hashCode => chemin.hashCode;
}
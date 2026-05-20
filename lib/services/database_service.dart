import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/morceau.dart';
import '../models/playlist.dart';

/// Service singleton qui gère toute la persistance locale via SQLite.
/// Compatible Windows / Linux / macOS grâce à sqflite_common_ffi.
class DatabaseService {
  // ── Singleton ────────────────────────────────────────────────
  static final DatabaseService instance = DatabaseService._internal();
  factory DatabaseService() => instance;
  DatabaseService._internal();

  static Database? _db;

  // ── Noms des tables ─────────────────────────────────────────
  static const String _tableMorceaux  = 'morceaux';
  static const String _tablePlaylists = 'playlists';
  static const String _tableLiaison   = 'playlist_morceaux';
  static const String _tableFavoris   = 'favoris';

  // ── Ouverture / création ─────────────────────────────────────
  Future<Database> get db async {
    _db ??= await _ouvrir();
    return _db!;
  }

  Future<Database> _ouvrir() async {
    // Chemin fiable sur toutes les plateformes sans path_provider
    String chemin;
    if (Platform.isWindows) {
      // %APPDATA%\musique.db  ex: C:\Users\xxx\AppData\Roaming\musique.db
      final appData = Platform.environment['APPDATA'] ?? '.';
      chemin = join(appData, 'musique.db');
    } else if (Platform.isLinux || Platform.isMacOS) {
      final home = Platform.environment['HOME'] ?? '.';
      chemin = join(home, '.local', 'share', 'musique.db');
    } else {
      // Android / iOS : getDatabasesPath() fonctionne normalement
      chemin = join(await databaseFactory.getDatabasesPath(), 'musique.db');
    }

    return databaseFactory.openDatabase(
      chemin,
      options: OpenDatabaseOptions(
        version:  1,
        onCreate: _creerTables,
      ),
    );
  }

  Future<void> _creerTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableMorceaux (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        titre     TEXT    NOT NULL,
        artiste   TEXT    NOT NULL,
        chemin    TEXT    NOT NULL UNIQUE,
        duree_ms  INTEGER NOT NULL DEFAULT 0,
        mime_type TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $_tablePlaylists (
        id  INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT    NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $_tableLiaison (
        playlist_id  INTEGER NOT NULL,
        morceau_id   INTEGER NOT NULL,
        position     INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (playlist_id, morceau_id),
        FOREIGN KEY (playlist_id) REFERENCES $_tablePlaylists(id) ON DELETE CASCADE,
        FOREIGN KEY (morceau_id)  REFERENCES $_tableMorceaux(id)  ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $_tableFavoris (
        morceau_id INTEGER PRIMARY KEY,
        ajoute_le  TEXT NOT NULL,
        FOREIGN KEY (morceau_id) REFERENCES $_tableMorceaux(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('PRAGMA foreign_keys = ON');
  }

  // ════════════════════════════════════════════════════════════
  // MORCEAUX
  // ════════════════════════════════════════════════════════════

  Future<int> sauvegarderMorceau(Morceau morceau) async {
    final base = await db;
    return base.insert(
      _tableMorceaux,
      {
        'titre':     morceau.titre,
        'artiste':   morceau.artiste,
        'chemin':    morceau.chemin,
        'duree_ms':  morceau.duree.inMilliseconds,
        'mime_type': morceau.mimeType,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> sauvegarderMorceaux(List<Morceau> morceaux) async {
    // Ignore les morceaux sans chemin valide (ex: bytes-only sur mobile)
    final valides = morceaux.where((m) => m.chemin.isNotEmpty).toList();
    if (valides.isEmpty) return;

    final base  = await db;
    final batch = base.batch();
    for (final m in valides) {
      batch.insert(
        _tableMorceaux,
        {
          'titre':     m.titre,
          'artiste':   m.artiste,
          'chemin':    m.chemin,
          'duree_ms':  m.duree.inMilliseconds,
          'mime_type': m.mimeType,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Morceau>> lireMorceaux() async {
    final base = await db;
    final rows = await base.query(_tableMorceaux, orderBy: 'titre ASC');
    return rows.map(_rowVersMorceau).toList();
  }

  Future<List<Morceau>> rechercherMorceaux(String requete) async {
    final base = await db;
    final q    = '%${requete.toLowerCase()}%';
    final rows = await base.rawQuery('''
      SELECT * FROM $_tableMorceaux
      WHERE LOWER(titre) LIKE ? OR LOWER(artiste) LIKE ?
      ORDER BY titre ASC
    ''', [q, q]);
    return rows.map(_rowVersMorceau).toList();
  }

  Future<void> supprimerMorceau(String chemin) async {
    final base = await db;
    await base.delete(
      _tableMorceaux,
      where:     'chemin = ?',
      whereArgs: [chemin],
    );
  }

  // ════════════════════════════════════════════════════════════
  // PLAYLISTS
  // ════════════════════════════════════════════════════════════

  Future<int> creerPlaylist(String nom) async {
    final base = await db;
    return base.insert(_tablePlaylists, {'nom': nom});
  }

  Future<List<Playlist>> lirePlaylists() async {
    final base   = await db;
    final rowsPl = await base.query(_tablePlaylists, orderBy: 'nom ASC');
    final result = <Playlist>[];

    for (final row in rowsPl) {
      final id       = row['id'] as int;
      final morceaux = await _lireMorceauxDePlaylist(base, id);
      result.add(Playlist(nom: row['nom'] as String, morceaux: morceaux));
    }
    return result;
  }

  Future<List<Morceau>> _lireMorceauxDePlaylist(
    Database base,
    int playlistId,
  ) async {
    final rows = await base.rawQuery('''
      SELECT m.* FROM $_tableMorceaux m
      INNER JOIN $_tableLiaison l ON l.morceau_id = m.id
      WHERE l.playlist_id = ?
      ORDER BY l.position ASC
    ''', [playlistId]);
    return rows.map(_rowVersMorceau).toList();
  }

  Future<void> ajouterMorceauAPlaylist(
    String nomPlaylist,
    Morceau morceau,
  ) async {
    final base = await db;

    final rowsPl = await base.query(
      _tablePlaylists,
      where:     'nom = ?',
      whereArgs: [nomPlaylist],
      limit:     1,
    );
    if (rowsPl.isEmpty) return;
    final playlistId = rowsPl.first['id'] as int;

    final rowsM = await base.query(
      _tableMorceaux,
      where:     'chemin = ?',
      whereArgs: [morceau.chemin],
      limit:     1,
    );
    if (rowsM.isEmpty) return;
    final morceauId = rowsM.first['id'] as int;

    final countResult = await base.rawQuery(
      'SELECT COUNT(*) as cnt FROM $_tableLiaison WHERE playlist_id = ?',
      [playlistId],
    );
    final count = (countResult.first['cnt'] as int? ?? 0);

    await base.insert(
      _tableLiaison,
      {
        'playlist_id': playlistId,
        'morceau_id':  morceauId,
        'position':    count,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> renommerPlaylist(String ancienNom, String nouveauNom) async {
    final base = await db;
    await base.update(
      _tablePlaylists,
      {'nom': nouveauNom},
      where:     'nom = ?',
      whereArgs: [ancienNom],
    );
  }

  Future<void> supprimerPlaylist(String nom) async {
    final base = await db;
    await base.delete(
      _tablePlaylists,
      where:     'nom = ?',
      whereArgs: [nom],
    );
  }

  // ════════════════════════════════════════════════════════════
  // FAVORIS
  // ════════════════════════════════════════════════════════════

  Future<void> ajouterFavori(Morceau morceau) async {
    final base = await db;

    await sauvegarderMorceau(morceau);

    final rows = await base.query(
      _tableMorceaux,
      where:     'chemin = ?',
      whereArgs: [morceau.chemin],
      limit:     1,
    );
    if (rows.isEmpty) return;
    final morceauId = rows.first['id'] as int;

    await base.insert(
      _tableFavoris,
      {
        'morceau_id': morceauId,
        'ajoute_le':  DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> retirerFavori(String chemin) async {
    final base = await db;
    final rows = await base.query(
      _tableMorceaux,
      where:     'chemin = ?',
      whereArgs: [chemin],
      limit:     1,
    );
    if (rows.isEmpty) return;
    final morceauId = rows.first['id'] as int;
    await base.delete(
      _tableFavoris,
      where:     'morceau_id = ?',
      whereArgs: [morceauId],
    );
  }

  Future<List<Morceau>> lireFavoris() async {
    final base = await db;
    final rows = await base.rawQuery('''
      SELECT m.* FROM $_tableMorceaux m
      INNER JOIN $_tableFavoris f ON f.morceau_id = m.id
      ORDER BY f.ajoute_le DESC
    ''');
    return rows.map(_rowVersMorceau).toList();
  }

  Future<bool> estFavori(String chemin) async {
    final base = await db;
    final rows = await base.rawQuery('''
      SELECT f.morceau_id FROM $_tableFavoris f
      INNER JOIN $_tableMorceaux m ON m.id = f.morceau_id
      WHERE m.chemin = ?
    ''', [chemin]);
    return rows.isNotEmpty;
  }

  // ════════════════════════════════════════════════════════════
  // UTILITAIRE
  // ════════════════════════════════════════════════════════════

  Morceau _rowVersMorceau(Map<String, dynamic> row) {
    return Morceau(
      titre:    row['titre']    as String,
      artiste:  row['artiste']  as String,
      chemin:   row['chemin']   as String,
      duree:    Duration(milliseconds: (row['duree_ms'] as int? ?? 0)),
      mimeType: row['mime_type'] as String?,
    );
  }

  Future<void> fermer() async {
    final base = await db;
    await base.close();
    _db = null;
  }
}

import 'package:just_audio/just_audio.dart';

class ServiceAudio {
  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get player => _player;

  // ── Streams exposés aux widgets ────────────────────────────
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration>    get positionStream    => _player.positionStream;
  Stream<Duration?>   get durationStream    => _player.durationStream;

  bool   get isPlaying => _player.playing;
  double get volume    => _player.volume;

  // ── Chargement d'un fichier local ──────────────────────────
  Future<void> chargerFichier(String chemin) async {
    await _player.setFilePath(chemin);
  }

  // ── Contrôles de base ──────────────────────────────────────
  Future<void> play()  async => _player.play();
  Future<void> pause() async => _player.pause();
  Future<void> stop()  async => _player.stop();

  Future<void> togglePlayPause() async {
    _player.playing ? await pause() : await play();
  }

  // ── Seek (barre de progression) ────────────────────────────
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  // ── Volume ─────────────────────────────────────────────────
  Future<void> setVolume(double valeur) async {
    await _player.setVolume(valeur.clamp(0.0, 1.0));
  }

  // ── Playlist ───────────────────────────────────────────────
  Future<void> chargerPlaylist(List<String> chemins, {int index = 0}) async {
    final sources = chemins.map((c) => AudioSource.file(c)).toList();
    await _player.setAudioSource(
      ConcatenatingAudioSource(children: sources),
      initialIndex: index,
    );
  }

  Future<void> suivant() async {
    if (_player.hasNext) await _player.seekToNext();
  }

  Future<void> precedent() async {
    // < 3 secondes → revient au début du morceau courant
    if (_player.position.inSeconds < 3) {
      if (_player.hasPrevious) await _player.seekToPrevious();
    } else {
      await seek(Duration.zero);
    }
  }

  // ── Modes de lecture ───────────────────────────────────────
  Future<void> setLoopMode(LoopMode mode) async {
    await _player.setLoopMode(mode);
  }

  Future<void> setShuffle(bool actif) async {
    await _player.setShuffleModeEnabled(actif);
  }

  // ── Libération des ressources ──────────────────────────────
  Future<void> dispose() async => _player.dispose();
}

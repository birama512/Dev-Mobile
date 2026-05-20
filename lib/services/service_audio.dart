import 'dart:io';
import 'package:just_audio/just_audio.dart';
import '../models/morceau.dart';

class ServiceAudio {
  ServiceAudio._();
  static final ServiceAudio instance = ServiceAudio._();

  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get player => _player;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration>    get positionStream     => _player.positionStream;
  Stream<Duration?>   get durationStream     => _player.durationStream;
  Stream<int?>        get currentIndexStream => _player.currentIndexStream;

  bool   get isPlaying => _player.playing;
  double get volume    => _player.volume;

  // ── Construit la source audio selon la plateforme ───────────
  //
  // Windows ne supporte PAS Uri.dataFromBytes → on passe toujours
  // par le chemin fichier. Les bytes ne sont utilisés que sur Web.
  AudioSource _sourceFromMorceau(Morceau morceau) {
    // Priorité 1 : chemin fichier valide (fonctionne partout)
    if (morceau.chemin.isNotEmpty) {
      return AudioSource.file(morceau.chemin);
    }

    // Priorité 2 : bytes en mémoire — uniquement sur Web
    // (pas de support sur Windows/Linux/macOS via just_audio)
    if (morceau.bytes != null && morceau.bytes!.isNotEmpty) {
      // Sur Web, just_audio accepte une URI data
      // Sur les autres plateformes, on écrit un fichier tmp
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Écrit les bytes dans un fichier temporaire puis joue via chemin
        final tmp = _ecrireFichierTemp(morceau);
        if (tmp != null) return AudioSource.file(tmp);
      }
    }

    // Fallback : URI vide → just_audio lancera une erreur gérée
    return AudioSource.uri(Uri.parse(''));
  }

  // Écrit les bytes d'un morceau dans un fichier temporaire.
  // Retourne le chemin du fichier créé, ou null si échec.
  String? _ecrireFichierTemp(Morceau morceau) {
    try {
      final ext = morceau.mimeType?.contains('mp4') == true ? 'm4a'
                : morceau.mimeType?.contains('wav') == true ? 'wav'
                : morceau.mimeType?.contains('ogg') == true ? 'ogg'
                : 'mp3';
      final tmp = File('${Directory.systemTemp.path}/audio_tmp_${DateTime.now().millisecondsSinceEpoch}.$ext');
      tmp.writeAsBytesSync(morceau.bytes!);
      return tmp.path;
    } catch (_) {
      return null;
    }
  }

  // ── Chargement ──────────────────────────────────────────────
  Future<void> chargerFichier(String chemin) async {
    await _player.setFilePath(chemin);
  }

  Future<bool> chargerPlaylist(List<Morceau> morceaux, {int index = 0}) async {
    // Filtre : garde uniquement les morceaux avec un chemin valide
    final valides = morceaux.where((m) => m.chemin.isNotEmpty || m.bytes != null).toList();

    if (valides.isEmpty) {
      print('[ServiceAudio] Aucun morceau avec source valide.');
      return false;
    }

    final sources    = valides.map(_sourceFromMorceau).toList();
    final safeIndex  = index.clamp(0, valides.length - 1);

    print('[ServiceAudio] Chargement ${valides.length} morceaux, index=$safeIndex');
    print('[ServiceAudio] Premier chemin : ${valides[safeIndex].chemin}');

    await _player.setAudioSource(
      ConcatenatingAudioSource(children: sources),
      initialIndex: safeIndex,
    );
    return true;
  }

  Future<bool> chargerEtLire(Morceau morceau) async {
    final charge = await chargerPlaylist([morceau]);
    if (!charge) return false;
    await play();
    return true;
  }

  // ── Contrôles ───────────────────────────────────────────────
  Future<void> play()           async => _player.play();
  Future<void> pause()          async => _player.pause();
  Future<void> stop()           async => _player.stop();

  Future<void> togglePlayPause() async {
    _player.playing ? await pause() : await play();
  }

  Future<void> seek(Duration position) async => _player.seek(position);

  Future<void> setVolume(double valeur) async {
    await _player.setVolume(valeur.clamp(0.0, 1.0));
  }

  // ── Navigation playlist ─────────────────────────────────────
  Future<void> suivant() async {
    if (_player.hasNext) await _player.seekToNext();
  }

  Future<void> precedent() async {
    if (_player.position.inSeconds < 3) {
      if (_player.hasPrevious) await _player.seekToPrevious();
    } else {
      await seek(Duration.zero);
    }
  }

  // ── Modes ───────────────────────────────────────────────────
  Future<void> setLoopMode(LoopMode mode) async => _player.setLoopMode(mode);
  Future<void> setShuffle(bool actif)     async => _player.setShuffleModeEnabled(actif);

  // ── Nettoyage ───────────────────────────────────────────────
  Future<void> dispose() async => _player.dispose();
}

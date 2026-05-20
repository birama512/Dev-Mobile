import 'dart:io';
import 'package:flutter/foundation.dart';
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

  AudioSource _sourceFromMorceau(Morceau morceau) {
    if (morceau.chemin.isNotEmpty) {
      if (kIsWeb) {
        final webUri = _normaliserUriWeb(morceau.chemin);
        if (webUri != null) return AudioSource.uri(webUri);
      }
      return AudioSource.file(morceau.chemin);
    }

    if (morceau.bytes != null && morceau.bytes!.isNotEmpty) {
      if (kIsWeb) {
        final dataUri = Uri.dataFromBytes(
          morceau.bytes!,
          mimeType: morceau.mimeType ?? 'audio/mpeg',
        );
        return AudioSource.uri(dataUri);
      }
      if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        final tmp = _ecrireFichierTemp(morceau);
        if (tmp != null) return AudioSource.file(tmp);
      }
    }
    return AudioSource.uri(Uri.parse(''));
  }

  Uri? _normaliserUriWeb(String valeur) {
    final brut = valeur.trim();
    if (brut.isEmpty) return null;

    final candidats = <String>{
      brut,
      Uri.decodeFull(brut),
      Uri.decodeComponent(brut),
    };

    for (final candidat in candidats) {
      final uri = Uri.tryParse(candidat);
      if (uri != null && uri.hasScheme) {
        return uri;
      }
    }

    return null;
  }

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

  Future<void> chargerFichier(String chemin) async {
    await _player.setFilePath(chemin);
  }

  Future<bool> chargerPlaylist(List<Morceau> morceaux, {int index = 0}) async {
    final valides = morceaux.where((m) => m.chemin.isNotEmpty || m.bytes != null).toList();

    if (valides.isEmpty) {
      debugPrint('[ServiceAudio] Aucun morceau avec source valide.');
      return false;
    }

    final sources   = valides.map(_sourceFromMorceau).toList();
    final safeIndex = index.clamp(0, valides.length - 1);

    debugPrint('[ServiceAudio] Chargement ${valides.length} morceaux, index=$safeIndex');
    debugPrint('[ServiceAudio] Premier chemin : ${valides[safeIndex].chemin}');

    final playlist = ConcatenatingAudioSource(children: sources);
    await _player.setAudioSource(playlist, initialIndex: safeIndex);
    return true;
  }

  Future<bool> chargerEtLire(Morceau morceau) async {
    final charge = await chargerPlaylist([morceau]);
    if (!charge) return false;
    await play();
    return true;
  }

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

  Future<void> setLoopMode(LoopMode mode) async => _player.setLoopMode(mode);
  Future<void> setShuffle(bool actif)     async => _player.setShuffleModeEnabled(actif);
  Future<void> dispose() async => _player.dispose();
}

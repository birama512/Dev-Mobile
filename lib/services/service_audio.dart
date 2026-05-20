import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';

import '../models/morceau.dart';

class ServiceAudio {
  ServiceAudio._();

  static final ServiceAudio instance = ServiceAudio._();

  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get player => _player;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<int?> get currentIndexStream => _player.currentIndexStream;

  bool get isPlaying => _player.playing;
  double get volume => _player.volume;

  AudioSource _sourceFromMorceau(Morceau morceau) {
    if (morceau.bytes != null && morceau.bytes!.isNotEmpty) {
      final mimeType = morceau.mimeType ?? 'audio/mpeg';
      return AudioSource.uri(
        Uri.dataFromBytes(
          morceau.bytes as Uint8List,
          mimeType: mimeType,
        ),
      );
    }

    return AudioSource.file(morceau.chemin);
  }

  Future<void> chargerFichier(String chemin) async {
    await _player.setFilePath(chemin);
  }

  Future<bool> chargerPlaylist(List<Morceau> morceaux, {int index = 0}) async {
    final morceauxValides = morceaux.where((morceau) => morceau.hasSource).toList();
    if (morceauxValides.isEmpty) {
      return false;
    }

    final sources = morceauxValides.map(_sourceFromMorceau).toList();
    final safeIndex = index.clamp(0, morceauxValides.length - 1);

    await _player.setAudioSource(
      ConcatenatingAudioSource(children: sources),
      initialIndex: safeIndex,
    );
    return true;
  }

  Future<bool> chargerEtLire(Morceau morceau) async {
    final charge = await chargerPlaylist([morceau]);
    if (!charge) {
      return false;
    }

    await play();
    return true;
  }

  Future<void> play() async => _player.play();
  Future<void> pause() async => _player.pause();
  Future<void> stop() async => _player.stop();

  Future<void> togglePlayPause() async {
    _player.playing ? await pause() : await play();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> setVolume(double valeur) async {
    await _player.setVolume(valeur.clamp(0.0, 1.0));
  }

  Future<void> suivant() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    }
  }

  Future<void> precedent() async {
    if (_player.position.inSeconds < 3) {
      if (_player.hasPrevious) {
        await _player.seekToPrevious();
      }
    } else {
      await seek(Duration.zero);
    }
  }

  Future<void> setLoopMode(LoopMode mode) async {
    await _player.setLoopMode(mode);
  }

  Future<void> setShuffle(bool actif) async {
    await _player.setShuffleModeEnabled(actif);
  }

  Future<void> dispose() async => _player.dispose();
}
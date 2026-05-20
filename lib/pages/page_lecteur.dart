import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';

import '../models/morceau.dart';
import '../services/service_audio.dart';
import '../services/service_fichier.dart';

class PageLecteur extends StatefulWidget {
  final Morceau morceau;
  final List<Morceau> playlist;
  final int initialIndex;

  const PageLecteur({
    super.key,
    required this.morceau,
    this.playlist = const [],
    this.initialIndex = 0,
  });

  static Route<void> route({
    required Morceau morceau,
    List<Morceau> playlist = const [],
    int initialIndex = 0,
  }) {
    return PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) {
        return PageLecteur(
          morceau: morceau,
          playlist: playlist,
          initialIndex: initialIndex,
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;
        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  @override
  State<PageLecteur> createState() => _PageLecteurState();
}

class _PageLecteurState extends State<PageLecteur> {
  final ServiceAudio _serviceAudio = ServiceAudio.instance;
  final ServiceFichiers _serviceFichiers = ServiceFichiers();

  bool _isMinimized = false;
  bool _isPreparing = true;
  bool _hasAudio = false;
  bool _shuffleEnabled = false;
  LoopMode _loopMode = LoopMode.off;
  List<Morceau> _queue = const [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _preparePlayback();
  }

  List<Morceau> _buildQueue() {
    final baseQueue = widget.playlist.isNotEmpty ? widget.playlist : [widget.morceau];
    return baseQueue.where((morceau) => morceau.hasSource).toList();
  }

  Future<void> _preparePlayback() async {
    final queue = _buildQueue();
    if (!mounted) {
      return;
    }

    if (queue.isEmpty) {
      setState(() {
        _queue = const [];
        _currentIndex = 0;
        _hasAudio = false;
        _isPreparing = false;
      });
      return;
    }

    final selectedIndex = widget.morceau.hasSource
      ? queue.indexWhere((morceau) => morceau.chemin == widget.morceau.chemin || (morceau.bytes != null && widget.morceau.bytes != null && identical(morceau.bytes, widget.morceau.bytes)))
        : -1;
    final safeIndex = selectedIndex >= 0
        ? selectedIndex
        : widget.initialIndex.clamp(0, queue.length - 1);

    final loaded = await _serviceAudio.chargerPlaylist(queue, index: safeIndex);
    if (!mounted) {
      return;
    }

    setState(() {
      _queue = queue;
      _currentIndex = safeIndex;
      _hasAudio = loaded;
      _isPreparing = false;
    });

    if (loaded) {
      await _serviceAudio.play();
    }
  }

  Future<void> _importAndPlay() async {
    final morceaux = await _serviceFichiers.choisirFichiers();
    if (!mounted || morceaux.isEmpty) {
      return;
    }

    final loaded = await _serviceAudio.chargerPlaylist(morceaux, index: 0);
    if (!mounted) {
      return;
    }

    if (!loaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun fichier audio valide n\'a été trouvé.')),
      );
      return;
    }

    setState(() {
      _queue = morceaux;
      _currentIndex = 0;
      _hasAudio = true;
      _isPreparing = false;
    });

    await _serviceAudio.play();
  }

  Future<void> _toggleShuffle() async {
    _shuffleEnabled = !_shuffleEnabled;
    setState(() {});
    await _serviceAudio.setShuffle(_shuffleEnabled);
  }

  Future<void> _toggleLoopMode() async {
    switch (_loopMode) {
      case LoopMode.off:
        _loopMode = LoopMode.all;
        break;
      case LoopMode.all:
        _loopMode = LoopMode.one;
        break;
      case LoopMode.one:
        _loopMode = LoopMode.off;
        break;
    }

    setState(() {});
    await _serviceAudio.setLoopMode(_loopMode);
  }

  Future<void> _seekToIndex(int index) async {
    if (index < 0 || index >= _queue.length) {
      return;
    }

    await _serviceAudio.player.seek(Duration.zero, index: index);
    await _serviceAudio.play();

    if (!mounted) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final currentTrack = _queue.isNotEmpty && _currentIndex >= 0 && _currentIndex < _queue.length
        ? _queue[_currentIndex]
        : widget.morceau;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E1E2C), Color(0xFF0D0D14)],
              ),
            ),
          ),
          Positioned(
            top: 90,
            left: -50,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).primaryColor.withOpacity(0.16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.18),
                    blurRadius: 100,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          _isMinimized ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          size: 32,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _isMinimized = !_isMinimized;
                          });
                        },
                      ),
                      Column(
                        children: [
                          Text(
                            _hasAudio ? 'En lecture' : 'Audio prêt',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.3,
                              color: Colors.white70,
                            ),
                          ),
                          if (_queue.isNotEmpty)
                            Text(
                              '${_currentIndex + 1}/${_queue.length}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white54,
                              ),
                            ),
                        ],
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_horiz, color: Colors.white),
                        color: const Color(0xFF1A1A24),
                        onSelected: (value) {
                          if (value == 'import') {
                            _importAndPlay();
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem<String>(
                            value: 'import',
                            child: Text('Importer de l\'audio'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _isMinimized
                          ? _buildCompactPlayer(context, currentTrack)
                          : _buildFullPlayer(context, currentTrack),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactPlayer(BuildContext context, Morceau currentTrack) {
    if (_isPreparing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasAudio) {
      return _buildEmptyState(context);
    }

    return Column(
      key: const ValueKey('compact-player'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF2C2C3E), Color(0xFF1A1A24)],
                ),
              ),
              child: const Icon(Icons.music_note_rounded, color: Colors.white54),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentTrack.titre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentTrack.artiste,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            StreamBuilder<PlayerState>(
              stream: _serviceAudio.playerStateStream,
              builder: (context, snapshot) {
                final playing = snapshot.data?.playing ?? _serviceAudio.isPlaying;
                return IconButton(
                  icon: Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                  ),
                  onPressed: _hasAudio ? () => _serviceAudio.togglePlayPause() : null,
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<Duration>(
          stream: _serviceAudio.positionStream,
          builder: (context, snapshot) {
            final position = snapshot.data ?? Duration.zero;
            return StreamBuilder<Duration?>(
              stream: _serviceAudio.durationStream,
              builder: (context, durationSnapshot) {
                final duration = durationSnapshot.data ?? currentTrack.duree;
                final max = duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0;
                final value = position.inMilliseconds.clamp(0, duration.inMilliseconds).toDouble();
                return SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                    activeTrackColor: Theme.of(context).primaryColor,
                    inactiveTrackColor: Colors.white12,
                    thumbColor: Theme.of(context).colorScheme.secondary,
                  ),
                  child: Slider(
                    value: value,
                    max: max,
                    onChanged: _hasAudio
                        ? (newValue) => _serviceAudio.seek(Duration(milliseconds: newValue.round()))
                        : null,
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildFullPlayer(BuildContext context, Morceau currentTrack) {
    if (_isPreparing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasAudio) {
      return _buildEmptyState(context);
    }

    return SingleChildScrollView(
      key: const ValueKey('full-player'),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 18),
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2C2C3E), Color(0xFF1A1A24)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.45),
                  offset: const Offset(10, 14),
                  blurRadius: 26,
                ),
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.28),
                  blurRadius: 42,
                  spreadRadius: -10,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.music_note_rounded,
                  size: 108,
                  color: Colors.white.withOpacity(0.12),
                ),
                Positioned(
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentIndex + 1}/${_queue.length}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            currentTrack.titre,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            currentTrack.artiste,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.72),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 26),
          StreamBuilder<Duration>(
            stream: _serviceAudio.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              return StreamBuilder<Duration?>(
                stream: _serviceAudio.durationStream,
                builder: (context, durationSnapshot) {
                  final duration = durationSnapshot.data ?? currentTrack.duree;
                  final max = duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0;
                  final value = position.inMilliseconds.clamp(0, duration.inMilliseconds).toDouble();

                  return Column(
                    children: [
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 4,
                          activeTrackColor: Theme.of(context).primaryColor,
                          inactiveTrackColor: Colors.white.withOpacity(0.1),
                          thumbColor: Theme.of(context).colorScheme.secondary,
                          overlayColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                        ),
                        child: Slider(
                          value: value,
                          max: max,
                          onChanged: (newValue) {
                            _serviceAudio.seek(Duration(milliseconds: newValue.round()));
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(position),
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                            Text(
                              _formatDuration(duration),
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(
                  _shuffleEnabled ? Icons.shuffle_on : Icons.shuffle,
                  color: _shuffleEnabled ? Theme.of(context).colorScheme.secondary : Colors.white54,
                ),
                onPressed: _toggleShuffle,
              ),
              IconButton(
                icon: const Icon(
                  Icons.skip_previous_rounded,
                  size: 36,
                  color: Colors.white,
                ),
                onPressed: _hasAudio ? _serviceAudio.precedent : null,
              ),
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _hasAudio ? _serviceAudio.togglePlayPause : null,
                    child: StreamBuilder<PlayerState>(
                      stream: _serviceAudio.playerStateStream,
                      builder: (context, snapshot) {
                        final playing = snapshot.data?.playing ?? _serviceAudio.isPlaying;
                        return Icon(
                          playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          size: 38,
                          color: Colors.white,
                        );
                      },
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.skip_next_rounded,
                  size: 36,
                  color: Colors.white,
                ),
                onPressed: _hasAudio ? _serviceAudio.suivant : null,
              ),
              IconButton(
                icon: Icon(
                  _loopMode == LoopMode.off
                      ? Icons.repeat
                      : _loopMode == LoopMode.one
                          ? Icons.repeat_one
                          : Icons.repeat,
                  color: _loopMode == LoopMode.off ? Colors.white54 : Theme.of(context).colorScheme.secondary,
                ),
                onPressed: _toggleLoopMode,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: _importAndPlay,
                  icon: const Icon(Icons.library_add, color: Colors.white70),
                  label: const Text('Ajouter de l\'audio'),
                ),
                TextButton.icon(
                  onPressed: _queue.isEmpty ? null : () => _seekToIndex((_currentIndex + 1).clamp(0, _queue.length - 1)),
                  icon: const Icon(Icons.queue_music, color: Colors.white70),
                  label: Text('${_queue.length} piste(s)'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'File d\'attente',
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: _queue.length,
            separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.06), height: 1),
            itemBuilder: (context, index) {
              final morceau = _queue[index];
              final isCurrent = index == _currentIndex;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: isCurrent ? Theme.of(context).primaryColor : Colors.white.withOpacity(0.08),
                  child: Icon(
                    isCurrent ? Icons.graphic_eq_rounded : Icons.music_note_rounded,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  morceau.titre,
                  style: TextStyle(
                    color: isCurrent ? Colors.white : Colors.white70,
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  morceau.artiste,
                  style: const TextStyle(color: Colors.white54),
                ),
                trailing: Text(
                  morceau.duree.inMilliseconds > 0 ? _formatDuration(morceau.duree) : '--:--',
                  style: const TextStyle(color: Colors.white38),
                ),
                onTap: () => _seekToIndex(index),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      key: const ValueKey('empty-player'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.35),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.28),
                ],
              ),
            ),
            child: const Icon(Icons.headphones_rounded, size: 64, color: Colors.white),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucun vrai fichier audio chargé',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Importe des fichiers audio depuis ton appareil pour activer play, pause, avance et retour.',
            style: TextStyle(color: Colors.white.withOpacity(0.68), fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _importAndPlay,
            icon: const Icon(Icons.upload_file),
            label: const Text('Importer un fichier'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
          ),
        ],
      ),
    );
  }
}
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

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
      pageBuilder: (_, animation, __) => PageLecteur(
        morceau:      morceau,
        playlist:     playlist,
        initialIndex: initialIndex,
      ),
      transitionsBuilder: (_, animation, __, child) {
        final tween = Tween(
          begin: const Offset(0.0, 1.0),
          end:   Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
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
  final ServiceAudio    _serviceAudio    = ServiceAudio.instance;
  final ServiceFichiers _serviceFichiers = ServiceFichiers();

  bool          _isMinimized    = false;
  bool          _isPreparing    = true;
  bool          _hasAudio       = false;
  String?       _erreur;
  bool          _shuffleEnabled = false;
  LoopMode      _loopMode       = LoopMode.off;
  List<Morceau> _queue          = const [];
  int           _currentIndex   = 0;

  @override
  void initState() {
    super.initState();
    // Petit délai pour laisser le widget s'afficher avant de charger l'audio
    Future.delayed(const Duration(milliseconds: 200), _preparePlayback);
  }

  // ── Préparation ──────────────────────────────────────────────

  List<Morceau> _buildQueue() {
    final base = widget.playlist.isNotEmpty
        ? widget.playlist
        : [widget.morceau];
    return base.where(_estLisible).toList();
  }

  bool _estLisible(Morceau m) {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return m.chemin.isNotEmpty && File(m.chemin).existsSync();
    }
    return m.chemin.isNotEmpty || (m.bytes?.isNotEmpty ?? false);
  }

  Future<void> _preparePlayback() async {
    if (!mounted) return;

    final queue = _buildQueue();

    if (queue.isEmpty) {
      if (mounted) {
        setState(() {
          _queue      = [];
          _hasAudio   = false;
          _isPreparing = false;
          _erreur     = 'Aucun fichier audio valide trouvé.\n'
              'Vérifie que le fichier existe encore sur le disque.';
        });
      }
      return;
    }

    // Trouve l'index du morceau sélectionné dans la queue filtrée
    int safeIndex = queue.indexWhere(
      (m) => m.chemin == widget.morceau.chemin,
    );
    if (safeIndex < 0) {
      safeIndex = widget.initialIndex.clamp(0, queue.length - 1);
    }

    try {
      debugPrint('[Lecteur] Chargement ${queue.length} morceaux, index=$safeIndex');
      debugPrint('[Lecteur] Premier chemin : ${queue[safeIndex].chemin}');

      final loaded = await _serviceAudio.chargerPlaylist(
        queue,
        index: safeIndex,
      );

      if (!mounted) return;

      if (!loaded) {
        setState(() {
          _hasAudio    = false;
          _isPreparing = false;
          _erreur      = 'Impossible de charger le fichier audio.';
        });
        return;
      }

      setState(() {
        _queue        = queue;
        _currentIndex = safeIndex;
        _hasAudio     = true;
        _isPreparing  = false;
        _erreur       = null;
      });

      await _serviceAudio.play();

    } catch (e, st) {
      debugPrint('[Lecteur] ERREUR : $e\n$st');
      if (mounted) {
        setState(() {
          _hasAudio    = false;
          _isPreparing = false;
          _erreur      = 'Erreur audio : $e';
        });
      }
    }
  }

  // ── Contrôles ────────────────────────────────────────────────

  Future<void> _importAndPlay() async {
    final morceaux = await _serviceFichiers.choisirFichiers();
    if (!mounted || morceaux.isEmpty) return;

    final loaded = await _serviceAudio.chargerPlaylist(morceaux, index: 0);
    if (!mounted) return;

    if (!loaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun fichier audio valide.')),
      );
      return;
    }

    setState(() {
      _queue        = morceaux;
      _currentIndex = 0;
      _hasAudio     = true;
      _erreur       = null;
    });

    await _serviceAudio.play();
  }

  Future<void> _toggleShuffle() async {
    setState(() => _shuffleEnabled = !_shuffleEnabled);
    await _serviceAudio.setShuffle(_shuffleEnabled);
  }

  Future<void> _toggleLoopMode() async {
    final modes = [LoopMode.off, LoopMode.all, LoopMode.one];
    final next  = modes[(modes.indexOf(_loopMode) + 1) % modes.length];
    setState(() => _loopMode = next);
    await _serviceAudio.setLoopMode(next);
  }

  Future<void> _seekToIndex(int index) async {
    if (index < 0 || index >= _queue.length) return;
    await _serviceAudio.player.seek(Duration.zero, index: index);
    await _serviceAudio.play();
    if (mounted) setState(() => _currentIndex = index);
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final currentTrack = (_queue.isNotEmpty &&
            _currentIndex >= 0 &&
            _currentIndex < _queue.length)
        ? _queue[_currentIndex]
        : widget.morceau;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end:   Alignment.bottomRight,
                colors: [Color(0xFF1E1E2C), Color(0xFF0D0D14)],
              ),
            ),
          ),
          // Glow
          Positioned(
            top: 90, left: -50,
            child: Container(
              width: 280, height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).primaryColor.withOpacity(0.16),
                boxShadow: [BoxShadow(
                  color:      Theme.of(context).primaryColor.withOpacity(0.18),
                  blurRadius: 100, spreadRadius: 40,
                )],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // Top bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          _isMinimized
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 32, color: Colors.white,
                        ),
                        onPressed: () =>
                            setState(() => _isMinimized = !_isMinimized),
                      ),
                      Column(children: [
                        Text(
                          _hasAudio ? 'En lecture' : 'Lecteur',
                          style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            letterSpacing: 1.3, color: Colors.white70,
                          ),
                        ),
                        if (_queue.isNotEmpty)
                          Text(
                            '${_currentIndex + 1}/${_queue.length}',
                            style: const TextStyle(
                              fontSize: 11, color: Colors.white54,
                            ),
                          ),
                      ]),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_horiz, color: Colors.white),
                        color: const Color(0xFF1A1A24),
                        onSelected: (v) {
                          if (v == 'import') _importAndPlay();
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
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
                      child: _isPreparing
                          ? _buildLoading()
                          : _erreur != null
                              ? _buildErreur()
                              : !_hasAudio
                                  ? _buildEmptyState()
                                  : _isMinimized
                                      ? _buildCompact(currentTrack)
                                      : _buildFull(currentTrack),
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

  // ── États ────────────────────────────────────────────────────

  Widget _buildLoading() {
    return const Center(
      key: ValueKey('loading'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFF6C63FF)),
          SizedBox(height: 16),
          Text('Chargement audio…', style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildErreur() {
    return Center(
      key: const ValueKey('erreur'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
            const SizedBox(height: 16),
            Text(
              _erreur ?? 'Erreur inconnue',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _importAndPlay,
              icon:  const Icon(Icons.upload_file),
              label: const Text('Importer un fichier'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      key: const ValueKey('empty'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 150, height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [
                  Theme.of(context).primaryColor.withOpacity(0.35),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.28),
                ]),
              ),
              child: const Icon(
                Icons.headphones_rounded, size: 64, color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucun fichier audio chargé',
              style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Importe des fichiers audio depuis ton appareil.',
              style: TextStyle(color: Colors.white.withOpacity(0.68)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _importAndPlay,
              icon:  const Icon(Icons.upload_file),
              label: const Text('Importer un fichier'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Player compact ───────────────────────────────────────────

  Widget _buildCompact(Morceau track) {
    return Column(
      key: const ValueKey('compact'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF2C2C3E), Color(0xFF1A1A24)],
              ),
            ),
            child: const Icon(
              Icons.music_note_rounded, color: Colors.white54,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(track.titre,
                style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(track.artiste,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          )),
          StreamBuilder<PlayerState>(
            stream: _serviceAudio.playerStateStream,
            builder: (_, snap) {
              final playing = snap.data?.playing ?? false;
              return IconButton(
                icon: Icon(
                  playing
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                ),
                onPressed: _serviceAudio.togglePlayPause,
              );
            },
          ),
        ]),
        const SizedBox(height: 12),
        _buildSlider(track, compact: true),
      ],
    );
  }

  // ── Player complet ───────────────────────────────────────────

  Widget _buildFull(Morceau track) {
    return SingleChildScrollView(
      key: const ValueKey('full'),
      physics: const BouncingScrollPhysics(),
      child: Column(children: [
        const SizedBox(height: 18),
        // Pochette
        Container(
          width: 300, height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end:   Alignment.bottomRight,
              colors: [Color(0xFF2C2C3E), Color(0xFF1A1A24)],
            ),
            boxShadow: [
              BoxShadow(
                color:      Colors.black.withOpacity(0.45),
                offset:     const Offset(10, 14),
                blurRadius: 26,
              ),
              BoxShadow(
                color:      Theme.of(context).primaryColor.withOpacity(0.28),
                blurRadius: 42, spreadRadius: -10,
              ),
            ],
          ),
          child: Stack(alignment: Alignment.center, children: [
            Icon(
              Icons.music_note_rounded, size: 108,
              color: Colors.white.withOpacity(0.12),
            ),
            if (_queue.isNotEmpty)
              Positioned(
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1}/${_queue.length}',
                    style: const TextStyle(
                      color: Colors.white70, fontSize: 12,
                    ),
                  ),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 28),
        Text(track.titre,
          style: const TextStyle(
            fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(track.artiste,
          style: TextStyle(
            fontSize: 16, color: Colors.white.withOpacity(0.72),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 26),
        _buildSlider(track),
        const SizedBox(height: 16),
        // Contrôles
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(
                _shuffleEnabled ? Icons.shuffle_on : Icons.shuffle,
                color: _shuffleEnabled
                    ? Theme.of(context).colorScheme.secondary
                    : Colors.white54,
              ),
              onPressed: _toggleShuffle,
            ),
            IconButton(
              icon: const Icon(
                Icons.skip_previous_rounded, size: 36, color: Colors.white,
              ),
              onPressed: _serviceAudio.precedent,
            ),
            Container(
              width: 76, height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).colorScheme.secondary,
                ]),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _serviceAudio.togglePlayPause,
                  child: StreamBuilder<PlayerState>(
                    stream: _serviceAudio.playerStateStream,
                    builder: (_, snap) {
                      final playing = snap.data?.playing ?? false;
                      return Icon(
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 38, color: Colors.white,
                      );
                    },
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.skip_next_rounded, size: 36, color: Colors.white,
              ),
              onPressed: _serviceAudio.suivant,
            ),
            IconButton(
              icon: Icon(
                _loopMode == LoopMode.one
                    ? Icons.repeat_one
                    : Icons.repeat,
                color: _loopMode == LoopMode.off
                    ? Colors.white54
                    : Theme.of(context).colorScheme.secondary,
              ),
              onPressed: _toggleLoopMode,
            ),
          ],
        ),
        const SizedBox(height: 20),
        // File d'attente
        if (_queue.isNotEmpty) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'File d\'attente',
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 16, fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: _queue.length,
            separatorBuilder: (_, __) => Divider(
              color: Colors.white.withOpacity(0.06), height: 1,
            ),
            itemBuilder: (_, i) {
              final m         = _queue[i];
              final isCurrent = i == _currentIndex;
              return Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: isCurrent
                        ? Theme.of(context).primaryColor
                        : Colors.white.withOpacity(0.08),
                    child: Icon(
                      isCurrent
                          ? Icons.graphic_eq_rounded
                          : Icons.music_note_rounded,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(m.titre,
                    style: TextStyle(
                      color: isCurrent ? Colors.white : Colors.white70,
                      fontWeight: isCurrent
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(m.artiste,
                    style: const TextStyle(color: Colors.white54),
                  ),
                  trailing: Text(
                    m.duree.inMilliseconds > 0 ? _fmt(m.duree) : '--:--',
                    style: const TextStyle(color: Colors.white38),
                  ),
                  onTap: () => _seekToIndex(i),
                ),
              );
            },
          ),
        ],
        const SizedBox(height: 16),
      ]),
    );
  }

  // ── Slider ───────────────────────────────────────────────────

  Widget _buildSlider(Morceau track, {bool compact = false}) {
    return StreamBuilder<Duration>(
      stream: _serviceAudio.positionStream,
      builder: (_, posSnap) {
        final position = posSnap.data ?? Duration.zero;
        return StreamBuilder<Duration?>(
          stream: _serviceAudio.durationStream,
          builder: (_, durSnap) {
            final duration = durSnap.data ?? track.duree;
            final max = duration.inMilliseconds > 0
                ? duration.inMilliseconds.toDouble()
                : 1.0;
            final value = position.inMilliseconds
                .clamp(0, duration.inMilliseconds)
                .toDouble();

            return Column(children: [
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: compact ? 3 : 4,
                  thumbShape: RoundSliderThumbShape(
                    enabledThumbRadius: compact ? 5 : 6,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 14,
                  ),
                  activeTrackColor:
                      Theme.of(context).primaryColor,
                  inactiveTrackColor:
                      Colors.white.withOpacity(0.1),
                  thumbColor:
                      Theme.of(context).colorScheme.secondary,
                  overlayColor: Theme.of(context)
                      .colorScheme
                      .secondary
                      .withOpacity(0.2),
                ),
                child: Slider(
                  value: value,
                  max:   max,
                  onChanged: (v) => _serviceAudio.seek(
                    Duration(milliseconds: v.round()),
                  ),
                ),
              ),
              if (!compact)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_fmt(position),
                        style: const TextStyle(
                          color: Colors.white54, fontSize: 12,
                        ),
                      ),
                      Text(_fmt(duration),
                        style: const TextStyle(
                          color: Colors.white54, fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ]);
          },
        );
      },
    );
  }
}
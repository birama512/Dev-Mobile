import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../services/service_audio.dart';

class PageProfil extends StatefulWidget {
  const PageProfil({super.key});

  @override
  State<PageProfil> createState() => _PageProfilState();
}

class _PageProfilState extends State<PageProfil> {
  final ServiceAudio _audio = ServiceAudio.instance;
  double _volume      = 1.0;
  bool   _aleatoire   = false;
  bool   _repetition  = false;

  @override
  void initState() {
    super.initState();
    _volume = _audio.volume;
  }
  Future<void> _onVolumeChange(double v) async {
    setState(() => _volume = v);
    await _audio.setVolume(v);
  }
  Future<void> _onAleatoireChange(bool v) async {
    setState(() => _aleatoire = v);
    await _audio.setShuffle(v);
  }

  Future<void> _onRepetitionChange(bool v) async {
    setState(() => _repetition = v);
    await _audio.setLoopMode(v ? LoopMode.one : LoopMode.off);
  }

  Future<void> _onDeconnexion() async {
    await _audio.stop();
    if (mounted) Navigator.pop(context);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1E1E2C), Color(0xFF0D0D14)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 24, top: 24, bottom: 16),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        "Profil",
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF00E5FF)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      "JD",
                      style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "John Doe",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  "Membre Premium",
                  style: TextStyle(
                    fontSize: 16,
                    color: const Color(0xFF00E5FF).withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                StreamBuilder<PlayerState>(
                  stream: _audio.playerStateStream,
                  builder: (context, snapshot) {
                    final playing = snapshot.data?.playing ?? false;
                    return Text(
                      playing ? "🎵 En cours de lecture" : "⏸ Lecture en pause",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [

                      _buildSectionTitre("Audio"),
                      _buildVolume(),

                      _buildToggleItem(
                        Icons.shuffle,
                        "Lecture aléatoire",
                        _aleatoire,
                        _onAleatoireChange,
                      ),

                      _buildToggleItem(
                        Icons.repeat_one,
                        "Répéter le morceau",
                        _repetition,
                        _onRepetitionChange,
                      ),

                      _buildSectionTitre("Application"),
                      _buildSettingItem(Icons.notifications_none, "Notifications"),
                      _buildSettingItem(Icons.history,            "Historique d'écoute"),
                      _buildSettingItem(Icons.help_outline,       "Aide & Support"),

                      const SizedBox(height: 24),
                      _buildSettingItem(
                        Icons.logout,
                        "Déconnexion",
                        isDestructive: true,
                        onTap: _onDeconnexion,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSectionTitre(String titre) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        titre,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white.withOpacity(0.4),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildVolume() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          const Icon(Icons.volume_down, color: Colors.white70, size: 24),
          Expanded(
            child: Slider(
              value: _volume,
              min: 0.0,
              max: 1.0,
              activeColor: const Color(0xFF6C63FF),
              inactiveColor: Colors.white24,
              onChanged: _onVolumeChange,
            ),
          ),
          const Icon(Icons.volume_up, color: Colors.white70, size: 24),
        ],
      ),
    );
  }

  Widget _buildToggleItem(
    IconData icon,
    String titre,
    bool valeur,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 28),
          const SizedBox(width: 16),
          Text(titre, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
          const Spacer(),
          Switch(
            value: valeur,
            onChanged: onChanged,
            activeColor: const Color(0xFF6C63FF),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    IconData icon,
    String title, {
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, color: isDestructive ? Colors.redAccent : Colors.white70, size: 28),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isDestructive ? Colors.redAccent : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (!isDestructive)
              const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}

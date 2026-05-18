import 'package:flutter/material.dart';

class PageProfil extends StatelessWidget {
  const PageProfil({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1E1E2C),
                  Color(0xFF0D0D14),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header with back button
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
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Avatar
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
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "John Doe",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
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
                const SizedBox(height: 48),
                // Options de paramètres
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildSettingItem(Icons.settings, "Paramètres de l'application"),
                        _buildSettingItem(Icons.notifications_none, "Notifications"),
                        _buildSettingItem(Icons.history, "Historique d'écoute"),
                        _buildSettingItem(Icons.help_outline, "Aide & Support"),
                        const SizedBox(height: 24),
                        _buildSettingItem(Icons.logout, "Déconnexion", isDestructive: true),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, {bool isDestructive = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isDestructive ? Colors.redAccent : Colors.white70,
            size: 28,
          ),
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
            const Icon(
              Icons.chevron_right,
              color: Colors.white54,
            ),
        ],
      ),
    );
  }
}

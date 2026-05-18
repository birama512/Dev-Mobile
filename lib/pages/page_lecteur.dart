import 'package:flutter/material.dart';

class PageLecteur extends StatefulWidget {
  const PageLecteur({super.key});

  @override
  State<PageLecteur> createState() => _PageLecteurState();
}

class _PageLecteurState extends State<PageLecteur> {
  bool isMinimized = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),

      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E1E2C), Color(0xFF0D0D14)],
              ),
            ),
          ),

          // Glow
          Positioned(
            top: 100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).primaryColor.withOpacity(0.15),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          // Player
          AnimatedAlign(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            alignment: isMinimized ? Alignment.bottomCenter : Alignment.center,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              height: isMinimized ? 110 : MediaQuery.of(context).size.height,
              width: double.infinity,

              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),

                      // TOP BAR
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(
                              isMinimized
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              size: 32,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                isMinimized = !isMinimized;
                              });
                            },
                          ),

                          if (!isMinimized)
                            const Text(
                              "En lecture",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5,
                                color: Colors.white70,
                              ),
                            ),

                          IconButton(
                            icon: const Icon(
                              Icons.more_horiz,
                              color: Colors.white,
                            ),
                            onPressed: () {},
                          ),
                        ],
                      ),

                      // MODE REDUIT
                      if (isMinimized) ...[
                        const SizedBox(height: 5),

                        Row(
                          children: [
                            Container(
                              width: 55,
                              height: 55,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF2C2C3E),
                                    Color(0xFF1A1A24),
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.music_note,
                                color: Colors.white54,
                              ),
                            ),

                            const SizedBox(width: 14),

                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Interstellar Resonance",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "Cosmic Harmonics",
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            IconButton(
                              icon: const Icon(
                                Icons.pause,
                                color: Colors.white,
                              ),
                              onPressed: () {},
                            ),
                          ],
                        ),

                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 5,
                            ),
                            activeTrackColor: Theme.of(context).primaryColor,
                            inactiveTrackColor: Colors.white12,
                            thumbColor: Theme.of(context).colorScheme.secondary,
                          ),
                          child: Slider(value: 0.3, onChanged: (v) {}),
                        ),
                      ],

                      // MODE NORMAL
                      if (!isMinimized)
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              children: [
                                const SizedBox(height: 20),

                                // Album Art
                                Container(
                                  width: 300,
                                  height: 300,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF2C2C3E),
                                        Color(0xFF1A1A24),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.5),
                                        offset: const Offset(10, 10),
                                        blurRadius: 20,
                                      ),
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.05),
                                        offset: const Offset(-5, -5),
                                        blurRadius: 20,
                                      ),
                                      BoxShadow(
                                        color: Theme.of(
                                          context,
                                        ).primaryColor.withOpacity(0.3),
                                        blurRadius: 40,
                                        spreadRadius: -10,
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Icon(
                                          Icons.music_note_rounded,
                                          size: 100,
                                          color: Colors.white.withOpacity(0.1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 40),

                                // Track Info
                                Column(
                                  children: [
                                    const Text(
                                      "Interstellar Resonance",
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Cosmic Harmonics",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.secondary,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 30),

                                // Progress Bar
                                SliderTheme(
                                  data: SliderThemeData(
                                    trackHeight: 4,
                                    activeTrackColor: Theme.of(
                                      context,
                                    ).primaryColor,
                                    inactiveTrackColor: Colors.white
                                        .withOpacity(0.1),
                                    thumbColor: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                    overlayColor: Theme.of(
                                      context,
                                    ).colorScheme.secondary.withOpacity(0.2),
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 6,
                                    ),
                                    overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 14,
                                    ),
                                  ),
                                  child: Slider(
                                    value: 0.3,
                                    onChanged: (val) {},
                                  ),
                                ),

                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "1:24",
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        "4:05",
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Controls
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.shuffle,
                                        color: Colors.white54,
                                      ),
                                      onPressed: () {},
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.skip_previous_rounded,
                                        size: 36,
                                        color: Colors.white,
                                      ),
                                      onPressed: () {},
                                    ),
                                    Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            Theme.of(context).primaryColor,
                                            Theme.of(
                                              context,
                                            ).colorScheme.secondary,
                                          ],
                                        ),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          customBorder: const CircleBorder(),
                                          onTap: () {},
                                          child: const Icon(
                                            Icons.pause_rounded,
                                            size: 36,
                                            color: Colors.white,
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
                                      onPressed: () {},
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.repeat,
                                        color: Colors.white54,
                                      ),
                                      onPressed: () {},
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 30),

                                // Bottom Actions
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 24.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.favorite_border,
                                          color: Colors.white54,
                                        ),
                                        onPressed: () {},
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.queue_music,
                                          color: Colors.white54,
                                        ),
                                        onPressed: () {},
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

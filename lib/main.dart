import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class Artist {
  final String name;
  final String image;

  const Artist({required this.name, required this.image});
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jeu des Artistes',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EEFF),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.music_note_rounded,
                  size: 72,
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Jeu des Artistes',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Retrouve le bon artiste parmi 9 images.\nTu as 1 minute et 3 vies.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ArtistGamePage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text(
                      'Commencer',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ArtistGamePage extends StatefulWidget {
  const ArtistGamePage({super.key});

  @override
  State<ArtistGamePage> createState() => _ArtistGamePageState();
}

class _ArtistGamePageState extends State<ArtistGamePage> {
  final Random random = Random();

  final List<Artist> allArtists = const [
    Artist(name: 'Davido', image: 'assets/images/davido.jpg'),
    Artist(name: 'Asake', image: 'assets/images/asake.jpg'),
    Artist(name: 'Wizkid', image: 'assets/images/wizkid.jpg'),
    Artist(name: 'Ayo Maff', image: 'assets/images/ayomaff.jpg'),
    Artist(name: 'Himra', image: 'assets/images/himra.jpg'),
    Artist(name: 'Naira Marley', image: 'assets/images/nairamarley.jpg'),
    Artist(name: 'Niska', image: 'assets/images/niska.jpg'),
    Artist(name: 'Tiakola', image: 'assets/images/tiakola.jpg'),
    Artist(name: 'Didi B', image: 'assets/images/didib.jpg'),
  ];

  late List<Artist> currentRoundArtists;
  late Artist targetArtist;

  int score = 0;
  int bestScore = 0;
  int lives = 3;
  int timeLeft = 60;
  bool gameOver = false;

  String message = 'Clique sur le bon artiste';
  Color messageColor = Colors.black87;

  Timer? gameTimer;

  @override
  void initState() {
    super.initState();
    loadBestScore();
    startGame();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  Future<void> loadBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      bestScore = prefs.getInt('best_score') ?? 0;
    });
  }

  Future<void> saveBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('best_score', bestScore);
  }

  void startGame() {
    gameTimer?.cancel();

    setState(() {
      score = 0;
      lives = 3;
      timeLeft = 60;
      gameOver = false;
      message = 'Clique sur le bon artiste';
      messageColor = Colors.black87;
    });

    startNewRound();
    startTimer();
  }

  void startTimer() {
    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (timeLeft > 0 && !gameOver) {
        setState(() {
          timeLeft--;
        });
      } else {
        timer.cancel();
        endGame('Temps écoulé');
      }
    });
  }

  void startNewRound() {
    currentRoundArtists = List.from(allArtists)..shuffle();
    targetArtist =
        currentRoundArtists[random.nextInt(currentRoundArtists.length)];

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> checkAnswer(Artist selectedArtist) async {
    if (gameOver) return;

    if (selectedArtist.name == targetArtist.name) {
      bool newRecord = false;

      setState(() {
        score++;
        if (score > bestScore) {
          bestScore = score;
          newRecord = true;
        }
        message = 'Bravo !';
        messageColor = Colors.green;
      });

      if (newRecord) {
        await saveBestScore();
      }
    } else {
      setState(() {
        lives--;
        message = 'Erreur !';
        messageColor = Colors.red;
      });

      if (lives <= 0) {
        endGame('Tu n’as plus de vies');
        return;
      }
    }

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted || gameOver) return;
      setState(() {
        message = 'Clique sur le bon artiste';
        messageColor = Colors.black87;
      });
      startNewRound();
    });
  }

  void endGame(String endMessage) {
    if (gameOver) return;

    gameTimer?.cancel();

    setState(() {
      gameOver = true;
      message = endMessage;
      messageColor = Colors.deepPurple;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Partie terminée', textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(endMessage, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              Text(
                'Score final : $score',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Meilleur score : $bestScore',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                startGame();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Rejouer'),
            ),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Accueil'),
            ),
          ],
        );
      },
    );
  }

  Widget buildHeart(bool active) {
    return Icon(
      Icons.favorite,
      color: active ? Colors.red : Colors.grey.shade400,
      size: 22,
    );
  }

  Widget buildInfoBadge({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget buildArtistCard(Artist artist) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => checkAnswer(artist),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.deepPurple.withOpacity(0.08)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            color: Colors.grey.shade200,
            child: Image.asset(
              artist.image,
              fit: BoxFit.contain,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 34,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1FF),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Jeu des Artistes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Trouve cet artiste',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      targetArtist.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        buildInfoBadge(
                          icon: Icons.star,
                          text: 'Score : $score',
                          color: Colors.deepPurple,
                        ),
                        buildInfoBadge(
                          icon: Icons.emoji_events,
                          text: 'Record : $bestScore',
                          color: Colors.orange,
                        ),
                        buildInfoBadge(
                          icon: Icons.timer,
                          text: 'Temps : $timeLeft s',
                          color: Colors.teal,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              buildHeart(lives >= 1),
                              const SizedBox(width: 4),
                              buildHeart(lives >= 2),
                              const SizedBox(width: 4),
                              buildHeart(lives >= 3),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: messageColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 10.0;
                    final cardWidth =
                        (constraints.maxWidth - (2 * spacing)) / 3;
                    final cardHeight =
                        (constraints.maxHeight - (2 * spacing)) / 3;

                    return GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: currentRoundArtists.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        childAspectRatio: cardWidth / cardHeight,
                      ),
                      itemBuilder: (context, index) {
                        return buildArtistCard(currentRoundArtists[index]);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text(
                    'Recommencer',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

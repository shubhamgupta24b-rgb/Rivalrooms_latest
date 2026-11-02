import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RivalRoomsApp());
}

class RivalRoomsApp extends StatelessWidget {
  const RivalRoomsApp({super.key});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFFB547);
    return MaterialApp(
      title: 'RivalRooms',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.dark,
          surface: const Color(0xFF191B20),
        ),
        scaffoldBackgroundColor: const Color(0xFF101116),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RIVALROOMS',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        actions: [
          IconButton(
            tooltip: 'Profile',
            onPressed: () {},
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF34302A), Color(0xFF1C1D22)],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: .08)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('YOUR NEXT MATCH STARTS HERE',
                    style: TextStyle(
                        color: Color(0xFFFFC36C),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4)),
                SizedBox(height: 12),
                Text('Play. Compete.\nRematch.',
                    style:
                        TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
                SizedBox(height: 8),
                Text('Quick games with friends, on your terms.',
                    style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const _SectionTitle(title: 'PLAY NOW', subtitle: 'Ready to jump in'),
          const SizedBox(height: 12),
          _GameTile(
            title: 'Tic Tac Toe',
            subtitle: 'Classic strategy • 2 players',
            icon: Icons.grid_3x3,
            tag: 'PLAYABLE',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TicTacToeScreen()),
            ),
          ),
          const SizedBox(height: 10),
          const _GameTile(
            title: 'Memory Match',
            subtitle: 'Match pairs • Multiplayer foundation',
            icon: Icons.extension,
            tag: 'COMING NEXT',
          ),
          const SizedBox(height: 10),
          const _GameTile(
            title: 'Pool',
            subtitle: 'Precision and timing',
            icon: Icons.sports_baseball,
            tag: 'COMING NEXT',
          ),
          const SizedBox(height: 24),
          const _SectionTitle(
              title: 'MULTIPLAYER', subtitle: 'Play with a room code'),
          const SizedBox(height: 12),
          const _ComingSoonPanel(),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        ],
      );
}

class _GameTile extends StatelessWidget {
  const _GameTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tag,
    this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final String tag;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xFF1A1C22),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB547).withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: const Color(0xFFFFB547)),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(subtitle,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(tag,
                    style: TextStyle(
                        color: onTap == null
                            ? Colors.white38
                            : const Color(0xFFFFC36C),
                        fontSize: 9,
                        fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ),
      );
}

class _ComingSoonPanel extends StatelessWidget {
  const _ComingSoonPanel();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1C22),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white12),
        ),
        child: const Row(
          children: [
            Icon(Icons.people_alt_outlined,
                size: 30, color: Color(0xFFFFB547)),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                'Create a private room or join friends with a code. Online lobby UI is being connected to the new server.',
                style: TextStyle(color: Colors.white70, height: 1.4),
              ),
            ),
          ],
        ),
      );
}

class TicTacToeScreen extends StatefulWidget {
  const TicTacToeScreen({super.key});

  @override
  State<TicTacToeScreen> createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends State<TicTacToeScreen> {
  List<String?> board = List.filled(9, null);
  String turn = 'X';
  String? winner;
  bool draw = false;

  void play(int index) {
    if (board[index] != null || winner != null || draw) return;
    setState(() {
      board[index] = turn;
      const lines = [
        [0, 1, 2],
        [3, 4, 5],
        [6, 7, 8],
        [0, 3, 6],
        [1, 4, 7],
        [2, 5, 8],
        [0, 4, 8],
        [2, 4, 6],
      ];
      for (final line in lines) {
        final mark = board[line[0]];
        if (mark != null &&
            mark == board[line[1]] &&
            mark == board[line[2]]) {
          winner = mark;
          break;
        }
      }
      if (winner == null && board.every((cell) => cell != null)) draw = true;
      if (winner == null && !draw) turn = turn == 'X' ? 'O' : 'X';
    });
  }

  void reset() {
    setState(() {
      board = List.filled(9, null);
      turn = 'X';
      winner = null;
      draw = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = winner != null
        ? 'Player $winner wins'
        : draw
            ? 'It’s a draw'
            : 'Player $turn’s turn';
    return Scaffold(
      appBar: AppBar(title: const Text('TIC TAC TOE')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(status,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 24),
              AspectRatio(
                aspectRatio: 1,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 9,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 9,
                    mainAxisSpacing: 9,
                  ),
                  itemBuilder: (context, index) => Material(
                    color: const Color(0xFF20232A),
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => play(index),
                      child: Center(
                        child: Text(
                          board[index] ?? '',
                          style: TextStyle(
                            fontSize: 54,
                            fontWeight: FontWeight.w900,
                            color: board[index] == 'X'
                                ? const Color(0xFFFFB547)
                                : const Color(0xFF8EC5FF),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: reset,
                icon: const Icon(Icons.refresh),
                label: const Text('NEW ROUND'),
              ),
              const SizedBox(height: 8),
              const Text('Local two-player mode',
                  style: TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      ),
    );
  }
}

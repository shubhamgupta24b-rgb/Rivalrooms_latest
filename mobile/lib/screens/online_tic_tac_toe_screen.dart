import 'package:flutter/material.dart';
import '../services/room_socket.dart';

class OnlineTicTacToeScreen extends StatefulWidget {
  const OnlineTicTacToeScreen({super.key, required this.socket, required this.playerId, required this.initialGame});
  final RoomSocket socket;
  final String playerId;
  final Map<String, dynamic> initialGame;
  @override
  State<OnlineTicTacToeScreen> createState() => _OnlineTicTacToeScreenState();
}

class _OnlineTicTacToeScreenState extends State<OnlineTicTacToeScreen> {
  late Map<String, dynamic> game;
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    game = widget.initialGame;
    widget.socket.onGameState = (state) { if (mounted) setState(() { game = state; error = null; }); };
  }
  Future<void> _move(int index) async {
    if (busy || game['status'] != 'playing' || game['turn'] != widget.playerId) return;
    setState(() { busy = true; error = null; });
    try {
      final next = await widget.socket.moveTicTacToe(index, game['version'] as int);
      if (mounted) setState(() => game = next);
    } catch (e) { if (mounted) setState(() => error = e.toString()); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) {
    final board = (game['board'] as List).cast<String?>();
    final players = (game['players'] as List).cast<String>();
    final mark = players.indexOf(widget.playerId) == 0 ? 'X' : 'O';
    final status = game['status'] == 'finished'
        ? (game['winner'] == widget.playerId ? 'You won' : 'You lost')
        : game['status'] == 'draw' ? 'Draw'
        : game['turn'] == widget.playerId ? 'Your turn (' + mark + ')' : 'Opponent’s turn';
    return Scaffold(
      appBar: AppBar(title: const Text('ONLINE TIC TAC TOE')),
      body: Center(child: Padding(padding: const EdgeInsets.all(22), child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(status, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text('Match version ' + game['version'].toString(), style: const TextStyle(color: Colors.white54)),
          if (error != null) Padding(padding: const EdgeInsets.all(8), child: Text(error!, style: const TextStyle(color: Colors.redAccent))),
          const SizedBox(height: 20),
          AspectRatio(aspectRatio: 1, child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(), itemCount: 9,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 9, mainAxisSpacing: 9),
            itemBuilder: (context, index) => Material(
              color: const Color(0xFF20232A), borderRadius: BorderRadius.circular(16),
              child: InkWell(onTap: () => _move(index), borderRadius: BorderRadius.circular(16),
                child: Center(child: Text(board[index] ?? '', style: TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: board[index] == 'X' ? const Color(0xFFFFB547) : const Color(0xFF8EC5FF)))),
            ),
          )),
          const SizedBox(height: 18),
          if (busy) const CircularProgressIndicator(),
          if (game['status'] != 'playing') const Text('Match complete. Leaderboard results require database connectivity.', style: TextStyle(color: Colors.white54), textAlign: TextAlign.center),
        ],
      ))),
    );
  }
}

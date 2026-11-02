import 'package:flutter/material.dart';
import '../services/api_client.dart';

class OnlineLobbyScreen extends StatefulWidget {
  const OnlineLobbyScreen({super.key});
  @override
  State<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends State<OnlineLobbyScreen> {
  final _name = TextEditingController();
  final _code = TextEditingController();
  final _api = RivalRoomsApi();
  bool _busy = false;
  String? _message;
  Map<String, dynamic>? _room;

  Future<void> _run(Future<Map<String, dynamic>> Function() action) async {
    if (_busy) return;
    setState(() { _busy = true; _message = null; });
    try {
      if (_name.text.trim().isEmpty) throw const ApiException('Enter a display name first.');
      await _api.createOrRestoreGuest(_name.text.trim());
      final room = await action();
      if (!mounted) return;
      setState(() { _room = room; _message = 'Room ready. Share code ${room['code']}'; });
    } catch (error) {
      if (mounted) setState(() => _message = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _name.dispose(); _code.dispose(); _api.close(); super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ONLINE LOBBY')),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const Text('Play with friends', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('Create a private room or join one using a code.',
              style: TextStyle(color: Colors.white60)),
          const SizedBox(height: 24),
          TextField(controller: _name, maxLength: 24,
            decoration: const InputDecoration(labelText: 'Display name', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : () => _run(() => _api.createRoom(gameId: 'tic_tac_toe', maxMembers: 2)),
            icon: const Icon(Icons.add_circle_outline), label: const Text('CREATE TIC TAC TOE ROOM')),
          const SizedBox(height: 22),
          const Center(child: Text('OR JOIN WITH CODE', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold))),
          const SizedBox(height: 12),
          TextField(controller: _code, textCapitalization: TextCapitalization.characters,
            maxLength: 6, decoration: const InputDecoration(labelText: '6-character room code', border: OutlineInputBorder())),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _run(() => _api.joinRoom(_code.text)),
            icon: const Icon(Icons.login), label: const Text('JOIN ROOM')),
          if (_busy) const Padding(padding: EdgeInsets.all(18), child: Center(child: CircularProgressIndicator())),
          if (_message != null) ...[
            const SizedBox(height: 18),
            Container(padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF20232A), borderRadius: BorderRadius.circular(14)),
              child: Text(_message!, style: const TextStyle(height: 1.4))),
          ],
          if (_room != null) ...[
            const SizedBox(height: 18),
            Text('ROOM ${_room!['code']}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2)),
            Text('${(_room!['members'] as List).length} / ${_room!['maxMembers']} players'),
            const SizedBox(height: 8),
            const Text('Room creation and joining are connected. Live lobby presence and ready controls are the next integration step.',
                style: TextStyle(color: Colors.white60)),
          ],
        ],
      ),
    );
  }
}

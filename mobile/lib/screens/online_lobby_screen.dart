import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/room_socket.dart';

class OnlineLobbyScreen extends StatefulWidget {
  const OnlineLobbyScreen({super.key});
  @override
  State<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends State<OnlineLobbyScreen> {
  final _name = TextEditingController();
  final _code = TextEditingController();
  final _api = RivalRoomsApi();
  RoomSocket? _socket;
  bool _busy = false;
  bool _ready = false;
  String? _message;
  Map<String, dynamic>? _room;
  String? _playerId;

  Future<void> _run(Future<Map<String, dynamic>> Function() action) async {
    if (_busy) return;
    setState(() { _busy = true; _message = null; });
    try {
      if (_name.text.trim().isEmpty) {
        throw const ApiException('Enter a display name first.');
      }
      final player = await _api.createOrRestoreGuest(_name.text.trim());
      final room = await action();
      final token = await _api.sessionToken();
      final socket = RoomSocket();
      await socket.connect(token);
      final joined = await socket.joinRoom(room['id'] as String);
      socket.onRoomUpdated = (updated) {
        if (mounted) setState(() => _room = updated);
      };
      if (!mounted) {
        socket.close();
        return;
      }
      setState(() {
        _playerId = player['playerId'] as String?;
        _room = joined;
        _socket = socket;
        _ready = _isReady(joined);
        _message = 'Live connection established. Share code ${room['code']}.';
      });
    } catch (error) {
      if (mounted) setState(() => _message = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool _isReady(Map<String, dynamic> room) {
    final members = room['members'] as List? ?? const [];
    final me = members.whereType<Map>().cast<Map<String, dynamic>>()
        .where((member) => member['playerId'] == _playerId);
    return me.isNotEmpty && me.first['ready'] == true;
  }

  Future<void> _setReady(bool value) async {
    final socket = _socket;
    if (socket == null) return;
    try {
      final updated = await socket.setReady(value);
      if (mounted) setState(() { _ready = value; _room = updated; });
    } catch (error) {
      if (mounted) setState(() => _message = error.toString());
    }
  }

  Future<void> _startRoom() async {
    final socket = _socket;
    if (socket == null) return;
    try {
      final updated = await socket.startRoom();
      if (mounted) setState(() {
        _room = updated;
        _message = 'Room started. The online game screen is the next integration step.';
      });
    } catch (error) {
      if (mounted) setState(() => _message = error.toString());
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _socket?.close();
    _api.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = _room;
    final members = room?['members'] as List? ?? const [];
    final isHost = members.whereType<Map>().any((member) =>
        member['playerId'] == _playerId && member['isHost'] == true);
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
          if (room != null) ...[
            const SizedBox(height: 18),
            Text('ROOM ${room['code']}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2)),
            Text('${members.length} / ${room['maxMembers']} players • ${room['status']}'),
            const SizedBox(height: 12),
            for (final member in members.whereType<Map>())
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(member['connected'] == true ? Icons.circle : Icons.circle_outlined,
                    color: member['connected'] == true ? Colors.greenAccent : Colors.white38, size: 14),
                title: Text(member['displayName']?.toString() ?? 'Player'),
                subtitle: Text(member['isHost'] == true ? 'Host' : 'Player'),
                trailing: Text(member['ready'] == true ? 'READY' : 'NOT READY',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            if (room['status'] == 'waiting' && !isHost)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('I am ready'),
                value: _ready,
                onChanged: _setReady,
              ),
            if (room['status'] == 'waiting' && isHost)
              FilledButton.icon(
                onPressed: members.length >= 2 ? _startRoom : null,
                icon: const Icon(Icons.play_arrow),
                label: const Text('START MATCH'),
              ),
            if (room['status'] == 'playing')
              const Text('Match started. Waiting for the game view.',
                  style: TextStyle(color: Colors.white70)),
          ],
        ],
      ),
    );
  }
}

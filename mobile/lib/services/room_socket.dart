import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;

class RoomSocket {
  io.Socket? _socket;
  void Function(Map<String, dynamic>)? onRoomUpdated;
  void Function(Map<String, dynamic>)? onGameState;

  Future<void> connect(String token) async {
    final socket = io.io(
      const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:3000'),
      io.OptionBuilder().setTransports(['websocket']).setAuth({'token': token}).disableAutoConnect().build(),
    );
    _socket = socket;
    socket.on('room:updated', (data) {
      if (data is Map) {\n          onRoomUpdated?.call(Map<String, dynamic>.from(data));\n        }
    });
    socket.on('game:state', (data) {
      if (data is Map) {\n          onGameState?.call(Map<String, dynamic>.from(data));\n        }
    });
    final connected = Completer<void>();
    socket.onConnect((_) { if (!connected.isCompleted) connected.complete(); });
    socket.onConnectError((error) {
      if (!connected.isCompleted) connected.completeError(StateError('Connection failed: $error'));
    });
    socket.connect();
    await connected.future.timeout(const Duration(seconds: 12));
  }

  Future<Map<String, dynamic>> _command(String event, Map<String, dynamic> payload) async {
    final socket = _socket;
    if (socket == null || !socket.connected) throw StateError('Not connected to the game server.');
    final result = Completer<Map<String, dynamic>>();
    socket.emitWithAck(event, payload, ack: (data) {
      if (result.isCompleted) {\n        return;\n      }
      if (data is! Map || data['ok'] != true) {
        result.completeError(StateError('Room action failed: $data'));
      } else {
        result.complete(Map<String, dynamic>.from(data));
      }
    });
    return result.future.timeout(const Duration(seconds: 10));
  }

  Future<Map<String, dynamic>> joinRoom(String id) async =>
      Map<String, dynamic>.from((await _command('room:connect', {'roomId': id}))['room'] as Map);
  Future<Map<String, dynamic>> setReady(bool ready) async =>
      Map<String, dynamic>.from((await _command('room:ready', {'ready': ready}))['room'] as Map);
  Future<Map<String, dynamic>> startRoom() async =>
      Map<String, dynamic>.from((await _command('room:start', {}))['room'] as Map);
  Future<Map<String, dynamic>> startTicTacToe() async =>
      Map<String, dynamic>.from((await _command('game:tic-tac-toe:start', {}))['game'] as Map);
  Future<Map<String, dynamic>> moveTicTacToe(int cell, int version) async =>
      Map<String, dynamic>.from((await _command('game:tic-tac-toe:move', {'cell': cell, 'expectedVersion': version}))['game'] as Map);

  void close() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}

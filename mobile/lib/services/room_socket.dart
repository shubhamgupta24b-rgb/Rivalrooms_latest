import 'package:socket_io_client/socket_io_client.dart' as io;

class RoomSocket {
  io.Socket? socket;
  void connect(String token) {
    socket = io.io(const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:3000'), io.OptionBuilder().setTransports(['websocket']).setAuth({'token': token}).disableAutoConnect().build());
    socket!.connect();
  }
  void close() { socket?.disconnect(); socket?.dispose(); }
}

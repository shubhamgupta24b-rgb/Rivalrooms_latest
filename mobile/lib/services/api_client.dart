import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RivalRoomsApi {
  RivalRoomsApi({http.Client? client})
      : _client = client ?? http.Client(),
        baseUrl = const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'http://10.0.2.2:3000',
        );

  final http.Client _client;
  final String baseUrl;
  static const _tokenKey = 'rr_session_token';
  static const _playerIdKey = 'rr_player_id';

  Future<Map<String, dynamic>> createOrRestoreGuest(String displayName) async {
    final prefs = await SharedPreferences.getInstance();
    var deviceId = prefs.getString(_playerIdKey);
    deviceId ??= 'rr_${DateTime.now().microsecondsSinceEpoch}_${DateTime.now().millisecond}';
    await prefs.setString(_playerIdKey, deviceId);
    final response = await _client.post(
      Uri.parse('$baseUrl/v1/sessions'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'deviceId': deviceId, 'displayName': displayName}),
    );
    final body = _decode(response);
    final token = body['token'];
    if (response.statusCode != 201 || token is! String) {
      throw ApiException(_message(body, 'Could not create player session.'));
    }
    await prefs.setString(_tokenKey, token);
    return Map<String, dynamic>.from(body['player'] as Map);
  }

  Future<String> sessionToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null) {\n      throw const ApiException('Create a player session first.');\n    }
    return token;
  }

  Future<Map<String, dynamic>> createRoom({required String gameId, int maxMembers = 2}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/v1/rooms'),
      headers: await _headers(),
      body: jsonEncode({'gameId': gameId, 'maxMembers': maxMembers}),
    );
    return _roomResponse(response);
  }

  Future<Map<String, dynamic>> joinRoom(String code) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/v1/rooms/join'),
      headers: await _headers(),
      body: jsonEncode({'code': code}),
    );
    return _roomResponse(response);
  }

  Future<Map<String, String>> _headers() async {
    final token = await sessionToken();
    return {'content-type': 'application/json', 'authorization': 'Bearer $token'};
  }

  Map<String, dynamic> _roomResponse(http.Response response) {
    final body = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_message(body, 'Room request failed.'));
    }
    return Map<String, dynamic>.from(body['room'] as Map);
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      final value = jsonDecode(response.body);
      return value is Map<String, dynamic> ? value : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  String _message(Map<String, dynamic> body, String fallback) {
    final error = body['error'];
    if (error is Map && error['message'] is String) {\n      return error['message'] as String;\n    }
    return fallback;
  }

  void close() => _client.close();
}

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

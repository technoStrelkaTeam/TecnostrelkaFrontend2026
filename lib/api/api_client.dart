import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models.dart';

class ApiConfig {
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String defaultBaseUrl() {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }
    return 'http://127.0.0.1:8000';
  }
}

class ApiClient {
  ApiClient({String? baseUrl}) : _baseUrl = baseUrl ?? ApiConfig.defaultBaseUrl();

  final String _baseUrl;
  String? _token;

  void updateToken(String? token) {
    _token = token;
  }

  Future<AuthResult> register(String name, String email, String password) async {
    await _post(
      '/users/register',
      body: {
        'name': name,
        'username': email,
        'email': email,
        'password': password,
      },
    );
    final token = await _requestToken(email, password);
    final user = await _fetchMe(token: token);
    return AuthResult(token: token, user: user);
  }

  Future<AuthResult> login(String email, String password) async {
    final token = await _requestToken(email, password);
    final user = await _fetchMe(token: token);
    return AuthResult(token: token, user: user);
  }

  Future<String> _requestToken(String username, String password) async {
    final uri = Uri.parse('$_baseUrl/users/token');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': username, 'password': password},
    );
    final json = _decode(response);
    final token = json['access_token'];
    if (token == null) {
      throw ApiException('Token not returned by server');
    }
    return token as String;
  }

  Future<UserProfile> _fetchMe({required String token}) async {
    final uri = Uri.parse('$_baseUrl/users/me');
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final json = _decode(response);
    return UserProfile.fromJson(json);
  }

  Future<UserProfile> getUserByEmail(String email) async {
    final uri = Uri.parse('$_baseUrl/users/getByEmail/$email');
    final response = await http.get(
      uri,
      headers: _headers(),
    );
    final json = _decode(response);
    return UserProfile.fromJson(json);
  }

  Future<Map<String, dynamic>> importFromImap(String login, String password) async {
    final uri = Uri.parse('$_baseUrl/users/import-from-imap');
    final response = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode({'login': login, 'password': password}),
    );
    final json = _decode(response);
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    return <String, dynamic>{};
  }

  Future<http.Response> _post(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = _headers();
    return http.post(uri, headers: headers, body: jsonEncode(body ?? {}));
  }

  Map<String, String> _headers() {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      json = <String, dynamic>{};
    }
    if (response.statusCode >= 400) {
      final message =
          json['detail']?.toString() ??
          json['error']?.toString() ??
          'Request failed (HTTP ${response.statusCode})';
      throw ApiException(message);
    }
    return json;
  }
}

class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
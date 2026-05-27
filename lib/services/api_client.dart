import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class ApiClientException implements Exception {
  final String message;
  final int? statusCode;

  const ApiClientException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  final String _baseUrl;
  final AuthService _authService;
  final http.Client _client;

  String get baseUrl => _baseUrl;

  ApiClient({
    String? baseUrlOverride,
    AuthService? authService,
    http.Client? client,
  })  : _baseUrl = resolveBaseUrl(baseUrlOverride: baseUrlOverride),
        _authService = authService ?? AuthService(baseUrlOverride: baseUrlOverride),
        _client = client ?? http.Client();

  static String resolveBaseUrl({String? baseUrlOverride}) {
    return AuthService.resolveBaseUrl(baseUrlOverride: baseUrlOverride);
  }

  Future<Map<String, dynamic>> get(String path, {bool authenticated = false}) {
    return _send(
      authenticated: authenticated,
      request: (headers) => _client.get(_uri(path), headers: headers),
    );
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) {
    return _send(
      authenticated: authenticated,
      request: (headers) => _client.post(
        _uri(path),
        headers: headers,
        body: jsonEncode(body ?? {}),
      ),
    );
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) {
    return _send(
      authenticated: authenticated,
      request: (headers) => _client.patch(
        _uri(path),
        headers: headers,
        body: jsonEncode(body ?? {}),
      ),
    );
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) {
    return _send(
      authenticated: authenticated,
      request: (headers) => _client.put(
        _uri(path),
        headers: headers,
        body: jsonEncode(body ?? {}),
      ),
    );
  }

  Future<Map<String, dynamic>> _send({
    required bool authenticated,
    required Future<http.Response> Function(Map<String, String> headers) request,
  }) async {
    var response = await request(await _headers(authenticated: authenticated));

    if (authenticated && response.statusCode == 401) {
      try {
        await _authService.refreshAccessToken();
        response = await request(await _headers(authenticated: true));
      } catch (_) {
        await _authService.clearSession();
        throw const ApiClientException('Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại', statusCode: 401);
      }
    }

    return _decodeResponse(response);
  }

  Uri _uri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_baseUrl$normalizedPath');
  }

  Future<Map<String, String>> _headers({required bool authenticated}) async {
    final headers = {'content-type': 'application/json'};
    if (authenticated) {
      headers['authorization'] = 'Bearer ${await _authService.requireAccessToken()}';
    }
    return headers;
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiClientException('Phản hồi server không hợp lệ', statusCode: response.statusCode);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiClientException(
        body['error']?.toString() ?? 'Lỗi server: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    return body;
  }
}

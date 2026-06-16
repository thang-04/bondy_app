import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/bondy_error_mapper.dart';
import 'auth_service.dart';

class ApiClientException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  final Map<String, dynamic>? data;

  const ApiClientException(
    this.message, {
    this.statusCode,
    this.code,
    this.data,
  });

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
  }) : _baseUrl = resolveBaseUrl(baseUrlOverride: baseUrlOverride),
       _authService =
           authService ?? AuthService(baseUrlOverride: baseUrlOverride),
       _client = client ?? http.Client();

  static String resolveBaseUrl({String? baseUrlOverride}) {
    return AuthService.resolveBaseUrl(baseUrlOverride: baseUrlOverride);
  }

  Future<Map<String, dynamic>> get(
    String path, {
    bool authenticated = false,
    Map<String, dynamic>? queryParams,
  }) {
    return _send(
      authenticated: authenticated,
      request: (headers) =>
          _client.get(_uri(path, queryParams: queryParams), headers: headers),
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

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) {
    return _send(
      authenticated: authenticated,
      request: (headers) => _client.delete(
        _uri(path),
        headers: headers,
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  Future<Map<String, dynamic>> _send({
    required bool authenticated,
    required Future<http.Response> Function(Map<String, String> headers)
    request,
  }) async {
    try {
      var response = await request(
        await _headers(authenticated: authenticated),
      ).timeout(const Duration(seconds: 15));

      if (authenticated && response.statusCode == 401) {
        try {
          await _authService.refreshAccessToken();
          response = await request(await _headers(authenticated: true));
        } catch (_) {
          await _authService.clearSession();
          throw const ApiClientException(
            'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại',
            statusCode: 401,
            code: 'UNAUTHORIZED',
          );
        }
      }

      return _decodeResponse(response);
    } on ApiClientException {
      rethrow;
    } on AuthRequiredException {
      rethrow;
    } on SessionExpiredException {
      rethrow;
    } on SocketException {
      throw const ApiClientException(
        'Không có kết nối mạng. Vui lòng kiểm tra Internet.',
      );
    } on TimeoutException {
      throw const ApiClientException(
        'Kết nối quá lâu. Kiểm tra mạng và thử lại.',
      );
    } on http.ClientException {
      throw const ApiClientException(
        'Không kết nối được máy chủ. Kiểm tra mạng hoặc địa chỉ API.',
      );
    } catch (e) {
      throw ApiClientException(BondyErrorMapper.message(e));
    }
  }

  Uri _uri(String path, {Map<String, dynamic>? queryParams}) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$_baseUrl$normalizedPath');
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(
        queryParameters: queryParams.map((k, v) => MapEntry(k, v.toString())),
      );
    }
    return uri;
  }

  Future<Map<String, String>> _headers({required bool authenticated}) async {
    final headers = {'content-type': 'application/json'};
    if (authenticated) {
      headers['authorization'] =
          'Bearer ${await _authService.requireAccessToken()}';
    }
    return headers;
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiClientException(
        'Phản hồi server không hợp lệ',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errorCode = body['code']?.toString();
      final serverMessage =
          body['error']?.toString() ??
          body['message']?.toString() ??
          _statusFallback(response.statusCode);
      final responseData = body['data'] is Map<String, dynamic>
          ? body['data'] as Map<String, dynamic>
          : null;
      throw ApiClientException(
        serverMessage,
        statusCode: response.statusCode,
        code: errorCode,
        data: responseData,
      );
    }

    return body;
  }

  static String _statusFallback(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Yêu cầu không hợp lệ.';
      case 401:
        return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      case 403:
        return 'Bạn không có quyền thực hiện thao tác này.';
      case 404:
        return 'Không tìm thấy dữ liệu.';
      case 409:
        return 'Dữ liệu đã tồn tại hoặc xung đột.';
      case 429:
        return 'Bạn thao tác quá nhanh. Vui lòng đợi một lát.';
      default:
        if (statusCode >= 500) return 'Máy chủ đang bận. Vui lòng thử lại sau.';
        return 'Đã xảy ra lỗi. Vui lòng thử lại.';
    }
  }
}

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:http/http.dart' as http_client;

import '../core/image_converter.dart';
import '../core/mime_detector.dart';
import '../models/user_profile_model.dart';
import './api_client.dart';
import './auth_service.dart';

class ProfileService {
  final ApiClient _apiClient;
  late final Dio _dio;

  ProfileService({ApiClient? apiClient, Dio? dio})
    : _apiClient = apiClient ?? ApiClient() {
    _dio = dio ?? Dio(BaseOptions(baseUrl: _apiClient.baseUrl));
  }

  Future<Options> _authOptions() async {
    final token = await AuthService().getToken();
    return Options(
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );
  }

  Future<UserProfileModel> getProfile() async {
    try {
      final body = await _apiClient.get('/profile/me', authenticated: true);
      if (body['success'] == true && body['data'] != null) {
        return UserProfileModel.fromJson(body['data'] as Map<String, dynamic>);
      }
      throw Exception(body['error'] ?? 'Không thể tải hồ sơ');
    } catch (e) {
      debugPrint('Get profile error: $e');
      rethrow;
    }
  }

  Future<String?> uploadImage(XFile file) => uploadMediaFile(file);

  Future<String?> uploadMediaFile(XFile file) async {
    try {
      final rawBytes = await file.readAsBytes();

      // 1. Nhận diện MIME type ban đầu từ magic bytes hoặc extension
      final detected = MimeDetector.detect(rawBytes);
      String initialFileName = file.name;
      final String initialMimeType;

      if (MimeDetector.hasValidExtension(initialFileName)) {
        final ext = initialFileName.split('.').last.toLowerCase();
        if (ext == 'png') {
          initialMimeType = 'image/png';
        } else if (ext == 'webp') {
          initialMimeType = 'image/webp';
        } else if (ext == 'gif') {
          initialMimeType = 'image/gif';
        } else if (ext == 'jpg' || ext == 'jpeg') {
          initialMimeType = 'image/jpeg';
        } else if (ext == 'm4a') {
          initialMimeType = 'audio/m4a';
        } else if (ext == 'mp3') {
          initialMimeType = 'audio/mpeg';
        } else if (ext == 'aac') {
          initialMimeType = 'audio/aac';
        } else if (ext == 'webm') {
          initialMimeType = 'audio/webm';
        } else if (ext == 'ogg') {
          initialMimeType = 'audio/ogg';
        } else {
          initialMimeType = detected.mimeType;
        }
      } else {
        initialMimeType = detected.mimeType;
        initialFileName = MimeDetector.ensureExtension(
          initialFileName,
          detected.extension,
        );
      }

      // 2. Chuyển đổi định dạng ảnh nếu chạy trên Web (ví dụ HEIC -> JPEG)
      final converted = await convertImageIfNeed(
        bytes: rawBytes,
        fileName: initialFileName,
        mimeType: initialMimeType,
      );

      final bytes = converted.bytes;
      final fileName = converted.fileName;
      final mimeType = converted.mimeType;

      final token = await AuthService().getToken();
      final uri = Uri.parse('${_apiClient.baseUrl}/upload');
      final request = http_client.MultipartRequest('POST', uri);
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.files.add(
        http_client.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http_client.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          final url = responseData['data']['url'];
          debugPrint('[IMG-DBG] upload returned URL: $url');
          return url;
        }
      }
      debugPrint(
        '[IMG-DBG] upload failed: ${response.statusCode} ${response.body}',
      );
      return null;
    } catch (e) {
      debugPrint('Upload media error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? bio,
    String? gender,
    String? city,
    String? datingGoal,
    Object? birthDate,
    List<String>? photos,
  }) async {
    final data = <String, dynamic>{};
    if (fullName != null) data['fullName'] = fullName;
    if (bio != null) data['bio'] = bio;
    if (gender != null) data['gender'] = gender;
    if (city != null) data['city'] = city;
    if (datingGoal != null) data['datingGoal'] = datingGoal;
    if (birthDate is DateTime)
      data['birthDate'] = birthDate.toIso8601String().split('T')[0];
    if (birthDate is String) data['birthDate'] = birthDate;
    if (photos != null) data['photos'] = photos;

    final body = await _apiClient.patch(
      '/profile/me',
      body: data,
      authenticated: true,
    );

    return (body['data'] as Map<String, dynamic>?) ?? body;
  }

  Future<Map<String, dynamic>> updateLocation({
    String? city,
    required double latitude,
    required double longitude,
  }) async {
    final data = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
    };
    if (city != null) data['city'] = city;

    final body = await _apiClient.patch(
      '/profile/location',
      body: data,
      authenticated: true,
    );

    return (body['data'] as Map<String, dynamic>?) ?? body;
  }

  Future<List<Map<String, dynamic>>> getInterests() async {
    final body = await _apiClient.get('/interests');
    final data = body['data'];
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return const [];
  }

  /// Trả về danh sách interest ID mà user đã chọn
  Future<List<String>> getUserInterests() async {
    final body = await _apiClient.get(
      '/profile/interests',
      authenticated: true,
    );
    final data = body['data'];
    if (data is List) {
      return data.map((e) => e.toString()).toList();
    }
    return const [];
  }

  Future<void> saveInterests(List<String> interestIds) async {
    await _apiClient.put(
      '/profile/interests',
      body: {'interestIds': interestIds},
      authenticated: true,
    );
  }

  Future<Map<String, dynamic>> getProfileStats() async {
    final body = await _apiClient.get('/profile/stats', authenticated: true);
    return (body['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> updateVisibility({required bool hidden}) async {
    final body = await _apiClient.patch(
      '/profile/visibility',
      body: {'isVisible': !hidden},
      authenticated: true,
    );
    return (body['data'] as Map<String, dynamic>?) ?? body;
  }

  Future<void> deleteAccount({required String password}) async {
    final body = await _apiClient.post(
      '/profile/delete',
      body: {'password': password},
      authenticated: true,
    );
    if (body['success'] != true) {
      throw Exception(body['error']?.toString() ?? 'Xóa tài khoản thất bại');
    }
    await AuthService().clearSession();
  }

  // ── Snooze (pause discovery) ────────────────────────────────────────────
  Future<SnoozeStatus> getSnoozeStatus() async {
    final body = await _apiClient.get('/profile/snooze', authenticated: true);
    final data = body['data'] as Map<String, dynamic>? ?? const {};
    return SnoozeStatus.fromJson(data);
  }

  /// [duration] is one of `24h`, `72h`, `7d`, `30d`, or `null` to un-snooze.
  Future<SnoozeStatus> setSnooze({String? duration}) async {
    final body = await _apiClient.post(
      '/profile/snooze',
      body: {'until': duration},
      authenticated: true,
    );
    final data = body['data'] as Map<String, dynamic>? ?? const {};
    return SnoozeStatus.fromJson(data);
  }

  // ── Notification preferences ────────────────────────────────────────────
  Future<Map<String, dynamic>> getNotificationPrefs() async {
    final body = await _apiClient.get(
      '/profile/notification-prefs',
      authenticated: true,
    );
    return (body['data'] as Map<String, dynamic>?) ?? const {};
  }

  Future<Map<String, dynamic>> updateNotificationPrefs(
    Map<String, Map<String, bool>> partial,
  ) async {
    final body = await _apiClient.put(
      '/profile/notification-prefs',
      body: partial,
      authenticated: true,
    );
    return (body['data'] as Map<String, dynamic>?) ?? const {};
  }

  Future<Map<String, dynamic>> saveDeepMatch({
    String? zodiacSign,
    List<String>? zodiacPreferences,
    List<String>? freeTimeSlots,
    String? desiredPartnerType,
  }) async {
    final data = <String, dynamic>{};
    if (zodiacSign != null) data['zodiacSign'] = zodiacSign;
    if (zodiacPreferences != null)
      data['zodiacPreferences'] = zodiacPreferences;
    if (freeTimeSlots != null) data['freeTimeSlots'] = freeTimeSlots;
    if (desiredPartnerType != null)
      data['desiredPartnerType'] = desiredPartnerType;

    final body = await _apiClient.put(
      '/profile/deep-match',
      body: data,
      authenticated: true,
    );

    return (body['data'] as Map<String, dynamic>?) ?? body;
  }
}

class SnoozeStatus {
  final DateTime? snoozedUntil;
  final bool isSnoozed;

  const SnoozeStatus({this.snoozedUntil, required this.isSnoozed});

  factory SnoozeStatus.fromJson(Map<String, dynamic> json) {
    final raw = json['snoozedUntil'];
    DateTime? until;
    if (raw is String && raw.isNotEmpty) {
      until = DateTime.tryParse(raw);
    }
    return SnoozeStatus(
      snoozedUntil: until,
      isSnoozed: json['isSnoozed'] == true,
    );
  }
}

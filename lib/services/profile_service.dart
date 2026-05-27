import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

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

  Future<String?> uploadImage(XFile file) async {
    try {
      final fileName = file.name;
      final bytes = await file.readAsBytes();

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      });

      final response = await _dio.post(
        '/upload',
        data: formData,
        options: await _authOptions(),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data']['url'];
      }
      return null;
    } catch (e) {
      debugPrint('Upload image error: $e');
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
    if (birthDate is DateTime) data['birthDate'] = birthDate.toIso8601String().split('T')[0];
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
    required String city,
    required double latitude,
    required double longitude,
  }) async {
    final body = await _apiClient.patch(
      '/profile/location',
      body: {
        'city': city,
        'latitude': latitude,
        'longitude': longitude,
      },
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

  Future<void> saveInterests(List<String> interestIds) async {
    await _apiClient.put(
      '/profile/interests',
      body: {'interestIds': interestIds},
      authenticated: true,
    );
  }
}

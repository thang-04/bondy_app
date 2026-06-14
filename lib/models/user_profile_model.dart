import 'package:flutter/foundation.dart';
import '../core/media_url.dart';

/// Model ánh xạ response từ GET /api/profile/me
/// Response shape: { success: true, data: { id, name, email, image, phone, profile: {...} } }
class UserProfileModel {
  // ── User fields ────────────────────────────────────────────────────────────
  final String id;
  final String? name;
  final String email;
  final String? image;
  final String? phone;

  // ── Profile fields (nullable khi profile chưa được tạo) ───────────────────
  final String? fullName;
  final String? gender;
  final DateTime? birthDate;
  final String? city;
  final String? bio;
  final String? datingGoal;
  final List<String> photos;
  final bool isHidden;

  // DeepMatch fields
  final String? zodiacSign;
  final List<String> zodiacPreferences;
  final int? lifePathNumber;
  final List<String> freeTimeSlots;
  final String? desiredPartnerType;

  const UserProfileModel({
    required this.id,
    required this.email,
    this.name,
    this.image,
    this.phone,
    this.fullName,
    this.gender,
    this.birthDate,
    this.city,
    this.bio,
    this.datingGoal,
    this.photos = const [],
    this.isHidden = false,
    this.zodiacSign,
    this.zodiacPreferences = const [],
    this.lifePathNumber,
    this.freeTimeSlots = const [],
    this.desiredPartnerType,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    // Server trả về Prisma Profile với user nested:
    // { id (profile id), userId, fullName, gender, ..., user: { id, email, name, image } }
    // Cũng hỗ trợ format cũ: { id (user id), email, name, image, profile: { fullName, ... } }
    final userNode = json['user'] as Map<String, dynamic>?;
    final legacyProfile = json['profile'] as Map<String, dynamic>?;

    // Xác định profile fields từ top-level (server mới) hoặc nested 'profile' (format cũ)
    final profileFields = legacyProfile ?? json;

    // Parse photos: server trả về List<dynamic>. Rewrite host trong từng URL
    // để máy thật reach được ảnh đã upload từ emulator (vốn lưu URL 10.0.2.2).
    List<String> parsePhotos(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) {
        final result = raw.map((e) {
          final original = e.toString();
          final rewritten = rewriteMediaUrl(original) ?? original;
          if (original != rewritten) {
            debugPrint('[IMG-DBG] rewrite: $original -> $rewritten');
          }
          return rewritten;
        }).toList();
        debugPrint('[IMG-DBG] photos after parse: $result');
        return result;
      }
      return [];
    }

    // User identity: ưu tiên user.id (server mới) → userId field → json['id']
    final userId =
        userNode?['id']?.toString() ??
        json['userId']?.toString() ??
        json['id']?.toString() ??
        '';

    // isVisible từ server, isHidden = !isVisible
    final isVisible = profileFields['isVisible'] as bool?;
    final isHiddenLegacy = profileFields['isHidden'] as bool?;
    final isHidden = isHiddenLegacy ?? (isVisible != null ? !isVisible : false);

    return UserProfileModel(
      id: userId,
      email: userNode?['email']?.toString() ?? json['email']?.toString() ?? '',
      name: userNode?['name']?.toString() ?? json['name']?.toString(),
      image: () {
        final rawImg =
            userNode?['image']?.toString() ?? json['image']?.toString();
        final rewrittenImg = rewriteMediaUrl(rawImg);
        debugPrint('[IMG-DBG] user.image raw=$rawImg rewritten=$rewrittenImg');
        return rewrittenImg;
      }(),
      phone: json['phone']?.toString(),
      // Profile fields (top-level trên server mới, nested trên format cũ)
      fullName: profileFields['fullName']?.toString(),
      gender: profileFields['gender']?.toString(),
      birthDate: profileFields['birthDate'] != null
          ? DateTime.tryParse(profileFields['birthDate'].toString())
          : null,
      city: profileFields['city']?.toString(),
      bio: profileFields['bio']?.toString(),
      datingGoal: profileFields['datingGoal']?.toString(),
      photos: parsePhotos(profileFields['photos']),
      isHidden: isHidden,
      zodiacSign: profileFields['zodiacSign']?.toString(),
      zodiacPreferences: List<String>.from(
        profileFields['zodiacPreferences'] ?? [],
      ),
      lifePathNumber: profileFields['lifePathNumber'] as int?,
      freeTimeSlots: List<String>.from(profileFields['freeTimeSlots'] ?? []),
      desiredPartnerType: profileFields['desiredPartnerType']?.toString(),
    );
  }

  /// Tên hiển thị: ưu tiên fullName → name → email prefix
  String get displayName => fullName?.isNotEmpty == true
      ? fullName!
      : name?.isNotEmpty == true
      ? name!
      : email.split('@').first;

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'image': image,
    'phone': phone,
    'fullName': fullName,
    'gender': gender,
    'birthDate': birthDate?.toIso8601String(),
    'city': city,
    'bio': bio,
    'datingGoal': datingGoal,
    'photos': photos,
    'isHidden': isHidden,
    'zodiacSign': zodiacSign,
    'zodiacPreferences': zodiacPreferences,
    'lifePathNumber': lifePathNumber,
    'freeTimeSlots': freeTimeSlots,
    'desiredPartnerType': desiredPartnerType,
  };
}

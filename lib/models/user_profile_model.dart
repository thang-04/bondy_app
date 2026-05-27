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
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>?;

    // Parse photos: server trả về List<dynamic>
    List<String> parsePhotos(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return [];
    }

    return UserProfileModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString(),
      image: json['image']?.toString(),
      phone: json['phone']?.toString(),
      // Profile
      fullName: profile?['fullName']?.toString(),
      gender: profile?['gender']?.toString(),
      birthDate: profile?['birthDate'] != null
          ? DateTime.tryParse(profile!['birthDate'].toString())
          : null,
      city: profile?['city']?.toString(),
      bio: profile?['bio']?.toString(),
      datingGoal: profile?['datingGoal']?.toString(),
      photos: parsePhotos(profile?['photos']),
    );
  }

  /// Tên hiển thị: ưu tiên fullName → name → email prefix
  String get displayName =>
      fullName?.isNotEmpty == true
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
      };
}

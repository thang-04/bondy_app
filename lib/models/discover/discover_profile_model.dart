class DiscoverProfile {
  final String id;
  final String name;
  final int age;
  final String distance;
  final String bio;
  final List<String> tags;
  final int matchPercentage;
  final String imageUrl;

  const DiscoverProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.distance,
    required this.bio,
    required this.tags,
    required this.matchPercentage,
    required this.imageUrl,
  });

  factory DiscoverProfile.fromJson(Map<String, dynamic> json) {
    final photos = (json['photos'] as List<dynamic>?) ?? [];
    Map<String, dynamic>? primaryPhoto;
    Map<String, dynamic>? fallbackPhoto;
    for (final photo in photos) {
      if (photo is! Map<String, dynamic>) continue;
      fallbackPhoto ??= photo;
      if (photo['isPrimary'] == true) {
        primaryPhoto = photo;
        break;
      }
    }

    return DiscoverProfile(
      id: json['userId']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Ẩn danh',
      age: (json['age'] as num?)?.toInt() ?? 0,
      distance: json['city']?.toString() ?? 'Gần bạn',
      bio: json['bio']?.toString() ?? '',
      tags: ((json['commonInterests'] as List<dynamic>?) ?? []).map((tag) => tag.toString()).toList(),
      matchPercentage: (json['matchPercentage'] as num?)?.toInt() ?? 80,
      imageUrl: primaryPhoto?['url']?.toString() ?? fallbackPhoto?['url']?.toString() ?? '👤',
    );
  }
}

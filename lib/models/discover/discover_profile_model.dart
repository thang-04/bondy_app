import '../../core/media_url.dart';

class DiscoverPrompt {
  final String prompt;
  final String answer;

  const DiscoverPrompt({required this.prompt, required this.answer});

  factory DiscoverPrompt.fromJson(Map<String, dynamic> json) {
    return DiscoverPrompt(
      prompt: json['prompt']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
    );
  }
}

class DiscoverProfile {
  final String id;
  final String name;
  final int age;
  final String distance;
  final String bio;
  final String? vibe;
  final List<DiscoverPrompt> prompts;
  final List<String> tags;
  final int matchPercentage;
  final String imageUrl;
  final List<String> photos;
  final String? datingGoal;
  final double? distanceKm;

  const DiscoverProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.distance,
    required this.bio,
    this.vibe,
    this.prompts = const [],
    required this.tags,
    required this.matchPercentage,
    required this.imageUrl,
    this.photos = const [],
    this.datingGoal,
    this.distanceKm,
  });

  factory DiscoverProfile.fromJson(Map<String, dynamic> json) {
    final photosRaw = (json['photos'] as List<dynamic>?) ?? [];
    final List<String> photosList = [];
    Map<String, dynamic>? primaryPhoto;
    Map<String, dynamic>? fallbackPhoto;
    for (final photo in photosRaw) {
      if (photo is! Map<String, dynamic>) continue;
      final url = photo['url']?.toString();
      if (url != null && url.isNotEmpty) {
        final rewritten = rewriteMediaUrl(url);
        if (rewritten != null) {
          photosList.add(rewritten);
        }
      }
      fallbackPhoto ??= photo;
      if (photo['isPrimary'] == true) {
        primaryPhoto = photo;
      }
    }

    final promptsRaw = (json['prompts'] as List<dynamic>?) ?? [];
    final double? distanceKm = json['distanceKm'] != null
        ? (json['distanceKm'] as num).toDouble()
        : null;

    return DiscoverProfile(
      id: json['userId']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Ẩn danh',
      age: (json['age'] as num?)?.toInt() ?? 0,
      distance: distanceKm != null
          ? (distanceKm % 1 == 0
              ? 'Cách bạn ${distanceKm.toInt()} km'
              : 'Cách bạn ${distanceKm.toStringAsFixed(1)} km')
          : (json['city']?.toString() ?? ''),
      bio: json['bio']?.toString() ?? '',
      vibe: json['vibe']?.toString(),
      prompts: promptsRaw
          .whereType<Map<String, dynamic>>()
          .map(DiscoverPrompt.fromJson)
          .toList(),
      tags: ((json['interests'] as List<dynamic>?) ??
              (json['commonInterests'] as List<dynamic>?) ??
              [])
          .map((tag) => tag.toString())
          .toList(),
      matchPercentage: (json['matchPercentage'] as num?)?.toInt() ?? 0,
      imageUrl: rewriteMediaUrl(
            primaryPhoto?['url']?.toString() ??
                fallbackPhoto?['url']?.toString(),
          ) ??
          '',
      photos: photosList,
      datingGoal: json['datingGoal']?.toString(),
      distanceKm: distanceKm,
    );
  }
}

class DiscoverFilters {
  final int? minAge;
  final int? maxAge;
  final int? maxDistance;
  final String? gender;
  final String? orientation;
  final String? datingGoal;
  final List<String>? interests;
  final int? minCompatibility;
  final List<String>? vibes;

  const DiscoverFilters({
    this.minAge,
    this.maxAge,
    this.maxDistance,
    this.gender,
    this.orientation,
    this.datingGoal,
    this.interests,
    this.minCompatibility,
    this.vibes,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    if (minAge != null) params['ageMin'] = minAge;
    if (maxAge != null) params['ageMax'] = maxAge;
    if (maxDistance != null) params['distanceKm'] = maxDistance;
    if (gender != null) params['genders'] = gender;
    if (orientation != null) params['orientations'] = orientation;
    if (datingGoal != null) params['goals'] = datingGoal;
    if (interests != null && interests!.isNotEmpty) {
      params['interestIds'] = interests!.join(',');
    }
    if (minCompatibility != null) params['minCompatibility'] = minCompatibility;
    if (vibes != null && vibes!.isNotEmpty) {
      params['vibes'] = vibes!.join(',');
    }
    return params;
  }
}

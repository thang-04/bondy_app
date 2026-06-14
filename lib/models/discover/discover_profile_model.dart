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

class CompatibilityFactor {
  final String type;
  final double weight;
  final double score;

  const CompatibilityFactor({
    required this.type,
    required this.weight,
    required this.score,
  });

  factory CompatibilityFactor.fromJson(Map<String, dynamic> json) {
    return CompatibilityFactor(
      type: json['type']?.toString() ?? '',
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DeepMatchData {
  final String? zodiacSign;
  final List<String> zodiacPreferences;
  final int? lifePathNumber;
  final List<String> freeTimeSlots;
  final String? desiredPartnerType;

  const DeepMatchData({
    this.zodiacSign,
    this.zodiacPreferences = const [],
    this.lifePathNumber,
    this.freeTimeSlots = const [],
    this.desiredPartnerType,
  });

  factory DeepMatchData.fromJson(Map<String, dynamic> json) {
    return DeepMatchData(
      zodiacSign: json['zodiacSign']?.toString(),
      zodiacPreferences: List<String>.from(json['zodiacPreferences'] ?? []),
      lifePathNumber: json['lifePathNumber'] as int?,
      freeTimeSlots: List<String>.from(json['freeTimeSlots'] ?? []),
      desiredPartnerType: json['desiredPartnerType']?.toString(),
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
  final DeepMatchData? deepMatch;
  final List<CompatibilityFactor> compatibilityFactors;

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
    this.deepMatch,
    this.compatibilityFactors = const [],
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

    final String city = json['city']?.toString() ?? '';
    final String distanceLabel = distanceKm != null
        ? (distanceKm % 1 == 0
              ? 'Cách bạn ${distanceKm.toInt()} km'
              : 'Cách bạn ${distanceKm.toStringAsFixed(1)} km')
        : '';

    final String finalDistance = [
      if (distanceLabel.isNotEmpty) distanceLabel,
      if (city.isNotEmpty) city,
    ].join(' • ');

    final deepMatchRaw = json['deepMatch'] as Map<String, dynamic>?;
    final deepMatch = deepMatchRaw != null
        ? DeepMatchData.fromJson(deepMatchRaw)
        : null;

    final compatibilityRaw = json['compatibility'] as Map<String, dynamic>?;
    final factorsRaw = compatibilityRaw?['factors'] as List<dynamic>?;
    final List<CompatibilityFactor> compatibilityFactors = factorsRaw != null
        ? factorsRaw
              .whereType<Map<String, dynamic>>()
              .map(
                (e) =>
                    CompatibilityFactor.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
        : const [];

    return DiscoverProfile(
      id: json['userId']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Ẩn danh',
      age: (json['age'] as num?)?.toInt() ?? 0,
      distance: finalDistance.isNotEmpty ? finalDistance : city,
      bio: json['bio']?.toString() ?? '',
      vibe: json['vibe']?.toString(),
      prompts: promptsRaw
          .whereType<Map<String, dynamic>>()
          .map(DiscoverPrompt.fromJson)
          .toList(),
      tags:
          ((json['interests'] as List<dynamic>?) ??
                  (json['commonInterests'] as List<dynamic>?) ??
                  [])
              .map((tag) => tag.toString())
              .toList(),
      matchPercentage: (json['matchPercentage'] as num?)?.toInt() ?? 0,
      imageUrl:
          rewriteMediaUrl(
            primaryPhoto?['url']?.toString() ??
                fallbackPhoto?['url']?.toString(),
          ) ??
          '',
      photos: photosList,
      datingGoal: json['datingGoal']?.toString(),
      distanceKm: distanceKm,
      deepMatch: deepMatch,
      compatibilityFactors: compatibilityFactors,
    );
  }
}

class DiscoverFilters {
  final int? minAge;
  final int? maxAge;
  final int? maxDistance;
  final List<String>? genders;
  final List<String>? orientations;
  final List<String>? goals;
  final List<String>? interests;
  final int? minCompatibility;
  final List<String>? vibes;

  const DiscoverFilters({
    this.minAge,
    this.maxAge,
    this.maxDistance,
    this.genders,
    this.orientations,
    this.goals,
    this.interests,
    this.minCompatibility,
    this.vibes,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    if (minAge != null) params['ageMin'] = minAge;
    if (maxAge != null) params['ageMax'] = maxAge;
    if (maxDistance != null) params['distanceKm'] = maxDistance;
    if (genders != null && genders!.isNotEmpty) {
      params['genders'] = genders!.join(',');
    }
    if (orientations != null && orientations!.isNotEmpty) {
      params['orientations'] = orientations!.join(',');
    }
    if (goals != null && goals!.isNotEmpty) {
      params['goals'] = goals!.join(',');
    }
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

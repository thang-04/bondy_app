import 'api_client.dart';

class SafetyCheckin {
  final String id;
  final String? matchId;
  final String? location;
  final DateTime? expectedReturnAt;
  final String status;
  final DateTime createdAt;

  const SafetyCheckin({
    required this.id,
    this.matchId,
    this.location,
    this.expectedReturnAt,
    required this.status,
    required this.createdAt,
  });

  bool get isActive => status == 'active';

  factory SafetyCheckin.fromJson(Map<String, dynamic> json) {
    return SafetyCheckin(
      id: json['id']?.toString() ?? '',
      matchId: json['matchId']?.toString(),
      location: json['location']?.toString(),
      expectedReturnAt: json['expectedReturnAt'] != null
          ? DateTime.tryParse(json['expectedReturnAt'].toString())
          : null,
      status: json['status']?.toString() ?? 'active',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class SafetyCheckinService {
  final ApiClient _apiClient;

  SafetyCheckinService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<SafetyCheckin> createCheckin({
    String? matchId,
    String? location,
    required DateTime expectedReturnAt,
  }) async {
    final body = <String, dynamic>{
      'expectedReturnAt': expectedReturnAt.toUtc().toIso8601String(),
    };
    if (matchId != null) body['matchId'] = matchId;
    if (location != null && location.isNotEmpty) body['location'] = location;

    final response = await _apiClient.post(
      '/safety/pre-date-checkin',
      authenticated: true,
      body: body,
    );
    return SafetyCheckin.fromJson(
      (response['data'] as Map<String, dynamic>?) ?? {},
    );
  }

  Future<SafetyCheckin> confirmCheckin(String checkinId) async {
    final response = await _apiClient.post(
      '/safety/pre-date-checkin/confirm',
      authenticated: true,
      body: {'checkinId': checkinId},
    );
    return SafetyCheckin.fromJson(
      (response['data'] as Map<String, dynamic>?) ?? {},
    );
  }

  Future<List<SafetyCheckin>> fetchActiveCheckins() async {
    final response = await _apiClient.get(
      '/safety/pre-date-checkin/active',
      authenticated: true,
    );
    final data = (response['data'] as List<dynamic>?) ?? [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(SafetyCheckin.fromJson)
        .toList();
  }
}

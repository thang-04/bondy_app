import 'api_client.dart';

class CoupleCheckinEntry {
  final String id;
  final String mood;
  final String? note;
  final DateTime createdAt;
  final bool isMine;

  CoupleCheckinEntry({
    required this.id,
    required this.mood,
    this.note,
    required this.createdAt,
    required this.isMine,
  });

  factory CoupleCheckinEntry.fromJson(Map<String, dynamic> json) {
    return CoupleCheckinEntry(
      id: json['id']?.toString() ?? '',
      mood: json['mood']?.toString() ?? '',
      note: json['note']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      isMine: json['isMine'] == true,
    );
  }
}

class RelationshipDashboard {
  final bool hasRelationship;
  final String? relationshipId;
  final String? partnerId;
  final String? partnerName;
  final String? partnerPhotoUrl;
  final int streakDays;
  final int daysTogether;
  final String? nextMilestoneTitle;
  final DateTime? nextMilestoneDate;
  final List<CoupleCheckinEntry> recentCheckins;

  RelationshipDashboard({
    required this.hasRelationship,
    this.relationshipId,
    this.partnerId,
    this.partnerName,
    this.partnerPhotoUrl,
    this.streakDays = 0,
    this.daysTogether = 0,
    this.nextMilestoneTitle,
    this.nextMilestoneDate,
    this.recentCheckins = const [],
  });

  factory RelationshipDashboard.fromJson(Map<String, dynamic> json) {
    if (json['hasRelationship'] != true) {
      return RelationshipDashboard(hasRelationship: false);
    }
    final partner = json['partner'] as Map<String, dynamic>? ?? {};
    final milestone = json['nextMilestone'] as Map<String, dynamic>?;
    final checkinsRaw = json['recentCheckins'] as List<dynamic>? ?? [];
    return RelationshipDashboard(
      hasRelationship: true,
      relationshipId: json['relationshipId']?.toString(),
      partnerId: partner['id']?.toString(),
      partnerName: partner['name']?.toString(),
      partnerPhotoUrl: partner['photoUrl']?.toString(),
      streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
      daysTogether: (json['daysTogether'] as num?)?.toInt() ?? 0,
      nextMilestoneTitle: milestone?['title']?.toString(),
      nextMilestoneDate: milestone?['date'] != null
          ? DateTime.tryParse(milestone!['date'].toString())
          : null,
      recentCheckins: checkinsRaw
          .whereType<Map<String, dynamic>>()
          .map(CoupleCheckinEntry.fromJson)
          .toList(),
    );
  }
}

class RelationshipService {
  final ApiClient _apiClient;

  RelationshipService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<RelationshipDashboard> getDashboard() async {
    final response = await _apiClient.get('/relationships/me', authenticated: true);
    return RelationshipDashboard.fromJson(
      (response['data'] as Map<String, dynamic>?) ?? {},
    );
  }

  Future<Map<String, dynamic>> createInvite({String? matchId}) async {
    final response = await _apiClient.post(
      '/relationships/invite',
      authenticated: true,
      body: matchId != null ? {'matchId': matchId} : <String, dynamic>{},
    );
    return (response['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<void> acceptInvite(String inviteCode) async {
    await _apiClient.post(
      '/relationships/accept',
      authenticated: true,
      body: {'inviteCode': inviteCode},
    );
  }

  Future<void> submitCheckin({required String mood, String? note}) async {
    await _apiClient.post(
      '/relationships/checkins',
      authenticated: true,
      body: {'mood': mood, if (note != null && note.isNotEmpty) 'note': note},
    );
  }

  Future<List<Map<String, dynamic>>> listMilestones() async {
    final response = await _apiClient.get(
      '/relationships/milestones',
      authenticated: true,
    );
    final data = (response['data'] as List<dynamic>?) ?? [];
    return data.map((e) => (e as Map).cast<String, dynamic>()).toList();
  }

  Future<void> addMilestone({
    required String title,
    required DateTime milestoneDate,
  }) async {
    await _apiClient.post(
      '/relationships/milestones',
      authenticated: true,
      body: {
        'title': title,
        'milestoneDate': milestoneDate.toUtc().toIso8601String(),
      },
    );
  }

  Future<Map<String, dynamic>?> fetchWeeklyReport() async {
    try {
      final response = await _apiClient.get(
        '/relationships/weekly-report',
        authenticated: true,
      );
      return (response['data'] as Map<String, dynamic>?);
    } catch (_) {
      return null;
    }
  }
}

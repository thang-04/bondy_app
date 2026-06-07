import 'api_client.dart';
import '../core/media_url.dart';

enum RelationshipTimelineItemType { started, milestone, checkin }

enum RelationshipDailyActionStatus { active, reminded, skipped }

String relationshipDateKey([DateTime? value]) {
  final date = value ?? DateTime.now();
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

RelationshipTimelineItemType _timelineItemTypeFromApi(String? value) {
  switch (value) {
    case 'STARTED':
      return RelationshipTimelineItemType.started;
    case 'CHECKIN':
      return RelationshipTimelineItemType.checkin;
    case 'MILESTONE':
    default:
      return RelationshipTimelineItemType.milestone;
  }
}

RelationshipDailyActionStatus _dailyActionStatusFromApi(String? value) {
  switch (value) {
    case 'REMINDED':
      return RelationshipDailyActionStatus.reminded;
    case 'SKIPPED':
      return RelationshipDailyActionStatus.skipped;
    case 'ACTIVE':
    default:
      return RelationshipDailyActionStatus.active;
  }
}

String _dailyActionStatusToApi(RelationshipDailyActionStatus status) {
  switch (status) {
    case RelationshipDailyActionStatus.reminded:
      return 'REMINDED';
    case RelationshipDailyActionStatus.skipped:
      return 'SKIPPED';
    case RelationshipDailyActionStatus.active:
      return 'ACTIVE';
  }
}

class RelationshipInvitation {
  final String id;
  final String inviterId;
  final String inviterName;
  final String? inviterPhoto;
  final String status;
  final DateTime? createdAt;

  const RelationshipInvitation({
    required this.id,
    required this.inviterId,
    required this.inviterName,
    required this.inviterPhoto,
    required this.status,
    required this.createdAt,
  });

  factory RelationshipInvitation.fromJson(Map<String, dynamic> json) {
    return RelationshipInvitation(
      id: json['id']?.toString() ?? '',
      inviterId: json['inviterId']?.toString() ?? '',
      inviterName: json['inviterName']?.toString() ?? 'Người dùng',
      inviterPhoto: rewriteMediaUrl(json['inviterPhoto']?.toString()),
      status: json['status']?.toString() ?? 'PENDING',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'inviterId': inviterId,
    'inviterName': inviterName,
    'inviterPhoto': inviterPhoto,
    'status': status,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
  };
}

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
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
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
      partnerPhotoUrl: rewriteMediaUrl(partner['photoUrl']?.toString()),
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

class RelationshipTimelineItem {
  final String id;
  final RelationshipTimelineItemType type;
  final String title;
  final String? description;
  final DateTime occurredAt;
  final String? actorName;
  final String? mood;

  const RelationshipTimelineItem({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    required this.occurredAt,
    this.actorName,
    this.mood,
  });

  factory RelationshipTimelineItem.fromJson(Map<String, dynamic> json) {
    return RelationshipTimelineItem(
      id: json['id']?.toString() ?? '',
      type: _timelineItemTypeFromApi(json['type']?.toString()),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      occurredAt:
          DateTime.tryParse(json['occurredAt']?.toString() ?? '') ??
          DateTime.now(),
      actorName: json['actorName']?.toString(),
      mood: json['mood']?.toString(),
    );
  }
}

class RelationshipDailyAction {
  final String actionKey;
  final String dateKey;
  final String title;
  final String description;
  final RelationshipDailyActionStatus status;
  final DateTime? remindAt;

  const RelationshipDailyAction({
    required this.actionKey,
    required this.dateKey,
    required this.title,
    required this.description,
    required this.status,
    this.remindAt,
  });

  factory RelationshipDailyAction.fromJson(Map<String, dynamic> json) {
    return RelationshipDailyAction(
      actionKey: json['actionKey']?.toString() ?? 'gratitude_note',
      dateKey: json['dateKey']?.toString() ?? relationshipDateKey(),
      title: json['title']?.toString() ?? 'Gửi một lời cảm ơn chân thành',
      description:
          json['description']?.toString() ??
          'Một lời cảm ơn nhỏ bé có thể thắp sáng cả ngày dài.',
      status: _dailyActionStatusFromApi(json['status']?.toString()),
      remindAt: DateTime.tryParse(json['remindAt']?.toString() ?? ''),
    );
  }
}

class RelationshipService {
  final ApiClient _apiClient;

  RelationshipService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<RelationshipDashboard> getDashboard() async {
    final response = await _apiClient.get(
      '/relationships/me',
      authenticated: true,
    );
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

  /// Kiểm tra lời mời xác nhận mối quan hệ đang chờ cho một matchId.
  Future<Map<String, dynamic>> checkPendingInvite(String matchId) async {
    final response = await _apiClient.get(
      '/relationships/invite/pending',
      authenticated: true,
      queryParams: {'matchId': matchId},
    );
    return (response['data'] as Map<String, dynamic>?) ?? {};
  }

  /// Chấp nhận lời mời xác nhận mối quan hệ qua matchId.
  Future<Map<String, dynamic>> acceptByMatchId(String matchId) async {
    final response = await _apiClient.post(
      '/relationships/accept',
      authenticated: true,
      body: {'matchId': matchId},
    );
    return (response['data'] as Map<String, dynamic>?) ?? {};
  }

  /// Từ chối lời mời xác nhận mối quan hệ.
  Future<void> declineInvite(String matchId) async {
    await _apiClient.post(
      '/relationships/invite/decline',
      authenticated: true,
      body: {'matchId': matchId},
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

  Future<List<RelationshipTimelineItem>> fetchTimeline() async {
    final response = await _apiClient.get(
      '/relationships/timeline',
      authenticated: true,
    );
    final data = (response['data'] as List<dynamic>?) ?? [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(RelationshipTimelineItem.fromJson)
        .toList();
  }

  Future<RelationshipDailyAction> fetchDailyAction({String? dateKey}) async {
    final response = await _apiClient.get(
      '/relationships/daily-action',
      authenticated: true,
      queryParams: dateKey == null ? null : {'dateKey': dateKey},
    );
    return RelationshipDailyAction.fromJson(
      (response['data'] as Map<String, dynamic>?) ?? {},
    );
  }

  Future<RelationshipDailyAction> updateDailyActionState({
    required String actionKey,
    required String dateKey,
    required RelationshipDailyActionStatus status,
    DateTime? remindAt,
  }) async {
    final response = await _apiClient.post(
      '/relationships/daily-action/state',
      authenticated: true,
      body: {
        'actionKey': actionKey,
        'dateKey': dateKey,
        'status': _dailyActionStatusToApi(status),
        if (remindAt != null) 'remindAt': remindAt.toUtc().toIso8601String(),
      },
    );
    return RelationshipDailyAction.fromJson(
      (response['data'] as Map<String, dynamic>?) ?? {},
    );
  }
}

import 'api_client.dart';

class PendingMatch {
  final String id;
  final String status;
  final String? chatId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhoto;
  final DateTime? expiresAt;

  PendingMatch({
    required this.id,
    required this.status,
    this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhoto,
    this.expiresAt,
  });

  factory PendingMatch.fromJson(Map<String, dynamic> json) {
    final other = json['otherUser'] as Map<String, dynamic>? ?? {};
    final first = other['firstName']?.toString() ?? '';
    final last = other['lastName']?.toString() ?? '';
    final name = '$first $last'.trim();
    return PendingMatch(
      id: json['id'] as String,
      status: json['status']?.toString() ?? 'PENDING',
      chatId: json['chatId'] as String?,
      otherUserId: other['id']?.toString() ?? '',
      otherUserName: name.isNotEmpty
          ? name
          : (other['name']?.toString() ?? 'Người kết nối'),
      otherUserPhoto: other['photo'] as String?,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'].toString())
          : null,
    );
  }

  bool get needsConfirmation => status == 'PENDING' && chatId == null;
}

class ConfirmMatchResult {
  final bool isConfirmed;
  final String? chatId;
  final String status;

  const ConfirmMatchResult({
    required this.isConfirmed,
    this.chatId,
    required this.status,
  });

  factory ConfirmMatchResult.fromJson(Map<String, dynamic> json) {
    return ConfirmMatchResult(
      isConfirmed: json['status'] == 'CONFIRMED',
      chatId: json['chatId'] as String?,
      status: json['status'] as String,
    );
  }
}

class MatchService {
  final ApiClient _apiClient;

  MatchService(this._apiClient);

  Future<List<PendingMatch>> listMatches() async {
    final response = await _apiClient.get('/matches', authenticated: true);
    final data = (response['data'] as List<dynamic>?) ?? [];
    return data
        .cast<Map<String, dynamic>>()
        .map(PendingMatch.fromJson)
        .toList();
  }

  Future<Map<String, dynamic>> getMatchDetail(String matchId) async {
    final response = await _apiClient.get(
      '/matches/$matchId',
      authenticated: true,
    );
    return (response['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<bool> unmatch(String matchId) async {
    final response = await _apiClient.delete(
      '/matches/$matchId',
      authenticated: true,
    );
    return response['success'] == true;
  }

  Future<ConfirmMatchResult> confirmMatch(String matchId) async {
    final response = await _apiClient.post(
      '/matches/$matchId/confirm',
      authenticated: true,
    );
    return ConfirmMatchResult.fromJson(
      response['data'] as Map<String, dynamic>,
    );
  }
}

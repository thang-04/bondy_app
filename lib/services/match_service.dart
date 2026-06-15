import 'api_client.dart';

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

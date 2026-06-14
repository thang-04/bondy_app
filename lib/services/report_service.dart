import 'api_client.dart';

enum ReportReason { spam, harassment, fakeProfile, inappropriate, other }

extension ReportReasonExtension on ReportReason {
  String get value {
    switch (this) {
      case ReportReason.spam:
        return 'SPAM';
      case ReportReason.harassment:
        return 'HARASSMENT';
      case ReportReason.fakeProfile:
        return 'FAKE_PROFILE';
      case ReportReason.inappropriate:
        return 'INAPPROPRIATE';
      case ReportReason.other:
        return 'OTHER';
    }
  }
}

class ReportResult {
  final String reportId;
  final String status;

  const ReportResult({required this.reportId, required this.status});

  factory ReportResult.fromJson(Map<String, dynamic> json) {
    return ReportResult(
      reportId: json['reportId'] as String,
      status: json['status'] as String,
    );
  }
}

class ReportService {
  final ApiClient _apiClient;

  ReportService(this._apiClient);

  Future<ReportResult> createReport({
    required String targetUserId,
    required ReportReason reason,
  }) async {
    final response = await _apiClient.post(
      '/reports',
      body: {'targetUserId': targetUserId, 'reason': reason.value},
      authenticated: true,
    );
    return ReportResult.fromJson(response['data'] as Map<String, dynamic>);
  }
}

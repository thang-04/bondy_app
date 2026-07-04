import 'package:bondy/services/api_client.dart';
import 'package:bondy/services/payment_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingApiClient extends ApiClient {
  String? postPath;
  Map<String, dynamic>? postBody;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    bool authenticated = false,
    Map<String, dynamic>? queryParams,
  }) async {
    expect(authenticated, isTrue);
    expect(path, '/payments/plans');
    return {
      'success': true,
      'data': {
        'gatewayConfigured': true,
        'subscriptions': [
          {
            'tier': 'PLUS',
            'name': 'PLUS',
            'amount': 39000,
            'durationDays': 30,
            'period': 'thang',
            'description': 'Plus plan',
          },
        ],
        'aiChatPasses': [
          {
            'code': 'AI_CHAT_PASS_3D',
            'name': 'Goi AI 3 ngay',
            'amount': 19000,
            'durationDays': 3,
            'totalTurns': 60,
            'period': '3 ngay',
            'description': 'Them 60 luot chat AI.',
          },
        ],
      },
    };
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) async {
    expect(authenticated, isTrue);
    postPath = path;
    postBody = body;
    return {
      'success': true,
      'data': {
        'id': 'pay-ai-1',
        'code': 'BONDYAI1',
        'productType': 'AI_CHAT_PASS',
        'productCode': 'AI_CHAT_PASS_3D',
        'tier': null,
        'amount': 19000,
        'durationDays': 3,
        'status': 'PENDING',
        'qrUrl': 'https://qr.example/ai',
        'bankCode': 'MBBank',
        'accountNumber': '0123456789',
        'accountHolder': 'BONDY APP',
        'transferContent': 'BONDYAI1',
        'planName': 'Goi AI 3 ngay',
        'period': '3 ngay',
        'totalTurns': 60,
        'paidAt': null,
        'expiresAt': '2026-07-04T12:30:00.000Z',
      },
    };
  }
}

void main() {
  test('parses subscription and AI chat pass plans from the catalog', () async {
    final service = PaymentService(apiClient: _RecordingApiClient());

    final catalog = await service.getPlans();

    expect(catalog.gatewayConfigured, isTrue);
    expect(catalog.subscriptions.single.tier, 'PLUS');
    expect(catalog.plans.single.tier, 'PLUS');
    expect(catalog.aiChatPasses.single.code, 'AI_CHAT_PASS_3D');
    expect(catalog.aiChatPasses.single.totalTurns, 60);
  });

  test('creates an AI chat pass payment order with packageCode', () async {
    final apiClient = _RecordingApiClient();
    final service = PaymentService(apiClient: apiClient);

    final order = await service.createAIChatPassOrder('AI_CHAT_PASS_3D');

    expect(apiClient.postPath, '/payments/ai-chat-pass');
    expect(apiClient.postBody, {'packageCode': 'AI_CHAT_PASS_3D'});
    expect(order.productType, 'AI_CHAT_PASS');
    expect(order.productCode, 'AI_CHAT_PASS_3D');
    expect(order.totalTurns, 60);
    expect(order.tier, isNull);
  });
}

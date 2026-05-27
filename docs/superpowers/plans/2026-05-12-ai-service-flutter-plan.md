# AI Service Flutter Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement AiService with environment-based mock/real API switching

**Architecture:** Service layer uses ApiClient for authenticated API calls. Dev detection via `baseUrl.contains('localhost')`. Mock returns intent-based suggestions with simulated latency. Production uses real backend at `/ai/conversation-suggest`.

**Tech Stack:** Flutter, http package, existing ApiClient pattern

---

## File Structure

```
Bondy_App/lib/models/ai_suggest_model.dart   -- Request/response models
Bondy_App/lib/services/ai_service.dart        -- Service with mock/real
Bondy_App/test/services/ai_service_test.dart   -- Unit tests
```

---

## Task 1: Create AI Suggest Models

**Files:**
- Create: `Bondy_App/lib/models/ai_suggest_model.dart`

- [ ] **Step 1: Write failing test**

```dart
// Bondy_App/test/models/ai_suggest_model_test.dart
import 'package:bondy/models/ai_suggest_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AiSuggestRequest.toJson serializes all fields', () {
    final request = AiSuggestRequest(
      conversationId: 'conv-123',
      userId: 'user-456',
      intent: 'greeting',
      tone: 'friendly',
      language: 'vi',
    );
    final json = request.toJson();
    expect(json['conversationId'], 'conv-123');
    expect(json['userId'], 'user-456');
    expect(json['intent'], 'greeting');
    expect(json['tone'], 'friendly');
    expect(json['language'], 'vi');
  });

  test('AiSuggestResponse.fromJson parses success response', () {
    final json = {
      'success': true,
      'data': {
        'suggestions': ['suggestion 1', 'suggestion 2'],
        'usage': {
          'tokensUsed': 100,
          'latencyMs': 200,
          'provider': 'openai',
        },
      },
    };
    final response = AiSuggestResponse.fromJson(json);
    expect(response.success, true);
    expect(response.data?.suggestions, ['suggestion 1', 'suggestion 2']);
    expect(response.data?.usage.tokensUsed, 100);
    expect(response.data?.usage.latencyMs, 200);
    expect(response.data?.usage.provider, 'openai');
  });

  test('AiSuggestResponse.fromJson parses error response', () {
    final json = {
      'success': false,
      'error': 'Something went wrong',
    };
    final response = AiSuggestResponse.fromJson(json);
    expect(response.success, false);
    expect(response.error, 'Something went wrong');
    expect(response.data, isNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/models/ai_suggest_model_test.dart`
Expected: FAIL - "AiSuggestRequest" isn't defined

- [ ] **Step 3: Write minimal implementation**

```dart
// Bondy_App/lib/models/ai_suggest_model.dart
class AiSuggestRequest {
  final String conversationId;
  final String userId;
  final String intent;
  final String tone;
  final String language;

  AiSuggestRequest({
    required this.conversationId,
    required this.userId,
    required this.intent,
    required this.tone,
    required this.language,
  });

  Map<String, dynamic> toJson() => {
    'conversationId': conversationId,
    'userId': userId,
    'intent': intent,
    'tone': tone,
    'language': language,
  };
}

class AiSuggestResponse {
  final bool success;
  final AiSuggestData? data;
  final String? error;

  AiSuggestResponse({
    required this.success,
    this.data,
    this.error,
  });

  factory AiSuggestResponse.fromJson(Map<String, dynamic> json) {
    return AiSuggestResponse(
      success: json['success'] as bool,
      data: json['data'] != null
          ? AiSuggestData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      error: json['error'] as String?,
    );
  }
}

class AiSuggestData {
  final List<String> suggestions;
  final AiUsage usage;

  AiSuggestData({
    required this.suggestions,
    required this.usage,
  });

  factory AiSuggestData.fromJson(Map<String, dynamic> json) {
    return AiSuggestData(
      suggestions: (json['suggestions'] as List<dynamic>).cast<String>(),
      usage: AiUsage.fromJson(json['usage'] as Map<String, dynamic>),
    );
  }
}

class AiUsage {
  final int tokensUsed;
  final int latencyMs;
  final String provider;

  AiUsage({
    required this.tokensUsed,
    required this.latencyMs,
    required this.provider,
  });

  factory AiUsage.fromJson(Map<String, dynamic> json) {
    return AiUsage(
      tokensUsed: json['tokensUsed'] as int,
      latencyMs: json['latencyMs'] as int,
      provider: json['provider'] as String,
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/models/ai_suggest_model_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Bondy_App/lib/models/ai_suggest_model.dart Bondy_App/test/models/ai_suggest_model_test.dart
git commit -m "feat: add AI suggest request/response models"
```

---

## Task 2: Create AI Service

**Files:**
- Create: `Bondy_App/lib/services/ai_service.dart`

- [ ] **Step 1: Write failing test**

```dart
// Bondy_App/test/services/ai_service_test.dart
import 'dart:convert';
import 'package:bondy/models/ai_suggest_model.dart';
import 'package:bondy/services/ai_service.dart';
import 'package:bondy/services/api_client.dart';
import 'package:bondy/services/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('uses mock for localhost baseUrl', () async {
    final storage = FlutterSecureStorage();
    await storage.write(key: 'accessToken', value: 'test-token');
    final authService = AuthService(baseUrlOverride: 'http://localhost:3000/api', storage: storage);
    final apiClient = ApiClient(
      baseUrlOverride: 'http://localhost:3000/api',
      authService: authService,
      client: MockClient((request) async {
        // This should NOT be called - mock should intercept
        fail('Real API should not be called in dev mode');
      }),
    );
    final service = AiService(apiClient);

    final response = await service.suggest(AiSuggestRequest(
      conversationId: 'conv-1',
      userId: 'user-1',
      intent: 'greeting',
      tone: 'friendly',
      language: 'vi',
    ));

    expect(response.success, true);
    expect(response.data?.suggestions, isNotEmpty);
    expect(response.data?.usage.provider, 'mock');
  });

  test('uses real API for non-localhost baseUrl', () async {
    final storage = FlutterSecureStorage();
    await storage.write(key: 'accessToken', value: 'test-token');
    final authService = AuthService(baseUrlOverride: 'https://api.bondy.com/api', storage: storage);
    final apiClient = ApiClient(
      baseUrlOverride: 'https://api.bondy.com/api',
      authService: authService,
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/ai/conversation-suggest');
        final body = jsonDecode(request.body);
        expect(body['conversationId'], 'conv-1');
        expect(body['intent'], 'greeting');
        return http.Response(jsonEncode({
          'success': true,
          'data': {
            'suggestions': ['Real suggestion 1', 'Real suggestion 2'],
            'usage': {
              'tokensUsed': 150,
              'latencyMs': 300,
              'provider': 'openai',
            },
          },
        }), 200);
      }),
    );
    final service = AiService(apiClient);

    final response = await service.suggest(AiSuggestRequest(
      conversationId: 'conv-1',
      userId: 'user-1',
      intent: 'greeting',
      tone: 'friendly',
      language: 'vi',
    ));

    expect(response.success, true);
    expect(response.data?.suggestions, ['Real suggestion 1', 'Real suggestion 2']);
    expect(response.data?.usage.provider, 'openai');
  });

  test('mock returns intent-based suggestions for greeting', () async {
    final service = AiService(_createMockApiClient());
    final response = await service.suggest(AiSuggestRequest(
      conversationId: 'conv-1',
      userId: 'user-1',
      intent: 'greeting',
      tone: 'friendly',
      language: 'vi',
    ));
    expect(response.data?.suggestions.any((s) => s.contains('Xin chào') || s.contains('Chào')), true);
  });

  test('mock returns intent-based suggestions for confess', () async {
    final service = AiService(_createMockApiClient());
    final response = await service.suggest(AiSuggestRequest(
      conversationId: 'conv-1',
      userId: 'user-1',
      intent: 'confess',
      tone: 'sincere',
      language: 'vi',
    ));
    expect(response.data?.suggestions.any((s) => s.contains('quan tâm') || s.contains('muốn nói')), true);
  });
}

// Helper to create mock client for testing
ApiClient _createMockApiClient() {
  final storage = FlutterSecureStorage();
  final authService = AuthService(baseUrlOverride: 'http://localhost:3000/api', storage: storage);
  return ApiClient(
    baseUrlOverride: 'http://localhost:3000/api',
    authService: authService,
    client: MockClient((request) async => http.Response('{}', 200)),
  );
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/ai_service_test.dart`
Expected: FAIL - "AiService" isn't defined

- [ ] **Step 3: Write minimal implementation**

```dart
// Bondy_App/lib/services/ai_service.dart
import 'package:bondy/models/ai_suggest_model.dart';
import 'package:bondy/services/api_client.dart';

class AiService {
  final ApiClient _apiClient;

  AiService(this._apiClient);

  bool get _isDev => _apiClient.baseUrl.contains('localhost');

  Future<AiSuggestResponse> suggest(AiSuggestRequest request) async {
    if (_isDev) {
      return _mockSuggest(request);
    }
    return _realSuggest(request);
  }

  Future<AiSuggestResponse> _mockSuggest(AiSuggestRequest request) async {
    await Future.delayed(Duration(milliseconds: 500));
    return AiSuggestResponse(
      success: true,
      data: AiSuggestData(
        suggestions: _getMockSuggestions(request.intent),
        usage: AiUsage(
          tokensUsed: 50,
          latencyMs: 500,
          provider: 'mock',
        ),
      ),
    );
  }

  Future<AiSuggestResponse> _realSuggest(AiSuggestRequest request) async {
    final response = await _apiClient.post(
      '/ai/conversation-suggest',
      body: request.toJson(),
      authenticated: true,
    );
    return AiSuggestResponse.fromJson(response);
  }

  List<String> _getMockSuggestions(String intent) {
    switch (intent) {
      case 'greeting':
        return [
          'Xin chào! Rất vui được trò chuyện với bạn',
          'Chào bạn, hôm nay bạn thế nào?',
          'Hey, có gì mới không?',
        ];
      case 'confess':
        return [
          'Tôi thực sự quan tâm đến bạn',
          'Tôi muốn nói rằng...',
          'Bạn có thời gian trò chuyện không?',
        ];
      case 'apology':
        return [
          'Tôi xin lỗi nếu điều gì đó làm bạn不舒服',
          'Xin lỗi, tôi không cố ý',
          'Rất tiếc về chuyện đó',
        ];
      default:
        return [
          'Bạn muốn nói gì?',
          'Tôi đang lắng nghe',
          'Tiếp tục đi',
        ];
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/services/ai_service_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Bondy_App/lib/services/ai_service.dart Bondy_App/test/services/ai_service_test.dart
git commit -m "feat: add AI service with environment-based mock/real switching"
```

---

## Task 3: Add baseUrl getter to ApiClient

**Files:**
- Modify: `Bondy_App/lib/services/api_client.dart:18`

Note: `AiService._isDev` needs access to `baseUrl` but ApiClient stores it as private field. We expose a public getter.

- [ ] **Step 1: Write failing test (for the getter)**

```dart
// Add to existing test file or create new test
test('ApiClient exposes baseUrl for environment detection', () {
  final apiClient = ApiClient(baseUrlOverride: 'http://localhost:3000/api');
  expect(apiClient.baseUrl, 'http://localhost:3000/api');

  final prodClient = ApiClient(baseUrlOverride: 'https://api.bondy.com/api');
  expect(prodClient.baseUrl, 'https://api.bondy.com/api');
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/api_client_test.dart -n "ApiClient exposes baseUrl"`
Expected: FAIL - "baseUrl" isn't defined for ApiClient

- [ ] **Step 3: Add baseUrl getter to ApiClient**

In `Bondy_App/lib/services/api_client.dart`, after line 18:
```dart
String get baseUrl => _baseUrl;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/services/api_client_test.dart -n "ApiClient exposes baseUrl"`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Bondy_App/lib/services/api_client.dart
git commit -m "feat: expose baseUrl on ApiClient for environment detection"
```

---

## Task 4: Run all tests and final verification

- [ ] **Step 1: Run full test suite**

Run: `cd Bondy_App && flutter test`
Expected: All tests pass

- [ ] **Step 2: Verify spec coverage**

Check that spec requirements are met:
- [x] Models created (AiSuggestRequest, AiSuggestResponse, AiSuggestData, AiUsage)
- [x] Service with environment-based switching (_isDev)
- [x] Mock implementation with intent-based suggestions
- [x] Real API call to /ai/conversation-suggest
- [x] Tests for mock and real paths

---

## Summary

| Task | Files | Status |
|------|-------|--------|
| 1 | ai_suggest_model.dart + test | ☐ |
| 2 | ai_service.dart + test | ☐ |
| 3 | api_client.dart (baseUrl getter) | ☐ |
| 4 | Full test run + commit | ☐ |

---

## Post-Completion

After all tasks complete:
```bash
git push
bd close bondy-d7e
```
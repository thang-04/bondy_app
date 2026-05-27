# AI Service Flutter Implementation Spec

## Goal

Implement `AiService` for Bondy Flutter app with environment-based behavior:
- Mock responses when `BASE_URL` is localhost/dev
- Real API calls when `BASE_URL` is production

## Backend Contract

**Endpoint:** `POST /api/ai/conversation-suggest`

**Request:**
```json
{
  "conversationId": "string",
  "userId": "string",
  "intent": "string",
  "tone": "string",
  "language": "string"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "suggestions": ["string", "..."],
    "usage": {
      "tokensUsed": 0,
      "latencyMs": 0,
      "provider": "string"
    }
  }
}
```

## Files to Create

1. `Bondy_App/lib/models/ai_suggest_model.dart` - Request/response models
2. `Bondy_App/lib/services/ai_service.dart` - Service with mock/real switching
3. `Bondy_App/test/services/ai_service_test.dart` - Unit tests

## Architecture

- `AiService` uses `ApiClient` for API calls
- Dev detection: `_apiClient.baseUrl.contains('localhost')`
- Mock returns 3 contextual suggestions based on `intent` parameter
- All API calls are authenticated

## Model Structure

```
AiSuggestRequest
  - conversationId: String
  - userId: String
  - intent: String
  - tone: String
  - language: String
  - toJson(): Map<String, dynamic>

AiSuggestResponse
  - success: bool
  - data: AiSuggestData?
  - error: String?
  - factory fromJson(Map<String, dynamic>)

AiSuggestData
  - suggestions: List<String>
  - usage: AiUsage

AiUsage
  - tokensUsed: int
  - latencyMs: int
  - provider: String
```

## Mock Behavior

- Simulates 500ms network latency
- Returns 3 suggestions based on intent:
  - "greeting" → ["Xin chào! Rất vui được trò chuyện với bạn", "Chào bạn, hôm nay bạn thế nào?", "Hey, có gì mới không?"]
  - "confess" → ["Tôi thực sự quan tâm đến bạn", "Tôi muốn nói rằng...", "Bạn có thời gian trò chuyện không?"]
  - "apology" → ["Tôi xin lỗi nếu điều gì đó làm bạn不舒服", "Xin lỗi, tôi không cố ý", "Rất tiếc về chuyện đó"]
  - default → ["Bạn muốn nói gì?", "Tôi đang lắng nghe", "Tiếp tục đi"]
- Usage provider: "mock"

## Testing Coverage

1. Mock returns suggestions for dev environment (localhost baseUrl)
2. Real API called for production environment (non-localhost baseUrl)
3. Request body correctly serialized
4. Response correctly parsed
5. Error handling when API fails
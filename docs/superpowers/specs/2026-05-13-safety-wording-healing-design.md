# Safety Wording Healing - Design Spec

> **Issue:** bondy-l04 - Safety wording healing - Rà soát và xử lý nội dung nhạy cảm

## Context

App có chức năng healing chatbot nhưng chưa có safety guardrails. Nếu user nhập nội dung nguy cơ cao (tự tử, tự hại, khủng hoảng), app không phản ứng phù hợp - có thể gây hại thay vì giúp đỡ.

**Yêu cầu:**
- Nội dung an toàn, không đóng vai bác sĩ/therapist
- Nếu phát hiện risk → khuyến nghị tìm hỗ trợ chuyên nghiệp
- KHÔNG gợi ý cụ thể (tránh liability)

## Architecture

**Layered defense approach:** Client-side (Flutter) + Server-side (Node.js)

| Layer | Location | Purpose |
|-------|----------|---------|
| Primary | Flutter `SafetyGuardrailsService` | Intercept before send, UX warning |
| Secondary | Backend `safety-guardrails.service.ts` | Final check, logging, async safety injection |

## Detection Logic

### Method: Regex + Proximity Scoring

**Risk patterns (regex):**
```
(tự tử|tự sát|tự hại|tự gây thương tích)
(kill|end my life|don't want to live)
(khủng hoảng|cub bản thân|mất kiểm soát)
```

**Scoring:**
| Condition | Score |
|-----------|-------|
| Keyword alone | 1 |
| Keyword + intent context ("muốn", "định", "sẽ", "đang") | 3 |
| Keyword + urgency ("ngay", "bây giờ", "lập tức") | 5 |

**Threshold:** score ≥ 3 → trigger warning

## User Flow

```
User types message
    ↓
Flutter: SafetyGuardrailsService.check(message)
    ↓
Score < 3? → Proceed normally
Score ≥ 3?
    ↓
Show warning overlay:
"Mình thấy bạn đang trải qua giai đoạn khó khăn. 
Mình không phải chuyên gia tâm lý, nhưng mình ở đây để lắng nghe.
Nếu bạn cần hỗ trợ, hãy cân nhắc tìm kiếm người giúp đỡ."
    ↓
[ "Gửi tin nhắn này" ] [ "Tìm hiểu thêm" ]
    ↓
User chooses:
- Override → message sent to backend
- Learn more → show general support info
```

## Files

### Flutter (Client)

**Create:** `Bondy_App/lib/services/safety_guardrails_service.dart`
```dart
class SafetyGuardrailsService {
  SafetyCheckResult check(String message);
  bool shouldShowWarning(int score);
}

class SafetyCheckResult {
  final int score;
  final List<String> matchedPatterns;
  final bool shouldWarn;
}
```

**Modify:** `Bondy_App/lib/screens/chat/healing_chatbot_coach_screen.dart`
- Integrate `SafetyGuardrailsService.check()` before sending messages
- Show warning overlay when `shouldWarn == true`

### Backend (Server)

**Create:** `bondy_server/src/service/safety-guardrails.service.ts`
```typescript
interface SafetyCheckResult {
  riskScore: number;
  matchedPatterns: string[];
  requiresWarning: boolean;
}

export function checkForRisk(content: string): SafetyCheckResult
```

**Modify:** `bondy_server/src/service/ai-conversation.service.ts`
- Add guardrails check async alongside AI generation
- If `requiresWarning == true`, prepend safety message to AI response
- Log flagged messages for human review

## Warning Message

Vietnamese text only (no specific hotline/reference to avoid liability):

> "Mình thấy bạn đang trải qua giai đoạn khó khăn. Mình không phải chuyên gia tâm lý, nhưng mình ở đây để lắng nghe bạn. Nếu bạn cần hỗ trợ chuyên môn, hãy cân nhắc tìm kiếm người giúp đỡ phù hợp."

## What NOT to Do

- Không đóng vai therapist/bác sĩ
- Không chẩn đoán
- Không gợi ý specific hotline hoặc crisis center (liability risk)
- Không block hoàn toàn user message (user autonomy)

## Test Cases

| Input | Expected Score | Expected Behavior |
|-------|---------------|------------------|
| "Hôm nay mình buồn" | 0 | Proceed normally |
| "Mình đang tự tử" | 5 | Show warning |
| "Mình muốn tự hại bản thân" | 6 | Show warning |
| "Lo lắng về công việc" | 1 | Proceed normally |
| "Mình định khủng hoảng lắm" | 3 | Show warning |
| "Kill myself later" | 5 | Show warning |

## Status

- [x] Design complete
- [ ] Implementation pending
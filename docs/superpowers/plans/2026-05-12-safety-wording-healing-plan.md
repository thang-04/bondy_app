# Safety Wording Healing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement response guardrails to ensure AI Coach acts as empathetic companion, NOT medical professional. Detect crisis keywords, block forbidden patterns, return empathetic crisis response.

**Architecture:** ContentSafetyService analyzes text before display. SafetyGuardrails defines allowed/forbidden patterns. Crisis detection triggers empathetic response with resource referral.

**Tech Stack:** TypeScript, Node.js (bondy_server), Flutter (bondy_client)

---

## File Structure

```
bondy_server/src/
  dto/
    safety.dto.ts              # SafetyResult interface
  service/
    safety-guardrails.ts      # Allowed/forbidden pattern definitions
    content-safety.service.ts # Main safety service
  types/
    crisis-keywords.ts        # Crisis keyword lists

Bondy_App/lib/
  screens/chat/healing_chatbot_coach_screen.dart  # Update response handling
```

---

## Task 1: Define SafetyResult DTO

**Files:**
- Create: `bondy_server/src/dto/safety.dto.ts`
- Test: `bondy_server/tests/unit/dto/safety.dto.test.ts`

- [ ] **Step 1: Write the failing test**

```typescript
// tests/unit/dto/safety.dto.test.ts
import { describe, it, expect } from 'vitest';
import { SafetyResult } from '../../src/dto/safety.dto';

describe('SafetyResult', () => {
  it('should have correct shape for safe content', () => {
    const result: SafetyResult = {
      isSafe: true,
      isCrisis: false,
      isForbidden: false,
      originalText: 'Hello'
    };
    expect(result.isSafe).toBe(true);
    expect(result.isCrisis).toBe(false);
  });

  it('should have crisis response for crisis content', () => {
    const result: SafetyResult = {
      isSafe: false,
      isCrisis: true,
      isForbidden: false,
      originalText: 'I want to die',
      crisisResponse: 'Empathetic message',
      resources: ['1800-XXXX']
    };
    expect(result.isCrisis).toBe(true);
    expect(result.crisisResponse).toBeDefined();
    expect(result.resources).toHaveLength(1);
  });
});
```

Run: `cd bondy_server && npx vitest tests/unit/dto/safety.dto.test.ts -v`

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL with "SafetyResult not defined"

- [ ] **Step 3: Write implementation**

```typescript
// src/dto/safety.dto.ts
export interface SafetyResult {
  isSafe: boolean;
  isCrisis: boolean;
  isForbidden: boolean;
  originalText: string;
  safeText?: string;
  crisisResponse?: string;
  resources?: string[];
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd bondy_server && npx vitest tests/unit/dto/safety.dto.test.ts -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
cd bondy_server
git add src/dto/safety.dto.ts tests/unit/dto/safety.dto.test.ts
git commit -m "feat(safety): add SafetyResult DTO

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Task 2: Define Crisis Keywords

**Files:**
- Create: `bondy_server/src/types/crisis-keywords.ts`
- Test: `bondy_server/tests/unit/types/crisis-keywords.test.ts`

- [ ] **Step 1: Write the failing test**

```typescript
// tests/unit/types/crisis-keywords.test.ts
import { describe, it, expect } from 'vitest';
import { CRISIS_KEYWORDS, detectCrisis } from '../../src/types/crisis-keywords';

describe('CrisisKeywords', () => {
  it('should detect self-harm keywords', () => {
    expect(detectCrisis('tôi muốn tự tử')).toBe(true);
    expect(detectCrisis('tôi muốn chết')).toBe(true);
    expect(detectCrisis('I want to end my life')).toBe(true);
  });

  it('should detect abuse keywords', () => {
    expect(detectCrisis('bạn đánh đập tôi')).toBe(true);
    expect(detectCrisis('lạm dụng')).toBe(true);
  });

  it('should return false for normal text', () => {
    expect(detectCrisis('hôm nay trời đẹp')).toBe(false);
    expect(detectCrisis('tôi yêu bạn')).toBe(false);
  });
});
```

Run: `cd bondy_server && npx vitest tests/unit/types/crisis-keywords.test.ts -v`

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL with "CRISIS_KEYWORDS not defined"

- [ ] **Step 3: Write crisis keywords**

```typescript
// src/types/crisis-keywords.ts

export const CRISIS_KEYWORDS = {
  selfHarm: [
    'tự tử', 'tự hại', 'end my life', 'không muốn sống',
    'chết đi cho rồi', 'mệt mỏi với cuộc sống', 'tôi muốn chết',
    'kill myself', 'die', 'suicide'
  ],
  abuse: [
    'bạo lực', 'lạm dụng', 'đánh đập', 'bị hành hạ',
    'abuse', 'violence', 'hit me', 'hurt me'
  ],
  crisis: [
    'không có gì đáng sống', 'nothing to live for',
    'mệt mỏi với tất cả', 'give up on life'
  ]
};

export function detectCrisis(text: string): boolean {
  const lower = text.toLowerCase();
  return (
    CRISIS_KEYWORDS.selfHarm.some(k => lower.includes(k.toLowerCase())) ||
    CRISIS_KEYWORDS.abuse.some(k => lower.includes(k.toLowerCase())) ||
    CRISIS_KEYWORDS.crisis.some(k => lower.includes(k.toLowerCase()))
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd bondy_server && npx vitest tests/unit/types/crisis-keywords.test.ts -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
cd bondy_server
git add src/types/crisis-keywords.ts tests/unit/types/crisis-keywords.test.ts
git commit -m "feat(safety): add crisis keywords detection

Self-harm, abuse, crisis keyword lists.
detectCrisis() function for text analysis.
Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Task 3: Define Safety Guardrails

**Files:**
- Create: `bondy_server/src/service/safety-guardrails.ts`
- Test: `bondy_server/tests/unit/service/safety-guardrails.test.ts`

- [ ] **Step 1: Write the failing test**

```typescript
// tests/unit/service/safety-guardrails.test.ts
import { describe, it, expect } from 'vitest';
import { FORBIDDEN_PATTERNS, ALLOWED_PATTERNS, checkForbidden } from '../../src/service/safety-guardrails';

describe('SafetyGuardrails', () => {
  it('should detect medical diagnosis attempts', () => {
    expect(checkForbidden('bạn bị depression')).toBe(true);
    expect(checkForbidden('có vẻ bạn bị anxiety')).toBe(true);
  });

  it('should detect treatment suggestions', () => {
    expect(checkForbidden('thử therapy này đi')).toBe(true);
    expect(checkForbidden('meditation sẽ chữa được')).toBe(true);
  });

  it('should allow empathetic responses', () => {
    expect(checkForbidden('mình hiểu bạn đang khó khăn')).toBe(false);
    expect(checkForbidden('cảm ơn bạn đã chia sẻ')).toBe(false);
  });
});
```

Run: `cd bondy_server && npx vitest tests/unit/service/safety-guardrails.test.ts -v`

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL with "FORBIDDEN_PATTERNS not defined"

- [ ] **Step 3: Write guardrails**

```typescript
// src/service/safety-guardrails.ts

export const FORBIDDEN_PATTERNS = [
  // Medical diagnosis
  /bạn bị |bạn có|vietnamese.*(depression|anxiety|stress|ptsd|trauma)/i,
  /c ó  bạn (depression|anxiety|mental|hiv|hội chứng)/i,
  /you have (depression|anxiety|ptsd|bipolar|schizophrenia)/i,
  // Treatment suggestions without resources
  /thử (therapy|medication|psychiatry|điều trị)/i,
  /nên đi khám bác sĩ/i,
  /meditation sẽ chữa/i,
  /yoga chữa/i,
  // Professional replacement
  /tôi có thể giúp bạn (xử lý|điều trị|chữa)/i,
  /tôi là chuyên gia/i,
  // Medical advice
  /bạn nên (uống|dùng|làm)[\s\S]{0,20}(thuốc|bài tập|liệu pháp)/i
];

export const ALLOWED_PATTERNS = [
  /mình hiểu/i,
  /cảm ơn.*đã chia sẻ/i,
  /bạn có muốn/i,
  /nghe có vẻ/i,
  /nhiều người cũng/i,
  /mình ở đây/i,
  /tôi không phải/i
];

export function checkForbidden(text: string): boolean {
  return FORBIDDEN_PATTERNS.some(pattern => pattern.test(text));
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd bondy_server && npx vitest tests/unit/service/safety-guardrails.test.ts -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
cd bondy_server
git add src/service/safety-guardrails.ts tests/unit/service/safety-guardrails.test.ts
git commit -m "feat(safety): add safety guardrails

Forbidden patterns: medical diagnosis, treatment suggestions.
Allowed patterns: empathy, listening, support.
Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Task 4: Create ContentSafetyService

**Files:**
- Create: `bondy_server/src/service/content-safety.service.ts`
- Test: `bondy_server/tests/unit/service/content-safety.service.test.ts`

- [ ] **Step 1: Write the failing test**

```typescript
// tests/unit/service/content-safety.service.test.ts
import { describe, it, expect } from 'vitest';
import { ContentSafetyService } from '../../src/service/content-safety.service';

describe('ContentSafetyService', () => {
  const service = new ContentSafetyService();

  it('should return safe for normal text', () => {
    const result = service.analyze('mình hiểu bạn đang khó khăn');
    expect(result.isSafe).toBe(true);
  });

  it('should detect crisis and return empathetic response', () => {
    const result = service.analyze('tôi không muốn sống nữa');
    expect(result.isCrisis).toBe(true);
    expect(result.crisisResponse).toContain('mình');
    expect(result.resources).toBeDefined();
  });

  it('should block forbidden patterns', () => {
    const result = service.analyze('bạn bị depression');
    expect(result.isForbidden).toBe(true);
  });
});
```

Run: `cd bondy_server && npx vitest tests/unit/service/content-safety.service.test.ts -v`

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL with "ContentSafetyService not defined"

- [ ] **Step 3: Write ContentSafetyService**

```typescript
// src/service/content-safety.service.ts
import { SafetyResult } from '../dto/safety.dto';
import { detectCrisis } from '../types/crisis-keywords';
import { checkForbidden } from './safety-guardrails';

const CRISIS_RESOURCE_HOTLINE = '1800-XXXX (hỗ trợ 24/7)';
const CRISIS_RESOURCE_WEBSITE = 'psychology.org.vn';

const CRISIS_RESPONSE = `Mình thấy bạn đang trải qua điều rất khó khăn. 
Cảm ơn bạn đã tin tưởng chia sẻ với mình.

Mình là người đồng hành, không phải chuyên gia y tế.
Nếu bạn cần hỗ trợ chuyên sâu, có thể liên hệ:
📞 ${CRISIS_RESOURCE_HOTLINE}
🌐 ${CRISIS_RESOURCE_WEBSITE}

Mình vẫn ở đây nếu bạn muốn nói chuyện thêm.`;

export class ContentSafetyService {
  analyze(text: string): SafetyResult {
    // Check for crisis first
    if (detectCrisis(text)) {
      return {
        isSafe: false,
        isCrisis: true,
        isForbidden: false,
        originalText: text,
        crisisResponse: CRISIS_RESPONSE,
        resources: [CRISIS_RESOURCE_HOTLINE, CRISIS_RESOURCE_WEBSITE]
      };
    }

    // Check for forbidden patterns
    if (checkForbidden(text)) {
      return {
        isSafe: false,
        isCrisis: false,
        isForbidden: true,
        originalText: text,
        safeText: 'Mình hiểu bạn đang trải qua điều khó khăn. Bạn có muốn chia sẻ thêm không?'
      };
    }

    // Safe content
    return {
      isSafe: true,
      isCrisis: false,
      isForbidden: false,
      originalText: text
    };
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd bondy_server && npx vitest tests/unit/service/content-safety.service.test.ts -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
cd bondy_server
git add src/service/content-safety.service.ts tests/unit/service/content-safety.service.test.ts
git commit -m "feat(safety): add ContentSafetyService

Analyzes text for crisis keywords, forbidden patterns.
Returns SafetyResult with empathetic crisis response.
Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Task 5: Update Flutter Healing Chatbot

**Files:**
- Modify: `Bondy_App/lib/screens/chat/healing_chatbot_coach_screen.dart`

- [ ] **Step 1: Review current bot response logic**

Current code at line 181-198:
```dart
void _sendMessage() {
  if (_controller.text.isNotEmpty) {
    setState(() {
      _messages.add(_BotMessage(_controller.text, true));
      _controller.clear();
    });
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _messages.add(_BotMessage(
            'Cảm ơn bạn đã chia sẻ. Mình hiểu cảm giác đó. Hãy nhớ rằng, mỗi bước nhỏ đều là tiến bộ trên hành trình chữa lành. 🌿',
            false,
          ));
        });
      }
    });
  }
}
```

- [ ] **Step 2: Add safety check before bot response**

Replace the hardcoded response with safety-aware response. The safety check should happen on the server side (bondy_server), but for now we can add a simple Flutter-side check.

- [ ] **Step 3: Test the flow**

Verify the bot response is empathetic and doesn't make medical claims.

- [ ] **Step 4: Commit**

```bash
git add Bondy_App/lib/screens/chat/healing_chatbot_coach_screen.dart
git commit -m "fix(safety): update healing chatbot response to use safe messaging

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Task 6: Run All Tests

- [ ] **Step 1: Run all safety tests**

Run: `cd bondy_server && npx vitest run tests/unit/dto tests/unit/service/content-safety.service.test.ts tests/unit/service/safety-guardrails.test.ts tests/unit/types/crisis-keywords.test.ts`
Expected: All PASS

- [ ] **Step 2: Commit**

```bash
git add -A
git commit -m "test(safety): run all safety service tests

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Success Checklist

- [ ] SafetyResult DTO defined
- [ ] Crisis keywords defined and working
- [ ] Forbidden patterns defined and working
- [ ] ContentSafetyService implemented
- [ ] Crisis detection returns empathetic response with resources
- [ ] Forbidden pattern blocking works
- [ ] Unit tests pass

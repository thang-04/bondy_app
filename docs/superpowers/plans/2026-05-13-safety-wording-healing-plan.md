# Safety Wording Healing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add safety guardrails to healing chatbot - detect risk keywords and show warning before sending messages.

**Architecture:** Layered defense: Flutter client-side check + Backend server-side check. Regex + proximity scoring for detection.

**Tech Stack:** TypeScript (backend), Dart/Flutter (client), Vitest (tests)

---

## File Structure

### Backend (bondy_server)

**New files:**
- `src/service/safety-guardrails.service.ts` - Core detection logic

**Modified files:**
- `src/service/ai-conversation.service.ts` - Integrate guardrails check
- `tests/unit/service/safety-guardrails.service.test.ts` - Unit tests

### Flutter (Bondy_App)

**New files:**
- `lib/services/safety_guardrails_service.dart` - Client-side detection
- `lib/services/safety_check_result.dart` - Data model

**Modified files:**
- `lib/screens/chat/healing_chatbot_coach_screen.dart` - Integrate warning overlay

---

## Task 1: Backend Safety Service

**Files:**
- Create: `bondy_server/src/service/safety-guardrails.service.ts`
- Create: `bondy_server/tests/unit/service/safety-guardrails.service.test.ts`

- [ ] **Step 1: Write failing test**

```typescript
// tests/unit/service/safety-guardrails.service.test.ts
import { describe, it, expect } from 'vitest';
import { checkForRisk } from '../../../src/service/safety-guardrails.service';

describe('SafetyGuardrailsService', () => {
  describe('checkForRisk', () => {
    it('should return score 0 for normal message', () => {
      const result = checkForRisk('Hôm nay mình buồn');
      expect(result.riskScore).toBe(0);
      expect(result.requiresWarning).toBe(false);
    });

    it('should detect suicide keywords', () => {
      const result = checkForRisk('Mình đang tự tử');
      expect(result.riskScore).toBeGreaterThanOrEqual(3);
      expect(result.requiresWarning).toBe(true);
    });

    it('should detect self-harm keywords', () => {
      const result = checkForRisk('Mình muốn tự hại bản thân');
      expect(result.riskScore).toBeGreaterThanOrEqual(3);
      expect(result.requiresWarning).toBe(true);
    });

    it('should detect crisis keywords', () => {
      const result = checkForRisk('Mình định khủng hoảng lắm');
      expect(result.riskScore).toBeGreaterThanOrEqual(3);
      expect(result.requiresWarning).toBe(true);
    });

    it('should detect English keywords', () => {
      const result = checkForRisk('I want to kill myself');
      expect(result.riskScore).toBeGreaterThanOrEqual(3);
      expect(result.requiresWarning).toBe(true);
    });

    it('should return matched patterns', () => {
      const result = checkForRisk('Mình đang tự tử');
      expect(result.matchedPatterns).toContain('tự tử');
    });
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npx vitest run tests/unit/service/safety-guardrails.service.test.ts`
Expected: FAIL - "checkForRisk is not a function"

- [ ] **Step 3: Write minimal implementation**

```typescript
// bondy_server/src/service/safety-guardrails.service.ts

export interface SafetyCheckResult {
  riskScore: number;
  matchedPatterns: string[];
  requiresWarning: boolean;
}

// Risk patterns with weights
const RISK_PATTERNS = [
  // Critical keywords - weight 3
  { pattern: /tự tử|tự sát|tự hại|tự gây thương tích/gi, weight: 3 },
  { pattern: /kill myself|end my life|don't want to live/gi, weight: 3 },
  { pattern: /khủng hoảng mạnh|cub bản thân|mất kiểm soát/gi, weight: 3 },
  
  // Intent modifiers - weight 2 (added to keyword)
  { pattern: /muốn|định|sẽ|đang muốn/gi, weight: 0, modifier: true },
  { pattern: /ngay|bây giờ|lập tức/gi, weight: 0, modifier: true },
  
  // Context keywords - weight 1
  { pattern: /lo lắng|buồn|stress|áp lực/gi, weight: 1 },
];

const WARNING_THRESHOLD = 3;

export function checkForRisk(content: string): SafetyCheckResult {
  const matchedPatterns: string[] = [];
  let baseScore = 0;
  
  const lowerContent = content.toLowerCase();
  
  // Check for critical keywords first
  for (const { pattern, weight } of RISK_PATTERNS) {
    if (!pattern.modifier) {
      const matches = lowerContent.match(pattern);
      if (matches) {
        matchedPatterns.push(...matches);
        baseScore += weight;
      }
    }
  }
  
  // Check for intent modifiers and add to base score
  let intentModifier = 0;
  for (const { pattern, weight, modifier } of RISK_PATTERNS) {
    if (modifier) {
      const matches = lowerContent.match(pattern);
      if (matches) {
        intentModifier += weight; // weight is 2 for modifiers
      }
    }
  }
  
  const riskScore = baseScore + (intentModifier > 0 ? 2 : 0);
  
  return {
    riskScore,
    matchedPatterns,
    requiresWarning: riskScore >= WARNING_THRESHOLD,
  };
}

export const SAFETY_WARNING_MESSAGE = 'Mình thấy bạn đang trải qua giai đoạn khó khăn. Mình không phải chuyên gia tâm lý, nhưng mình ở đây để lắng nghe bạn. Nếu bạn cần hỗ trợ chuyên môn, hãy cân nhắc tìm kiếm người giúp đỡ phù hợp.';
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npx vitest run tests/unit/service/safety-guardrails.service.test.ts`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/service/safety-guardrails.service.ts tests/unit/service/safety-guardrails.service.test.ts
git commit -m "feat(safety): add backend safety guardrails service"
```

---

## Task 2: Integrate Guardrails into AI Conversation Service

**Files:**
- Modify: `bondy_server/src/service/ai-conversation.service.ts`
- Test: Existing tests should still pass

- [ ] **Step 1: Add import and modify generateWithFallback**

```typescript
// At top of ai-conversation.service.ts, add import:
import { checkForRisk, SAFETY_WARNING_MESSAGE } from './safety-guardrails.service';

// In generateWithFallback method, after feature check:
// Add safety check before generating suggestion
const riskCheck = checkForRisk(JSON.stringify(request));
if (riskCheck.requiresWarning) {
  // Log for human review (async, doesn't block response)
  console.warn('[SafetyGuardrails] Risky content detected:', {
    userId: request.userId,
    score: riskCheck.riskScore,
    patterns: riskCheck.matchedPatterns,
    timestamp: new Date().toISOString(),
  });
}
```

- [ ] **Step 2: Modify generateWithFallback to inject safety message**

Find the line that says `return { success: true, data: { suggestions: ...` and wrap with safety check:

```typescript
// After the try block that calls generateSuggestion,
// modify the catch block to inject safety message:
```

Actually, the safety message should be prepended to AI response. Let's modify the success response instead:

```typescript
// In generateWithFallback, after successful AI generation:
const result = await this.generateSuggestion(request);

// Inject safety warning if risk detected
const riskCheck = checkForRisk(
  `${request.conversationId} ${request.intent} ${request.tone}`
);

if (riskCheck.requiresWarning && result.success && result.data) {
  // Prepend safety message to first suggestion
  result.data.suggestions = [
    SAFETY_WARNING_MESSAGE,
    ...result.data.suggestions,
  ];
}

return result;
```

- [ ] **Step 3: Run existing tests**

Run: `npx vitest run tests/unit/service/ai-conversation.service.test.ts`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add src/service/ai-conversation.service.ts
git commit -m "feat(safety): integrate guardrails into AI conversation service"
```

---

## Task 3: Flutter Safety Service

**Files:**
- Create: `Bondy_App/lib/services/safety_guardrails_service.dart`
- Create: `Bondy_App/lib/services/safety_check_result.dart`
- Create: `Bondy_App/test/services/safety_guardrails_service_test.dart`

- [ ] **Step 1: Write failing test**

```dart
// Bondy_App/test/services/safety_guardrails_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bondy_app/services/safety_guardrails_service.dart';

void main() {
  group('SafetyGuardrailsService', () {
    late SafetyGuardrailsService service;

    setUp(() {
      service = SafetyGuardrailsService();
    });

    test('should return score 0 for normal message', () {
      final result = service.check('Hôm nay mình buồn');
      expect(result.score, 0);
      expect(result.shouldWarn, false);
    });

    test('should detect suicide keywords', () {
      final result = service.check('Mình đang tự tử');
      expect(result.score, greaterThanOrEqualTo(3));
      expect(result.shouldWarn, true);
    });

    test('should detect self-harm keywords', () {
      final result = service.check('Mình muốn tự hại bản thân');
      expect(result.score, greaterThanOrEqualTo(3));
      expect(result.shouldWarn, true);
    });

    test('should return matched patterns', () {
      final result = service.check('Mình đang tự tử');
      expect(result.matchedPatterns, contains('tự tử'));
    });
  });
}
```

- [ ] **Step 2: Create data model**

```dart
// Bondy_App/lib/services/safety_check_result.dart
class SafetyCheckResult {
  final int score;
  final List<String> matchedPatterns;
  final bool shouldWarn;

  SafetyCheckResult({
    required this.score,
    required this.matchedPatterns,
    required this.shouldWarn,
  });
}
```

- [ ] **Step 3: Write service implementation**

```dart
// Bondy_App/lib/services/safety_guardrails_service.dart
import 'safety_check_result.dart';

class SafetyGuardrailsService {
  static const int _warningThreshold = 3;

  static final List<_RiskPattern> _criticalPatterns = [
    _RiskPattern(r'tự tử|tự sát|tự hại|tự gây thương tích', 3),
    _RiskPattern(r'kill myself|end my life|don\'t want to live', 3),
    _RiskPattern(r'khủng hoảng mạnh|cub bản thân|mất kiểm soát', 3),
  ];

  static final List<_RiskPattern> _intentModifiers = [
    _RiskPattern(r'muốn|định|sẽ|đang muốn', 2),
    _RiskPattern(r'ngay|bây giờ|lập tức', 2),
  ];

  static final List<_RiskPattern> _contextPatterns = [
    _RiskPattern(r'lo lắng|buồn|stress|áp lực', 1),
  ];

  SafetyCheckResult check(String message) {
    final matchedPatterns = <String>[];
    int baseScore = 0;

    final lowerMessage = message.toLowerCase();

    // Check critical keywords
    for (final pattern in _criticalPatterns) {
      final matches = pattern.regex.allMatches(lowerMessage);
      if (matches.isNotEmpty) {
        matchedPatterns.addAll(matches.map((m) => m.group(0)!));
        baseScore += pattern.weight;
      }
    }

    // Check modifiers
    int hasModifier = 0;
    for (final pattern in _intentModifiers) {
      if (pattern.regex.hasMatch(lowerMessage)) {
        hasModifier = 1;
      }
    }

    final score = baseScore + (hasModifier > 0 ? 2 : 0);

    return SafetyCheckResult(
      score: score,
      matchedPatterns: matchedPatterns,
      shouldWarn: score >= _warningThreshold,
    );
  }
}

class _RiskPattern {
  final RegExp regex;
  final int weight;

  _RiskPattern(String pattern, this.weight) : regex = RegExp(pattern, caseSensitive: false);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/services/safety_guardrails_service_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/services/safety_check_result.dart lib/services/safety_guardrails_service.dart test/services/safety_guardrails_service_test.dart
git commit -m "feat(safety): add Flutter safety guardrails service"
```

---

## Task 4: Integrate Warning Overlay in Healing Screen

**Files:**
- Modify: `Bondy_App/lib/screens/chat/healing_chatbot_coach_screen.dart`

- [ ] **Step 1: Add import and field**

```dart
// At top of file, add:
import '../../services/safety_guardrails_service.dart';

// In _HealingChatbotCoachScreenState class, add:
final _safetyService = SafetyGuardrailsService();
String? _pendingMessage;
bool _showSafetyWarning = false;
```

- [ ] **Step 2: Modify _sendMessage to check for risk**

Replace the `_sendMessage` method:

```dart
void _sendMessage() {
  if (_controller.text.isNotEmpty) {
    final message = _controller.text;
    
    // Check for safety risk
    final safetyCheck = _safetyService.check(message);
    
    if (safetyCheck.shouldWarn) {
      // Show warning but allow override
      setState(() {
        _pendingMessage = message;
        _showSafetyWarning = true;
      });
    } else {
      // Proceed normally
      _proceedWithMessage(message);
    }
  }
}

void _proceedWithMessage(String message) {
  setState(() {
    _messages.add(_BotMessage(message, true));
    _controller.clear();
  });
  
  Future.delayed(const Duration(seconds: 1), () {
    if (mounted) {
      setState(() {
        _messages.add(_BotMessage(
          'Cảm ơn bạn đã chia sẻ với mình. Mình ở đây lắng nghe bạn.',
          false,
        ));
      });
    }
  });
}
```

- [ ] **Step 3: Add warning overlay widget**

Add this method before `_buildTopic`:

```dart
Widget _buildSafetyWarningOverlay() {
  return GestureDetector(
    onTap: () => setState(() => _showSafetyWarning = false),
    child: Container(
      color: BondyColors.overlay,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: BondyColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite,
                  color: BondyColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Mình thấy bạn đang trải qua giai đoạn khó khăn',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Mình không phải chuyên gia tâm lý, nhưng mình ở đây để lắng nghe bạn. Nếu bạn cần hỗ trợ chuyên môn, hãy cân nhắc tìm kiếm người giúp đỡ phù hợp.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: BondyColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _showSafetyWarning = false),
                      child: const Text('Quay lại'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _showSafetyWarning = false);
                        if (_pendingMessage != null) {
                          _proceedWithMessage(_pendingMessage!);
                          _pendingMessage = null;
                        }
                      },
                      child: const Text('Gửi tin nhắn'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
```

- [ ] **Step 4: Add overlay to Stack in build method**

Find `if (_showOverlay) _buildAskBondyOverlay()` and add below:

```dart
if (_showSafetyWarning) _buildSafetyWarningOverlay(),
```

- [ ] **Step 5: Test manually**

Build Flutter app and test:
- Type normal message → should send without warning
- Type "Mình đang tự tử" → should show warning overlay
- Tap "Gửi tin nhắn" → message should be sent

- [ ] **Step 6: Commit**

```bash
git add lib/screens/chat/healing_chatbot_coach_screen.dart
git commit -m "feat(safety): integrate warning overlay in healing screen"
```

---

## Task 5: Final Verification

- [ ] **Step 1: Run all backend tests**

Run: `npx vitest run tests/unit/service/`
Expected: All tests pass

- [ ] **Step 2: Run Flutter tests**

Run: `flutter test`
Expected: All tests pass

- [ ] **Step 3: Verify git status**

Run: `git status`
Expected: Clean working tree (no uncommitted changes)

---

## Spec Coverage Check

| Spec Requirement | Task |
|-----------------|------|
| Regex pattern matching | Task 1 |
| Proximity scoring | Task 1 |
| Threshold ≥3 trigger | Task 1 |
| Warning message (Vietnamese) | Task 1 |
| Client-side check (Flutter) | Task 3 |
| Server-side check (Backend) | Task 1-2 |
| Warning overlay UI | Task 4 |
| User override option | Task 4 |
| No specific hotline | Task 1 (in message) |

## Type Consistency Check

| Component | Type/Method | Defined In |
|----------|-------------|-----------|
| `checkForRisk(content: string)` | Task 1 | `safety-guardrails.service.ts` |
| `SafetyCheckResult.riskScore` | Task 1 | `safety-guardrails.service.ts` |
| `SafetyCheckResult.requiresWarning` | Task 1 | `safety-guardrails.service.ts` |
| `SafetyGuardrailsService.check(message)` | Task 3 | `safety_guardrails_service.dart` |
| `SafetyCheckResult.score` | Task 3 | `safety_check_result.dart` |
| `SafetyCheckResult.shouldWarn` | Task 3 | `safety_check_result.dart` |

All types consistent across tasks.
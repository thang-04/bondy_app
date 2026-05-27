# Safety Wording Healing Design

**Issue:** bondy-jdi  
**Status:** Approved  
**Date:** 2026-05-12

---

## 1. Overview

Rà soát toàn bộ text Healing để không đóng vai bác sĩ/therapist. Nội dung an toàn, không chẩn đoán hoặc xử lý khủng hoảng ngoài phạm vi app. Nếu user nhập nội dung nguy cơ cao, trả khuyến nghị tìm hỗ trợ chuyên nghiệp.

**Vision:** Bondy Coach là người bạn đồng hành tâm sự — đồng cảm, điều phối cảm xúc, KHÔNG phải therapist/doctor.

---

## 2. Two-Pronged Approach

```
PHASE 1: Text Audit              PHASE 2: Guardrails
─────────────────────           ─────────────────────
• Read existing healing text      • Define AI can/cannot say
• Flag unsafe patterns           • Implement ContentSafetyService
• Update/fix text               • Enforce in response generation
```

---

## 3. Response Guardrails

### AI ĐƯỢC NÓI (Allowed Patterns)
```
✓ Empathetic: "Mình hiểu bạn đang khó khăn"
✓ Gratitude: "Cảm ơn bạn đã chia sẻ với mình"
✓ Open-ended: "Bạn có muốn nói thêm về điều này?"
✓ Reflecting: "Nghe có vẻ bạn đang cảm thấy..."
✓ Normalizing: "Nhiều người cũng trải qua điều này"
✓ Presence: "Mình ở đây lắng nghe bạn"
```

### AI KHÔNG ĐƯỢC NÓI (Forbidden Patterns)
```
✗ Medical diagnosis: "bạn bị depression/anxiety"
✗ Treatment suggestions: "thử therapy/medication này"
✗ Professional替代: "bạn nên đi khám bác sĩ" (phải kèm hotline)
✗ Crisis handling beyond scope: "tôi có thể giúp bạn xử lý"
✗ Medical advice: "thiền sẽ chữa được anxiety của bạn"
```

---

## 4. Crisis Detection + Response

### Detection Keywords
| Category | Keywords |
|----------|----------|
| Self-harm | "tự tử", "tự hại", "end my life", "không muốn sống", "chết đi cho rồi" |
| Abuse | "bạo lực", "lạm dụng", "đánh đập" |
| Crisis | "mệt mỏi với cuộc sống", "không có gì đáng sống" |

### Crisis Response Flow
```
User input
    │
    ▼
ContentSafetyService.analyze(text)
    │
    ├── Crisis detected?
    │     └── Return SafetyResult { isCrisis: true, response: empathetic + resource }
    │
    ├── Forbidden pattern detected?
    │     └── Return SafetyResult { isForbidden: true, safeVersion }
    │
    └── Safe?
          └── Return SafetyResult { isSafe: true, originalText }
```

### Crisis Response (Empathetic + Resource)
```
"Mình thấy bạn đang trải qua điều rất khó khăn. 
Cảm ơn bạn đã tin tưởng chia sẻ với mình.

Mình là người đồng hành, không phải chuyên gia y tế.
Nếu bạn cần hỗ trợ chuyên sâu, có thể liên hệ:
📞 1800-XXXX (hỗ trợ 24/7)
🌐 psychology.org.vn

Mình vẫn ở đây nếu bạn muốn nói chuyện thêm."
```

---

## 5. Text Audit Findings

### Files Reviewed
- `Bondy_App/lib/screens/chat/healing_chatbot_coach_screen.dart`
- `Bondy_App/lib/screens/healing/content_hub_library_screen.dart`

### Issues Found
| File | Line | Issue | Severity | Fix |
|------|------|-------|----------|-----|
| healing_chatbot_coach_screen.dart | 192 | "Hãy nhớ rằng, mỗi bước nhỏ đều là tiến bộ trên hành trình chữa lành" | Low | ✅ Acceptable - general encouragement |
| content_hub_library_screen.dart | 97 | "5 bước chữa lành sau chia tay" | Low | ⚠️ "chữa lành" borderline but acceptable as wellness |

**Status: No major violations found.** Current text is mostly safe.

---

## 6. File Structure

```
bondy_server/src/
  service/
    content-safety.service.ts    # Main safety service
    safety-guardrails.ts        # Allowed/forbidden patterns
  dto/
    safety.dto.ts               # SafetyResult type

Bondy_App/lib/
  screens/chat/healing_chatbot_coach_screen.dart  # Update response handling
  screens/healing/content_hub_library_screen.dart # Safe text check
```

---

## 7. SafetyResult Type

```typescript
interface SafetyResult {
  isSafe: boolean;
  isCrisis: boolean;
  isForbidden: boolean;
  originalText: string;
  safeText?: string;          // If forbidden pattern detected
  crisisResponse?: string;     // If crisis detected
  resources?: string[];       // Hotlines, websites
}
```

---

## 8. Success Criteria

- [ ] Text audit completed - no major violations
- [ ] ContentSafetyService implemented
- [ ] Crisis keywords detected
- [ ] Forbidden patterns blocked
- [ ] Crisis response is empathetic + provides resources
- [ ] Unit tests pass

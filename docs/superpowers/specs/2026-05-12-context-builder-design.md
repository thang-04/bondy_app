# Context Builder tối thiểu Design

**Issue:** bondy-r38  
**Status:** Approved  
**Date:** 2026-05-12

---

## 1. Overview

Lấy profile public, common interests, survey summary ngắn, 3–5 messages gần nhất để build AI context.

**Kết quả mong muốn:** AI context đủ dùng nhưng không gửi quá nhiều dữ liệu nhạy cảm.

**Ghi chú:** Không gửi toàn bộ lịch sử chat hoặc raw survey không cần thiết.

---

## 2. Architecture

```
Request → ContextBuilder.build(userId, chatId)
                    │
        ┌───────────┼───────────┐
        ▼           ▼           ▼
   getProfile   getInterests  getSurvey   getRecentMessages
        │           │           │              │
        └───────────┴───────────┴──────────────┘
                        │
                        ▼
               SanitizeContext()
                        │
                        ▼
                  AiContext (JSON)
```

---

## 3. Interface

```typescript
interface AiContext {
  userProfile: {
    displayName: string;
    ageRange: string;        // "25-30" thay vì "1995"
    gender: string;
    bio?: string;
  };
  interests: string[];       // Tags từ survey, không phải raw answers
  preferences: {
    communicationStyle: string;
    loveLanguage: string;
    relationshipGoals: string;
  };
  recentMessages: {
    content: string;
    isFromMe: boolean;
    timestamp: string;
  }[];
}

class ContextBuilder {
  async build(userId: string, chatId: string): Promise<AiContext>
}
```

---

## 4. Data Sources

### 4.1 User Profile (từ profile.repository.ts)
- `displayName`: firstName + lastName
- `ageRange`: compute từ birthDate → age range (18-22, 23-27, 28-32, etc)
- `gender`: từ profile
- `bio`: từ profile (public info only)

### 4.2 Interests (từ survey.repository.ts)
- Lấy tags từ survey answers
- Không gửi raw survey responses
- Chỉ list of interest tags

### 4.3 Survey Summary (từ survey.repository.ts)
Preferences được trích xuất:
- `communicationStyle`: từ survey answers
- `loveLanguage`: từ survey answers
- `relationshipGoals`: từ survey answers

### 4.4 Recent Messages (từ chat.repository.ts)
- Lấy 3-5 messages gần nhất (configurable)
- Mỗi message: content, isFromMe, timestamp
- Không gửi full chat history

---

## 5. Sanitization Rules

| Field | Raw | Sanitized |
|-------|-----|-----------|
| birthDate | "1995-03-15" | "25-30" (age range) |
| location | "123 Nguyen Hue, District 1" | "Ho Chi Minh City" (city only) |
| interests | [full survey answers array] | [interest tags only] |
| messages | [all chat history] | [last 3-5 messages] |
| phone/email | "0909123456" | REMOVED |
| income/financial | any | REMOVED |
| health info | any | REMOVED |

**PRINCIPLE: Zero sensitive data - only aggregated/anonymized tags**

---

## 6. Output Schema

```typescript
// ContextBuilder.build() returns:
{
  userProfile: {
    displayName: string;      // "Minh"
    ageRange: string;         // "25-30"
    gender: string;          // "male"
    bio?: string;            // truncated, public info only
  },
  interests: string[],       // ["travel", "cooking", "music"]
  preferences: {
    communicationStyle: string;  // e.g. "open", "reserved"
    loveLanguage: string;        // e.g. "words", "acts", "time"
    relationshipGoals: string;    // e.g. "long-term", "casual"
  },
  recentMessages: [
    {
      content: string;       // truncated to 200 chars if needed
      isFromMe: boolean;
      timestamp: string;     // ISO 8601
    }
  ]
}
```

---

## 7. File Structure

```
src/
  service/
    context-builder.service.ts    # Main ContextBuilder class
  repository/
    survey.repository.ts         # Add getSurveyTags(), getPreferences()
  dto/
    context.dto.ts               # AiContext interface
```

---

## 8. Dependencies

- `profile.repository.ts` — exists, getPublicProfile()
- `survey.repository.ts` — exists, needs new methods
- `chat.repository.ts` — exists, listMessages()
- bondy-711: IAiProvider (used by AiService)

---

## 9. Error Handling

- If profile not found: throw Error with userId
- If chat not found: throw Error with chatId
- If survey not taken: return empty interests/preferences
- If no messages: return empty recentMessages array

---

## 10. Success Criteria

- [ ] ContextBuilder.build() returns AiContext
- [ ] No sensitive data in output (age as range, no raw survey)
- [ ] Recent messages limited to 3-5
- [ ] All data properly sanitized
- [ ] Unit tests pass

# Lưu AiSuggestion Design

**Issue:** bondy-bf8  
**Status:** Approved  
**Date:** 2026-05-12

---

## 1. Overview

Thêm/lưu record AiSuggestion với userId, chatId, intent, inputContext, outputSuggestions, status. Có lịch sử gợi ý để audit/debug. Nếu AI fail vẫn có thể log status FAILED.

---

## 2. Prisma Model

```prisma
model AiSuggestion {
  id              String   @id @default(uuid())
  userId          String
  chatId          String
  intent          String               // e.g., "opener", "continue", "deepen"
  inputContext    Json?                // sanitized context from ContextBuilder
  outputSuggestions Json?               // JSON array of suggestions from AI
  provider        String?               // e.g., "mock", "gemini", "openai"
  tokensUsed      Int?
  latencyMs       Int?
  status          AiSuggestionStatus
  errorMessage    String?
  createdAt       DateTime @default(now())
  updatedAt       DateTime @updatedAt

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)
  chat Chat @relation(fields: [chatId], references: [id], onDelete: Cascade)
}

enum AiSuggestionStatus {
  PENDING
  SUCCESS
  FAILED
  SKIPPED
}
```

---

## 3. Repository

```typescript
// src/repository/ai-suggestion.repository.ts

export interface CreateAiSuggestionInput {
  userId: string;
  chatId: string;
  intent: string;
  inputContext?: object;
  outputSuggestions?: string[];
  provider?: string;
  tokensUsed?: number;
  latencyMs?: number;
  status: AiSuggestionStatus;
  errorMessage?: string;
}

export interface AiSuggestionRepository {
  create(input: CreateAiSuggestionInput): Promise<AiSuggestion>;
  findByUserId(userId: string, limit?: number): Promise<AiSuggestion[]>;
  findByChatId(chatId: string, limit?: number): Promise<AiSuggestion[]>;
  updateStatus(id: string, status: AiSuggestionStatus, output?: Partial<AiSuggestion>): Promise<AiSuggestion>;
}
```

---

## 4. Service

```typescript
// src/service/ai-suggestion.service.ts

export class AiSuggestionService {
  async saveSuggestion(input: CreateAiSuggestionInput): Promise<AiSuggestion> {
    return aiSuggestionRepository.create(input);
  }

  async markSuccess(id: string, output: { suggestions: string[]; tokensUsed: number; latencyMs: number }): Promise<AiSuggestion> {
    return aiSuggestionRepository.updateStatus(id, 'SUCCESS', output);
  }

  async markFailed(id: string, errorMessage: string): Promise<AiSuggestion> {
    return aiSuggestionRepository.updateStatus(id, 'FAILED', { errorMessage });
  }

  async getUserHistory(userId: string, limit?: number): Promise<AiSuggestion[]> {
    return aiSuggestionRepository.findByUserId(userId, limit);
  }
}
```

---

## 5. Workflow Integration

```
AiService.generateSuggestion()
    │
    ├── Create AiSuggestion record (status: PENDING)
    │
    ├── Call AI Provider
    │
    ├── If success:
    │     └── updateStatus(SUCCESS, { suggestions, tokens, latency })
    │
    └── If failed:
          └── updateStatus(FAILED, { errorMessage })
```

---

## 6. File Structure

```
bondy_server/prisma/schema.prisma    # Add AiSuggestion model
bondy_server/src/
  repository/
    ai-suggestion.repository.ts       # AiSuggestionRepository
  service/
    ai-suggestion.service.ts         # AiSuggestionService
  dto/
    ai-suggestion.dto.ts              # CreateInput, Response types
```

---

## 7. Success Criteria

- [ ] AiSuggestion Prisma model created
- [ ] Repository with CRUD operations
- [ ] Service with saveSuggestion, markSuccess, markFailed
- [ ] Workflow integrated (AiService calls these before/after AI generate)
- [ ] Unit tests pass

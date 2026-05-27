# AiSuggestion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Prisma model, repository, and service for storing AI suggestions with status tracking (PENDING → SUCCESS/FAILED).

**Architecture:** Prisma model + Repository pattern + Service layer. Workflow: AiService creates PENDING record before AI call, updates to SUCCESS/FAILED after.

**Tech Stack:** TypeScript, Prisma, Node.js, vitest

---

## File Structure

```
bondy_server/prisma/schema.prisma         # Add AiSuggestion model
bondy_server/src/
  dto/ai-suggestion.dto.ts                # CreateInput types
  repository/ai-suggestion.repository.ts  # CRUD operations
  service/ai-suggestion.service.ts       # Business logic
```

---

## Task 1: Add Prisma AiSuggestion Model

**Files:**
- Modify: `bondy_server/prisma/schema.prisma`
- Test: `bondy_server/tests/unit/repository/ai-suggestion.repository.test.ts`

- [ ] **Step 1: Write the test**

```typescript
// tests/unit/repository/ai-suggestion.repository.test.ts
import { describe, it, expect } from 'vitest';

describe('AiSuggestion Model', () => {
  it('should define AiSuggestionStatus enum', () => {
    const statuses = ['PENDING', 'SUCCESS', 'FAILED', 'SKIPPED'];
    expect(statuses).toContain('PENDING');
    expect(statuses).toContain('SUCCESS');
    expect(statuses).toContain('FAILED');
  });

  it('should have required fields', () => {
    const suggestion = {
      id: 'uuid',
      userId: 'user-123',
      chatId: 'chat-456',
      intent: 'opener',
      status: 'PENDING'
    };
    expect(suggestion.userId).toBeDefined();
    expect(suggestion.chatId).toBeDefined();
    expect(suggestion.intent).toBeDefined();
    expect(suggestion.status).toBeDefined();
  });
});
```

Run: `npx vitest tests/unit/repository/ai-suggestion.repository.test.ts -v`

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL if model not yet defined

- [ ] **Step 3: Add to schema.prisma**

```prisma
model AiSuggestion {
  id              String   @id @default(uuid())
  userId          String
  chatId          String
  intent          String
  inputContext    Json?
  outputSuggestions Json?
  provider        String?
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

**Note:** Add at end of schema.prisma before the closing bracket. Also add relations to User and Chat models.

- [ ] **Step 4: Run Prisma migrate**

Run: `cd bondy_server && npx prisma db push`
Expected: Model created in database

- [ ] **Step 5: Commit**

```bash
git add bondy_server/prisma/schema.prisma
git commit -m "feat(ai-suggestion): add AiSuggestion Prisma model

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Task 2: Create DTO

**Files:**
- Create: `bondy_server/src/dto/ai-suggestion.dto.ts`
- Test: `bondy_server/tests/unit/dto/ai-suggestion.dto.test.ts`

- [ ] **Step 1: Write the failing test**

```typescript
// tests/unit/dto/ai-suggestion.dto.test.ts
import { describe, it, expect } from 'vitest';
import { CreateAiSuggestionInput, AiSuggestionStatus } from '../../../src/dto/ai-suggestion.dto';

describe('AiSuggestion DTO', () => {
  it('should have CreateAiSuggestionInput with required fields', () => {
    const input: CreateAiSuggestionInput = {
      userId: 'user-123',
      chatId: 'chat-456',
      intent: 'opener',
      status: AiSuggestionStatus.PENDING
    };
    expect(input.userId).toBe('user-123');
    expect(input.chatId).toBe('chat-456');
    expect(input.intent).toBe('opener');
    expect(input.status).toBe(AiSuggestionStatus.PENDING);
  });
});
```

Run: `npx vitest tests/unit/dto/ai-suggestion.dto.test.ts -v`

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL with "AiSuggestionStatus not defined"

- [ ] **Step 3: Write DTO**

```typescript
// src/dto/ai-suggestion.dto.ts
export enum AiSuggestionStatus {
  PENDING = 'PENDING',
  SUCCESS = 'SUCCESS',
  FAILED = 'FAILED',
  SKIPPED = 'SKIPPED'
}

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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npx vitest tests/unit/dto/ai-suggestion.dto.test.ts -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/dto/ai-suggestion.dto.ts tests/unit/dto/ai-suggestion.dto.test.ts
git commit -m "feat(ai-suggestion): add CreateAiSuggestionInput DTO

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Task 3: Create Repository

**Files:**
- Create: `bondy_server/src/repository/ai-suggestion.repository.ts`
- Test: `bondy_server/tests/unit/repository/ai-suggestion.repository.test.ts`

- [ ] **Step 1: Write the failing test**

```typescript
// tests/unit/repository/ai-suggestion.repository.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { aiSuggestionRepository } from '../../../src/repository/ai-suggestion.repository';
import { CreateAiSuggestionInput, AiSuggestionStatus } from '../../../src/dto/ai-suggestion.dto';

// Mock prisma
vi.mock('../../../src/lib/prisma', () => ({
  default: {
    aiSuggestion: {
      create: vi.fn().mockResolvedValue({ id: 'new-id' }),
      findMany: vi.fn().mockResolvedValue([]),
      findFirst: vi.fn().mockResolvedValue(null),
      update: vi.fn().mockResolvedValue({ id: 'updated-id' }),
    }
  }
}));

describe('AiSuggestionRepository', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('should create suggestion with correct input', async () => {
    const input: CreateAiSuggestionInput = {
      userId: 'user-123',
      chatId: 'chat-456',
      intent: 'opener',
      status: AiSuggestionStatus.PENDING
    };
    const result = await aiSuggestionRepository.create(input);
    expect(result.id).toBe('new-id');
  });

  it('should findByUserId', async () => {
    const results = await aiSuggestionRepository.findByUserId('user-123');
    expect(Array.isArray(results)).toBe(true);
  });

  it('should findByChatId', async () => {
    const results = await aiSuggestionRepository.findByChatId('chat-456');
    expect(Array.isArray(results)).toBe(true);
  });
});
```

Run: `npx vitest tests/unit/repository/ai-suggestion.repository.test.ts -v`

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL with "aiSuggestionRepository not defined"

- [ ] **Step 3: Write Repository**

```typescript
// src/repository/ai-suggestion.repository.ts
import { prisma } from '../lib/prisma';
import { CreateAiSuggestionInput, AiSuggestionStatus } from '../dto/ai-suggestion.dto';

export interface AiSuggestionRepository {
  create(input: CreateAiSuggestionInput): Promise<any>;
  findByUserId(userId: string, limit?: number): Promise<any[]>;
  findByChatId(chatId: string, limit?: number): Promise<any[]>;
  updateStatus(id: string, status: AiSuggestionStatus, extra?: Partial<any>): Promise<any>;
}

export const aiSuggestionRepository: AiSuggestionRepository = {
  async create(input: CreateAiSuggestionInput) {
    return prisma.aiSuggestion.create({ data: input });
  },

  async findByUserId(userId: string, limit = 50) {
    return prisma.aiSuggestion.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: limit
    });
  },

  async findByChatId(chatId: string, limit = 20) {
    return prisma.aiSuggestion.findMany({
      where: { chatId },
      orderBy: { createdAt: 'desc' },
      take: limit
    });
  },

  async updateStatus(id: string, status: AiSuggestionStatus, extra = {}) {
    return prisma.aiSuggestion.update({
      where: { id },
      data: { status, ...extra }
    });
  }
};
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npx vitest tests/unit/repository/ai-suggestion.repository.test.ts -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/repository/ai-suggestion.repository.ts tests/unit/repository/ai-suggestion.repository.test.ts
git commit -m "feat(ai-suggestion): add AiSuggestionRepository

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Task 4: Create Service

**Files:**
- Create: `bondy_server/src/service/ai-suggestion.service.ts`
- Test: `bondy_server/tests/unit/service/ai-suggestion.service.test.ts`

- [ ] **Step 1: Write the failing test**

```typescript
// tests/unit/service/ai-suggestion.service.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { AiSuggestionService } from '../../../src/service/ai-suggestion.service';
import { AiSuggestionStatus } from '../../../src/dto/ai-suggestion.dto';

// Mock repository
vi.mock('../../../src/repository/ai-suggestion.repository', () => ({
  aiSuggestionRepository: {
    create: vi.fn().mockResolvedValue({ id: 'new-id' }),
    updateStatus: vi.fn().mockResolvedValue({ id: 'updated-id' }),
    findByUserId: vi.fn().mockResolvedValue([]),
  }
}));

describe('AiSuggestionService', () => {
  let service: AiSuggestionService;

  beforeEach(() => {
    service = new AiSuggestionService();
    vi.clearAllMocks();
  });

  it('should save suggestion', async () => {
    const result = await service.saveSuggestion({
      userId: 'user-123',
      chatId: 'chat-456',
      intent: 'opener',
      status: AiSuggestionStatus.PENDING
    });
    expect(result.id).toBe('new-id');
  });

  it('should mark success', async () => {
    const result = await service.markSuccess('suggestion-id', {
      suggestions: ['Hello', 'Hi there'],
      tokensUsed: 50,
      latencyMs: 200
    });
    expect(result.id).toBe('updated-id');
  });

  it('should mark failed', async () => {
    const result = await service.markFailed('suggestion-id', 'AI timeout');
    expect(result.id).toBe('updated-id');
  });
});
```

Run: `npx vitest tests/unit/service/ai-suggestion.service.test.ts -v`

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL with "AiSuggestionService not defined"

- [ ] **Step 3: Write Service**

```typescript
// src/service/ai-suggestion.service.ts
import { aiSuggestionRepository } from '../repository/ai-suggestion.repository';
import { CreateAiSuggestionInput, AiSuggestionStatus } from '../dto/ai-suggestion.dto';

export class AiSuggestionService {
  async saveSuggestion(input: CreateAiSuggestionInput) {
    return aiSuggestionRepository.create(input);
  }

  async markSuccess(id: string, output: { suggestions: string[]; tokensUsed: number; latencyMs: number }) {
    return aiSuggestionRepository.updateStatus(id, AiSuggestionStatus.SUCCESS, {
      outputSuggestions: output.suggestions,
      tokensUsed: output.tokensUsed,
      latencyMs: output.latencyMs
    });
  }

  async markFailed(id: string, errorMessage: string) {
    return aiSuggestionRepository.updateStatus(id, AiSuggestionStatus.FAILED, { errorMessage });
  }

  async markSkipped(id: string) {
    return aiSuggestionRepository.updateStatus(id, AiSuggestionStatus.SKIPPED);
  }

  async getUserHistory(userId: string, limit?: number) {
    return aiSuggestionRepository.findByUserId(userId, limit);
  }
}

export const aiSuggestionService = new AiSuggestionService();
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npx vitest tests/unit/service/ai-suggestion.service.test.ts -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/service/ai-suggestion.service.ts tests/unit/service/ai-suggestion.service.test.ts
git commit -m "feat(ai-suggestion): add AiSuggestionService

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Task 5: Run All Tests

- [ ] **Step 1: Run all ai-suggestion tests**

Run: `npx vitest run tests/unit/dto/ai-suggestion.dto.test.ts tests/unit/repository/ai-suggestion.repository.test.ts tests/unit/service/ai-suggestion.service.test.ts`
Expected: All PASS

- [ ] **Step 2: Commit**

```bash
git add -A
git commit -m "test(ai-suggestion): run all tests

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Success Checklist

- [ ] Prisma model added to schema
- [ ] DTO with CreateAiSuggestionInput and AiSuggestionStatus enum
- [ ] Repository with create, findByUserId, findByChatId, updateStatus
- [ ] Service with saveSuggestion, markSuccess, markFailed, markSkipped
- [ ] Unit tests pass
- [ ] All committed

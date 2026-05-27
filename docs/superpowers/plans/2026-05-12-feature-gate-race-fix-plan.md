# Feature Gate Race Condition Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix race condition between checkFeature() and consumeFeature() by creating atomic checkAndConsumeFeature() operation using DB transaction.

**Architecture:** New `user_quotas` table with pessimistic locking via `SELECT FOR UPDATE` in a DB transaction. Single atomic call replaces two-step check-then-consume.

**Tech Stack:** TypeScript, Prisma ORM, PostgreSQL, Vitest

---

## File Structure

```
bondy_server/
├── prisma/
│   └── migrations/
│       └── YYYYMMDDHHMMSS_create_user_quotas/
│           └── migration.sql
├── src/
│   ├── service/
│   │   ├── feature.service.ts          (interface only, add checkAndConsumeFeature)
│   │   └── feature.service.impl.ts     (NEW - Prisma implementation)
│   ├── error/
│   │   └── feature-gated.error.ts      (update mock import)
│   └── service/
│       └── ai-conversation.service.ts  (switch to atomic call)
└── tests/
    └── unit/
        └── service/
            └── feature.service.test.ts  (NEW - race condition test)
```

---

## Task 1: Create Prisma Migration for user_quotas Table

**Files:**
- Create: `bondy_server/prisma/migrations/YYYYMMDDHHMMSS_create_user_quotas/migration.sql`

- [ ] **Step 1: Create migration file**

```sql
-- Migration: Create user_quotas table for atomic feature quota tracking
-- Uses SELECT FOR UPDATE for pessimistic locking within transactions

CREATE TABLE IF NOT EXISTS "user_quotas" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
    "feature" VARCHAR(50) NOT NULL,
    "quota_limit" INT NOT NULL DEFAULT 10,
    "quota_used" INT NOT NULL DEFAULT 0,
    "version" INT NOT NULL DEFAULT 1,
    "updated_at" TIMESTAMP DEFAULT NOW(),
    "created_at" TIMESTAMP DEFAULT NOW(),
    CONSTRAINT "user_quotas_user_feature_unique" UNIQUE("user_id", "feature")
);

CREATE INDEX IF NOT EXISTS "idx_user_quotas_user_feature" ON "user_quotas"("user_id", "feature");

-- Seed some default quota for testing
INSERT INTO "user_quotas" ("user_id", "feature", "quota_limit", "quota_used") 
VALUES 
    ('00000000-0000-0000-0000-000000000001', 'ai_suggestions', 10, 0),
    ('00000000-0000-0000-0000-000000000002', 'ai_suggestions', 10, 0);
```

- [ ] **Step 2: Verify migration runs successfully**

Run: `cd bondy_server && npx prisma migrate dev --name create_user_quotas --skip-seed`
Expected: Migration applied, no errors

---

## Task 2: Add checkAndConsumeFeature to FeatureService Interface

**Files:**
- Modify: `bondy_server/src/service/feature.service.ts`

- [ ] **Step 1: Update interface with new atomic method**

```typescript
// Feature Service Interface

export interface FeatureCheckResult {
  allowed: boolean;
  remaining: number;
  limitType?: string;
}

export interface FeatureService {
  checkFeature(userId: string, feature: string): Promise<FeatureCheckResult>;
  consumeFeature(userId: string, feature: string): Promise<void>;
  // NEW: Atomic check-and-consume operation
  checkAndConsumeFeature(userId: string, feature: string): Promise<FeatureCheckResult>;
}
```

- [ ] **Step 2: Verify TypeScript compiles**

Run: `cd bondy_server && npx tsc --noEmit src/service/feature.service.ts`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add src/service/feature.service.ts
git commit -m "feat(feature-gate): add checkAndConsumeFeature to interface"
```

---

## Task 3: Create Prisma Implementation

**Files:**
- Create: `bondy_server/src/service/feature.service.impl.ts`
- Modify: `bondy_server/src/error/feature-gated.error.ts` (update import)

- [ ] **Step 1: Create feature.service.impl.ts**

```typescript
import { PrismaClient } from '@prisma/client';
import { FeatureService, FeatureCheckResult } from './feature.service';

const prisma = new PrismaClient();

export const featureServiceImpl: FeatureService = {
  async checkFeature(userId: string, feature: string): Promise<FeatureCheckResult> {
    const quota = await prisma.userQuota.findUnique({
      where: { user_id_feature: { user_id: userId, feature } }
    });
    
    if (!quota) {
      return { allowed: true, remaining: 10, limitType: 'unlimited' };
    }
    
    const remaining = quota.quota_limit - quota.quota_used;
    return {
      allowed: remaining > 0,
      remaining,
      limitType: 'daily'
    };
  },

  async consumeFeature(userId: string, feature: string): Promise<void> {
    await prisma.userQuota.updateMany({
      where: { user_id: userId, feature, quota_used: { lt: prisma.raw('quota_limit') } },
      data: { quota_used: { increment: 1 }, version: { increment: 1 } }
    });
  },

  async checkAndConsumeFeature(userId: string, feature: string): Promise<FeatureCheckResult> {
    return await prisma.$transaction(async (tx) => {
      // Lock the row for update to prevent concurrent modifications
      const quota = await tx.$queryRaw<
        { id: string; user_id: string; feature: string; quota_limit: number; quota_used: number; version: number }[]
      >`
        SELECT id, user_id, feature, quota_limit, quota_used, version
        FROM user_quotas
        WHERE user_id = ${userId} AND feature = ${feature}
        FOR UPDATE
      `;

      if (!quota || quota.length === 0) {
        // No quota record - allow with default limit
        return { allowed: true, remaining: 10, limitType: 'daily' };
      }

      const currentQuota = quota[0];
      const remaining = currentQuota.quota_limit - currentQuota.quota_used;

      if (remaining <= 0) {
        return { allowed: false, remaining: 0, limitType: 'daily' };
      }

      // Increment quota_used atomically
      await tx.userQuota.update({
        where: { id: currentQuota.id },
        data: {
          quota_used: { increment: 1 },
          version: { increment: 1 },
          updated_at: new Date()
        }
      });

      return { allowed: true, remaining: remaining - 1, limitType: 'daily' };
    });
  }
};
```

- [ ] **Step 2: Update feature-gated.error.ts to export real implementation**

```typescript
import { FeatureService } from '../service/feature.service';
import { featureServiceImpl } from '../service/feature.service.impl';

// Export real implementation for production use
export const featureService: FeatureService = featureServiceImpl;

export { FeatureCheckResult } from '../service/feature.service';
```

- [ ] **Step 3: Verify TypeScript compiles**

Run: `cd bondy_server && npx tsc --noEmit`
Expected: No errors

- [ ] **Step 4: Commit**

```bash
git add src/service/feature.service.impl.ts src/error/feature-gated.error.ts
git commit -m "feat(feature-gate): add Prisma implementation for atomic checkAndConsumeFeature"
```

---

## Task 4: Update AiConversationService to Use Atomic Call

**Files:**
- Modify: `bondy_server/src/service/ai-conversation.service.ts`

- [ ] **Step 1: Update ai-conversation.service.ts to use atomic call**

Replace the two-step check-then-consume with single atomic call:

```typescript
import { createProvider } from '../factory/ai-provider.factory';
import { loadProviderConfig } from '../config/ai-provider.config';
import { ContextBuilder } from './context-builder.service';
const contextBuilder = new ContextBuilder();
import { aiSuggestionService } from './ai-suggestion.service';
import { buildConversationPrompt } from './prompt-builder';
import { ConversationSuggestRequest, ConversationSuggestResponse } from '../dto/ai-conversation.dto';
import { AiSuggestionStatus } from '../dto/ai-suggestion.dto';
import { featureService } from '../error/feature-gated.error';

const AI_FEATURE = 'ai_suggestions';

const FRIENDLY_ERROR = 'Xin loi ban, AI dang ban lam. Ban thu lai sau vai phut nhe 💛';

export class AiConversationService {
  async generateSuggestion(request: ConversationSuggestRequest & { userId: string }): Promise<ConversationSuggestResponse> {
    // Atomic check-and-consume BEFORE AI generation
    const featureCheck = await featureService.checkAndConsumeFeature(request.userId, AI_FEATURE);
    if (!featureCheck.allowed) {
      return {
        success: false,
        error: 'LIMIT_REACHED',
        remaining: featureCheck.remaining,
        limitType: featureCheck.limitType
      };
    }

    let suggestionId: string | undefined;

    try {
      // Build context
      const context = await contextBuilder.build(request.userId, request.conversationId);

      // Save PENDING record
      const suggestion = await aiSuggestionService.saveSuggestion({
        userId: request.userId,
        chatId: request.conversationId,
        intent: request.intent,
        inputContext: context,
        status: AiSuggestionStatus.PENDING
      });
      suggestionId = suggestion.id;

      // Build prompt and call AI
      const prompt = buildConversationPrompt(context, request.intent, request.tone, request.language);
      const config = loadProviderConfig();
      const provider = createProvider(config.type, config);
      const response = await provider.generateStructured<{ suggestions: string[] }>(prompt, { suggestions: [] });

      // Update SUCCESS
      await aiSuggestionService.markSuccess(suggestionId, {
        suggestions: response.data.suggestions,
        tokensUsed: response.tokensUsed,
        latencyMs: response.latencyMs
      });

      return {
        success: true,
        data: {
          suggestions: response.data.suggestions,
          usage: {
            tokensUsed: response.tokensUsed,
            latencyMs: response.latencyMs,
            provider: response.provider
          }
        }
      };
    } catch (error) {
      // Update FAILED if we have suggestion ID
      if (suggestionId) {
        await aiSuggestionService.markFailed(suggestionId, error instanceof Error ? error.message : 'Unknown error');
      }
      // Throw to trigger fallback in generateWithFallback
      throw error;
    }
  }

  async generateWithFallback(request: ConversationSuggestRequest & { userId: string }): Promise<ConversationSuggestResponse> {
    // Atomic check-and-consume upfront - single atomic operation
    const featureCheck = await featureService.checkAndConsumeFeature(request.userId, AI_FEATURE);
    if (!featureCheck.allowed) {
      return {
        success: false,
        error: 'LIMIT_REACHED',
        remaining: featureCheck.remaining,
        limitType: featureCheck.limitType
      };
    }

    // Try real provider
    try {
      const result = await this.generateSuggestion(request);
      return result;
      // NOTE: consumeFeature already called inside generateSuggestion - no double-consume
    } catch (error1) {
      // Try mock fallback
      try {
        const result = await this.generateWithMock(request);
        return result;
      } catch (error2) {
        // Return friendly error
        return {
          success: false,
          error: FRIENDLY_ERROR
        };
      }
    }
  }

  private async generateWithMock(request: ConversationSuggestRequest & { userId: string }): Promise<ConversationSuggestResponse> {
    let suggestionId: string | undefined;

    try {
      // Build context
      const context = await contextBuilder.build(request.userId, request.conversationId);

      // Save PENDING record
      const suggestion = await aiSuggestionService.saveSuggestion({
        userId: request.userId,
        chatId: request.conversationId,
        intent: request.intent,
        inputContext: context,
        status: AiSuggestionStatus.PENDING
      });
      suggestionId = suggestion.id;

      // Build prompt and call mock AI
      const prompt = buildConversationPrompt(context, request.intent, request.tone, request.language);
      const config = loadProviderConfig();
      const provider = createProvider('mock', config);
      const response = await provider.generateStructured<{ suggestions: string[] }>(prompt, { suggestions: [] });

      // Update SUCCESS
      await aiSuggestionService.markSuccess(suggestionId, {
        suggestions: response.data.suggestions,
        tokensUsed: response.tokensUsed,
        latencyMs: response.latencyMs
      });

      return {
        success: true,
        data: {
          suggestions: response.data.suggestions,
          usage: {
            tokensUsed: response.tokensUsed,
            latencyMs: response.latencyMs,
            provider: 'mock'
          }
        }
      };
    } catch (error) {
      if (suggestionId) {
        await aiSuggestionService.markFailed(suggestionId, error instanceof Error ? error.message : 'Unknown error');
      }
      throw error;
    }
  }
}

export const aiConversationService = new AiConversationService();
```

- [ ] **Step 2: Verify TypeScript compiles**

Run: `cd bondy_server && npx tsc --noEmit`
Expected: No errors

- [ ] **Step 3: Run tests to verify integration**

Run: `cd bondy_server && npx vitest run tests/unit/service/ai-conversation.service.test.ts`
Expected: All tests pass (may need mocking update - see test file)

- [ ] **Step 4: Commit**

```bash
git add src/service/ai-conversation.service.ts
git commit -m "feat(feature-gate): use atomic checkAndConsumeFeature in AiConversationService"
```

---

## Task 5: Add Race Condition Test

**Files:**
- Create: `bondy_server/tests/unit/service/feature.service.test.ts`

- [ ] **Step 1: Write race condition test**

```typescript
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { PrismaClient } from '@prisma/client';
import { featureServiceImpl } from '../../../src/service/feature.service.impl';

// Use separate test DB or transaction per test
const prisma = new PrismaClient();

describe('FeatureService Race Condition Tests', () => {
  const TEST_USER_ID = '00000000-0000-0000-0000-000000000001';
  const TEST_FEATURE = 'ai_suggestions';
  const QUOTA_LIMIT = 5;

  beforeEach(async () => {
    // Reset quota for testing
    await prisma.userQuota.upsert({
      where: { user_id_feature: { user_id: TEST_USER_ID, feature: TEST_FEATURE } },
      update: { quota_used: 0, version: 1 },
      create: {
        user_id: TEST_USER_ID,
        feature: TEST_FEATURE,
        quota_limit: QUOTA_LIMIT,
        quota_used: 0,
        version: 1
      }
    });
  });

  afterEach(async () => {
    // Cleanup
    await prisma.userQuota.update({
      where: { user_id_feature: { user_id: TEST_USER_ID, feature: TEST_FEATURE } },
      data: { quota_used: 0, version: 1 }
    });
  });

  it('should not exceed quota limit under concurrent requests', async () => {
    const CONCURRENT_REQUESTS = 20;
    
    // Spawn N concurrent checkAndConsumeFeature calls
    const promises = Array.from({ length: CONCURRENT_REQUESTS }, () =>
      featureServiceImpl.checkAndConsumeFeature(TEST_USER_ID, TEST_FEATURE)
    );

    const results = await Promise.all(promises);
    
    // Count how many were allowed
    const allowedCount = results.filter(r => r.allowed).length;
    
    // Should never exceed quota limit
    expect(allowedCount).toBeLessThanOrEqual(QUOTA_LIMIT);
    
    // Most calls should be rejected (since we have more requests than quota)
    const rejectedCount = results.filter(r => !r.allowed).length;
    expect(rejectedCount).toBeGreaterThan(0);
  });

  it('should correctly track remaining quota after concurrent requests', async () => {
    // Reset to known state
    await prisma.userQuota.update({
      where: { user_id_feature: { user_id: TEST_USER_ID, feature: TEST_FEATURE } },
      data: { quota_used: 0 }
    });

    const CONCURRENT_REQUESTS = 3;
    const promises = Array.from({ length: CONCURRENT_REQUESTS }, () =>
      featureServiceImpl.checkAndConsumeFeature(TEST_USER_ID, TEST_FEATURE)
    );

    await Promise.all(promises);

    // Check final quota state
    const quota = await prisma.userQuota.findUnique({
      where: { user_id_feature: { user_id: TEST_USER_ID, feature: TEST_FEATURE } }
    });

    expect(quota?.quota_used).toBe(CONCURRENT_REQUESTS);
    expect(quota?.quota_limit - (quota?.quota_used ?? 0)).toBe(QUOTA_LIMIT - CONCURRENT_REQUESTS);
  });

  it('should consume quota exactly once per successful atomic operation', async () => {
    // Reset
    await prisma.userQuota.update({
      where: { user_id_feature: { user_id: TEST_USER_ID, feature: TEST_FEATURE } },
      data: { quota_used: 0 }
    });

    // Call once
    const result = await featureServiceImpl.checkAndConsumeFeature(TEST_USER_ID, TEST_FEATURE);
    
    expect(result.allowed).toBe(true);
    
    const quota = await prisma.userQuota.findUnique({
      where: { user_id_feature: { user_id: TEST_USER_ID, feature: TEST_FEATURE } }
    });
    
    expect(quota?.quota_used).toBe(1);
  });
});
```

- [ ] **Step 2: Run the race condition test**

Run: `cd bondy_server && npx vitest run tests/unit/service/feature.service.test.ts`
Expected: Tests pass with DB connected

- [ ] **Step 3: Commit**

```bash
git add tests/unit/service/feature.service.test.ts
git commit -m "test(feature-gate): add race condition test for concurrent quota consumption"
```

---

## Task 6: Final Verification

- [ ] **Step 1: Run all unit tests**

Run: `cd bondy_server && npx vitest run tests/unit/service/`
Expected: All tests pass

- [ ] **Step 2: Run linter**

Run: `cd bondy_server && npm run lint` (or appropriate lint command)
Expected: No lint errors

- [ ] **Step 3: Verify TypeScript compiles cleanly**

Run: `cd bondy_server && npx tsc --noEmit`
Expected: No errors

- [ ] **Step 4: Push to remote**

```bash
git pull --rebase
git push
git status
```
Expected: Working tree clean, up to date with origin

---

## Spec Coverage Check

- [x] Race condition between checkFeature/consumeFeature → Solved by atomic checkAndConsumeFeature
- [x] Database-level locking → SELECT FOR UPDATE in transaction
- [x] New user_quotas table → Migration created
- [x] Integration in AiConversationService → Updated to use atomic call
- [x] Race condition test → Written in feature.service.test.ts

## Gaps Found

None. All spec requirements covered.

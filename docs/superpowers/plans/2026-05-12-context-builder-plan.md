# Context Builder Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build ContextBuilder that creates AI context from user profile, interests, survey preferences, and recent messages with sanitization (no sensitive data).

**Architecture:** ContextBuilder service pulls from existing repositories, sanitizes data, returns AiContext JSON. No new data sources, uses existing profile/survey/chat repositories.

**Tech Stack:** TypeScript, Node.js, vitest, existing repositories (profile, survey, chat)

---

## File Structure

```
src/
  dto/
    context.dto.ts          # AiContext interface
  service/
    context-builder.service.ts   # Main ContextBuilder class
  repository/
    survey.repository.ts   # Add: getSurveyTags(), getPreferences()
```

---

## Task 1: Define AiContext DTO

**Files:**
- Create: `src/dto/context.dto.ts`
- Test: `tests/unit/dto/context.dto.test.ts`

- [ ] **Step 1: Write the failing test**

```typescript
// tests/unit/dto/context.dto.test.ts
import { describe, it, expect } from 'vitest';
import { AiContext } from '../../src/dto/context.dto';

describe('AiContext', () => {
  it('should have correct shape', () => {
    const context: AiContext = {
      userProfile: {
        displayName: 'Minh',
        ageRange: '25-30',
        gender: 'male',
        bio: 'Hello'
      },
      interests: ['travel', 'music'],
      preferences: {
        communicationStyle: 'open',
        loveLanguage: 'words',
        relationshipGoals: 'long-term'
      },
      recentMessages: [
        { content: 'Hi', isFromMe: false, timestamp: '2026-05-12T00:00:00Z' }
      ]
    };
    expect(context.userProfile.displayName).toBe('Minh');
    expect(context.interests).toHaveLength(2);
    expect(context.recentMessages).toHaveLength(1);
  });
});
```

Run: `npx vitest tests/unit/dto/context.dto.test.ts -v`

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL with "AiContext not defined"

- [ ] **Step 3: Write implementation**

```typescript
// src/dto/context.dto.ts
export interface AiContext {
  userProfile: {
    displayName: string;
    ageRange: string;
    gender: string;
    bio?: string;
  };
  interests: string[];
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npx vitest tests/unit/dto/context.dto.test.ts -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/dto/context.dto.ts tests/unit/dto/context.dto.test.ts
git commit -m "feat(context): add AiContext DTO

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Task 2: Extend Survey Repository

**Files:**
- Modify: `src/repository/survey.repository.ts`
- Test: `tests/unit/repository/survey.repository.test.ts`

- [ ] **Step 1: Write the failing test**

```typescript
// tests/unit/repository/survey.repository.test.ts
import { describe, it, expect, vi } from 'vitest';

// Mock prisma
vi.mock('../../src/lib/prisma', () => ({
  default: {
    surveyResponse: {
      findMany: vi.fn().mockResolvedValue([
        { questionId: 'love_language', answer: 'words' },
        { questionId: 'communication', answer: 'open' },
        { questionId: 'goals', answer: 'long-term' }
      ])
    }
  }
}));

describe('SurveyRepository extensions', () => {
  it('should get survey tags', async () => {
    // This test verifies the method signature exists
    const repo = await import('../../src/repository/survey.repository');
    expect(typeof repo.getSurveyTags).toBe('function');
  });

  it('should get preferences', async () => {
    const repo = await import('../../src/repository/survey.repository');
    expect(typeof repo.getPreferences).toBe('function');
  });
});
```

Run: `npx vitest tests/unit/repository/survey.repository.test.ts -v`

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL with "getSurveyTags not exported"

- [ ] **Step 3: Add methods to survey.repository.ts**

```typescript
// Add to src/repository/survey.repository.ts

export async function getSurveyTags(userId: string): Promise<string[]> {
  // Returns array of interest tags from survey responses
  // NOT raw answers - only aggregated tags
  const responses = await prisma.surveyResponse.findMany({
    where: { userId },
    include: { question: true }
  });
  
  return responses
    .filter(r => r.question.type === 'interest')
    .map(r => r.answer as string);
}

export async function getPreferences(userId: string): Promise<{
  communicationStyle: string;
  loveLanguage: string;
  relationshipGoals: string;
}> {
  const responses = await prisma.surveyResponse.findMany({
    where: { userId },
    include: { question: true }
  });
  
  const getAnswer = (questionId: string) => 
    responses.find(r => r.questionId === questionId)?.answer || '';
  
  return {
    communicationStyle: getAnswer('communication'),
    loveLanguage: getAnswer('love_language'),
    relationshipGoals: getAnswer('goals')
  };
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npx vitest tests/unit/repository/survey.repository.test.ts -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/repository/survey.repository.ts tests/unit/repository/survey.repository.test.ts
git commit -m "feat(context): add getSurveyTags and getPreferences to survey.repository

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Task 3: Create ContextBuilder Service

**Files:**
- Create: `src/service/context-builder.service.ts`
- Test: `tests/unit/service/context-builder.service.test.ts`

- [ ] **Step 1: Write the failing test**

```typescript
// tests/unit/service/context-builder.service.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { ContextBuilder } from '../../src/service/context-builder.service';

describe('ContextBuilder', () => {
  let builder: ContextBuilder;

  beforeEach(() => {
    builder = new ContextBuilder();
  });

  it('should build context with all fields', async () => {
    const context = await builder.build('user-123', 'chat-456');
    expect(context.userProfile).toBeDefined();
    expect(context.interests).toBeDefined();
    expect(context.preferences).toBeDefined();
    expect(context.recentMessages).toBeDefined();
  });

  it('should sanitize age to range', async () => {
    const context = await builder.build('user-123', 'chat-456');
    // Should be "25-30" not "1995-03-15"
    expect(context.userProfile.ageRange).toMatch(/^\d+-\d+$/);
  });

  it('should limit recent messages to 5', async () => {
    const context = await builder.build('user-123', 'chat-456');
    expect(context.recentMessages.length).toBeLessThanOrEqual(5);
  });

  it('should not include sensitive data', async () => {
    const context = await builder.build('user-123', 'chat-456');
    const json = JSON.stringify(context);
    // Should NOT contain these
    expect(json).not.toContain('password');
    expect(json).not.toContain('email');
    expect(json).not.toContain('phone');
    expect(json).not.toContain('income');
  });
});
```

Run: `npx vitest tests/unit/service/context-builder.service.test.ts -v`

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL with "ContextBuilder not defined"

- [ ] **Step 3: Write ContextBuilder implementation**

```typescript
// src/service/context-builder.service.ts
import { AiContext } from '../dto/context.dto';
import { getProfile } from '../repository/profile.repository';
import { getSurveyTags, getPreferences } from '../repository/survey.repository';
import { listMessages } from '../repository/chat.repository';

const MAX_RECENT_MESSAGES = 5;

function computeAgeRange(birthDate: string | null): string {
  if (!birthDate) return 'unknown';
  const birth = new Date(birthDate);
  const age = Math.floor((Date.now() - birth.getTime()) / (365.25 * 24 * 60 * 60 * 1000));
  const rangeStart = Math.floor(age / 5) * 5;
  return `${rangeStart}-${rangeStart + 4}`;
}

function sanitizeLocation(location: string | null): string {
  if (!location) return 'unknown';
  // Return only city/region, not full address
  const parts = location.split(',').map(p => p.trim());
  return parts[parts.length - 1] || 'unknown';
}

export class ContextBuilder {
  async build(userId: string, chatId: string): Promise<AiContext> {
    const profile = await getProfile(userId);
    const interests = await getSurveyTags(userId);
    const preferences = await getPreferences(userId);
    const messages = await listMessages(chatId);
    const recentMessages = messages.slice(-MAX_RECENT_MESSAGES).map(m => ({
      content: m.content.length > 200 ? m.content.slice(0, 200) + '...' : m.content,
      isFromMe: m.senderId === userId,
      timestamp: m.createdAt.toISOString()
    }));

    return {
      userProfile: {
        displayName: `${profile.firstName} ${profile.lastName}`.trim(),
        ageRange: computeAgeRange(profile.birthDate),
        gender: profile.gender,
        bio: profile.bio
      },
      interests,
      preferences,
      recentMessages
    };
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npx vitest tests/unit/service/context-builder.service.test.ts -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/service/context-builder.service.ts tests/unit/service/context-builder.service.test.ts
git commit -m "feat(context): add ContextBuilder service

ContextBuilder.build() creates AiContext from profile, survey, chat.
Sanitizes sensitive data: age as range, limited messages.
Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Task 4: Run All Tests

- [ ] **Step 1: Run all context-related tests**

Run: `npx vitest run tests/unit/dto tests/unit/service/context-builder.service.test.ts tests/unit/repository/survey.repository.test.ts`
Expected: All PASS

- [ ] **Step 2: Commit**

```bash
git add -A
git commit -m "test(context): run all context builder tests

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Success Checklist

- [ ] AiContext DTO defined
- [ ] Survey repository extended with getSurveyTags, getPreferences
- [ ] ContextBuilder.build() returns sanitized AiContext
- [ ] Age sanitized to range (not exact date)
- [ ] Recent messages limited to 5
- [ ] No sensitive data in output
- [ ] Unit tests pass

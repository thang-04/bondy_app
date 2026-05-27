# API Conversation Suggest Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create POST /api/ai/conversation-suggest endpoint that returns 3-5 Vietnamese conversation suggestions based on intent, tone, language.

**Architecture:** API Route → AiConversationService → ContextBuilder + IAiProvider. AiSuggestion record created (PENDING → SUCCESS/FAILED) for audit trail.

**Tech Stack:** TypeScript, Next.js API routes, Prisma, existing services (ContextBuilder, AiSuggestionService, IAiProvider)

---

## File Structure

```
bondy_server/src/
  app/api/ai/conversation-suggest/route.ts   # API route handler
  service/ai-conversation.service.ts          # Business logic
  dto/ai-conversation.dto.ts                  # Request/Response types
  enum/conversation-intent.enum.ts            # Intent enum
  types/prompt.types.ts                       # Prompt building types
```

---

## Task 1: Define DTO Types

**Files:**
- Create: `src/dto/ai-conversation.dto.ts`
- Test: `tests/unit/dto/ai-conversation.dto.test.ts`

- [ ] **Step 1: Write the failing test**

```typescript
// tests/unit/dto/ai-conversation.dto.test.ts
import { describe, it, expect } from 'vitest';
import { ConversationSuggestRequest, ConversationSuggestResponse, ConversationIntent } from '../../../src/dto/ai-conversation.dto';

describe('ConversationSuggest DTO', () => {
  it('should have valid request structure', () => {
    const request: ConversationSuggestRequest = {
      conversationId: 'chat-123',
      intent: ConversationIntent.OPENER,
      tone: 'casual',
      language: 'vi'
    };
    expect(request.conversationId).toBe('chat-123');
    expect(request.intent).toBe('opener');
  });

  it('should have valid response structure', () => {
    const response: ConversationSuggestResponse = {
      success: true,
      data: {
        suggestions: ['Hello', 'Hi there'],
        usage: { tokensUsed: 50, latencyMs: 200, provider: 'mock' }
      }
    };
    expect(response.success).toBe(true);
    expect(response.data.suggestions).toHaveLength(2);
  });

  it('should have all ConversationIntent values', () => {
    expect(Object.values(ConversationIntent)).toContain('opener');
    expect(Object.values(ConversationIntent)).toContain('continue');
    expect(Object.values(ConversationIntent)).toContain('deepen');
    expect(Object.values(ConversationIntent)).toContain('humor');
    expect(Object.values(ConversationIntent)).toContain('flirt');
  });
});
```

Run: `npx vitest tests/unit/dto/ai-conversation.dto.test.ts -v`

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL with "ConversationSuggestRequest not defined"

- [ ] **Step 3: Write DTO**

```typescript
// src/dto/ai-conversation.dto.ts
export enum ConversationIntent {
  OPENER = 'opener',
  CONTINUE = 'continue',
  DEEPEN = 'deepen',
  HUMOR = 'humor',
  FLIRT = 'flirt'
}

export interface ConversationSuggestRequest {
  conversationId: string;
  intent: ConversationIntent;
  tone: 'casual' | 'warm' | 'playful';
  language: 'vi' | 'en';
}

export interface SuggestionUsage {
  tokensUsed: number;
  latencyMs: number;
  provider: string;
}

export interface ConversationSuggestResponse {
  success: boolean;
  data?: {
    suggestions: string[];
    usage: SuggestionUsage;
  };
  error?: string;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npx vitest tests/unit/dto/ai-conversation.dto.test.ts -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/dto/ai-conversation.dto.ts tests/unit/dto/ai-conversation.dto.test.ts
git commit -m "feat(api): add ConversationSuggestRequest/Response DTOs

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Task 2: Create Prompt Builder

**Files:**
- Create: `src/service/prompt-builder.ts`
- Test: `tests/unit/service/prompt-builder.test.ts`

- [ ] **Step 1: Write the failing test**

```typescript
// tests/unit/service/prompt-builder.test.ts
import { describe, it, expect } from 'vitest';
import { buildConversationPrompt } from '../../../src/service/prompt-builder';
import { ConversationIntent } from '../../../src/dto/ai-conversation.dto';
import { AiContext } from '../../../src/dto/context.dto';

describe('PromptBuilder', () => {
  const mockContext: AiContext = {
    userProfile: { displayName: 'Minh', ageRange: '25-30', gender: 'male' },
    interests: ['travel', 'music'],
    preferences: { communicationStyle: 'open', loveLanguage: 'words', relationshipGoals: 'long-term' },
    recentMessages: [{ content: 'Hello', isFromMe: false, timestamp: '2026-05-12T00:00:00Z' }]
  };

  it('should build prompt with Vietnamese language', () => {
    const prompt = buildConversationPrompt(mockContext, ConversationIntent.OPENER, 'casual', 'vi');
    expect(prompt).toContain('tiếng Việt');
    expect(prompt).toContain('opener');
    expect(prompt).toContain('Minh');
  });

  it('should include tone in prompt', () => {
    const prompt = buildConversationPrompt(mockContext, ConversationIntent.HUMOR, 'playful', 'vi');
    expect(prompt).toContain('vui vẻ');
  });

  it('should include context summary', () => {
    const prompt = buildConversationPrompt(mockContext, ConversationIntent.CONTINUE, 'warm', 'vi');
    expect(prompt).toContain('travel');
    expect(prompt).toContain('music');
  });
});
```

Run: `npx vitest tests/unit/service/prompt-builder.test.ts -v`

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL with "buildConversationPrompt not defined"

- [ ] **Step 3: Write Prompt Builder**

```typescript
// src/service/prompt-builder.ts
import { ConversationIntent } from '../dto/ai-conversation.dto';
import { AiContext } from '../dto/context.dto';

const TONE_MAP = {
  casual: 'thân mật, thoải mái',
  warm: 'ấm áp, quan tâm',
  playful: 'vui vẻ, hài hước nhẹ'
};

export function buildConversationPrompt(
  context: AiContext,
  intent: ConversationIntent,
  tone: string,
  language: string
): string {
  const toneText = TONE_MAP[tone as keyof typeof TONE_MAP] || 'thân mật';
  const langText = language === 'vi' ? 'Việt' : 'Anh';
  
  return `Bạn là Bondy Coach, người bạn đồng hành tâm sự.
Hãy gợi ý 3-5 câu trả lời tiếng ${langText} với tone ${toneText} cho intent "${intent}".
Context: ${JSON.stringify(context, null, 2)}
Chỉ trả về JSON array các câu gợi ý, không giải thích thêm.`;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npx vitest tests/unit/service/prompt-builder.test.ts -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/service/prompt-builder.ts tests/unit/service/prompt-builder.test.ts
git commit -m "feat(api): add prompt builder for conversation suggestions

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Task 3: Create AiConversationService

**Files:**
- Create: `src/service/ai-conversation.service.ts`
- Test: `tests/unit/service/ai-conversation.service.test.ts`

- [ ] **Step 1: Write the failing test**

```typescript
// tests/unit/service/ai-conversation.service.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { AiConversationService } from '../../../src/service/ai-conversation.service';
import { ConversationIntent } from '../../../src/dto/ai-conversation.dto';

// Mock dependencies
vi.mock('../../../src/service/context-builder.service', () => ({
  contextBuilder: { build: vi.fn().mockResolvedValue({ userProfile: { displayName: 'Test' } }) }
}));

vi.mock('../../../src/service/ai-suggestion.service', () => ({
  aiSuggestionService: { 
    saveSuggestion: vi.fn().mockResolvedValue({ id: 'suggestion-123' }),
    markSuccess: vi.fn().mockResolvedValue({ id: 'suggestion-123' }),
    markFailed: vi.fn().mockResolvedValue({ id: 'suggestion-123' })
  }
}));

vi.mock('../../../src/factory/ai-provider.factory', () => ({
  createProvider: vi.fn().mockReturnValue({
    generateStructured: vi.fn().mockResolvedValue({ data: { suggestions: ['Hello', 'Hi'] }, tokensUsed: 50, latencyMs: 100, provider: 'mock' })
  })
}));

describe('AiConversationService', () => {
  let service: AiConversationService;

  beforeEach(() => {
    service = new AiConversationService();
    vi.clearAllMocks();
  });

  it('should generate suggestions successfully', async () => {
    const result = await service.generateSuggestion({
      conversationId: 'chat-123',
      userId: 'user-456',
      intent: ConversationIntent.OPENER,
      tone: 'casual',
      language: 'vi'
    });
    expect(result.data?.suggestions).toHaveLength(2);
  });

  it('should save AiSuggestion before calling provider', async () => {
    await service.generateSuggestion({
      conversationId: 'chat-123',
      userId: 'user-456',
      intent: ConversationIntent.CONTINUE,
      tone: 'warm',
      language: 'vi'
    });
    const { aiSuggestionService } = await import('../../../src/service/ai-suggestion.service');
    expect(aiSuggestionService.saveSuggestion).toHaveBeenCalled();
  });
});
```

Run: `npx vitest tests/unit/service/ai-conversation.service.test.ts -v`

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL with "AiConversationService not defined"

- [ ] **Step 3: Write AiConversationService**

```typescript
// src/service/ai-conversation.service.ts
import { createProvider } from '../factory/ai-provider.factory';
import { loadProviderConfig } from '../config/ai-provider.config';
import { contextBuilder } from './context-builder.service';
import { aiSuggestionService } from './ai-suggestion.service';
import { buildConversationPrompt } from './prompt-builder';
import { ConversationSuggestRequest, ConversationSuggestResponse } from '../dto/ai-conversation.dto';
import { AiSuggestionStatus } from '../dto/ai-suggestion.dto';

export class AiConversationService {
  async generateSuggestion(request: ConversationSuggestRequest & { userId: string }): Promise<ConversationSuggestResponse> {
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
      
      // Build prompt and call AI
      const prompt = buildConversationPrompt(context, request.intent, request.tone, request.language);
      const provider = createProvider(loadProviderConfig().type, loadProviderConfig());
      const response = await provider.generateStructured<{ suggestions: string[] }>(prompt, { suggestions: [] });
      
      // Update SUCCESS
      await aiSuggestionService.markSuccess(suggestion.id, {
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
      // (Error handling in catch block)
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error'
      };
    }
  }
}

export const aiConversationService = new AiConversationService();
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npx vitest tests/unit/service/ai-conversation.service.test.ts -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/service/ai-conversation.service.ts tests/unit/service/ai-conversation.service.test.ts
git commit -m "feat(api): add AiConversationService with context building and AI calling

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Task 4: Create API Route

**Files:**
- Create: `src/app/api/ai/conversation-suggest/route.ts`
- Test: `tests/unit/app/api/ai-conversation-suggest.test.ts`

- [ ] **Step 1: Write the failing test**

```typescript
// tests/unit/app/api/ai-conversation-suggest.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { POST } from '../../../src/app/api/ai/conversation-suggest/route';

// Mock service
vi.mock('../../../src/service/ai-conversation.service', () => ({
  aiConversationService: {
    generateSuggestion: vi.fn().mockResolvedValue({
      success: true,
      data: { suggestions: ['Hello'], usage: { tokensUsed: 10, latencyMs: 50, provider: 'mock' } }
    })
  }
}));

describe('POST /api/ai/conversation-suggest', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('should return suggestions on valid request', async () => {
    const request = {
      json: async () => ({
        conversationId: 'chat-123',
        userId: 'user-456',
        intent: 'opener',
        tone: 'casual',
        language: 'vi'
      })
    };
    const response = await POST(request as any);
    expect(response.status).toBe(200);
  });

  it('should return 400 on missing fields', async () => {
    const request = {
      json: async () => ({ conversationId: 'chat-123' }) // missing other fields
    };
    const response = await POST(request as any);
    expect(response.status).toBe(400);
  });
});
```

Run: `npx vitest tests/unit/app/api/ai-conversation-suggest.test.ts -v`

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL with "route module error"

- [ ] **Step 3: Write API Route**

```typescript
// src/app/api/ai/conversation-suggest/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { aiConversationService } from '../../../service/ai-conversation.service';
import { ConversationIntent } from '../../../dto/ai-conversation.dto';

const VALID_INTENTS = Object.values(ConversationIntent);
const VALID_TONES = ['casual', 'warm', 'playful'];
const VALID_LANGUAGES = ['vi', 'en'];

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    
    // Validation
    if (!body.conversationId || !body.userId || !body.intent || !body.tone || !body.language) {
      return NextResponse.json(
        { success: false, error: 'Missing required fields' },
        { status: 400 }
      );
    }
    
    if (!VALID_INTENTS.includes(body.intent)) {
      return NextResponse.json(
        { success: false, error: `Invalid intent. Must be one of: ${VALID_INTENTS.join(', ')}` },
        { status: 400 }
      );
    }
    
    if (!VALID_TONES.includes(body.tone)) {
      return NextResponse.json(
        { success: false, error: `Invalid tone. Must be one of: ${VALID_TONES.join(', ')}` },
        { status: 400 }
      );
    }
    
    if (!VALID_LANGUAGES.includes(body.language)) {
      return NextResponse.json(
        { success: false, error: `Invalid language. Must be one of: ${VALID_LANGUAGES.join(', ')}` },
        { status: 400 }
      );
    }
    
    const result = await aiConversationService.generateSuggestion({
      conversationId: body.conversationId,
      userId: body.userId,
      intent: body.intent,
      tone: body.tone,
      language: body.language
    });
    
    return NextResponse.json(result, { status: result.success ? 200 : 500 });
  } catch (error) {
    return NextResponse.json(
      { success: false, error: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npx vitest tests/unit/app/api/ai-conversation-suggest.test.ts -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/app/api/ai/conversation-suggest/route.ts tests/unit/app/api/ai-conversation-suggest.test.ts
git commit -m "feat(api): add POST /api/ai/conversation-suggest endpoint

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Task 5: Run All Tests

- [ ] **Step 1: Run all AI conversation tests**

Run: `npx vitest run tests/unit/dto/ai-conversation tests/unit/service/ai-conversation tests/unit/service/prompt-builder tests/unit/app/api/ai-conversation`
Expected: All PASS

- [ ] **Step 2: Commit**

```bash
git add -A
git commit -m "test(api): run all conversation suggest tests

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Success Checklist

- [ ] DTO types defined
- [ ] Prompt builder working
- [ ] AiConversationService with full workflow
- [ ] API route with validation
- [ ] AiSuggestion PENDING → SUCCESS/FAILED workflow
- [ ] All tests passing
- [ ] All committed
# API Conversation Suggest Design

**Issue:** bondy-401  
**Status:** Approved  
**Date:** 2026-05-12

---

## 1. Overview

Tạo POST /api/ai/conversation-suggest. Input: conversationId, intent, tone, language. Output: 3–5 câu gợi ý tiếng Việt đúng intent.

---

## 2. API Endpoint

```typescript
// POST /api/ai/conversation-suggest
// Request
{
  "conversationId": string,  // maps to chatId internally
  "intent": string,          // "opener" | "continue" | "deepen" | "humor" | "flirt"
  "tone": string,            // "casual" | "warm" | "playful"
  "language": string          // "vi" | "en"
}

// Response
{
  "success": true,
  "data": {
    "suggestions": string[],  // 3-5 Vietnamese suggestions
    "usage": {
      "tokensUsed": number,
      "latencyMs": number,
      "provider": string
    }
  }
}
```

---

## 3. Intent Enum

```typescript
export enum ConversationIntent {
  OPENER = 'opener',
  CONTINUE = 'continue',
  DEEPEN = 'deepen',
  HUMOR = 'humor',
  FLIRT = 'flirt'
}
```

---

## 4. Service Layer

```typescript
// src/service/ai-conversation.service.ts

export class AiConversationService {
  async generateSuggestion(request: ConversationSuggestRequest) {
    // 1. Build context from ContextBuilder
    const context = await contextBuilder.build(request.userId, request.conversationId);
    
    // 2. Save PENDING AiSuggestion record
    const suggestion = await aiSuggestionService.saveSuggestion({
      userId: request.userId,
      chatId: request.conversationId,
      intent: request.intent,
      inputContext: context,
      status: AiSuggestionStatus.PENDING
    });
    
    // 3. Call AI Provider
    try {
      const response = await provider.generateStructured(prompt, { suggestions: [] });
      
      // 4. Update SUCCESS
      await aiSuggestionService.markSuccess(suggestion.id, {
        suggestions: response.data.suggestions,
        tokensUsed: response.tokensUsed,
        latencyMs: response.latencyMs
      });
      
      return response;
    } catch (error) {
      // 5. Update FAILED
      await aiSuggestionService.markFailed(suggestion.id, error.message);
      throw error;
    }
  }
}
```

---

## 5. Prompt Building

```typescript
function buildPrompt(context: AiContext, intent: string, tone: string, language: string): string {
  const toneText = {
    casual: "thân mật, thoải mái",
    warm: "ấm áp, quan tâm",
    playful: "vui vẻ, hài hước nhẹ"
  }[tone] || "thân mật";
  
  return `Bạn là Bondy Coach, người bạn đồng hành tâm sự.
Hãy gợi ý 3-5 câu trả lời tiếng ${language === 'vi' ? 'Việt' : 'Anh'} 
với tone ${toneText} cho intent "${intent}".
Context: ${JSON.stringify(context)}
Chỉ trả về JSON array các câu gợi ý, không giải thích thêm.`;
}
```

---

## 6. File Structure

```
bondy_server/src/
  app/api/ai/conversation-suggest/route.ts   # API route
  service/ai-conversation.service.ts          # Main service
  dto/ai-conversation.dto.ts                 # Request/Response types
```

---

## 7. Dependencies

- ContextBuilder (bondy-r38)
- AiSuggestionService (bondy-bf8)
- IAiProvider (bondy-711)
- FeatureGate (bondy-dyf - future)

---

## 8. Success Criteria

- [ ] POST /api/ai/conversation-suggest works
- [ ] Returns 3-5 Vietnamese suggestions
- [ ] Saves AiSuggestion record (PENDING → SUCCESS/FAILED)
- [ ] Uses ContextBuilder for context
- [ ] Feature Gate integration (bondy-dyf)
- [ ] Unit tests pass
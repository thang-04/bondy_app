# Fallback Design - bondy-dru

## Context

Implement hybrid fallback approach for AI conversation suggestions:
- Try real provider (Gemini/OpenAI) first
- If fail → try MockAiProvider as fallback
- If mock also fails → return friendly error

## Decision

### Flow
```
1. Try: Real AI Provider (Gemini/OpenAI)
   ↓ fail
2. Try: MockAiProvider as fallback
   ↓ fail
3. Return: Friendly error message
```

## Design

### Friendly Error Message
```typescript
const FRIENDLY_ERROR = 'Xin loi ban, AI dang ban lam. Ban thu lai sau vai phut nhe 💛';
```

### AiConversationService Method

```typescript
async generateWithFallback(request: ConversationSuggestRequest & { userId: string }): Promise<ConversationSuggestResponse> {
  // Try real provider
  try {
    return await this.generateSuggestion(request);
  } catch (error1) {
    // Try mock fallback
    try {
      const mockResult = await this.generateWithMock(request);
      return mockResult;
    } catch (error2) {
      // Return friendly error
      return {
        success: false,
        error: FRIENDLY_ERROR
      };
    }
  }
}
```

### Mock Fallback Method
```typescript
private async generateWithMock(request: ConversationSuggestRequest & { userId: string }): Promise<ConversationSuggestResponse> {
  const mockConfig = loadProviderConfig();
  const mockProvider = createProvider('mock', mockConfig);
  // ... call mock provider and return result
}
```

## Files to Modify

- `bondy_server/src/service/ai-conversation.service.ts`
  - Add FRIENDLY_ERROR constant
  - Add `generateWithFallback` method
  - Add private `generateWithMock` helper

## Backwards Compatibility

- Keep existing `generateSuggestion` method unchanged
- New fallback method is opt-in
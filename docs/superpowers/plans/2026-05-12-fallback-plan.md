# Fallback Plan - bondy-dru

## Tasks

### 1. Add FRIENDLY_ERROR constant to ai-conversation.service.ts

```typescript
const FRIENDLY_ERROR = 'Xin loi ban, AI dang ban lam. Ban thu lai sau vai phut nhe 💛';
```

### 2. Add private generateWithMock method

- Use existing MockAiProvider via createProvider
- Call provider.generateStructured with same prompt
- Handle errors and return ConversationSuggestResponse

### 3. Add public generateWithFallback method

- Wrap try/catch around real provider call
- On failure, call generateWithMock
- On mock failure, return friendly error response

### 4. Add tests

- Test fallback success path
- Test mock failure path
- Test both fail path

## Test Commands

```bash
cd bondy_server
npx vitest run src/service/ai-conversation.service.test.ts
```

## Acceptance Criteria

- [ ] Real provider fail → mock fallback → success
- [ ] Real provider fail → mock fail → friendly error
- [ ] All existing tests still pass
# Feature Gate Integration Design

## Context
Need to integrate AI feature gating (check-feature/consume-feature) into bondy-server before AI generation calls.

## Problem
AI generation should only proceed if user has available quota, and quota should be consumed on successful generation.

## Solution

### 1. Feature Service Interface
```typescript
// src/service/feature.service.ts
export interface FeatureCheckResult {
  allowed: boolean;
  remaining: number;
  limitType?: string;
}

export interface FeatureService {
  checkFeature(userId: string, feature: string): Promise<FeatureCheckResult>;
  consumeFeature(userId: string, feature: string): Promise<void>;
}
```

### 2. FeatureGatedError
```typescript
// src/error/feature-gated.error.ts
export class FeatureGatedError extends Error {
  readonly remaining: number;
  readonly limitType: string;

  constructor(remaining: number, limitType: string) {
    super(`Feature limit reached: ${limitType}`);
    this.name = 'FeatureGatedError';
    this.remaining = remaining;
    this.limitType = limitType;
  }
}
```

### 3. Mock Implementation
```typescript
// src/service/feature.service.mock.ts
export const featureService: FeatureService = {
  async checkFeature(userId, feature) {
    return { allowed: true, remaining: 10 };
  },
  async consumeFeature(userId, feature) {
    // noop
  }
};
```

### 4. Integration in AiConversationService
- Before AI call: checkFeature
- If NOT allowed: throw FeatureGatedError
- On success: consumeFeature

## Files
- `src/service/feature.service.ts` - interface
- `src/service/feature.service.mock.ts` - mock implementation
- `src/error/feature-gated.error.ts` - error class
- `src/service/ai-conversation.service.ts` - integrate

## Testing
- npx vitest
# Feature Gate Race Condition Fix - Design

## Context
Issue: bondy-w59 - Race condition in Feature Gate

checkFeature() và consumeFeature() là 2 operations riêng biệt. Giữa 2 calls, concurrent requests có thể exhaust quota. Không có atomic operation để đảm bảo consistency.

## Problem
Multiple users có thể vượt quota limit do race condition. Revenue impact nếu quota là paid feature.

## Solution

### 1. Database Schema

New table `user_quotas`:
```sql
CREATE TABLE user_quotas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  feature VARCHAR(50) NOT NULL,
  quota_limit INT NOT NULL DEFAULT 10,
  quota_used INT NOT NULL DEFAULT 0,
  version INT NOT NULL DEFAULT 1,
  updated_at TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, feature)
);

CREATE INDEX idx_user_quotas_user_feature ON user_quotas(user_id, feature);
```

### 2. Atomic Operation

New method `checkAndConsumeFeature()`:

```typescript
export interface FeatureService {
  checkFeature(userId: string, feature: string): Promise<FeatureCheckResult>;
  consumeFeature(userId: string, feature: string): Promise<void>;
  checkAndConsumeFeature(userId: string, feature: string): Promise<FeatureCheckResult>;
}
```

Transaction flow:
1. BEGIN
2. SELECT quota_limit, quota_used FROM user_quotas WHERE user_id=X AND feature=Y FOR UPDATE
3. IF quota_used >= quota_limit → ROLLBACK, return allowed: false
4. ELSE → UPDATE user_quotas SET quota_used = quota_used + 1, version = version + 1 WHERE id=X
5. COMMIT
6. Return allowed: true, remaining: new_remaining

### 3. Implementation

Files to create/modify:
- `prisma/migrations/xxx_create_user_quotas/migration.sql` - new table
- `src/service/feature.service.ts` - add checkAndConsumeFeature to interface
- `src/service/feature.service.impl.ts` - new Prisma implementation
- `src/service/feature.service.mock.ts` - update mock (or keep as fallback)
- `src/service/ai-conversation.service.ts` - switch to atomic call

### 4. Integration

Replace 2-step check → consume with single atomic call:

```typescript
// BEFORE (race condition)
const check = await featureService.checkFeature(userId, feature);
if (!check.allowed) throw new FeatureGatedError(...);
const result = await generateAI(...);
if (result.success) await featureService.consumeFeature(userId, feature);

// AFTER (atomic)
const check = await featureService.checkAndConsumeFeature(userId, feature);
if (!check.allowed) throw new FeatureGatedError(...);
const result = await generateAI(...);
```

### 5. Testing

Race condition test:
- Spawn N concurrent requests from same user
- Verify total consumed = min(N, quota_limit)
- No requests should exceed quota limit

## Decisions
- DB: Prisma + migrations
- Table: New user_quotas table (not extending subscriptions)
- Atomic approach: DB transaction with SELECT FOR UPDATE (pessimistic locking within transaction)

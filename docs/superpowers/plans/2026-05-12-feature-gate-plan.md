# Feature Gate Implementation Plan

## Steps

1. **Create `src/service/feature.service.ts`**
   - Define FeatureCheckResult interface
   - Define FeatureService interface

2. **Create `src/error/feature-gated.error.ts`**
   - Define FeatureGatedError class extending Error
   - Include remaining and limitType properties

3. **Create `src/service/feature.service.mock.ts`**
   - Implement mock FeatureService
   - Always returns allowed: true, remaining: 10

4. **Modify `src/service/ai-conversation.service.ts`**
   - Import featureService and FeatureGatedError
   - Before AI generation: call checkFeature
   - If not allowed: throw FeatureGatedError
   - After success: call consumeFeature

5. **Test**
   - Run `npx vitest` to verify

## Verification
- All tests pass
- Integration compiles correctly
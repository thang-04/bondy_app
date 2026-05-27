# Codebase Concerns

**Analysis Date:** 2026-05-17

## Tech Debt

**OTP Authentication - In-Memory Store Not Production-Ready:**
- Issue: OTP records stored in `Map<string, OtpRecord>` (in-memory) - resets on server restart, doesn't scale across multiple instances
- Files: `bondy_server/src/service/otp-auth.service.ts`
- Impact: Users must re-request OTP after restart; multi-instance deployments fail OTP verification
- Fix approach: Replace with Redis or database-backed storage

**JWT Default Secret in Production:**
- Issue: `env.ts` defaults to `'default-secret-change-in-production'` when `JWT_SECRET` env var not set
- Files: `bondy_server/src/config/env.ts:4`
- Impact: Tokens can be forged if deployed without proper env var
- Fix approach: Fail-fast startup check that throws if `JWT_SECRET` not properly configured in non-development

**Mock AI Provider Used in Production:**
- Issue: `AI_PROVIDER_TYPE` defaults to `'mock'` - no actual AI responses generated
- Files: `bondy_server/src/config/ai-provider.config.ts:20`
- Impact: AI conversation suggestions always return empty/mock responses
- Fix approach: Require explicit provider type, warn/error if mock used in non-dev

**Crisis Hotline Placeholder:**
- Issue: Hotline number is `'1800-XXXX (hỗ trợ 24/7)'` - placeholder not replaced with real number
- Files: `bondy_server/src/service/content-safety.service.ts:5`
- Impact: Users in crisis receive non-functional contact info
- Fix approach: Replace with actual crisis hotline number for Vietnam

**OpenTelemetry Wrapper Is Stub:**
- Issue: `OtelWrapper` collects metrics/spans in memory but exports nothing - no actual OTLP export configured
- Files: `bondy_server/src/wrapper/otel-wrapper.ts`
- Impact: Zero observability into AI provider calls
- Fix approach: Implement actual OTLP exporter or integrate with existing observability stack

**Healing Content Has Hardcoded Fallback:**
- Issue: Service falls back to in-memory seed content when database unavailable - prevents data consistency
- Files: `bondy_server/src/service/healing.service.ts:58-88`
- Impact: User progress may be lost; content served may be stale
- Fix approach: Make database migration a precondition, do not serve inconsistent fallback

## Known Bugs

**No bugs found in codebase scan.** (No TODO/FIXME/HACK comments present in source code)

## Security Considerations

**OTP Rate Limiting Uses In-Memory Map:**
- Risk: Rate limit state lost on restart; concurrent requests across instances bypass lockout
- Files: `bondy_server/src/service/otp-auth.service.ts:25-31`
- Current mitigation: Per-instance tracking, 15-min lockout after 5 failures
- Recommendations: Use Redis for distributed rate limiting

**CORS Proxy Wildcard:**
- Risk: `Access-Control-Allow-Origin: *` allows any website to make API requests
- Files: `bondy_server/src/proxy.ts:7`
- Current mitigation: Requires Bearer token authentication
- Recommendations: Restrict to known frontend origins in production

**JWT Secret in Codebase Fallback:**
- Risk: Default secret in `env.ts` could be accidentally used in production
- Files: `bondy_server/src/config/env.ts:4`
- Recommendations: Add startup validation, reject requests if default secret detected

**Image Upload No Validation:**
- Risk: Upload endpoint accepts any file type, no size/content-type enforcement
- Files: `bondy_server/src/app/api/upload/route.ts:42-65`
- Recommendations: Add file type whitelist, size limit, virus scan

**Insecure Password Storage Check:**
- Risk: `auth.repository.verifyPassword` implementation not reviewed
- Files: `bondy_server/src/repository/auth.repository.ts`
- Recommendations: Verify bcrypt/argon2 usage, check salt rounds

## Performance Bottlenecks

**Healing Service Calls DB on Every Request:**
- Problem: `tryEnsureSeedContent()` called on every healing endpoint
- Files: `bondy_server/src/service/healing.service.ts:58-66`
- Cause: Redundant seed content check even when content already persisted
- Improvement path: Check once at startup or use feature flag to gate

**Prisma Client Log in Production:**
- Problem: `prisma.ts` logs all queries in development - verbose output, potential performance hit
- Files: `bondy_server/src/lib/prisma.ts:10`
- Cause: `'query'` log level included when `NODE_ENV === 'development'`
- Improvement path: Ensure query logging only in non-production, consider structured logging

**AI Suggestion Saves Multiple Records Per Request:**
- Problem: Each AI suggestion flow creates 2 records: primary + mock fallback
- Files: `bondy_server/src/service/ai-conversation.service.ts:68-123`
- Cause: Primary suggestion created then marked skipped when mock fallback triggers
- Improvement path: Only create suggestion record after provider succeeds

## Fragile Areas

**OTP Auth Service Singleton:**
- Files: `bondy_server/src/service/otp-auth.service.ts:171`
- Why fragile: Module-level singleton with mutable state (`otpStore` Map) - race conditions in concurrent requests
- Safe modification: Move state to external store (Redis) before scaling
- Test coverage: Has test hooks (`clearOtpsForTest`, `getOtpRecordForTest`) but tests not visible in codebase

**Healing Seed Content Hardcoded:**
- Files: `bondy_server/src/service/healing.seed.ts`
- Why fragile: Content duplicated between code and database; body text is full Vietnamese strings - i18n not extensible
- Safe modification: Externalize to config file or CMS
- Test coverage: No tests visible for seed data

**AI Provider Factory Error Handling:**
- Files: `bondy_server/src/factory/ai-provider.factory.ts`
- Why fragile: Creates providers but errors propagate to caller - no fallback chain defined at factory level
- Safe modification: Implement circuit breaker pattern

**Auth Middleware Auth Header Parsing:**
- Files: `bondy_server/src/middleware/auth.middleware.ts:13`
- Why fragile: `authHeader?.startsWith('Bearer ')` - no case-insensitive check, could miss `bearer` lowercase
- Safe modification: Use case-insensitive comparison for auth scheme

## Scaling Limits

**In-Memory OTP Store:**
- Current capacity: ~10K OTP records before memory pressure
- Limit: Single Next.js instance; breaks with multiple instances or containers
- Scaling path: Migrate to Redis with TTL keys

**Prisma PostgreSQL Connection Pool:**
- No explicit pool config visible
- Limit: Default Prisma pool (10 connections) may exhaust under load
- Scaling path: Configure `connection_limit` in DATABASE_URL, use PgBouncer

## Dependencies at Risk

**Next.js 14.x:**
- Risk: Recent major version, potential API changes between minor versions
- Impact: API route handlers may break on Next.js upgrades
- Migration plan: Pin to minor version, test incremental upgrades

**Prisma 5.x:**
- Risk: Using `prisma-client-js` generator
- Impact: Client regeneration needed on schema changes
- Migration plan: Review Prisma upgrade path; 6.x has breaking changes

**bcryptjs:**
- Risk: Pure JS implementation slower than bcrypt-native alternatives
- Impact: Password hashing could become auth bottleneck
- Migration plan: Consider bcrypt-native for production

## Missing Critical Features

**No Database Migrations for Healing:**
- Problem: `healing.service.ts` checks `seedPersisted` but no Prisma migration creates healing tables
- Blocks: User progress tracking, course completion, journal logs

**No Rate Limiting on API Endpoints:**
- Problem: OTP endpoints vulnerable to brute force with no per-IP/range limiting
- Blocks: Production deployment without WAF

**No Email Verification Enforcement:**
- Problem: Users can register without verified email; `emailVerified` field not enforced in protected routes
- Blocks: Trust and safety features

**No Refresh Token Rotation:**
- Problem: Old refresh tokens not invalidated on reuse (Rotation not implemented)
- Files: `bondy_server/src/service/auth.service.ts:113-138`
- Blocks: Refresh token reuse detection, session invalidation

## Test Coverage Gaps

**Untested Authentication Flow:**
- What's not tested: OTP send/verify, password reset, email verification end-to-end
- Files: `bondy_server/src/app/api/auth/*`
- Risk: Auth regressions undetected

**Untested AI Safety Guardrails:**
- What's not tested: Crisis detection, forbidden content blocking, risk score thresholds
- Files: `bondy_server/src/types/crisis-keywords.ts`, `bondy_server/src/service/safety-guardrails.service.ts`
- Risk: Safety bypasses undetected

**Untested Healing Service:**
- What's not tested: Course progression, lesson completion, check-in flow
- Files: `bondy_server/src/service/healing.service.ts`
- Risk: Healing progress tracking could break silently

**Flutter App - No Unit Tests Visible:**
- What's not tested: Services, viewmodels, state management
- Files: `Bondy_App/lib/`
- Risk: Business logic regressions undetected

---

*Concerns audit: 2026-05-17*
# External Integrations

**Analysis Date:** 2026-05-17

## APIs & External Services

**AI Provider:**
- Mock provider (default) - `src/config/ai-provider.config.ts`
- Google Gemini - configured via GEMINI_API_KEY, GEMINI_MODEL (not implemented)
- OpenAI - configured via OPENAI_API_KEY, OPENAI_MODEL (not implemented)
  - SDK: No external SDK, uses direct API calls
  - Auth: GEMINI_API_KEY / OPENAI_API_KEY env vars

**Supabase:**
- Used for storage/auth integration
  - Client: @supabase/supabase-js 2.100.0
  - Auth: NEXT_PUBLIC_SUPABASE_URL, NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY
  - Location: `bondy_server/src/lib/supabase.ts`

**Email Delivery:**
- Nodemailer 7.0.7 - Transactional emails
  - Multiple transport configs: Ethereal (dev), Gmail, custom SMTP
  - Location: `bondy_server/src/service/email-delivery.service.ts`
  - Auth: Email credentials in env

## Data Storage

**Database:**
- PostgreSQL
  - Connection: DATABASE_URL, DIRECT_URL env vars
  - ORM: Prisma 6.19.3
  - Schema: `bondy_server/prisma/schema.prisma`
  - Models: User, Profile, Swipe, Match, Chat, Message, Survey, AiSuggestion, UserQuota

**File Storage:**
- Supabase (configured but not extensively used)
- Local filesystem for uploads via `/api/upload` endpoint

**Caching:**
- None detected

## Authentication & Identity

**Server Auth:**
- NextAuth 5.0.0-beta.30
  - Prisma adapter for session/account storage
  - Custom JWT strategy
- JWT tokens via jsonwebtoken
- Refresh token rotation
- OTP-based phone/email verification (dev OTP via nodemailer test accounts)

**App Auth:**
- Custom AuthService using http.Client
- Token storage: flutter_secure_storage
- Base URL resolution: .env > platform-specific defaults (10.0.2.2:3001 for Android emulator, localhost:3001 otherwise)
- Location: `Bondy_App/lib/services/auth_service.dart`

## Monitoring & Observability

**Error Tracking:**
- None detected

**Logs:**
- Console.log/stderr (standard Node.js)
- Test output via Vitest

## CI/CD & Deployment

**Hosting:**
- Not explicitly configured in codebase

**CI Pipeline:**
- GitHub Actions (`.github/` directory present)
- Playwright config: `bondy_server/playwright.config.ts`

## Environment Configuration

**Required env vars (server):**
- DATABASE_URL - PostgreSQL connection string
- DIRECT_URL - Direct PostgreSQL connection (Prisma)
- JWT_SECRET - Token signing secret
- NEXT_PUBLIC_BASE_URL - Server base URL
- NEXT_PUBLIC_SUPABASE_URL - Supabase project URL
- NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY - Supabase anon key
- AI_PROVIDER_TYPE - 'mock' | 'gemini' | 'openai'
- AI_TIMEOUT_MS, AI_MAX_RETRIES - AI provider config
- MOCK_AI_DELAY_MS, MOCK_AI_ERROR_RATE - Mock provider config

**Secrets location:**
- `.env` files (not committed - see .gitignore)
- `.env.example` for template

## Webhooks & Callbacks

**Incoming:**
- None explicitly defined

**Outgoing:**
- None explicitly defined

---

*Integration audit: 2026-05-17*
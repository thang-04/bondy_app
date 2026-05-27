# Technology Stack

**Analysis Date:** 2026-05-17

## Languages

**Primary:**
- TypeScript 5.9.3 - bondy_server API, Next.js
- Dart 3.11.0 - Bondy_App Flutter app

**Secondary:**
- Prisma schema (DSL-based)
- SQL - bondy_sql.sql

## Runtime

**Server (bondy_server):**
- Node.js (bundled with Next.js 16.1.6)
- npm for package management
- Lockfile: `package-lock.json`

**App (Bondy_App):**
- Flutter SDK
- Dart VM / AOT
- Lockfile: `pubspec.lock`

## Frameworks

**Server:**
- Next.js 16.1.6 - React framework, API routes
- next-auth 5.0.0-beta.30 - Authentication
- Prisma 6.19.3 - ORM
- swagger-jsdoc 6.2.8 + swagger-ui-express 5.0.1 - API documentation

**Client App:**
- Flutter 3.11.0 - UI framework
- provider 6.1.5+1 - State management
- go_router 14.0.0 - Navigation

**Testing:**
- Vitest - Server unit/integration tests
- Playwright - E2E tests
- flutter_test - Flutter unit tests
- integration_test - Flutter integration tests

**Build/Dev:**
- ts-node 10.9.2 - TypeScript execution
- TypeScript 5.9.3

## Key Dependencies

**Server Critical:**
- @prisma/client 6.19.3 - Database ORM
- @supabase/supabase-js 2.100.0 - Supabase client
- bcryptjs 2.4.3 - Password hashing
- jsonwebtoken 9.0.3 - JWT handling
- nodemailer 7.0.7 - Email delivery
- zod 3.22.0 - Schema validation

**App Critical:**
- dio 5.9.2 - HTTP client
- flutter_secure_storage 10.0.0 - Secure token storage
- flutter_dotenv 5.1.0 - Environment config
- image_picker 1.2.1 - Photo selection
- geolocator 13.0.2 - Location services
- flutter_map 7.0.2 - Maps
- appinio_swiper 2.1.1 - Swipe UI

## Configuration

**Environment:**
- Server: `bondy_server/.env` with `NEXT_PUBLIC_` prefix for client-exposed vars
- App: `Bondy_App/.env` via flutter_dotenv
- Key configs: DATABASE_URL, JWT_SECRET, NEXT_PUBLIC_BASE_URL, NEXT_PUBLIC_SUPABASE_URL, AI_PROVIDER_TYPE

**Build:**
- Server: tsconfig.json (ES2020 target, bundler moduleResolution)
- App: pubspec.yaml

## Platform Requirements

**Development:**
- Node.js compatible environment
- PostgreSQL 5432
- Flutter 3.11+

**Production:**
- Next.js deployable (Vercel/self-hosted)
- PostgreSQL database
- Android 21+ / iOS

---

*Stack analysis: 2026-05-17*
# Architecture

**Analysis Date:** 2026-05-17

## System Overview

```text
┌─────────────────────────────────────────────────────────────┐
│                        Flutter App                          │
│                   `Bondy_App/lib/`                          │
├─────────────────────────────────────────────────────────────┤
│  Screens (UI)  │  ViewModels (State)  │  Services (API)     │
│  widgets/      │  viewmodels/         │  services/           │
└────────┬───────┴──────────────────────┴─────────────────────┘
         │ HTTP JSON
         ▼
┌─────────────────────────────────────────────────────────────┐
│                      Next.js REST API                       │
│                  `bondy_server/src/`                        │
├──────────────────┬──────────────────┬───────────────────────┤
│   App Router     │   Services      │   Repositories        │
│   `app/api/`     │   `service/`     │   `repository/`       │
└────────┬─────────┴────────┬─────────┴──────────┬────────────┘
         │                  │                     │
         ▼                  ▼                     ▼
┌─────────────────────────────────────────────────────────────┐
│                    Prisma ORM / PostgreSQL                  │
│                   `bondy_server/prisma/`                    │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│                    Supabase (Storage)                       │
│                 `src/lib/supabase.ts`                       │
└─────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| Next.js App Router | HTTP endpoint handling, request/response | `bondy_server/src/app/api/` |
| Services | Business logic, orchestration | `bondy_server/src/service/` |
| Repositories | Data access via Prisma | `bondy_server/src/repository/` |
| Auth Middleware | JWT verification, route protection | `bondy_server/src/middleware/auth.middleware.ts` |
| Flutter Screens | UI rendering, user interaction | `Bondy_App/lib/screens/` |
| Flutter ViewModels | State management, business logic | `Bondy_App/lib/viewmodels/` |
| Flutter Services | API communication, HTTP | `Bondy_App/lib/services/` |
| ApiClient | HTTP client with auth token management | `Bondy_App/lib/services/api_client.dart` |

## Pattern Overview

**Overall:** Layered/Clean Architecture with Repository Pattern

**Key Characteristics:**
- **Server:** Next.js App Router with service layer and repository pattern
- **App:** Provider-based state management with service layer calling REST API
- **Data:** Prisma ORM connecting to PostgreSQL
- **Auth:** JWT tokens with refresh token rotation stored in database
- **AI:** Factory pattern for AI provider abstraction (mock/OpenAI)

## Layers

**API Routes (`bondy_server/src/app/api/`):**
- Purpose: Handle HTTP requests/responses using Next.js App Router
- Location: `bondy_server/src/app/api/`
- Contains: Route handlers for auth, chats, discover, healing, home, profile, surveys, swipes
- Depends on: Services
- Used by: Flutter app via HTTP

**Services (`bondy_server/src/service/`):**
- Purpose: Business logic, validation, orchestration
- Location: `bondy_server/src/service/`
- Contains: `auth.service.ts`, `chat.service.ts`, `discover.service.ts`, `healing.service.ts`, `home.service.ts`, `profile.service.ts`, `survey.service.ts`, `swipe.service.ts`, `ai-conversation.service.ts`, `content-safety.service.ts`, `safety-guardrails.service.ts`
- Depends on: Repositories, DTOs, external services (email, AI)
- Used by: API Routes

**Repositories (`bondy_server/src/repository/`):**
- Purpose: Data access layer wrapping Prisma queries
- Location: `bondy_server/src/repository/`
- Contains: `auth.repository.ts`, `chat.repository.ts`, `discover.repository.ts`, `profile.repository.ts`, `swipe.repository.ts`, `survey.repository.ts`, `healing.repository.ts`, `ai-suggestion.repository.ts`
- Depends on: Prisma client
- Used by: Services

**DTOs (`bondy_server/src/dto/`):**
- Purpose: Data transfer objects for request/response validation
- Location: `bondy_server/src/dto/`
- Contains: `auth.dto.ts`, `chat.dto.ts`, `profile.dto.ts`, `swipe.dto.ts`, `ai-suggestion.dto.ts`, `ai-conversation.dto.ts`, `healing.dto.ts`
- Depends on: Zod schemas for validation
- Used by: API Routes, Services

**Flutter ViewModels (`Bondy_App/lib/viewmodels/`):**
- Purpose: State management using ChangeNotifier/Provider
- Location: `Bondy_App/lib/viewmodels/`
- Contains: `auth_viewmodel.dart`, `survey_viewmodel.dart`, `discover_viewmodel.dart`, `home_viewmodel.dart`, `ai_coach_viewmodel.dart`
- Depends on: Services
- Used by: Flutter Screens

**Flutter Services (`Bondy_App/lib/services/`):**
- Purpose: API communication, external integrations
- Location: `Bondy_App/lib/services/`
- Contains: `api_client.dart`, `auth_service.dart`, `chat_service.dart`, `discover_service.dart`, `survey_service.dart`, `healing_service.dart`, `profile_service.dart`, `ai_service.dart`, `safety_guardrails_service.dart`, `home_service.dart`
- Depends on: HTTP client, secure storage
- Used by: ViewModels, Screens directly for simple cases

## Data Flow

### Primary Request Path (Flutter to Server)

1. **User Action** - User taps button on Flutter screen
2. **Screen Handler** - Screen calls ViewModel method
3. **ViewModel** - ViewModel calls Service method with auth token
4. **ApiClient** (`Bondy_App/lib/services/api_client.dart:88`)
   - Adds `Authorization: Bearer {token}` header
   - Sends HTTP request to server
   - Handles 401 by attempting token refresh
5. **API Route** (`bondy_server/src/app/api/{domain}/{action}/route.ts`)
   - Validates request body with DTO/Zod
   - Calls Service method
6. **Service** (`bondy_server/src/service/{domain}.service.ts`)
   - Executes business logic
   - Calls Repository for data access
7. **Repository** (`bondy_server/src/repository/{domain}.repository.ts`)
   - Executes Prisma queries
   - Returns domain objects
8. **Response** - Data flows back through layers

### Auth Flow

1. **Login Request** - `POST /api/auth/login`
2. **AuthService** (`bondy_server/src/service/auth.service.ts:45`) validates credentials
3. **AuthRepository** verifies password via bcrypt
4. **JwtUtils** (`bondy_server/src/lib/jwt.ts`) generates token pair
5. **Response** returns `{ user, accessToken, refreshToken }`
6. **Flutter** stores tokens in `flutter_secure_storage`
7. **Subsequent requests** - `ApiClient` attaches Bearer token

### Refresh Token Flow

1. **Access token expires** - Server returns 401
2. **ApiClient** (`Bondy_App/lib/services/api_client.dart:94`) catches 401
3. **AuthService.refreshAccessToken()** - Sends refresh token to `/api/auth/refresh`
4. **AuthService** (`bondy_server/src/service/auth.service.ts:113`) validates refresh token
5. **New token pair** returned and stored
6. **Original request retried** with new access token

## Key Abstractions

**AI Provider Factory:**
- Purpose: Abstract AI provider implementation (mock vs OpenAI)
- Examples: `bondy_server/src/factory/ai-provider.factory.ts`, `bondy_server/src/abstract/abstract-ai-provider.ts`
- Pattern: Factory pattern with provider interface

**Safety Guardrails:**
- Purpose: Content moderation for user-generated content
- Examples: `bondy_server/src/service/safety-guardrails.ts`, `bondy_server/src/types/crisis-keywords.ts`
- Pattern: Chain of responsibility for content checking

**Survey System:**
- Purpose: Multi-step questionnaire with scoring
- Examples: `bondy_server/src/service/survey.service.ts`, `Bondy_App/lib/screens/survey/`
- Pattern: Template-Question-Option hierarchy with score mapping

**Swipe/Discover Matching:**
- Purpose: Dating app core matching mechanics
- Examples: `bondy_server/src/service/swipe.service.ts`, `bondy_server/src/service/discover.service.ts`
- Pattern: Tinder-style swipe with bidirectional match detection

## Entry Points

**Server Entry Point:**
- Location: `bondy_server/src/app/api/health/route.ts` (health check)
- Triggers: HTTP requests to `/api/*` routes
- Responsibilities: Route handling, middleware chain, response formatting

**Server Prisma:**
- Location: `bondy_server/src/lib/prisma.ts`
- Exports: Prisma client singleton for database access

**Flutter Entry Point:**
- Location: `Bondy_App/lib/main.dart`
- Triggers: App launch
- Responsibilities: Initialize providers, define routes, app configuration

## Architectural Constraints

- **Threading:** Node.js single-threaded event loop (Next.js handles concurrency via worker threads for compute)
- **Global state:** Server uses module-level singletons (e.g., `authService`, `authRepository`); Flutter uses Provider for scoped state
- **Circular imports:** Not detected in exploration
- **Database:** PostgreSQL via Prisma ORM; directUrl for migrations, DATABASE_URL for application
- **File storage:** Supabase for file uploads (photos, images)
- **Auth storage:** Refresh tokens stored in database with hashed token

## Anti-Patterns

### Direct Route-to-Repository Access

**What happens:** API routes sometimes call repository directly instead of going through service layer
**Why it's wrong:** Bypasses business logic, validation, and orchestration that services provide
**Do this instead:** Route calls Service method, Service calls Repository

### Missing Error Types

**What happens:** Services throw raw `Error` objects with Vietnamese messages
**Why it's wrong:** No typed errors, inconsistent error handling across the codebase
**Do this instead:** Create specific error classes in `bondy_server/src/error/`, use discriminated unions

### Hardcoded Route Handlers

**What happens:** Each route file manually handles auth middleware and response formatting
**Why it's wrong:** Repetitive code, inconsistent middleware application
**Do this instead:** Use higher-order functions or base route classes for common patterns

## Error Handling

**Strategy:** try-catch with typed exceptions, HTTP status code mapping

**Patterns:**
- Services throw `Error` with message string (no structured error type)
- API routes catch errors and return `NextResponse.json({ error }, { status: code })`
- Flutter `ApiClient` catches responses and throws `ApiClientException`
- ViewModels catch service exceptions and set error state

## Cross-Cutting Concerns

**Logging:** `console.error` in services for errors; no centralized logging framework
**Validation:** Zod schemas in DTOs for request validation
**Authentication:** JWT Bearer tokens with refresh token rotation in database
**Error Handling:** Try-catch blocks with error messages returned as JSON

---

*Architecture analysis: 2026-05-17*
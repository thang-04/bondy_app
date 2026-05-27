# Codebase Structure

**Analysis Date:** 2026-05-17

## Directory Layout

```
bondy/                           # Monorepo root
├── bondy_server/                # Next.js REST API backend
│   ├── prisma/
│   │   ├── schema.prisma       # Database schema
│   │   ├── migrations/         # Prisma migrations
│   │   ├── seed-interests.js   # Interest seeding
│   │   └── seed-survey.js      # Survey seeding
│   ├── src/
│   │   ├── abstract/           # Abstract classes (AI providers)
│   │   ├── app/api/            # Next.js App Router endpoints
│   │   │   ├── ai/             # AI conversation endpoints
│   │   │   ├── auth/            # Authentication endpoints
│   │   │   ├── chats/           # Chat/messaging endpoints
│   │   │   ├── discover/        # Profile discovery endpoints
│   │   │   ├── healing/         # Healing content endpoints
│   │   │   ├── health/          # Health check endpoint
│   │   │   ├── home/            # Home dashboard endpoints
│   │   │   ├── interests/       # Interests endpoints
│   │   │   ├── profile/         # Profile management endpoints
│   │   │   ├── surveys/         # Survey endpoints
│   │   │   ├── swipes/          # Swipe action endpoints
│   │   │   └── upload/          # File upload endpoint
│   │   ├── config/             # Configuration (env, AI provider)
│   │   ├── dto/                # Data Transfer Objects
│   │   ├── entity/             # Entity definitions
│   │   ├── enums/              # Enum definitions
│   │   ├── error/              # Custom error classes
│   │   ├── exception/          # Exception handlers
│   │   ├── factory/            # Factory classes
│   │   ├── interface/          # Interface definitions
│   │   ├── lib/                # Utilities (JWT, Prisma client)
│   │   ├── mapper/             # Data mappers
│   │   ├── middleware/         # Express/Next.js middleware
│   │   ├── provider/           # Provider implementations
│   │   ├── proxy.ts            # Proxy configuration
│   │   ├── repository/        # Data access layer
│   │   ├── security/           # Security utilities
│   │   ├── service/            # Business logic layer
│   │   ├── types/              # Type definitions
│   │   ├── utils/              # Utility functions
│   │   └── wrapper/            # Wrapper classes (OpenTelemetry)
│   └── package.json
│
├── Bondy_App/                  # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart           # App entry point
│   │   ├── models/             # Data models
│   │   ├── screens/            # UI screens
│   │   │   ├── auth/           # Authentication screens
│   │   │   ├── chat/           # Chat/messaging screens
│   │   │   ├── discover/       # Discovery/matching screens
│   │   │   ├── healing/       # Healing content screens
│   │   │   ├── home/           # Home dashboard
│   │   │   ├── profile/        # Profile screens
│   │   │   ├── relationship/   # Relationship features
│   │   │   ├── settings/       # Settings screens
│   │   │   ├── social/         # Social features
│   │   │   └── survey/         # Survey screens
│   │   ├── services/           # API services
│   │   ├── theme/              # App theming
│   │   ├── viewmodels/         # State management
│   │   └── widgets/            # Shared widgets
│   ├── pubspec.yaml
│   └── assets/                 # App assets (images)
│
├── .planning/codebase/          # Generated documentation
├── CLAUDE.md                    # Project instructions
├── DESIGN.md                    # Design documentation
└── AGENTS.md                    # Agent instructions
```

## Directory Purposes

**`bondy_server/prisma/`:**
- Purpose: Database schema and migrations
- Contains: `schema.prisma`, `migrations/`, seed files
- Key files: `schema.prisma` - defines all database models

**`bondy_server/src/app/api/`:**
- Purpose: HTTP API endpoints using Next.js App Router
- Contains: Route handlers organized by domain
- Key files: `health/route.ts`, `auth/login/route.ts`

**`bondy_server/src/service/`:**
- Purpose: Business logic implementation
- Contains: Service classes for each domain
- Key files: `auth.service.ts`, `chat.service.ts`, `discover.service.ts`, `survey.service.ts`

**`bondy_server/src/repository/`:**
- Purpose: Data access layer
- Contains: Repository classes wrapping Prisma queries
- Key files: `auth.repository.ts`, `chat.repository.ts`

**`bondy_server/src/dto/`:**
- Purpose: Request/response data transfer objects with Zod validation
- Contains: DTOs for each domain

**`bondy_server/src/lib/`:**
- Purpose: Shared utilities
- Contains: `prisma.ts` (Prisma client), `jwt.ts` (JWT utilities), `supabase.ts` (Supabase client)

**`Bondy_App/lib/screens/`:**
- Purpose: Flutter UI screens organized by feature
- Contains: 10 feature directories (auth, chat, discover, healing, home, profile, relationship, settings, social, survey)

**`Bondy_App/lib/services/`:**
- Purpose: API communication and external services
- Contains: `api_client.dart` (HTTP client with auth), service classes for each domain

**`Bondy_App/lib/viewmodels/`:**
- Purpose: State management using Provider/ChangeNotifier
- Contains: ViewModels for auth, survey, discover, home, ai_coach

**`Bondy_App/lib/models/`:**
- Purpose: Data models for Flutter app
- Contains: `home_widget_model.dart`, `survey_question_model.dart`, `discover_profile_model.dart`, `user_profile_model.dart`

**`Bondy_App/lib/widgets/`:**
- Purpose: Reusable UI components
- Contains: `bondy_button.dart`, `bondy_logo.dart`, `survey_option_card.dart`, home widgets, location widgets, AI suggestion widgets

## Key File Locations

**Entry Points:**
- `Bondy_App/lib/main.dart`: Flutter app entry point with route configuration
- `bondy_server/src/app/api/health/route.ts`: API health check

**Server Configuration:**
- `bondy_server/src/config/env.ts`: Environment variable configuration
- `bondy_server/src/config/ai-provider.config.ts`: AI provider configuration
- `bondy_server/prisma/schema.prisma`: Database schema definition

**Authentication:**
- `bondy_server/src/lib/jwt.ts`: JWT token generation and verification
- `bondy_server/src/middleware/auth.middleware.ts`: Auth middleware for routes
- `bondy_server/src/service/auth.service.ts`: Authentication business logic
- `Bondy_App/lib/services/auth_service.dart`: Flutter auth service with token storage

**Database:**
- `bondy_server/src/lib/prisma.ts`: Prisma client singleton
- `bondy_server/prisma/schema.prisma`: Full database schema

**API Client:**
- `Bondy_App/lib/services/api_client.dart`: Centralized HTTP client with auth handling

## Naming Conventions

**Files (Server - TypeScript):**
- Route files: `route.ts` (lowercase)
- Service classes: `{name}.service.ts` (camelCase, PascalCase class name)
- Repository classes: `{name}.repository.ts` (camelCase, PascalCase class name)
- DTOs: `{name}.dto.ts` (camelCase)
- Middleware: `{name}.middleware.ts` (camelCase)

**Files (Flutter - Dart):**
- Screens: `{screen_name}_screen.dart` (snake_case)
- ViewModels: `{name}_viewmodel.dart` (snake_case)
- Services: `{name}_service.dart` (snake_case)
- Models: `{name}_model.dart` (snake_case)
- Widgets: `{name}.dart` (snake_case for files, PascalCase for classes)

**Directories:**
- Server: lowercase (e.g., `app/api/auth`, `service`, `repository`)
- Flutter: snake_case (e.g., `screens/auth`, `viewmodels/auth`)

**TypeScript/JavaScript:**
- Variables/functions: camelCase
- Classes/Types: PascalCase
- Constants: UPPER_SNAKE_CASE
- File names: camelCase or snake_case (mixed usage)

**Dart:**
- Variables/functions/classes: PascalCase
- Private members: _underscore prefix
- File names: snake_case

## Where to Add New Code

**New API Endpoint (Server):**
1. Create route file: `bondy_server/src/app/api/{domain}/{action}/route.ts`
2. Add DTO in `bondy_server/src/dto/{name}.dto.ts` with Zod schema
3. Add service method in `bondy_server/src/service/{domain}.service.ts`
4. Add repository method in `bondy_server/src/repository/{domain}.repository.ts` if needed
5. Update `bondy_server/src/dto/index.ts` to export new DTO

**New Service (Server):**
- Location: `bondy_server/src/service/{name}.service.ts`
- Use existing repository pattern: inject repositories, return domain objects

**New Flutter Screen:**
1. Create file: `Bondy_App/lib/screens/{domain}/{name}_screen.dart`
2. Add route in `Bondy_App/lib/main.dart` routes map
3. Add ViewModel in `Bondy_App/lib/viewmodels/{name}_viewmodel.dart` if state needed
4. Add Service in `Bondy_App/lib/services/{name}_service.dart` if API calls needed

**New Flutter ViewModel:**
- Location: `Bondy_App/lib/viewmodels/{domain}/{name}_viewmodel.dart`
- Extend `ChangeNotifier`, use `notifyListeners()` for state updates

**New Flutter Service:**
- Location: `Bondy_App/lib/services/{name}_service.dart`
- Use `ApiClient` for HTTP calls, inject `AuthService` for token management

**New Database Model:**
1. Add model to `bondy_server/prisma/schema.prisma`
2. Run `npx prisma format` to validate
3. Run `npx prisma db push` or create migration

## Special Directories

**`bondy_server/node_modules/`:**
- Purpose: npm dependencies
- Generated: Yes
- Committed: No (gitignored)

**`Bondy_App/.dart_tool/`:**
- Purpose: Dart tooling cache
- Generated: Yes
- Committed: No (gitignored)

**`Bondy_App/.idea/`:**
- Purpose: Android Studio/WebStorm configuration
- Generated: Yes
- Committed: Partial (caches and libraries only)

**`bondy_server/prisma/migrations/`:**
- Purpose: Database migration history
- Generated: Yes (via `prisma migrate`)
- Committed: Yes (version controlled)

**`.planning/codebase/`:**
- Purpose: Generated architecture and documentation
- Generated: Yes (by AI mapping agent)
- Committed: Yes

---

*Structure analysis: 2026-05-17*
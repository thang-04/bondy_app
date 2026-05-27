# Testing Patterns

**Analysis Date:** 2026-05-17

## Test Framework

### TypeScript (bondy_server)

**Runner:** Vitest v1.x

- Config: `vitest.config.ts`
- Config: `vitest.integration.config.ts` (separate integration config)
- Environment: Node.js

**Run Commands:**
```bash
npm test                    # Run unit tests
npm run test:watch          # Watch mode (if configured)
```

**Assertion Library:** Vitest built-in (`expect`)

### Dart (Bondy_App)

**Runner:** Flutter Test

- Config: `flutter_test` SDK
- Integration tests: `integration_test` SDK

**Run Commands:**
```bash
flutter test                      # Run all tests
flutter test widget_test.dart     # Run specific test file
```

## Test File Organization

### bondy_server

```
tests/
├── setup/
│   ├── test-env.ts           # Test environment setup
│   └── integration-env.ts     # Integration environment
├── unit/                     # Unit tests (mirrors src/ structure)
│   ├── app/api/
│   ├── config/
│   ├── dto/
│   ├── error/
│   ├── middleware/
│   ├── repository/
│   ├── service/
│   └── lib/
├── integration/              # Integration tests
│   ├── auth.integration.test.ts
│   └── helpers/
│       ├── db.ts
│       └── http.ts
└── system/                   # E2E/system tests
    ├── api-doc.spec.ts
    ├── auth-password.spec.ts
    ├── auth-token.spec.ts
    ├── auth.spec.ts
    ├── flows.spec.ts
    ├── mobile-contract.spec.ts
    ├── security.spec.ts
    └── swagger.spec.ts
```

**Test File Naming:**

- Unit tests: `*.test.ts`
- Integration tests: `*.integration.test.ts`
- System/Playwright tests: `*.spec.ts`

**Location:** Tests live in `tests/` directory separate from `src/`

### Bondy_App

```
test/
├── widget_test.dart          # Main widget smoke test
└── (minimal test coverage)
```

**Location:** Tests co-located in `test/` directory

## Test Structure

### TypeScript Unit Test Pattern

```typescript
import { beforeEach, describe, expect, it, vi } from "vitest";

import { authRepository } from "@/repository/auth.repository";
import { AuthService } from "@/service/auth.service";
import { emailDeliveryService } from "@/service/email-delivery.service";
import { JwtUtils } from "@/lib/jwt";

describe("AuthService", () => {
  let service: AuthService;

  beforeEach(() => {
    vi.restoreAllMocks();
    service = new AuthService();
    vi.spyOn(JwtUtils, "generateTokenPair").mockReturnValue(tokens);
  });

  it("logs users in with password accounts", async () => {
    vi.spyOn(authRepository, "findByEmail").mockResolvedValue(user as never);
    vi.spyOn(authRepository, "verifyPassword").mockResolvedValue(true);

    await expect(
      service.login({ email: user.email, password: "Password123" }),
    ).resolves.toEqual({ /* expected result */ });
  });

  it("rejects invalid login attempts", async () => {
    vi.spyOn(authRepository, "findByEmail").mockResolvedValueOnce(null);
    await expect(
      service.login({ email: user.email, password: "Password123" }),
    ).rejects.toThrow("Email hoặc mật khẩu không đúng");
  });
});
```

### Dart Test Pattern

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      // dotenv.load may fail in test context, ignore
    }
  });

  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BondyApp());
    expect(find.byType(BondyApp), findsOneWidget);
  });
}
```

## Mocking

### TypeScript (Vitest)

**Framework:** Vitest built-in `vi` (mock functions)

**Prisma Mock Pattern:**
```typescript
const prismaMocks = vi.hoisted(() => {
  const mockPrisma = {
    account: {},
    session: {},
    user: {
      findUnique: vi.fn(),
      create: vi.fn(),
      update: vi.fn(),
    },
    // ...
  };
  return {
    mockPrisma,
    prismaClientMock: vi.fn(function PrismaClient() {
      return mockPrisma;
    }),
  };
});

vi.mock('@prisma/client', () => ({
  PrismaClient: prismaClientMock,
}));
```

**Service Mocking:**
```typescript
vi.spyOn(authRepository, "findByEmail").mockResolvedValue(user as never);
vi.spyOn(JwtUtils, "generateTokenPair").mockReturnValue(tokens);
```

**Mock clearing:** `vi.clearAllMocks()` in `beforeEach`

### Dart (Flutter Test)

**Framework:** No mock library detected in pubspec.yaml

**Limited mocking:** Manual stubbing in services

## Fixtures and Factories

### TypeScript

**Test Data:** Defined inline in test files

```typescript
const user = {
  id: "user-id",
  email: "user@example.com",
  name: "User",
  emailVerified: null,
  image: null,
  createdAt: new Date("2026-01-01T00:00:00Z"),
  profile: { id: "profile-id" },
  passwordHash: "hash",
};

const tokens = {
  accessToken: "access-token",
  refreshToken: "refresh-token",
};
```

**Location:** Inline in each test file (no dedicated fixtures directory)

## Coverage

### TypeScript

**Requirements:** 100% thresholds enforced in `vitest.config.ts`:

```typescript
coverage: {
  thresholds: {
    statements: 100,
    branches: 100,
    functions: 100,
    lines: 100,
  },
}
```

**View Coverage:**
```bash
# Coverage output in ./coverage directory
# Reports: text, html, json
```

**Excluded from coverage:**
- `src/**/*.d.ts` (type declarations)
- `src/types/**` (type definitions)
- `node_modules`, `.next`, `coverage`

### Dart

**Coverage:** Not enforced

## Test Types

### Unit Tests

**TypeScript:** 37 test files found in `tests/unit/`

- Route handlers: `tests/unit/app/api/*.test.ts`
- Services: `tests/unit/service/*.test.ts`
- Repositories: `tests/unit/repository/*.test.ts`
- DTOs: `tests/unit/dto/*.test.ts`
- Middleware: `tests/unit/middleware/*.test.ts`

**Dart:** Minimal unit tests (only `widget_test.dart`)

### Integration Tests

**TypeScript:** `tests/integration/auth.integration.test.ts`

- Uses separate `integration-env.ts` setup
- Helper files: `db.ts`, `http.ts`

**Dart:** `integration_test` SDK available but not used

### E2E/System Tests

**TypeScript:** Playwright tests in `tests/system/`

- Config: `playwright.config.ts`
- Tests: API docs, auth flows, mobile contract, security, swagger

**Dart:** None detected

## Common Patterns

### Async Testing

**TypeScript:**
```typescript
it("logs users in with password accounts", async () => {
  await expect(service.login({ email, password })).resolves.toEqual(expected);
});
```

### Error Testing

**TypeScript:**
```typescript
it("rejects invalid login attempts", async () => {
  vi.spyOn(authRepository, "findByEmail").mockResolvedValueOnce(null);
  await expect(
    service.login({ email, password }),
  ).rejects.toThrow("Email hoặc mật khẩu không đúng");
});
```

### Environment Mocking

**TypeScript:**
```typescript
const mutableEnv = process.env as Record<string, string | undefined>;
mutableEnv.JWT_SECRET = 'unit-test-secret';
mutableEnv.NODE_ENV = 'test';
mutableEnv.PORT = '3000';
```

## Test Setup

### TypeScript

**Setup File:** `tests/setup/test-env.ts`

- Mocks Prisma client globally
- Sets test environment variables
- Clears mocks before each test

### Dart

**Setup:** `setUpAll()` in `widget_test.dart`

- Initializes `TestWidgetsFlutterBinding`
- Loads `.env` file (optional, ignores failures)

---

*Testing analysis: 2026-05-17*
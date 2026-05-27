# Coding Conventions

**Analysis Date:** 2026-05-17

## Naming Patterns

**Files:**

- TypeScript: `camelCase.ts` (e.g., `auth.service.ts`, `auth.middleware.ts`)
- Dart: `snake_case.dart` (e.g., `auth_service.dart`, `api_client.dart`)

**Classes:**

- TypeScript: `PascalCase` (e.g., `AuthService`, `AuthRepository`)
- Dart: `PascalCase` (e.g., `AuthService`, `ApiClient`)

**Functions/Methods:**

- TypeScript: `camelCase` (e.g., `findByEmail`, `generateTokenPair`)
- Dart: `camelCase` (e.g., `sendOtp`, `refreshAccessToken`)

**Variables:**

- TypeScript: `camelCase` (e.g., `accessToken`, `refreshToken`)
- Dart: `camelCase` (e.g., `accessToken`, `refreshToken`)

**Types/Interfaces:**

- TypeScript: `PascalCase` (e.g., `LoginDto`, `TokenPair`, `AuthUser`)
- Dart: `PascalCase` (e.g., `SendOtpResult`, `VerifyOtpResult`)

**Constants:**

- TypeScript: `camelCase` or `UPPER_SNAKE_CASE` (e.g., `ACCESS_EXPIRY` in class as `readonly`)
- Dart: `camelCase` with `static const` (e.g., `static const _accessTokenKey = 'accessToken'`)

## Code Style

**Formatting:**

- TypeScript: Uses Next.js defaults, no explicit prettier config found
- Dart: Uses `flutter_lints` (default Flutter lint set)

**Linting:**

- TypeScript: ESLint configured via Next.js
- Dart: `analysis_options.yaml` with `include: package:flutter_lints/flutter.yaml`

**Type Safety:**

- TypeScript: `strict: true` in `tsconfig.json`
- Dart: Strong mode enabled via Flutter SDK

## Import Organization

**TypeScript (bondy_server):**

```typescript
// External imports
import { z } from "zod";
import bcrypt from 'bcryptjs';

// Internal path aliases
import { authRepository } from "@/repository/auth.repository";
import { loginSchema } from "@/dto/auth.dto";
```

Path alias: `@/` maps to `src/` directory

**Dart (Bondy_App):**

```dart
// Dart imports
import 'dart:convert';

// Package imports
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

// Relative imports for local files
import 'auth_service.dart';
import '../models/user_profile_model.dart';
```

## Error Handling

**TypeScript:**

```typescript
// Route-level error handling
export async function POST(req: NextRequest) {
  try {
    const result = await authService.login(validatedData);
    return NextResponse.json({ success: true, data: result });
  } catch (error: unknown) {
    console.error('Login error:', error);
    if (error instanceof Error) {
      return NextResponse.json(
        { success: false, error: error.message },
        { status: 401 }
      );
    }
    return NextResponse.json(
      { success: false, error: 'Đã xảy ra lỗi' },
      { status: 500 }
    );
  }
}
```

- Custom error classes: `AiProviderError` in `src/error/ai-provider.error.ts`
- Error messages in Vietnamese (user-facing)

**Dart:**

```dart
class ApiClientException implements Exception {
  final String message;
  final int? statusCode;

  const ApiClientException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

// Usage in services
throw const ApiClientException('Phiên đăng nhập đã hết hạn', statusCode: 401);
```

Custom exceptions: `ApiClientException`, `AuthRequiredException`, `SessionExpiredException`, `AuthServiceException`

## Logging

**TypeScript:**

- Use `console.error` for errors with context
- Use structured logging where appropriate

```typescript
console.error('Login error:', error);
console.error('Failed to send password reset email:', error);
```

**Dart:**

- Use `debugPrint` for debug logging (Flutter)
- No structured logging framework detected

## Comments

**TypeScript:**

- JSDoc style for DTOs and schemas
- Inline comments for complex logic

```typescript
// Helper: Generate tokens for user
private async generateTokensForUser(userId: string, email: string): Promise<TokenPair> {
```

**Dart:**

- Minimal comments, code should be self-documenting
- No specific documentation pattern observed

## Function Design

**Size:** Functions typically do one thing; complex logic extracted to helpers

**Parameters:**

- TypeScript: Use DTOs for complex input, single params for simple operations
- Dart: Use named parameters for complex methods

**Return Values:**

- TypeScript: Always return structured data (objects with `success`, `data`/`error`)
- Dart: Return typed objects (e.g., `SendOtpResult`, `VerifyOtpResult`)

## Module Design

**TypeScript:**

- Services: `src/service/` - business logic
- Repositories: `src/repository/` - data access
- DTOs: `src/dto/` - input validation schemas using Zod
- Middleware: `src/middleware/` - auth middleware

**Dart:**

- Services: `lib/services/` - API clients and business logic
- Models: `lib/models/` - data models
- ViewModels: `lib/viewmodels/` - state management
- Screens: `lib/screens/` - UI components
- Widgets: `lib/widgets/` - reusable UI components

## API Response Format

**TypeScript (bondy_server):**

```typescript
// Success
return NextResponse.json({ success: true, data: result });

// Error
return NextResponse.json({ success: false, error: error.message }, { status: 401 });
```

**Dart (Bondy_App):**

```dart
// Response decoding
if (response.statusCode < 200 || response.statusCode >= 300) {
  throw ApiClientException(
    body['error']?.toString() ?? 'Lỗi server: ${response.statusCode}',
    statusCode: response.statusCode,
  );
}
```

## Validation

**TypeScript:** Zod schemas in `src/dto/`

```typescript
export const loginSchema = z.object({
  email: z.string().email("Email không hợp lệ"),
  password: z.string().min(1, "Mật khẩu không được để trống"),
});
```

**Dart:** Manual validation in services (no formal schema library detected)

## Singleton Pattern

**TypeScript:** Module-level singleton instances

```typescript
export const authRepository = new AuthRepository();
export const authService = new AuthService();
```

**Dart:** Class instantiation in ViewModels

```dart
ChangeNotifierProvider(create: (_) => AuthViewModel()),
ChangeNotifierProvider(create: (_) => SurveyViewModel()),
```

---

*Convention analysis: 2026-05-17*
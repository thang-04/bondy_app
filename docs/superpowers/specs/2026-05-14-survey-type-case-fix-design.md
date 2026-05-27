# Spec: Chuẩn hóa surveyType thành UPPERCASE

## Problem Statement

`surveyType` đang bị case-sensitivity mismatch trong hệ thống:

- **Flutter app** gửi: `onboarding` (lowercase)
- **route.ts** chuyển thành: `ONBOARDING` (uppercase) trước khi query Prisma
- **Database** lưu nguyên giá trị gửi vào → case không nhất quán → query `ONBOARDING` không match `onboarding`

Kết quả: API `/api/surveys?surveyType=onboarding&status=active` trả về empty array dù có survey trong DB.

## Solution

Chuẩn hóa tất cả `surveyType` về **UPPERCASE** (`'ONBOARDING'`, `'PERSONALITY'`, `'RELATIONSHIP'`, `'WELLBEING'`).

## Changes

### 1. `src/dto/survey.dto.ts`

**Trước:**
```typescript
const surveyTypeSchema = z.preprocess(
  (value) => (typeof value === 'string' ? value.toLowerCase() : value),
  z.enum(['onboarding', 'personality', 'relationship', 'wellbeing'])
);
```

**Sau:**
```typescript
const surveyTypeSchema = z.enum(['ONBOARDING', 'PERSONALITY', 'RELATIONSHIP', 'WELLBEING']);
```

- Enum UPPERCASE
- Bỏ `preprocess` vì Zod enum sẽ validate đúng case
- **Lưu ý:** Flutter app hiện gửi lowercase → cần Flutter team cũng gửi uppercase HOẶC thêm preprocess normalize về uppercase ở đây (giữ lại preprocess nhưng đổi sang `.toUpperCase()`)

### 2. `src/app/api/surveys/route.ts`

**Trước:**
```typescript
surveyType: validatedQuery.surveyType?.toUpperCase() as typeof validatedQuery.surveyType,
```

**Sau:**
```typescript
surveyType: validatedQuery.surveyType, // Không cần uppercase nữa vì schema validate đã UPPERCASE
```

- Bỏ `.toUpperCase()` — enum đã là UPPERCASE

### 3. `src/repository/home.repository.ts`

**Giữ nguyên** — đã dùng `'ONBOARDING'` uppercase (line 15) → đúng intent.

### 4. Database Migration

Chuẩn hóa data hiện có trong `SurveyTemplate`:

```sql
UPDATE "SurveyTemplate" SET "surveyType" = 'ONBOARDING' WHERE "surveyType" = 'onboarding';
UPDATE "SurveyTemplate" SET "surveyType" = 'PERSONALITY' WHERE "surveyType" = 'personality';
UPDATE "SurveyTemplate" SET "surveyType" = 'RELATIONSHIP' WHERE "surveyType" = 'relationship';
UPDATE "SurveyTemplate" SET "surveyType" = 'WELLBEING' WHERE "surveyType" = 'wellbeing';
```

### 5. Seed Data

Sửa tất cả seed scripts/new surveys dùng UPPERCASE `surveyType`.

### 6. Code Audit — Các nơi khác

Kiểm tra và sửa hardcoded lowercase `surveyType` trong:
- `tests/unit/app/api/survey-routes.test.ts` — đã dùng lowercase `'onboarding'` → đổi thành `'ONBOARDING'`

## Acceptance Criteria

1. Query `/api/surveys?surveyType=ONBOARDING&status=active` trả về surveys đúng (không empty)
2. Tất cả `SurveyTemplate.surveyType` trong DB là UPPERCASE
3. Unit tests pass
4. Flutter app hiển thị đúng survey onboarding sau khi tạo tài khoản

## Files Affected

- `bondy_server/src/dto/survey.dto.ts`
- `bondy_server/src/app/api/surveys/route.ts`
- Database: `SurveyTemplate` rows
- `bondy_server/tests/unit/app/api/survey-routes.test.ts` (if applicable)
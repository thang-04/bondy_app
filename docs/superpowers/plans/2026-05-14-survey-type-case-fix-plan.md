# Survey Type Case Normalization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Chuẩn hóa `surveyType` thành UPPERCASE trong toàn bộ hệ thống, fix case-sensitivity mismatch gây ra empty array khi query survey.

**Architecture:** Thay đổi Zod schema để normalize case về UPPERCASE (giữ preprocess nhưng đổi thành `.toUpperCase()`), bỏ `.toUpperCase()` thừa ở route.ts, update test expectations, chạy DB migration.

**Tech Stack:** TypeScript, Zod, Prisma, Next.js App Router, Vitest

---

## Pre-Flight: Audit Codebase for surveyType Usage

**Files to check:**
- `bondy_server/src/dto/survey.dto.ts`
- `bondy_server/src/app/api/surveys/route.ts`
- `bondy_server/src/repository/home.repository.ts`
- `bondy_server/tests/unit/app/api/survey-routes.test.ts`

Run: `grep -rn "surveyType" --include="*.ts" bondy_server/src/ bondy_server/tests/`

Expected: Các hardcoded values phải là UPPERCASE sau khi fix. Ghi nhận tất cả lowercase occurrences để sửa.

---

## Task 1: Update `survey.dto.ts` Schema

**Files:**
- Modify: `bondy_server/src/dto/survey.dto.ts`

- [ ] **Step 1: Verify current code**

```typescript
// Current lines 9-13 in survey.dto.ts
const surveyTypeSchema = z.preprocess(
  (value) => (typeof value === 'string' ? value.toLowerCase() : value),
  z.enum(['onboarding', 'personality', 'relationship', 'wellbeing'])
);
```

- [ ] **Step 2: Update surveyTypeSchema to normalize to UPPERCASE**

```typescript
// Replace lines 9-13
const surveyTypeSchema = z.preprocess(
  (value) => (typeof value === 'string' ? value.toUpperCase() : value),
  z.enum(['ONBOARDING', 'PERSONALITY', 'RELATIONSHIP', 'WELLBEING'])
);
```

- [ ] **Step 3: Verify status schema also uses uppercase (for consistency)**

```typescript
// Lines 3-7 — verify status also normalizes to UPPERCASE
const surveyStatusSchema = z
  .preprocess(
    (value) => (typeof value === 'string' ? value.toUpperCase() : value),
    z.enum(['DRAFT', 'ACTIVE', 'ARCHIVED'])
  );
```

**Note:** Nếu status schema vẫn dùng lowercase (`'draft', 'active', 'archived'`), cần đổi thành UPPERCASE để nhất quán. Kiểm tra file và update nếu cần.

- [ ] **Step 4: Commit**

```bash
cd /c/Users/ADMIN/Downloads/bondy
git add bondy_server/src/dto/survey.dto.ts
git commit -m "fix(survey.dto): normalize surveyType to UPPERCASE via preprocess"
```

---

## Task 2: Update `surveys/route.ts` — Remove Redundant `.toUpperCase()`

**Files:**
- Modify: `bondy_server/src/app/api/surveys/route.ts`

- [ ] **Step 1: Verify current code at lines 21-25**

```typescript
const normalizedQuery = {
  ...validatedQuery,
  status: validatedQuery.status?.toUpperCase() as typeof validatedQuery.status,
  surveyType: validatedQuery.surveyType?.toUpperCase() as typeof validatedQuery.surveyType,
};
```

- [ ] **Step 2: Remove redundant `.toUpperCase()` calls**

Vì schema đã tự normalize qua preprocess, `.toUpperCase()` ở route.ts là thừa:

```typescript
const normalizedQuery = {
  ...validatedQuery,
  // status và surveyType đã được normalize bởi Zod schema preprocessing
};
```

- [ ] **Step 3: Verify route.ts still passes correct data**

Sau khi bỏ `.toUpperCase()`, `normalizedQuery.surveyType` sẽ là giá trị UPPERCASE đã được normalize bởi schema (ví dụ: `'ONBOARDING'`).

- [ ] **Step 4: Commit**

```bash
git add bondy_server/src/app/api/surveys/route.ts
git commit -m "fix(surveys/route): remove redundant toUpperCase — schema handles normalization"
```

---

## Task 3: Update Unit Test Expectations

**Files:**
- Modify: `bondy_server/tests/unit/app/api/survey-routes.test.ts`

- [ ] **Step 1: Verify test expectations at line 32-38**

```typescript
// Current test expects ONBOARDING (already correct)
expect(getSurveysSpy).toHaveBeenCalledWith({
  page: 1,
  limit: 10,
  status: 'ACTIVE',
  surveyType: 'ONBOARDING',  // ← Already correct
  search: undefined,
});
```

- [ ] **Step 2: Verify the test input still makes sense**

Test gửi `surveyType=onboarding` (lowercase from Flutter). Với schema preprocess đổi thành `.toUpperCase()`, giá trị nhận được ở service vẫn là `'ONBOARDING'` — test vẫn pass. Không cần thay đổi test.

**Lưu ý:** Test input là lowercase (`onboarding`) nhưng expected output là UPPERCASE (`ONBOARDING`) — đây là behavior đúng, thể hiện việc Flutter gửi lowercase và API normalize về UPPERCASE.

- [ ] **Step 3: Run test to verify**

```bash
cd /c/Users/ADMIN/Downloads/bondy/bondy_server
npx vitest run tests/unit/app/api/survey-routes.test.ts
```

Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add bondy_server/tests/unit/app/api/survey-routes.test.ts
git commit -m "test(survey-routes): verify ONBOARDING normalization (no changes needed)"
```

---

## Task 4: Database Migration — Normalize Existing surveyType Values

**Files:**
- Database: `SurveyTemplate` rows in Supabase PostgreSQL

- [ ] **Step 1: Create Prisma migration**

```bash
cd /c/Users/ADMIN/Downloads/bondy/bondy_server
npx prisma migrate dev --name normalize_survey_type_to_uppercase
```

- [ ] **Step 2: Or run raw SQL if migration not applicable**

```sql
-- Chuẩn hóa tất cả surveyType về UPPERCASE
UPDATE "SurveyTemplate" SET "surveyType" = 'ONBOARDING' WHERE "surveyType" = 'onboarding';
UPDATE "SurveyTemplate" SET "surveyType" = 'PERSONALITY' WHERE "surveyType" = 'personality';
UPDATE "SurveyTemplate" SET "surveyType" = 'RELATIONSHIP' WHERE "surveyType" = 'relationship';
UPDATE "SurveyTemplate" SET "surveyType" = 'WELLBEING' WHERE "surveyType" = 'wellbeing';
```

**Note:** Chạy SQL trực tiếp trên Supabase dashboard hoặc qua Prisma Studio.

- [ ] **Step 3: Verify migration**

```bash
npx prisma db pull --force
# Hoặc kiểm tra qua Supabase dashboard
```

---

## Task 5: Code Audit — Check for Other surveyType References

**Files:**
- Audit: All `.ts` files in `bondy_server/src/` and `bondy_server/tests/`

- [ ] **Step 1: Search for any lowercase surveyType hardcodes**

```bash
grep -rni "surveyType.*['\"]onboarding\|surveyType.*['\"]personality\|surveyType.*['\"]relationship\|surveyType.*['\"]wellbeing" --include="*.ts" bondy_server/
```

Expected: Không có kết quả nào. Nếu có, sửa UPPERCASE.

- [ ] **Step 2: Search for any `.toLowerCase()` on surveyType**

```bash
grep -rni "surveyType.*toLowerCase\|toLowerCase.*surveyType" --include="*.ts" bondy_server/
```

Expected: Không có. Nếu có, báo lỗi và sửa.

- [ ] **Step 3: Commit audit results**

```bash
git add -A
git commit -m "chore: audit surveyType case — all references UPPERCASE"
```

---

## Task 6: End-to-End Verification

- [ ] **Step 1: Run full test suite**

```bash
cd /c/Users/ADMIN/Downloads/bondy/bondy_server
npx vitest run
```

Expected: Tất cả tests PASS

- [ ] **Step 2: Manual API test**

```bash
curl "http://localhost:3001/api/surveys?surveyType=ONBOARDING&status=ACTIVE"
```

Expected: Trả về surveys (không empty) nếu có data trong DB.

- [ ] **Step 3: Push changes**

```bash
cd /c/Users/ADMIN/Downloads/bondy
git pull --rebase
git push
git status  # Must show "up to date with origin"
```

---

## Acceptance Criteria Check

- [ ] `GET /api/surveys?surveyType=ONBOARDING&status=ACTIVE` trả về surveys đúng
- [ ] Tất cả tests pass
- [ ] Tất cả `surveyType` values trong code là UPPERCASE
- [ ] Database `SurveyTemplate` rows đã được normalize về UPPERCASE
- [ ] Changes đã push lên remote

---

## Spec Coverage Check

| Spec Requirement | Task |
|-----------------|------|
| dto/survey.dto.ts: enum UPPERCASE, preprocess `.toUpperCase()` | Task 1 |
| route.ts: bỏ `.toUpperCase()` thừa | Task 2 |
| Database migration: UPDATE SurveyTemplate | Task 4 |
| Test expectations: UPPERCASE | Task 3 |
| Code audit: tìm và sửa các references khác | Task 5 |
| Verification: tests + manual API test | Task 6 |

**Spec gaps:** Không có gaps — tất cả requirements từ spec đều được cover bởi các tasks trên.
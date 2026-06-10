# Design Spec: Onboarding DeepMatch Flow & Survey Result Redesign

This document outlines the design and implementation details for swapping the onboarding step order (Interest -> DeepMatch -> Survey) and redesigning the survey result screen to render direct inline options instead of popup bottom sheets.

## Objective

1. **Onboarding Flow Swapping**:
   - Swaps the order of steps during onboarding: After completing the **Interest Setup**, the user is navigated directly to **DeepMatch Setup** (`/deep-match/setup`), rather than going to **Survey Intro** (`/survey/intro`).
   - Once the user completes the DeepMatch setup, they proceed to the **Survey Intro** -> **Survey Questions** -> **Survey Result**.

2. **Survey Result Screen Redesign**:
   - Removes all floating popups (modal bottom sheets) from `SurveyResultScreen`.
   - The UI screen itself changes dynamically based on the survey outcome (`_needsHealing` vs. ready for matching).
   - Displays different pathway lists and action buttons on the page directly.

---

## Technical Design

### 1. Onboarding Router Modifications

**File:** `lib/services/onboarding_router.dart`
- In `navigateToNextStep`, check if the user has completed their DeepMatch setup.
- DeepMatch is considered complete if the user profile contains `zodiacSign != null`, `desiredPartnerType != null`, and `freeTimeSlots` list is not empty.
- If the next onboarding step is `COMPLETE_SURVEY` (or if `profileComplete == true` but `surveyComplete != true`), check `isDeepMatchComplete`:
  - If **false**: Navigate to `/deep-match/setup` with `arguments: {'targetRoute': '/survey/intro'}`.
  - If **true**: Proceed to `/survey/intro`.

### 2. Auth Gate Screen Modifications

**File:** `lib/screens/auth/auth_gate_screen.dart`
- In `_restoreSession()`, align session restoration routing with the onboarding router logic.
- If the user has completed their profile but not their survey:
  - Check if `isDeepMatchComplete` is false. If so, route to `/deep-match/setup` with `arguments: {'targetRoute': '/survey/intro'}`.
  - Otherwise, route to `/survey/intro`.
- If the next action is `COMPLETE_SURVEY` based on `profileCompletionStatus`, perform the same check and route accordingly.

### 3. Survey Result Screen Modifications

**File:** `lib/screens/survey/survey_result_screen.dart`
- Remove the didChangeDependencies post-frame callback calling `_showPlanPrompt()`.
- Delete functions `_showPlanPrompt()`, `_showHealingPlanPrompt()`, and `_showMatchingPrompt()`.
- Add a boolean flag `_isSaving` to track the loading state when the user selects the "Bắt đầu ngay" healing option.
- Implement the dynamic UI rendering in the `build` method:
  - **Case 1: `_needsHealing == true`** (user needs healing)
    - Icon: `Icons.favorite` (Pink/red themed circle background)
    - Title: "Cảm ơn bạn đã chia sẻ!"
    - Subtitle: "Bondy đã hiểu thêm về bạn.\nĐây là lộ trình chữa lành dành riêng cho bạn."
    - Pathway list items:
      - 🌿 Tuần 1-2: Chữa lành nội tâm
      - 👥 Tuần 3-4: Kết nối nhẹ nhàng
      - 💖 Tuần 5+: Sẵn sàng mở lòng
    - Inline buttons:
      - **Bắt đầu ngay** (Primary button): Calls `_healingService.startRecommendedPlan()` and navigates to the healing plan route.
      - **Xem trước** (Secondary outlined button): Navigates to the healing plan route in preview mode (`preview: true`).
      - **Để sau** (Text button): Navigates to `/home/healing`.
  - **Case 2: `_needsHealing == false`** (user ready for matching)
    - Icon: `Icons.people_alt` (Green themed circle background, e.g. `Color(0xFF10B981)`)
    - Title: "Cảm ơn bạn đã chia sẻ!"
    - Subtitle: "Bondy đã hiểu thêm về bạn.\nBạn đã sẵn sàng để khám phá những kết nối mới."
    - Pathway list items:
      - 🧩 Tuần 1-2: Ghép đôi tương hợp
      - 💬 Tuần 3-4: Trò chuyện sâu sắc
      - 🌟 Tuần 5+: Xây dựng gắn kết
    - Inline buttons:
      - **Khám phá ngay** (Primary button): Navigates to `/discover`.
      - **Xem Content Hub trước** (Secondary outlined button): Navigates to `/home/healing`.

---

## Verification Plan

### Manual Verification
1. Log in with a user that has completed the profile but not yet completed DeepMatch.
2. Complete Interest Selection and click next. Verify that the app navigates to the DeepMatch Setup screen instead of the Survey Intro screen.
3. Complete the DeepMatch setup. Verify that the app transitions to the Survey Intro screen.
4. Complete the survey and reach the Survey Result screen.
5. Verify that no popups/bottom sheets appear on the Survey Result screen.
6. Verify the UI matches the survey result type:
   - For healing paths, verify the 3 options (Bắt đầu ngay, Xem trước, Để sau) render inline and function correctly.
   - For matching paths, verify the 2 options (Khám phá ngay, Xem Content Hub trước) render inline and function correctly.

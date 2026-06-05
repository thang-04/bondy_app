# Healing Flow Refactor — Design Document

**Date:** 2026-05-31  
**Goal:** Sửa bug + đơn giản hóa luồng healing → ra bản ổn định cho demo/release

---

## 1. Tổng quan luồng Healing hiện tại

### 1.1 Flow Map

```
User vào tab Healing (Bottom Nav index=1)
  │
  ├─── MainShellScreen(initialIndex: 1) 
  │        └── HealingModeDashboardScreen
  │
  ├── Nếu isFirstTime → show FirstTimeEntryBottomSheet
  │      ├─ Check-in → EmotionalCheckinDialog → CheckinResultBridgeScreen
  │      ├─ Reflection → /healing/plan (preview mode)
  │      └─ Để sau → đóng sheet
  │
  ├── Nếu !hasTodayCheckin → auto-open EmotionalCheckinDialog
  │
  ├── Dashboard phân nhánh theo activePlanSummary:
  │   ├─── CÓ active plan (Journey Mode):
  │   │     ├─ JourneyProgressHeader (title, progress)
  │   │     ├─ "Khám phá Content Hub" → /content
  │   │     ├─ JourneyDayTile × N ngày (expandable)
  │   │     └─ "Tiếp tục ngày hiện tại" → _continuePlanCurrentDay
  │   │
  │   └─── KHÔNG CÓ active plan (Discovery Mode):
  │         ├─ hasInProgress:
  │         │   └─ ContinueJourneyCard → course-detail hoặc /healing/plan
  │         ├─ !hasInProgress:
  │         │   └─ StartHealingPathCard
  │         │       ├─ Check-in → EmotionalCheckinDialog
  │         │       └─ Reflection → /healing/plan (preview) → start plan
  │         ├─ PlanDiscoveryCard (nếu có recommendedPlan) → /healing/plan (preview)
  │         ├─ TodayForYouCard → content dựa theo primaryIntent
  │         └─ ...
  │
  ├── Common widgets (cả 2 mode):
  │   ├─ TodayCheckinSummaryCard (nếu đã check-in)
  │   ├─ PostCheckinPrimaryActionCard (gợi ý theo mood)
  │   ├─ ReflectionPromptCard → /chatbot
  │   ├─ ★ _StageProgressCard (HARD-CODE!)
  │   ├─ ★ "Nghi thức hằng ngày" (HARD-CODE 2 cards!)
  │   ├─ CoachCard → /chatbot
  │   └─ ★ ConnectGentlyCard (HARD-CODE avatars!)
  │
  └── Sub-screens:
      ├─ /healing/plan → HealingPlanScreen (preview/timeline mode)
      ├─ /healing/article-detail → HealingArticleDetailScreen
      ├─ /healing/exercise-detail → HealingExerciseDetailScreen
      ├─ /healing/course-detail → HealingCourseDetailScreen
      ├─ /healing/audio-player → HealingAudioPlayerScreen
      ├─ /healing/daily → HealingDailyScreen (★ HARD-CODE audio library!)
      ├─ /healing/checkin-result → CheckinResultBridgeScreen
      ├─ /healing/ritual-overview → DailyRitualOverviewScreen
      ├─ /healing/ritual-reading-detail → RitualReadingDetailScreen
      ├─ /healing/ritual-audio-detail → RitualAudioDetailScreen
      ├─ /healing/stabilize-quick-actions → StabilizeQuickActionsScreen
      ├─ /healing/reflection-complete → ReflectionCompleteSheet
      ├─ /healing/starter-recommendation → StarterRecommendationScreen
      └─ /content → ContentHubLibraryScreen
```

### 1.2 Kiến trúc layer

```
Screen (UI) → ViewModel (HealingHomeViewModel) → Service (HealingService) → API (/healing/*)
                                                    └─ HealingProgressStore (local cache)
```

### 1.3 Server API Coverage

| API Endpoint | Status | App sử dụng? |
|---|---|---|
| GET /healing/home | ✅ Có | ✅ HealingHomeViewModel.loadHome() |
| POST /healing/checkin | ✅ Có | ✅ submitCheckin() |
| GET /healing/articles/:id | ✅ Có | ✅ HealingArticleDetailScreen |
| POST /healing/articles/:id/complete | ✅ Có | ✅ completeArticle() |
| GET /healing/exercises/:id | ✅ Có | ✅ HealingExerciseDetailScreen |
| POST /healing/exercises/:id/complete | ✅ Có | ✅ completeExercise() |
| GET /healing/audios/:id | ✅ Có | ✅ HealingAudioPlayerScreen |
| GET /healing/rituals/:id | ✅ Có | ✅ RitualReadingDetailScreen |
| GET /healing/courses/:id | ✅ Có | ✅ HealingCourseDetailScreen |
| POST /healing/courses/:id/start | ✅ Có | ✅ startCourse() |
| POST /healing/courses/:id/lessons/:lessonId/complete | ✅ Có | ✅ completeLesson() |
| GET /healing/plan/timeline | ✅ Có | ✅ fetchActivePlanTimeline() |
| GET /healing/plan/preview | ✅ Có | ✅ fetchRecommendedPlanPreview() |
| POST /healing/plan/start | ✅ Có | ✅ startRecommendedPlan() |
| POST /healing/plan/items/:id/complete | ✅ Có | ✅ completePlanItem() |
| GET /healing/entry | ✅ Có | ⚠️ fetchEntryState() — có method nhưng chưa thấy screen nào gọi |

Server seed data: 10 articles, 8 exercises, 3 courses (7/10/5 ngày). Không có seed cho audio/ritual content.

---

## 2. DANH SÁCH BUG PHÁT HIỆN

### 🔴 Critical (User không dùng được)

| # | Bug | File | Chi tiết |
|---|---|---|---|
| C1 | **Lịch trình 7 ngày crash/lỗi khi server chưa có plan** | `healing_plan_screen.dart` | Nếu user mở `/healing/plan` khi chưa start plan VÀ không pass `preview: true`, screen sẽ gọi `fetchActivePlanTimeline()` → server throw 404 → hiện error thay vì redirect sang preview |
| C2 | **Audio player route không nhận arguments đúng** | `main.dart:223` | Route `/healing/audio-player` dùng `const HealingAudioPlayerScreen()` → không pass `audioId` → player show loading rỗng |
| C3 | **Ritual reading route không nhận arguments đúng** | `main.dart:230` | Route `/healing/ritual-reading-detail` dùng `const RitualReadingDetailScreen()` → không pass `ritualId` → show error |

### 🟡 Major (Trải nghiệm xấu, hard-code)

| # | Bug | File:Line | Chi tiết |
|---|---|---|---|
| M1 | **`_StageProgressCard` hard-code "GIAI ĐOẠN 2 — Tái kết nối — 35%"** | `healing_mode_dashboard_screen.dart:1622-1696` | Không load từ DB, mọi user đều thấy cùng data |
| M2 | **"Nghi thức hằng ngày" hard-code 2 card cứng** | `healing_mode_dashboard_screen.dart:405-433` | Luôn hiển thị "Hiểu về nỗi buồn" + "Bài tập thở" bất kể mood/state |
| M3 | **Audio library trong HealingDailyScreen hard-code 2 track** | `healing_daily_screen.dart:331-346` | List `tracks` là const, không load từ API |
| M4 | **ConnectGentlyCard hard-code avatar + "+4"** | `healing_mode_dashboard_screen.dart:1962-1987` | Dùng asset avatars cứng, số "+4" cứng, không load từ DB |
| M5 | **DailyRitualOverviewScreen hard-code danh sách ritual** | `daily_ritual_overview_screen.dart:27-75` | Tất cả ritual items là const, ID cũng hard-code |
| M6 | **PostCheckinCardConfig route mapping dựa theo text string** | `daily_ritual_personalization.dart:78-92` | `resolvePrimaryRouteByCta()` match bằng string label tiếng Việt → dễ vỡ khi đổi text |
| M7 | **Greeting "Chào buổi tối" hard-code** | `healing_mode_dashboard_screen.dart:283` | Luôn hiển thị "buổi tối" bất kể thời gian thực |

### 🟢 Minor (UX polish)

| # | Bug | File | Chi tiết |
|---|---|---|---|
| m1 | **CheckinResultBridgeScreen quá sơ sài** | `checkin_result_bridge_screen.dart` | Không hiển thị thông tin mood đã check-in, chỉ có 2 nút generic |
| m2 | **HealingFlowState.returningInProgress() hard-code lastIntensity: 4** | `healing_flow_state.dart:41` | Factory method hard-code intensity |
| m3 | **HealingFlowState.postTriggeredReturn() hard-code lastIntensity: 8** | `healing_flow_state.dart:51` | Factory method hard-code intensity |
| m4 | **reflectionPrompt fallback hard-code** | `healing_mode_dashboard_screen.dart:230` | Fallback `'Điều mình đang tự trách là gì?'` thay vì từ server |
| m5 | **_DailyByteCard trong ContentHub hard-code** | `content_hub_library_screen.dart:794+` | Nội dung daily byte cứng |

---

## 3. PHÂN TÍCH VẤN ĐỀ LOGIC PHỨC TẠP

### 3.1 Quá nhiều rẽ nhánh trên Dashboard

Hiện tại `_buildScaffold()` có **8+ conditions** quyết định UI:
- `activePlan != null` → Journey vs Discovery
- `flow.topBlock` → ContinueJourney vs StartPath
- `hasTodayCheckin` → show checkin card vs quick checkin
- `postCheckinConfig != null` → show primary action
- `recommendedPlan != null` → show plan discovery
- Auto-open checkin dialog
- First time bottom sheet
- Mood-based primaryIntent routing

→ **User lạc trong quá nhiều trạng thái, không biết mình đang ở đâu.**

### 3.2 Route arguments không thống nhất

Cùng 1 screen nhưng có 3-4 cách truyền arguments:
- String ID trực tiếp: `Navigator.pushNamed(route, arguments: 'some-id')`
- Map: `arguments: {'audioId': id, 'planMode': true}`
- Constructor param: `HealingAudioPlayerScreen(audioId: id)`
- Không truyền gì cả (hard-code trong screen)

→ **Gây crash khi route không nhận đúng kiểu argument.**

### 3.3 Duplicated logic

- `_readinessFromIntensity()` xuất hiện ở cả `healing_service.dart:365` VÀ `healing_home_viewmodel.dart:146`
- `_needsFromMood()` cũng duplicate ở 2 file
- Bottom nav routing code copy-paste ở 4+ screens

---

## 4. ĐỀ XUẤT GIẢI PHÁP

### Approach A: Patch & Fix (Recommended) ⭐

**Ý tưởng:** Sửa tất cả bug, thay hard-code bằng data từ API, giữ nguyên cấu trúc file hiện tại.

**Ưu điểm:** Nhanh (2-3 ngày), an toàn, không phá vỡ gì đang chạy tốt.  
**Nhược điểm:** Cấu trúc file vẫn phức tạp (dashboard 2049 dòng).

### Approach B: Structural Refactor

**Ý tưởng:** Tách `healing_mode_dashboard_screen.dart` (2049 dòng) thành nhiều widget nhỏ, refactor route system.

**Ưu điểm:** Code sạch hơn, dễ maintain.  
**Nhược điểm:** 4-5 ngày, risk regression cao.

### Approach C: Hybrid (Recommended cho phase 2)

Phase 1: Approach A (fix bugs + remove hard-code)  
Phase 2: Approach B (refactor structure sau khi ổn định)

---

## 5. PLAN CHI TIẾT — PHASE 1 (Patch & Fix)

### Sprint 1: Fix Critical Bugs (Ưu tiên cao nhất)

#### Task 1.1: Fix HealingPlanScreen fallback khi chưa có plan
- **File:** `healing_plan_screen.dart`
- **Thay đổi:** Khi `_isPreview=false` và `fetchActivePlanTimeline()` throw → tự chuyển sang preview mode thay vì show error

#### Task 1.2: Fix route arguments cho Audio Player  
- **File:** `main.dart` route registration
- **Thay đổi:** Parse `arguments` đúng kiểu (String hoặc Map) trong `HealingAudioPlayerScreen`

#### Task 1.3: Fix route arguments cho Ritual Reading
- **File:** `main.dart` route registration
- **Thay đổi:** Tương tự Task 1.2

### Sprint 2: Remove Hard-coded Data

#### Task 2.1: _StageProgressCard → load từ API
- **Thay đổi:** 
  - Server: Thêm field `stageProgress` vào `/healing/home` response
  - App: `_StageProgressCard` nhận data từ `HealingHomeData`
  - Nếu server chưa có API → hide card tạm thời

#### Task 2.2: "Nghi thức hằng ngày" → load từ sections
- **Thay đổi:** Thay 2 card hard-code bằng `home.sections.rituals` từ API
- Fallback: nếu rituals rỗng → ẩn section

#### Task 2.3: Audio library → load từ sections  
- **Thay đổi:** `HealingDailyScreen._CompactAudioLibrary` dùng `home.sections.audios`
- Fallback: nếu audios rỗng → ẩn section

#### Task 2.4: ConnectGentlyCard → ẩn hoặc load từ API
- **Thay đổi:** Tạm ẩn phần avatar + count, chỉ giữ nút "Tìm match"
- Phase 2: load từ matching API

#### Task 2.5: DailyRitualOverviewScreen → load từ API
- **Thay đổi:** Thay danh sách const bằng gọi API sections.rituals + sections.exercises

#### Task 2.6: Fix greeting theo thời gian thực
- **Thay đổi:** Dùng `DateTime.now().hour` để chọn "buổi sáng/chiều/tối"

### Sprint 3: Đơn giản hóa logic chuyển mode

#### Task 3.1: Làm rõ 2 mode trên Dashboard
- **Thay đổi:**
  - Journey Mode: Header rõ ràng "Lộ trình của bạn", progress bar, danh sách ngày
  - Discovery Mode: Header "Khám phá", card bắt đầu, gợi ý nội dung
  - Không mix widgets của 2 mode

#### Task 3.2: Đơn giản hóa PostCheckinCardConfig routing
- **Thay đổi:** Chuyển từ match string label → dùng enum-based routing

#### Task 3.3: Fix route arguments consistency
- **Thay đổi:** Tất cả healing screens đều support cả 2 cách: constructor param VÀ route arguments (String hoặc Map)

### Sprint 4: Cải thiện UX

#### Task 4.1: Upgrade CheckinResultBridgeScreen
- **Thay đổi:** Hiển thị mood + intensity đã check-in, gợi ý nội dung phù hợp từ recovery bundle

#### Task 4.2: Remove duplicated utility functions
- **Thay đổi:** Tạo shared file cho `_readinessFromIntensity()` và `_needsFromMood()`

#### Task 4.3: Audit tất cả nút/link
- Kiểm tra mọi `Navigator.pushNamed()` trong healing screens
- Đảm bảo route tồn tại trong `main.dart`
- Đảm bảo arguments truyền đúng

---

## 6. SERVER CHANGES NEEDED

| API | Thay đổi |
|---|---|
| GET /healing/home | Thêm `stageProgress: { stage, label, percent }` vào response |
| Seed data | Thêm seed cho AUDIO content (hiện chỉ có articles + exercises + courses) |
| Seed data | Thêm seed cho RITUAL content |

---

## 7. VERIFICATION PLAN

### Automated
- Chạy `flutter analyze` sau mỗi thay đổi
- Chạy existing tests: `flutter test`

### Manual
- Mở Healing tab → kiểm tra greeting đúng thời gian
- Check-in → kiểm tra result screen hiện đúng mood
- Mở lộ trình 7 ngày → kiểm tra không crash
- Tap từng nút/card → kiểm tra navigate đúng
- Kiểm tra không có data hard-code còn sót

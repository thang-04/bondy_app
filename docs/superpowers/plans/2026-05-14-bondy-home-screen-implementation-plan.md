# Bondy Home Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement Home Screen với 5 widgets cá nhân hóa theo final spec đã approved

**Architecture:** Flutter app gọi `/api/home/content?userId=xxx` → Backend trả về widgets theo rule engine → Flutter render widgets tương ứng. Backend đã implement đầy đủ, chủ yếu cần fix Flutter UI và 1 bug backend nhỏ.

**Tech Stack:** Flutter (Bondy_App), Node.js/Prisma (bondy_server)

---

## File Structure

### Backend (bondy_server)
```
src/repository/home.repository.ts    - Fix 'active' → 'ACTIVE' (Task 1)
```

### Flutter (Bondy_App)
```
lib/theme/app_theme.dart              - Đã có đầy đủ tokens
lib/models/home/home_widget_model.dart - Đã có HomeWidget model
lib/services/home_service.dart       - Đã gọi /home/content API
lib/viewmodels/home/home_viewmodel.dart - Quản lý state
lib/widgets/home/banner_widget.dart          - Refactor theo spec
lib/widgets/home/emotion_checkin_widget.dart - Refactor theo spec
lib/widgets/home/milestone_reminder_widget.dart - Refactor theo spec
lib/widgets/home/discovery_card_widget.dart   - Refactor theo spec
lib/widgets/home/suggestion_card_widget.dart   - Refactor theo spec
lib/widgets/home/relationship_strength_card.dart - DELETE (removed)
lib/screens/home/main_shell_screen.dart      - Update navigation icons
```

---

## Task 1: Fix RelationshipStatus Case Bug

**Files:**
- Modify: `bondy_server/src/repository/home.repository.ts:35-39`

- [ ] **Step 1: Check actual status value in schema**

```bash
grep -n "status" bondy_server/prisma/schema.prisma | head -20
```

- [ ] **Step 2: Fix query if needed**

Nếu schema là `status String @default("active")` thì code hiện tại đúng.
Nếu có enum `RelationshipStatus` thì đổi sang `'ACTIVE'`.

---

## Task 2: Refactor BannerWidget

**Files:**
- Modify: `Bondy_App/lib/widgets/home/banner_widget.dart`
- Test: Visual verify trên device

- [ ] **Step 1: Review current BannerWidget implementation**

```bash
cat Bondy_App/lib/widgets/home/banner_widget.dart
```

- [ ] **Step 2: Ensure implementation follows spec**

Check:
- Background: Signature gradient (#FF0066 → #FF007F)
- No border (No-Line Rule)
- Corner radius: 24px
- Tinted shadow: pink tint blur 32px+
- CTA button với signature gradient

- [ ] **Step 3: Run flutter analyze**

```bash
cd Bondy_App && flutter analyze lib/widgets/home/banner_widget.dart
```

Expected: No errors

---

## Task 3: Refactor EmotionCheckinWidget

**Files:**
- Modify: `Bondy_App/lib/widgets/home/emotion_checkin_widget.dart`
- Test: Visual verify trên device

- [ ] **Step 1: Review current implementation**

```bash
cat Bondy_App/lib/widgets/home/emotion_checkin_widget.dart
```

- [ ] **Step 2: Ensure implementation follows spec**

Check:
- No border (No-Line Rule)
- Background: color shift surfaceContainerLow → surfaceContainerLowest
- Corner radius: 32px
- Emotion buttons: 😊 😌 😔 😰 (4 options)
- BoxShadow: pink tinted

- [ ] **Step 3: Run flutter analyze**

```bash
cd Bondy_App && flutter analyze lib/widgets/home/emotion_checkin_widget.dart
```

---

## Task 4: Refactor MilestoneReminderWidget

**Files:**
- Modify: `Bondy_App/lib/widgets/home/milestone_reminder_widget.dart`
- Test: Visual verify trên device

- [ ] **Step 1: Review current implementation**

```bash
cat Bondy_App/lib/widgets/home/milestone_reminder_widget.dart
```

- [ ] **Step 2: Ensure implementation follows spec**

Check:
- Background: Tertiary gradient (#FFF3E0 → #FFE0B2)
- No border
- Days badge: pill shape với tertiary color
- Corner radius: 32px

- [ ] **Step 3: Run flutter analyze**

```bash
cd Bondy_App && flutter analyze lib/widgets/home/milestone_reminder_widget.dart
```

---

## Task 5: Refactor DiscoveryCardWidget

**Files:**
- Modify: `Bondy_App/lib/widgets/home/discovery_card_widget.dart`
- Test: Visual verify trên device

- [ ] **Step 1: Review current implementation**

```bash
cat Bondy_App/lib/widgets/home/discovery_card_widget.dart
```

- [ ] **Step 2: Ensure implementation follows spec**

Check:
- No border
- Pink-tinted shadow: rgba(183, 0, 71, 0.08)
- Profile cards: 3 ô ngang (ListView.horizontal)
- Interest tags: chips với primaryContainer color
- Corner radius: 32px

- [ ] **Step 3: Run flutter analyze**

```bash
cd Bondy_App && flutter analyze lib/widgets/home/discovery_card_widget.dart
```

---

## Task 6: Refactor SuggestionCardWidget

**Files:**
- Modify: `Bondy_App/lib/widgets/home/suggestion_card_widget.dart`
- Test: Visual verify trên device

- [ ] **Step 1: Review current implementation**

```bash
cat Bondy_App/lib/widgets/home/suggestion_card_widget.dart
```

- [ ] **Step 2: Ensure implementation follows spec**

Check:
- Background: Suggestion gradient (#FFB3A7 → #E8A0BF → #AE8FDB)
- CTA button: Signature gradient
- Corner radius: 32px
- No border

- [ ] **Step 3: Run flutter analyze**

```bash
cd Bondy_App && flutter analyze lib/widgets/home/suggestion_card_widget.dart
```

---

## Task 7: Delete RelationshipStrengthCard

**Files:**
- Delete: `Bondy_App/lib/widgets/home/relationship_strength_card.dart`
- Modify: Any imports referencing it

- [ ] **Step 1: Find files importing relationship_strength_card**

```bash
grep -r "relationship_strength_card" Bondy_App/lib/ --include="*.dart"
```

- [ ] **Step 2: Remove imports and references**

Nếu có file nào import widget này, xóa import đó.

- [ ] **Step 3: Delete the file**

```bash
rm Bondy_App/lib/widgets/home/relationship_strength_card.dart
```

---

## Task 8: Update Bottom Navigation Icons

**Files:**
- Modify: `Bondy_App/lib/screens/home/main_shell_screen.dart`

- [ ] **Step 1: Review current bottom nav**

```bash
cat Bondy_App/lib/screens/home/main_shell_screen.dart | head -100
```

- [ ] **Step 2: Update Match icon từ heart sang bolt**

Tìm đoạn BottomNavigationBar và đổi icon thứ 3 từ `Icons.favorite` thành `Icons.bolt`.

```dart
BottomNavigationBar(
  items: [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.spa), label: 'Healing'),
    BottomNavigationBarItem(icon: Icon(Icons.bolt), label: 'Match'),
    BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
  ],
)
```

- [ ] **Step 3: Run flutter analyze**

```bash
cd Bondy_App && flutter analyze lib/screens/home/main_shell_screen.dart
```

---

## Task 9: Verify HomeViewModel Integration

**Files:**
- Review: `Bondy_App/lib/viewmodels/home/home_viewmodel.dart`

- [ ] **Step 1: Review viewmodel**

```bash
cat Bondy_App/lib/viewmodels/home/home_viewmodel.dart
```

- [ ] **Step 2: Ensure widgets map correctly**

Kiểm tra HomeWidgetType enum map đúng với 5 widget types:
- BANNER
- EMOTION_CHECKIN
- MILESTONE_REMINDER
- DISCOVERY_CARD
- SUGGESTION_CARD

---

## Task 10: Visual Verification

**Testing:** Chạy app và verify từng widget

- [ ] **Step 1: Build iOS**

```bash
cd Bondy_App && flutter run -d <device_id>
```

- [ ] **Step 2: Verify widgets theo thứ tự priority**

Verify mỗi widget hiển thị đúng design:
1. BANNER - signature gradient, no border, 24px radius
2. EMOTION_CHECKIN - no border, 32px radius, 4 emotion buttons
3. MILESTONE_REMINDER - tertiary gradient, days badge
4. DISCOVERY_CARD - pink shadow, 3 profile cards horizontal
5. SUGGESTION_CARD - suggestion gradient, signature CTA

---

## Pre-flight Checklist

Trước khi kết thúc, chạy:

```bash
cd Bondy_App && flutter analyze
cd bondy_server && npm run lint 2>/dev/null || true
```

---

**Plan complete.** Chọn execution approach:

1. **Subagent-Driven (recommended)** - Dispatch fresh subagent per task
2. **Inline Execution** - Execute tasks in this session
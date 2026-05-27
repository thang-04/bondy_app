# Bondy Home Screen - Final Design Spec

**Date:** 2026-05-14
**Status:** Final - Approved
**Scope:** Tab Home only (Flutter UI + Backend)

---

## Mục lục

1. [Overview](#1-overview)
2. [Screen Layout](#2-screen-layout)
3. [Widget Specifications](#3-widget-specifications)
4. [Backend API](#4-backend-api)
5. [Design Tokens](#5-design-tokens)
6. [Decisions Log](#6-decisions-log)

---

## 1. Overview

### 1.1 Mục tiêu

Rebuild Home Screen tab để:
- Hiển thị widgets cá nhân hóa dựa trên user state
- Tuân thủ "The Digital Sanctuary" design system
- Kết nối Flutter app với backend API thật

### 1.2 Widgets

| Widget | Nguồn data | Điều kiện hiển thị |
|--------|------------|-------------------|
| BANNER | API | Chưa hoàn thành onboarding survey |
| EMOTION_CHECKIN | API | Có relationship active + chưa checkin hôm nay |
| MILESTONE_REMINDER | API | Có milestone trong 7 ngày tới |
| DISCOVERY_CARD | API | mode='solo' hoặc chưa có match |
| SUGGESTION_CARD | API (dating_goal) | Luôn hiển thị (default cuối) |

**Removed widgets:**
- RELATIONSHIP_STRENGTH - Hoãn sang version sau
- Quick Actions Grid - Không cần thiết cho MVP

---

## 2. Screen Layout

### 2.1 ASCII Wireframe

```
┌─────────────────────────────────────────────┐
│  ╔═══════════════════════════════════════╗ │
│  ║  HEADER (Gradient: #FF0066 → #FF007F) ║ │
│  ║  ┌─────────────┐    ┌──────────────┐   ║ │
│  ║  │   BONDY     │    │    Avatar    │   ║ │
│  ║  │   Logo      │    │   (44px)    │   ║ │
│  ║  │ + Greeting  │    └──────────────┘   ║ │
│  ║  └─────────────┘                       ║ │
│  ╚═══════════════════════════════════════╝ │
├─────────────────────────────────────────────┤
│                                             │
│  (ListView builder - các widgets)            │
│                                             │
│  ┌─ BANNER WIDGET ──────────────────────┐   │
│  │ 📋  [Title]              [CTA Btn] │   │
│  └─────────────────────────────────────┘   │
│                                             │
│  ┌─ EMOTION CHECKIN WIDGET ─────────────┐   │
│  │ 💝  Check-in cảm xúc hôm nay         │   │
│  │     Bạn đang cảm thấy thế nào?       │   │
│  │                                     │   │
│  │   😊 Vui  😌 Bình yên  😔 Buồn  😰 Lo│   │
│  └─────────────────────────────────────┘   │
│                                             │
│  ┌─ MILESTONE REMINDER WIDGET ──────────┐   │
│  │ 🎉  [Title]            [Days Badge] │   │
│  │     [Date]                           │   │
│  └─────────────────────────────────────┘   │
│                                             │
│  ┌─ DISCOVERY CARD WIDGET ──────────────┐   │
│  │ Gợi ý kết nối cho bạn ✨             │   │
│  │                                     │   │
│  │  ┌─────┐  ┌─────┐  ┌─────┐         │   │
│  │  │ 👤  │  │ 👤  │  │ 👤  │         │   │
│  │  │Name │  │Name │  │Name │         │   │
│  │  │City │  │City │  │City │         │   │
│  │  │Tags │  │Tags │  │Tags │         │   │
│  │  └─────┘  └─────┘  └─────┘         │   │
│  └─────────────────────────────────────┘   │
│                                             │
│  ┌─ SUGGESTION CARD WIDGET ─────────────┐   │
│  │  ┌──────────────────────────────┐   │   │
│  │  │     DAILY INSPIRATION        │   │   │
│  │  │     [Title Text]            │   │   │
│  │  │     [Content Text]          │   │   │
│  │  │           🧘‍♀️              │   │   │
│  │  │  ┌───────────────────────┐  │   │   │
│  │  │  │  Bắt đầu hành trình → │  │   │   │
│  │  │  └───────────────────────┘  │   │   │
│  │  └──────────────────────────────┘   │   │
│  └─────────────────────────────────────┘   │
│                                             │
│              (bottom padding 100px)        │
│                                             │
├─────────────────────────────────────────────┤
│           FLOATING ACTION BUTTON            │
│     ┌─────────────────────────────┐        │
│     │ 💬  Hỏi Bondy                │        │
│     └─────────────────────────────┘        │
├─────────────────────────────────────────────┤
│  ┌───────────────────────────────────────┐  │
│  │      BOTTOM NAVIGATION BAR             │  │
│  │  ┌───┐  ┌───┐  ┌───┐  ┌───┐  ┌───┐   │  │
│  │  │ 🏠 │  │ 🧘 │  │ ⚡ │  │ 💬 │  │ 👤 │  │  │
│  │  │Home│  │Heal│  │MATCH│ │Chat│  │Prof│  │  │
│  │  └───┘  └───┘  └───┘  └───┘  └───┘   │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

### 2.2 Widget Priority Order

```
1. BANNER (nếu chưa complete survey)
2. EMOTION_CHECKIN (nếu có relationship + chưa checkin)
3. MILESTONE_REMINDER (nếu có milestone trong 7 ngày)
4. DISCOVERY_CARD (nếu solo mode hoặc chưa có match)
5. SUGGESTION_CARD (default - luôn có)
```

---

## 3. Widget Specifications

### 3.1 BANNER Widget

**Điều kiện:** User chưa hoàn thành onboarding survey

**Data từ API:**
```json
{
  "widget_type": "BANNER",
  "priority": 1,
  "data": {
    "action": "COMPLETE_SURVEY",
    "title": "Hoàn thành khảo sát để Bondy hiểu bạn hơn 💬",
    "cta": "Bắt đầu ngay"
  }
}
```

**Design:**
- Background: Signature gradient (#FF0066 → #FF007F)
- No border (No-Line Rule)
- Corner radius: 24px
- Tinted shadow: `rgba(183, 0, 71, 0.08)`

### 3.2 EMOTION_CHECKIN Widget

**Điều kiện:** Có active relationship + chưa checkin hôm nay

**Data từ API:**
```json
{
  "widget_type": "EMOTION_CHECKIN",
  "priority": 2,
  "data": {
    "relationship_id": "rel_xxx",
    "partner_name": "Minh"
  }
}
```

**Design:**
- No border (No-Line Rule)
- Background: surfaceContainerLow → surfaceContainerLowest color shift
- Emotion buttons: 😊 😌 😔 🤔
- Corner radius: 32px

### 3.3 MILESTONE_REMINDER Widget

**Điều kiện:** Có milestone trong 7 ngày tới

**Data từ API:**
```json
{
  "widget_type": "MILESTONE_REMINDER",
  "priority": 3,
  "data": {
    "title": "1 Month Anniversary",
    "date": "2026-05-20",
    "days_left": 6,
    "milestone_type": "ANNIVERSARY"
  }
}
```

**Design:**
- Background: Tertiary gradient (#FFF3E0 → #FFE0B2)
- No border
- Days badge: pill shape với tertiary color

### 3.4 DISCOVERY_CARD Widget

**Điều kiện:** mode='solo' hoặc chưa có match nào

**Data từ API:**
```json
{
  "widget_type": "DISCOVERY_CARD",
  "priority": 4,
  "data": {
    "profiles": [
      { "user_id": "xxx", "name": "Minh", "city": "HCM", "common_interests": ["music", "travel"] }
    ]
  }
}
```

**Design:**
- No border
- Pink-tinted shadow: `rgba(183, 0, 71, 0.08)`
- Profile cards: 3 ô ngang
- Interest tags: chips với primaryContainer color

### 3.5 SUGGESTION_CARD Widget

**Điều kiện:** Luôn hiển thị (default cuối cùng)

**Data từ API:**
```json
{
  "widget_type": "SUGGESTION_CARD",
  "priority": 5,
  "data": {
    "dating_goal": "serious",
    "title": "Xây dựng tình yêu bền vững 💑",
    "content": "Hãy thử chia sẻ điều bạn trân trọng nhất trong một mối quan hệ."
  }
}
```

**Design:**
- Background: Suggestion gradient (#FFB3A7 → #E8A0BF → #AE8FDB)
- CTA button: Signature gradient
- Corner radius: 32px

---

## 4. Backend API

### 4.1 Main Endpoint

**GET `/api/home/content?userId=xxx`**

**Response:**
```json
{
  "success": true,
  "data": {
    "widgets": [
      {
        "widget_type": "EMOTION_CHECKIN",
        "priority": 1,
        "data": { ... }
      }
    ]
  }
}
```

### 4.2 Repository Methods

| Method | Return | Mô tả |
|--------|--------|-------|
| `checkOnboardingSurveyCompleted(userId)` | `boolean` | User đã làm onboarding survey chưa |
| `getActiveRelationship(userId)` | `{id, partnerId, partnerName} \| null` | Relationship active của user |
| `hasTodayCheckin(relationshipId, userId)` | `boolean` | Đã checkin hôm nay chưa |
| `getUpcomingMilestone(relationshipId)` | `{title, date, daysLeft} \| null` | Milestone trong 7 ngày |
| `getLatestSurveyModeCode(userId)` | `string \| null` | Mode code từ submission mới nhất |
| `getMatchCount(userId)` | `number` | Số match của user |
| `getDiscoveryProfiles(userId)` | `Array<{id, name, city, commonInterests}>` | Profiles gợi ý |
| `getDatingGoal(userId)` | `string \| null` | Dating goal của user |

### 4.3 RelationshipStatus Enum

**Giá trị:** `'ACTIVE'` (uppercase)

```typescript
enum RelationshipStatus {
  ACTIVE = 'ACTIVE',
  PAUSED = 'PAUSED',
  ENDED = 'ENDED'
}
```

**Lưu ý:** Code hiện tại dùng `'active'` lowercase - cần fix thành `'ACTIVE'`.

---

## 5. Design Tokens

### 5.1 Colors

| Token | Hex | Usage |
|-------|-----|-------|
| primary | `#b70047` | Heartbeat color |
| primaryContainer | `#ff728f` | Lighter primary |
| secondary | `#92348e` | Soul color |
| secondaryContainer | `#ffbdf4` | Connection chips |
| tertiary | `#994400` | Spark color |
| surface | `#fbf5f7` | Base canvas |
| surfaceContainerLow | `#f5eff1` | Secondary content |
| surfaceContainerLowest | `#ffffff` | Cards |
| onSurface | `#302e30` | Text (NOT pure black) |
| signatureGradient | `#FF0066 → #FF007F` | CTAs only |

### 5.2 Key Design Rules

1. **No-Line Rule:** Không dùng 1px borders cho sectioning
2. **Signature Gradient:** Chỉ dùng cho main CTAs và hero headers
3. **Tinted Shadows:** `rgba(183, 0, 71, 0.08)` at 32px+ blur
4. **Corner Radius:** md (24px) buttons, lg (32px) containers
5. **NO pure black text:** Dùng `#302e30`

---

## 6. Decisions Log

| Date | Issue | Decision | Reason |
|------|-------|----------|--------|
| 2026-05-14 | RELATIONSHIP_STRENGTH | REMOVED | Quá phức tạp, hoãn sang version sau |
| 2026-05-14 | Quick Actions Grid | REMOVED | Không cần thiết cho MVP |
| 2026-05-14 | API Endpoint | `/api/home/content?userId=xxx` | Endpoint hiện tại trong codebase |
| 2026-05-14 | RelationshipStatus case | Fix code → `'ACTIVE'` uppercase | Theo Prisma enum convention |
| 2026-05-14 | Widget priority order | User spec order | Logic rule-based đã đúng trong code |
| 2026-05-14 | Bottom nav Match icon | ⚡ | Phù hợp concept "kết nối mạnh" |

---

## 7. Files to Modify

### Backend (bondy_server)
```
src/repository/home.repository.ts    - Fix 'active' → 'ACTIVE'
```

### Flutter (Bondy_App)
```
lib/theme/app_theme.dart           - Add DESIGN.md tokens
lib/widgets/home/banner_widget.dart
lib/widgets/home/emotion_checkin_widget.dart
lib/widgets/home/milestone_reminder_widget.dart
lib/widgets/home/discovery_card_widget.dart
lib/widgets/home/suggestion_card_widget.dart
lib/screens/home/main_shell_screen.dart
lib/viewmodels/home/home_viewmodel.dart
lib/services/home_service.dart
```

---

**Approved:** 2026-05-14
# Bondy App Home Screen UI/UX Specification

> **Document Version:** 1.0
> **Date:** 2026-05-14
> **Scope:** Tab Home only (not full app redesign)
> **Design System:** "The Digital Sanctuary" (DESIGN.md)
> **Reference Screen:** Stitch "Bondy App Home Screen" (projects/14989562978617292831/screens/494743612c2a4026b859a99225f66bfe)

---

## 1. Screen Layout Structure

### 1.1 ASCII Wireframe

```
┌─────────────────────────────────────────────┐
│            SAFE AREA (Status Bar)           │
├─────────────────────────────────────────────┤
│  ╔═══════════════════════════════════════╗ │
│  ║     HEADER (Gradient: #FF8A65→#E91E63) ║ │
│  ║  ┌─────────────┐    ┌──────────────┐   ║ │
│  ║  │   BONDY     │    │    Avatar    │   ║ │
│  ║  │   Logo      │    │   (44px)    │   ║ │
│  ║  │   + Greeting│    └──────────────┘   ║ │
│  ║  └─────────────┘                       ║ │
│  ╚═══════════════════════════════════════╝ │
├─────────────────────────────────────────────┤
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
│  │  │                             │   │   │
│  │  │     [Title Text]            │   │   │
│  │  │     [Content Text]          │   │   │
│  │  │                             │   │   │
│  │  │           🧘‍♀️              │   │   │
│  │  │                             │   │   │
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
│  │  │ 🏠 │  │ 🧘 │  │ ❤️ │  │ 💬 │  │ 👤 │  │  │
│  │  │Home│  │Heal│  │MATCH│ │Chat│  │Prof│  │  │
│  │  └───┘  └───┘  └───┘  └───┘  └───┘   │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

### 1.2 Screen Dimensions
- **Width:** 390px (mobile breakpoint)
- **Height:** Dynamic (screen height minus safe areas)
- **Safe Area Top:** System default (notch-aware)
- **Safe Area Bottom:** Handled by bottom navigation

### 1.3 Layout Algorithm
```
Screen
├── Header (fixed height: ~100px including padding)
│   └── Row: Logo/Text (left) + Avatar (right)
├── Expanded
│   └── ListView.builder
│       └── Dynamic widgets based on HomeWidget.widgetType:
│           ├── BANNER → BannerWidget
│           ├── EMOTION_CHECKIN → EmotionCheckinWidget
│           ├── MILESTONE_REMINDER → MilestoneReminderWidget
│           ├── DISCOVERY_CARD → DiscoveryCardWidget
│           └── SUGGESTION_CARD → SuggestionCardWidget
├── FloatingActionButton (Bondy Coach chatbot)
└── BottomNavigationBar (fixed, height: 90px with rounded top corners)
```

---

## 2. Design Tokens

### 2.1 Color Palette

#### Primary Colors
| Token | Hex | Usage |
|-------|-----|-------|
| `primary` | `#F87171` | Main actions, active states, CTAs |
| `primaryDark` | `#E11D48` | Dark mode accents, pressed states |
| `primaryLight` | `#FFF1F2` | Faint backgrounds, highlights |
| `secondary` | `#FDA4AF` | Gradient end color, secondary accents |
| `primaryGradientStart` | `#FF8A65` | Header and card gradient start (Stitch) |
| `primaryGradientEnd` | `#E91E63` | Header and card gradient end (Stitch) |

#### Surface Colors
| Token | Hex | Usage |
|-------|-----|-------|
| `surface` | `#FFFFFF` | Cards, overlays, input backgrounds |
| `background` | `#FFF8F6` | Main screen background (warm off-white) |
| `surfaceContainerLow` | `#F5EFF1` | Secondary content areas |
| `surfaceContainerLowest` | `#FFFFFF` | Interactive cards |

#### Text Colors
| Token | Hex | Usage |
|-------|-----|-------|
| `textPrimary` | `#2D0A15` | Headlines, body text, primary content |
| `textSecondary` | `#8A6A75` | Subtitles, descriptions, supporting text |
| `textHint` | `#B9AA5` | Placeholders, disabled text, timestamps |

#### Utility Colors
| Token | Hex | Usage |
|-------|-----|-------|
| `divider` | `#E5E7EB` | Borders, separators (use sparingly per "No-Line" rule) |
| `error` | `#EF4444` | Error states, destructive actions |
| `cardBorder` | `#E5E7EB` | Card outlines (only when necessary) |
| `chatBubbleUser` | `#F87171` | User's chat messages |
| `chatBubbleOther` | `#F3F4F6` | Other user's chat messages |
| `overlay` | `#80000000` | Modal overlays (50% opacity black) |

#### Suggestion Card Gradient
| Position | Hex |
|----------|-----|
| Start | `#FFB3A7` |
| Middle | `#E8A0BF` |
| End | `#AE8FDB` |

#### Milestone Reminder Gradient
| Position | Hex |
|----------|-----|
| Start | `#FFF3E0` |
| End | `#FFE0B2` |

### 2.2 Typography

#### Font Family
- **Primary Font:** Plus Jakarta Sans (display, headlines, labels)
- **Secondary Font:** Inter (body text) - via GoogleFonts.plusJakartaSansTextTheme

#### Type Scale
| Token | Size | Line Height | Weight | Letter Spacing | Usage |
|-------|------|-------------|--------|----------------|-------|
| `display-md` | 44px (2.75rem) | 1.2 | 700 | -0.02em | Onboarding hooks, emotional quotes |
| `display-sm` | 36px (2.25rem) | 1.2 | 700 | -0.02em | Hero text |
| `headline-lg` | 28px (1.75rem) | 1.3 | 700 | -0.01em | Screen titles |
| `headline-md` | 26px (1.625rem) | 1.3 | 800 | 0 | App logo, main headings |
| `headline-sm` | 24px (1.5rem) | 1.3 | 700 | -0.01em | Section titles, user names |
| `title-lg` | 20px (1.25rem) | 1.4 | 700 | 0 | Card titles |
| `title-md` | 17px (1.0625rem) | 1.4 | 700 | 0 | Widget section headers |
| `title-sm` | 15px (0.9375rem) | 1.4 | 700 | 0 | Sub-card titles, button text |
| `body-lg` | 16px (1rem) | 1.5 | 400 | 0 | Body text, bios |
| `body-md` | 14px (0.875rem) | 1.5 | 400 | 0 | Secondary body text |
| `body-sm` | 13px (0.8125rem) | 1.4 | 400 | 0 | Captions, metadata |
| `label-lg` | 14px (0.875rem) | 1.4 | 600 | 0 | Navigation labels |
| `label-md` | 12px (0.75rem) | 1.4 | 500 | 0 | Timestamps, small labels |
| `label-sm` | 11px (0.6875rem) | 1.4 | 600 | 0 | Chip labels, badges |
| `label-xs` | 10px (0.625rem) | 1.4 | 600 | 0 | Interest tags, small hints |

### 2.3 Spacing Scale

| Token | Value | Pixel | Usage |
|-------|-------|-------|-------|
| `spacing-1` | 0.25rem | 4px | Tight internal padding |
| `spacing-2` | 0.5rem | 8px | Icon gaps, small margins |
| `spacing-3` | 0.75rem | 12px | Internal component padding |
| `spacing-4` | 1rem | 16px | Standard padding, card internal |
| `spacing-5` | 1.5rem | 24px | Section gaps |
| `spacing-6` | 2rem | 32px | Large section separations |
| `spacing-7` | 3rem | 48px | Major section breaks |

#### Standard Margins
| Usage | Value |
|-------|-------|
| Horizontal screen margin | 20px |
| Vertical widget margin | 8px |
| Card internal padding | 20px |
| Section header bottom padding | 12px |
| List bottom padding (above FAB) | 100px |

### 2.4 Border Radius

| Token | Value | Usage |
|-------|-------|-------|
| `radius-sm` | 8px | Small buttons, input fields |
| `radius-md` | 16px | Medium cards, chips |
| `radius-lg` | 20px | Large cards, modals |
| `radius-xl` | 24px | Primary buttons, CTAs |
| `radius-full` | 9999px | Avatar, chips, pills |

### 2.5 Shadows

#### Card Shadow (Standard)
```dart
BoxShadow(
  color: Colors.black.withValues(alpha: 0.04), // 4% opacity
  blurRadius: 8,
  offset: Offset(0, 2),
)
```

#### Elevated Card Shadow (e.g., Banner)
```dart
BoxShadow(
  color: Color(0xFFE91E63).withValues(alpha: 0.25), // Pink-tinted, 25% opacity
  blurRadius: 16,
  offset: Offset(0, 6),
)
```

#### Bottom Navigation Shadow
```dart
BoxShadow(
  color: Colors.black.withValues(alpha: 0.08), // 8% opacity
  blurRadius: 20,
  offset: Offset(0, -4),
)
```

#### Match Button Shadow
```dart
BoxShadow(
  color: Color(0xFFFF5864).withValues(alpha: 0.3),
  blurRadius: 16,
  offset: Offset(0, 6),
)
```

### 2.6 Animation Specifications

| Property | Value | Usage |
|----------|-------|-------|
| `easing` | `Curves.easeInOut` | All transitions |
| `cubic-bezier` | `(0.4, 0, 0.2, 1)` | Liquid motion feel |
| `duration-fast` | 200ms | Button press feedback |
| `duration-normal` | 300ms | Page transitions, card animations |
| `duration-slow` | 500ms | Modal appearances |

---

## 3. Widget Specifications

### 3.1 Header Widget

#### Visual Specifications
| Property | Value |
|----------|-------|
| Height | ~80px (including padding) |
| Padding | 20px horizontal, 16px top, 12px bottom |
| Background | LinearGradient `#FF8A65` → `#E91E63` |
| Border Radius | None (full width) |

#### Content Layout
```
Row (mainAxisAlignment: spaceBetween)
├── Column (crossAxisAlignment: start)
│   ├── Text "Bondy" (headline-md, white, weight 800)
│   └── Text "Chào buổi sáng 👋" (body-md, white 90% opacity)
└── CircleAvatar
    ├── outer: 44px diameter, white background, 3px white border
    └── inner: 40px diameter, #FFE0CC background, centered emoji "👤"
```

#### Text Styles
| Element | Style |
|---------|-------|
| App Name | `headline-md`: 26px, weight 800, white |
| Greeting | `body-md`: 14px, white with 0.9 opacity |

---

### 3.2 BannerWidget

#### Container
| Property | Value |
|----------|-------|
| Width | `double.infinity` (full width minus margins) |
| Margin | 20px horizontal, 8px vertical |
| Padding | 20px all sides |
| Background | LinearGradient `#FF8A65` → `#E91E63` |
| Border Radius | 20px |
| Shadow | Pink-tinted, 16px blur, 6px offset, 25% opacity |

#### Content Layout
```
Row
├── Text emoji "📋" (36px font size)
├── SizedBox (width: 16px)
└── Expanded
    └── Column
        ├── Text (title) - 15px, weight 700, white
        └── GestureDetector → CTA Button
            ├── Container
            │   ├── padding: 16px horizontal, 8px vertical
            │   ├── background: white
            │   └── borderRadius: 20px
            └── Text (cta text) - 13px, weight 700, primary color
```

#### Interaction
- Tap CTA button navigates to `/survey/intro` when `action == 'COMPLETE_SURVEY'`

---

### 3.3 EmotionCheckinWidget

#### Container
| Property | Value |
|----------|-------|
| Background | white |
| Border Radius | 20px |
| Border | 1px solid `#FFE0E6` |
| Shadow | 12px blur, 4px offset, 5% opacity |
| Padding | 20px all sides |

#### Layout Structure
```
Column (crossAxisAlignment: start)
├── Row
│   ├── Container (icon wrapper)
│   │   ├── size: 44px × 44px
│   │   ├── background: #FFE0E6
│   │   ├── borderRadius: 12px
│   │   └── child: emoji "💝" (22px)
│   ├── SizedBox (width: 12px)
│   └── Column
│       ├── Text "Check-in cảm xúc hôm nay" (title-sm, weight 700, #1A1A2E)
│       └── Text "Bạn đang cảm thấy thế nào với [partnerName]?" (body-sm, #6B7280)
├── SizedBox (height: 16px)
└── Row (mainAxisAlignment: spaceAround)
    └── _MoodChip × 4 (😊 Vui, 😌 Bình yên, 😔 Buồn, 😰 Lo lắng)
```

#### _MoodChip Component
| Property | Value |
|----------|-------|
| Layout | Column (center alignment) |
| Emoji | 28px font size |
| Label | 11px, `#6B7280` |

#### Interaction
- Tap shows SnackBar: "Đã ghi nhận cảm xúc: [label]"
- Future: calls API with mood + relationshipId

---

### 3.4 MilestoneReminderWidget

#### Container
| Property | Value |
|----------|-------|
| Background | LinearGradient `#FFF3E0` → `#FFE0B2` |
| Border Radius | 20px |
| Border | 1px solid `#FFCC80` |
| Padding | 20px all sides |

#### Layout Structure
```
Row
├── Container (icon)
│   ├── size: 48px × 48px
│   ├── background: rgba(255, 152, 0, 0.15)
│   ├── shape: circle
│   └── child: emoji "🎉" (24px)
├── SizedBox (width: 16px)
├── Expanded
│   └── Column
│       ├── Text (title) - 15px, weight 700, #1A1A2E
│       └── Text (date) - 12px, #6B7280 (if date is not empty)
└── Container (days badge)
    ├── padding: 12px horizontal, 6px vertical
    ├── background: #FF9800
    ├── borderRadius: 20px
    └── Text (daysText) - 12px, weight 700, white

DaysText logic:
- 0 days left → "Hôm nay!"
- 1 day left → "Còn 1 ngày"
- N days left → "Còn N ngày"
```

---

### 3.5 DiscoveryCardWidget

#### Container
| Property | Value |
|----------|-------|
| Margin | 20px horizontal, 8px vertical |
| Child | Column |

#### Section Header
| Property | Value |
|----------|-------|
| Padding | 12px bottom |
| Text | "Gợi ý kết nối cho bạn ✨" (title-md, weight 700, #1A1A2E) |

#### Profile List
| Property | Value |
|----------|-------|
| Height | 160px |
| Scroll Direction | horizontal |
| Item Spacing | 12px |

#### _ProfileChip Component
| Property | Value |
|----------|-------|
| Width | 130px |
| Padding | 16px all sides |
| Background | white |
| Border Radius | 16px |
| Border | 1px solid #E5E7EB |
| Shadow | 8px blur, 2px offset, 4% opacity |

#### Profile Chip Content
```
Column (crossAxisAlignment: start)
├── CircleAvatar
│   ├── radius: 24px (48px diameter)
│   ├── background: #FFE0E6
│   └── child: emoji "👤" (22px)
├── SizedBox (height: 10px)
├── Text (name) - 14px, weight 700, #1A1A2E, overflow ellipsis
├── Text (city) - 11px, #6B7280, overflow ellipsis (if city is not empty)
└── Text (interests) - 10px, weight 600, #FF5864, overflow ellipsis (if interests not empty)
    └── shows: interests.take(2).join(', ')
```

#### Empty State (_EmptyDiscovery)
| Property | Value |
|----------|-------|
| Width | `double.infinity` |
| Padding | 20px all sides |
| Background | #F9FAFB |
| Border Radius | 16px |
| Border | 1px solid #E5E7EB |
| Text | "Thêm sở thích vào profile để Bondy gợi ý tốt hơn 🎯" (body-sm, #6B7280, center aligned) |

---

### 3.6 SuggestionCardWidget

#### Container
| Property | Value |
|----------|-------|
| Width | `double.infinity` |
| Margin | 20px horizontal, 8px vertical |
| Padding | 20px all sides |
| Background | LinearGradient `#FFB3A7` → `#E8A0BF` → `#AE8FDB` (topLeft to bottomRight) |
| Border Radius | 20px |
| Shadow | 20px blur, 8px offset, 30% opacity (gradient color) |

#### Content Layout
```
Column (crossAxisAlignment: start)
├── Container (badge)
│   ├── padding: 12px horizontal, 6px vertical
│   ├── background: white 30% opacity
│   ├── borderRadius: 20px
│   └── Text "DAILY INSPIRATION" - label-sm, weight 700, white, letterSpacing 1
├── SizedBox (height: 14px)
├── Text (title) - 20px, weight 800, white, height 1.2
├── SizedBox (height: 8px)
├── Text (content) - 13px, white 85% opacity, height 1.4 (if content is not empty)
├── SizedBox (height: 16px)
├── Center
│   └── Text emoji "🧘‍♀️" (48px)
├── SizedBox (height: 16px)
└── GestureDetector → CTA Button
    ├── width: double.infinity
    ├── padding: 14px vertical
    ├── background: LinearGradient #FF8A50 → #D946B8
    ├── borderRadius: 30px
    └── Row (center)
        ├── Text "Bắt đầu hành trình" - title-sm, weight 700, white
        └── SizedBox (width: 6px)
            └── Icon arrow_forward (18px, white)
```

#### Interaction
- Tap navigates to `/content`

---

### 3.7 FloatingActionButton (Bondy Coach)

| Property | Value |
|----------|-------|
| Type | FloatingActionButton.extended |
| Background | `#FF4D6D` |
| Icon | `Icons.chat_bubble` (20px, white) |
| Label | "Hỏi Bondy" (14px, weight 600, white) |
| Position | Default FAB position (bottom right, above bottom nav) |

---

## 4. Bottom Navigation Specification

### 4.1 Container
| Property | Value |
|----------|-------|
| Height | 90px |
| Background | white |
| Border Radius | `BorderRadius.vertical(top: Radius.circular(24))` |
| Shadow | 20px blur, -4px offset, 8% opacity |
| Padding | 16px bottom, 2px top |
| extendBody | true (to render behind safe area) |

### 4.2 Navigation Items

#### Layout
```
Row (mainAxisAlignment: spaceEvenly, crossAxisAlignment: center)
├── _buildNavItem (Home)
├── _buildNavItem (Healing)
├── _buildMatchButton (MATCH - center elevated)
├── _buildNavItemWithBadge (Matches)
└── _buildNavItem (Profile)
```

### 4.3 Standard Nav Item (_buildNavItem)

| Property | Value |
|----------|-------|
| Width | 56px |
| Icon Size | 24px |
| Label | label-lg (14px), weight 500 |
| Active Color | `#FF5864` |
| Inactive Color | `#9CA3AF` |

### 4.4 Nav Item with Badge (_buildNavItemWithBadge)

| Property | Value |
|----------|-------|
| Icon | Same as standard |
| Badge | 8px × 8px circle, `#FF5864`, positioned top-right (-1px, -3px) |
| Badge Border | 1.5px white |

### 4.5 Match Button (_buildMatchButton)

| Property | Value |
|----------|-------|
| Icon Container | 56px × 56px circle |
| Icon | `Icons.favorite` (26px, white) |
| Background | `#FF5864` |
| Border | 4px white |
| Shadow | 16px blur, 6px offset, 30% opacity |
| Offset | -14px vertical (elevated above nav bar) |
| Label | "MATCH" (10px, weight 700, `#EB5757`, letterSpacing 0.5) |
| Label Offset | -12px vertical |

### 4.6 Tab Definitions

| Index | Icon (inactive) | Icon (active) | Label | Route |
|-------|----------------|--------------|-------|-------|
| 0 | `Icons.home_outlined` | `Icons.home` | Home | (current tab) |
| 1 | `Icons.self_improvement_outlined` | `Icons.self_improvement` | Healing | _HealingTab |
| 2 | (MATCH button) | (MATCH button) | (MATCH) | /discover |
| 3 | `Icons.chat_bubble_outline` | `Icons.chat_bubble` | Matches | _CommunityTab |
| 4 | `Icons.person_outline` | `Icons.person` | Profile | _ProfileTab |

---

## 5. State Management

### 5.1 Architecture Pattern
- **Pattern:** ChangeNotifier + ListenableBuilder
- **ViewModel:** `HomeViewModel`

### 5.2 State Classes

```dart
// lib/viewmodels/home/home_viewmodel.dart

sealed class HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<HomeWidget> widgets;
  HomeLoaded(this.widgets);
}

class HomeError extends HomeState {
  final String message;
  HomeError(this.message);
}
```

### 5.3 ViewModel Interface

```dart
class HomeViewModel extends ChangeNotifier {
  HomeState state = HomeLoading();

  Future<void> loadContent(String userId) async { ... }
  Future<void> loadAuthenticatedContent({AuthService? authService}) async { ... }
  Future<void> refresh(String userId) async { ... }
  Future<void> refreshAuthenticated({AuthService? authService}) async { ... }
}
```

### 5.4 Data Flow

```
1. _HomeTabState.initState()
   └── _viewModel.loadAuthenticatedContent()

2. HomeViewModel.loadAuthenticatedContent()
   ├── Gets userId from AuthService
   └── Calls loadContent(userId)

3. HomeViewModel.loadContent(userId)
   ├── state = HomeLoading()
   ├── notifyListeners()
   ├── HomeService.fetchHomeContent(userId)
   │   └── ApiClient.get('/home/content?userId=$userId')
   ├── state = HomeLoaded(widgets) OR HomeError(message)
   └── notifyListeners()

4. _HomeTabState.build()
   └── ListenableBuilder(listenable: _viewModel)
       └── Switch on state:
           ├── HomeLoading → CircularProgressIndicator
           ├── HomeError → RefreshIndicator + error UI
           └── HomeLoaded → ListView.builder with widget dispatch
```

### 5.5 Widget Type Dispatch

```dart
return switch (w.widgetType) {
  'BANNER' => BannerWidget(data: w.data),
  'EMOTION_CHECKIN' => EmotionCheckinWidget(data: w.data),
  'MILESTONE_REMINDER' => MilestoneReminderWidget(data: w.data),
  'DISCOVERY_CARD' => DiscoveryCardWidget(data: w.data),
  'SUGGESTION_CARD' => SuggestionCardWidget(data: w.data),
  _ => const SizedBox.shrink(), // unknown type — skip
};
```

### 5.6 HomeWidget Model

```dart
// lib/models/home/home_widget_model.dart

class HomeWidget {
  final String id;
  final String widgetType;  // BANNER | EMOTION_CHECKIN | MILESTONE_REMINDER | DISCOVERY_CARD | SUGGESTION_CARD
  final int priority;       // Lower = higher priority, displayed first
  final Map<String, dynamic> data;

  HomeWidget({
    required this.id,
    required this.widgetType,
    required this.priority,
    required this.data,
  });

  factory HomeWidget.fromJson(Map<String, dynamic> json) { ... }
}
```

---

## 6. HomeService Specification

### 6.1 Service Interface

```dart
// lib/services/home_service.dart

class HomeService {
  final ApiClient _apiClient;

  HomeService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<HomeWidget>> fetchHomeContent(String userId) async {
    final body = await _apiClient.get('/home/content?userId=$userId');
    if (body['success'] != true) {
      throw Exception(body['error']?.toString() ?? 'Lỗi không xác định');
    }

    final widgetsJson = (body['data']?['widgets'] as List<dynamic>?) ?? [];

    final widgets = widgetsJson
        .map((w) => HomeWidget.fromJson(w as Map<String, dynamic>))
        .toList();

    // Sort by priority ascending (lower = displayed first)
    widgets.sort((a, b) => a.priority.compareTo(b.priority));
    return widgets;
  }
}
```

### 6.2 API Endpoint

| Method | Endpoint | Auth Required |
|--------|----------|---------------|
| GET | `/home/content?userId={userId}` | Yes |

---

## 7. Interaction Specifications

### 7.1 Pull-to-Refresh

| Property | Value |
|----------|-------|
| Widget | RefreshIndicator |
| Color | `#FF4D6D` |
| onRefresh | `_viewModel.refreshAuthenticated()` |
| Physics | AlwaysScrollableScrollPhysics |

### 7.2 Navigation Interactions

| Action | Result |
|--------|--------|
| Tap Home tab | Switch to _HomeTab (no navigation) |
| Tap Healing tab | Switch to _HealingTab |
| Tap MATCH button | Navigate to `/discover` |
| Tap Matches tab | Switch to _CommunityTab |
| Tap Profile tab | Switch to _ProfileTab |
| Tap Bondy Coach FAB | Navigate to `/chatbot` |

### 7.3 Widget Interactions

| Widget | Action | Result |
|--------|--------|--------|
| BannerWidget CTA | Tap | Navigate to `/survey/intro` |
| EmotionCheckinWidget mood | Tap | Show SnackBar confirmation |
| MilestoneReminderWidget | Tap | (Currently no action) |
| DiscoveryCardWidget chip | Tap | Navigate to `/discover` |
| SuggestionCardWidget CTA | Tap | Navigate to `/content` |

---

## 8. Design System Compliance

### 8.1 "No-Line" Rule Compliance
- No 1px solid borders used for sectioning
- Structure defined by background color shifts
- Borders only used where absolutely necessary (cards, inputs)
- MilestoneRemiderWidget uses gradient background transition instead of border

### 8.2 Glassmorphism Usage
- Bottom navigation bar uses semi-transparent white with shadow
- Modals (if any) would use 12-20px backdrop blur

### 8.3 Typography Compliance
- Plus Jakarta Sans used for all text (via GoogleFonts)
- Asymmetric tracking: headlines use letterSpacing: -0.02em
- Display text uses display-md (44px, 2.75rem)

### 8.4 Color Compliance
- No pure black (#000000) for text - uses `#2D0A15` (textPrimary)
- Primary gradient: `#FF0066` to `#FF007F` (not currently used - Stitch uses orange-pink)
- Shadow colors use tinted shadows (pink-tinted) rather than grey

### 8.5 Corner Radius Compliance
- All interactive elements use `radius-md` (16px) or larger
- No hard corners anywhere in the UI
- Buttons use `radius-xl` (24px) or `radius-full` (9999px)

### 8.6 Spacing Compliance
- All spacing follows the spacing scale
- Card internal padding: 20px (spacing-5)
- Horizontal margin: 20px
- Section gaps: 12-16px

---

## 9. Error States

### 9.1 HomeError State UI

```
Column (center)
├── Text emoji "😕" (48px)
├── SizedBox (height: 16px)
├── Text (state.message) - body-md, #6B7280, center aligned
├── SizedBox (height: 8px)
└── Text "Kéo xuống để thử lại" - label-md, #9CA3AF, center aligned
```

### 9.2 Loading State UI

```
Center
└── CircularProgressIndicator (color: #FF4D6D)
```

---

## 10. Technical Implementation Notes

### 10.1 File Structure

```
Bondy_App/lib/
├── screens/home/
│   └── main_shell_screen.dart       # Contains _HomeTab, _HealingTab, _CommunityTab, _ProfileTab
├── widgets/home/
│   ├── banner_widget.dart           # BANNER widget
│   ├── emotion_checkin_widget.dart   # EMOTION_CHECKIN widget
│   ├── milestone_reminder_widget.dart # MILESTONE_REMINDER widget
│   ├── discovery_card_widget.dart   # DISCOVERY_CARD widget
│   └── suggestion_card_widget.dart  # SUGGESTION_CARD widget
├── viewmodels/home/
│   └── home_viewmodel.dart          # HomeState, HomeViewModel
├── services/
│   ├── home_service.dart            # HomeService
│   └── api_client.dart              # ApiClient (shared)
└── models/home/
    └── home_widget_model.dart       # HomeWidget
```

### 10.2 Key Dependencies

| Package | Purpose |
|---------|---------|
| `flutter/material.dart` | Core Flutter widgets |
| `google_fonts/google_fonts.dart` | Plus Jakarta Sans typography |
| `provider` or built-in ChangeNotifier | State management |

### 10.3 Theme Integration

The `BondyTheme` class in `app_theme.dart` provides:
- Material 3 theme configuration
- ColorScheme with primary `#F87171`
- Scaffold background `#FFF8F6`
- TextTheme with Plus Jakarta Sans
- Component themes (elevated buttons, outlined buttons, inputs, cards, bottom nav)

---

## 11. Accessibility Notes

- All interactive elements have minimum 44px touch targets
- Text contrast ratios follow WCAG guidelines
- Icons have semantic labels in navigation
- All images (avatars) have fallback emoji display
- Color is not the only means of conveying information (labels accompany mood chips)

---

## 12. Performance Considerations

- ListView.builder used for widget list (lazy loading)
- IndexedStack for tab content (preserves state)
- Image.network includes errorBuilder for fallback
- Pull-to-refresh clears and reloads data
- FAB uses extendBody to avoid layout conflicts with bottom nav
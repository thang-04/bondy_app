# Bondy App Home Screen Rebuild - Master Specification

**Date:** 2026-05-14  
**Status:** Draft - Pending User Review  
**Scope:** Tab Home only (Flutter UI + Backend)

---

## Executive Summary

Rebuild the Bondy App Home Screen tab to match the Stitch "Bondy App Home Screen" design while implementing the "The Digital Sanctuary" design system from DESIGN.md. This is a full-stack effort requiring both Flutter UI updates and backend model implementations.

**Key Goals:**
1. Replace current hardcoded colors/widgets with DESIGN.md design system
2. Implement 3 missing backend models (Relationship, Checkin, Milestone)
3. Add new RelationshipStrengthCard widget
4. Ensure all widgets follow "No-Line Rule" and use Signature Gradient

---

## Part Index

| Part | Document | Size | Purpose |
|------|----------|------|---------|
| **Part 1** | `2026-05-14-bondy-home-screen-ui-ux-spec.md` | 30.2K | Wireframe, design tokens, layout |
| **Part 2** | `2026-05-14-bondy-home-screen-backend-spec.md` | 19.6K | Prisma schema, repositories, APIs |
| **Part 3** | `2026-05-14-bondy-home-screen-flutter-spec.md` | 65.2K | Theme changes, widget refactors |
| **Part 4** | `2026-05-14-bondy-design-migration-spec.md` | 22.6K | Token mapping, migration sequence |
| **Part 5** | `2026-05-14-bondy-home-screen-integration-testing-spec.md` | 36.7K | API contracts, test strategy |

---

## Screen Layout (ASCII Wireframe)

```
┌──────────────────────────────────────┐
│ [Blob decorations - gradient pink]    │
│                                      │
│  BONDY (gradient)         👤 Avatar │
│  "Chào buổi sáng"                    │
│                                      │
│ ┌──────────────────────────────┐     │
│ │ 💪 RELATIONSHIP STRENGTH     │     │
│ │ ████████████░░░░░░  78%      │     │ ← NEW Widget
│ │ 🔥 3 day streak              │     │
│ └──────────────────────────────┘     │
│                                      │
│ ┌────────┐ ┌────────┐ ┌────────┐      │
│ │  💬   │ │  🎯   │ │  📅   │      │
│ │Check-in│ │ Goals │ │ Dates │      │ ← Quick Actions
│ └────────┘ └────────┘ └────────┘      │
│                                      │
│ ┌──────────────────────────────┐     │
│ │ 💡 DAILY SUGGESTION           │     │
│ │ "Ask your partner: ..."      │     │
│ │               [Continue →]    │     │
│ └──────────────────────────────┘     │
│                                      │
│ ┌──────────────────────────────┐     │
│ │ 📝 Relationship Check-in      │     │
│ │    Complete your daily        │     │
│ │    emotional sync            │     │
│ └──────────────────────────────┘     │
│                                      │
│ ┌──────────────────────────────┐     │
│ │ 🎮 Communication Challenge     │     │
│ │    3-day streak 🔥            │     │
│ └──────────────────────────────┘     │
│                                      │
│    [Hỏi Bondy 💬] (FAB)             │
├──────────────────────────────────────┤
│   🏠    🧘    MATCH 💕    💬    👤   │
└──────────────────────────────────────┘
```

---

## Design System Reference

### Colors (from DESIGN.md "The Digital Sanctuary")

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

### Key Design Rules

1. **No-Line Rule:** No 1px borders for sectioning. Use color shifts instead.
2. **Signature Gradient:** Only for main CTAs and hero headers.
3. **Tinted Shadows:** `rgba(183, 0, 71, 0.08)` at 32px+ blur.
4. **Corner Radius:** md (24px) for buttons, lg (32px) for containers.
5. **Glassmorphism:** 12-20px blur + 70% opacity for overlays.
6. **Liquid Transitions:** `Cubic(0.4, 0, 0.2, 1)` ease-in-out.

---

## Backend Models Required

### 1. Relationship Model
```prisma
model Relationship {
  id        String   @id @default(cuid())
  user1Id   String
  user2Id   String
  status    String   // ACTIVE, PAUSED, ENDED
  createdAt DateTime @default(now())
  checkins  Checkin[]
  milestones Milestone[]
}
```

### 2. Checkin Model
```prisma
model Checkin {
  id              String   @id @default(cuid())
  relationshipId  String
  userId          String
  emotionLevel    Int      // 1-5
  emotionLabel    String   // HAPPY, PEACEFUL, SAD, ANXIOUS
  note            String?
  createdAt       DateTime @default(now())
}
```

### 3. Milestone Model
```prisma
model Milestone {
  id              String   @id @default(cuid())
  relationshipId  String
  title           String
  milestoneType   String
  date            DateTime
  isRecurring     Boolean  @default(false)
  reminderDays    Int
  completed       Boolean @default(false)
  createdAt       DateTime @default(now())
}
```

### Repository Methods to Implement
- `getActiveRelationship(userId)` → returns partner info
- `hasTodayCheckin(userId)` → returns boolean
- `getUpcomingMilestone(userId)` → returns milestone within 7 days
- `saveCheckin()`, `getRecentCheckins()`, `createRelationship()`, `createMilestone()`

---

## Widget Refactor Summary

| Widget | Key Changes |
|--------|-------------|
| BannerWidget | Signature gradient, no border, 24px radius, ambient shadow |
| EmotionCheckinWidget | NO BORDER (no-line rule), color layering, Material icons |
| MilestoneReminderWidget | Tertiary gradient, no border, tinted shadow |
| DiscoveryCardWidget | NO BORDER, pink-tinted shadow rgba(183,0,71,0.08) |
| SuggestionCardWidget | Signature gradient CTA, secondary_container badge |
| **RelationshipStrengthCard** | **NEW** - progress bar, streak badge, glassmorphism |

---

## Implementation Checklist

### Phase 1: Backend (Priority)
- [ ] Create Prisma migration for 3 new models
- [ ] Implement repository methods in `home.repository.ts`
- [ ] Update service layer if needed
- [ ] Add seed data for testing
- [ ] Verify with API tests

### Phase 2: Flutter Theme
- [ ] Update `app_theme.dart` with DESIGN.md colors
- [ ] Add BondyColors, BondyRadius, BondyShadows classes
- [ ] Add typography styles (Plus Jakarta Sans + Inter)
- [ ] Verify theme compilation

### Phase 3: Flutter Widgets
- [ ] Refactor BannerWidget
- [ ] Refactor EmotionCheckinWidget
- [ ] Refactor MilestoneReminderWidget
- [ ] Refactor DiscoveryCardWidget
- [ ] Refactor SuggestionCardWidget
- [ ] Create new RelationshipStrengthCard

### Phase 4: MainShellScreen
- [ ] Update header gradient
- [ ] Update bottom navigation
- [ ] Add Quick Actions grid
- [ ] Add FAB for Bondy Coach
- [ ] Verify scroll behavior
- [ ] Test on multiple screen sizes

### Phase 5: Integration & Testing
- [ ] Connect Flutter to real backend APIs
- [ ] Add unit tests (HomeService)
- [ ] Add widget tests
- [ ] Add integration tests
- [ ] Visual verification against Stitch design
- [ ] Accessibility check

---

## Files to Modify

### Flutter (Bondy_App)
```
lib/
├── theme/
│   └── app_theme.dart                    [MODIFY]
├── screens/
│   └── home/
│       └── main_shell_screen.dart       [MODIFY]
├── widgets/
│   └── home/
│       ├── banner_widget.dart           [MODIFY]
│       ├── emotion_checkin_widget.dart  [MODIFY]
│       ├── milestone_reminder_widget.dart [MODIFY]
│       ├── discovery_card_widget.dart   [MODIFY]
│       ├── suggestion_card_widget.dart   [MODIFY]
│       └── relationship_strength_card.dart [NEW]
├── viewmodels/
│   └── home/
│       └── home_viewmodel.dart         [MODIFY - if needed]
└── services/
    └── home_service.dart                [MODIFY - if needed]
```

### Backend (bondy_server)
```
src/
├── repositories/
│   └── home.repository.ts               [MODIFY]
├── services/
│   └── home.service.ts                 [MODIFY - if needed]
└── prisma/
    └── schema.prisma                   [MODIFY]
```

---

## Critical Design Rules

1. **NO 1px borders** - Use background color shifts for sectioning
2. **NO pure black** - Use `#302e30` for text
3. **NO black shadows** - Use pink-tinted `rgba(183, 0, 71, 0.08)`
4. **NO hard corners** - Everything 24px+ radius
5. **Signature gradient only for CTAs** - `#FF0066 → #FF007F`
6. **Glassmorphism for overlays** - 12-20px blur + 70% opacity

---

## Next Steps

1. **User reviews and approves** this master spec
2. **Writing-plans skill invoked** to create implementation plan
3. Execute implementation in phases per checklist

---

**Approval Required Before Proceeding to Implementation**

Please review the spec documents and let me know if you want any changes:
- Any modifications to scope?
- Any sections need more detail?
- Questions about approach?
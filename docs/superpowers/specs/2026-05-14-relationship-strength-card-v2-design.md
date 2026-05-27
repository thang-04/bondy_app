# RelationshipStrengthCard - Redesign Spec (v2)

**Date:** 2026-05-14
**Status:** Draft - For Future Version
**Type:** Widget Design

---

## Overview

Redesign `RelationshipStrengthCard` để đơn giản hơn, dễ implement, và lấy data từ API thật.

## Current State (v1 - Removed)

- Quá phức tạp với nhiều data points
- Sử dụng mock data
- Backend API chưa support

## Proposed Design (v2)

### UI Layout

```
┌─────────────────────────────────────────────┐
│  💕  Cùng nhau xây dựng                    │
│      [Partner Name]                        │
│                                             │
│  ████████████░░░░░░░░░░░░  75%            │
│                                             │
│  🔥 7 ngày streak    ✓ Đã check-in hôm nay│
└─────────────────────────────────────────────┘
```

### Data Required

| Field | Source | Description |
|-------|--------|-------------|
| `partner_name` | `getActiveRelationship().partnerName` | Tên partner |
| `strength_score` | Tính toán từ checkins | 0-100% |
| `streak_days` | Tính từ checkin pattern | Số ngày liên tiếp |
| `checked_in_today` | `hasTodayCheckin()` | Boolean |

### Backend API Changes

**Option A: Add new endpoint**

```typescript
// GET /api/home/relationship-status?userId=xxx
{
  partnerName: string | null,
  strengthScore: number,
  streakDays: number,
  checkedInToday: boolean
}
```

**Option B: Extend existing widget**

Add `RELATIONSHIP_STRENGTH` widget_type to `buildHomeContent()` response.

### Implementation Approach

1. Backend: Add `getRelationshipStrength()` method to `homeRepository`
2. Backend: Create new API endpoint or extend existing
3. Frontend: Create new simplified `RelationshipStrengthCard`
4. Frontend: Integrate via HomeViewModel

### Simplification Compared to v1

| v1 | v2 |
|----|-----|
| 5 data points | 4 data points |
| Common interests display | Removed (complex to compute) |
| Last checkin time | Replaced with "checked_in_today" boolean |
| Strength meter detailed | Simplified progress bar |

---

## Notes

- Design spec only - implementation in future version
- Waiting for backend to support relationship data properly
# Bondy Home Screen Backend Specification

**Issue:** bondy-home-backend  
**Status:** Draft  
**Date:** 2026-05-14  
**Design System:** "The Digital Sanctuary"

---

## 1. Overview

This specification covers backend changes required to power the Bondy App Home Screen. The home screen displays personalized widgets based on user state, relationship status, check-in history, and upcoming milestones.

**Current Gaps:**
- `getActiveRelationship()` returns `null` - no Relationship model
- `hasTodayCheckin()` returns `false` - no Checkin model
- `getUpcomingMilestone()` returns `null` - no Milestone model

**Scope:** bondy_server (Node.js/Express/Prisma/PostgreSQL)

---

## 2. Prisma Schema Changes

### 2.1 Relationship Model

Represents an active partnership between two matched users.

```prisma
model Relationship {
  id              String            @id @default(cuid())
  user1Id         String
  user2Id         String
  status          RelationshipStatus @default(ACTIVE)
  startedAt       DateTime          @default(now())
  endedAt         DateTime?

  user1           User              @relation("RelationshipUser1", fields: [user1Id], references: [id], onDelete: Cascade)
  user2           User              @relation("RelationshipUser2", fields: [user2Id], references: [id], onDelete: Cascade)
  checkins        Checkin[]
  milestones      Milestone[]

  createdAt       DateTime          @default(now())
  updatedAt       DateTime          @updatedAt

  @@unique([user1Id, user2Id])
  @@index([user1Id])
  @@index([user2Id])
  @@index([status])
}

enum RelationshipStatus {
  ACTIVE
  PAUSED
  ENDED
}
```

### 2.2 Checkin Model

Daily emotional check-in records for each relationship.

```prisma
model Checkin {
  id              String          @id @default(cuid())
  relationshipId  String
  userId          String
  emotionLevel    Int            // 1-5 scale
  emotionLabel    String?         // e.g., "happy", "anxious", "grateful"
  note            String?
  isShared        Boolean         @default(false)
  sharedAt        DateTime?
  createdAt       DateTime        @default(now())
  updatedAt       DateTime        @updatedAt

  relationship    Relationship    @relation(fields: [relationshipId], references: [id], onDelete: Cascade)

  @@unique([relationshipId, userId, createdAt]) // One checkin per user per day
  @@index([relationshipId, createdAt])
  @@index([userId, createdAt])
}
```

**Validation Rules:**
- `emotionLevel`: Integer, 1-5 inclusive
- `emotionLabel`: Optional string, max 50 characters
- `note`: Optional string, max 500 characters
- `isShared`: Boolean, defaults to false

### 2.3 Milestone Model

Important dates and reminders for relationships.

```prisma
model Milestone {
  id              String          @id @default(cuid())
  relationshipId  String
  title           String
  milestoneType   MilestoneType
  date            DateTime
  isRecurring     Boolean         @default(false)
  reminderDays    Int             @default(7)        // Days before to send reminder
  isNotified      Boolean         @default(false)
  createdAt       DateTime        @default(now())
  updatedAt       DateTime        @updatedAt

  relationship    Relationship    @relation(fields: [relationshipId], references: [id], onDelete: Cascade)

  @@index([relationshipId, date])
  @@index([date, isNotified])
}

enum MilestoneType {
  ANNIVERSARY
  BIRTHDAY
  SPECIAL_DATE
  CUSTOM
}
```

**Validation Rules:**
- `title`: Required string, max 100 characters
- `milestoneType`: Enum value
- `date`: Required DateTime
- `isRecurring`: Boolean, defaults to false
- `reminderDays`: Integer, 1-30, defaults to 7

### 2.4 User Model - Add Relations

Add to existing User model:

```prisma
model User {
  // ... existing fields ...

  // Add these relations
  relationships1     Relationship[]    @relation("RelationshipUser1")
  relationships2     Relationship[]    @relation("RelationshipUser2")
  checkins           Checkin[]
}
```

---

## 3. Repository Layer

### 3.1 File: `src/repository/home.repository.ts`

Add/modify these methods:

#### getActiveRelationship

```typescript
async getActiveRelationship(userId: string): Promise<{
  id: string;
  partnerId: string;
  partnerName: string | null;
} | null> {
  // Find relationship where user is user1 or user2 and status is ACTIVE
  const relationship = await prisma.relationship.findFirst({
    where: {
      status: 'ACTIVE',
      OR: [
        { user1Id: userId },
        { user2Id: userId },
      ],
    },
    include: {
      user1: { include: { profile: { select: { fullName: true } } } },
      user2: { include: { profile: { select: { fullName: true } } } },
    },
    orderBy: { startedAt: 'desc' },
  });

  if (!relationship) return null;

  const isUser1 = relationship.user1Id === userId;
  const partner = isUser1 ? relationship.user2 : relationship.user1;
  const partnerName = partner.profile?.fullName ?? null;
  const partnerId = partner.id;

  return {
    id: relationship.id,
    partnerId,
    partnerName,
  };
}
```

#### hasTodayCheckin

```typescript
async hasTodayCheckin(relationshipId: string, userId: string): Promise<boolean> {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);

  const checkin = await prisma.checkin.findFirst({
    where: {
      relationshipId,
      userId,
      createdAt: {
        gte: today,
        lt: tomorrow,
      },
    },
  });

  return checkin !== null;
}
```

#### getUpcomingMilestone

```typescript
async getUpcomingMilestone(relationshipId: string): Promise<{
  id: string;
  title: string;
  date: string;
  daysLeft: number;
  milestoneType: string;
} | null> {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const nextWeek = new Date(today);
  nextWeek.setDate(nextWeek.getDate() + 7);

  const milestone = await prisma.milestone.findFirst({
    where: {
      relationshipId,
      date: {
        gte: today,
        lte: nextWeek,
      },
    },
    orderBy: { date: 'asc' },
  });

  if (!milestone) return null;

  const daysLeft = Math.ceil(
    (milestone.date.getTime() - today.getTime()) / (1000 * 60 * 60 * 24)
  );

  return {
    id: milestone.id,
    title: milestone.title,
    date: milestone.date.toISOString(),
    daysLeft,
    milestoneType: milestone.milestoneType,
  };
}
```

#### saveCheckin (New Method)

```typescript
async saveCheckin(input: {
  relationshipId: string;
  userId: string;
  emotionLevel: number;
  emotionLabel?: string;
  note?: string;
}): Promise<Checkin> {
  return prisma.checkin.create({
    data: {
      relationshipId: input.relationshipId,
      userId: input.userId,
      emotionLevel: input.emotionLevel,
      emotionLabel: input.emotionLabel,
      note: input.note,
    },
  });
}
```

#### getRecentCheckins (New Method)

```typescript
async getRecentCheckins(
  relationshipId: string,
  limit = 7
): Promise<Array<{
  id: string;
  userId: string;
  emotionLevel: number;
  emotionLabel: string | null;
  note: string | null;
  isShared: boolean;
  createdAt: string;
}>> {
  const checkins = await prisma.checkin.findMany({
    where: { relationshipId },
    orderBy: { createdAt: 'desc' },
    take: limit,
  });

  return checkins.map((c) => ({
    id: c.id,
    userId: c.userId,
    emotionLevel: c.emotionLevel,
    emotionLabel: c.emotionLabel,
    note: c.note,
    isShared: c.isShared,
    createdAt: c.createdAt.toISOString(),
  }));
}
```

#### createRelationship (New Method)

```typescript
async createRelationship(user1Id: string, user2Id: string): Promise<Relationship> {
  // Ensure consistent ordering (smaller ID first)
  const [firstId, secondId] = user1Id < user2Id ? [user1Id, user2Id] : [user2Id, user1Id];

  return prisma.relationship.create({
    data: {
      user1Id: firstId,
      user2Id: secondId,
      status: 'ACTIVE',
    },
  });
}
```

#### createMilestone (New Method)

```typescript
async createMilestone(input: {
  relationshipId: string;
  title: string;
  milestoneType: MilestoneType;
  date: Date;
  isRecurring?: boolean;
  reminderDays?: number;
}): Promise<Milestone> {
  return prisma.milestone.create({
    data: {
      relationshipId: input.relationshipId,
      title: input.title,
      milestoneType: input.milestoneType,
      date: input.date,
      isRecurring: input.isRecurring ?? false,
      reminderDays: input.reminderDays ?? 7,
    },
  });
}
```

---

## 4. Service Layer

### 4.1 File: `src/service/home.service.ts`

Modify `buildHomeContent` to call the new repository methods.

### 4.2 Home Response DTO

```typescript
// src/dto/home.dto.ts

export interface HomeWidget {
  widget_type: 'BANNER' | 'SUGGESTION_CARD' | 'EMOTION_CHECKIN' | 'MILESTONE_REMINDER' | 'DISCOVERY_CARD';
  priority: number;
  data: BannerData | SuggestionCardData | EmotionCheckinData | MilestoneReminderData | DiscoveryCardData;
}

export interface BannerData {
  action: 'COMPLETE_SURVEY';
  title: string;
  cta: string;
}

export interface SuggestionCardData {
  dating_goal: string;
  title: string;
  content: string;
}

export interface EmotionCheckinData {
  relationship_id: string;
  partner_name: string;
}

export interface MilestoneReminderData {
  id?: string; // milestone id
  title: string;
  date: string;
  days_left: number;
  milestone_type?: string;
}

export interface DiscoveryCardData {
  profiles: Array<{
    user_id: string;
    name: string | null;
    city: string | null;
    common_interests: string[];
  }>;
}

export interface HomeResponse {
  widgets: HomeWidget[];
}
```

### 4.3 Checkin Request DTO

```typescript
export interface CreateCheckinRequest {
  relationshipId: string;
  emotionLevel: number;      // 1-5, required
  emotionLabel?: string;     // max 50 chars
  note?: string;            // max 500 chars
}

export interface CreateCheckinResponse {
  success: boolean;
  data: {
    id: string;
    createdAt: string;
  };
}
```

---

## 5. API Response Structures

### 5.1 GET /api/home

**Response (200 OK):**

```json
{
  "widgets": [
    {
      "widget_type": "EMOTION_CHECKIN",
      "priority": 1,
      "data": {
        "relationship_id": "rel_abc123",
        "partner_name": "Minh"
      }
    },
    {
      "widget_type": "MILESTONE_REMINDER",
      "priority": 2,
      "data": {
        "id": "mil_xyz789",
        "title": "1 Month Anniversary",
        "date": "2026-05-20T00:00:00.000Z",
        "days_left": 6,
        "milestone_type": "ANNIVERSARY"
      }
    },
    {
      "widget_type": "SUGGESTION_CARD",
      "priority": 3,
      "data": {
        "dating_goal": "serious",
        "title": "Xây dựng tình yêu bền vững 💑",
        "content": "Hãy thử chia sẻ điều bạn trân trọng nhất trong một mối quan hệ."
      }
    }
  ]
}
```

### 5.2 POST /api/checkin

**Request:**

```json
{
  "relationshipId": "rel_abc123",
  "emotionLevel": 4,
  "emotionLabel": "happy",
  "note": "Feeling great today!"
}
```

**Response (201 Created):**

```json
{
  "success": true,
  "data": {
    "id": "chk_abc456",
    "createdAt": "2026-05-14T10:30:00.000Z"
  }
}
```

**Error Response (400 Bad Request):**

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "emotionLevel must be between 1 and 5"
  }
}
```

### 5.3 GET /api/relationships/:relationshipId/checkins

**Query Parameters:**
- `limit`: number (default: 7, max: 30)
- `offset`: number (default: 0)

**Response (200 OK):**

```json
{
  "success": true,
  "data": {
    "checkins": [
      {
        "id": "chk_abc456",
        "userId": "user_123",
        "emotionLevel": 4,
        "emotionLabel": "happy",
        "note": "Feeling great today!",
        "isShared": false,
        "createdAt": "2026-05-14T10:30:00.000Z"
      }
    ],
    "pagination": {
      "total": 14,
      "limit": 7,
      "offset": 0
    }
  }
}
```

### 5.4 POST /api/relationships/:relationshipId/milestones

**Request:**

```json
{
  "title": "1 Month Anniversary",
  "milestoneType": "ANNIVERSARY",
  "date": "2026-05-20",
  "isRecurring": false,
  "reminderDays": 3
}
```

**Response (201 Created):**

```json
{
  "success": true,
  "data": {
    "id": "mil_xyz789",
    "title": "1 Month Anniversary",
    "milestoneType": "ANNIVERSARY",
    "date": "2026-05-20T00:00:00.000Z",
    "isRecurring": false,
    "reminderDays": 3
  }
}
```

### 5.5 GET /api/relationships/:relationshipId/milestones

**Query Parameters:**
- `upcoming`: boolean (default: false) - if true, only return future milestones

**Response (200 OK):**

```json
{
  "success": true,
  "data": {
    "milestones": [
      {
        "id": "mil_xyz789",
        "title": "1 Month Anniversary",
        "milestoneType": "ANNIVERSARY",
        "date": "2026-05-20T00:00:00.000Z",
        "isRecurring": false,
        "isNotified": false,
        "daysLeft": 6
      }
    ]
  }
}
```

---

## 6. Migration Scripts

### 6.1 Migration File: `2026-05-14_home_screen_models.prisma`

```prisma
-- Create Relationship model
CREATE TABLE "Relationship" (
    "id" TEXT NOT NULL PRIMARY KEY DEFAULT cuuid(),
    "user1Id" TEXT NOT NULL,
    "user2Id" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'ACTIVE',
    "startedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "endedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "Relationship_user1Id_fkey" FOREIGN KEY ("user1Id") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "Relationship_user2Id_fkey" FOREIGN KEY ("user2Id") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE UNIQUE INDEX "Relationship_user1Id_user2Id_unique" ON "Relationship"("user1Id", "user2Id");
CREATE INDEX "Relationship_user1Id_idx" ON "Relationship"("user1Id");
CREATE INDEX "Relationship_user2Id_idx" ON "Relationship"("user2Id");
CREATE INDEX "Relationship_status_idx" ON "Relationship"("status");

-- Create Checkin model
CREATE TABLE "Checkin" (
    "id" TEXT NOT NULL PRIMARY KEY DEFAULT cuuid(),
    "relationshipId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "emotionLevel" INTEGER NOT NULL,
    "emotionLabel" TEXT,
    "note" TEXT,
    "isShared" BOOLEAN NOT NULL DEFAULT false,
    "sharedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "Checkin_relationshipId_fkey" FOREIGN KEY ("relationshipId") REFERENCES "Relationship"("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "Checkin_emotionLevel_range" CHECK ("emotionLevel" >= 1 AND "emotionLevel" <= 5)
);

CREATE UNIQUE INDEX "Checkin_relationshipId_userId_createdAt_unique" ON "Checkin"("relationshipId", "userId", "createdAt");
CREATE INDEX "Checkin_relationshipId_createdAt_idx" ON "Checkin"("relationshipId", "createdAt");
CREATE INDEX "Checkin_userId_createdAt_idx" ON "Checkin"("userId", "createdAt");

-- Create Milestone model
CREATE TABLE "Milestone" (
    "id" TEXT NOT NULL PRIMARY KEY DEFAULT cuuid(),
    "relationshipId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "milestoneType" TEXT NOT NULL,
    "date" TIMESTAMP(3) NOT NULL,
    "isRecurring" BOOLEAN NOT NULL DEFAULT false,
    "reminderDays" INTEGER NOT NULL DEFAULT 7,
    "isNotified" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "Milestone_relationshipId_fkey" FOREIGN KEY ("relationshipId") REFERENCES "Relationship"("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "Milestone_reminderDays_range" CHECK ("reminderDays" >= 1 AND "reminderDays" <= 30)
);

CREATE INDEX "Milestone_relationshipId_date_idx" ON "Milestone"("relationshipId", "date");
CREATE INDEX "Milestone_date_isNotified_idx" ON "Milestone"("date", "isNotified");

-- Create enum type for RelationshipStatus
CREATE TYPE "RelationshipStatus" AS ENUM ('ACTIVE', 'PAUSED', 'ENDED');

-- Create enum type for MilestoneType
CREATE TYPE "MilestoneType" AS ENUM ('ANNIVERSARY', 'BIRTHDAY', 'SPECIAL_DATE', 'CUSTOM');
```

### 6.2 Seed Data Script (Optional)

```typescript
// prisma/seed-home-screen.ts
import prisma from '../src/lib/prisma';

async function seedRelationshipForExistingMatches() {
  // Find all matches that don't have a relationship yet
  const matchesWithoutRelationship = await prisma.match.findMany({
    where: {
      NOT: {
        // This subquery would check if a relationship exists
        // We'll implement this after Relationship model is created
      }
    },
    include: {
      user1: true,
      user2: true,
    },
  });

  console.log(`Found ${matchesWithoutRelationship.length} matches without relationships`);

  for (const match of matchesWithoutRelationship) {
    await prisma.relationship.create({
      data: {
        user1Id: match.user1Id,
        user2Id: match.user2Id,
        status: 'ACTIVE',
      },
    });
    console.log(`Created relationship for match ${match.id}`);
  }
}

seedRelationshipForExistingMatches()
  .then(() => console.log('Done'))
  .catch(console.error);
```

---

## 7. File Structure

```
bondy_server/
├── prisma/
│   ├── schema.prisma                    # Add Relationship, Checkin, Milestone models
│   └── migrations/
│       └── 2026-05-14_home_screen_models/
│           └── migration.sql
│
├── src/
│   ├── repository/
│   │   └── home.repository.ts           # Update getActiveRelationship, hasTodayCheckin, getUpcomingMilestone
│   │                                     # Add saveCheckin, getRecentCheckins, createRelationship, createMilestone
│   │
│   ├── service/
│   │   └── home.service.ts              # Update buildHomeContent to use new repo methods
│   │
│   ├── dto/
│   │   └── home.dto.ts                  # HomeWidget, Checkin, Milestone DTOs
│   │
│   └── app/api/
│       ├── home/
│       │   └── route.ts                 # GET /api/home
│       ├── checkin/
│       │   └── route.ts                 # POST /api/checkin
│       └── relationships/
│           └── [relationshipId]/
│               ├── checkins/
│               │   └── route.ts         # GET /api/relationships/:id/checkins
│               └── milestones/
│                   └── route.ts         # GET, POST /api/relationships/:id/milestones
```

---

## 8. API Endpoints Summary

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /api/home | Get personalized home widgets |
| POST | /api/checkin | Create a checkin |
| GET | /api/relationships/:id/checkins | Get checkin history |
| POST | /api/relationships/:id/milestones | Create a milestone |
| GET | /api/relationships/:id/milestones | Get milestones |

---

## 9. Success Criteria

- [ ] Prisma schema includes Relationship, Checkin, Milestone models
- [ ] `getActiveRelationship()` returns partner info for users in ACTIVE relationship
- [ ] `hasTodayCheckin()` returns true if user already checked in today
- [ ] `getUpcomingMilestone()` returns milestone within 7 days if exists
- [ ] POST /api/checkin creates checkin record with validation
- [ ] GET /api/relationships/:id/checkins returns paginated checkin history
- [ ] POST /api/relationships/:id/milestones creates milestone with validation
- [ ] GET /api/relationships/:id/milestones returns milestones list
- [ ] All endpoints return consistent response format `{ success, data, error }`
- [ ] Migration script runs successfully on fresh database
- [ ] Unit tests pass for repository methods

---

## 10. Dependencies

- None (uses existing Prisma client, auth middleware)

## 11. Out of Scope

- Checkin sharing between partners (isShared field present but not exposed in API)
- Milestone notifications (isNotified field present but not exposed in API)
- Relationship pause/end functionality
- Chat message history in home screen
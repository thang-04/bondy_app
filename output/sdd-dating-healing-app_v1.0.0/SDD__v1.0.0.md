# Software Design Document: Dating Matching & Healing App

**Version:** 1.0.0  
**Date:** 2026-05-16  
**Status:** Draft  
**Author:** SDD Agent  

---

## 1. Introduction

### 1.1 Purpose

This Software Design Document (SDD) provides a comprehensive design specification for the Dating Matching & Healing App. The document details the system architecture, database design, API specifications, and use case implementations following IEEE Std 1016.

### 1.2 Scope

The application enables users to:
- Register and authenticate via email/password
- Create and manage profiles with required fields
- Discover compatible profiles using compatibility scoring
- Like/Pass profiles with swipe actions
- Create mutual matches with confirmation flow
- Engage in realtime chat with AI suggestions
- Access healing check-ins and affiliate courses
- Subscribe to tiered plans (Free, Plus, Premium, Elite)
- Admin management for moderation and user control

### 1.3 Definitions and Acronyms

| Term | Definition |
|------|------------|
| UC | Use Case |
| API | Application Programming Interface |
| DDL | Data Definition Language |
| ERD | Entity Relationship Diagram |
| SSO | Single Sign-On |
| JWT | JSON Web Token |
| NFR | Non-Functional Requirement |
| PII | Personally Identifiable Information |

### 1.4 Document Structure

This SDD follows IEEE Std 1016 with sections:
1. Introduction
2. References
3. Definitions
4. General Description
5. System Design
6. Detailed Design
7. Appendices

---

## 2. References

| Reference | Description |
|-----------|-------------|
| IEEE Std 1016-2009 | IEEE Standard for Information Technology - Systems Design - Software Design Descriptions |
| SRS-dating-healing-app.md | Software Requirements Specification document v1.0.0 |
| OpenAPI 3.0 | API Specification Standard |
| PlantUML | UML Diagram Language |
| MySQL 8.0 | Relational Database Management System |

---

## 3. Definitions

| Term | Definition |
|------|------------|
| **Actor** | External entity that interacts with the system |
| **Use Case** | Sequence of actions performed by the system |
| **Compatibility Score** | Algorithm-derived match percentage between users |
| **Mutual Match** | Both users have liked each other |
| **Conversation** | Chat channel created after mutual match confirmation |
| **Healing Check-In** | User mood and emotional state capture |
| **Affiliate Course** | Third-party healing content linked via affiliate |

---

## 4. General Description

### 4.1 System Context

The Dating Matching & Healing App is a mobile-first application that connects users seeking romantic relationships. The system provides discovery, matching, real-time communication, and healing support features.

**Key External Interfaces:**
- AI Service (chat suggestions, moderation detection)
- Payment Service (subscription management)
- Email Service (verification, notifications)
- Affiliate Providers (course recommendations)

### 4.2 Design Principles

1. **Security-First**: All inputs validated, PII protected, access controls enforced
2. **Scalability**: Stateless design, database indexing for performance
3. **Reliability**: Transaction integrity, idempotent operations
4. **Maintainability**: Clean separation of concerns, documented APIs

### 4.3 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                           CLIENTS                                    │
│                    Mobile App (iOS/Android)                          │
│                    Web App (Admin Dashboard)                         │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        API GATEWAY                                   │
│                   Authentication / Rate Limiting                     │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                    ┌─────────────┴─────────────┐
                    ▼                           ▼
        ┌───────────────────┐         ┌───────────────────┐
        │   CORE SERVICES   │         │   ADMIN SERVICES  │
        │  - Auth Service    │         │  - User Management│
        │  - Profile Service │         │  - Moderation     │
        │  - Discovery Svc   │         │  - Subscription   │
        │  - Match Service   │         │  - Affiliate Mgmt │
        │  - Chat Service    │         └───────────────────┘
        │  - Healing Service │                   │
        └─────────┬─────────┘                   │
                  │                             │
                  ▼                             ▼
        ┌─────────────────────────────────────────────────┐
        │              DATA LAYER (MySQL)                  │
        │   Users, Profiles, Matches, Messages, Logs      │
        └─────────────────────────────────────────────────┘
                  │                             │
                  ▼                             ▼
        ┌───────────────────┐         ┌───────────────────┐
        │   AI SERVICE      │         │   EXTERNAL SVCS   │
        │  - Chat Suggest   │         │  - Email Service  │
        │  - Moderation     │         │  - Payment Svc   │
        │  - Healing Logic   │         │  - Affiliate APIs│
        └───────────────────┘         └───────────────────┘
```

### 4.4 Module Decomposition

| Module | Responsibility | Key Components |
|--------|----------------|----------------|
| Auth Module | User registration, login, email verification | Register, Login, VerifyEmail, ForgotPassword |
| Profile Module | Profile CRUD, photo management, visibility | CreateProfile, UpdateProfile, HideProfile, DeleteAccount |
| Discovery Module | Compatibility scoring, profile filtering, discovery queue | DiscoverProfiles, CalculateCompatibility, ApplyFilters |
| Swipe Module | Like, Pass, Report actions | LikeProfile, PassProfile, ReportProfile |
| Match Module | Mutual match creation, confirmation flow, expiration | CreateMatch, ConfirmConversation, ExpireMatch, Unmatch |
| Conversation Module | Conversation management, member access control | CreateConversation, AddMember, CloseConversation |
| Chat Module | Real-time messaging, status updates | SendMessage, MarkSeen, TypingIndicator, OnlineStatus |
| AI Module | Chat suggestions, usage tracking, limits | SuggestMessage, TrackUsage, EnforceLimit |
| Healing Module | Check-in capture, content display, affiliate suggestions | CreateCheckIn, GetHealingContent, GetAffiliateCourses |
| Subscription Module | Tier management, paywall enforcement | GetSubscription, CheckLimit, UpgradePlan |
| Admin Module | User management, moderation, reporting | ManageUser, ReviewProfile, ProcessReport |

---

## 5. System Design

### 5.1 Architecture Design

#### 5.1.1 Overall System Architecture

See: `diagrams/architecture.puml`

#### 5.1.2 Deployment Architecture

See: `diagrams/deployment.puml`

#### 5.1.3 Data Model

See: `diagrams/data_model.puml`

### 5.2 Database Design

#### 5.2.1 Database Schema (MySQL 8.0)

See: `db/schema.sql`

#### 5.2.2 Key Tables

| Table | Purpose |
|-------|---------|
| users | User accounts with auth credentials |
| profiles | User profile data and preferences |
| photos | Profile photos with moderation status |
| matching_preferences | User discovery filters |
| compatibility_scores | Cached compatibility calculations |
| likes | Swipe actions (like/pass) |
| matches | Mutual match records |
| conversations | Chat channels |
| messages | Chat messages |
| ai_usage | AI suggestion usage tracking |
| healing_check_ins | Healing check-in records |
| subscriptions | User subscription tiers |
| reports | User-submitted reports |
| moderation_logs | Admin action audit trail |
| affiliate_courses | Third-party course catalog |

### 5.3 API Design

#### 5.3.1 API Endpoints Overview

| Category | Endpoints |
|----------|-----------|
| Auth | POST /auth/register, POST /auth/login, POST /auth/verify |
| Profile | GET/PUT /profile, POST /profile/photo, DELETE /profile |
| Discovery | GET /discover, POST /discover/filters |
| Swipe | POST /swipe/like, POST /swipe/pass, POST /swipe/report |
| Match | GET /matches, POST /match/confirm, DELETE /match |
| Conversation | GET /conversations, POST /conversations |
| Chat | GET /messages, POST /messages, PUT /messages/{id}/read |
| AI | POST /ai/suggest, GET /ai/usage |
| Healing | POST /healing/checkin, GET /healing/content |
| Subscription | GET /subscription, POST /subscription/upgrade |

See: `api/auth.yaml`, `api/profile.yaml`, `api/discovery.yaml`, etc.

### 5.4 Security Design

| Mechanism | Implementation |
|-----------|----------------|
| Authentication | JWT tokens with 15-minute expiry |
| Authorization | Role-based (User, Admin) with resource-level checks |
| Input Validation | All inputs sanitized and validated |
| Rate Limiting | 100 req/min per user, 1000 req/min per IP |
| Data Protection | PII encryption at rest, TLS in transit |

---

## 6. Detailed Design

### 6.1 Use Case Diagrams

Each use case has a dedicated folder under `diagrams/` containing:
- use_case.puml
- sequence.puml
- activity.puml
- class.puml
- state.puml

#### UC01: Authentication
**Folder:** `diagrams/UC01-Auth/`
**Actors:** Customer, Admin
**Description:** User registration, login, and email verification flows

#### UC02: Profile Management
**Folder:** `diagrams/UC02-Profile/`
**Actors:** Customer, Admin, AI Service
**Description:** Profile creation, updates, visibility control, and deletion

#### UC03: Discovery
**Folder:** `diagrams/UC03-Discover/`
**Actors:** Customer, AI Service
**Description:** Profile discovery with compatibility scoring and filtering

#### UC04: Swipe Actions
**Folder:** `diagrams/UC04-Swipe/`
**Actors:** Customer
**Description:** Like, Pass, and Report actions on discovered profiles

#### UC05: Match Lifecycle
**Folder:** `diagrams/UC05-Match/`
**Actors:** Customer
**Description:** Mutual match creation, confirmation, expiration, and unmatching

#### UC06: Conversation
**Folder:** `diagrams/UC06-Conversation/`
**Actors:** Customer
**Description:** Conversation creation after match confirmation

#### UC07: Chat
**Folder:** `diagrams/UC07-Chat/`
**Actors:** Customer, AI Service
**Description:** Real-time messaging with status indicators

#### UC08: AI Suggestions
**Folder:** `diagrams/UC08-AI-Suggestion/`
**Actors:** Customer, AI Service
**Description:** AI-powered chat suggestions with usage limits

#### UC09: Healing
**Folder:** `diagrams/UC09-Healing/`
**Actors:** Customer, Affiliate Provider
**Description:** Healing check-ins and affiliate course recommendations

#### UC10: Subscription
**Folder:** `diagrams/UC10-Subscription/`
**Actors:** Customer, Payment Service
**Description:** Subscription tiers, paywalls, and upgrade flows

#### UC11: Admin
**Folder:** `diagrams/UC11-Admin/`
**Actors:** Admin
**Description:** User management, moderation, and reporting tools

### 6.2 Class Diagrams

Key classes in the system:

| Class | Package | Responsibility |
|-------|---------|----------------|
| User | auth | User account and credentials |
| Profile | profile | User profile data |
| Photo | profile | Profile photo management |
| MatchingPreference | discovery | Discovery filter settings |
| CompatibilityScore | discovery | Compatibility calculation |
| Like | swipe | Like/Pass action record |
| Match | match | Mutual match record |
| Conversation | chat | Chat channel |
| Message | chat | Chat message |
| AIUsage | ai | AI usage tracking |
| HealingCheckIn | healing | Healing check-in record |
| Subscription | subscription | Subscription tier status |
| Report | moderation | User report record |
| ModerationLog | moderation | Admin action audit |

### 6.3 Sequence Diagrams

Key interaction flows:

1. **Registration Flow:** User -> API Gateway -> Auth Service -> User Repository
2. **Discovery Flow:** User -> Discovery Service -> Compatibility Engine -> Profile Repository
3. **Match Flow:** Like Service -> Match Service -> Notification Service
4. **Chat Flow:** User -> Chat Service -> Message Repository -> WebSocket Server
5. **AI Suggestion Flow:** User -> AI Service -> Usage Tracker -> Chat Service

### 6.4 State Diagrams

Key state machines:

1. **User Account State:** Unverified -> Verified -> Suspended -> Deleted
2. **Match State:** Pending -> Both Confirmed -> Active -> Expired -> Unmatched
3. **Conversation State:** Created -> Active -> Archived -> Deleted
4. **Message State:** Sent -> Delivered -> Seen -> Deleted
5. **Subscription State:** Free -> Plus -> Premium -> Elite
6. **Moderation State:** Pending -> Approved -> Warning -> Rejected

### 6.5 Database Schema Details

See `db/schema.sql` for complete DDL including:
- Table definitions with constraints
- Indexes for performance
- Foreign key relationships
- Trigger definitions for audit logging

### 6.6 API Specifications

See `api/` folder for OpenAPI 3.0 YAML files:
- `auth.yaml` - Authentication endpoints
- `profile.yaml` - Profile management endpoints
- `discovery.yaml` - Discovery and filtering endpoints
- `swipe.yaml` - Swipe action endpoints
- `match.yaml` - Match management endpoints
- `conversation.yaml` - Conversation endpoints
- `chat.yaml` - Messaging endpoints
- `ai.yaml` - AI suggestion endpoints
- `healing.yaml` - Healing check-in endpoints
- `subscription.yaml` - Subscription management
- `admin.yaml` - Admin functionality

---

## 7. Appendices

### Appendix A: Glossary

| Term | Definition |
|------|------------|
| Compatibility Score | Percentage indicating match quality based on shared interests, location, goals |
| Mutual Match | Both users have liked each other |
| Paywall | UI element restricting access based on subscription tier |
| Affiliate Course | Third-party healing course linked via affiliate program |
| Auto-detect | AI-based moderation flagging system |

### Appendix B: TBD Items Tracking

| ID | Item | Status | Dependencies |
|----|------|--------|--------------|
| OD-001 | Paid tier exact rights | TBD | Requires business decision |
| OD-002 | Paid tier pricing | TBD | Requires business decision |
| OD-003 | Billing cycle policy | TBD | Requires business decision |
| OD-004 | Compatibility score weights | TBD | Requires data analysis |
| OD-005 | Legal retention review | TBD | Requires legal review |

### Appendix C: Diagrams Index

| Diagram | Location | Type |
|---------|----------|------|
| Architecture Overview | `diagrams/architecture.puml` | Component Diagram |
| Deployment | `diagrams/deployment.puml` | Deployment Diagram |
| Data Model | `diagrams/data_model.puml` | ERD |
| UC01 Auth | `diagrams/UC01-Auth/*.puml` | Multiple |
| UC02 Profile | `diagrams/UC02-Profile/*.puml` | Multiple |
| UC03 Discover | `diagrams/UC03-Discover/*.puml` | Multiple |
| UC04 Swipe | `diagrams/UC04-Swipe/*.puml` | Multiple |
| UC05 Match | `diagrams/UC05-Match/*.puml` | Multiple |
| UC06 Conversation | `diagrams/UC06-Conversation/*.puml` | Multiple |
| UC07 Chat | `diagrams/UC07-Chat/*.puml` | Multiple |
| UC08 AI Suggestion | `diagrams/UC08-AI-Suggestion/*.puml` | Multiple |
| UC09 Healing | `diagrams/UC09-Healing/*.puml` | Multiple |
| UC10 Subscription | `diagrams/UC10-Subscription/*.puml` | Multiple |
| UC11 Admin | `diagrams/UC11-Admin/*.puml` | Multiple |

### Appendix D: API Endpoints Summary

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /api/v1/auth/register | Register new user |
| POST | /api/v1/auth/login | User login |
| POST | /api/v1/auth/verify | Verify email |
| GET | /api/v1/profile | Get current user profile |
| PUT | /api/v1/profile | Update profile |
| DELETE | /api/v1/profile | Delete account |
| GET | /api/v1/discover | Get discover list |
| POST | /api/v1/discover/filters | Update discovery filters |
| POST | /api/v1/swipe/like | Like a profile |
| POST | /api/v1/swipe/pass | Pass a profile |
| POST | /api/v1/swipe/report | Report a profile |
| GET | /api/v1/matches | Get user matches |
| POST | /api/v1/matches/{id}/confirm | Confirm match |
| DELETE | /api/v1/matches/{id} | Unmatch |
| GET | /api/v1/conversations | List conversations |
| POST | /api/v1/conversations | Create conversation |
| GET | /api/v1/messages | Get messages |
| POST | /api/v1/messages | Send message |
| PUT | /api/v1/messages/{id}/read | Mark as read |
| POST | /api/v1/ai/suggest | Get AI suggestion |
| GET | /api/v1/ai/usage | Get AI usage stats |
| POST | /api/v1/healing/checkin | Submit check-in |
| GET | /api/v1/healing/content | Get healing content |
| GET | /api/v1/subscription | Get subscription |
| POST | /api/v1/subscription/upgrade | Upgrade subscription |

---

**Document Control:**
- Version: 1.0.0
- Created: 2026-05-16
- Status: Draft for Review
# Software Requirements Specification: Dating Matching & Healing App

## 1. Product Overview

### 1.1 Purpose

This document defines MVP requirements for a dating/matching application for single customers who want to discover compatible people, create mutual matches, start conversations, and use basic healing support before or during relationship exploration.

### 1.2 Business Problem

Users need a safer and more meaningful way to find potential romantic connections. Matching should not rely only on appearance. The system should use personal data, interests, location, relationship goals, personality/value inputs, and healing readiness to suggest compatible people.

### 1.3 Product Goal

The system helps users:

- Discover compatible people.
- Like or pass suggested profiles.
- Create matches only when both sides like each other.
- Confirm conversation before chat starts.
- Chat in real time after conversation is confirmed.
- Receive AI suggested chat messages.
- Complete healing check-ins and access basic healing content.
- Access paid features through subscription paywalls.

### 1.4 MVP Scope

MVP includes:

- Email/password registration and login.
- Email verification.
- Profile creation.
- Discover list with required filters.
- Swipe actions: like, pass/dislike, report from profile card.
- Mutual-like match creation.
- Match confirmation flow before conversation creation.
- Realtime chat with text, emoji, image, voice, and AI suggested text.
- Chat states: seen, typing, online status, delivery status.
- AI chat suggestion with free daily limit.
- Healing check-in flow.
- Affiliate course suggestions.
- Free tier plus three paid tiers: Plus, Premium, Elite.
- Paywall for selected actions.
- Admin tools for user management, profile review, reports, moderation logs, subscription view, and affiliate courses.
- Auto-detect moderation with pending review and user warning.

### 1.5 Out Of Scope For MVP

- In-app checkout for third-party courses.
- Auto-ban moderation action unless later approved.
- Auto-reject moderation action unless later approved.
- Final paid tier pricing and exact paid tier limits.
- Legal/compliance final retention review.
- Full compatibility score weight tuning.

### 1.6 Open Decisions

| ID | Decision | Status |
|---|---|---|
| OD-001 | Exact rights and numbers for Plus, Premium, Elite | TBD custom |
| OD-002 | Pricing for Plus, Premium, Elite | TBD |
| OD-003 | Billing cycle, cancel, refund policy | TBD |
| OD-004 | Compatibility score weights | TBD |
| OD-005 | Legal review for retention policy | TBD |

## 2. Actors And External Systems

| Actor/System | Description | Main Goal |
|---|---|---|
| Customer | Single user looking for relationship discovery and healing support. | Discover, match, chat, heal, manage profile/subscription. |
| Admin | Internal operator. | Manage users, review profiles/reports, monitor subscriptions and affiliate courses. |
| AI Service | External/internal AI capability. | Generate chat suggestions and support moderation/check-in logic. |
| Payment Service | Subscription/payment provider or mock premium state provider. | Manage paid tier status. |
| Affiliate Provider | Third-party course/content provider. | Receive referred users through affiliate links. |

## 3. Product Context

### 3.1 High-Level Flow

```text
Register/Login -> Verify Email -> Create Profile -> Complete Matching Inputs -> Discover -> Like/Pass -> Mutual Match -> Both Confirm Conversation -> Chat -> AI Suggestions / Healing Support / Affiliate Course Suggestions
```

### 3.2 Core Business Flow

1. User creates an account with email/password.
2. User verifies email.
3. User completes required profile fields.
4. System reviews profile through auto-detect moderation.
5. User enters discover.
6. System shows compatible profiles based on required filters and compatibility score.
7. User likes or passes profiles.
8. If two users like each other, system creates a match.
9. Both users must confirm conversation within 24 hours.
10. If both confirm, system creates conversation.
11. Users chat in real time.
12. AI may suggest chat messages within usage limit.
13. User may use healing check-in and receive basic content or affiliate course suggestions.

## 4. Functional Requirements

### 4.1 Authentication

#### FR-AUTH-001: Register With Email And Password

The system shall allow customers to register using email and password.

Acceptance criteria:

- User can submit email and password.
- System validates email format.
- System validates password against configured password rules. Password rules are TBD.
- System blocks duplicate email registration.
- System sends email verification after successful registration.

#### FR-AUTH-002: Email Verification

The system shall verify customer email before full app access.

Acceptance criteria:

- User receives verification email.
- User can verify email through verification link or code.
- User with unverified email cannot complete protected actions. Protected action list is TBD.
- System shows validation message if email is unverified.

#### FR-AUTH-003: Login

The system shall allow registered customers to log in with email/password.

Acceptance criteria:

- User can log in with valid credentials.
- System rejects invalid credentials.
- System does not expose whether email or password specifically failed, unless product decides otherwise.

### 4.2 Profile Management

#### FR-PROFILE-001: Create Required Profile

The system shall require user profile data before discover.

Required fields:

- Display name.
- Age/date of birth.
- Gender/orientation.
- Profile photo.
- Location.
- Bio.
- Interests.
- Relationship goal.

Acceptance criteria:

- User cannot enter discover until required profile fields are complete.
- System validates age/date of birth.
- System rejects underage users based on configured minimum age. Minimum age is TBD.
- System requires at least one valid profile photo.
- System does not show exact location to other users.

#### FR-PROFILE-002: Hide Profile

The system shall allow users to hide profile from discover.

Acceptance criteria:

- User can toggle profile visibility.
- Hidden profile does not appear in other users' discover results.
- User can still access account settings and existing allowed conversations unless blocked by other rules.

#### FR-PROFILE-003: Delete Account

The system shall allow users to delete their account.

Acceptance criteria:

- User can request account deletion.
- System deletes or anonymizes PII.
- System preserves report evidence if required by moderation retention rules.
- Deleted user no longer appears in discover.

### 4.3 Discover And Matching

#### FR-DISCOVER-001: Discover Compatible Profiles

The system shall show compatible profiles in discover.

Required discover filters:

- Age range.
- Location/distance.
- Gender/orientation preference.
- Relationship goal.
- Shared interests.
- Compatibility score threshold.

Acceptance criteria:

- Discover excludes blocked users.
- Discover excludes hidden profiles.
- Discover excludes profiles that fail moderation visibility rules.
- Discover does not expose exact location.
- Discover loads within target NFR response time.

#### FR-DISCOVER-002: Compatibility Score

The system shall calculate a compatibility score.

Score factors:

- Shared interests.
- Distance/location.
- Relationship goal alignment.
- Personality/value answers.
- Healing readiness.
- Deal-breakers.

Acceptance criteria:

- System can rank discover profiles by score.
- System can filter profiles below minimum threshold.
- Deal-breakers can exclude profiles even if score is otherwise high.
- Exact factor weights are TBD.

#### FR-SWIPE-001: Like Profile

The system shall allow user to like a profile from discover.

Business rules:

- Free user can send 20 likes per day.
- Paid tier like limits are TBD custom.
- Empty/invalid target profile cannot be liked.
- Duplicate like should not create duplicate match.

Acceptance criteria:

- User can like eligible profile.
- System decrements or tracks daily like usage for free tier.
- System shows paywall when free user exceeds 20 likes/day.
- System prevents duplicate match creation.

#### FR-SWIPE-002: Pass/Dislike Profile

The system shall allow user to pass/dislike a profile.

Acceptance criteria:

- User can pass profile from discover.
- Passed profile is removed from current discover queue according to configured redisplay policy. Redisplay policy is TBD.

#### FR-SWIPE-003: Report From Profile Card

The system shall allow user to report a profile from discover card.

Acceptance criteria:

- User can choose report reason.
- Report enters admin report queue.
- System preserves report evidence according to retention policy.

### 4.4 Match Lifecycle

#### FR-MATCH-001: Create Match On Mutual Like

The system shall create a match only when two users like each other.

Acceptance criteria:

- If A likes B and B already liked A, system creates one match.
- If B later likes A, system creates one match.
- System prevents duplicate matches between same pair.
- System records match creation timestamp.

#### FR-MATCH-002: Confirm Conversation

The system shall require both users to confirm conversation after match.

Business rules:

- Both users must confirm conversation.
- Conversation is created only after both confirmations.
- Match expires after 24 hours if both users do not confirm.

Acceptance criteria:

- System tracks confirmation status per user.
- System creates conversation only after both confirmations.
- System expires unconfirmed match after 24 hours.
- Expired match cannot create conversation unless rematch policy allows it. Rematch policy is TBD.

#### FR-MATCH-003: Unmatch

The system shall allow user to unmatch.

Acceptance criteria:

- User can unmatch from match/conversation context.
- Unmatch closes or hides conversation according to retention/report rules.
- Unmatched users no longer see active match state.

#### FR-MATCH-004: Block Cancels Match

The system shall cancel or close match/conversation when a user blocks another user.

Acceptance criteria:

- Blocking prevents future discover visibility between both users.
- Blocking closes active match/conversation.
- Blocked user cannot send messages to blocker.

#### FR-MATCH-005: Report Preserves Evidence

The system shall preserve evidence when a match or conversation is reported.

Acceptance criteria:

- Report captures relevant profile/chat context.
- Evidence remains available to admin for 24 months.
- Evidence may be retained even if user deletes account, limited to necessary data.

### 4.5 Realtime Chat

#### FR-CHAT-001: Create Conversation After Confirmation

The system shall create conversation only after both matched users confirm.

Acceptance criteria:

- Conversation is linked to match.
- Only conversation members can access conversation.
- User outside conversation cannot view chat.

#### FR-CHAT-002: Send Messages

The system shall support chat messages.

Message types:

- Text.
- Emoji.
- Image.
- Voice.
- AI suggested text.

Acceptance criteria:

- User can send supported message types.
- System rejects empty messages.
- System rejects messages from user not in conversation.
- System handles missing data without app crash.

#### FR-CHAT-003: Realtime Chat States

The system shall support realtime chat states.

States:

- Seen.
- Typing.
- Online status.
- Delivery status.

Acceptance criteria:

- User sees delivery status after sending supported message.
- User sees typing state when other user is typing.
- User sees seen status when message is read.
- User sees online/offline or recent activity state according to privacy policy. Exact display rule is TBD.

#### FR-CHAT-004: Chat Retention

The system shall retain normal chat data for 12 months.

Acceptance criteria:

- Normal chat is retained for 12 months.
- Report-related evidence may be retained for 24 months.
- Deletion/anonymization respects PII deletion rule and report evidence exception.

### 4.6 AI Chat Suggestions

#### FR-AI-001: Suggest Chat Message

The system shall allow AI to suggest chat messages.

AI input sources:

- Profiles of both users.
- Shared interests.
- Current chat history.
- Healing check-in data.

Acceptance criteria:

- User can request AI suggestion in conversation.
- System returns suggested text.
- User chooses whether to send suggested text.
- System does not automatically send AI suggestion without user action.

#### FR-AI-002: AI Usage Limit

The system shall limit free AI suggestion usage.

Business rules:

- Free user can use 10 AI suggestions per day.
- Paid tier AI limits are TBD custom.
- System should include technical rate limits to prevent abuse/cost spike. Exact rate limits are TBD.

Acceptance criteria:

- System tracks AI usage per user per day.
- System blocks free user after 10 AI suggestions/day.
- System shows paywall when AI limit is exceeded.
- System prevents AI calls beyond allowed quota.

### 4.7 Healing Check-In And Content

#### FR-HEAL-001: Healing Check-In

The system shall provide basic healing check-in.

Check-in fields:

- Mood today.
- Dating readiness.
- Emotional needs.
- Trigger/discomfort.
- Small goal.

Acceptance criteria:

- User can complete check-in.
- System stores check-in for later use in personalization.
- System may use check-in data for AI suggestions and healing content.
- System handles missing check-in data without app crash.

#### FR-HEAL-002: Healing Content

The system shall show basic healing content.

Acceptance criteria:

- User can access healing tab.
- System shows content based on check-in where possible.
- Paid tiers may unlock expanded healing content. Exact tier rights are TBD custom.

#### FR-HEAL-003: Affiliate Course Suggestions

The system shall suggest third-party healing courses through affiliate links.

Placement:

- After healing check-in.
- In Healing tab.
- During paywall upsell.

Rules:

- Affiliate links must not be inserted directly into conversation.
- Affiliate link must include disclaimer that course is from third party/affiliate.
- In-app checkout is out of scope for MVP.

Acceptance criteria:

- User can open affiliate course link.
- System can track referral/commission where integration supports it.
- System shows affiliate disclaimer.

### 4.8 Subscription And Paywall

#### FR-SUB-001: Subscription Tiers

The system shall support Free plus three paid tiers.

Tiers:

- Free.
- Plus.
- Premium.
- Elite.

Known tier differences:

- Like limit.
- AI limit.
- Advanced filters.
- Healing content.

Open items:

- Exact rights and numbers are TBD custom.
- Prices are TBD.
- Billing cycle/cancel/refund policy is TBD.

#### FR-SUB-002: Paywall

The system shall show paywall when user attempts restricted actions.

Paywall triggers:

- Free user exceeds 20 likes/day.
- User attempts to use advanced filters without eligible tier.
- User exceeds AI suggestion limit.

Acceptance criteria:

- Paywall appears at restricted action.
- Paywall explains blocked feature.
- Paywall shows available upgrade path.
- Mock premium state works for MVP testing.

### 4.9 Moderation And Admin

#### FR-MOD-001: Auto-Detect Profile Violations

The system shall auto-detect profile violations.

Violation categories:

- Sensitive images.
- Spam/scam.
- Contact information.
- Toxic language.
- Fake profile.
- Underage indicators.

Actions:

- Pending review.
- Warning user.

Acceptance criteria:

- Suspected violation enters profile review queue.
- User can receive warning for profile issue.
- Auto-detect does not auto-ban in MVP unless future decision approves it.
- Auto-detect does not auto-reject in MVP unless future decision approves it.

#### FR-ADMIN-001: Admin Screens

The system shall provide admin screens.

Required admin screens:

- User management.
- Profile review.
- Report queue.
- Moderation logs.
- Subscription view.
- Affiliate courses.

Acceptance criteria:

- Admin can view and manage users.
- Admin can review profiles flagged by auto-detect.
- Admin can process reports.
- Admin can view moderation logs.
- Admin can view subscription/free/paid/mock premium state.
- Admin can manage affiliate course links.

#### FR-ADMIN-002: Audit Moderation Actions

The system shall audit moderation/admin actions.

Acceptance criteria:

- System records who took action.
- System records action type.
- System records target user/profile/report.
- System records timestamp.

## 5. Business Rules

| ID | Rule |
|---|---|
| BR-LIKE-001 | Free user gets 20 likes per day. |
| BR-LIKE-002 | Paid tier like limits are TBD custom. |
| BR-MATCH-001 | Match is created only on mutual like. |
| BR-MATCH-002 | System must prevent duplicate match between same user pair. |
| BR-CONV-001 | Both matched users must confirm before conversation is created. |
| BR-CONV-002 | Match expires after 24 hours if conversation is not confirmed by both users. |
| BR-CHAT-001 | User not in conversation must not view or send messages in that conversation. |
| BR-CHAT-002 | Empty message must be rejected. |
| BR-AI-001 | Free user gets 10 AI suggestions per day. |
| BR-AI-002 | AI calls beyond quota must be blocked and paywall shown. |
| BR-PAY-001 | Paywall appears for like limit, advanced filters, and AI over-limit. |
| BR-MOD-001 | Auto-detect sends suspected profile violations to pending review. |
| BR-MOD-002 | Auto-detect can warn user for profile issue. |
| BR-RET-001 | Normal chat retained for 12 months. |
| BR-RET-002 | Report evidence retained for 24 months. |
| BR-PRIV-001 | Exact location is never shown to other users. |
| BR-COURSE-001 | Third-party courses are sold through affiliate links, not in-app checkout. |
| BR-COURSE-002 | Affiliate links must not be inserted into chat conversations. |

## 6. Screens

### 6.1 Customer Screens

| Screen | Purpose | Key Elements |
|---|---|---|
| Register | Create account. | Email, password, submit, validation messages. |
| Login | Access existing account. | Email, password, submit, forgot password TBD. |
| Email Verification | Verify email. | Verification status, resend email. |
| Profile Setup | Complete required profile. | Display name, DOB, gender/orientation, photos, location, bio, interests, relationship goal. |
| Discover | View compatible profiles. | Profile card, compatibility info, like, pass, report. |
| Match Confirmation | Confirm conversation after mutual match. | Match info, confirm, decline/ignore, expiry timer. |
| Chat List | View conversations. | Conversation previews, unread status. |
| Chat Detail | Realtime chat. | Messages, input, image/voice upload, AI suggestion, seen/typing/online/delivery. |
| Healing Check-In | Capture current emotional state. | Mood, readiness, needs, trigger, small goal. |
| Healing Tab | Show healing content and affiliate courses. | Content list, course cards, affiliate disclaimer. |
| Subscription/Paywall | Upgrade plan. | Feature blocked reason, Plus/Premium/Elite options, mock premium state. |
| Settings | Account/privacy controls. | Hide profile, delete account, subscription status. |

### 6.2 Admin Screens

| Screen | Purpose | Key Elements |
|---|---|---|
| User Management | Manage users. | Search, user detail, status, profile, actions. |
| Profile Review | Review flagged profiles. | Auto-detect reason, profile data, approve/warn/action. |
| Report Queue | Process reports. | Reporter, reported user, reason, evidence, action. |
| Moderation Logs | Audit moderation. | Actor, action, target, timestamp. |
| Subscription View | View plan state. | Free/Plus/Premium/Elite/mock premium state. |
| Affiliate Courses | Manage affiliate links. | Course title, category, URL, active status, disclaimer. |

## 7. Data Requirements

### 7.1 Core Entities

| Entity | Required Fields / Notes |
|---|---|
| User | ID, email, password hash, email verified status, account status, created timestamp. |
| Profile | User ID, display name, DOB/age, gender/orientation, location, bio, interests, relationship goal, visibility status. |
| Photo | ID, user/profile ID, URL/storage reference, moderation status. |
| MatchingPreference | User ID, age range, location/distance preference, gender/orientation preference, relationship goal preference, deal-breakers. |
| CompatibilityScore | User A, User B, score, factors, calculated timestamp. |
| Like | Source user, target user, timestamp, status. |
| Match | User A, User B, match timestamp, confirmation statuses, expiry timestamp, status. |
| Conversation | Match ID, member IDs, status, created timestamp. |
| Message | Conversation ID, sender ID, type, content/reference, delivery status, read status, timestamp. |
| AIUsage | User ID, usage date, count, tier, limit. |
| HealingCheckIn | User ID, mood, readiness, emotional needs, trigger, small goal, timestamp. |
| Subscription | User ID, tier, status, start/end timestamps, mock premium flag. |
| Report | Reporter ID, target user/profile/conversation/message, reason, evidence references, status, created timestamp. |
| ModerationLog | Admin/system actor, action, target, reason, timestamp. |
| AffiliateCourse | Title, category, affiliate URL, active status, disclaimer text. |

### 7.2 Data Privacy Rules

- Exact location must not be shown to other users.
- Delete account must delete/anonymize PII.
- Report evidence may be retained for 24 months even after account deletion if necessary.
- Normal chat retained for 12 months.
- Retention policy requires legal/compliance review before production launch.

## 8. Messages

### 8.1 Auth Validation

| Case | Message |
|---|---|
| Invalid email | `Please enter a valid email address.` |
| Missing password | `Password is required.` |
| Duplicate email | `An account with this email already exists.` |
| Email not verified | `Please verify your email before continuing.` |
| Invalid login | `Email or password is incorrect.` |

### 8.2 Profile Validation

| Case | Message |
|---|---|
| Missing required profile field | `Please complete all required profile information.` |
| Missing photo | `Please add at least one profile photo.` |
| Underage detected | `You do not meet the minimum age requirement.` |
| Bio violation | `Your profile contains content that needs review.` |
| Exact location hidden | `Your exact location will not be shown to other users.` |

### 8.3 Like/Match Errors

| Case | Message |
|---|---|
| Free like limit reached | `You have used all 20 free likes today. Upgrade to keep liking.` |
| Duplicate match prevented | `You are already matched with this user.` |
| Match expired | `This match has expired because both users did not confirm in time.` |
| Match created | `It's a match! Confirm if you want to start a conversation.` |

### 8.4 Chat Errors

| Case | Message |
|---|---|
| Empty message | `Message cannot be empty.` |
| Not conversation member | `You do not have access to this conversation.` |
| Send failure | `Message could not be sent. Please try again.` |
| Missing data fallback | `Something is missing. Please refresh and try again.` |

### 8.5 AI Limit Errors

| Case | Message |
|---|---|
| Free AI limit reached | `You have used all 10 free AI suggestions today. Upgrade for more.` |
| AI service failure | `AI suggestion is unavailable right now. Please try again later.` |
| AI rate limit | `Please wait before requesting another AI suggestion.` |

### 8.6 Paywall Messages

| Case | Message |
|---|---|
| Like paywall | `Upgrade to get more likes today.` |
| Advanced filter paywall | `Upgrade to unlock advanced filters.` |
| AI paywall | `Upgrade to get more AI suggestions.` |
| Healing content paywall | `Upgrade to unlock deeper healing content.` |

## 9. Non-Functional Requirements

| ID | Requirement |
|---|---|
| NFR-PERF-001 | Discover list should load in <= 2 seconds under normal conditions. |
| NFR-PERF-002 | Realtime chat message should reach online recipient in <= 1 second under normal conditions. |
| NFR-AVAIL-001 | MVP uptime target is 99.5%. |
| NFR-UX-001 | Product should be mobile-first. |
| NFR-AUDIT-001 | Moderation/admin actions must be audited. |
| NFR-SEC-001 | User outside conversation must not access chat. |
| NFR-SEC-002 | System must prevent duplicate matches. |
| NFR-SEC-003 | System must prevent empty message submission. |
| NFR-SEC-004 | System must enforce AI usage limit. |
| NFR-SEC-005 | System must enforce paywall rules. |
| NFR-REL-001 | App must not crash when optional/missing data is unavailable. |

## 10. Blocker Defects That Must Not Exist

The MVP must not ship with these blocker defects:

- Duplicate match between same two users.
- Empty message can be sent.
- User not in conversation can view chat.
- AI can be called beyond allowed limit.
- Paywall does not work for restricted features.
- App crashes when data is missing.

## 11. Traceability Matrix

| Use Case | Features | Screens | Data | Rules |
|---|---|---|---|---|
| Register/Login | Auth, email verification | Register, Login, Email Verification | User | FR-AUTH-001..003 |
| Complete Profile | Profile setup, moderation | Profile Setup | Profile, Photo | FR-PROFILE-001, FR-MOD-001 |
| Discover People | Discover, compatibility score | Discover | Profile, MatchingPreference, CompatibilityScore | FR-DISCOVER-001..002 |
| Like/Pass | Swipe | Discover | Like | FR-SWIPE-001..003, BR-LIKE-001 |
| Create Match | Mutual like | Discover, Match Confirmation | Match | FR-MATCH-001, BR-MATCH-001 |
| Confirm Conversation | Both users confirm | Match Confirmation | Match, Conversation | FR-MATCH-002, BR-CONV-001 |
| Chat Realtime | Messages, states | Chat List, Chat Detail | Conversation, Message | FR-CHAT-001..004 |
| AI Suggestion | AI suggested text | Chat Detail | AIUsage, Message | FR-AI-001..002 |
| Healing Check-In | Check-in, content | Healing Check-In, Healing Tab | HealingCheckIn, AffiliateCourse | FR-HEAL-001..003 |
| Subscription Paywall | Free/paid tiers, paywall | Subscription/Paywall | Subscription, AIUsage, Like | FR-SUB-001..002 |
| Moderate Profile/Report | Auto-detect, admin tools | Admin screens | Report, ModerationLog | FR-MOD-001, FR-ADMIN-001..002 |

## 12. Acceptance Summary

MVP is acceptable when:

- User can register, verify email, complete profile, and enter discover.
- Discover uses required filters and compatibility factors.
- Free user is limited to 20 likes/day.
- Mutual like creates only one match.
- Conversation requires confirmation from both users within 24 hours.
- Chat supports required message types and states.
- Chat access is restricted to conversation members only.
- AI suggestions work and free user is limited to 10/day.
- Healing check-in and affiliate course suggestions are available in allowed placements.
- Paywall appears for like limit, advanced filters, and AI over-limit.
- Auto-detect moderation sends suspected profiles to pending review and can warn users.
- Admin can access required admin screens.
- Retention rules are applied for chat and reports.
- Blocker defects listed in Section 10 are absent.

## 13. Appendix: TBD Items

| Area | TBD |
|---|---|
| Password policy | Minimum length, complexity, reset flow. |
| Protected actions before email verification | Exact list. |
| Minimum age | Legal/product decision. |
| Discover redisplay policy | Whether passed profiles return. |
| Rematch policy | Whether expired/unmatched users can match again. |
| Online status privacy | Exact display rule. |
| Paid tier rights | Exact limits and unlocked features for Plus/Premium/Elite. |
| Pricing | Price per tier. |
| Billing | Billing cycle, cancel, refund. |
| Compatibility score | Factor weights and threshold. |
| AI technical rate limits | Per minute/hour safeguards. |
| Legal retention review | Production policy validation. |

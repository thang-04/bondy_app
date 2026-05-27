# Phan Chia Cong Viec 3 Dev Tap Trung Dev 2 / Dev 3

## Muc Tieu

File nay chia cong viec cho 3 dev cung lam cac mien dang nam trong Dev 2 va Dev 3: Swipe, Match, Conversation, Chat, AI, Subscription, Paywall, Healing, Affiliate, Moderation, Admin. Muc tieu la lam dung luong SRS/SDD va tranh conflict giua cac dev.

## Nguyen Tac Khong Conflict

| Nguyen tac | Ap dung |
|---|---|
| Mot owner cho moi contract | Moi API payload/schema/service core chi co 1 dev owner. Dev khac chi consume. |
| Khong tao conversation truc tiep | Conversation chi duoc tao sau khi match da du 2 confirmation. |
| Paywall payload chi co 1 shape | Dev phu trach Paywall dinh nghia payload, tat ca luong like/AI/filter/healing dung lai. |
| Report model chi co 1 owner | Swipe tao report theo interface, Admin xu ly report. Khong tao 2 bang/report model khac nhau. |
| Block table chi co 1 owner | Block action owner tao model/API; Discover/Chat chi consume de exclude/deny. |
| Admin chi consume domain data | Admin khong lap lai business logic cua Match/Chat/AI/Healing, chi doc/xu ly theo API/service owner. |

## Tong Phan Cong Moi

| Dev | Ten pham vi | Owner chinh | Man hinh chinh | API/module chinh |
|---|---|---|---|---|
| Dev A | Match + Conversation + Chat | Swipe, Match lifecycle, Conversation, Chat access, Block | Discover actions, Match Confirmation, Chat List, Chat Detail | `/api/v1/swipe/*`, `/api/v1/matches/*`, `/api/v1/blocks`, `/api/v1/conversations`, `/api/v1/messages` |
| Dev B | AI + Subscription + Paywall | AI suggestion, AI usage, Subscription tiers, Paywall payload/quota | AI Suggestion sheet, Subscription/Paywall | `/api/v1/ai/*`, `/api/v1/subscription/*`, paywall/quota service |
| Dev C | Healing + Moderation + Admin | Healing check-in/content, Affiliate, Report admin, Moderation, Admin screens | Healing Check-In, Healing Tab, Admin screens | `/api/v1/healing/*`, `/api/v1/affiliate-courses`, `/api/v1/admin/*`, moderation/audit service |

## Dev A: Match / Conversation / Chat

| SRS/SDD | Viec can lam | Man hinh | API/module | Giao dien voi Dev khac |
|---|---|---|---|---|
| FR-SWIPE-001 | Like profile | Discover | `POST /api/v1/swipe/like` | Goi Dev B quota service truoc khi ghi like. |
| FR-SWIPE-002 | Pass profile | Discover | `POST /api/v1/swipe/pass` | Discover queue se exclude passed profiles. |
| FR-SWIPE-003 | Report profile | Discover | `POST /api/v1/swipe/report` | Tao report theo model/interface cua Dev C. |
| FR-MATCH-001 | Tao pending match khi mutual like | Discover, Match Confirmation | Match service | Khong tao conversation tai day. |
| FR-MATCH-002, FR-CHAT-001 | Confirm conversation | Match Confirmation | `POST /api/v1/matches/{id}/confirm` | Chi tao conversation khi ca 2 user da confirm. |
| FR-MATCH-002 | Expire pending match sau 24h | Match Confirmation | Match expiry service/job | Expired match khong tao conversation. |
| FR-MATCH-003 | Unmatch | Match/Chat | `DELETE /api/v1/matches/{id}` | Neu co report/evidence thi dung retention rule cua Dev C. |
| FR-MATCH-004 | Block user | Profile/Chat/Settings | `/api/v1/blocks` | Dev C admin co the xem block context neu report. Discover consume block table. |
| FR-CHAT-001 | Conversation list | Chat List | `GET /api/v1/conversations` | Chi tra conversation cua member. |
| FR-CHAT-002 | Send/list messages | Chat Detail | `GET/POST /api/v1/messages` | Message type `AI_SUGGESTED_TEXT` den tu Dev B suggestion selection. |
| FR-CHAT-002 | Image/voice message references | Chat Detail | Message storage/upload reference | Neu upload service co san, dung lai; khong tao upload contract moi neu chua thong nhat. |
| FR-CHAT-003 | Seen/typing/online/delivery | Chat Detail | `PUT /api/v1/messages/{id}/read`, typing/online/delivery endpoints/events | Dev B AI sheet chi hien state, khong sua state service. |
| FR-CHAT-004 | Chat retention 12 thang | Chat backend | Retention job/service | Report evidence 24 thang do Dev C xu ly. |

### Dev A Khong Duoc Lam

| Khong lam | Ly do |
|---|---|
| Khong define paywall payload rieng | Dev B owner paywall. |
| Khong tao `Report` schema rieng | Dev C owner report/admin/evidence. |
| Khong goi AI provider | Dev B owner AI. |
| Khong auto-ban/reject user | Dev C owner moderation/admin. |

## Dev B: AI / Subscription / Paywall

| SRS/SDD | Viec can lam | Man hinh | API/module | Giao dien voi Dev khac |
|---|---|---|---|---|
| FR-SUB-001 | Subscription tiers | Subscription/Paywall | `GET /api/v1/subscription`, `POST /api/v1/subscription/upgrade` | Dev A dung de check like limit; Dev C dung de check healing premium. |
| FR-SUB-002 | Mock premium state | Subscription/Paywall, Admin Subscription View | Subscription service/mock flag | Dev C admin screen consume de hien/toggle. |
| FR-SUB-002, BR-PAY-001 | Paywall payload chung | Paywall | Paywall/quota service | Dev A va Dev C phai dung chung shape nay. |
| BR-LIKE-001 | Like quota 20/day | Discover/Paywall | Quota service | Dev A goi truoc `swipe/like`. |
| FR-SUB-002 | Advanced filter entitlement | Discover Filters/Paywall | Entitlement service | Dev 1/Discover goi neu co advanced filters. |
| FR-AI-001 | AI suggestion endpoint | Chat Detail AI sheet | `POST /api/v1/ai/suggest` | Phai check conversation membership qua service cua Dev A. |
| FR-AI-001 | AI input context | Chat Detail AI sheet | Context builder | Lay profile/shared interests tu Dev 1, chat history tu Dev A, healing check-in tu Dev C. |
| FR-AI-001 | User chooses before send | Chat Detail AI sheet | Flutter AI widget/service | Khi user chon, tra text ve Chat input cua Dev A, khong auto-send. |
| FR-AI-002 | AI quota 10/day | AI sheet/Paywall | AIUsage table/service | Chan call truoc provider, vuot quota tra paywall payload chung. |
| FR-AI-002 | Technical rate limit | AI backend | Rate-limit guard | Chong abuse/cost spike. |
| FR-SUB-002 | Paywall UI | Subscription/Paywall | Flutter subscription service/screen | Co Free/Plus/Premium/Elite, blocked reason, upgrade path. |

### Paywall Payload Do Dev B Dinh Nghia

| Field | Y nghia |
|---|---|
| `code` | `PAYWALL_REQUIRED` hoac `LIMIT_REACHED`. |
| `blockedFeature` | `LIKE_LIMIT`, `ADVANCED_FILTER`, `AI_SUGGESTION`, `HEALING_CONTENT`. |
| `message` | Ly do bi chan de UI hien. |
| `upgradeOptions` | Plus/Premium/Elite options. |
| `currentTier` | Tier hien tai cua user. |
| `mockPremium` | Trang thai mock premium neu co. |

### Dev B Khong Duoc Lam

| Khong lam | Ly do |
|---|---|
| Khong tao conversation/chat message truc tiep | Dev A owner chat flow. |
| Khong tu bypass membership check | AI phai check conversation membership qua Dev A. |
| Khong implement admin report/moderation UI | Dev C owner admin. |
| Khong tao healing content schema rieng | Dev C owner healing. |

## Dev C: Healing / Affiliate / Moderation / Admin

| SRS/SDD | Viec can lam | Man hinh | API/module | Giao dien voi Dev khac |
|---|---|---|---|---|
| FR-HEAL-001 | Healing check-in | Healing Check-In | `POST /api/v1/healing/checkin` | Dev B AI context consume latest check-in. |
| FR-HEAL-002 | Healing content | Healing Tab | `GET /api/v1/healing/content` | Premium content check goi Dev B entitlement/paywall. |
| FR-HEAL-003 | Affiliate courses | Healing Tab, Paywall | `/api/v1/affiliate-courses` | Khong insert affiliate link vao chat cua Dev A. |
| FR-HEAL-003 | Affiliate placement | Healing Check-In, Healing Tab, Paywall | Healing response/UI | Sau check-in, trong Healing tab, trong paywall upsell. |
| FR-MOD-001 | Auto-detect moderation | Profile Setup/Profile Review | Moderation service | Dev A/B consume moderation/report status, khong tu detect rieng. |
| FR-MOD-001 | Profile review queue | Admin Profile Review | `/api/v1/admin/profile-reviews` | Profile/photo moderation status day vao queue. |
| FR-MOD-001 | User warning | Admin/Profile | Warning service/log | Warning user, khong auto-ban/auto-reject MVP. |
| FR-SWIPE-003, FR-MATCH-005 | Report evidence | Admin Report Queue | `Report` model/evidence service | Dev A tao report theo interface, Dev C xu ly evidence retention 24 thang. |
| FR-ADMIN-001 | User management | Admin User Management | `/api/v1/admin/users` | Read/manage user status. |
| FR-ADMIN-001 | Report queue | Admin Report Queue | `/api/v1/admin/reports` | Process reports tu Dev A. |
| FR-ADMIN-002 | Moderation logs | Admin Moderation Logs | `/api/v1/admin/moderation-logs` | Ghi actor, action type, target user/profile/report, timestamp. |
| FR-ADMIN-001 | Subscription view | Admin Subscription View | `/api/v1/admin/subscriptions` | Consume subscription/mock premium tu Dev B. |
| FR-ADMIN-001 | Affiliate admin | Admin Affiliate Courses | `/api/v1/admin/affiliate-courses` | CRUD affiliate links/disclaimers. |
| SRS 6.2 | Admin Flutter screens | Admin area | Flutter admin services/screens | User management, profile review, report queue, logs, subscription, affiliate courses. |

### Dev C Khong Duoc Lam

| Khong lam | Ly do |
|---|---|
| Khong tao match/conversation/chat logic | Dev A owner flow. |
| Khong define paywall payload rieng | Dev B owner payload/quota. |
| Khong goi AI provider | Dev B owner AI. |
| Khong sua discover scoring | Dev 1 owner discover; Dev C chi cung cap moderation/healing data. |

## Thu Tu Luong Thuc Thi Bat Buoc

| Luong | Thu tu chuan | Owner |
|---|---|---|
| Like -> Match -> Conversation | `swipe/like` -> check like quota Dev B -> create/update like -> if mutual like create pending match -> show Match Confirmation -> both confirm -> create conversation -> Chat List/Detail hien conversation | Dev A + Dev B |
| Report profile | Discover card -> `swipe/report` Dev A -> create Report/evidence theo interface Dev C -> Admin Report Queue Dev C process -> ModerationLog Dev C ghi action | Dev A + Dev C |
| Block user | User block -> Dev A close match/conversation + prevent send message -> Discover excludes block -> Admin/report context consume if needed | Dev A |
| AI suggestion | Chat Detail -> Dev B `ai/suggest` -> auth user from token -> membership check qua Dev A -> quota 10/day Dev B -> context profile/chat/healing -> provider call -> return suggestion -> user manually sends via Dev A chat input | Dev B + Dev A + Dev C |
| Healing premium | User mo premium healing content -> Dev C check content access -> Dev B entitlement/paywall -> allowed returns content, blocked returns paywall payload | Dev C + Dev B |
| Admin moderation | Profile/photo update -> Dev C auto-detect -> suspected enters review queue -> Admin reviews -> warning/approve/action -> ModerationLog written -> Discover consumes moderation status to exclude unsafe profile | Dev C + Dev 1 |

## Bang Giao Dien Giua Dev

| Interface | Owner | Consumer | Noi dung can thong nhat |
|---|---|---|---|
| Paywall/quota service | Dev B | Dev A, Dev C | Input userId + feature; output allowed or paywall payload chung. |
| Conversation membership service | Dev A | Dev B | Input userId + conversationId; output member/not member. |
| Report creation interface | Dev C | Dev A | Required fields: reporterId, target user/profile/conversation/message, reason, evidence refs, status. |
| Moderation status | Dev C | Dev 1, Dev A | Status: pending/approved/warning/rejected; visibility rule for discover/chat/report. |
| Healing check-in latest data | Dev C | Dev B | Mood, readiness, needs, trigger, small goal, timestamp. |
| Subscription state | Dev B | Dev C | Tier, status, mockPremium, limits. |
| Chat message type enum | Dev A | Dev B | TEXT, EMOJI, IMAGE, VOICE, AI_SUGGESTED_TEXT. |

## File/Module Ownership De Xuat

| Area | Owner | Duong dan du kien |
|---|---|---|
| Swipe/Match/Block/Conversation/Chat APIs | Dev A | `bondy_server/src/app/api/swipe`, `matches`, `blocks`, `conversations`, `messages`, `chats` |
| Match/Chat services | Dev A | `bondy_server/src/service/match*`, `conversation*`, `chat*`, `block*` |
| AI/Subscription/Paywall APIs | Dev B | `bondy_server/src/app/api/ai`, `subscription` |
| AI/Quota/Paywall services | Dev B | `bondy_server/src/service/ai*`, `feature*`, `quota*`, `paywall*`, `subscription*` |
| Healing/Admin APIs | Dev C | `bondy_server/src/app/api/healing`, `affiliate-courses`, `admin` |
| Healing/Moderation/Admin services | Dev C | `bondy_server/src/service/healing*`, `moderation*`, `admin*`, `report*`, `audit*` |
| Chat Flutter | Dev A | `Bondy_App/lib/screens/chat`, chat services/viewmodels |
| AI/Paywall Flutter | Dev B | `Bondy_App/lib/widgets/ai_*`, `screens/settings/premium_paywall_screen.dart`, subscription services |
| Healing/Admin Flutter | Dev C | `Bondy_App/lib/screens/healing`, `screens/admin`, healing/admin services |

## Diem Check Conflict Truoc Khi Merge

| Cau hoi | Neu cau tra loi la Co thi phai sync voi owner |
|---|---|
| Co sua Prisma model shared khong? | Sync voi Dev A/Dev B/Dev C theo model owner truoc khi merge. |
| Co doi paywall response shape khong? | Sync voi Dev B. |
| Co tao/sua conversation flow khong? | Sync voi Dev A. |
| Co tao/sua report/evidence khong? | Sync voi Dev C. |
| Co dung AI context tu chat/healing/profile khong? | Sync voi Dev A + Dev C + Dev 1. |
| Co them admin action moi khong? | Sync voi Dev C de ghi audit log. |

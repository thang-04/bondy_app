# Phan Chia Cong Viec 3 Dev Theo SRS/SDD

## Tong Quan Phan Cong

| Dev | Phu trach chinh | Man hinh chinh | API/module chinh | Khong lam de tranh conflict |
|---|---|---|---|---|
| Dev 1 | Auth, Profile, Discover | Register, Login, Email Verification, Profile Setup, Discover, Settings profile | Auth, Profile, Discovery, MatchingPreference, CompatibilityScore | Khong implement match/chat/paywall/admin. Chi goi contract do Dev 2/3 cung cap. |
| Dev 2 | Swipe, Match, Conversation, Chat, AI | Discover actions, Match Confirmation, Chat List, Chat Detail, AI Suggestion sheet | Swipe, Match, Conversation, Chat, AIUsage | Khong implement subscription tier/admin/healing content. Chi goi paywall/quota contract do Dev 3 cung cap. |
| Dev 3 | Subscription, Paywall, Healing, Affiliate, Moderation, Admin | Subscription/Paywall, Healing Check-In, Healing Tab, Admin screens | Subscription, Paywall, Healing, AffiliateCourse, Report, ModerationLog, Admin | Khong implement discover scoring/match/chat core. Chi cung cap moderation/report/paywall data cho Dev 1/2 dung. |

## Dev 1: Auth / Profile / Discover

| SRS/SDD | Nhom viec | Man hinh lien quan | Backend/API can lam | Ghi chu va phu thuoc |
|---|---|---|---|---|
| FR-AUTH-001, UC01 | Dang ky | Register | `POST /api/v1/auth/register` | Email/password, validate email/password, chan email trung, gui verification email sau dang ky. |
| FR-AUTH-003, UC01 | Dang nhap | Login | `POST /api/v1/auth/login` | Loi login generic, khong lo email hay password sai rieng. |
| FR-AUTH-002, UC01 | Xac minh email | Email Verification | `POST /api/v1/auth/verify`, resend verification | User chua verify bi chan protected actions truoc khi vao profile/discover/chat. |
| FR-PROFILE-001, UC02 | Ho so bat buoc | Profile Setup | `GET/PUT /api/v1/profile` | Bat buoc display name, DOB/age, gender/orientation, photo, location, bio, interests, relationship goal. |
| FR-PROFILE-001 | Kiem tra tuoi | Profile Setup | Profile validation | Validate DOB, chan user duoi tuoi toi thieu. |
| FR-PROFILE-001, SDD photos | Anh dai dien | Profile Setup, Image Upload | `POST /api/v1/profile/photo` | Bat buoc it nhat 1 anh hop le. Moderation status cua photo do Dev 3 cung cap. |
| FR-PROFILE-001, BR-PRIV-001 | Vi tri | Location Setup/Profile Setup | `PUT /api/v1/profile` hoac `/api/v1/profile/location` | Luu location cho filter, public serializer khong tra exact location. |
| FR-PROFILE-002 | An ho so | Settings | `PUT /api/v1/profile/visibility` | Hidden profile khong vao discover. |
| FR-PROFILE-003 | Xoa tai khoan | Settings | `DELETE /api/v1/profile` | Xoa/anonymize PII. Neu user co report evidence, Dev 3 cung cap retention rule. |
| FR-DISCOVER-001, UC03 | Discover filters | Discover | `GET /api/v1/discover`, `POST /api/v1/discover/filters` | Filter age range, distance, gender/orientation, relationship goal, shared interests, compatibility threshold. |
| FR-DISCOVER-002, UC03 | Compatibility score | Discover | CompatibilityScore service/table | Shared interests, distance, goal alignment, personality/value, healing readiness, deal-breakers. Healing readiness lay tu Dev 3. |
| FR-DISCOVER-001, BR-PRIV-001 | Discover exclusion/privacy | Discover | Discover repository/serializer | Loai blocked users do Dev 2 tao, hidden profiles do Dev 1 tao, moderation-failed profiles do Dev 3 tao. Khong tra exact location. |
| SRS Screen 6.1 | Flutter profile/discover flow | Register, Profile Setup, Discover, Settings | Auth/Profile/Discover services | UI khong cho vao discover neu profile thieu field bat buoc hoac email chua verify. |

## Dev 2: Swipe / Match / Conversation / Chat / AI

| SRS/SDD | Nhom viec | Man hinh lien quan | Backend/API can lam | Ghi chu va phu thuoc |
|---|---|---|---|---|
| FR-SWIPE-001, UC04 | Like profile | Discover | `POST /api/v1/swipe/like` | Like profile hop le, empty/invalid target bi chan, duplicate like khong tao duplicate match. Goi quota/paywall cua Dev 3 truoc khi ghi like. |
| FR-SWIPE-002, UC04 | Pass profile | Discover | `POST /api/v1/swipe/pass` | Pass xong remove khoi current discover queue theo redisplay policy. |
| FR-SWIPE-003, UC04 | Report profile | Discover | `POST /api/v1/swipe/report` | Chon reason, tao `Report`, luu evidence. Admin queue do Dev 3 hien thi/xu ly. |
| FR-MATCH-001, UC05 | Tao match | Discover, Match Confirmation | Match service | Mutual like moi tao 1 pending match, record timestamp, khong tao conversation ngay. |
| FR-MATCH-002, FR-CHAT-001, UC05/UC06 | Confirm conversation | Match Confirmation | `POST /api/v1/matches/{id}/confirm` | Ca 2 user confirm moi tao conversation. Match co expiry timer 24h. |
| FR-MATCH-002 | Het han match | Match Confirmation | Match expiry service/job | Pending match het han sau 24h neu chua du 2 confirm; expired match khong tao conversation. |
| FR-MATCH-003 | Unmatch | Match/Chat | `DELETE /api/v1/matches/{id}` | Dong/an conversation theo retention/report rules do Dev 3 cung cap. |
| FR-MATCH-004 | Block user | Profile/Chat/Settings | `/api/v1/blocks` | Block ngan discover ve sau, dong match/conversation hien co, blocked user khong gui message duoc. Dev 1 dung block table trong discover. |
| FR-CHAT-001, UC06 | Conversation | Chat List | `GET /api/v1/conversations`, `POST /api/v1/conversations` | Conversation linked to confirmed match; chi members xem duoc. |
| FR-CHAT-002, UC07 | Chat message | Chat Detail | `GET/POST /api/v1/messages` hoac conversation messages route | Gui text, emoji, image, voice, AI suggested text. User ngoai conversation bi chan. |
| FR-CHAT-002, BR-CHAT-002 | Empty/missing message | Chat Detail | Message validation | Reject empty message, missing data khong lam app crash. |
| FR-CHAT-003, UC07 | Chat states | Chat Detail | `PUT /api/v1/messages/{id}/read`, typing/online/delivery endpoints/events | Seen, typing, online/recent activity, delivery status. |
| FR-CHAT-004, BR-RET-001 | Chat retention | Chat backend | Retention policy/job | Normal chat 12 thang. Neu report evidence, Dev 3 giu 24 thang. |
| FR-AI-001, UC08 | AI suggestion endpoint | Chat Detail AI sheet | `POST /api/v1/ai/suggest`, `GET /api/v1/ai/usage` | Auth user only, userId lay tu token, check conversation membership truoc khi build context. |
| FR-AI-002, BR-AI-001/002 | AI quota | Chat Detail AI sheet | AIUsage service/table | Free user 10 suggestions/day, co technical rate limit, chan call vuot quota truoc khi goi provider. Paywall payload do Dev 3 dinh nghia. |
| FR-AI-001 | AI input context | Chat Detail AI sheet | Context builder | Lay profiles ca 2 user tu Dev 1, shared interests, current chat history, healing check-in data tu Dev 3. |
| FR-AI-001 | AI send flow | Chat Detail | Flutter AI widget/service | User chon suggestion truoc, khong auto-send, bo hardcoded mock user/conversation. |

## Dev 3: Subscription / Paywall / Healing / Affiliate / Moderation / Admin

| SRS/SDD | Nhom viec | Man hinh lien quan | Backend/API can lam | Ghi chu va phu thuoc |
|---|---|---|---|---|
| FR-SUB-001, UC10 | Subscription model | Subscription/Paywall | `GET /api/v1/subscription`, `POST /api/v1/subscription/upgrade` | Ho tro Free, Plus, Premium, Elite, status, start/end, mock premium flag. |
| FR-SUB-002 | Mock premium | Subscription/Paywall/Admin Subscription View | Mock premium API/flag | Dung de test MVP; admin xem/toggle duoc. |
| FR-SUB-002, BR-PAY-001 | Paywall chung | Subscription/Paywall | Paywall payload/service | Tra blocked feature, reason, upgrade path, tier options. Dev 1/2 chi goi service nay, khong tu tao paywall payload rieng. |
| FR-SUB-002, BR-LIKE-001 | Like paywall | Discover/Paywall | Paywall + quota service | Dev 2 goi de chan like thu 21 cua free user. |
| FR-SUB-002 | Advanced filter paywall | Discover Filters/Paywall | Entitlement check | Dev 1 goi de chan advanced filters neu tier khong du. |
| FR-AI-002, BR-AI-002 | AI paywall | AI sheet/Paywall | Paywall response contract | Dev 2 goi khi vuot 10 AI suggestions/day. |
| FR-HEAL-002, FR-SUB-001 | Healing paywall | Healing/Paywall | Healing entitlement check | Chan premium healing content bang server-side check. |
| SRS Screen 6.1 | Paywall UI | Subscription/Paywall | Flutter subscription service | UI co Free/Plus/Premium/Elite, blocked reason, upgrade path, mock premium state. |
| FR-HEAL-001, UC09 | Healing check-in | Healing Check-In | `POST /api/v1/healing/checkin` | Luu mood today, dating readiness, emotional needs, trigger/discomfort, small goal. |
| FR-HEAL-002, UC09 | Healing content | Healing Tab | `GET /api/v1/healing/content` | Content dua tren check-in neu co; missing check-in data khong crash. |
| FR-HEAL-003, BR-COURSE-001 | Affiliate courses | Healing Tab/Paywall | AffiliateCourse schema/API | Course co title, category, affiliate URL, active status, disclaimer, referral tracking neu integration ho tro. |
| FR-HEAL-003, BR-COURSE-002 | Affiliate placement | Healing Check-In, Healing Tab, Paywall | Healing response/UI | Hien sau check-in, trong Healing tab, trong paywall upsell. Khong chen affiliate link vao chat. |
| FR-MOD-001, UC11 | Auto moderation | Profile Setup/Profile Review | Moderation service | Detect sensitive images, spam/scam, contact info, toxic language, fake profile, underage indicators. Dev 1/2 goi moderation status de exclude discover/report. |
| FR-MOD-001, FR-ADMIN-001 | Profile review queue | Admin Profile Review | `/api/v1/admin/profile-reviews` | Suspected profile vao pending review, admin approve/warn/action. Khong auto-ban/auto-reject trong MVP. |
| FR-MOD-001 | User warning | Admin/Profile | Warning service/log | Auto-detect co the warning user; ghi moderation log. |
| FR-ADMIN-001 | User management | Admin User Management | `/api/v1/admin/users` | Admin xem/tim user, profile, status, actions. |
| FR-ADMIN-001 | Report queue | Admin Report Queue | `/api/v1/admin/reports` | Admin xem/process reports, evidence references do Dev 2 tao. |
| FR-ADMIN-002, NFR-AUDIT-001 | Moderation logs | Admin Moderation Logs | `/api/v1/admin/moderation-logs` | Luu actor, action type, target user/profile/report, timestamp. |
| FR-ADMIN-001 | Subscription view | Admin Subscription View | `/api/v1/admin/subscriptions` | Admin xem Free/Plus/Premium/Elite/mock premium state. |
| FR-ADMIN-001 | Affiliate admin | Admin Affiliate Courses | `/api/v1/admin/affiliate-courses` | Admin CRUD affiliate course links/disclaimers. |
| SRS Screen 6.2, UC11 | Admin Flutter screens | Admin area | Flutter admin services/screens | UI cho user management, profile review, report queue, moderation logs, subscription view, affiliate courses. |

## Ranh Gioi De Khong Conflict

| Shared area | Owner quyet dinh | Dev khac duoc lam gi |
|---|---|---|
| Auth/Profile/Discover API contract | Dev 1 | Dev 2/3 chi consume response, khong sua logic discover/profile neu chua thong nhat. |
| Swipe/Match/Conversation/Chat/AI API contract | Dev 2 | Dev 1/3 chi consume match/chat/report/AI status, khong tao conversation truc tiep. |
| Subscription/Paywall/Healing/Admin contract | Dev 3 | Dev 1/2 chi goi paywall/quota/moderation service, khong tu define payload rieng. |
| Prisma schema chung | Dev 1 lead schema merge | Dev 2/3 de xuat model can them, Dev 1 merge ten relation/index de tranh duplicate model. |
| Report/evidence | Dev 3 owner model/admin queue | Dev 2 tao report/evidence theo interface cua Dev 3. |
| Block table | Dev 2 owner action/model | Dev 1 dung block table de exclude discover. |
| Moderation status | Dev 3 owner moderation model | Dev 1 dung moderation status de exclude discover; Dev 2 dung trong report evidence. |
| Paywall payload | Dev 3 owner | Dev 1/2 tra lai payload tu service, khong custom message/shape. |
| Flutter routes | Moi dev owner screen cua minh | Neu can navigate sang screen cua dev khac, chi dung route name/params da thong nhat. |

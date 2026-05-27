# BONDY – DESIGN DOC BACKLOG PHÂN CHIA SONG SONG CHO 5 DEV

**Ngày tạo:** 2026-05-04  
**Dự án:** Bondy_App + bondy_server  
**Frontend:** Flutter + Provider/MVVM  
**Backend:** Next.js App Router + Prisma + PostgreSQL  
**Chiến lược:** Hybrid – Sprint đầu làm MVP end-to-end, nhưng DB/API contract thiết kế sẵn để nâng cấp production.

---

## 1. Mục tiêu

Backlog này viết lại kế hoạch Matching, Chat, AI Coach, Healing và Subscription để phù hợp với codebase hiện tại của Bondy.

Mục tiêu không chia theo layer DB/API/UI, mà chia theo module nghiệp vụ hoàn chỉnh để 5 dev có thể làm song song:

| Dev | Module | Mục tiêu chính |
|---|---|---|
| Dev 1 | Matching + Discover + Swipe | User xem profile, swipe, like, match |
| Dev 2 | Chat REST + Chat List | User đã match có thể nhắn tin qua REST trước |
| Dev 3 | AI Conversation Coach | AI gợi ý câu mở đầu/phản hồi trong chat |
| Dev 4 | Healing Flow | User check-in cảm xúc và nhận nội dung healing |
| Dev 5 | Subscription + Feature Gate | Quản lý gói premium, giới hạn tính năng, paywall |

Sprint 1 của nhóm feature này cần demo được flow:

```text
Survey/Profile hoàn tất
  ↓
Discover profile
  ↓
Swipe LIKE/SKIP
  ↓
Mutual like tạo Match + Chat
  ↓
Chat REST gửi/nhận message
  ↓
AI Suggest trong chat
  ↓
Hết lượt thì mở Paywall
  ↓
Healing check-in hoạt động độc lập
```

---

## 2. Đánh giá backlog cũ

### Điểm tốt

- Chia theo module nghiệp vụ là đúng hướng.
- Mỗi dev có ownership rõ ràng.
- Có mock data để làm độc lập.
- Có Definition of Done tương đối đầy đủ.
- Đã nghĩ tới monetization và AI từ sớm.

### Điểm cần chỉnh để khớp project

| Backlog cũ | Điều chỉnh phù hợp Bondy hiện tại |
|---|---|
| Tạo `user_likes` | Dùng model Prisma hiện có `Swipe` |
| Tạo `conversations` | Dùng model Prisma hiện có `Chat` |
| `messages.conversation_id` | Dùng `Message.chatId` nội bộ, API có thể alias `conversationId` |
| Realtime bắt buộc Sprint 1 | Sprint 1 làm REST ổn định, realtime để Sprint 2 |
| Subscription là module riêng lẻ | Subscription phải cung cấp `Feature Gate` cho Dev 1 và Dev 3 |
| AI gọi trực tiếp provider thật | Tạo abstraction: Mock provider trước, Gemini/OpenAI sau |
| API nhận `userId` từ client | Backend nên lấy user từ JWT/session, không tin input FE |

---

## 3. Kiến trúc tích hợp chung

### 3.1 Backend convention

Các API mới nên tổ chức theo pattern hiện tại của `bondy_server`:

```text
src/app/api/<module>/...
src/service/<module>.service.ts
src/repository/<module>.repository.ts
src/dto/<module>.dto.ts
```

Ví dụ:

```text
src/app/api/discover/route.ts
src/app/api/matching/swipe/route.ts
src/service/matching.service.ts
src/repository/matching.repository.ts
src/dto/matching.dto.ts
```

### 3.2 Flutter convention

Frontend `Bondy_App` đang theo Flutter Provider/MVVM. Mỗi module nên có:

```text
lib/models/<module>/
lib/services/<module>_service.dart
lib/viewmodels/<module>/<module>_viewmodel.dart
lib/screens/<module>/...
```

UI không gọi API trực tiếp. UI gọi ViewModel, ViewModel gọi Service.

### 3.3 Auth convention

API user-sensitive không nên nhận `userId` từ Flutter. Nên dùng:

```http
Authorization: Bearer <accessToken>
```

Trong dev nếu cần mock nhanh, có thể dùng `x-user-id`, nhưng phải ghi rõ `dev-only`.

---

## 4. DB contract

### 4.1 Model hiện có dùng lại

#### Swipe

Dùng thay cho `user_likes`.

Cần bổ sung constraint/index:

```prisma
@@unique([swiperId, targetUserId])
@@index([swiperId])
@@index([targetUserId])
```

Action chuẩn hóa:

```text
LIKE
SKIP
```

#### Match

Dùng model hiện có `Match`.

Cần bổ sung:

```prisma
status String @default("ACTIVE")
```

Rule bắt buộc:

```text
user1Id < user2Id
```

Status:

```text
ACTIVE
UNMATCHED
BLOCKED
```

#### Chat

Dùng thay cho `conversations`.

Cần bổ sung để query chat list nhanh:

```prisma
lastMessagePreview String?
lastMessageAt      DateTime?
updatedAt          DateTime @updatedAt
```

API có thể trả field `conversationId = chat.id` để frontend dễ hiểu.

#### Message

Dùng model hiện có `Message`.

Cần bổ sung:

```prisma
status String @default("SENT")

@@index([chatId, createdAt])
@@index([senderId])
```

---

### 4.2 Model mới nên thêm

#### AiSuggestion

```prisma
model AiSuggestion {
  id                String   @id @default(uuid())
  userId            String
  chatId            String?
  intent            String
  tone              String?
  language          String   @default("vi")
  inputContext      Json?
  outputSuggestions Json
  model             String?
  status            String   @default("SUCCESS")
  createdAt         DateTime @default(now())

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId, createdAt])
  @@index([chatId])
}
```

#### HealingCheckin

```prisma
model HealingCheckin {
  id        String   @id @default(uuid())
  userId    String
  mood      String
  note      String?
  createdAt DateTime @default(now())

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId, createdAt])
}
```

#### HealingContent

```prisma
model HealingContent {
  id         String   @id @default(uuid())
  type       String
  title      String
  content    String
  moodTarget String?
  isActive   Boolean  @default(true)
  createdAt  DateTime @default(now())
}
```

#### Subscription

```prisma
model Subscription {
  id                     String   @id @default(uuid())
  userId                 String   @unique
  plan                   String   @default("FREE")
  status                 String   @default("ACTIVE")
  startAt                DateTime?
  expireAt               DateTime?
  platform               String?
  provider               String?
  providerSubscriptionId String?
  createdAt              DateTime @default(now())
  updatedAt              DateTime @updatedAt

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)
}
```

#### FeatureUsage

```prisma
model FeatureUsage {
  id         String   @id @default(uuid())
  userId     String
  feature    String
  usedCount  Int      @default(0)
  limitCount Int?
  date       DateTime
  createdAt  DateTime @default(now())
  updatedAt  DateTime @updatedAt

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([userId, feature, date])
  @@index([userId, feature])
}
```

#### PurchaseLog

```prisma
model PurchaseLog {
  id            String   @id @default(uuid())
  userId        String
  provider      String
  productId     String
  purchaseToken String?
  status        String
  rawPayload    Json?
  createdAt     DateTime @default(now())

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId, createdAt])
}
```

---

## 5. API contract chính

### 5.1 Discover

```http
GET /api/discover?cursor=&limit=20
```

```json
{
  "items": [
    {
      "userId": "u_02",
      "displayName": "Linh",
      "age": 23,
      "avatarUrl": "...",
      "bio": "Thích cafe và đi dạo",
      "city": "Hà Nội",
      "distanceKm": 3.2,
      "compatibilityScore": 8,
      "commonInterests": ["Cafe", "Music"]
    }
  ],
  "nextCursor": null
}
```

### 5.2 Swipe / Matching

```http
POST /api/matching/swipe
```

```json
{
  "targetUserId": "u_02",
  "action": "LIKE"
}
```

Response khi match:

```json
{
  "swiped": true,
  "matched": true,
  "matchId": "m_01",
  "conversationId": "chat_01",
  "matchedUser": {
    "userId": "u_02",
    "displayName": "Linh",
    "avatarUrl": "..."
  }
}
```

### 5.3 Matches

```http
GET /api/matches
```

```json
{
  "items": [
    {
      "matchId": "m_01",
      "conversationId": "chat_01",
      "user": {
        "userId": "u_02",
        "displayName": "Linh",
        "avatarUrl": "..."
      },
      "matchedAt": "2026-05-06T10:00:00Z"
    }
  ]
}
```

### 5.4 Conversations

```http
GET /api/conversations
GET /api/conversations/:conversationId/messages
POST /api/conversations/:conversationId/messages
POST /api/conversations/:conversationId/read
```

Send message request:

```json
{
  "content": "Hello bạn"
}
```

Message response:

```json
{
  "messageId": "msg_01",
  "conversationId": "chat_01",
  "senderId": "u_01",
  "content": "Hello bạn",
  "messageType": "TEXT",
  "createdAt": "2026-05-06T10:30:00Z",
  "isMine": true
}
```

### 5.5 AI Conversation Suggest

```http
POST /api/ai/conversation-suggest
```

```json
{
  "conversationId": "chat_01",
  "intent": "ICE_BREAKER",
  "tone": "FRIENDLY",
  "language": "vi"
}
```

```json
{
  "suggestions": [
    "Mình thấy bạn thích cafe, bạn hay đi quán nào ở Hà Nội vậy?",
    "Profile của bạn có vibe khá nhẹ nhàng, cuối tuần bạn thường làm gì để thư giãn?",
    "Nếu chọn một buổi hẹn đầu tiên lý tưởng, bạn thích cafe hay đi dạo hơn?"
  ],
  "usage": {
    "remainingFreeUses": 4
  }
}
```

### 5.6 Healing

```http
POST /api/healing/checkin
GET /api/healing/today
POST /api/healing/chat
```

### 5.7 Subscription

```http
GET /api/subscription/me
POST /api/subscription/check-feature
POST /api/subscription/consume-feature
POST /api/subscription/mock-upgrade
POST /api/subscription/google-play/verify
```

Feature gate response khi hết lượt:

```json
{
  "allowed": false,
  "reason": "LIMIT_REACHED",
  "paywallType": "AI_SUGGEST_LIMIT"
}
```

---

## 6. Phân chia module

### Dev 1 – Matching + Discover + Swipe

Scope:

- Discover API.
- Swipe LIKE/SKIP.
- Mutual like tạo Match + Chat.
- Match list.
- Discover UI nối ViewModel.
- Match modal.

Definition of Done:

- Không hiển thị chính user.
- Không hiển thị user đã swipe/match.
- LIKE/SKIP lưu DB.
- Mutual like tạo Match + Chat.
- Không duplicate Match/Chat.
- Flutter chạy được với mock và API thật.

### Dev 2 – Chat REST + Chat List

Scope:

- Conversation list.
- Message list.
- Send message.
- Mark read.
- Chat list UI.
- Chat detail UI.

Definition of Done:

- User chỉ xem/gửi trong chat của mình.
- Message lưu DB trước khi trả response.
- Reload không mất message.
- Last message cập nhật.
- Empty/loading/error state đầy đủ.

### Dev 3 – AI Conversation Coach

Scope:

- AI suggest API.
- MockAiProvider trước.
- Lưu AiSuggestion.
- Gọi Feature Gate trước khi generate.
- AI bottom sheet trong chat.

Definition of Done:

- Có ít nhất 5 intent.
- Output tiếng Việt tự nhiên.
- Tap suggestion fill vào input.
- Không tự gửi thay user.
- Có xử lý limit/paywall.
- Có fallback khi AI fail.

### Dev 4 – Healing Flow

Scope:

- Daily mood check-in.
- Healing today content.
- Healing content detail.
- Healing chatbot MVP/mock.
- Disclaimer an toàn.

Definition of Done:

- Lưu check-in.
- Content đổi theo mood.
- Có màn Healing Home.
- Có content detail.
- Chatbot không đóng vai bác sĩ/chuyên gia tâm lý.
- Có nút quay lại Discover khi user sẵn sàng.

### Dev 5 – Subscription + Feature Gate

Scope:

- Subscription state.
- Check feature.
- Consume feature.
- Mock upgrade.
- Paywall UI.
- Usage limit dialog.

Definition of Done:

- Dev 1 dùng được gate cho swipe.
- Dev 3 dùng được gate cho AI suggest.
- Hết lượt hiện paywall.
- Mock upgrade đổi trạng thái premium.
- Không hard-code premium logic trong từng module.

---

## 7. Dependency map

```text
Dev 5 Feature Gate
  ├── Dev 1 dùng cho daily swipe limit
  └── Dev 3 dùng cho AI suggest limit

Dev 1 Matching
  └── tạo Chat cho Dev 2 dùng

Dev 2 Chat
  └── cung cấp recent messages cho Dev 3 context

Dev 4 Healing
  └── độc lập, chỉ dùng Auth/User/Profile

Dev 3 AI
  ├── phụ thuộc Chat nếu suggest trong conversation
  └── phụ thuộc Feature Gate để limit
```

---

## 8. Error code chuẩn

```text
UNAUTHORIZED
FORBIDDEN
VALIDATION_ERROR
PROFILE_INCOMPLETE
DUPLICATE_SWIPE
ALREADY_MATCHED
CHAT_NOT_FOUND
NOT_CHAT_MEMBER
MESSAGE_EMPTY
MESSAGE_TOO_LONG
LIMIT_REACHED
AI_PROVIDER_FAILED
HEALING_CONTENT_NOT_FOUND
```

Error response:

```json
{
  "error": {
    "code": "LIMIT_REACHED",
    "message": "Bạn đã dùng hết lượt AI Suggest hôm nay.",
    "details": {
      "paywallType": "AI_SUGGEST_LIMIT"
    }
  }
}
```

---

## 9. Sprint plan đề xuất

### Ngày 1 – Contract day

- Chốt Prisma migration.
- Chốt API response.
- Chốt Flutter model field.
- Chốt mock JSON.
- Chốt error code.

### Ngày 2–4 – Build song song

- Dev 1: Discover/Matching.
- Dev 2: Chat REST.
- Dev 3: AI Coach.
- Dev 4: Healing.
- Dev 5: Subscription/Feature Gate.

### Ngày 5 – Integration

Demo flow:

```text
User A like User B
User B like User A
Match modal xuất hiện
Chat được tạo
Gửi message
Bấm AI Suggest
Hết lượt thì hiện paywall
Healing check-in hoạt động độc lập
```

---

## 10. Rủi ro và cách giảm rủi ro

| Rủi ro | Cách xử lý |
|---|---|
| 5 dev mock lệch contract | Ngày 1 phải chốt contract + mock JSON |
| Duplicate match khi 2 request đồng thời | Dùng transaction + unique `[user1Id, user2Id]` |
| Chat phụ thuộc Matching | Dev 2 dùng mock Chat ID trước |
| AI provider fail/chậm | Mock provider + timeout + fallback |
| Billing thật phức tạp | Sprint 1 chỉ mock upgrade, Sprint 2 verify Google Play |
| Realtime tăng scope | Sprint 1 REST, Sprint 2 realtime |
| UserId bị giả mạo | Lấy user từ JWT/session, không tin body |

---

## 11. Kết luận

Kế hoạch mới giữ đúng tinh thần chia song song theo module nghiệp vụ, nhưng chỉnh để khớp codebase hiện tại:

- Không tạo bảng trùng chức năng.
- Dùng `Swipe`, `Match`, `Chat`, `Message` hiện có.
- Subscription trở thành shared Feature Gate.
- AI và Healing có scope MVP rõ.
- Realtime và Billing thật được đẩy sang phase sau để giảm rủi ro.

Đây là nền phù hợp để team triển khai Sprint 2 theo hướng MVP chạy được, sau đó nâng cấp production dần.

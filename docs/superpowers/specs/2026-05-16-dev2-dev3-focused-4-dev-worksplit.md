# Phân Chia Công Việc 4 Dev Tập Trung Dev 2 / Dev 3

## Mục Tiêu

File này chia lại các phần việc đang nằm trong phạm vi Dev 2 và Dev 3 thành 4 nhóm độc lập hơn: Match/Chat, AI/Paywall, Healing/Affiliate, Admin/Moderation. Mục tiêu là để 4 dev làm song song nhưng không đụng nhau, đồng thời các luồng thực thi vẫn đúng theo SRS/SDD.

## Nguyên Tắc Không Conflict

| Nguyên tắc | Áp dụng | Giải thích |
|---|---|---|
| Mỗi contract có 1 owner | API payload, schema, enum, service core chỉ có 1 dev owner. | Tránh mỗi dev tự tạo response/schema khác nhau làm UI và backend lệch nhau. |
| Conversation chỉ tạo sau confirm | Không dev nào được tạo conversation trước khi match đủ 2 confirmation. | SRS yêu cầu cả hai user xác nhận match trước khi chat. |
| Paywall payload dùng chung | Like, AI, advanced filter, healing premium đều dùng payload do Dev B định nghĩa. | Nếu mỗi luồng trả paywall khác nhau, Flutter sẽ khó xử lý và dễ lỗi. |
| Report/evidence dùng chung | Swipe tạo report theo interface của Dev D; Admin/Moderation xử lý. | Report là dữ liệu dùng cho moderation/admin nên Dev D phải quản lý model và evidence. |
| Moderation status dùng chung | Dev D owner moderation status; Discover/Chat/Admin consume. | Discover cần biết profile nào bị pending/rejected để loại khỏi danh sách. |
| Admin không lặp lại business logic | Admin chỉ đọc/xử lý/action qua service owner, không viết lại logic match/chat/AI/healing. | Admin là lớp vận hành, không nên tự tạo logic riêng gây sai lệch với app user. |
| Không phụ thuộc cứng vào dev khác | Mỗi dev phải có contract/stub/mock để tiếp tục làm nếu dev khác chưa xong. | Ví dụ Dev A chưa làm xong conversation membership thì Dev B vẫn làm AI quota/paywall và dùng membership stub tạm. |

## Tổng Phân Công 4 Dev

| Dev | Phạm vi | Owner chính | Màn hình chính | API/module chính | Giải thích |
|---|---|---|---|---|---|
| Dev A | Swipe / Match / Conversation / Chat | Like/pass/report action, match lifecycle, block, conversation, message, chat states | Discover actions, Match Confirmation, Chat List, Chat Detail | `/api/v1/swipe/*`, `/api/v1/matches/*`, `/api/v1/blocks`, `/api/v1/conversations`, `/api/v1/messages` | Dev A giữ toàn bộ luồng từ user thao tác trên Discover đến khi match được xác nhận và chat hoạt động. |
| Dev B | AI / Subscription / Paywall | AI suggestion, AI usage quota, subscription tiers, paywall payload/quota/entitlement | AI Suggestion sheet, Subscription/Paywall | `/api/v1/ai/*`, `/api/v1/subscription/*`, paywall/quota service | Dev B giữ các giới hạn trả phí và AI để mọi luồng quota/paywall dùng chung một cách nhất quán. |
| Dev C | Healing / Affiliate | Healing check-in, healing content, affiliate courses, healing paywall consume | Healing Check-In, Healing Tab, affiliate course cards | `/api/v1/healing/*`, `/api/v1/affiliate-courses` | Dev C giữ trải nghiệm healing và affiliate course, nhưng chỉ gọi paywall của Dev B khi gặp nội dung premium. |
| Dev D | Moderation / Admin / Audit | Auto-detect moderation, report queue, profile review, moderation logs, admin screens | Admin User Management, Profile Review, Report Queue, Moderation Logs, Subscription View, Affiliate Courses | `/api/v1/admin/*`, moderation service, report/evidence service, audit service | Dev D giữ phần vận hành nội bộ: kiểm duyệt, xử lý report, audit log và admin dashboard. |

## Dev A: Swipe / Match / Conversation / Chat (Hùng)

| SRS/SDD | Việc cần làm | Màn hình | API/module | Giao diện với dev khác | Giải thích |
|---|---|---|---|---|---|
| FR-SWIPE-001 | Like profile | Discover | `POST /api/v1/swipe/like` | Gọi Dev B quota service trước khi ghi like. | Free user chỉ có 20 like/ngày, nên like phải check quota trước khi lưu. |
| FR-SWIPE-002 | Pass profile | Discover | `POST /api/v1/swipe/pass` | Discover queue sẽ exclude passed profiles. | User pass profile thì profile đó phải biến khỏi hàng đợi hiện tại. |
| FR-SWIPE-003 | Report profile | Discover | `POST /api/v1/swipe/report` | Tạo report theo interface của Dev D. | Dev A nhận hành động report từ card, nhưng dữ liệu report/evidence thuộc Dev D. |
| FR-MATCH-001 | Tạo pending match khi mutual like | Discover, Match Confirmation | Match service | Không tạo conversation tại bước like. | Mutual like chỉ tạo match chờ xác nhận, chưa được mở chat ngay. |
| FR-MATCH-002, FR-CHAT-001 | Confirm conversation | Match Confirmation | `POST /api/v1/matches/{id}/confirm` | Cả 2 user confirm mới tạo conversation. | Đây là điểm quan trọng nhất để sửa lỗi hiện tại: chat chỉ mở khi hai bên đồng ý. |
| FR-MATCH-002 | Expire pending match sau 24h | Match Confirmation | Match expiry service/job | Expired match không tạo conversation. | Nếu sau 24h chưa đủ 2 confirmation, match hết hạn và không thể mở chat. |
| FR-MATCH-003 | Unmatch | Match/Chat | `DELETE /api/v1/matches/{id}` | Đóng/ẩn conversation theo retention/evidence rule của Dev D. | User phải có quyền dừng match; nếu đã có report thì vẫn phải giữ evidence theo rule. |
| FR-MATCH-004 | Block user | Profile/Chat/Settings | `/api/v1/blocks` | Block ngăn discover, đóng match/conversation, chặn send message. | Block là chức năng an toàn; blocked user không được tiếp tục thấy hoặc nhắn với blocker. |
| FR-CHAT-001 | Conversation list | Chat List | `GET /api/v1/conversations` | Chỉ members xem được conversation. | User ngoài conversation không được thấy chat. |
| FR-CHAT-002 | Send/list messages | Chat Detail | `GET/POST /api/v1/messages` | Hỗ trợ TEXT, EMOJI, IMAGE, VOICE, AI_SUGGESTED_TEXT. | Chat phải hỗ trợ đúng các loại message trong SRS. |
| FR-CHAT-002 | Empty/missing message | Chat Detail | Message validation | Reject empty message, missing data không crash. | Empty message là blocker defect trong SRS, phải chặn ở backend và UI. |
| FR-CHAT-003 | Seen/typing/online/delivery | Chat Detail | `PUT /api/v1/messages/{id}/read`, typing/online/delivery endpoints/events | Dev B AI sheet chỉ consume chat state, không sửa state service. | Trạng thái realtime thuộc Chat; AI sheet không được tự quản lý state riêng. |
| FR-CHAT-004 | Chat retention 12 tháng | Chat backend | Retention job/service | Report evidence 24 tháng do Dev D owner. | Chat thường giữ 12 tháng, nhưng evidence report giữ 24 tháng. |

### Dev A Không Được Làm

| Không làm | Lý do | Giải thích |
|---|---|---|
| Không define paywall payload | Dev B owner. | Dev A chỉ gọi paywall service, không tự trả response khác shape. |
| Không tạo AI provider call | Dev B owner. | AI cần quota/rate limit/cost control do Dev B quản lý. |
| Không tạo Report/evidence schema riêng | Dev D owner. | Report dùng cho admin/moderation nên schema phải thống nhất với Dev D. |
| Không xử lý admin moderation action | Dev D owner. | Admin action cần audit log và quyền admin. |
| Không thêm affiliate/healing content | Dev C owner. | Healing/affiliate là domain riêng, tránh lẫn vào chat. |

## Dev B: AI / Subscription / Paywall (Minh)

| SRS/SDD | Việc cần làm | Màn hình | API/module | Giao diện với dev khác | Giải thích |
|---|---|---|---|---|---|
| FR-SUB-001 | Subscription tiers | Subscription/Paywall | `GET /api/v1/subscription`, `POST /api/v1/subscription/upgrade` | Dev A check like limit; Dev C check healing premium; Dev D admin view consume. | Subscription là nguồn sự thật cho Free/Plus/Premium/Elite. |
| FR-SUB-002 | Mock premium state | Subscription/Paywall, Admin Subscription View | Subscription service/mock flag | Dev D admin screen consume để xem/toggle. | MVP cần mock premium để test paywall mà chưa cần billing thật. |
| FR-SUB-002, BR-PAY-001 | Paywall payload chung | Subscription/Paywall | Paywall/quota service | Dev A/C dùng chung, không custom payload. | Paywall phải có blocked reason và upgrade path giống nhau ở mọi luồng. |
| BR-LIKE-001 | Like quota 20/ngày | Discover/Paywall | Quota service | Dev A gọi trước `swipe/like`. | Like limit là trigger paywall bắt buộc trong SRS. |
| FR-SUB-002 | Advanced filter entitlement | Discover Filters/Paywall | Entitlement service | Dev 1/Discover gọi khi dùng advanced filters. | Advanced filter là paid feature, không nên hardcode ở Discover. |
| FR-AI-001 | AI suggestion endpoint | Chat Detail AI sheet | `POST /api/v1/ai/suggest` | Check conversation membership qua Dev A trước provider call. | AI suggestion chỉ được dùng trong conversation mà user là member. |
| FR-AI-001 | AI context builder | Chat Detail AI sheet | Context builder | Lấy profile/shared interests từ Dev 1, chat history từ Dev A, healing check-in từ Dev C. | SRS yêu cầu AI dùng cả profile hai bên, sở thích chung, chat history và healing data. |
| FR-AI-001 | User chooses before send | Chat Detail AI sheet | Flutter AI widget/service | Trả suggestion về input chat của Dev A, không auto-send. | AI không được tự gửi message; user phải quyết định có gửi hay không. |
| FR-AI-002 | AI quota 10/ngày | AI sheet/Paywall | AIUsage service/table | Chặn call vượt quota trước provider; vượt quota trả paywall payload. | Không được gọi AI provider nếu user đã hết quota. |
| FR-AI-002 | Technical rate limit | AI backend | Rate-limit guard | Chống abuse/cost spike. | Ngoài daily quota còn cần rate limit kỹ thuật để tránh spam/cost. |
| SRS Screen 6.1 | Paywall UI | Subscription/Paywall | Flutter subscription service/screen | Hiện blocked reason, Plus/Premium/Elite, mock premium state. | Paywall screen phải cho user hiểu bị chặn gì và nâng cấp bằng cách nào. |

### Paywall Payload Do Dev B Owner

| Field | Ý nghĩa | Giải thích |
|---|---|---|
| `code` | `PAYWALL_REQUIRED` hoặc `LIMIT_REACHED`. | Code giúp Flutter phân biệt lỗi thường và paywall. |
| `blockedFeature` | `LIKE_LIMIT`, `ADVANCED_FILTER`, `AI_SUGGESTION`, `HEALING_CONTENT`. | Cho UI biết feature nào bị chặn. |
| `message` | Lý do bị chặn. | Text hiển thị trong paywall. |
| `upgradeOptions` | Plus/Premium/Elite options. | Các lựa chọn nâng cấp. |
| `currentTier` | Tier hiện tại. | Giúp UI highlight gói hiện tại. |
| `mockPremium` | Trạng thái mock premium. | Dùng cho MVP testing/admin toggle. |

### Dev B Không Được Làm

| Không làm | Lý do | Giải thích |
|---|---|---|
| Không tạo conversation/chat message trực tiếp | Dev A owner. | AI chỉ gợi ý text, user gửi qua chat flow của Dev A. |
| Không bypass membership check | Phải check qua Dev A. | Tránh user ngoài conversation request AI context. |
| Không tạo healing content schema | Dev C owner. | AI chỉ consume healing check-in, không quản lý healing content. |
| Không implement admin report/moderation UI | Dev D owner. | Admin cần audit/quyền riêng. |

## Dev C: Healing / Affiliate (Thắng)

| SRS/SDD | Việc cần làm | Màn hình | API/module | Giao diện với dev khác | Giải thích |
|---|---|---|---|---|---|
| FR-HEAL-001 | Healing check-in | Healing Check-In | `POST /api/v1/healing/checkin` | Dev B AI context consume latest check-in. | Check-in là nguồn data cho personalization và AI suggestion. |
| FR-HEAL-001 | Check-in fields | Healing Check-In | HealingCheckIn schema/service | Mood today, dating readiness, emotional needs, trigger/discomfort, small goal. | Phải đúng field trong SRS, không dùng field cũ kiểu mood/intensity/context thay thế. |
| FR-HEAL-002 | Healing content | Healing Tab | `GET /api/v1/healing/content` | Premium content check gọi Dev B entitlement/paywall. | Content cơ bản mở cho user, content premium check paywall. |
| FR-HEAL-002 | Missing check-in fallback | Healing Tab | Healing content service | Missing check-in data không crash. | Nếu user chưa check-in, app vẫn phải hiển thị fallback content. |
| FR-HEAL-003 | Affiliate courses | Healing Tab, Paywall | `/api/v1/affiliate-courses` | Course có affiliate URL, disclaimer, active status. Admin CRUD do Dev D. | Affiliate course là third-party link, không phải course nội bộ thu tiền trong app. |
| FR-HEAL-003 | Affiliate placement | Healing Check-In, Healing Tab, Paywall | Healing response/UI | Sau check-in, trong Healing tab, trong paywall upsell. | Đây là 3 vị trí SRS yêu cầu affiliate xuất hiện. |
| BR-COURSE-001 | No in-app course checkout | Healing Tab | Affiliate link handling | Mở external affiliate link, không checkout course trong app. | SRS ghi rõ in-app checkout cho third-party course nằm ngoài MVP. |
| BR-COURSE-002 | No affiliate in chat | Healing/Chat boundary | Content guard | Không chèn affiliate link vào conversation/chat/AI message. | Affiliate link không được xuất hiện trong chat. |
| SRS Screen 6.1 | Flutter Healing UI | Healing Check-In, Healing Tab | Flutter healing services/screens | Check-in form, content list, course card, disclaimer. | UI cần đủ form check-in và course card có disclaimer. |

### Dev C Không Được Làm

| Không làm | Lý do | Giải thích |
|---|---|---|
| Không define paywall payload | Dev B owner. | Dev C chỉ gọi paywall service khi content premium bị chặn. |
| Không tạo AI provider call | Dev B owner. | Healing chỉ cung cấp context cho AI. |
| Không sửa chat message insertion | Dev A owner. | Tránh vô tình chèn affiliate link vào chat. |
| Không implement admin action/audit | Dev D owner. | Admin CRUD/audit cần quyền và log riêng. |

## Dev D: Moderation / Admin / Audit (Hải Anh)

| SRS/SDD | Việc cần làm | Màn hình | API/module | Giao diện với dev khác | Giải thích |
|---|---|---|---|---|---|
| FR-MOD-001 | Auto-detect moderation | Profile Setup/Profile Review | Moderation service | Dev 1/Dev A consume moderation status để exclude discover/report context. | Profile/photo nghi vi phạm phải vào queue, không được hiện tự do trong discover. |
| FR-MOD-001 | Profile review queue | Admin Profile Review | `/api/v1/admin/profile-reviews` | Suspected profile/photo vào pending review. | Admin cần nơi duyệt profile bị auto-detect. |
| FR-MOD-001 | User warning | Admin/Profile | Warning service/log | Warning user; không auto-ban/auto-reject MVP. | SRS cho warning, pending review; không tự động ban/reject trong MVP. |
| FR-SWIPE-003, FR-MATCH-005 | Report model/evidence | Admin Report Queue | Report/evidence service | Dev A tạo report theo interface của Dev D. Evidence giữ 24 tháng. | Report từ profile/chat phải giữ đủ context cho admin xử lý. |
| FR-ADMIN-001 | User management | Admin User Management | `/api/v1/admin/users` | Xem/tìm user, profile, status, actions. | Admin cần quản lý user và trạng thái tài khoản. |
| FR-ADMIN-001 | Report queue | Admin Report Queue | `/api/v1/admin/reports` | Process reports từ Dev A. | Admin xử lý report reason/evidence/action. |
| FR-ADMIN-002, NFR-AUDIT-001 | Moderation logs | Admin Moderation Logs | `/api/v1/admin/moderation-logs` | Ghi actor, action type, target user/profile/report, timestamp. | Mọi action moderation/admin phải audit được. |
| FR-ADMIN-001 | Subscription view | Admin Subscription View | `/api/v1/admin/subscriptions` | Consume subscription/mock premium từ Dev B. | Admin xem tier và mock premium state. |
| FR-ADMIN-001 | Affiliate admin | Admin Affiliate Courses | `/api/v1/admin/affiliate-courses` | CRUD affiliate links/disclaimers do Dev C schema cung cấp. | Admin quản lý course affiliate, nhưng business display thuộc Dev C. |
| SRS Screen 6.2 | Admin Flutter screens | Admin area | Flutter admin services/screens | User management, profile review, report queue, moderation logs, subscription view, affiliate courses. | Cần đủ 6 màn admin trong SRS. |

### Dev D Không Được Làm

| Không làm | Lý do | Giải thích |
|---|---|---|
| Không tạo match/conversation/chat logic | Dev A owner. | Admin chỉ xem/xử lý trạng thái, không thay luồng chat core. |
| Không define paywall payload | Dev B owner. | Admin consume subscription/paywall state từ Dev B. |
| Không tạo healing content business logic | Dev C owner. | Admin chỉ CRUD affiliate links, không quyết định healing personalization. |
| Không gọi AI provider | Dev B owner. | Admin moderation không được dùng sai AI suggestion provider. |

## Thứ Tự Luồng Thực Thi Bắt Buộc

| Luồng | Thứ tự chuẩn | Owner | Giải thích |
|---|---|---|---|
| Like -> Match -> Conversation | `swipe/like` -> Dev B check like quota -> Dev A create/update like -> if mutual like create pending match -> Match Confirmation -> both confirm -> Dev A create conversation -> Chat List/Detail hiện conversation | Dev A + Dev B | Đảm bảo like limit chạy trước khi tạo match và conversation không tạo trước confirm. |
| Report profile | Discover card -> Dev A `swipe/report` -> create Report/evidence theo Dev D interface -> Dev D Admin Report Queue process -> Dev D ghi ModerationLog | Dev A + Dev D | User tạo report ở Discover, nhưng evidence/admin xử lý do Dev D quản. |
| Block user | User block -> Dev A close match/conversation + prevent send message -> Discover excludes block -> Admin/report context consume if needed | Dev A | Block phải ảnh hưởng cả discover, match và chat. |
| AI suggestion | Chat Detail -> Dev B `ai/suggest` -> auth user from token -> Dev A membership check -> Dev B quota 10/day -> context profile/chat/healing -> provider call -> return suggestion -> user manually sends via Dev A chat input | Dev B + Dev A + Dev C | AI phải qua auth, membership, quota và user phải tự chọn gửi. |
| Healing premium | User mở premium healing content -> Dev C check content access -> Dev B entitlement/paywall -> allowed returns content, blocked returns paywall payload | Dev C + Dev B | Healing không tự tạo paywall shape, phải dùng paywall chung. |
| Affiliate suggestion | User submit check-in -> Dev C returns content/course suggestions with disclaimer -> user opens external affiliate link -> no link inserted into chat | Dev C | Affiliate chỉ hiển thị ở healing/paywall, không xuất hiện trong chat. |
| Admin moderation | Profile/photo update -> Dev D auto-detect -> suspected enters review queue -> Admin reviews -> warning/approve/action -> Dev D writes ModerationLog -> Discover consumes moderation status | Dev D + Dev 1 | Moderation status ảnh hưởng discover visibility và phải có audit log. |

## Bảng Giao Diện Giữa Dev

| Interface | Owner | Consumer | Nội dung cần thống nhất | Giải thích |
|---|---|---|---|---|
| Paywall/quota service | Dev B | Dev A, Dev C | Input userId + feature; output allowed hoặc paywall payload chung. | Like, AI, healing premium đều dùng chung để tránh response lệch. |
| Conversation membership service | Dev A | Dev B | Input userId + conversationId; output member/not member. | AI cần check user thuộc conversation trước khi build context. |
| Chat message enum | Dev A | Dev B | TEXT, EMOJI, IMAGE, VOICE, AI_SUGGESTED_TEXT. | AI suggested text vẫn là message type trong chat domain. |
| Report creation interface | Dev D | Dev A | reporterId, target user/profile/conversation/message, reason, evidence refs, status. | Dev A chỉ gửi đúng data, Dev D quản report lifecycle. |
| Report/evidence retention rule | Dev D | Dev A, Dev C | Normal chat 12 tháng, report evidence 24 tháng, deletion/anonymization exception. | Unmatch/delete account vẫn phải giữ evidence nếu cần. |
| Healing check-in latest data | Dev C | Dev B | mood, readiness, needs, trigger, smallGoal, timestamp. | AI suggestion dùng healing context theo SRS. |
| Subscription state | Dev B | Dev D, Dev C, Dev A | tier, status, mockPremium, limits. | Admin/healing/like limit đều dựa trên subscription state. |
| Moderation status | Dev D | Dev 1, Dev A, Dev C | pending/approved/warning/rejected; visibility rule. | Discover loại profile unsafe theo status này. |
| Affiliate course model | Dev C | Dev D | title, category, affiliateUrl, active, disclaimer. | Dev C định nghĩa course hiển thị; Dev D làm admin CRUD. |

## Kế Hoạch Không Bị Chặn Khi Dev Khác Chưa Xong

| Nếu dev chưa xong | Phần có thể ảnh hưởng | Dev còn lại vẫn làm được gì | Cách làm tạm không conflict | Khi owner xong thì nối lại thế nào |
|---|---|---|---|---|
| Dev A chưa xong Match/Chat | Dev B cần membership check cho AI; Dev D cần report từ swipe; Dev C không bị ảnh hưởng trực tiếp | Dev B vẫn làm AI quota, AI provider wrapper, paywall response, subscription UI; Dev C vẫn làm healing/affiliate; Dev D vẫn làm admin/report/moderation screens | Dev B tạo `ConversationMembershipPort` interface và dùng stub `isMember=true/false` trong test; Dev D tạo report admin bằng seed/mock report data | Thay stub bằng service thật của Dev A, giữ nguyên interface `checkMembership(userId, conversationId)` |
| Dev B chưa xong Paywall/Quota | Dev A cần like quota; Dev C cần healing premium check; Dev D cần subscription view | Dev A vẫn làm swipe/match/chat core với paywall stub; Dev C vẫn làm healing content với premium flag mock; Dev D vẫn làm admin screens với mock subscription data | Dùng `PaywallPort` stub trả `allowed=true` hoặc payload mẫu; không tự define payload mới ngoài shape đã ghi | Đổi implementation stub sang Dev B service, giữ nguyên payload fields |
| Dev C chưa xong Healing/Affiliate | Dev B thiếu healing context cho AI; Dev D thiếu affiliate model admin CRUD | Dev A không bị chặn; Dev B vẫn làm AI bằng context builder có `healingCheckIn=null`; Dev D vẫn làm admin shell và moderation/report | Dev B dùng nullable healing context; Dev D dùng affiliate course mock theo model đã thống nhất | Khi Dev C xong, Dev B đọc latest check-in thật; Dev D nối admin CRUD vào API thật |
| Dev D chưa xong Admin/Moderation | Dev A thiếu report persistence/evidence; Dev C thiếu affiliate admin; Dev 1 thiếu moderation status cho discover | Dev A vẫn làm report endpoint với `ReportPort` stub; Dev C vẫn làm affiliate display; Dev B không bị chặn | Dev A lưu report theo interface mock/in-memory/test fixture; Dev C seed affiliate courses tạm; moderation status default `approved` trong dev env | Khi Dev D xong, thay stub bằng report/moderation/admin services thật, không đổi endpoint consumer |
| Dev 1 chưa xong Profile/Discover | Dev B thiếu profile/shared interests cho AI; Dev A discover action UI có thể chưa đủ data; Dev D moderation status chưa được consume | Dev A vẫn test swipe/match bằng seed users; Dev B vẫn làm AI context với profile stub; Dev C/D không bị chặn | Dùng seed users/profiles và `ProfileContextPort` stub cho AI | Khi Dev 1 xong, Dev B nối context builder vào profile/discover service thật |

## Interface Stub Bắt Buộc Để Không Chặn Nhau

| Interface/stub | Owner thật | Dev dùng khi owner chưa xong | Shape tối thiểu | Mục đích |
|---|---|---|---|---|
| `PaywallPort` | Dev B | Dev A, Dev C | `{ allowed, payload?: { code, blockedFeature, message, upgradeOptions, currentTier, mockPremium } }` | Dev A/C không cần chờ Paywall thật để làm flow. |
| `ConversationMembershipPort` | Dev A | Dev B | `{ isMember: boolean }` | Dev B test AI auth/membership mà không cần chat hoàn chỉnh. |
| `ReportPort` | Dev D | Dev A | `{ reportId, status }` | Dev A làm report action trước khi admin/report persistence hoàn chỉnh. |
| `HealingContextPort` | Dev C | Dev B | `{ mood, readiness, needs, trigger, smallGoal, timestamp } | null` | Dev B build AI context dù healing chưa xong. |
| `SubscriptionStatePort` | Dev B | Dev D, Dev C, Dev A | `{ tier, status, mockPremium, limits }` | Admin/healing/like quota đọc được subscription state mẫu. |
| `ModerationStatusPort` | Dev D | Dev 1, Dev A, Dev C | `{ status, visibilityAllowed, reason? }` | Discover/report/healing biết profile/content có được hiển thị không. |

## Ví Dụ Không Bị Chặn

| Tình huống | Cách xử lý đúng |
|---|---|
| Dev A chưa có conversation membership service | Dev B vẫn hoàn thành `POST /api/v1/ai/suggest` với `ConversationMembershipPort` stub; test quota, rate limit, provider call, paywall vẫn chạy. Khi Dev A xong, chỉ thay adapter. |
| Dev B chưa có quota service | Dev A vẫn hoàn thành like/pass/match/confirm/chat flow với `PaywallPort` stub `allowed=true`. Khi Dev B xong, bật quota thật trước khi ghi like. |
| Dev C chưa có healing check-in | Dev B vẫn build AI context với `healingCheckIn=null`, bảo đảm AI không crash khi thiếu data. Khi Dev C xong, thêm latest check-in thật. |
| Dev D chưa có report queue | Dev A vẫn tạo report qua `ReportPort` stub và trả reportId giả trong test. Khi Dev D xong, nối persistence/admin queue thật. |
| Dev D chưa có moderation status | Dev 1/Dev A dùng default `visibilityAllowed=true` trong dev/test fixture. Khi Dev D xong, discover/chat dùng status thật để exclude unsafe profiles. |

## File/Module Ownership Đề Xuất

| Area | Owner | Đường dẫn dự kiến | Giải thích |
|---|---|---|---|
| Swipe/Match/Block/Conversation/Chat APIs | Dev A | `bondy_server/src/app/api/swipe`, `matches`, `blocks`, `conversations`, `messages`, `chats` | Tất cả API tạo luồng match-chat nằm cùng owner. |
| Match/Chat services | Dev A | `bondy_server/src/service/match*`, `conversation*`, `chat*`, `block*` | Business logic match/chat không phân tán. |
| Chat Flutter | Dev A | `Bondy_App/lib/screens/chat`, chat services/viewmodels | UI chat consume đúng API Dev A. |
| AI/Subscription/Paywall APIs | Dev B | `bondy_server/src/app/api/ai`, `subscription` | AI và paywall/quota đi cùng nhau vì liên quan giới hạn sử dụng. |
| AI/Quota/Paywall services | Dev B | `bondy_server/src/service/ai*`, `feature*`, `quota*`, `paywall*`, `subscription*` | Một owner cho quota/paywall để không lệch rule. |
| AI/Paywall Flutter | Dev B | `Bondy_App/lib/widgets/ai_*`, `screens/settings/premium_paywall_screen.dart`, subscription services | AI sheet và paywall UI cùng consume payload Dev B. |
| Healing/Affiliate APIs | Dev C | `bondy_server/src/app/api/healing`, `affiliate-courses` | Healing và affiliate là cùng trải nghiệm user. |
| Healing/Affiliate services | Dev C | `bondy_server/src/service/healing*`, `affiliate*` | Personalization và course suggestion nằm chung owner. |
| Healing Flutter | Dev C | `Bondy_App/lib/screens/healing`, healing services/viewmodels | UI healing không đụng chat/admin logic. |
| Admin/Moderation APIs | Dev D | `bondy_server/src/app/api/admin`, moderation/reports/logs routes | Admin route gom một owner để dễ audit/permission. |
| Admin/Moderation services | Dev D | `bondy_server/src/service/moderation*`, `admin*`, `report*`, `audit*` | Moderation, report, audit liên quan chặt với nhau. |
| Admin Flutter | Dev D | `Bondy_App/lib/screens/admin`, admin services/viewmodels | Admin UI không trộn vào customer UI. |

## Điểm Check Conflict Trước Khi Merge

| Câu hỏi | Nếu có thì sync với owner | Giải thích |
|---|---|---|
| Có sửa conversation/match/chat flow không? | Dev A | Tránh phá rule confirm-before-conversation. |
| Có sửa paywall/quota/subscription payload không? | Dev B | Tránh Flutter nhận nhiều shape paywall khác nhau. |
| Có sửa healing/affiliate content model không? | Dev C | Tránh admin và healing UI lệch model course/disclaimer. |
| Có sửa report/evidence/moderation/admin action không? | Dev D | Tránh mất audit log hoặc retention rule. |
| Có sửa Prisma model shared không? | Owner model liên quan + schema merge lead. | Tránh tạo trùng bảng/relation/index. |
| Có thêm message type mới không? | Dev A + Dev B nếu liên quan AI. | Chat enum phải thống nhất với AI suggested message. |
| Có dùng healing data trong AI context không? | Dev B + Dev C. | AI context cần đúng field healing check-in. |
| Có hiện subscription/mock premium trong admin không? | Dev D + Dev B. | Admin phải đọc đúng subscription state. |

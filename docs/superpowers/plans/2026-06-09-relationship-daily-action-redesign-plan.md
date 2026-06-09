# Tách biệt Luồng Hành động nhỏ và Check-in Cảm xúc Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tách biệt hoàn toàn luồng Hành động nhỏ hôm nay (gửi tin nhắn chat cảm ơn kèm gợi ý) và luồng Check-in cảm xúc (bento card dẫn sang màn check-in riêng biệt).

**Architecture:** 
- Khởi tạo `ChatService` và `ApiClient` bên trong `RelationshipHomeDashboard` để gửi tin nhắn.
- Nút "Thực hiện" trên Daily Action card mở ra một dialog tùy chỉnh cho phép chọn mẫu tin nhắn cảm ơn hoặc tự nhập nội dung gửi qua chat, sau đó cập nhật Daily Action sang `SKIPPED` để ẩn card.
- Bento card "Bạn" trong "Cảm xúc của chúng mình" khi chưa check-in sẽ hiển thị dạng nút "Check-in ngay" màu san hô và cho phép nhấn vào để điều hướng sang màn check-in cảm xúc.

**Tech Stack:** Flutter, Dart, Provider

---

## Các thay đổi chi tiết

### Task 1: Khai báo dịch vụ Chat và ApiClient trong Dashboard State
**Files:**
- Modify: [relationship_home_dashboard.dart](file:///c:/Users/THANGND/EXE_Project/bondy_app/lib/screens/relationship/relationship_home_dashboard.dart)

- [ ] **Step 1: Thêm import dịch vụ chat**
  Thêm import `../../services/chat_service.dart` và `../../services/api_client.dart` ở phần đầu file.

- [ ] **Step 2: Khai báo instance trong State**
  Khai báo `_apiClient` và `_chatService` bên trong lớp `_RelationshipHomeDashboardState`:
  ```dart
  late final ApiClient _apiClient = ApiClient();
  late final ChatService _chatService = ChatService(_apiClient);
  ```

---

### Task 2: Cập nhật giao diện Bento Card "Cảm xúc của chúng mình"
**Files:**
- Modify: [relationship_home_dashboard.dart](file:///c:/Users/THANGND/EXE_Project/bondy_app/lib/screens/relationship/relationship_home_dashboard.dart)

- [ ] **Step 1: Sửa đổi phần render Bento cho Bạn**
  Thay đổi phần hiển thị của widget "Bạn" khi `myCheckin` bằng `null`:
  - Bọc bằng `GestureDetector` có `onTap` dẫn sang màn check-in cảm xúc.
  - Sử dụng màu nền `0xFFFFF5F5` khi chưa check-in, viền màu san hô nhạt.
  - Hiển thị avatar tròn chứa icon dấu cộng `+` và text trạng thái màu coral "Check-in ngay".

---

### Task 3: Xây dựng Dialog nhập liệu và gửi tin nhắn cho Hành động nhỏ hôm nay
**Files:**
- Modify: [relationship_home_dashboard.dart](file:///c:/Users/THANGND/EXE_Project/bondy_app/lib/screens/relationship/relationship_home_dashboard.dart)

- [ ] **Step 1: Cập nhật nút "Thực hiện"**
  Cập nhật thuộc tính `onPressed` của nút "Thực hiện" trên Daily Action card để gọi hàm `_showDailyActionDialog(action)`.

- [ ] **Step 2: Triển khai hàm `_showDailyActionDialog`**
  Viết phương thức `_showDailyActionDialog(RelationshipDailyAction action)`:
  - Hiển thị một `AlertDialog` sử dụng font `GoogleFonts.plusJakartaSans`.
  - Hiển thị danh sách gợi ý ngang (Horizontal list of Chips) nếu `action.actionKey == 'gratitude_note'`.
  - Có TextField để soạn tin nhắn. Khi người dùng click vào một gợi ý, điền nội dung gợi ý đó vào TextField.
  - Nút "Gửi": hiển thị trạng thái loading, lấy danh sách chat qua `_chatService.listChats()`, tìm chat của đối phương (`partnerId`), gọi `sendMessage` để gửi tin nhắn, sau đó gọi `_viewModel.setDailyActionState(status: RelationshipDailyActionStatus.skipped)` để ẩn card, reload dashboard và đóng Dialog.

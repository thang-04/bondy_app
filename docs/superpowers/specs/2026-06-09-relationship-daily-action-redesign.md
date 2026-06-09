# Thiết kế: Tách biệt Luồng Hành động nhỏ hôm nay và Check-in cảm xúc

Tài liệu này đặc tả sự thay đổi kỹ thuật để tách biệt hoàn toàn hai luồng:
1. **Check-in cảm xúc:** Thực hiện trực tiếp bằng cách nhấn bento card "Bạn" trong phần "Cảm xúc của chúng mình".
2. **Hành động nhỏ hôm nay:** Nhấn "Thực hiện" hiển thị Pop-up nhập lời cảm ơn/lời nhắn ngắn kèm gợi ý và gửi thẳng vào Chat với đối phương, sau đó ẩn card đi.

---

## 1. Thiết kế Giao diện & Trải nghiệm (UI/UX)

### 1.1 Bento Card "Cảm xúc của chúng mình" khi chưa Check-in
* Khi người dùng hiện tại chưa check-in cảm xúc hôm nay:
  - Hiển thị phần "Bạn" với phong cách nổi bật mời gọi: màu nền đỏ nhạt (`0xFFFFF5F5`), viền san hô nhạt, avatar tròn chứa dấu cộng `+`, và text trạng thái màu đỏ san hô "Check-in ngay".
  - Khi người dùng nhấn vào toàn bộ ô "Bạn" này, ứng dụng sẽ điều hướng sang màn hình `/relationship/checkin`.
* Khi đã check-in: hiển thị thông thường như trước.

### 1.2 Pop-up "Hành động nhỏ hôm nay"
* Khi nhấn nút **"Thực hiện"** trên card Daily Action:
  - Hiển thị một `AlertDialog` tại chỗ.
  - Chứa danh sách tin nhắn gợi ý ngang (Horizontal Chips) tùy thuộc vào `actionKey`.
  - Có ô nhập tin nhắn (TextField) được tự động điền khi nhấn vào một gợi ý, hoặc người dùng tự gõ.
  - Nút "Gửi tin nhắn" sẽ thực hiện:
    1. Tải danh sách chat để tìm `chatId` khớp với `partnerId`.
    2. Gửi tin nhắn chứa nội dung đã nhập vào phòng chat đó thông qua `ChatService.sendMessage()`.
    3. Cập nhật trạng thái Daily Action sang `SKIPPED` để ẩn card trên Dashboard thông qua `setDailyActionState(status: skipped)`.
    4. Tải lại Dashboard và hiển thị SnackBar thành công.

---

## 2. Các thay đổi mã nguồn đề xuất

### 2.1 Cập nhật màn hình Dashboard
#### [MODIFY] [relationship_home_dashboard.dart](file:///c:/Users/THANGND/EXE_Project/bondy_app/lib/screens/relationship/relationship_home_dashboard.dart)
- Khởi tạo thêm `ApiClient` và `ChatService` để thực hiện gửi tin nhắn.
- Cập nhật hàm `_buildDailyActionCard` để khi nhấn "Thực hiện" sẽ gọi hàm `_showDailyActionDialog(action)`.
- Triển khai hàm `_showDailyActionDialog(action)` để vẽ popup gửi tin nhắn, kèm theo logic lấy `chatId` từ `ChatService.listChats()` dựa trên `partnerId`.
- Cập nhật hàm `_buildEmotionsBento` để khi người dùng chưa check-in sẽ hiển thị bento card dạng nút "Check-in ngay" có thể click được.

---

## 3. Kế hoạch xác minh

### Kiểm thử thủ công:
1. **Xác minh luồng Check-in:** Mở Dashboard khi chưa check-in cảm xúc -> Xác nhận bento "Bạn" hiển thị dạng "Check-in ngay" màu san hô -> Nhấn vào sẽ chuyển sang màn Check-in.
2. **Xác minh luồng Hành động nhỏ:** Nhấn "Thực hiện" trên card Hành động nhỏ -> Dialog mở ra kèm gợi ý -> Chọn một gợi ý -> Nhấn "Gửi" -> Card biến mất trên Dashboard, đồng thời tin nhắn xuất hiện trong phòng chat với đối phương.

# Thiết kế màn hình Loading khởi động và Thanh chỉ số chuyển ảnh

Tài liệu thiết kế chi tiết cho việc tối ưu hoá trải nghiệm người dùng (UX) trên màn hình chi tiết hồ sơ (ProfileDetailScreen) và màn hình khởi động (AuthGateScreen).

## 1. Mục tiêu
- **Tối ưu trải nghiệm chuyển ảnh**: Sửa lỗi thanh chỉ số ảnh bị đè lên mặt người dùng, quá to và đặt không hợp lý trên màn hình chi tiết hồ sơ.
- **Tạo ấn tượng khởi động đẹp mắt**: Thiết kế lại màn hình loading đầu tiên khi mở ứng dụng với nền gradient chuyển sắc thương hiệu, logo co giãn nhẹ (pulse animation) và vòng xoay tải thanh lịch.

## 2. Thiết kế chi tiết

### 2.1. Thanh chỉ số ảnh trên màn hình chi tiết hồ sơ
- **Tập tin**: [profile_detail_screen.dart](file:///c:/Users/THANGND/EXE_Project/bondy_app/lib/screens/discover/profile_detail_screen.dart)
- **Thay đổi vị trí**:
  - Chuyển `top: 100` thành `top: MediaQuery.of(context).padding.top + 12`.
  - Đảm bảo thanh chỉ số nằm sát viền trên cùng của màn hình, trên nút quay lại và nút báo cáo, khớp với tỷ lệ màn hình thực tế.
- **Thay đổi kích thước**:
  - Giảm độ dày `height` từ `3` xuống `2`.
  - Giữ lại hiệu ứng màu sắc tương phản (`Colors.white` cho ảnh hiện tại và `Colors.white.withValues(alpha: 0.4)` cho ảnh khác).

### 2.2. Màn hình Loading khởi động (AuthGateScreen)
- **Tập tin**: [auth_gate_screen.dart](file:///c:/Users/THANGND/EXE_Project/bondy_app/lib/screens/auth/auth_gate_screen.dart)
- **Giao diện nền (Background)**:
  - Thay thế màu nền kem tĩnh `HealingStitchColors.warmBackground` bằng gradient thương hiệu đầy sắc màu `BondyColors.signatureGradient`.
- **Hoạt họa Logo (Pulse Animation)**:
  - Sử dụng widget `SingleTickerProviderStateMixin` và `AnimationController`.
  - Logo `assets/images/logo.png` co giãn nhịp nhàng (scale từ `0.94` đến `1.04`) kết hợp thay đổi độ trong suốt nhẹ nhàng trong chu kỳ 2 giây lặp đi lặp lại.
- **Trạng thái tải (Loading State Indicator)**:
  - Hiển thị một `CircularProgressIndicator` màu trắng nét mảnh (`strokeWidth: 2`) ngay bên dưới logo với khoảng cách hợp lý.
  - Sử dụng văn bản trạng thái màu trắng mờ thanh lịch: *"Đang khôi phục phiên..."*.

## 3. Kế hoạch xác minh (Verification Plan)
- Chạy ứng dụng trên thiết bị giả lập hoặc thực tế.
- Kiểm tra trực quan màn hình khởi động (AuthGateScreen): xác minh gradient hiển thị đúng toàn màn hình, logo có hiệu ứng hoạt họa pulse mượt mà, văn bản hiển thị rõ ràng.
- Kiểm tra màn hình chi tiết hồ sơ (`ProfileDetailScreen`): mở chi tiết một hồ sơ bất kỳ từ màn hình Discover, xác minh thanh ngang chuyển ảnh nằm sát viền trên (ở vị trí status bar) và hiển thị thanh mảnh.

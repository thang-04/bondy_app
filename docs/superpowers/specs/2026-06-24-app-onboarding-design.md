# Đặc tả Thiết kế: Tính năng Hướng dẫn Sử dụng App (Onboarding & Swipe Tutorial)

Tài liệu này đặc tả thiết kế và kiến trúc triển khai hệ thống hướng dẫn sử dụng đơn giản (Interactive Showcase Tour) dành cho các tài khoản mới trên Bondy App.

---

## 1. Mục tiêu & Kịch bản Trải nghiệm (UI/UX Flow)

Hệ thống hướng dẫn được chia thành 2 giai đoạn nối tiếp nhau nhằm tối ưu hóa trải nghiệm làm quen của người dùng mới mà không gây phiền nhiễu:

### Giai đoạn 1: Hướng dẫn trên Màn hình chính (`MainShellScreen`)
*   **Kịch bản (Core Tour):** 
    *   **Bước 1 (Match FAB):** Bong bóng tooltip chỉ vào nút Trái tim nổi ở giữa thanh Bottom Navigation Bar để hướng dẫn người dùng bấm vào tìm bạn.
    *   **Bước 2 (Healing Tab):** Bong bóng tooltip chỉ vào nút Healing (icon trái tim y tế) ở tab thứ 2 để hướng dẫn tham gia thử thách cặp đôi.
*   **Cơ chế kích hoạt:** Tự động hiển thị sau khi người dùng đăng nhập lần đầu và UI màn hình chính render xong (trễ 800ms).
*   **Lưu trạng thái:** Lưu biến boolean `has_seen_main_onboarding = true` cục bộ thông qua `SharedPreferences`.

### Giai đoạn 2: Hướng dẫn trên Màn hình Khám phá (`DiscoverMatchingScreen`)
*   **Kịch bản (Swipe & Action Buttons Tour):**
    *   Hiển thị một màn che mờ (Overlay) toàn màn hình khi người dùng chuyển sang tab Match lần đầu tiên.
    *   Hiển thị hoạt họa ngón tay quẹt trượt sang phải để minh họa cử chỉ quẹt (Quẹt phải: Thích 💚, Quẹt trái: Bỏ qua ❌).
    *   Bong bóng hướng dẫn chỉ xuống **4 nút tương tác nhanh** dưới cùng (Hoàn tác, Pass, Super Like, Like) để giới thiệu cách tương tác nhanh không cần quẹt.
*   **Cơ chế kích hoạt:** Tự động hiển thị khi nạp xong dữ liệu profile đầu tiên trên màn hình Discover.
*   **Lưu trạng thái:** Lưu biến boolean `has_seen_swipe_tutorial = true` cục bộ thông qua `SharedPreferences`.

---

## 2. Giải pháp Kỹ thuật & Kiến trúc (Technical Design)

Chúng ta sử dụng giải pháp **Tự xây dựng Custom Overlay** bằng công cụ gốc của Flutter thay vì dùng thư viện bên ngoài. Giải pháp này giúp dễ dàng tùy biến giao diện gradient, bo góc tròn và kiểm soát luồng điều phối chính xác mà không làm nặng app.

### 2.1 Cấu trúc Lớp mới (New Classes)

Toàn bộ logic dùng chung của Showcase sẽ được đặt trong thư mục mới `lib/widgets/onboarding/`:

1.  **`showcase_step.dart`:** Model định nghĩa dữ liệu cho mỗi bước chỉ dẫn.
    ```dart
    enum ShowcasePosition { top, bottom }

    class ShowcaseStep {
      final GlobalKey targetKey;
      final String title;
      final String content;
      final String icon;
      final ShowcasePosition position;

      ShowcaseStep({
        required this.targetKey,
        required this.title,
        required this.content,
        required this.icon,
        this.position = ShowcasePosition.top,
      });
    }
    ```

2.  **`hole_painter.dart`:** Vẽ lớp phủ mờ màu đen và đục một lỗ tròn/chữ nhật bo góc tại tọa độ của widget mục tiêu.
    *   Sử dụng `Path.combine(PathOperation.difference, backgroundPath, holePath)` để đục lỗ.
    *   Tự động tính toán toạ độ và kích thước dựa trên `GlobalKey` của widget.

3.  **`onboarding_tooltip.dart`:** Widget bong bóng tooltip hiển thị nội dung hướng dẫn.
    *   Giao diện sử dụng Font `Plus Jakarta Sans`, gradient `cam-hồng` (`Color(0xFFFF6B6B)` đến `Color(0xFFFFB28E)`), bo góc tròn (`borderRadius: BorderRadius.circular(16)`), có bóng đổ mịn.
    *   Bao gồm chỉ số bước (ví dụ: "Bước 1/2"), nút "Bỏ qua" (Skip), nút "Tiếp tục" (Next) và chấm dot indicator.

4.  **`onboarding_overlay.dart`:** Controller điều phối việc hiển thị `OverlayEntry`.
    *   Cung cấp phương thức: `static void show(BuildContext context, {required List<ShowcaseStep> steps, VoidCallback? onCompleted})`.
    *   Tự động tính toán vị trí hiển thị của bong bóng chỉ dẫn (tránh bị lệch hoặc tràn màn hình).

5.  **`swipe_tutorial_overlay.dart`:** Widget Overlay che phủ màn hình Discover.
    *   Hiển thị hoạt họa di chuyển ngón tay bằng `AnimationController`.
    *   Vẽ 2 khu vực trái/phải để hướng dẫn cử chỉ.
    *   Hiển thị tooltip đục lỗ trỏ vào thanh 4 nút tương tác dưới cùng.

---

## 3. Danh sách các file thay đổi (Codebase Modifications)

### Các file cần tạo mới [NEW]
*   [NEW] [showcase_step.dart](file:///c:/Users/THANGND/EXE_Project/bondy_app/lib/widgets/onboarding/showcase_step.dart)
*   [NEW] [hole_painter.dart](file:///c:/Users/THANGND/EXE_Project/bondy_app/lib/widgets/onboarding/hole_painter.dart)
*   [NEW] [onboarding_tooltip.dart](file:///c:/Users/THANGND/EXE_Project/bondy_app/lib/widgets/onboarding/onboarding_tooltip.dart)
*   [NEW] [onboarding_overlay.dart](file:///c:/Users/THANGND/EXE_Project/bondy_app/lib/widgets/onboarding/onboarding_overlay.dart)
*   [NEW] [swipe_tutorial_overlay.dart](file:///c:/Users/THANGND/EXE_Project/bondy_app/lib/widgets/onboarding/swipe_tutorial_overlay.dart)

### Các file cần sửa đổi [MODIFY]
*   [MODIFY] [bondy_bottom_nav_bar.dart](file:///c:/Users/THANGND/EXE_Project/bondy_app/lib/widgets/navigation/bondy_bottom_nav_bar.dart): Bổ sung tham số `matchKey` và `healingKey`, gán chúng vào các widget nút Match và nút Healing tương ứng trên thanh điều hướng.
*   [MODIFY] [main_shell_screen.dart](file:///c:/Users/THANGND/EXE_Project/bondy_app/lib/screens/home/main_shell_screen.dart):
    *   Khai báo `_matchKey` và `_healingKey`.
    *   Truyền key vào `BondyBottomNavBar`.
    *   Kiểm tra `SharedPreferences` và kích hoạt `OnboardingOverlay.show(...)` khi khởi tạo.
*   [MODIFY] [discover_matching_screen.dart](file:///c:/Users/THANGND/EXE_Project/bondy_app/lib/screens/discover/discover_matching_screen.dart):
    *   Gán một `GlobalKey` vào cụm 4 nút tương tác dưới cùng.
    *   Kích hoạt `SwipeTutorialOverlay` che phủ lên trên màn hình khi dữ liệu profile tải xong và người dùng chưa xem hướng dẫn.

---

## 4. Kế hoạch Kiểm thử & Xác minh (Verification Plan)

### Kiểm thử Tự động
*   Viết Unit Test cho `ShowcaseStep` để đảm bảo khởi tạo đúng dữ liệu.
*   Viết Widget Test kiểm tra `OnboardingTooltip` hiển thị đúng nội dung title, content và các nút bấm.

### Kiểm thử Thủ công (Manual Verification)
1.  **Chạy trên máy ảo/thiết bị thực:**
    *   Đăng nhập tài khoản mới tinh (hoặc xóa dữ liệu app/clear cache).
    *   Kiểm tra xem khi vào trang chủ, Overlay có xuất hiện và đục lỗ chính xác tại nút Match & Healing không.
    *   Thử bấm nút "Tiếp tục" để kiểm tra tính năng chuyển bước hoạt động trơn tru.
    *   Thử bấm nút "Bỏ qua" để kiểm tra đóng Overlay lập tức.
2.  **Kiểm tra SharedPreferences:**
    *   Tắt app đi mở lại sau khi đã xem hướng dẫn, đảm bảo hướng dẫn không hiển thị lại nữa.
3.  **Kiểm tra hướng dẫn quẹt thẻ:**
    *   Nhấp vào nút Match để mở màn hình Discover.
    *   Kiểm tra xem Overlay hướng dẫn quẹt thẻ và 4 nút tương tác dưới cùng có hiển thị chính xác không.
    *   Bấm "Bắt đầu khám phá" và thử quẹt thẻ để kiểm tra độ phản hồi của app.

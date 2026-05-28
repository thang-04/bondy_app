# Tài Liệu Thiết Kế: Hệ Thống Profile Phong Cách Bento Grid Hiện Đại

Tài liệu này mô tả chi tiết thiết kế mới cho hai màn hình Profile trong ứng dụng Bondy: Màn hình Profile cá nhân (`_ProfileTab` thuộc `MainShellScreen`) và Màn hình chi tiết Profile của đối phương (`ProfileDetailScreen`). Phong cách chủ đạo là Bento Grid tối giản, hiện đại và cao cấp, mang lại trải nghiệm thị giác sống động và phân cấp thông tin rõ ràng.

## 1. Mục Tiêu Thiết Kế
*   **Hiện đại hóa giao diện:** Thay thế các danh sách phẳng và các khối thông tin rời rạc truyền thống bằng bố cục lưới Bento linh hoạt, có chiều sâu.
*   **Tăng tính tương tác (Gamification):** Sử dụng các gam màu pastel nhẹ nhàng, biểu tượng sinh động để làm nổi bật các chỉ số thống kê (Streak, Kết nối) và các thông tin quan trọng.
*   **Trải nghiệm cao cấp (Premium UI/UX):** Áp dụng hiệu ứng kính mờ (Glassmorphic), đổ bóng mềm (Soft shadow), typography đồng bộ (`Plus Jakarta Sans`) và hiệu ứng rung nhẹ (Haptic feedback) khi tương tác.

---

## 2. Chi Tiết Thiết Kế Giao Diện

### 2.1. Màn Hình Profile Cá Nhân (`_ProfileTab` trong `main_shell_screen.dart`)
Bố cục được chia thành các khối Bento rõ ràng từ trên xuống dưới:

1.  **Bento Box 1: Thông tin cá nhân chính (Avatar & Name Card)**
    *   **Cấu trúc:** Một card Bento lớn bo góc `24dp`, nền trắng (`Colors.white`), có đổ bóng mờ mịn màng (`BoxShadow` có blur radius lớn, màu shadow rất nhạt).
    *   **Avatar:** Kích thước `90dp`. Viền kép tinh tế (Double border) màu primary. Nếu thiếu ảnh đại diện, avatar placeholder sẽ hiển thị chữ cái đầu tiên trên nền màu Gradient mượt mà chuyển sắc từ Tím sang Hồng ấm (thay vì màu đơn sắc phẳng).
    *   **Thông tin:** Display name font `Plus Jakarta Sans`, size `22dp`, `FontWeight.w700`. Email và bio hiển thị ngăn nắp.
    *   **Action nhanh:** Icon nút "Chỉnh sửa" dạng hình tròn xám mờ ở góc trên bên phải để mở nhanh màn hình chỉnh sửa hồ sơ.
2.  **Bento Box 2: Chỉ số Stats (Stats Grid Row)**
    *   Gồm 3 ô Bento xếp ngang với màu nền pastel đặc trưng:
        *   **Streak ngày (Chiếm 40%):** Nền màu cam pastel nhạt (`0xFFFFF5F0`). Hiển thị số ngày streak lớn màu cam đậm, icon ngọn lửa sống động và nhãn "Ngày streak".
        *   **Kết nối (Chiếm 30%):** Nền màu hồng pastel nhạt (`0xFFFFF0F5`). Hiển thị số lượng kết nối lớn màu hồng đỏ, icon trái tim nhỏ và nhãn "Kết nối".
        *   **Tuần này (Chiếm 30%):** Nền màu tím pastel nhạt (`0xFFF5F3FF`). Hiển thị số hoạt động tuần lớn màu tím đậm, icon tick tiến độ và nhãn "Tuần này".
3.  **Bento Box 3: Nhóm các menu chức năng (Bento Group Cards)**
    *   Gom 9 ListTile rời rạc hiện tại thành 3 nhóm thẻ Bento lớn bo góc `20dp`, nền trắng. Các menu item bên trong phân tách bằng divider siêu mỏng (`0.5dp` với độ mờ cao):
        *   **Nhóm 1 (Cá nhân hóa & Premium):** *Sở thích* (Icon: Trái tim ấm), *Mối quan hệ của tôi* (Icon: Hai người kết nối), *Bondy Premium* (Icon: Ngôi sao vàng gradient kèm Badge "PRO" màu vàng nổi bật bên phải).
        *   **Nhóm 2 (Bảo mật & Thiết lập):** *Đổi mật khẩu* (Icon: Khóa bảo mật), *Quyền riêng tư* (Icon: Lá chắn), *Thông báo* (Icon: Chuông).
        *   **Nhóm 3 (Hỗ trợ & Thông tin):** *Trợ giúp* (Icon: Trung tâm trợ giúp), *Về Bondy* (Icon: Thông tin).
4.  **Bento Box 4: Nút Đăng xuất**
    *   Nút Outlined mỏng màu đỏ cam nhã nhặn, bo góc `16dp`, đặt độc lập ở cuối danh sách.

### 2.2. Màn Hình Chi Tiết Profile Đối Phương (`ProfileDetailScreen` trong `profile_detail_screen.dart`)
Tổ chức lại thông tin chi tiết dưới dạng Bento Grid nghệ thuật:

1.  **Hero Header (Ảnh bìa chính)**
    *   Ảnh bìa được bo góc dưới cực lớn (`32dp`) để tách biệt rõ ràng với phần nội dung bên dưới.
    *   Overlay Gradient chuyển tiếp mịn màng ở đáy ảnh để hiển thị Tên, Tuổi, Trạng thái online xanh lá rõ nét.
    *   Chip khoảng cách (ví dụ: `Cách bạn 5 km`) được thiết kế dạng kính mờ (Glassmorphic) màu trắng trong suốt, viền mỏng màu trắng.
2.  **Bento Grid Layout chi tiết**
    *   **Hàng 1 (Hai ô Bento nhỏ 50% - 50%):**
        *   **Ô Tương thích (Match %):** Nền hồng pastel nhạt (`0xFFFFF0F5`), số phần trăm tương thích lớn màu hồng đỏ kèm icon trái tim.
        *   **Ô Mục tiêu (Dating Goal):** Nền tím pastel nhạt (`0xFFF5F3FF`), biểu tượng mục tiêu (Hẹn hò tìm hiểu, Lâu dài...) kèm icon trái tim đôi và font chữ đậm.
    *   **Hàng 2 (Ô lớn 100%): Gợi ý mở lời (Icebreaker)**
        *   Nền màu vàng/cam pastel ấm áp (`0xFFFEF3C7`). Tiêu đề "GỢI Ý MỞ LỜI" in hoa màu cam đậm kèm icon bóng đèn. Câu mở lời được đặt trong dấu ngoặc kép in nghiêng tinh tế.
    *   **Hàng 3 (Ô lớn 100%): Giới thiệu (Bio)**
        *   Card trắng bo góc `24dp` với khoảng cách dòng thoáng đãng, mang đến trải nghiệm đọc thư thái.
    *   **Hàng 4 (Ô lớn 100%): Sở thích (Interests)**
        *   Card chứa các tag sở thích. Mỗi tag sẽ có màu nền pastel ngẫu nhiên tinh tế (tông xanh, hồng, vàng dịu xen kẽ) thay vì chỉ một màu đơn sắc, giúp hiển thị trẻ trung và sinh động hơn.
    *   **Hàng 5 (Ô lớn 100%): Thư viện ảnh (Photo Gallery)**
        *   Danh sách ảnh thumbnail bo góc `16dp` nằm ngang. Ảnh đang chọn hiển thị viền màu primary nổi bật.
3.  **Nút FAB Tương Tác (Thả Tim)**
    *   Nút FAB to tròn (`60dp`), nền gradient Hồng đào sang Đỏ san hô, đổ bóng phát sáng (glow shadow) cùng tông màu. Có hoạt ảnh co giãn (Scale transition) và haptic feedback khi tương tác.

---

## 3. Kỹ Thuật Triển Khai Trong Flutter

### 3.1. Các màu sắc và UI Token đề xuất
Chúng ta sẽ sử dụng các màu sắc có sẵn hoặc bổ sung các màu pastel chuyên biệt vào giao diện để đảm bảo tính đồng bộ:
*   `BondyColors.primary` và `BondyColors.primaryLight`
*   Màu pastel bổ sung:
    *   Cam Pastel: `Color(0xFFFFF5F0)` / Cam đậm: `Color(0xFFF97316)`
    *   Hồng Pastel: `Color(0xFFFFF0F5)` / Hồng đậm: `Color(0xFFEC4899)`
    *   Tím Pastel: `Color(0xFFF5F3FF)` / Tím đậm: `Color(0xFF8B5CF6)`
    *   Vàng/Cam Pastel: `Color(0xFFFEF3C7)` / Vàng đậm: `Color(0xFFD97706)`
*   Độ cong góc (Border Radius): `24.0` cho card Bento chính, `16.0` cho card nhỏ/thumbnail.
*   Bóng mờ (Soft Shadow):
    ```dart
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 20,
      offset: const Offset(0, 8),
    )
    ```

### 3.2. Widget Cấu Trúc Bento
Chúng ta sẽ xây dựng các helper widget hoặc sử dụng Layout Grid (bằng `Row` và `Column` kết hợp `Expanded` hoặc `Flexible`) để đảm bảo layout co giãn mượt mà trên mọi thiết bị di động có kích thước màn hình khác nhau.

---

## 4. Kế Hoạch Xác Minh (Verification Plan)
1.  **Kiểm tra giao diện trên nhiều kích thước màn hình (Responsive Test):** Đảm bảo Bento Grid hiển thị đúng tỷ lệ, không bị tràn viền hoặc lỗi `overflow pixel` trên các thiết bị màn hình nhỏ (như iPhone SE) và màn hình lớn (như iPhone Pro Max/Pixel XL).
2.  **Kiểm tra trạng thái tải (Loading state) & Lỗi (Error state):** Đảm bảo hiệu ứng skeleton loader hoặc circular indicator hoạt động mượt mà trong khi đang tải dữ liệu profile.
3.  **Kiểm tra tương tác:** Kiểm tra sự mượt mà của hiệu ứng chuyển ảnh thumbnail, hiệu ứng bấm nút menu, nút Like và nút Đăng xuất.

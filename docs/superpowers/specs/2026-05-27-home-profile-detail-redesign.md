# Đặc tả Thiết kế: Tái thiết kế giao diện màn Home & chi tiết Profile

Tài liệu đặc tả này mô tả kế hoạch tái thiết kế giao diện (UI Redesign) cho hai màn hình cốt lõi: màn hình Home (Trang chủ) và màn hình Profile Detail (Chi tiết thông tin đối phương) dựa trên tài nguyên thiết kế từ Stitch (Emotional State Q4).

## Mục tiêu thiết kế
1. **Màn hình Home:** 
   - Tối ưu hóa phong cách Bento Grid hiện đại theo tông màu ấm (`warm cream palette`).
   - Tích hợp **Logo thương hiệu Bondy** (`BondyLogoMini`) vào thanh tiêu đề chính.
   - Thay đổi tiêu đề Mood Check-in từ "Check-in cảm xúc hôm nay" thành **"Hôm nay bạn cảm thấy như thế nào?"** để tăng độ tương tác tự nhiên.
   - Bổ sung mục **"Gợi ý tương thích cao" (Suggested Profiles)** hiển thị danh sách các hồ sơ phù hợp có độ tương thích cao dạng trượt ngang.
2. **Màn hình Profile Detail:**
   - Cập nhật cấu trúc dữ liệu Model `DiscoverProfile` để lưu và hiển thị đầy đủ hình ảnh (`photos`) và mục tiêu hẹn hò (`datingGoal`).
   - Thiết kế lại giao diện theo mẫu Stitch với Hero Image bo góc (`hero-clip`), gợi ý mở lời (Icebreaker), danh sách sở thích và mục tiêu trực quan, thanh trượt ngang thư viện ảnh và nút Like nổi (`floating-action-btn`).

---

## Chi tiết thay đổi đề xuất

### 1. Cấu trúc dữ liệu (Data Layer)
#### `lib/models/discover/discover_profile_model.dart`
*   Thêm trường `List<String> photos` vào class `DiscoverProfile` để lưu danh sách tất cả các URL ảnh từ JSON trả về.
*   Thêm trường `String? datingGoal` đại diện cho mục tiêu hẹn hò (ví dụ: "Mối quan hệ lâu dài", "Muốn tìm người bạn đời").
*   Cập nhật hàm factory `DiscoverProfile.fromJson` để:
    *   Lấy toàn bộ các phần tử `url` từ mảng `photos` trong JSON thay vì chỉ lấy ảnh primary.
    *   Parse trường `datingGoal` từ JSON (ví dụ: `json['datingGoal']` hoặc từ metadata).

---

### 2. Màn hình Trang chủ (Home Dashboard Screen)
#### `lib/screens/home/home_dashboard_screen.dart`
*   **Thanh tiêu đề (`_HomeTopBar`):**
    - Sử dụng `BondyLogoMini(size: 32)` thay cho icon `Icons.bubble_chart_rounded` cũ để hiển thị logo thương hiệu Bondy bên cạnh nhãn "Bondy".
*   **Phần Mood Check-in (`_HealingGateBanner`):**
    - Cập nhật tiêu đề hiển thị từ "Check-in cảm xúc hôm nay" thành **"Hôm nay bạn cảm thấy như thế nào?"**.
*   **Mục Gợi ý Tương thích Cao (`_SuggestedProfilesSection`):**
    - Tạo mới một Widget dạng danh sách trượt ngang (`ListView.builder` chiều ngang) hiển thị các hồ sơ gợi ý.
    - Gọi API `/discover/profiles` thông qua `DiscoverService` để lấy danh sách các profile và sắp xếp theo `matchPercentage` giảm dần.
    - Mỗi thẻ hồ sơ bao gồm ảnh đại diện, phần trăm tương thích dạng nhãn đỏ (ví dụ: "98% Match"), tên, tuổi và khoảng cách.
    - Khi nhấn vào một thẻ hồ sơ, điều hướng đến màn hình chi tiết đối phương `/profile-detail` với argument là đối tượng `DiscoverProfile`.
*   **Bento Grid (`_QuickDiscoveryBento`):**
    - Cập nhật nhãn và subtext:
      - "Kết đôi" -> Subtext: "Tìm tri kỷ"
      - "Chữa lành" -> Subtext: "Thiền & Yoga"
      - "Mối quan hệ" -> Subtext: "Lời khuyên chuyên gia"

---

### 3. Màn hình Chi tiết hồ sơ (Profile Detail Screen)
#### `lib/screens/discover/profile_detail_screen.dart`
*   **Header Hero (`SliverAppBar` / background):**
    - Thiết kế phần ảnh Hero lớn có bo góc tròn bên dưới (`border-bottom-left-radius` và `border-bottom-right-radius` khoảng 30px-40px).
    - Thêm một lớp Gradient đen mờ (`hero-overlay`) phủ lên ảnh từ dưới lên để hiển thị rõ thông tin Tên, Tuổi, Khoảng cách chữ màu trắng đè lên.
*   **Gợi ý mở lời (Icebreaker):**
    - Thêm hộp thoại màu xanh Indigo ở đầu nội dung (`bg-indigo-50/50`, viền `border-indigo-100`) hiển thị lời khuyên giao tiếp: *"Hãy thử hỏi [Tên] về những hoạt động cuối tuần yêu thích..."*.
*   **Phần giới thiệu bản thân & Sở thích:**
    - Cập nhật style chữ, sử dụng font chữ Google Fonts `plusJakartaSans` với khoảng cách dòng và kích thước chữ mềm mại hơn.
*   **Thư viện ảnh trượt ngang (Gallery):**
    - Thêm danh sách trượt ngang các ảnh phụ của người dùng lấy từ `profile.photos`.
    - Hiển thị tối đa 2 ảnh và ảnh cuối có một lớp phủ mờ kèm số lượng ảnh còn lại (ví dụ: `+3`).
*   **Mục tiêu (Goal):**
    - Hiển thị hộp thông tin mục tiêu hẹn hò (`datingGoal`) trực quan với biểu tượng trái tim lớn.
*   **Nút Thích Nổi (Floating Heart Button):**
    - Thêm một nút nổi (`FloatingActionButton` hoặc positioned widget) hình tròn màu gradient từ hồng sang cam nằm đè lên góc phải màn hình để người dùng nhấn Kết nối (LIKE) dễ dàng.

---

## Kế hoạch kiểm thử (Verification Plan)
1. **Kiểm tra giao diện:**
   - Chạy ứng dụng trên máy ảo/thiết bị thật để kiểm tra độ mượt mà của layout Bento Grid, thanh trượt hồ sơ gợi ý trên màn Home và thanh trượt ảnh ngang trên màn Profile Detail.
   - Đảm bảo hiển thị đúng Logo thương hiệu ở TopBar của màn Home.
2. **Kiểm tra luồng dữ liệu:**
   - Kiểm tra xem dữ liệu danh sách ảnh và mục tiêu của đối phương có được parse chính xác từ API backend thông qua `DiscoverProfile.fromJson`.
   - Kiểm tra tính năng chuyển hướng khi click vào thẻ gợi ý trên màn Home sang màn Profile Detail có truyền đúng đối tượng profile.

# Kế hoạch triển khai sửa lỗi thanh chỉ số ảnh và thiết kế lại màn hình loading khởi động

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tối ưu hóa vị trí thanh chỉ số ảnh trên màn hình chi tiết hồ sơ và thiết kế lại màn hình loading khởi động với giao diện gradient, logo có hiệu ứng pulse sang trọng.

**Architecture:** Màn hình chi tiết hồ sơ sẽ sử dụng chiều cao status bar từ MediaQuery để đặt vị trí thanh chỉ số sát mép trên. Màn hình loading sẽ tích hợp AnimationController và Ticker để tạo hiệu ứng co giãn (pulse) cho logo, đồng thời phủ nền gradient toàn màn hình.

**Tech Stack:** Flutter, Dart, AnimationController, ScaleTransition.

---

## Chunk 1: Sửa thanh chỉ số ảnh trên ProfileDetailScreen

### Task 1: Điều chỉnh vị trí và độ dày thanh chỉ số ảnh

**Files:**
- Modify: [profile_detail_screen.dart](file:///c:/Users/THANGND/EXE_Project/bondy_app/lib/screens/discover/profile_detail_screen.dart)

- [ ] **Step 1: Cập nhật vị trí và kích thước thanh ngang**
  Thay đổi thuộc tính `top` và `height` của thanh ngang chỉ số trong hàm `_buildHero`.
  
  *Mã nguồn thay đổi dự kiến:*
  ```dart
  // Trong lib/screens/discover/profile_detail_screen.dart:
  // Thay thế vị trí:
  Positioned(
    top: MediaQuery.of(context).padding.top + 12,
    left: 20,
    right: 20,
    child: Row(
      children: List.generate(
        photos.length,
        (idx) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            height: 2, // Thay đổi độ dày từ 3 thành 2
            decoration: BoxDecoration(
              color: idx == _currentPhotoIndex
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    ),
  )
  ```

- [ ] **Step 2: Commit thay đổi Task 1**
  ```bash
  git add lib/screens/discover/profile_detail_screen.dart
  git commit -m "style: move photo indicator to top and make it thinner on profile detail"
  ```

---

## Chunk 2: Thiết kế lại màn hình loading khởi động

### Task 2: Cập nhật giao diện và thêm hiệu ứng pulse logo vào AuthGateScreen

**Files:**
- Modify: [auth_gate_screen.dart](file:///c:/Users/THANGND/EXE_Project/bondy_app/lib/screens/auth/auth_gate_screen.dart)
- Test: [auth_gate_screen_test.dart](file:///c:/Users/THANGND/EXE_Project/bondy_app/test/screens/auth/auth_gate_screen_test.dart)

- [ ] **Step 1: Thêm SingleTickerProviderStateMixin và thuộc tính hoạt họa**
  Cập nhật class `_AuthGateScreenState` để sử dụng `SingleTickerProviderStateMixin` và khai báo các thuộc tính hoạt họa:
  ```dart
  class _AuthGateScreenState extends State<AuthGateScreen> with SingleTickerProviderStateMixin {
    late final AnimationController _animationController;
    late final Animation<double> _scaleAnimation;
    late final Animation<double> _opacityAnimation;
  ```

- [ ] **Step 2: Khởi tạo và giải phóng AnimationController**
  Khởi tạo hoạt họa trong `initState` (lặp lại vô hạn với chế độ đảo ngược) và gọi `dispose` để tránh rò rỉ bộ nhớ.
  ```dart
  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.04).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreSession();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  ```

- [ ] **Step 3: Thiết kế lại giao diện trong phương thức build**
  Thay đổi UI để dùng nền gradient, hiển thị ảnh logo và hiệu ứng co giãn.
  ```dart
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: BondyColors.signatureGradient,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Bondy với hiệu ứng hoạt họa pulse
                    FadeTransition(
                      opacity: _opacityAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 160,
                          height: 160,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Vòng xoay tải tinh tế màu trắng
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Dòng chữ trạng thái
                    Text(
                      'Đang khôi phục phiên...',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  ```
  *(Lưu ý: Nhớ import `../../theme/app_theme.dart` để lấy `BondyColors` và `package:google_fonts/google_fonts.dart` cho GoogleFonts).*

- [ ] **Step 4: Chạy kiểm thử tự động**
  Chạy lệnh `flutter test test/screens/auth/auth_gate_screen_test.dart` để xác nhận giao diện mới không phá vỡ lô-gic hoạt động của màn hình AuthGate.
  Mong đợi: Tất cả các bài kiểm thử đều PASS.

- [ ] **Step 5: Commit thay đổi Task 2**
  ```bash
  git add lib/screens/auth/auth_gate_screen.dart
  git commit -m "feat: redesign loading screen with signature gradient and pulsing logo"
  ```

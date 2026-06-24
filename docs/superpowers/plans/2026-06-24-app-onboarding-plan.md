# Kế hoạch Triển khai: Tính năng Hướng dẫn Sử dụng App (Onboarding & Swipe Tutorial)

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Xây dựng hệ thống chỉ dẫn tương tác (Interactive Onboarding Showcase Tour) ở màn hình chính và màn hình Match/Discover cho người dùng mới sử dụng Custom Overlay của Flutter và lưu trạng thái qua SharedPreferences.

**Architecture:** Sử dụng Flutter `OverlayEntry` cùng với `CustomPainter` (`ColorFiltered` kết hợp `BlendMode.dstOut`) để đục lỗ sáng trên nền đen mờ tại vị trí của các widget mục tiêu (lấy qua `GlobalKey`). Tạo một controller quản lý tập trung và một widget hoạt họa cử chỉ quẹt riêng biệt cho màn hình Match.

**Tech Stack:** Flutter SDK (Dart), Provider, SharedPreferences, Google Fonts.

---

## Chunk 1: Xây dựng các lớp cơ sở (Core Onboarding Widgets & Model)

### Task 1: Định nghĩa Model ShowcaseStep
**Files:**
- Create: [showcase_step.dart](file:///c:/Users/THANGND/EXE_Project/bondy_app/lib/widgets/onboarding/showcase_step.dart)
- Test: [showcase_step_test.dart](file:///c:/Users/THANGND/EXE_Project/bondy_app/test/widgets/onboarding/showcase_step_test.dart)

- [ ] **Step 1: Viết test kiểm tra khởi tạo model ShowcaseStep**
  Tạo file `test/widgets/onboarding/showcase_step_test.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:bondy/widgets/onboarding/showcase_step.dart';

  void main() {
    test('ShowcaseStep should initialize with correct values', () {
      final key = GlobalKey();
      final step = ShowcaseStep(
        targetKey: key,
        title: 'Test Title',
        content: 'Test Content',
        icon: '🔥',
        position: ShowcasePosition.bottom,
      );

      expect(step.targetKey, key);
      expect(step.title, 'Test Title');
      expect(step.content, 'Test Content');
      expect(step.icon, '🔥');
      expect(step.position, ShowcasePosition.bottom);
    });
  }
  ```

- [ ] **Step 2: Chạy test và xác nhận lỗi biên dịch (Compilation Fail)**
  Run: `flutter test test/widgets/onboarding/showcase_step_test.dart`
  Expected: Lỗi biên dịch vì `showcase_step.dart` chưa tồn tại.

- [ ] **Step 3: Triển khai code ShowcaseStep**
  Tạo file `lib/widgets/onboarding/showcase_step.dart`:
  ```dart
  import 'package:flutter/material.dart';

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

- [ ] **Step 4: Chạy test xác nhận PASS**
  Run: `flutter test test/widgets/onboarding/showcase_step_test.dart`
  Expected: PASS

- [ ] **Step 5: Commit lên Git**
  ```bash
  git add lib/widgets/onboarding/showcase_step.dart test/widgets/onboarding/showcase_step_test.dart
  git commit -m "feat: add ShowcaseStep model and unit test"
  ```

---

### Task 2: Tạo CustomPainter HolePainter để đục lỗ sáng
**Files:**
- Create: [hole_painter.dart](file:///c:/Users/THANGND/EXE_Project/bondy_app/lib/widgets/onboarding/hole_painter.dart)

- [ ] **Step 1: Viết lớp HolePainter đục lỗ tròn/chữ nhật bo góc**
  Tạo file `lib/widgets/onboarding/hole_painter.dart`:
  ```dart
  import 'package:flutter/material.dart';

  class HolePainter extends CustomPainter {
    final Rect targetRect;
    final double borderRadius;
    final Color barrierColor;

    HolePainter({
      required this.targetRect,
      this.borderRadius = 12.0,
      this.barrierColor = Colors.black54,
    });

    @override
    void paint(Canvas canvas, Size size) {
      final paint = Paint()
        ..color = barrierColor
        ..style = PaintingStyle.fill;

      // Vẽ lớp nền phủ mờ toàn bộ canvas
      final backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

      // Vẽ vùng lỗ đục sáng
      final holePath = Path();
      if (borderRadius > 0) {
        holePath.addRRect(RRect.fromRectAndRadius(targetRect, Radius.circular(borderRadius)));
      } else {
        holePath.addOval(targetRect);
      }

      // Đục lỗ bằng cách lấy phần hiệu (difference)
      final finalPath = Path.combine(PathOperation.difference, backgroundPath, holePath);
      canvas.drawPath(finalPath, paint);
    }

    @override
    bool shouldRepaint(covariant HolePainter oldDelegate) {
      return oldDelegate.targetRect != targetRect ||
          oldDelegate.borderRadius != borderRadius ||
          oldDelegate.barrierColor != barrierColor;
    }
  }
  ```

- [ ] **Step 2: Commit lên Git**
  ```bash
  git add lib/widgets/onboarding/hole_painter.dart
  git commit -m "feat: add HolePainter to draw highlighted hole on dimmed barrier"
  ```

---

### Task 3: Tạo Widget OnboardingTooltip
**Files:**
- Create: [onboarding_tooltip.dart](file:///c:/Users/THANGND/EXE_Project/bondy_app/lib/widgets/onboarding/onboarding_tooltip.dart)
- Test: [onboarding_tooltip_test.dart](file:///c:/Users/THANGND/EXE_Project/bondy_app/test/widgets/onboarding/onboarding_tooltip_test.dart)

- [ ] **Step 1: Viết test kiểm tra UI hiển thị của OnboardingTooltip**
  Tạo file `test/widgets/onboarding/onboarding_tooltip_test.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:bondy/widgets/onboarding/onboarding_tooltip.dart';

  void main() {
    testWidgets('OnboardingTooltip should display titles, contents and invoke callbacks', (WidgetTester tester) async {
      bool nextCalled = false;
      bool skipCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OnboardingTooltip(
              title: 'Welcome Tour',
              content: 'Let us show you around',
              icon: '👋',
              currentStep: 1,
              totalSteps: 2,
              onNext: () => nextCalled = true,
              onSkip: () => skipCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('Welcome Tour'), findsOneWidget);
      expect(find.text('Let us show you around'), findsOneWidget);
      expect(find.text('Bước 1/2'), findsOneWidget);

      await tester.tap(find.text('Tiếp tục →'));
      await tester.pump();
      expect(nextCalled, true);

      await tester.tap(find.text('Bỏ qua'));
      await tester.pump();
      expect(skipCalled, true);
    });
  }
  ```

- [ ] **Step 2: Chạy test và xác nhận lỗi biên dịch**
  Run: `flutter test test/widgets/onboarding/onboarding_tooltip_test.dart`
  Expected: Lỗi biên dịch vì `onboarding_tooltip.dart` chưa được viết.

- [ ] **Step 3: Triển khai widget OnboardingTooltip**
  Tạo file `lib/widgets/onboarding/onboarding_tooltip.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:google_fonts/google_fonts.dart';

  class OnboardingTooltip extends StatelessWidget {
    final String title;
    final String content;
    final String icon;
    final int currentStep;
    final int totalSteps;
    final VoidCallback onNext;
    final VoidCallback onSkip;

    const OnboardingTooltip({
      super.key,
      required this.title,
      required this.content,
      required this.icon,
      required this.currentStep,
      required this.totalSteps,
      required this.onNext,
      required this.onSkip,
    });

    @override
    Widget build(BuildContext context) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A24),
          border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.3)),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.between,
              children: [
                Text(
                  'BƯỚC $currentStep/$totalSteps',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFFF9F80),
                    letterSpacing: 1.0,
                  ),
                ),
                Text(icon, style: const TextStyle(fontSize: 18)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              content,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                height: 1.4,
                color: const Color(0xFFD0D0D6),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.between,
              children: [
                // Indicators
                Row(
                  children: List.generate(
                    totalSteps,
                    (index) => Container(
                      margin: const EdgeInsets.only(right: 6),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: index + 1 == currentStep
                            ? const Color(0xFFFF6B6B)
                            : const Color(0xFF4A4A5A),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                // Actions Buttons
                Row(
                  children: [
                    TextButton(
                      onPressed: onSkip,
                      child: Text(
                        'Bỏ qua',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFFA0A0A0),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        backgroundColor: const Color(0xFFFF6B6B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      onPressed: onNext,
                      child: Text(
                        currentStep == totalSteps ? 'Xong' : 'Tiếp tục',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    }
  }
  ```

- [ ] **Step 4: Chạy test xác nhận PASS**
  Run: `flutter test test/widgets/onboarding/onboarding_tooltip_test.dart`
  Expected: PASS

- [ ] **Step 5: Commit lên Git**
  ```bash
  git add lib/widgets/onboarding/onboarding_tooltip.dart test/widgets/onboarding/onboarding_tooltip_test.dart
  git commit -m "feat: add OnboardingTooltip widget and widget test"
  ```

---

## Chunk 2: Điều phối Overlay và Xây dựng Hướng dẫn Quẹt thẻ

### Task 4: Xây dựng Controller OnboardingOverlay
**Files:**
- Create: [onboarding_overlay.dart](file:///c:/Users/THANGND/EXE_Project/bondy_app/lib/widgets/onboarding/onboarding_overlay.dart)

- [ ] **Step 1: Tạo controller điều phối hiển thị Overlay**
  Tạo file `lib/widgets/onboarding/onboarding_overlay.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'showcase_step.dart';
  import 'hole_painter.dart';
  import 'onboarding_tooltip.dart';

  class OnboardingOverlay {
    static OverlayEntry? _overlayEntry;

    static void show(
      BuildContext context, {
      required List<ShowcaseStep> steps,
      VoidCallback? onCompleted,
    }) {
      if (steps.isEmpty) return;

      int currentStepIndex = 0;
      final overlayState = Overlay.of(context);

      void remove() {
        _overlayEntry?.remove();
        _overlayEntry = null;
      }

      void renderStep() {
        remove();

        final step = steps[currentStepIndex];
        final renderBox = step.targetKey.currentContext?.findRenderObject() as RenderBox?;
        
        if (renderBox == null) {
          // Bỏ qua bước nếu widget chưa sẵn sàng hiển thị trên màn hình
          if (currentStepIndex < steps.length - 1) {
            currentStepIndex++;
            renderStep();
          } else {
            onCompleted?.call();
          }
          return;
        }

        final size = renderBox.size;
        final position = renderBox.localToGlobal(Offset.zero);
        // Padding xung quanh lỗ đục sáng để tạo khoảng thở rộng hơn widget
        const double padding = 6.0;
        final targetRect = Rect.fromLTWH(
          position.dx - padding,
          position.dy - padding,
          size.width + padding * 2,
          size.height + padding * 2,
        );

        _overlayEntry = OverlayEntry(
          builder: (context) {
            final screenWidth = MediaQuery.of(context).size.width;
            final tooltipWidth = screenWidth - 40; // margin 20px mỗi bên

            // Tính toán vị trí hiển thị của Tooltip dựa theo cấu hình và vị trí widget
            double? tooltipTop;
            double? tooltipBottom;

            if (step.position == ShowcasePosition.top) {
              tooltipBottom = MediaQuery.of(context).size.height - position.dy + 12;
            } else {
              tooltipTop = position.dy + size.height + 12;
            }

            return Material(
              color: Colors.transparent,
              child: Stack(
                children: [
                  // Lớp phủ mờ vẽ lỗ đục sáng
                  Positioned.fill(
                    child: CustomPaint(
                      painter: HolePainter(
                        targetRect: targetRect,
                        borderRadius: 16,
                      ),
                    ),
                  ),
                  
                  // Chặn click xuyên qua nền mờ
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {}, // hấp thụ tất cả click
                    ),
                  ),

                  // Bong bóng tooltip
                  Positioned(
                    left: 20,
                    width: tooltipWidth,
                    top: tooltipTop,
                    bottom: tooltipBottom,
                    child: OnboardingTooltip(
                      title: step.title,
                      content: step.content,
                      icon: step.icon,
                      currentStep: currentStepIndex + 1,
                      totalSteps: steps.length,
                      onNext: () {
                        if (currentStepIndex < steps.length - 1) {
                          currentStepIndex++;
                          renderStep();
                        } else {
                          remove();
                          onCompleted?.call();
                        }
                      },
                      onSkip: () {
                        remove();
                        onCompleted?.call();
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );

        overlayState.insert(_overlayEntry!);
      }

      renderStep();
    }
  }
  ```

- [ ] **Step 2: Commit lên Git**
  ```bash
  git add lib/widgets/onboarding/onboarding_overlay.dart
  git commit -m "feat: add OnboardingOverlay to orchestrate the step-by-step tour"
  ```

---

### Task 5: Tạo SwipeTutorialOverlay cho màn hình Match
**Files:**
- Create: [swipe_tutorial_overlay.dart](file:///c:/Users/THANGND/EXE_Project/bondy_app/lib/widgets/onboarding/swipe_tutorial_overlay.dart)

- [ ] **Step 1: Triển khai widget hoạt họa quẹt thẻ và đục lỗ 4 nút tương tác**
  Tạo file `lib/widgets/onboarding/swipe_tutorial_overlay.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:google_fonts/google_fonts.dart';
  import 'hole_painter.dart';

  class SwipeTutorialOverlay extends StatefulWidget {
    final GlobalKey bottomButtonsKey;
    final VoidCallback onDismiss;

    const SwipeTutorialOverlay({
      super.key,
      required this.bottomButtonsKey,
      required this.onDismiss,
    });

    @override
    State<SwipeTutorialOverlay> createState() => _SwipeTutorialOverlayState();
  }

  class _SwipeTutorialOverlayState extends State<SwipeTutorialOverlay>
      with SingleTickerProviderStateMixin {
    late AnimationController _controller;
    late Animation<Offset> _handOffsetAnimation;

    @override
    void initState() {
      super.initState();
      _controller = AnimationController(
        duration: const Duration(milliseconds: 2000),
        vsync: this,
      )..repeat();

      _handOffsetAnimation = TweenSequence<Offset>([
        TweenSequenceItem(
          tween: Tween<Offset>(begin: const Offset(-0.8, 0.0), end: const Offset(0.6, 0.0))
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 70,
        ),
        TweenSequenceItem(
          tween: ConstantTween<Offset>(const Offset(0.6, 0.0)),
          weight: 30,
        ),
      ]).animate(_controller);
    }

    @override
    void dispose() {
      _controller.dispose();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      final renderBox = widget.bottomButtonsKey.currentContext?.findRenderObject() as RenderBox?;
      Rect targetRect = Rect.zero;

      if (renderBox != null) {
        final size = renderBox.size;
        final position = renderBox.localToGlobal(Offset.zero);
        targetRect = Rect.fromLTWH(
          position.dx - 8,
          position.dy - 8,
          size.width + 16,
          size.height + 16,
        );
      }

      return Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Vẽ nền đen mờ đục lỗ sáng cho 4 nút dưới cùng
            Positioned.fill(
              child: CustomPaint(
                painter: HolePainter(
                  targetRect: targetRect,
                  borderRadius: 16,
                  barrierColor: Colors.black.withOpacity(0.75),
                ),
              ),
            ),

            // Chặn tương tác click bên dưới
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
              ),
            ),

            // Hướng dẫn 2 bên cánh quẹt trái/phải
            Positioned(
              top: MediaQuery.of(context).size.height * 0.35,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.between,
                children: [
                  // Trái (Bỏ qua)
                  _buildDirectionIndicator(
                    emoji: '❌',
                    label: 'Quẹt Trái\nBỏ qua',
                    color: const Color(0xFFEF4444),
                  ),
                  
                  // Phải (Thích)
                  _buildDirectionIndicator(
                    emoji: '💚',
                    label: 'Quẹt Phải\nGửi Thích',
                    color: const Color(0xFF2ECC71),
                  ),
                ],
              ),
            ),

            // Hoạt họa cử chỉ ở trung tâm
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 40),
                  AnimatedBuilder(
                    animation: _handOffsetAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_handOffsetAnimation.value.dx * 100, 0),
                        child: const Text('👉', style: TextStyle(fontSize: 48)),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Kéo sang phải để Thích',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFFFFAA66),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),

            // Text hướng dẫn tiêu đề chính ở trên
            Positioned(
              top: 80,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  Text(
                    'Hướng dẫn Quẹt Kết Nối',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Khám phá và kết nối cực kỳ đơn giản',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFFC0C0C5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // Tooltip hướng dẫn 4 nút tương tác nhanh ở dưới lỗ đục
            if (renderBox != null)
              Positioned(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).size.height - targetRect.top + 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A24),
                    border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Nút tương tác nhanh',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bạn cũng có thể bấm trực tiếp để Hoàn tác, Bỏ qua, Super Like hoặc Thích.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFFD0D0D6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Nút "Bắt đầu khám phá" dưới cùng
            Positioned(
              bottom: 40,
              left: 30,
              right: 30,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFFFF6B6B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
                onPressed: widget.onDismiss,
                child: Text(
                  'Bắt đầu khám phá',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildDirectionIndicator({
      required String emoji,
      required String label,
      required Color color,
    }) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          border: Border.all(color: color.withOpacity(0.6), width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        width: 85,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: color.withOpacity(0.9),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
  }
  ```

- [ ] **Step 2: Commit lên Git**
  ```bash
  git add lib/widgets/onboarding/swipe_tutorial_overlay.dart
  git commit -m "feat: add SwipeTutorialOverlay widget for discover screen onboarding"
  ```

---

## Chunk 3: Tích hợp vào Bottom Nav Bar và Màn hình chính

### Task 6: Tích hợp Key vào BondyBottomNavBar
**Files:**
- Modify: [bondy_bottom_nav_bar.dart](file:///c:/Users/THANGND/EXE_Project/bondy_app/lib/widgets/navigation/bondy_bottom_nav_bar.dart)

- [ ] **Step 1: Chỉnh sửa constructor và gán Key vào widget tương ứng**
  Cập nhật file `lib/widgets/navigation/bondy_bottom_nav_bar.dart` để thêm:
  *   Thêm `matchKey` và `healingKey` vào tham số của `BondyBottomNavBar`.
  *   Gán `healingKey` vào widget `_NavItem` của nút Healing (icon `Icons.monitor_heart_outlined`).
  *   Gán `matchKey` vào widget nút `Match` nổi ở giữa (FAB container).
  
  *Gợi ý đoạn code chỉnh sửa:*
  ```diff
  class BondyBottomNavBar extends StatelessWidget {
     final int currentIndex;
     final ValueChanged<int>? onTabSelected;
     final VoidCallback? onMatchTap;
     final bool hasMatchBadge;
  +  final GlobalKey? matchKey;
  +  final GlobalKey? healingKey;
  
     const BondyBottomNavBar({
       super.key,
       required this.currentIndex,
       this.onTabSelected,
       this.onMatchTap,
       this.hasMatchBadge = false,
  +    this.matchKey,
  +    this.healingKey,
     });
  ```
  Trong widget build, gán key vào:
  ```diff
                         // Healing
                         Expanded(
                           child: _NavItem(
  +                          key: healingKey,
                             index: 1,
                             currentIndex: currentIndex,
                             icon: Icons.monitor_heart_outlined,
  ```
  Và nút Match FAB:
  ```diff
             // Nút Match (FAB) lồi lên trên
             Positioned(
               // Canh giữa màn hình
               left: 0,
               right: 0,
               top: 0,
               child: Center(
                 child: GestureDetector(
  +                key: matchKey,
                   onTap: onMatchTap,
                   child: Container(
                     width: _fabSize,
  ```

- [ ] **Step 2: Commit lên Git**
  ```bash
  git add lib/widgets/navigation/bondy_bottom_nav_bar.dart
  git commit -m "feat: pass and assign matchKey and healingKey in BondyBottomNavBar"
  ```

---

### Task 7: Kích hoạt Onboarding trên MainShellScreen
**Files:**
- Modify: [main_shell_screen.dart](file:///c:/Users/THANGND/EXE_Project/bondy_app/lib/screens/home/main_shell_screen.dart)

- [ ] **Step 1: Sửa MainShellScreen để quản lý GlobalKey và kích hoạt Showcase**
  Cập nhật file `lib/screens/home/main_shell_screen.dart` để thêm logic:
  *   Khai báo `final GlobalKey _matchKey = GlobalKey();` và `final GlobalKey _healingKey = GlobalKey();`.
  *   Trong `_MainShellScreenState.initState()`, thêm post-frame callback để kiểm tra `SharedPreferences` xem key `has_seen_main_onboarding` đã có chưa. Nếu chưa -> gọi `OnboardingOverlay.show` với các bước chỉ dẫn, và lưu cờ thành `true` khi hoàn tất.
  *   Truyền `matchKey: _matchKey` và `healingKey: _healingKey` vào `BondyBottomNavBar`.

  *Gợi ý đoạn code chỉnh sửa:*
  ```dart
  // Trong _MainShellScreenState:
  final GlobalKey _matchKey = GlobalKey();
  final GlobalKey _healingKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // ... code cũ ...
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ChatViewModel>().fetchChats();
      context.read<RelationshipViewModel>().loadDashboard();
      _checkAndShowOnboarding();
    });
  }

  Future<void> _checkAndShowOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('has_seen_main_onboarding') ?? false;
    if (!hasSeen && mounted) {
      // Đợi 800ms để đảm bảo UI render xong và BottomNav ổn định vị trí
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;

      final steps = [
        ShowcaseStep(
          targetKey: _matchKey,
          title: 'Quẹt Tìm Bạn 🔥',
          content: 'Bấm vào nút Trái Tim này để bắt đầu khám phá và quẹt chọn một nửa phù hợp của bạn.',
          icon: '❤️',
          position: ShowcasePosition.top,
        ),
        ShowcaseStep(
          targetKey: _healingKey,
          title: 'Hành Trình Chữa Lành 💖',
          content: 'Khám phá không gian chữa lành tâm hồn, nơi bạn và đối tác cùng tham gia các thử thách cặp đôi.',
          icon: '🩺',
          position: ShowcasePosition.top,
        ),
      ];

      OnboardingOverlay.show(
        context,
        steps: steps,
        onCompleted: () async {
          final p = await SharedPreferences.getInstance();
          await p.setBool('has_seen_main_onboarding', true);
        },
      );
    }
  }
  ```

- [ ] **Step 2: Commit lên Git**
  ```bash
  git add lib/screens/home/main_shell_screen.dart
  git commit -m "feat: check prefs and show interactive onboarding on MainShellScreen"
  ```

---

## Chunk 4: Tích hợp Hướng dẫn Quẹt thẻ ở màn hình Match

### Task 8: Tích hợp SwipeTutorialOverlay vào DiscoverMatchingScreen
**Files:**
- Modify: [discover_matching_screen.dart](file:///c:/Users/THANGND/EXE_Project/bondy_app/lib/screens/discover/discover_matching_screen.dart)

- [ ] **Step 1: Cập nhật DiscoverMatchingScreen để hiển thị SwipeTutorialOverlay**
  Cập nhật file `lib/screens/discover/discover_matching_screen.dart`:
  *   Khai báo `final GlobalKey _bottomButtonsKey = GlobalKey();`.
  *   Gán `_bottomButtonsKey` vào Row chứa 4 nút hành động dưới cùng (dòng 588).
  *   Khai báo một biến State: `bool _showSwipeTutorial = false;`.
  *   Trong `_loadInitialData()`, sau khi tải dữ liệu xong và danh sách profile không trống (`_viewModel.profiles.isNotEmpty`), kiểm tra `SharedPreferences` cho key `has_seen_swipe_tutorial`.
  *   Nếu chưa xem, đặt `_showSwipeTutorial = true` thông qua `setState`.
  *   Trong `build()`, bọc Stack ở ngoài cùng, nếu `_showSwipeTutorial` bằng `true`, hiển thị `SwipeTutorialOverlay(bottomButtonsKey: _bottomButtonsKey, onDismiss: _dismissSwipeTutorial)` trên cùng của Stack.
  *   Hàm `_dismissSwipeTutorial` sẽ gọi `setState(() => _showSwipeTutorial = false)` và lưu cờ `has_seen_swipe_tutorial = true` vào `SharedPreferences`.

  *Gợi ý đoạn code chỉnh sửa:*
  ```dart
  // Trong _DiscoverMatchingScreenState:
  final GlobalKey _bottomButtonsKey = GlobalKey();
  bool _showSwipeTutorial = false;

  // Trong _loadInitialData() sau khi nạp profiles thành công:
  if (_viewModel.profiles.isNotEmpty) {
    _checkSwipeTutorial();
  }

  Future<void> _checkSwipeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('has_seen_swipe_tutorial') ?? false;
    if (!hasSeen && mounted) {
      setState(() => _showSwipeTutorial = true);
    }
  }

  Future<void> _dismissSwipeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_swipe_tutorial', true);
    if (mounted) {
      setState(() => _showSwipeTutorial = false);
    }
  }
  ```
  Gán key vào Row chứa action buttons:
  ```dart
  // Bottom Action buttons
  Padding(
    key: _bottomButtonsKey,
    padding: const EdgeInsets.symmetric(vertical: 24.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
  ...
  ```
  Và trong Stack của `build()`:
  ```dart
  return Stack(
    children: [
      Column(
        children: [
          // ... code cũ ...
        ],
      ),
      _buildSwipeFeedback(),
      if (_showSwipeTutorial)
        Positioned.fill(
          child: SwipeTutorialOverlay(
            bottomButtonsKey: _bottomButtonsKey,
            onDismiss: _dismissSwipeTutorial,
          ),
        ),
    ],
  );
  ```

- [ ] **Step 2: Commit lên Git**
  ```bash
  git add lib/screens/discover/discover_matching_screen.dart
  git commit -m "feat: show swipe and action buttons tutorial on DiscoverMatchingScreen"
  ```

---

## Chunk 5: Chạy kiểm thử và Kiểm chứng (Verification)

### Task 9: Kiểm chứng chất lượng và Chạy ứng dụng
**Files:**
- Modify: Không

- [ ] **Step 1: Chạy toàn bộ các test của Onboarding**
  Run: `flutter test test/widgets/onboarding/`
  Expected: Tất cả các test (model và widget) chạy thành công và hiển thị màu xanh lá.

- [ ] **Step 2: Chạy linter phân tích code**
  Run: `flutter analyze`
  Expected: Không có lỗi nghiêm trọng (Errors) hoặc cảnh báo (Warnings) liên quan đến các file mới/file sửa đổi.

- [ ] **Step 3: Chạy ứng dụng thực tế để kiểm tra thủ công**
  Nhờ người dùng build thử app lên máy ảo hoặc thiết bị kiểm thử, thực hiện các thao tác:
  *   Tạo/Đăng nhập tài khoản mới tinh để xem kịch bản Main Showcase (Match -> Healing).
  *   Bấm "Bỏ qua" hoặc "Tiếp tục" hết các bước.
  *   Nhấp vào nút Match để chuyển qua trang Discover, kiểm tra xem lớp phủ hướng dẫn quẹt thẻ + đục lỗ 4 nút có hiển thị mượt mà không.
  *   Xác nhận trải nghiệm người dùng hoạt động trơn tru.

- [ ] **Step 4: Thực hiện Push code lên Git Remote**
  Run: `git pull --rebase; git push`
  Expected: Code được đẩy lên repository thành công, hoàn tất session làm việc.

# Kế hoạch Triển khai: Tái cấu trúc Danh sách kết đôi & Tính năng Gợi ý AI

> **For agentic workers:** REQUIRED: Use superpowers:executing-plans to implement this plan in the current session. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Triển khai tái cấu trúc giao diện Danh sách kết đôi và tích hợp các tính năng Trợ lý AI (Ask Bondy FAB & Bottom Sheet, AI Icebreakers, Deeper Prompts, Weekend Date Suggestions) với sự phân tách kiến trúc rõ ràng giữa phân hệ Chat AI và Chat Người dùng.

**Architecture:** Sử dụng Flutter Widgets cao cấp của Bondy App, định nghĩa các mô hình dữ liệu tĩnh cho AI Icebreakers/Prompts trong `lib/core/ai_prompts_config.dart`, triển khai Bottom Sheet và Date Suggestions Card cuộn ngang dưới dạng các Widget độc lập để đảm bảo tính module hóa, sạch sẽ và dễ bảo trì.

**Tech Stack:** Flutter SDK, Google Fonts (Plus Jakarta Sans), AppTheme (BondyColors), Material Design 3.

---

## Các tập tin sẽ Tạo mới & Sửa đổi

*   **Tạo mới:**
    1.  `lib/core/ai_prompts_config.dart`: Định nghĩa kho dữ liệu tĩnh cho các gợi ý AI (Icebreakers, Deeper Prompts, Weekend Places).
    2.  `lib/widgets/chat/ask_bondy_bottom_sheet.dart`: Giao diện Bottom Sheet trợ lý AI thấu cảm.
    3.  `lib/widgets/chat/date_suggestions_widget.dart`: Thành phần đồ họa hiển thị các thẻ gợi ý địa điểm hẹn hò trượt ngang trong chat AI.
*   **Sửa đổi:**
    1.  `lib/screens/chat/matches_list_screen.dart`: Tái cấu trúc Danh sách kết đôi, thay FAB Hỏi Bondy, thêm cuộn ngang Mới tương hợp, thêm ô tìm kiếm và AI Icebreaker.
    2.  `lib/screens/chat/chat_screen.dart`: Thêm dải Prompt câu hỏi sâu trên bàn phím phòng chat đôi.
    3.  `lib/screens/chat/healing_chatbot_coach_screen.dart`: Tiếp nhận tin nhắn khởi đầu ban đầu và hỗ trợ hiển thị thẻ Date Suggestions Card.

---

## Chi tiết các Bước triển khai (Bite-sized Tasks)

### Task 1: Khởi tạo Cấu hình AI Prompts
*   **Files:**
    *   Create: `lib/core/ai_prompts_config.dart`
*   - [ ] **Step 1: Tạo tệp cấu hình AI Prompts**
    Định nghĩa kho câu hỏi, gợi ý mở lời và dữ liệu giả lập địa điểm đi chơi để dùng chung cho toàn bộ app.

    *Viết mã nguồn vào `lib/core/ai_prompts_config.dart`:*
    ```dart
    class AIPromptsConfig {
      static const List<String> icebreakers = [
        'Ảnh đại diện của bạn trông rất bình yên, bạn có hay đi dã ngoại không?',
        'Cuối tuần của bạn thường diễn ra như thế nào?',
        'Bạn thích một buổi tối ấm áp ở nhà hay đi dạo phố hơn?',
        'Thể loại nhạc nào giúp bạn nạp năng lượng sau một ngày mệt mỏi?',
        'Nếu được chọn một địa điểm để đi trốn ngay lúc này, bạn sẽ chọn đi đâu?',
      ];

      static const List<String> deeperPrompts = [
        'Điều gì khiến bạn thấy thoải mái nhất khi ở bên một người?',
        'Điều gì làm bạn vui vẻ và tự hào nhất trong tuần này?',
        'Kỷ niệm đáng nhớ nhất thời thơ ấu của bạn là gì?',
        'Một ngày hoàn hảo đối với bạn sẽ trông như thế nào?',
      ];

      static const List<Map<String, String>> mockDateSuggestions = [
        {
          'name': 'The Hideout Cafe',
          'category': 'Cafe',
          'distance': '1.2km',
          'price': '$$',
          'vibe': 'Yên tĩnh',
          'description': 'Phù hợp với vibe của hai bạn',
          'image': 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?q=80&w=600',
        },
        {
          'name': "Pizza 4P's",
          'category': 'Dinner',
          'distance': '3.5km',
          'price': '$$$',
          'vibe': 'Lãng mạn',
          'description': 'Không gian lãng mạn',
          'image': 'https://images.unsplash.com/photo-1513104890138-7c749659a591?q=80&w=600',
        },
        {
          'name': 'West Lake Sunset',
          'category': 'Outdoor',
          'distance': '5.0km',
          'price': 'Free',
          'vibe': 'Dạo bộ',
          'description': 'Thư giãn cuối tuần',
          'image': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=600',
        },
      ];
    }
    ```

*   - [ ] **Step 2: Commit cấu hình AI**
    ```bash
    git add lib/core/ai_prompts_config.dart
    git commit -m "feat: add AI prompts configuration pool"
    ```

---

### Task 2: Tạo Trình hiển thị Thẻ gợi ý hẹn hò cuối tuần (`DateSuggestionsWidget`)
*   **Files:**
    *   Create: `lib/widgets/chat/date_suggestions_widget.dart`
*   - [ ] **Step 1: Định nghĩa Widget thẻ địa điểm hẹn hò**
    Thiết kế widget cuộn ngang các thẻ địa điểm lãng mạn với đầy đủ nút bấm, phản hồi xúc giác đẹp mắt.

    *Viết mã nguồn vào `lib/widgets/chat/date_suggestions_widget.dart`:*
    ```dart
    import 'package:flutter/material.dart';
    import 'package:google_fonts/google_fonts.dart';
    import '../../theme/app_theme.dart';

    class DateSuggestionsWidget extends StatelessWidget {
      final List<Map<String, String>> places;
      final Function(String name)? onShare;
      final Function(String name)? onSave;
      final Function(String name)? onMap;

      const DateSuggestionsWidget({
        super.key,
        required this.places,
        this.onShare,
        this.onSave,
        this.onMap,
      });

      @override
      Widget build(BuildContext context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: BondyColors.primary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Dưới đây là một vài gợi ý dành cho hai bạn:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: BondyColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 290,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: places.length,
                itemBuilder: (context, index) {
                  final place = places[index];
                  return Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: BondyColors.divider.withValues(alpha: 0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Place Image & Tags
                          Stack(
                            children: [
                              Image.network(
                                place['image'] ?? '',
                                height: 140,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 140,
                                  color: BondyColors.primaryLight,
                                  child: const Icon(Icons.image_not_supported, color: BondyColors.primary),
                                ),
                              ),
                              Container(
                                height: 140,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.6),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 12,
                                left: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, py: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    (place['category'] ?? '').toUpperCase(),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: BondyColors.primary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 12,
                                left: 12,
                                right: 12,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      place['name'] ?? '',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, color: Colors.white, size: 12),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${place['distance']} • ${place['price']} • ${place['vibe']}',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white.withValues(alpha: 0.9),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // Vibe Match Banner
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            color: BondyColors.primaryLight.withValues(alpha: 0.35),
                            child: Row(
                              children: [
                                const Icon(Icons.auto_awesome, color: BondyColors.primary, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  place['description'] ?? '',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: BondyColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Action Buttons
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildActionButton(
                                    icon: Icons.share,
                                    label: 'Chia sẻ',
                                    onTap: () => onShare?.call(place['name'] ?? ''),
                                  ),
                                  _buildActionButton(
                                    icon: Icons.bookmark_border,
                                    label: 'Lưu',
                                    onTap: () => onSave?.call(place['name'] ?? ''),
                                  ),
                                  _buildActionButton(
                                    icon: Icons.map_outlined,
                                    label: 'Bản đồ',
                                    onTap: () => onMap?.call(place['name'] ?? ''),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }

      Widget _buildActionButton({
        required IconData icon,
        required String label,
        required VoidCallback onTap,
      }) {
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: BondyColors.primary, size: 18),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: BondyColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    ```

*   - [ ] **Step 2: Commit DateSuggestionsWidget**
    ```bash
    git add lib/widgets/chat/date_suggestions_widget.dart
    git commit -m "feat: add DateSuggestionsWidget for chatbot date recommendations"
    ```

---

### Task 3: Tạo Trợ lý AI Bottom Sheet Overlay (`AskBondyBottomSheet`)
*   **Files:**
    *   Create: `lib/widgets/chat/ask_bondy_bottom_sheet.dart`
*   - [ ] **Step 1: Triển khai Bottom Sheet Ask Bondy**
    Xây dựng giao diện kéo lên từ dưới hiện đại, với khối chào mừng nghiêng 3 độ và các nút chọn nhanh chủ đề tâm sự.

    *Viết mã nguồn vào `lib/widgets/chat/ask_bondy_bottom_sheet.dart`:*
    ```dart
    import 'package:flutter/material.dart';
    import 'package:google_fonts/google_fonts.dart';
    import '../../theme/app_theme.dart';

    class AskBondyBottomSheet extends StatefulWidget {
      final Function(String message) onSubmit;

      const AskBondyBottomSheet({super.key, required this.onSubmit});

      @override
      State<AskBondyBottomSheet> createState() => _AskBondyBottomSheetState();
    }

    class _AskBondyBottomSheetState extends State<AskBondyBottomSheet> {
      final _controller = TextEditingController();

      @override
      void dispose() {
        _controller.dispose();
        super.dispose();
      }

      @override
      Widget build(BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 20,
            right: 20,
            top: 10,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pull indicator
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.between,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: BondyColors.primaryGradient,
                            ),
                            child: const Icon(Icons.favorite, color: Colors.white, size: 12),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Bondy AI',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: BondyColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'LẮNG NGHE & THẤU HIỂU',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: BondyColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 16, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Tilted Welcome AI Card
              Transform.rotate(
                angle: 0.03, // Tilted approx 2 degrees
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: BondyColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: BondyColors.primary.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bondy lắng nghe bạn...',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Một không gian an toàn để chia sẻ cảm xúc và tìm lời khuyên cho trái tim.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Prompts List
              Text(
                'GỢI Ý TRÒ CHUYỆN',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade400,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              _buildPromptButton(
                icon: Icons.forum_outlined,
                text: 'Làm sao để mở đầu câu chuyện?',
                color: const Color(0xFFF0F7FF),
                onTap: () => widget.onSubmit('Làm sao để mở đầu câu chuyện?'),
              ),
              _buildPromptButton(
                icon: Icons.sentiment_dissatisfied_outlined,
                text: 'Hôm nay mình thấy hơi mệt mỏi',
                color: const Color(0xFFF5F3FF),
                onTap: () => widget.onSubmit('Hôm nay mình thấy hơi mệt mỏi'),
              ),
              _buildPromptButton(
                icon: Icons.track_changes,
                text: 'Tư vấn về mục tiêu yêu đương',
                color: const Color(0xFFFFF1F2),
                onTap: () => widget.onSubmit('Tư vấn về mục tiêu yêu đương'),
              ),
              const SizedBox(height: 20),
              // Chat input row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Nhập câu hỏi của bạn...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            color: Colors.grey.shade400,
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                        ),
                        style: GoogleFonts.plusJakartaSans(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      final txt = _controller.text.trim();
                      if (txt.isNotEmpty) widget.onSubmit(txt);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: BondyColors.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Security note
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_user_outlined, color: Colors.green, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Cuộc trò chuyện của bạn luôn được bảo mật',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }

      Widget _buildPromptButton({
        required IconData icon,
        required String text,
        required Color color,
        required VoidCallback onTap,
      }) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: BondyColors.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 12),
                ],
              ),
            ),
          ),
        );
      }
    }
    ```

*   - [ ] **Step 2: Commit AskBondyBottomSheet**
    ```bash
    git add lib/widgets/chat/ask_bondy_bottom_sheet.dart
    git commit -m "feat: add AskBondyBottomSheet component"
    ```

---

### Task 4: Sửa đổi Giao diện Danh sách kết đôi (`MatchesListScreen`)
*   **Files:**
    *   Modify: `lib/screens/chat/matches_list_screen.dart`
*   - [ ] **Step 1: Chèn các thư viện nhập khẩu và thuộc tính cần thiết**
    Nhập khẩu `ai_prompts_config.dart`, `ask_bondy_bottom_sheet.dart` và thêm `_searchController` vào state để phục vụ tính năng tìm kiếm động.

    *Sửa đổi dòng nhập khẩu và thuộc tính trong `lib/screens/chat/matches_list_screen.dart`:*
    ```dart
    // Thay đổi ở các dòng import đầu tệp:
    import 'dart:async';
    import 'package:flutter/material.dart';
    import 'package:google_fonts/google_fonts.dart';

    import '../../services/api_client.dart';
    import '../../services/chat_service.dart';
    import '../../services/match_service.dart';
    import '../../theme/app_theme.dart';
    import '../../core/ai_prompts_config.dart'; // import mới
    import '../../widgets/chat/ask_bondy_bottom_sheet.dart'; // import mới
    ```

    *Thêm `_searchController` và mảng lọc vào State:*
    ```dart
      final _searchController = TextEditingController();
      String _searchQuery = '';
      // và tại dispose():
      @override
      void dispose() {
        _refreshTimer?.cancel();
        _searchController.dispose();
        super.dispose();
      }
    ```

*   - [ ] **Step 2: Triển khai Nút nổi FAB, Ô tìm kiếm và Gợi ý cuộn ngang**
    Sửa đổi hàm `build` của `MatchesListScreen` để:
    1. Trả về `floatingActionButton` Hỏi Bondy AI.
    2. Đọc ô tìm kiếm `_buildSearchField()`.
    3. Trả về hàng cuộn ngang `_buildHorizontalPendingList()` nếu có lượt chờ xác nhận.
    4. Xóa Container Hỏi Bondy cũ `_buildBondyEntry`.
    5. Triển khai lọc tìm kiếm động đối với danh sách chat hiển thị.

    *Ví dụ mã code trong `MatchesListScreen` build():*
    ```dart
    // 1. Thêm FAB vào Scaffold
    return Scaffold(
      backgroundColor: BondyColors.background,
      appBar: ...
      body: body,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => AskBondyBottomSheet(
              onSubmit: (msg) {
                Navigator.pop(context);
                Navigator.of(context).pushNamed(
                  '/chatbot',
                  arguments: {'initialMessage': msg},
                ).then((_) => _loadAll(silent: true));
              },
            ),
          );
        },
        backgroundColor: Colors.transparent,
        elevation: 4,
        child: Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: BondyColors.primaryGradient,
          ),
          child: const Icon(Icons.smart_toy, color: Colors.white, size: 28),
        ),
      ),
    );
    ```

    *Sửa đổi cấu trúc `ListView` bên trong body để thay đổi giao diện:*
    ```dart
    // Thêm thanh tìm kiếm và hàng cuộn ngang
    final filteredChats = _chats.where((chat) {
      final name = chat.otherUser.displayName.toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    final body = RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, widget.embedded ? 16 : 8, 16, 24),
        children: [
          // 1. Ô tìm kiếm
          _buildSearchField(),
          const SizedBox(height: 16),
          // 2. Mới tương hợp hàng cuộn ngang (nếu có pending matches)
          if (_pendingMatches.isNotEmpty) ...[
            Text(
              'Mới tương hợp',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: BondyColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            _buildHorizontalPendingList(),
            const SizedBox(height: 16),
          ],
          // 3. Danh sách cuộc trò chuyện
          Text(
            'Tin nhắn',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: BondyColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (_isLoading)
             // Loading state...
          else if (_errorMessage != null)
             // Error state...
          else if (filteredChats.isEmpty && _pendingMatches.isEmpty)
             // Empty state...
          else
            ...filteredChats.map((chat) => _buildChatTile(context, chat)),
        ],
      ),
    );
    ```

    *Xây dựng hàm `_buildSearchField` và `_buildHorizontalPendingList`:*
    ```dart
    Widget _buildSearchField() {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm người ấy...',
                  hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 13),
                  border: InputBorder.none,
                ),
                style: GoogleFonts.plusJakartaSans(fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildHorizontalPendingList() {
      return SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _pendingMatches.length,
          itemBuilder: (context, index) {
            final match = _pendingMatches[index];
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pushNamed(
                  '/match-confirm',
                  arguments: {'matchId': match.id},
                ).then((_) => _loadAll(silent: true)),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFF97316), Color(0xFFEA2A5A)],
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundImage: match.otherUserPhoto != null
                              ? NetworkImage(match.otherUserPhoto!)
                              : null,
                          child: match.otherUserPhoto == null
                              ? Text(match.otherUserName[0].toUpperCase())
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      match.otherUserName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }
    ```

*   - [ ] **Step 3: Cập nhật `_buildChatTile` hỗ trợ AI Icebreakers**
    Sửa đổi code hiển thị dòng tin nhắn cuối trong `_buildChatTile`. Nếu cuộc hội thoại mới tinh, hiển thị một câu gợi ý ngẫu nhiên từ pool.

    *Sửa đổi trong `_buildChatTile`:*
    ```dart
    // Thay thế đoạn: final lastMessage = chat.lastMessage?.content ?? 'Bắt đầu cuộc trò chuyện';
    
    final bool isNewChat = chat.lastMessage == null || chat.lastMessage!.content.isEmpty;
    final int seed = chat.id.hashCode;
    final String icebreaker = AIPromptsConfig.icebreakers[seed % AIPromptsConfig.icebreakers.length];
    
    // Và hiển thị subtitle Widget tương ứng:
    subtitle: isNewChat
        ? Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                const Icon(Icons.local_florist, size: 14, color: BondyColors.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Gợi ý mở lời: "$icebreaker"',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: BondyColors.primary.withValues(alpha: 0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          )
        : Text(
            chat.lastMessage!.content,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: BondyColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
    ```

*   - [ ] **Step 4: Commit MatchesListScreen redesign**
    ```bash
    git add lib/screens/chat/matches_list_screen.dart
    git commit -m "feat: redesign matches list screen with search, horizontal pending list and FAB"
    ```

---

### Task 5: Sửa đổi Giao diện Trợ lý AI Chatbot (`HealingChatbotCoachScreen`)
*   **Files:**
    *   Modify: `lib/screens/chat/healing_chatbot_coach_screen.dart`
*   - [ ] **Step 1: Import DateSuggestionsWidget và cấu hình**
    Tích hợp thư viện mới vào màn hình AI Coach.

    *Thêm dòng nhập khẩu:*
    ```dart
    import '../../widgets/chat/date_suggestions_widget.dart';
    import '../../core/ai_prompts_config.dart';
    ```

*   - [ ] **Step 2: Xử lý `initialMessage` khi mở trang**
    Trong hàm `didChangeDependencies`, nếu có tham số `initialMessage` truyền sang từ Bottom Sheet, chatbot sẽ tự động chèn tin nhắn và kích hoạt AI sinh phản hồi.

    *Nhận diện arguments trong State:*
    ```dart
    // Ví dụ trong didChangeDependencies:
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic> && args.containsKey('initialMessage')) {
      final initMsg = args['initialMessage'] as String;
      // Tránh lặp lại:
      args.remove('initialMessage');
      _sendDirectMessage(initMsg);
    }
    ```

*   - [ ] **Step 3: Hỗ trợ hiển thị bong bóng chat dạng thẻ card gợi ý cuối tuần**
    Nếu AI gửi phản hồi gợi ý địa điểm, ta render ra widget `DateSuggestionsWidget` cuộn ngang tuyệt đẹp.

    *Sửa đổi hàm render bong bóng chat:*
    ```dart
    // Giả sử có một đoạn phân tích tin nhắn:
    if (msg.messageType == 'DATE_SUGGESTION') {
      return DateSuggestionsWidget(
        places: AIPromptsConfig.mockDateSuggestions,
        onShare: (name) => _handleSharePlace(name),
        onSave: (name) => _handleSavePlace(name),
        onMap: (name) => _handleMapPlace(name),
      );
    }
    ```

*   - [ ] **Step 4: Commit HealingChatbotCoachScreen updates**
    ```bash
    git add lib/screens/chat/healing_chatbot_coach_screen.dart
    git commit -m "feat: integrate DateSuggestionsWidget and initial message flow into chatbot coach screen"
    ```

---

### Task 6: Tích hợp Prompt câu hỏi sâu trong Phòng Chat Người dùng (`ChatScreen`)
*   **Files:**
    *   Modify: `lib/screens/chat/chat_screen.dart`
*   - [ ] **Step 1: Import cấu hình AI Prompts**
    Nhập khẩu thư viện prompts vào `chat_screen.dart`.

    *Thêm dòng nhập khẩu:*
    ```dart
    import '../../core/ai_prompts_config.dart';
    ```

*   - [ ] **Step 2: Triển khai thanh gợi ý AI Deeper Prompts trên thanh nhập tin nhắn**
    Thay thế ListView emojis cũ của thanh nhập tin nhắn thành dải các nút Chip câu hỏi sâu ngắt quãng sắc màu.

    *Sửa đổi hàm `_buildInputBar` trong `chat_screen.dart`:*
    ```dart
    // Thay thế đoạn ListView chứa ActionChip emojis cũ thành dải gợi ý câu hỏi sâu:
    Widget _buildInputBar() {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: BondyColors.divider.withValues(alpha: 0.5)),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Thanh Prompt câu hỏi sâu
              SizedBox(
                height: 42,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: AIPromptsConfig.deeperPrompts.length,
                  itemBuilder: (context, index) {
                    final prompt = AIPromptsConfig.deeperPrompts[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        avatar: const Icon(Icons.psychology, size: 16, color: BondyColors.primary),
                        label: Text(
                          prompt,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: BondyColors.textPrimary,
                          ),
                        ),
                        backgroundColor: Colors.white,
                        side: BorderSide(color: BondyColors.primary.withValues(alpha: 0.2)),
                        onPressed: () {
                          setState(() {
                            _controller.text = prompt;
                          });
                          // Focus và đưa con trỏ xuống cuối dòng
                          _controller.selection = TextSelection.fromPosition(
                            TextPosition(offset: _controller.text.length),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              // Khung soạn thảo tin nhắn bên dưới...
              Row(
                children: [
                  // Nút ảnh, mic, TextField như cũ...
                ],
              ),
            ],
          ),
        ),
      );
    }
    ```

*   - [ ] **Step 3: Commit ChatScreen updates**
    ```bash
    git add lib/screens/chat/chat_screen.dart
    git commit -m "feat: add AI Deeper Prompts bar above chat input in ChatScreen"
    ```

---

## 5. Xác nhận & Kiểm tra chất lượng (Verification)

Sau khi triển khai xong, chúng ta chạy lệnh sau để xác thực biên dịch và cú pháp sạch sẽ:
```bash
flutter analyze
```
Yêu cầu: Không có lỗi phân tích.
